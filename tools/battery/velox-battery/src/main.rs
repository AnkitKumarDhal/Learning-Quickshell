use serde_json::{Value, json};
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const SCHEMA_VERSION: u32 = 1;

#[derive(Debug, Clone)]
struct CommandResult {
    success: bool,
    stdout: String,
    stderr: String,
    exit_code: Option<i32>,
}

#[derive(Debug, Clone)]
struct BatteryInfo {
    present: bool,
    device: Option<PathBuf>,
    status: Value,
    diagnostics: Value,
}

#[derive(Debug, Clone)]
struct PerformanceInfo {
    status: Value,
    capabilities: Value,
    diagnostics: Value,
}

#[derive(Debug, Clone)]
struct ChargingInfo {
    status: Value,
    capabilities: Value,
    diagnostics: Value,
}

#[derive(Debug, Clone)]
struct DisplayInfo {
    status: Value,
    capabilities: Value,
    diagnostics: Value,
}

fn main() {
    let mut args = env::args().skip(1);
    let command = args.next().unwrap_or_else(|| "status".to_string());

    let result = match command.as_str() {
        "status" => Ok(build_status()),
        "capabilities" => Ok(build_capabilities()),
        "diagnose" => Ok(build_diagnostics()),
        "performance" => handle_performance_command(args.collect()),
        "charge" => handle_charge_command(args.collect()),
        "display" => handle_display_command(args.collect()),
        "help" | "--help" | "-h" => {
            print_help();
            return;
        }
        other => Err(format!(
            "Unknown command: {other}. Run `velox-battery help` for usage."
        )),
    };

    match result {
        Ok(output) => match serde_json::to_string_pretty(&output) {
            Ok(serialized) => println!("{serialized}"),
            Err(error) => {
                eprintln!("Failed to serialize JSON: {error}");
                std::process::exit(1);
            }
        },
        Err(error) => {
            eprintln!("{error}");
            std::process::exit(1);
        }
    }
}

fn print_help() {
    println!(
        "\
velox-battery - Velox-Q battery/backend adapter

Read-only commands:

  velox-battery status
      Current battery, performance, charging, and display state.

  velox-battery capabilities
      Hardware/backend capabilities detected on this system.

  velox-battery diagnose
      Detailed diagnostics and backend-selection information.

Write commands:

  velox-battery performance get
      Get the active performance profile.

  velox-battery performance set <profile>
      Set power-saving, balanced, or performance.

  velox-battery charge get
      Get the current Velox-Q charging state.

  velox-battery charge set <mode>
      Set conserve or full.

  velox-battery display get
      Get the detected display refresh information.

  velox-battery display set <refresh>
      Change only the selected monitor refresh rate.

  velox-battery help
      Show this help message.
"
    );
}

// Commands

fn run_command(program: &str, args: &[&str]) -> CommandResult {
    match Command::new(program).args(args).output() {
        Ok(output) => CommandResult {
            success: output.status.success(),
            stdout: String::from_utf8_lossy(&output.stdout).trim().to_string(),
            stderr: String::from_utf8_lossy(&output.stderr).trim().to_string(),
            exit_code: output.status.code(),
        },
        Err(error) => CommandResult {
            success: false,
            stdout: String::new(),
            stderr: error.to_string(),
            exit_code: None,
        },
    }
}

fn executable_in_path(program: &str) -> Option<PathBuf> {
    if program.contains('/') {
        let path = PathBuf::from(program);
        return is_executable_file(&path).then_some(path);
    }

    let path_var = env::var_os("PATH")?;

    for directory in env::split_paths(&path_var) {
        let candidate = directory.join(program);
        if is_executable_file(&candidate) {
            return Some(candidate);
        }
    }

    None
}

fn is_executable_file(path: &Path) -> bool {
    if !path.is_file() {
        return false;
    }

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::metadata(path)
            .map(|m| m.permissions().mode() & 0o111 != 0)
            .unwrap_or(false)
    }

    #[cfg(not(unix))]
    {
        true
    }
}

fn command_exists(program: &str) -> bool {
    executable_in_path(program).is_some()
}

fn systemctl_active(unit: &str) -> bool {
    run_command("systemctl", &["is-active", "--quiet", unit]).success
}

fn read_trimmed(path: &Path) -> Option<String> {
    fs::read_to_string(path)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}

fn read_integer(path: &Path) -> Option<i64> {
    read_trimmed(path)?.parse().ok()
}

