use serde_json::{Value, json};
use std::env;

mod battery;
mod charging;
mod display;
mod performance;
mod system;

const SCHEMA_VERSION: u32 = 1;

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

// Reports

fn build_status() -> Value {
    let battery = battery::inspect();
    let performance = performance::inspect();
    let charging = charging::inspect(&battery);
    let display = display::inspect();

    json!({
        "version": SCHEMA_VERSION,
        "battery": battery.status,
        "performance": performance.status,
        "charging": charging.status,
        "display": display.status
    })
}

fn build_capabilities() -> Value {
    let battery = battery::inspect();
    let performance = performance::inspect();
    let charging = charging::inspect(&battery);
    let display = display::inspect();

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
    let battery = battery::inspect();
    let performance = performance::inspect();
    let mut charging = charging::inspect(&battery);
    let display = display::inspect();

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

// Performance

fn handle_performance_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery performance get|set <profile>".to_string())?;

    match action {
        "get" => Ok(json!({
            "version": SCHEMA_VERSION,
            "success": true,
            "performance": performance::inspect().status
        })),
        "set" => {
            let requested = args.get(1).map(String::as_str).ok_or_else(|| {
                "Usage: velox-battery performance set <power-saving|balanced|performance>"
                    .to_string()
            })?;

            performance::set(requested)
        }
        _ => Err("Usage: velox-battery performance get|set <profile>".to_string()),
    }
}

// Charging

fn handle_charge_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery charge get|set <mode>".to_string())?;

    match action {
        "get" => {
            let battery = battery::inspect();
            Ok(json!({
                "version": SCHEMA_VERSION,
                "success": true,
                "charging": charging::inspect(&battery).status
            }))
        }
        "set" => {
            let requested = args
                .get(1)
                .map(String::as_str)
                .ok_or_else(|| "Usage: velox-battery charge set <conserve|full>".to_string())?;

            let battery = battery::inspect();
            charging::set(requested, &battery)
        }
        _ => Err("Usage: velox-battery charge get|set <mode>".to_string()),
    }
}

// Display

fn handle_display_command(args: Vec<String>) -> Result<Value, String> {
    let action = args
        .first()
        .map(String::as_str)
        .ok_or_else(|| "Usage: velox-battery display get|set <refresh>".to_string())?;

    match action {
        "get" => Ok(json!({
            "version": SCHEMA_VERSION,
            "success": true,
            "display": display::inspect().status
        })),
        "set" => {
            let requested = args
                .get(1)
                .ok_or_else(|| "Usage: velox-battery display set <refresh>".to_string())?;

            let refresh = requested
                .parse::<f64>()
                .map_err(|_| format!("Invalid refresh rate: {requested}"))?;

            display::set(refresh)
        }
        _ => Err("Usage: velox-battery display get|set <refresh>".to_string()),
    }
}

fn detect_tlp_battery_plugin() -> Value {
    if !system::command_exists("tlp-stat") {
        return json!({
            "available": false,
            "reason": "tlp-stat was not found."
        });
    }

    let result = system::run_command("tlp-stat", &["-b"]);

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
