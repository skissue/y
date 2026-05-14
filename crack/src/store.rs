use crate::cli::Action;
use anyhow::{Context, Result, anyhow, bail};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

const HEADER: &str = "start,end";
const MAX_TASK_LEN: usize = 64;

#[derive(Debug)]
pub enum State {
    Stopped,
    Running { since: String },
}

#[derive(Debug)]
pub enum Outcome {
    Started { at: String },
    Stopped { at: String },
    AlreadyRunning { since: String },
    AlreadyStopped,
}

/// Reject anything that isn't a short, simple identifier.
pub fn validate_task(task: &str) -> Result<()> {
    if task.is_empty() {
        bail!("invalid task name: empty");
    }
    if task.len() > MAX_TASK_LEN {
        bail!("invalid task name: longer than {MAX_TASK_LEN} bytes");
    }
    if !task
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
    {
        bail!("invalid task name: must match [A-Za-z0-9_-]{{1,64}}");
    }
    Ok(())
}

pub fn task_path(dir: &Path, task: &str) -> PathBuf {
    dir.join(format!("{task}.csv"))
}

/// Inspect the file and decide whether the clock is currently running.
pub fn current_state(path: &Path) -> Result<State> {
    let body = match fs::read_to_string(path) {
        Ok(s) => s,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(State::Stopped),
        Err(e) => return Err(e).context("reading task file"),
    };

    let last = match last_data_line(&body) {
        Some(l) => l,
        None => return Ok(State::Stopped),
    };

    let mut parts = last.splitn(2, ',');
    let start = parts
        .next()
        .ok_or_else(|| anyhow!("malformed row: {last:?}"))?
        .trim();
    let end = parts
        .next()
        .ok_or_else(|| anyhow!("malformed row (no comma): {last:?}"))?
        .trim();

    if start.is_empty() {
        bail!("malformed row (empty start): {last:?}");
    }

    if end.is_empty() {
        Ok(State::Running {
            since: start.to_string(),
        })
    } else {
        Ok(State::Stopped)
    }
}

/// Apply the action against the file, using `now` as the clock.
pub fn apply(path: &Path, action: Action, now: &str) -> Result<Outcome> {
    let state = current_state(path)?;
    match (action, state) {
        (Action::Start, State::Stopped) | (Action::Toggle, State::Stopped) => {
            append_open_row(path, now)?;
            Ok(Outcome::Started {
                at: now.to_string(),
            })
        }
        (Action::Start, State::Running { since }) => Ok(Outcome::AlreadyRunning { since }),
        (Action::Stop, State::Running { .. }) | (Action::Toggle, State::Running { .. }) => {
            close_last_row(path, now)?;
            Ok(Outcome::Stopped {
                at: now.to_string(),
            })
        }
        (Action::Stop, State::Stopped) => Ok(Outcome::AlreadyStopped),
    }
}

// ---- internals ----

/// Last non-empty, non-header line of `body`, if any.
fn last_data_line(body: &str) -> Option<&str> {
    body.lines()
        .map(str::trim_end)
        .filter(|l| !l.is_empty() && *l != HEADER)
        .next_back()
}

fn append_open_row(path: &Path, now: &str) -> Result<()> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).context("creating output directory")?;
        }
    }

    let exists = path.exists();
    let mut f = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .context("opening task file")?;

    if !exists {
        writeln!(f, "{HEADER}").context("writing header")?;
    }
    writeln!(f, "{now},").context("writing open row")?;
    Ok(())
}