fn read_float(path: &Path) -> Option<f64> {
    read_trimmed(path)?.parse().ok()
}

fn file_exists(path: &Path) -> bool {
    path.exists()
}

fn directory_entries(path: &Path) -> Vec<PathBuf> {
    let mut entries = fs::read_dir(path)
        .ok()
        .into_iter()
        .flat_map(|dir| dir.filter_map(Result::ok))
        .map(|entry| entry.path())
        .collect::<Vec<_>>();

    entries.sort();
    entries
}

fn command_path(program: &str) -> Option<String> {
    executable_in_path(program).map(|path| path.to_string_lossy().into_owned())
}

fn dedupe_sorted(values: impl IntoIterator<Item = String>) -> Vec<String> {
    values
        .into_iter()
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect()
}

// Reports

fn build_status() -> Value {
    let battery = inspect_battery();
    let performance = inspect_performance();
    let charging = inspect_charging(&battery);
    let display = inspect_display();

    json!({
        "version": SCHEMA_VERSION,
        "battery": battery.status,
        "performance": performance.status,
        "charging": charging.status,
        "display": display.status
    })
}

fn build_capabilities() -> Value {
    let battery = inspect_battery();
    let performance = inspect_performance();
    let charging = inspect_charging(&battery);
    let display = inspect_display();

    json!({
        "version": SCHEMA_VERSION,
        "battery": {
            "present": battery.present
        },
        "performance": performance.capabilities,
        "charging": charging.capabilities,
        "display": display.capabilities
    })
}

fn build_diagnostics() -> Value {
    let battery = inspect_battery();
    let performance = inspect_performance();
    let mut charging = inspect_charging(&battery);
    let display = inspect_display();

    if let Some(object) = charging.diagnostics.as_object_mut() {
        object.insert(
            "tlp_battery_plugin_diagnostic".to_string(),
            detect_tlp_battery_plugin(),
        );
    }

    json!({
        "version": SCHEMA_VERSION,
        "battery": battery.diagnostics,
        "performance": performance.diagnostics,
        "charging": charging.diagnostics,
        "display": display.diagnostics
    })
}

// Battery

fn find_battery_device() -> Option<PathBuf> {
    directory_entries(Path::new("/sys/class/power_supply"))
        .into_iter()
        .filter(|path| {
            path.file_name()
                .and_then(|name| name.to_str())
                .map(|name| name.starts_with("BAT"))
                .unwrap_or(false)
                && path.is_dir()
        })
        .next()
}

fn battery_time_remaining_minutes(status: &str, battery: &Path) -> Option<i64> {
    if let (Some(now), Some(full), Some(power)) = (
        read_float(&battery.join("energy_now")),
        read_float(&battery.join("energy_full")),
        read_float(&battery.join("power_now")),
    ) {
        if power > 0.0 {
            let hours = if status.eq_ignore_ascii_case("charging") {
                if full > now {
                    (full - now) / power
                } else {
                    return None;
                }
            } else if status.eq_ignore_ascii_case("discharging") {
                now / power
            } else {
                return None;
            };

            if hours.is_finite() && hours > 0.0 {
                return Some((hours * 60.0).round().max(1.0) as i64);
            }
        }
    }

    if let (Some(now), Some(full), Some(current)) = (
        read_float(&battery.join("charge_now")),
        read_float(&battery.join("charge_full")),
        read_float(&battery.join("current_now")),
    ) {
        if current > 0.0 {
            let hours = if status.eq_ignore_ascii_case("charging") {
                if full > now {
                    (full - now) / current
                } else {
                    return None;
                }
            } else if status.eq_ignore_ascii_case("discharging") {
                now / current
            } else {
                return None;
            };

            if hours.is_finite() && hours > 0.0 {
                return Some((hours * 60.0).round().max(1.0) as i64);
            }
        }
    }

    None
}

