---
layout: post
title: "A simple way to collaborate with Python developers that do not use Emacs"
tags: emacs vscode python development
excerpt: "In this post I'll share some tips to make it easier to setup a (Unix-based) Python development environment for Emacs and VSCode users."
---

The more you use Emacs, the more you feel uncomfortable when you have
to write something outside it. This is even more true when writing
code. Some months ago I switched to `lsp-mode`, a client for the
Language Server Protocol that aims to provide IDE-like experience in
Emacs. To me, using `lsp-mode` has several advantages, including the
ability to quickly write, test and debug small snippets of code
without even touching the mouse.

However, I recognize that anyone has its favourite IDE when it comes
to writing code. I also understand that maybe using Emacs is not a
priority to all of us. As an example, the favourite IDE of some of my
colleagues happens to be Visual Studio Code. To stay productive, we
need to be able to develop in the same environment using different
(and potentially conflicting) setups.

In this post I'll share some **tips** to make it easier to setup a
**collaborative** (Unix-based) **Python development** environment.

## The typical Python development environment

Python is a very appealing solution when software needs to be
developed rapidly and there are no particular hardware requirements or
constraints. Complex operations can be done concisely, and there are
libraries for pretty much anything. To use a function that is not
provided by the standard library, we just need to install an external
package running `pip install pkg_name` and then we are ready to go.

To keep the system clean, and to avoid dependency conflicts between
multiple projects, _virtual environments_ are used. Each virtual
environment (or simply _venv_) is a directory tree that contains a
Python installation, plus a number of additional packages. To create a
venv, it is only required to type in the terminal the command `python
-m venv venv_name`. To use it instead of the global Python
installation, its enough to enter it and source the terminal with the
command `source bin/activate`.

Virtual environments are the key to make sure that each Python project
is self contained, but sometimes a project relies on a number of
external dependencies or binaries that need to be available
system-wide. To accomodate for this, several build systems can be
used. One of the most common is **GNU make**. `make` is relevant for a
number of historical reasons, but most importantly, it fits nicely in
a Unix environment, as it can be used to run directly shell
commands. Many large projects use it extensively, as it enables an end
user to build and install a package without knowing the details of how
that is done.

In our typical development environment we use `make` to setup, build,
execute and test most of the projects. However, we do not use the same
set of tools to code. The ones using VS Code can take advantage of
utils and extensions it provides to set current Python venv and use
the makefiles, while Emacs users need some additional
configuration. This is not really an issue, however, we have to ensure
**the additional configuration files introduced in the repository
don't cause conflicts to each other** (i.e., Emacs configuration files
must be transparent to VS Code and viceversa).

## Emacs, lsp-mode and Python virtual environments

Before going into the details of the setup, I'll talk a little bit
about how Emacs can be transformed into an IDE using `lsp-mode`,
touching only the key points. If you already know how to setup an
Emacs IDE, the following can be skipped.

To act as an IDE, Emacs needs some extensions. There are many packages
that can be used to do that; I use `lsp-mode`. At high level, it is a
client able to interact with a backend server via asynchronous calls
using the Language Server Procol. The idea is that we can support many
different languages by simply replacing the backend server, and thus
have a configuration that is not language-specific. This basically
means we have to provide a server to Emacs whenever a Python source
file in our project is read into a buffer. Anyway, unlike a
traditional IDE, Emacs by itself is not aware of what a project is,
and thus we have to send it some updates each time we open, close or
switch to project-related file. If you think about it, IDEs like VS
Code or IntelliJ are built on the concept of project, to which they
usually assign the whole window. A good way to address this problem is
to use environment variables, which are accessible to Emacs through
the `getenv` function. To cut a long story short, I do this using
`direnv`. This allows me to automatically load/unload some environment
variables each time I open a file, kill or switch to a buffer.

In its simplicity, `direnv` is a fantastic tool. It offers many
standard library function, including some to configure and activate a
Python layout. `direnv` checks for the existence of an `.envrc` file
inside the root project directory each time the directory is opened,
and if the file exists, it is loaded and all the environment exported
variables are made available to the current shell. The key point is
that this happens only if the `.envrc` file is authorized by the user.


## Project setup

The idea is that Emacs and non-Emacs users can use two slightly
different configurations for the same Python project:
- Emacs users rely on `direnv` to setup the local development
  environment, and use the `make` build system for anything else;
- non-Emacs users solely rely on the `make` build system.

The first necessity is that both configurations target the same
virtual environment. 

To create a venv with `direnv`, the Emacs user is required to create
the `.envrc` file (in the root project directory), and add `layout
python python3` as the first line. Running the command `direnv allow`
immediately causes the `.envrc` file to be loaded, and the Python3
layout to be created. The venv is by default created in the
`.direnv/python-$(VERSION)` folder, and activated each time the root
project directory is opened.

Non-Emacs user create the venv using a Makefile rule. We only
need to ensure the venv path matches the default one used by
direnv. To do that, we declare in the makefile the variable `VENVNAME
:= $(subst P,p,$(subst $(space),-,$(shell python3 --version)))`, where
`space` is the literal `$() $()`. To create the venv, the non-Emacs
user can run the recipe `install`, defined as:

```make
install:
	test -d $(VENV) || $(VIRTUALENV) $(VENV)
```
where `VIRTUALENV` is defined as `VIRTUALENV := python3 -m venv .direnv/$(VENVNAME)
`

### Python requirements and app execution

At this point both the Emacs and non-Emacs users are working in the
same venv. The only difference we have to keep in mind is that the
Emacs user's venv is activated by default.

