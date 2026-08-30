use serde_json::{Value, json};

use crate::battery::BatteryInfo;
use crate::system::{
    command_exists, dedupe_sorted, format_privileged_command_failure, read_trimmed, run_command,
};

pub struct ChargingInfo {
    pub status: Value,
    pub capabilities: Value,
    pub diagnostics: Value,
}

pub fn inspect(battery: &BatteryInfo) -> ChargingInfo {
    let Some(device) = battery.device.as_deref() else {
        return unavailable("No battery device exists.");
    };

    let charge_types = read_trimmed(&device.join("charge_types"));
    let has_charge_control_start = device.join("charge_control_start_threshold").exists();
    let has_charge_control_end = device.join("charge_control_end_threshold").exists();
    let has_charge_start = device.join("charge_start_threshold").exists();
    let has_charge_stop = device.join("charge_stop_threshold").exists();

    let has_any_control = charge_types.is_some()
        || has_charge_control_start
        || has_charge_control_end
        || has_charge_start
        || has_charge_stop;

    let tlp_present = command_exists("tlp");

    let backend = if tlp_present && has_any_control {
        Some("tlp")
    } else if has_any_control {
        Some("native")
    } else {
        None
    };

    let interface = if charge_types.is_some() {
        Some("charge_types")
    } else if has_charge_control_start || has_charge_control_end {
        Some("charge_control_thresholds")
    } else if has_charge_start || has_charge_stop {
        Some("charge_thresholds")
    } else {
        None
    };

    let options = derive_charge_options(
        charge_types.as_deref(),
        has_charge_control_start,
        has_charge_control_end,
        has_charge_start,
        has_charge_stop,
    );

    let current = derive_current_charge_option(charge_types.as_deref());
    let raw_current_charge_type = derive_raw_current_charge_type(charge_types.as_deref());
    let available = backend.is_some();

    ChargingInfo {
        status: json!({
            "available": available,
            "backend": backend,
            "current": current,
            "interface": interface,
            "options": options
        }),
        capabilities: json!({
            "available": available,
            "backend": backend,
            "interface": interface,
            "options": options
        }),
        diagnostics: json!({
            "available": available,
            "selected_backend": backend,
            "interface": interface,
            "tlp_present": tlp_present,
            "charge_types": charge_types,
            "raw_current_charge_type": raw_current_charge_type,
            "interfaces": {
                "charge_control_start_threshold": has_charge_control_start,
                "charge_control_end_threshold": has_charge_control_end,
                "charge_start_threshold": has_charge_start,
                "charge_stop_threshold": has_charge_stop
            },
            "options": options,
            "current": current
        }),
    }
}

pub fn set(requested: &str, battery: &BatteryInfo) -> Result<Value, String> {
    let mode = match requested {
        "conserve" | "full" => requested,
        _ => {
            return Err(format!(
                "Unsupported charge mode: {requested}. Valid modes are conserve and full."
            ));
        }
    };

    if !battery.present {
        return Err("Cannot change charging behavior because no battery was detected.".to_string());
    }

    let charging = inspect(battery);

    let backend = charging
        .status
        .get("backend")
        .and_then(Value::as_str)
        .ok_or_else(|| "No supported charging backend is available.".to_string())?;

    match backend {
        "tlp" => {
            let device_name = battery
                .device
                .as_deref()
                .and_then(|path| path.file_name())
                .and_then(|name| name.to_str())
                .ok_or_else(|| "Could not determine the battery device name.".to_string())?;

            let args: Vec<&str> = match mode {
                "conserve" => vec!["-n", "tlp", "setcharge", "0", "1", device_name],
                "full" => vec!["-n", "tlp", "fullcharge", device_name],
                _ => unreachable!(),
            };

            let output = run_command("sudo", &args);

            if !output.success {
                let command = std::iter::once("sudo")
                    .chain(args.iter().copied())
                    .collect::<Vec<_>>();

                return Err(format_privileged_command_failure(&command, &output));
            }
        }
        "native" => {
            return Err(
                "Native charging control is detected, but a generic write operation has not been implemented yet."
                    .to_string(),
            );
        }
        other => return Err(format!("Unsupported charging backend selected: {other}")),
    }

    let after_battery = crate::battery::inspect();
    let after = inspect(&after_battery);

    Ok(json!({
        "version": 1,
        "success": true,
        "requested": mode,
        "result": after.status
    }))
}

// Charging options

fn derive_charge_options(
    charge_types: Option<&str>,
    has_charge_control_start: bool,
    has_charge_control_end: bool,
    has_charge_start: bool,
    has_charge_stop: bool,
) -> Vec<String> {
    if let Some(types) = charge_types {
        let mut options = Vec::new();

        for value in types.split_whitespace() {
            let value = value.trim_matches(['[', ']']);

            match value {
                "Long_Life" => options.push("conserve".to_string()),
                "Standard" => options.push("full".to_string()),
                "Fast" => {}
                _ => {}
            }
        }

        return dedupe_sorted(options);
    }

    if has_charge_control_start || has_charge_control_end || has_charge_start || has_charge_stop {
        return vec!["threshold-control".to_string()];
    }

    vec![]
}

fn derive_current_charge_option(charge_types: Option<&str>) -> Option<String> {
    match derive_raw_current_charge_type(charge_types)?.as_str() {
        "Long_Life" => Some("conserve".to_string()),
        "Standard" => Some("full".to_string()),
        _ => None,
    }
}

fn derive_raw_current_charge_type(charge_types: Option<&str>) -> Option<String> {
    charge_types?.split_whitespace().find_map(|value| {
        let active = value.strip_prefix('[')?.strip_suffix(']')?;
        (!active.is_empty()).then(|| active.to_string())
    })
}

// Diagnostics

fn unavailable(reason: &str) -> ChargingInfo {
    ChargingInfo {
        status: json!({
            "available": false,
            "backend": null,
            "current": null,
            "interface": null,
            "options": []
        }),
        capabilities: json!({
            "available": false,
            "backend": null,
            "interface": null,
            "options": []
        }),
        diagnostics: json!({
            "available": false,
            "reason": reason
        }),
    }
}