fn inspect_battery() -> BatteryInfo {
    let Some(battery) = find_battery_device() else {
        return BatteryInfo {
            present: false,
            device: None,
            status: json!({ "present": false }),
            diagnostics: json!({
                "present": false,
                "selected_device": null,
                "message": "No BAT* power-supply device was found."
            }),
        };
    };

    let name = battery
        .file_name()
        .and_then(|value| value.to_str())
        .unwrap_or("unknown");
    let status_text =
        read_trimmed(&battery.join("status")).unwrap_or_else(|| "Unknown".to_string());
    let capacity = read_integer(&battery.join("capacity"));
    let manufacturer = read_trimmed(&battery.join("manufacturer"));
    let model_name = read_trimmed(&battery.join("model_name"));
    let cycle_count = read_integer(&battery.join("cycle_count"));
    let time_remaining = battery_time_remaining_minutes(&status_text, &battery);

    let energy_full_design_uwh = read_integer(&battery.join("energy_full_design"));
    let energy_full_uwh = read_integer(&battery.join("energy_full"));
    let energy_now_uwh = read_integer(&battery.join("energy_now"));
    let power_now_uw = read_integer(&battery.join("power_now"));

    let status = json!({
        "present": true,
        "device": name,
        "status": status_text,
        "capacity": capacity,
        "time_remaining_minutes": time_remaining
    });

    let diagnostics = json!({
        "present": true,
        "selected_device": battery,
        "device_name": name,
        "status": status_text,
        "capacity": capacity,
        "time_remaining_minutes": time_remaining,
        "manufacturer": manufacturer,
        "model_name": model_name,
        "cycle_count": cycle_count,
        "energy_full_design_mwh": energy_full_design_uwh.map(|value| value / 1000),
        "energy_full_mwh": energy_full_uwh.map(|value| value / 1000),
        "energy_now_mwh": energy_now_uwh.map(|value| value / 1000),
        "power_now_mw": power_now_uw.map(|value| value / 1000),
        "sysfs_units": {
            "energy": "uWh",
            "power": "uW"
        },
        "interfaces": {
            "charge_types": file_exists(&battery.join("charge_types")),
            "charge_control_start_threshold": file_exists(&battery.join("charge_control_start_threshold")),
            "charge_control_end_threshold": file_exists(&battery.join("charge_control_end_threshold")),
            "charge_start_threshold": file_exists(&battery.join("charge_start_threshold")),
            "charge_stop_threshold": file_exists(&battery.join("charge_stop_threshold"))
        }
    });

    BatteryInfo {
        present: true,
        device: Some(battery),
        status,
        diagnostics,
    }
}

// Performance