Now we have to provide a method to install Python requirements. To
avoid confusion, the `install` rule can be reused, adding to the
recipe the required steps:

```make
install: $(REQUIREMENTS)
	test -d $(VENV) || $(VIRTUALENV) $(VENV)
	$(PIP) $@ --upgrade pip
	$(PIP) $@ -r $<
```

where `REQUIREMENTS` is the file `$ROOT_DIR/requirements.txt`.
Running `make install` doesn't cause any problem to the Emacs user
since there is no modification to the Python executable path.

To run the application we provide the `run` recipe, which has
`install` as a prerequisite (if requirements.txt is updated then the
newly introduced requirements will automatically be installed each
time the app is executed).

```make
run: install
	@ echo $(PYTHON)
	$(PYTHON) $(APP)
```
`APP` is defined as `APP := app_launcher.py`.

As a final step, we can provide a rule to clean the venv when
needed. This is done by `clean`, defined as:

```make
clean:
	@ rm -rf $(VENV)
	@ find . -path '*/__pycache__/*' -delete
	@ find . -type d -name '__pycache__' -delete
```

### System-wide dependencies and $PATH

Usually a project relies on some libraries or binaries that need to be
available system-wide. However, I try to keep my system as close to a
vanilla distribution as much as I can, trying to avoid the dependency
hell. What I typically do is install all the required binaries in the
directory `$ROOT_DIR/bin`, which is then added to the `$PATH`
environment variable. This can be done easily using `direnv` with
`PATH_add`, a function that prepends an input path to the `PATH`
environment variable. This is really a killer feature, as `direnv` not
only adds the input path when the project is opened, but it also
removes it when the project is closed, keeping my global `PATH` clean.

Anyway, I recommend to install software dependencies using Makefile
rules. It is a bad practice to use `direnv` to perform time consuming
operations. Not only if `direnv` takes too much Emacs may hang, but
also other programs might crash (e.g., git might crash if different
commands are executed simultaneously, causing the local content to be
corrupted). Therefore, I use `direnv` only to create the project
directory structure, add paths to the global environment, and check if
a software dependency is available (sending a message to the user
otherwise). This is done using the function `has`, as detailed in the
following:

```bash
# add bin to path
PATH_add  bin

# required dependencies
binary_deps+=( "dep1" "dep2" "dep3")

# warn the user if a dependency is missing
for dep in ${binary_deps[@]}; do
    if ! has $dep; then
	echo "missing dependency '${dep}', to install it run 'make install_binaries'"
    fi
done

```

Non-Emacs users can export `bin` to the global path adding to the
Makefile the following line.

```bash
export PATH = $(shell printenv PATH):$(ROOT_DIR)/$(LOCAL_BINARIES)
```

The last change won't affect `direnv` users, as it only adds a
duplicate to the PATH. There also other solutions (e.g., exploiting
the functionality provided by the dynamic linker), but this is the
most straightforward to me.

### .envrc

The final version of the `.envrc` file.

```bash
# create a python3 layout
layout python python3

# create directory to store the local binaries and add it to the path
mkdir -p bin
PATH_add  bin

# required dependencies
binary_deps+=( "dep1" "dep2" "dep3")

# warn the user if a dependency is missing
for dep in ${binary_deps[@]}; do
    if ! has $dep; then
	# (do not use the .envrc to install binaries, use Makefile instead...
	#  ... if the .envrc blocks, other tools might hang or break, e.g. emacs or git)
	echo "missing dependency '${dep}', to install it run 'make install_binaries'"	
    fi
done
```

### Makefile

The final version of the `Makefile`.

```make
.PHONY: all clean remove_binaries install_binaries install run

# literal to define whitespace
space=$() $()

# make the venv path name matches the default name used by direnv
VENVNAME       := $(subst P,p,$(subst $(space),-,$(shell python3 --version)))
VIRTUALENV     := python3 -m venv .direnv/$(VENVNAME)
ROOT_DIR       := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
VENV           := $(strip $(ROOT_DIR)/.direnv/$(VENVNAME))
ACTIVATE       := $(VENV)/bin/activate
PYTHON         := $(VENV)/bin/python
PIP            := $(PYTHON) -m pip

SHELL          := /bin/bash

LOCAL_BINARIES := bin

REQUIREMENTS   := requirements.txt      # insert here your python requirements
APP            := app_launcher.py	# this file is used as the main app driver

# add ./bin to the path
export PATH = $(shell printenv PATH):$(ROOT_DIR)/$(LOCAL_BINARIES)

all: run				# install python deps run the project

clean:					# clean python dependencies
	@ rm -rf $(VENV)
	@ find . -path '*/__pycache__/*' -delete
	@ find . -type d -name '__pycache__' -delete

remove_binaries:			# remove local binaries
	@ rm -rf $(LOCAL_BINARIES)

install_binaries:			# use this rule to install local binaries in ./bin
	@ mkdir -p $(ROOT_DIR)/$(LOCAL_BINARIES)
	@ echo "Installing required binaries locally..."
	@ echo "...DONE"
	@ echo "Remember to ADD $(ROOT_DIR)/bin to the current PATH" \
		"**ONLY if you are NOT USING direnv**." \
		"To do that run 'make export_path'"

install: $(REQUIREMENTS)		# install python venv (with all required packages)
	test -d $(VENV) || $(VIRTUALENV) $(VENV)
	$(PIP) $@ --upgrade pip
	$(PIP) $@ -r $<

run: install 				# run project
	@ echo $(PYTHON)
	$(PYTHON) $(APP)
```
