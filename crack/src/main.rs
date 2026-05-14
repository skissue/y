use anyhow::{Context, Result, bail};
use clap::Parser;
use std::path::PathBuf;
use std::process::ExitCode;

use crack::cli::Args;
use crack::store::{self, Outcome};
use crack::time;

fn main() -> ExitCode {
    let args = Args::parse();
    match run(args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e:#}");
            ExitCode::from(2)
        }
    }
}

fn run(args: Args) -> Result<()> {
    store::validate_task(&args.task)?;
    let dir = resolve_dir(args.dir)?;
    std::fs::create_dir_all(&dir).context("creating output directory")?;

    let path = store::task_path(&dir, &args.task);
    let now = time::now_rfc3339();
    let outcome = store::apply(&path, args.action, &now)?;

    match outcome {
        Outcome::Started { at } => println!("started {:?} at {at}", args.task),
        Outcome::Stopped { at } => println!("stopped {:?} at {at}", args.task),
        Outcome::AlreadyRunning { since } => {
            println!("{:?} already running since {since} (no-op)", args.task)
        }
        Outcome::AlreadyStopped => println!("{:?} already stopped (no-op)", args.task),
    }
    Ok(())
}

/// `--dir` if given, else $XDG_DATA_HOME/crack, else $HOME/.local/share/crack.
fn resolve_dir(explicit: Option<PathBuf>) -> Result<PathBuf> {
    if let Some(d) = explicit {
        return Ok(d);
    }
    if let Some(v) = std::env::var_os("XDG_DATA_HOME") {
        if !v.is_empty() {
            return Ok(PathBuf::from(v).join("crack"));
        }
    }
    if let Some(home) = std::env::var_os("HOME") {
        if !home.is_empty() {
            return Ok(PathBuf::from(home).join(".local/share/crack"));
        }
    }
    bail!("no output directory: pass --dir or set XDG_DATA_HOME or HOME");
}
