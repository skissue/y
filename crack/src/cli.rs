use clap::{Parser, ValueEnum};
use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum Action {
    Start,
    Stop,
    Toggle,
}

/// Tiny CLI time tracker. One CSV per task in the output directory.
#[derive(Debug, Parser)]
#[command(name = "crack", version, about)]
pub struct Args {
    /// Task name. Must match `[A-Za-z0-9_-]{1,64}`.
    pub task: String,

    /// What to do with the clock for this task.
    pub action: Action,

    /// Output directory. Defaults to $XDG_DATA_HOME/crack
    /// or $HOME/.local/share/crack.
    #[arg(long, short)]
    pub dir: Option<PathBuf>,
}
