use serde_json::{Value, json};
use std::path::{Path, PathBuf};

use crate::system::{directory_entries, file_exists, read_float, read_integer, read_trimmed};

pub struct BatteryInfo {
    pub present: bool,
    pub device: Option<PathBuf>,
    pub status: Value,
    pub diagnostics: Value,
}

pub fn inspect() -> BatteryInfo {
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

    BatteryInfo {
        present: true,
        device: Some(battery.clone()),
        status: json!({
            "present": true,
            "device": name,
            "status": status_text,
            "capacity": capacity,
            "time_remaining_minutes": time_remaining
        }),
        diagnostics: json!({
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
        }),
    }
}

fn find_battery_device() -> Option<PathBuf> {
    directory_entries(Path::new("/sys/class/power_supply"))
        .into_iter()
        .find(|path| {
            path.file_name()
                .and_then(|name| name.to_str())
                .map(|name| name.starts_with("BAT"))
                .unwrap_or(false)
                && path.is_dir()
        })
}

fn battery_time_remaining_minutes(status: &str, battery: &Path) -> Option<i64> {
    if let (Some(now), Some(full), Some(power)) = (
        read_float(&battery.join("energy_now")),
        read_float(&battery.join("energy_full")),
        read_float(&battery.join("power_now")),
    ) && power > 0.0
    {
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

    if let (Some(now), Some(full), Some(current)) = (
        read_float(&battery.join("charge_now")),
        read_float(&battery.join("charge_full")),
        read_float(&battery.join("current_now")),
    ) && current > 0.0
    {
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

    None
}