fn inspect_performance() -> PerformanceInfo {
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
        CommandResult {
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
            CommandResult {
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

fn tlp_is_active() -> bool {
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

fn normalize_performance_option(value: &str) -> String {
    match value {
        "power-saver" | "powersave" | "power_save" | "low-power" => "power-saving".to_string(),
        "balanced" | "balance_power" | "balance_performance" => "balanced".to_string(),
        "performance" => "performance".to_string(),
        other => other.to_string(),
    }
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

// Performance writes

fn handle_performance_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery performance get|set <profile>".to_string())?;

    match action {
        "get" => {
            let info = inspect_performance();

            Ok(json!({
                "version": SCHEMA_VERSION,
                "success": true,
                "performance": info.status
            }))
        }
        "set" => {
            let requested = args.get(1).map(String::as_str).ok_or_else(|| {
                "Usage: velox-battery performance set <power-saving|balanced|performance>"
                    .to_string()
            })?;

            set_performance(requested)
        }
        _ => Err("Usage: velox-battery performance get|set <profile>".to_string()),
    }
}

fn set_performance(requested: &str) -> Result<Value, String> {
    let profile = normalize_requested_performance(requested)?;
    let info = inspect_performance();

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

            match interface {
                "tlp-pd" => {
                    let tlp_profile = profile_to_tlp_profile(&profile);
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
                    let tlp_profile = profile_to_tlp_profile(&profile);
                    let args = ["-n", "tlp", tlp_profile];
                    let output = run_command("sudo", &args);

                    if !output.success {
                        return Err(format_privileged_command_failure(
                            &["sudo", &args[0], &args[1], &args[2]],
                            &output,
                        ));
                    }
                }
                other => {
                    return Err(format!("TLP selected an unsupported interface: {other}"));
                }
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
        "native" => return set_native_performance(&profile),
        other => return Err(format!("Unsupported performance backend selected: {other}")),
    }

    let after = inspect_performance();

    Ok(json!({
        "version": SCHEMA_VERSION,
        "success": true,
        "requested": profile,
        "result": after.status
    }))
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

fn set_native_performance(profile: &str) -> Result<Value, String> {
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

    fs::write(current_path, requested_native).map_err(|error| {
        format!(
            "Failed to write `{requested_native}` to {}: {error}",
            current_path.display()
        )
    })?;

    Ok(json!({
        "version": SCHEMA_VERSION,
        "success": true,
        "requested": profile,
        "backend": "native",
        "current": read_trimmed(current_path)
    }))
}

fn format_command_failure(program: &str, args: &[&str], result: &CommandResult) -> String {
    let command = std::iter::once(program)
        .chain(args.iter().copied())
        .collect::<Vec<_>>()
        .join(" ");

    let detail = if !result.stderr.is_empty() {
        result.stderr.clone()
    } else if !result.stdout.is_empty() {
        result.stdout.clone()
    } else {
        format!("command failed with exit code {:?}", result.exit_code)
    };

    format!("{command} failed: {detail}")
}

fn format_privileged_command_failure(args: &[&str], result: &CommandResult) -> String {
    let command = args.join(" ");

    let detail = if !result.stderr.is_empty() {
        result.stderr.clone()
    } else if !result.stdout.is_empty() {
        result.stdout.clone()
    } else {
        format!("command failed with exit code {:?}", result.exit_code)
    };

    if result.stderr.contains("a password is required")
        || result.stderr.contains("may not run")
        || result.stderr.contains("not allowed")
    {
        return format!(
            "{command} is not authorized for passwordless execution. This will be handled by the Velox-Q privilege setup in the later sudoers/installation phase."
        );
    }

    format!("{command} failed: {detail}")
}

// Charging

fn inspect_charging(battery: &BatteryInfo) -> ChargingInfo {
    let Some(device) = battery.device.as_deref() else {
        return ChargingInfo {
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
                "reason": "No battery device exists."
            }),
        };
    };

    let charge_types = read_trimmed(&device.join("charge_types"));
    let has_charge_control_start = file_exists(&device.join("charge_control_start_threshold"));
    let has_charge_control_end = file_exists(&device.join("charge_control_end_threshold"));
    let has_charge_start = file_exists(&device.join("charge_start_threshold"));
    let has_charge_stop = file_exists(&device.join("charge_stop_threshold"));

    let has_any_control = charge_types.is_some()
        || has_charge_control_start
        || has_charge_control_end
        || has_charge_start
        || has_charge_stop;

    let tlp_present = command_exists("tlp");
    let tlp_active = tlp_present && tlp_is_active();

    let backend = if tlp_active && has_any_control {
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
            "tlp_active": tlp_active,
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

fn detect_tlp_battery_plugin() -> Value {
    if !command_exists("tlp-stat") {
        return json!({
            "available": false,
            "reason": "tlp-stat was not found."
        });
    }

    let result = run_command("tlp-stat", &["-b"]);

    if !result.success {
        return json!({
            "available": false,
            "reason": "tlp-stat -b failed.",
            "stdout": result.stdout,
            "stderr": result.stderr,
            "exit_code": result.exit_code
        });
    }

    let plugin = result.stdout.lines().find_map(|line| {
        line.trim()
            .strip_prefix("Plugin:")
            .map(|value| value.trim().to_string())
    });

    let supported_features = result.stdout.lines().find_map(|line| {
        line.trim()
            .strip_prefix("Supported features:")
            .map(|value| value.trim().to_string())
    });

    json!({
        "available": true,
        "plugin": plugin,
        "supported_features": supported_features,
        "stdout": result.stdout
    })
}

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

// Charging writes

fn handle_charge_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery charge get|set <mode>".to_string())?;

    match action {
        "get" => {
            let battery = inspect_battery();
            let charging = inspect_charging(&battery);

            Ok(json!({
                "version": SCHEMA_VERSION,
                "success": true,
                "charging": charging.status
            }))
        }
        "set" => {
            let requested = args
                .get(1)
                .map(String::as_str)
                .ok_or_else(|| "Usage: velox-battery charge set <conserve|full>".to_string())?;

            set_charge(requested)
        }
        _ => Err("Usage: velox-battery charge get|set <mode>".to_string()),
    }
}

fn set_charge(requested: &str) -> Result<Value, String> {
    let mode = match requested {
        "conserve" => "conserve",
        "full" => "full",
        _ => {
            return Err(format!(
                "Unsupported charge mode: {requested}. Valid modes are conserve and full."
            ));
        }
    };

    let battery = inspect_battery();

    if !battery.present {
        return Err("Cannot change charging behavior because no battery was detected.".to_string());
    }

    let charging = inspect_charging(&battery);

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
        "native" => return set_native_charge(mode, battery.device.as_deref()),
        other => return Err(format!("Unsupported charging backend selected: {other}")),
    }

    let after_battery = inspect_battery();
    let after = inspect_charging(&after_battery);

    Ok(json!({
        "version": SCHEMA_VERSION,
        "success": true,
        "requested": mode,
        "result": after.status
    }))
}

fn set_native_charge(mode: &str, battery: Option<&Path>) -> Result<Value, String> {
    let Some(device) = battery else {
        return Err("No battery device is available.".to_string());
    };

    if !device.join("charge_types").exists() {
        return Err(
            "Native charging control is detected, but no supported generic write method has been implemented for this interface."
                .to_string(),
        );
    }

    Err(format!(
        "Native charging backend cannot yet apply `{mode}` to {}.",
        device.display()
    ))
}

// Display

fn inspect_display() -> DisplayInfo {
    if !command_exists("hyprctl") {
        return unavailable_display("hyprctl was not found.");
    }

    let result = run_command("hyprctl", &["-j", "monitors", "all"]);

    if !result.success {
        return unavailable_display(&format!(
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
        return unavailable_display("Hyprland returned no monitors.");
    }

    let Some(monitor) = select_display_monitor(&monitors) else {
        return unavailable_display("No suitable active monitor was found.");
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
            "selection_strategy": "Prefer active internal-panel connectors such as eDP-/LVDS-/DSI-, otherwise prefer the focused active monitor, then the first active monitor.",
            "write_method": "hyprctl eval with hl.monitor({ output, mode })"
        }),
    }
}

fn unavailable_display(reason: &str) -> DisplayInfo {
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

fn select_display_monitor(monitors: &[Value]) -> Option<&Value> {
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
        array
            .iter()
            .filter_map(Value::as_str)
            .map(str::to_string)
            .collect::<Vec<_>>()
    } else if let Some(text) = monitor.get("availableModes").and_then(Value::as_str) {
        text.split_whitespace()
            .map(str::to_string)
            .collect::<Vec<_>>()
    } else {
        Vec::new()
    };

    let prefix = if width > 0 && height > 0 {
        format!("{width}x{height}@")
    } else {
        String::new()
    };

    let mut rates = modes
        .iter()
        .filter(|mode| prefix.is_empty() || mode.starts_with(&prefix))
        .filter_map(|mode| parse_refresh_from_mode(mode))
        .collect::<Vec<_>>();

    rates.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    rates.dedup_by(|a, b| (*a - *b).abs() < 0.001);
    rates
}

fn parse_refresh_from_mode(mode: &str) -> Option<f64> {
    let (_, refresh) = mode.split_once('@')?;
    refresh.trim_end_matches("Hz").trim().parse().ok()
}

// Display writes

fn handle_display_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery display get|set <refresh>".to_string())?;

    match action {
        "get" => {
            let display = inspect_display();

            Ok(json!({
                "version": SCHEMA_VERSION,
                "success": true,
                "display": display.status
            }))
        }
        "set" => {
            let requested = args
                .get(1)
                .ok_or_else(|| "Usage: velox-battery display set <refresh>".to_string())?;

            let refresh = requested
                .parse::<f64>()
                .map_err(|_| format!("Invalid refresh rate: {requested}"))?;

            set_display_refresh(refresh)
        }
        _ => Err("Usage: velox-battery display get|set <refresh>".to_string()),
    }
}

fn set_display_refresh(requested: f64) -> Result<Value, String> {
    if !requested.is_finite() || requested <= 0.0 {
        return Err("Refresh rate must be a positive number.".to_string());
    }

    let display = inspect_display();

    let available = display
        .status
        .get("available")
        .and_then(Value::as_bool)
        .unwrap_or(false);

    if !available {
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

    let matched = options
        .iter()
        .filter_map(Value::as_f64)
        .find(|rate| (*rate - requested).abs() < 0.01);

    let refresh = matched.ok_or_else(|| {
        format!("Refresh rate {requested} is not available for {output} at {resolution}.")
    })?;

    let mode = format!("{resolution}@{refresh:.2}Hz");
    let lua = format!("hl.monitor({{ output = \"{output}\", mode = \"{mode}\" }})");

    let result = run_command("hyprctl", &["eval", &lua]);

    if !result.success {
        return Err(format_command_failure("hyprctl", &["eval", &lua], &result));
    }

    let after = inspect_display();

    Ok(json!({
        "version": SCHEMA_VERSION,
        "success": true,
        "requested": refresh,
        "output": output,
        "mode": mode,
        "result": after.status
    }))
}
