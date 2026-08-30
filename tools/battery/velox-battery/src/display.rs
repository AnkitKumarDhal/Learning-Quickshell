use serde_json::{Value, json};

use crate::system::{command_exists, format_command_failure, run_command};

pub struct DisplayInfo {
    pub status: Value,
    pub capabilities: Value,
    pub diagnostics: Value,
}

pub fn inspect() -> DisplayInfo {
    if !command_exists("hyprctl") {
        return unavailable("hyprctl was not found.");
    }

    let result = run_command("hyprctl", &["-j", "monitors", "all"]);

    if !result.success {
        return unavailable(&format!(
            "hyprctl monitors query failed: {}",
            if result.stderr.is_empty() {
                "unknown error"
            } else {
                &result.stderr
            }
        ));
    }

    let parsed: Value = match serde_json::from_str(&result.stdout) {
        Ok(value) => value,
        Err(error) => {
            return DisplayInfo {
                status: json!({
                    "available": false,
                    "backend": "hyprland",
                    "output": null,
                    "resolution": null,
                    "current_refresh": null,
                    "options": []
                }),
                capabilities: json!({
                    "available": false,
                    "backend": "hyprland",
                    "options": []
                }),
                diagnostics: json!({
                    "available": false,
                    "backend": "hyprland",
                    "reason": "hyprctl returned invalid JSON.",
                    "parse_error": error.to_string()
                }),
            };
        }
    };

    let monitors = parsed.as_array().cloned().unwrap_or_default();

    if monitors.is_empty() {
        return unavailable("Hyprland returned no monitors.");
    }

    let Some(monitor) = select_monitor(&monitors) else {
        return unavailable("No suitable active monitor was found.");
    };

    let output = monitor
        .get("name")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    let width = monitor.get("width").and_then(Value::as_u64).unwrap_or(0);
    let height = monitor.get("height").and_then(Value::as_u64).unwrap_or(0);
    let current_refresh = monitor.get("refreshRate").and_then(Value::as_f64);

    let resolution = if width > 0 && height > 0 {
        Some(format!("{width}x{height}"))
    } else {
        None
    };

    let refresh_options = matching_refresh_rates(&monitor, width, height);
    let available = !refresh_options.is_empty();

    DisplayInfo {
        status: json!({
            "available": available,
            "backend": "hyprland",
            "output": output,
            "resolution": resolution,
            "current_refresh": current_refresh,
            "options": refresh_options
        }),
        capabilities: json!({
            "available": available,
            "backend": "hyprland",
            "output": output,
            "options": refresh_options
        }),
        diagnostics: json!({
            "available": available,
            "backend": "hyprland",
            "selected_output": output,
            "selected_resolution": resolution,
            "current_refresh": current_refresh,
            "matching_refresh_rates": refresh_options,
            "monitor": monitor,
            "selection_strategy": "Prefer active internal-panel connectors such as eDP-/LVDS-/DSI-, otherwise the focused active monitor, then the first active monitor.",
            "write_method": "hyprctl eval with hl.monitor({ output, mode })"
        }),
    }
}

pub fn set(requested: f64) -> Result<Value, String> {
    if !requested.is_finite() || requested <= 0.0 {
        return Err("Refresh rate must be a positive number.".to_string());
    }

    let display = inspect();

    if !display
        .status
        .get("available")
        .and_then(Value::as_bool)
        .unwrap_or(false)
    {
        return Err("No usable display refresh-rate control is available.".to_string());
    }

    let output = display
        .status
        .get("output")
        .and_then(Value::as_str)
        .ok_or_else(|| "No display output was detected.".to_string())?;

    let resolution = display
        .status
        .get("resolution")
        .and_then(Value::as_str)
        .ok_or_else(|| "No current display resolution was detected.".to_string())?;

    let options = display
        .status
        .get("options")
        .and_then(Value::as_array)
        .ok_or_else(|| "No display refresh-rate options were detected.".to_string())?;

    let refresh = options
        .iter()
        .filter_map(Value::as_f64)
        .find(|rate| (*rate - requested).abs() < 0.01)
        .ok_or_else(|| {
            format!("Refresh rate {requested} is not available for {output} at {resolution}.")
        })?;

    let mode = format!("{resolution}@{refresh:.2}Hz");
    let lua = format!("hl.monitor({{ output = \"{output}\", mode = \"{mode}\" }})");
    let result = run_command("hyprctl", &["eval", lua.as_str()]);

    if !result.success {
        return Err(format_command_failure(
            "hyprctl",
            &["eval", lua.as_str()],
            &result,
        ));
    }

    let after = inspect();

    Ok(json!({
        "version": 1,
        "success": true,
        "requested": refresh,
        "output": output,
        "mode": mode,
        "result": after.status
    }))
}

fn unavailable(reason: &str) -> DisplayInfo {
    DisplayInfo {
        status: json!({
            "available": false,
            "backend": null,
            "output": null,
            "resolution": null,
            "current_refresh": null,
            "options": []
        }),
        capabilities: json!({
            "available": false,
            "backend": null,
            "options": []
        }),
        diagnostics: json!({
            "available": false,
            "reason": reason
        }),
    }
}

fn select_monitor(monitors: &[Value]) -> Option<&Value> {
    let active = monitors
        .iter()
        .filter(|monitor| {
            !monitor
                .get("disabled")
                .and_then(Value::as_bool)
                .unwrap_or(false)
        })
        .collect::<Vec<_>>();

    if active.is_empty() {
        return None;
    }

    if let Some(monitor) = active.iter().find(|monitor| {
        monitor
            .get("name")
            .and_then(Value::as_str)
            .map(is_internal_display_name)
            .unwrap_or(false)
    }) {
        return Some(monitor);
    }

    if let Some(monitor) = active.iter().find(|monitor| {
        monitor
            .get("focused")
            .and_then(Value::as_bool)
            .unwrap_or(false)
    }) {
        return Some(monitor);
    }

    active.first().copied()
}

fn is_internal_display_name(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    lower.starts_with("edp-") || lower.starts_with("lvds-") || lower.starts_with("dsi-")
}

fn matching_refresh_rates(monitor: &Value, width: u64, height: u64) -> Vec<f64> {
    let modes = if let Some(array) = monitor.get("availableModes").and_then(Value::as_array) {
        array.iter().filter_map(Value::as_str).collect::<Vec<_>>()
    } else if let Some(text) = monitor.get("availableModes").and_then(Value::as_str) {
        text.split_whitespace().collect::<Vec<_>>()
    } else {
        Vec::new()
    };

    let prefix = if width > 0 && height > 0 {
        format!("{width}x{height}@")
    } else {
        String::new()
    };

    let mut rates = modes
        .into_iter()
        .filter(|mode| prefix.is_empty() || mode.starts_with(&prefix))
        .filter_map(parse_refresh_from_mode)
        .collect::<Vec<_>>();

    rates.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    rates.dedup_by(|a, b| (*a - *b).abs() < 0.001);
    rates
}

fn parse_refresh_from_mode(mode: &str) -> Option<f64> {
    let (_, refresh) = mode.split_once('@')?;
    refresh.trim_end_matches("Hz").trim().parse().ok()
}
