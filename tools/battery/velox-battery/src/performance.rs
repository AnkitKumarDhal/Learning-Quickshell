use serde_json::{Value, json};
use std::path::Path;

use crate::system::{
    command_exists, command_path, dedupe_sorted, format_command_failure,
    format_privileged_command_failure, read_trimmed, run_command, systemctl_active,
};

pub struct PerformanceInfo {
    pub status: Value,
    pub capabilities: Value,
    pub diagnostics: Value,
}

pub fn inspect() -> PerformanceInfo {
    let tlp_present = command_exists("tlp");
    let tlp_stat_present = command_exists("tlp-stat");
    let tlpctl_present = command_exists("tlpctl");
    let tlp_pd_present = command_exists("tlp-pd");

    let tlp_active = tlp_present && tlp_is_active();
    let tlp_pd_active = tlp_pd_present && tlpctl_present && systemctl_active("tlp-pd.service");
    let ppd_present = command_exists("powerprofilesctl");
    let ppd_active = systemctl_active("power-profiles-daemon.service");

    let tlp_status = if tlp_stat_present {
        run_command("tlp-stat", &["-s"])
    } else {
        crate::system::CommandResult {
            success: false,
            stdout: String::new(),
            stderr: "tlp-stat command not found".to_string(),
            exit_code: None,
        }
    };

    let tlp_profile = parse_tlp_profile(&tlp_status.stdout);
    let native_profile = read_trimmed(Path::new("/sys/firmware/acpi/platform_profile"));

    let native_choices = read_trimmed(Path::new("/sys/firmware/acpi/platform_profile_choices"))
        .map(|value| {
            value
                .split_whitespace()
                .map(str::to_string)
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    let scaling_driver = read_trimmed(Path::new(
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver",
    ));

    let scaling_governors = read_trimmed(Path::new(
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors",
    ))
    .map(|value| {
        value
            .split_whitespace()
            .map(str::to_string)
            .collect::<Vec<_>>()
    })
    .unwrap_or_default();

    let epp_preferences = read_trimmed(Path::new(
        "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences",
    ))
    .map(|value| {
        value
            .split_whitespace()
            .map(str::to_string)
            .collect::<Vec<_>>()
    })
    .unwrap_or_default();

    let native_available = !native_choices.is_empty() || native_profile.is_some();

    let (backend, interface, options, current) = if tlp_active {
        (
            Some("tlp"),
            if tlp_pd_active {
                Some("tlp-pd")
            } else {
                Some("cli")
            },
            vec![
                "power-saving".to_string(),
                "balanced".to_string(),
                "performance".to_string(),
            ],
            tlp_profile.as_deref().map(normalize_performance_option),
        )
    } else if ppd_active {
        let profile_list = if ppd_present {
            run_command("powerprofilesctl", &["list"])
        } else {
            crate::system::CommandResult {
                success: false,
                stdout: String::new(),
                stderr: "powerprofilesctl not found".to_string(),
                exit_code: None,
            }
        };

        let options = dedupe_sorted(
            parse_powerprofilesctl_profiles(&profile_list.stdout)
                .into_iter()
                .map(|value| normalize_performance_option(&value)),
        );

        let current = if ppd_present {
            let result = run_command("powerprofilesctl", &["get"]);

            if result.success && !result.stdout.is_empty() {
                Some(normalize_performance_option(result.stdout.trim()))
            } else {
                None
            }
        } else {
            None
        };

        (
            Some("power-profiles-daemon"),
            Some("dbus"),
            options,
            current,
        )
    } else if native_available {
        (
            Some("native"),
            Some("platform_profile"),
            dedupe_sorted(
                native_choices
                    .iter()
                    .map(|value| normalize_performance_option(value)),
            ),
            native_profile.as_deref().map(normalize_performance_option),
        )
    } else {
        (None, None, vec![], None)
    };

    let available = backend.is_some();

    PerformanceInfo {
        status: json!({
            "available": available,
            "backend": backend,
            "interface": interface,
            "current": current,
            "options": options
        }),
        capabilities: json!({
            "available": available,
            "backend": backend,
            "interface": interface,
            "options": options
        }),
        diagnostics: json!({
            "selected_backend": backend,
            "selected_interface": interface,
            "available": available,
            "current": current,
            "options": options,
            "tools": {
                "tlp": {
                    "present": tlp_present,
                    "active": tlp_active,
                    "path": command_path("tlp")
                },
                "tlp-stat": {
                    "present": tlp_stat_present,
                    "path": command_path("tlp-stat")
                },
                "tlpctl": {
                    "present": tlpctl_present,
                    "path": command_path("tlpctl")
                },
                "tlp-pd": {
                    "present": tlp_pd_present,
                    "active": tlp_pd_active,
                    "path": command_path("tlp-pd")
                },
                "powerprofilesctl": {
                    "present": ppd_present,
                    "path": command_path("powerprofilesctl")
                },
                "power-profiles-daemon": {
                    "active": ppd_active
                }
            },
            "tlp": {
                "profile": tlp_profile,
                "status_command": {
                    "success": tlp_status.success,
                    "stdout": tlp_status.stdout,
                    "stderr": tlp_status.stderr,
                    "exit_code": tlp_status.exit_code
                }
            },
            "native": {
                "platform_profile": native_profile,
                "platform_profile_choices": native_choices,
                "scaling_driver": scaling_driver,
                "scaling_available_governors": scaling_governors,
                "energy_performance_available_preferences": epp_preferences
            },
            "selection_reason": performance_selection_reason(
                backend,
                tlp_active,
                tlp_pd_active,
                ppd_active,
                native_available,
            )
        }),
    }
}

pub fn set(requested: &str) -> Result<Value, String> {
    let profile = normalize_requested_performance(requested)?;
    let info = inspect();

    let backend = info
        .status
        .get("backend")
        .and_then(Value::as_str)
        .ok_or_else(|| "No supported performance backend is available.".to_string())?;

    match backend {
        "tlp" => {
            let interface = info
                .status
                .get("interface")
                .and_then(Value::as_str)
                .unwrap_or("cli");
            let tlp_profile = profile_to_tlp_profile(&profile);

            match interface {
                "tlp-pd" => {
                    let output = run_command("tlpctl", &["set", tlp_profile]);

                    if !output.success {
                        return Err(format_command_failure(
                            "tlpctl",
                            &["set", tlp_profile],
                            &output,
                        ));
                    }
                }
                "cli" => {
                    let args = ["-n", "tlp", tlp_profile];
                    let output = run_command("sudo", &args);

                    if !output.success {
                        return Err(format_privileged_command_failure(
                            &["sudo", &args[0], &args[1], &args[2]],
                            &output,
                        ));
                    }
                }
                other => return Err(format!("TLP selected an unsupported interface: {other}")),
            }
        }
        "power-profiles-daemon" => {
            let ppd_profile = profile_to_ppd_profile(&profile);
            let output = run_command("powerprofilesctl", &["set", ppd_profile]);

            if !output.success {
                return Err(format_command_failure(
                    "powerprofilesctl",
                    &["set", ppd_profile],
                    &output,
                ));
            }
        }
        "native" => return set_native(&profile),
        other => return Err(format!("Unsupported performance backend selected: {other}")),
    }

    let after = inspect();

    Ok(json!({
        "version": 1,
        "success": true,
        "requested": profile,
        "result": after.status
    }))
}

pub fn tlp_is_active() -> bool {
    if systemctl_active("tlp.service") {
        return true;
    }

    if !command_exists("tlp-stat") {
        return false;
    }

    let result = run_command("tlp-stat", &["-s"]);

    result.success
        && result
            .stdout
            .lines()
            .any(|line| line.trim_start().starts_with("tlp") && line.contains("enabled"))
}

fn normalize_requested_performance(value: &str) -> Result<String, String> {
    let normalized = normalize_performance_option(value);

    match normalized.as_str() {
        "power-saving" | "balanced" | "performance" => Ok(normalized),
        _ => Err(format!(
            "Unsupported performance profile: {value}. Valid profiles are power-saving, balanced, and performance."
        )),
    }
}

fn normalize_performance_option(value: &str) -> String {
    match value {
        "power-saver" | "powersave" | "power_save" | "low-power" => "power-saving".to_string(),
        "balanced" | "balance_power" | "balance_performance" => "balanced".to_string(),
        "performance" => "performance".to_string(),
        other => other.to_string(),
    }
}

fn profile_to_tlp_profile(profile: &str) -> &'static str {
    match profile {
        "power-saving" => "power-saver",
        "balanced" => "balanced",
        "performance" => "performance",
        _ => unreachable!(),
    }
}

fn profile_to_ppd_profile(profile: &str) -> &'static str {
    match profile {
        "power-saving" => "power-saver",
        "balanced" => "balanced",
        "performance" => "performance",
        _ => unreachable!(),
    }
}