/// Rewrite the file with the last row's `end` filled in. Uses a temp file +
/// rename so a crash mid-write can't leave the CSV truncated.
fn close_last_row(path: &Path, now: &str) -> Result<()> {
    let body = fs::read_to_string(path).context("reading task file")?;
    let mut lines: Vec<String> = body.lines().map(str::to_string).collect();

    let idx = lines
        .iter()
        .rposition(|l| !l.trim().is_empty() && l.trim() != HEADER)
        .ok_or_else(|| anyhow!("no open row to close"))?;

    let row = lines[idx].trim_end().to_string();
    if !row.ends_with(',') {
        bail!("last row is not open: {row:?}");
    }
    lines[idx] = format!("{row}{now}");

    let mut out = lines.join("\n");
    out.push('\n');

    let tmp = path.with_extension("csv.tmp");
    fs::write(&tmp, out).context("writing temp file")?;
    fs::rename(&tmp, path).context("renaming temp file")?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::cli::Action;
    use tempfile::TempDir;

    // ---- task name validation ----

    #[test]
    fn validate_accepts_simple_names() {
        for ok in ["work", "deep_work", "p1", "a-b-c", "X", "0", "_"] {
            assert!(validate_task(ok).is_ok(), "should accept {ok:?}");
        }
    }

    #[test]
    fn validate_rejects_bad_names() {
        for bad in ["", " ", "has space", "with/slash", "dot.name", "uni¢ode", &"x".repeat(65)] {
            assert!(validate_task(bad).is_err(), "should reject {bad:?}");
        }
    }

    #[test]
    fn task_path_is_dir_plus_task_csv() {
        let p = task_path(std::path::Path::new("/tmp/out"), "work");
        assert_eq!(p, std::path::PathBuf::from("/tmp/out/work.csv"));
    }

    // ---- state on missing / empty file ----

    #[test]
    fn state_of_missing_file_is_stopped() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        assert!(matches!(current_state(&p).unwrap(), State::Stopped));
    }

    // ---- start ----

    #[test]
    fn start_when_stopped_creates_file_with_header_and_open_row() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        let outcome = apply(&p, Action::Start, "2026-05-13T10:00:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::Started { .. }));
        let body = std::fs::read_to_string(&p).unwrap();
        assert_eq!(body, "start,end\n2026-05-13T10:00:00+02:00,\n");
        assert!(matches!(current_state(&p).unwrap(), State::Running { .. }));
    }

    #[test]
    fn start_when_running_is_noop() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        apply(&p, Action::Start, "2026-05-13T10:00:00+02:00").unwrap();
        let before = std::fs::read_to_string(&p).unwrap();
        let outcome = apply(&p, Action::Start, "2026-05-13T10:30:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::AlreadyRunning { .. }));
        let after = std::fs::read_to_string(&p).unwrap();
        assert_eq!(before, after);
    }

    // ---- stop ----

    #[test]
    fn stop_when_running_closes_row() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        apply(&p, Action::Start, "2026-05-13T10:00:00+02:00").unwrap();
        let outcome = apply(&p, Action::Stop, "2026-05-13T11:00:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::Stopped { .. }));
        let body = std::fs::read_to_string(&p).unwrap();
        assert_eq!(
            body,
            "start,end\n2026-05-13T10:00:00+02:00,2026-05-13T11:00:00+02:00\n"
        );
        assert!(matches!(current_state(&p).unwrap(), State::Stopped));
    }

    #[test]
    fn stop_when_stopped_is_noop() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        let outcome = apply(&p, Action::Stop, "2026-05-13T10:00:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::AlreadyStopped));
        assert!(!p.exists());
    }

    // ---- toggle ----

    #[test]
    fn toggle_starts_when_stopped() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        let outcome = apply(&p, Action::Toggle, "2026-05-13T10:00:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::Started { .. }));
        assert!(matches!(current_state(&p).unwrap(), State::Running { .. }));
    }

    #[test]
    fn toggle_stops_when_running() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        apply(&p, Action::Start, "2026-05-13T10:00:00+02:00").unwrap();
        let outcome = apply(&p, Action::Toggle, "2026-05-13T11:00:00+02:00").unwrap();
        assert!(matches!(outcome, Outcome::Stopped { .. }));
        assert!(matches!(current_state(&p).unwrap(), State::Stopped));
    }

    // ---- multi-block sequence ----

    #[test]
    fn sequence_appends_blocks() {
        let dir = TempDir::new().unwrap();
        let p = task_path(dir.path(), "work");
        apply(&p, Action::Start, "2026-05-13T10:00:00+02:00").unwrap();
        apply(&p, Action::Stop, "2026-05-13T10:30:00+02:00").unwrap();
        apply(&p, Action::Start, "2026-05-13T11:00:00+02:00").unwrap();
        apply(&p, Action::Stop, "2026-05-13T11:45:00+02:00").unwrap();
        let body = std::fs::read_to_string(&p).unwrap();
        assert_eq!(
            body,
            "start,end\n\
             2026-05-13T10:00:00+02:00,2026-05-13T10:30:00+02:00\n\
             2026-05-13T11:00:00+02:00,2026-05-13T11:45:00+02:00\n",
        );
    }
}
