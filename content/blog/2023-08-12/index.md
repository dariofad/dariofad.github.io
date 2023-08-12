+++
title = "Sandboxing Zola: lightweight isolation of a static website generator"
date = 2023-08-12

[taxonomies]
tags = ["landlock", "zola", "sandbox", "environment", "file-system"]

[extra]
toc = true
comment = false
outdate_alert = false
+++

In this post I'll show how to sandbox Zola using Landlock, avoiding to
push confidential information (i.e., files and environment variables)
to your website.

<!-- more -->

## Intro

A while ago I decided to stop using Jekyll. The two main reasons for
this change are associated with the management of Ruby Gems and the
lack of updates to the Minima theme (e.g., dark mode). I really wanted
a single-binary static website generator, and after asking some
friends, I decided to use [Zola](https://www.getzola.org/).

Zola is super easy, and after a quick personalization of the template,
I was ready to deploy the website on GitHub Pages. The original idea
was to rely on Actions, however, I noticed some problems with the
scripts that were used by the community. The scripts looked _frail_,
and I was concerned that sooner or later something might break.

I didn't want to overcomplicate something so simple, and I didn't find
any practical advantage in using Actions. I thought: _I just want a
static website, and it should exactly work as it does locally_. So, I
opted for publishing the content directly from `/docs`. The dowside is
security, of course. Zola's code is open source and can be verified,
but what if there were unwanted bugs? What if I were to include
confidential resources in some pages and push without noticing? My
main concern was related to environment variables and local files, so
I decided to implement a little program to restrict the resources
available at website generation time.

In the following I'll explain how it works.

## Environment variables

I usually don't store secret tokens in environment variables, and when
I really need I use [direnv](https://direnv.net/), which permits to
edit the environment loading and unloading variables based on the
current directory. However, there may be other software running on the
workstation while building the website, so it is safer to constrain
them. The realization is simple, we only need to _drop_ some variables
before the website is generated. For that, we start from the array of
all the environment variables (`ENV_VARS` in the snipped below), then
create an array of variables which may be legitimately required by
Zola (`ENV_VAR_ALLOWLIST`). Finally, we unset every variable that
belongs to the first array but not to the second. A simple script like
the following can be used.

```bash
#!/bin/bash

ENV_VARS=( $(env | cut -d= -f1) )

ENV_VAR_ALLOWLIST=( DBUS_SESSION_BUS_ADDRESS DESKTOP_SESSION GDMSESSION \
                    GTK_IM_MODULE GTK_MODULES HOME LANG LANGUAGE LC_ADDRESS \
                    LC_ALL LC_IDENTIFICATION LC_MONETARY LC_NAME LC_NUMERIC \
                    LC_TIME LESSOPEN LOGNAME OLD_PWD PATH PWD SESSION_MANAGER \
                    SYSTEMD_EXEC_PID USER USERNAME XDG_CONFIG_DIRS \
                    XDG_CURRENT_DESKTOP XDG_MENU_PREFIX XDG_SESSION_DESKTOP \
                    XDG_SESSION_TYPE XMODIFIERS SHELL )

for v in ${ENV_VARS[@]}; do
    found=0
    for va in ${ENV_VAR_ALLOWLIST[@]}; do
	if [ $v == $va ]; then
	    found=1
	    break
	fi
    done
    if [ $found == 0 ]; then
	# unset variable v
	unset $v
    fi
done
```

## Files

Files are the biggest concern. The idea is that anything outside of
the website folder should not be read by the static generator at build
time. To enforce this condition we can use Landlock: an unprivileged,
stackable access control LSM available from version 5.13. Landlock is
very intuitive, it allows a process to restricts its privileges with a
single call from user space. After this operation is performed, the
set of privileges can only be further restricted (privileges cannot be
reclaimed). Again, the realization is simple, we just need a launcher
that restricts its privileges before Zola is executed. The only
requirement to obtain is the _policy_, or rather the list of
file-system resources the Zola binary needs to read/write/exec to
successfully produce the website. This list can be quickly generated
using `ldd` and `strace`, here is how it looks like on my workstation.

```json
{
    "read": [
	"/etc/ld.so.cache",
	"/lib64/ld-linux-x86-64.so.2",
	"/lib/x86_64-linux-gnu/libc.so.6",
	"/lib/x86_64-linux-gnu/libgcc_s.so.1",
	"/lib/x86_64-linux-gnu/libm.so.6",
	"/home/dariofad/.cargo/bin/zola",
	"."
    ],
    "write": [
	".",
	"/dev/null"
    ],
    "exec": [
	"/lib64/ld-linux-x86-64.so.2",	
	"/home/dariofad/.cargo/bin/zola"
    ]
}
```

What I really appreciate about Zola is that it only needs to access
the program interpreter and 3 libraries to work as intended. About the
launcher, it is implemented as a minimal Rust application called
`boxer`. It just:
1. reads the json policy using serde,
2. configures the appropriate Landlock ruleset,
3. calls Landlock enforcing the ruleset,
4. executes Zola with the input argument (i.e., `build` or `serve`).

The code is shown below.

```Rust
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
```

Putting all the pieces together, we just need to add a line to the
previous bash script, calling the `boxer` right after the unwanted
variables have been unset.

```Make
# spawn the sandboxer
(./boxer/target/debug/boxer --argument $1 --policy $2)
```

Argument `$1` is either `build` or `serve`, while argument `$2` is the
path to the json policy file.

Let's use a new Makefile phony target (`build`) to build our website!

```Make
.PHONY: build

POLICY := boxer/zola.json

_clean_website:
	$(info [*] Clean website)
	@rm -rf docs/*

build: _clean_website
	$(info [*] Unset environment variables & rebuild website)
	@./boxer/subshell.sh $@ $(POLICY)
```

Just in case you were wondering, we don't need to worry about the
execution of other targets potentially contained in the Makefile, as
by
[default](https://www.gnu.org/software/make/manual/html_node/Execution.html),
each target recipe line is executed in a new sub-shell (so environment
variables and sandboxing only affect the process that executes Zola).


## Availability

You can check the source of this pages to see how everything
works. [Here](https://github.com/dariofad/dariofad.github.io/blob/master/Makefile)
you can find the Makefile, and
[here](https://github.com/dariofad/dariofad.github.io/tree/master/boxer)
the sandboxer. You may also find convenient the `make serve` option,
which allows to write a new blog post without enforcing restrictions.

Thanks for reading.
