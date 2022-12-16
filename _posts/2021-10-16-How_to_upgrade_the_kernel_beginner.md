---
layout: post
title: "How to upgrade the Kernel (beginner)"
tags: beginner linux kernel build landlock
excerpt: "In this post I'll show you how easy it is to replace the Kernel of your distro to enable one of the latest LSM."
---

One of the latest modules available in the Linux Kernel is Landlock,
an unprivileged sandboxing mechanism that allows a process to confine
itself. Since it could be useful for one of my new projects, I decided
to try it out.  Landlock was merged into [Linux
5.13](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=17ae69aba89d). As
I wanted to test the latest version available, I needed a **Kernel
upgrade**. Contrary to what one might think, upgrading the Kernel with
a more recent version is really easy.

In this post I'll show you how to **build and install** the latest
**Kernel** version available to your system, possibly enabling the
Landlock LSM module.

## Upgrade

Before we begin, I'd like to remind you that we're not installing the
latest Kernel image via `apt` from the official repository of your
distribution, but from source files. Thus, I recommend installing a
VM, with at least 50 GB of dedicated storage (after the build, the
local folder containing the latest image occupies approximately 21
GB). The following procedure has been tested with Ubuntu 21.10.

### Source files and requirements

The first thing to do is to download the Kernel mainline version. You
can either do this from [The Linux Kernel
Archives](https://www.kernel.org/) or from
[Github](https://github.com/torvalds/linux). From terminal you run:

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15-rc5.tar.xz
tar -xvf linux-5.15-rc5.tar.xz
cd linux-5.15-rc5
```

To compile the kernel you need a minimal set of
[requirements](https://www.kernel.org/doc/html/v4.13/process/changes.html). The
version of each tool may vary between different platforms (based on
the architecture), in my case I just need the following:

```bash
sudo apt install \
	fakeroot \ 
	build-essential \
	ncurses-doc \
	libncurses-dev \
	xz-utils \
	libssl-dev \
	bc \
	flex \
	libelf-dev \
	bison
```

### Edit the build configuration

To configure the build we need to edit the content of the `.config`
configuration file. This is an automatically generated file that
should be changed only with the terminal-oriented `menuconfig`
configuration tool (you can start it running `make
menuconfig`). However, since we already have a valid configuration for
our VM saved at `/boot/config-$(uname -r)`, we can override `.config`
with its content. To do that run:

```bash
cp /boot/config-$(uname -r) .config
```

Notice that when you override `.config`, you're deleting the
configuration required by the components or modules that were added to
the Kernel repository after your running Kernel image was
created. This typically impacts he drivers added to support new
hardware. Anyway, it isn't a big problem: you can either use
`menuconfig` to specify the missing bits, or directly provide the
input at build time (from terminal, according to the default options).

Additionally, as we won't need to seal keys in a TPM using
[keyrings](https://man7.org/linux/man-pages/man7/keyrings.7.html), we
can edit `.config` setting the variable `CONFIG_SYSTEM_TRUSTED_KEYS`
to `""`. Also, we can comment out the line `CONFIG_DEBUG_INFO_BTF=y`,
as we won't need to debug eBPF programs.

Finally, if you want to activate Landlock LSM, edit the security
options setting the `CONFIG_LSM` variable to:

```make
CONFIG_LSM="lockdown,yama,integrity,apparmor,landlock"
```

### Compile and install

We're now ready to compile the Kernel. Run:

```bash
make -jN
```

where N is the number of jobs allowed at once. Kernel compilation
takes a while. Once the process terminates, you can install the
modules to `/lib/modules/linux-5.15-rc5` running:

```bash
sudo make modules_install
```

and the save the Kernel executable bzImage to `/boot/vmlinuz` running:

```bash
sudo make install
```

Notice that, by performing the last operation, you don't need to
manually execute `update-initramfs` and update Grub with the new
option. Indeed, you can verify that the new Kernel is the first boot
option reading the content of `/boot/grub/grub.cfg`. Don't worry, you
don't need to understand the syntax of this file, you can just search
for the keyword `menuentry` (the main menu) with the following Awk
one-liner:

```bash
sudo awk -F\' '/menuentry / {print $2}' /boot/grub/grub.cfg
```

The program prints the chars following the string `menuentry '`, until
the terminator `'`(as specified by the field separator argument `-F`)
is found, for each occurence of the keyword.

## Check the LSM is working

To boot into the new Kernel we only need to restart the VM. After
that, you can open the terminal and verify that Landlock is running:

<p align="center">
	<img src="/assets/blog_assets/2021_10_16/landlock_status.png" width="700" style="border-radius: 2%;">
</p>
