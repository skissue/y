use assert_cmd::Command;
use tempfile::TempDir;

fn crack(dir: &std::path::Path) -> Command {
    let mut cmd = Command::cargo_bin("crack").unwrap();
    cmd.arg("--dir").arg(dir);
    cmd
}

#[test]
fn full_start_stop_toggle_sequence() {
    let dir = TempDir::new().unwrap();

    crack(dir.path()).args(["work", "start"]).assert().success();
    crack(dir.path()).args(["work", "stop"]).assert().success();
    crack(dir.path()).args(["work", "toggle"]).assert().success();
    crack(dir.path()).args(["work", "toggle"]).assert().success();

    let body = std::fs::read_to_string(dir.path().join("work.csv")).unwrap();
    let lines: Vec<&str> = body.lines().collect();
    assert_eq!(lines[0], "start,end");
    assert_eq!(lines.len(), 3, "expected header + 2 closed rows, got {body:?}");
    for row in &lines[1..] {
        let cols: Vec<&str> = row.split(',').collect();
        assert_eq!(cols.len(), 2, "row should have 2 cols: {row:?}");
        assert!(!cols[0].is_empty(), "start should be set: {row:?}");
        assert!(!cols[1].is_empty(), "end should be set: {row:?}");
    }
}

#[test]
fn invalid_task_name_exits_nonzero() {
    let dir = TempDir::new().unwrap();
    crack(dir.path())
        .args(["bad name", "start"])
        .assert()
        .failure();
}

#[test]
fn start_when_already_running_is_noop() {
    let dir = TempDir::new().unwrap();
    crack(dir.path()).args(["t", "start"]).assert().success();
    let before = std::fs::read_to_string(dir.path().join("t.csv")).unwrap();
    crack(dir.path()).args(["t", "start"]).assert().success();
    let after = std::fs::read_to_string(dir.path().join("t.csv")).unwrap();
    assert_eq!(before, after);
}
