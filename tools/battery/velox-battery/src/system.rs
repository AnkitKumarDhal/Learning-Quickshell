use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Debug, Clone)]
pub struct CommandResult {
    pub success: bool,
    pub stdout: String,
    pub stderr: String,
    pub exit_code: Option<i32>,
}

pub fn run_command(program: &str, args: &[&str]) -> CommandResult {
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

pub fn executable_in_path(program: &str) -> Option<PathBuf> {
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
            .map(|metadata| metadata.permissions().mode() & 0o111 != 0)
            .unwrap_or(false)
    }

    #[cfg(not(unix))]
    {
        true
    }
}

pub fn command_exists(program: &str) -> bool {
    executable_in_path(program).is_some()
}

pub fn command_path(program: &str) -> Option<String> {
    executable_in_path(program).map(|path| path.to_string_lossy().into_owned())
}

pub fn systemctl_active(unit: &str) -> bool {
    run_command("systemctl", &["is-active", "--quiet", unit]).success
}

pub fn read_trimmed(path: &Path) -> Option<String> {
    fs::read_to_string(path)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}

pub fn read_integer(path: &Path) -> Option<i64> {
    read_trimmed(path)?.parse().ok()
}

pub fn read_float(path: &Path) -> Option<f64> {
    read_trimmed(path)?.parse().ok()
}

pub fn file_exists(path: &Path) -> bool {
    path.exists()
}

pub fn directory_entries(path: &Path) -> Vec<PathBuf> {
    let mut entries = fs::read_dir(path)
        .ok()
        .into_iter()
        .flat_map(|dir| dir.filter_map(Result::ok))
        .map(|entry| entry.path())
        .collect::<Vec<_>>();

    entries.sort();
    entries
}

pub fn dedupe_sorted(values: impl IntoIterator<Item = String>) -> Vec<String> {
    values
        .into_iter()
        .collect::<std::collections::BTreeSet<_>>()
        .into_iter()
        .collect()
}

pub fn format_command_failure(program: &str, args: &[&str], result: &CommandResult) -> String {
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

pub fn format_privileged_command_failure(args: &[&str], result: &CommandResult) -> String {
    let command = args.join(" ");

    if result.stderr.contains("a password is required")
        || result.stderr.contains("may not run")
        || result.stderr.contains("not allowed")
    {
        return format!(
            "{command} is not authorized for passwordless execution. This will be handled by the Velox-Q privilege setup in the later sudoers/installation phase."
        );
    }

    let detail = if !result.stderr.is_empty() {
        result.stderr.clone()
    } else if !result.stdout.is_empty() {
        result.stdout.clone()
    } else {
        format!("command failed with exit code {:?}", result.exit_code)
    };

    format!("{command} failed: {detail}")
}