fn set_native(profile: &str) -> Result<Value, String> {
    let choices_path = Path::new("/sys/firmware/acpi/platform_profile_choices");
    let current_path = Path::new("/sys/firmware/acpi/platform_profile");

    let choices = read_trimmed(choices_path)
        .map(|value| {
            value
                .split_whitespace()
                .map(str::to_string)
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    let requested_native = match profile {
        "power-saving" => "low-power",
        "balanced" => "balanced",
        "performance" => "performance",
        _ => unreachable!(),
    };

    if !choices.iter().any(|choice| choice == requested_native) {
        return Err(format!(
            "Native platform_profile backend does not expose `{requested_native}`."
        ));
    }

    std::fs::write(current_path, requested_native).map_err(|error| {
        format!(
            "Failed to write `{requested_native}` to {}: {error}",
            current_path.display()
        )
    })?;

    Ok(json!({
        "version": 1,
        "success": true,
        "requested": profile,
        "backend": "native",
        "current": read_trimmed(current_path)
    }))
}

fn parse_tlp_profile(output: &str) -> Option<String> {
    output.lines().find_map(|line| {
        let trimmed = line.trim();

        if !trimmed.starts_with("TLP profile") {
            return None;
        }

        let (_, value) = trimmed.split_once('=')?;
        let profile = value.trim().split('/').next()?.trim();

        (!profile.is_empty()).then(|| profile.to_string())
    })
}

fn parse_powerprofilesctl_profiles(output: &str) -> Vec<String> {
    output
        .lines()
        .filter_map(|line| {
            let trimmed = line.trim();

            if trimmed.starts_with("Performance") {
                Some("performance")
            } else if trimmed.starts_with("Balanced") {
                Some("balanced")
            } else if trimmed.starts_with("Power Saver") {
                Some("power-saver")
            } else {
                None
            }
        })
        .map(str::to_string)
        .collect()
}

fn performance_selection_reason(
    backend: Option<&str>,
    tlp_active: bool,
    tlp_pd_active: bool,
    ppd_active: bool,
    native_available: bool,
) -> &'static str {
    match backend {
        Some("tlp") if tlp_pd_active => {
            "TLP is active and tlp-pd is active, so TLP is selected through its desktop-facing profile interface."
        }
        Some("tlp") if tlp_active => {
            "TLP is active, but tlp-pd is not active, so the TLP CLI interface is currently selected."
        }
        Some("power-profiles-daemon") if ppd_active => {
            "TLP is unavailable, so the active power-profiles-daemon is used."
        }
        Some("native") if native_available => {
            "TLP and power-profiles-daemon are unavailable, so the native platform_profile interface is used."
        }
        _ => "No supported performance backend was detected.",
    }
}
