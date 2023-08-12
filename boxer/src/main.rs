use anyhow::{bail, Result};
use clap::Parser;
use landlock::{
    Access, AccessFs, PathBeneath, PathFd, Ruleset, RulesetAttr, RulesetCreatedAttr, RulesetStatus,
    ABI,
};
use serde::Deserialize;
use std::fs;
use std::process::{Command, Stdio};

#[derive(Deserialize, Debug)]
struct Policy {
    read: Vec<String>,
    write: Vec<String>,
    exec: Vec<String>,
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Args {
    #[clap(long = "argument", value_name = "ARG")]
    pub argument: String,

    #[clap(long = "policy", value_name = "FILE")]
    pub policy: String,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let pol: Policy = serde_json::from_str(&fs::read_to_string(args.policy)?)?;
    let abi = ABI::V2;

    let mut ruleset = Ruleset::new()
        .handle_access(AccessFs::from_all(abi))?
        .create()?;

    ruleset = ruleset.add_rule(PathBeneath::new(PathFd::new(".")?, Access::from_all(abi)))?;

    for path in &pol.read {
        let path_fd = PathFd::new(path)?;
        ruleset = ruleset.add_rule(PathBeneath::new(path_fd, AccessFs::from_read(abi)))?;
    }
    for path in &pol.write {
        let path_fd = PathFd::new(path)?;
        ruleset = ruleset.add_rule(PathBeneath::new(path_fd, Access::from_write(abi)))?;
    }
    for path in &pol.exec {
        let path_fd = PathFd::new(path)?;
        ruleset = ruleset.add_rule(PathBeneath::new(path_fd, AccessFs::Execute))?;
    }

    let status = ruleset.restrict_self()?;

    if status.ruleset == RulesetStatus::NotEnforced {
        bail!("Landlock not supported, upgrade kernel please");
    }

    Command::new("zola")
        .arg(args.argument)
        .stdout(Stdio::null())
        .spawn()?
        .wait()?;

    Ok(())
}
