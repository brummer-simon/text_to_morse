# text_to_morse

An example linux kernel module written in Rust, converting text to morse code.

This repository contains all resources used in my talk held at the RustFest 2024.
It contains a pre-configured virtual development environment supporting loading of rust kernel modules and
means to build, integrate and test __your own kernel modules__ easily.

The contents of this repository are educational resources, so feel free to use and distribute it.

TODO(mention task/link after publishing)

## Development environment

In general, the best way to run kernel modules under development is a virtual environment. It
prevents "biting the hand that feeds you" problems, often encountered during low level development.

This setup uses [buildroot](http://www.buildroot.org) to build a tiny userland and [qemu](http://www.qemu.org), a hardware emulator.
The linux kernel itself is configured and built directly from source.

Combining the cross-compiling capabilities of buildroot and linux with the ability of qemu to emulate
most existing system architectures, the result is a flexible test environment able to mimic most existing systems.

In this case: We emulate plain old x86_64. After building and starting the environment via qemu, it is accessible via SSH.
Out-of-tree build artifacts like kernel modules are deployed via SCP.

In order to provide a convenient user experience of all of those steps are scripted away and executable via make.

### Initial build instructions

1) Install all mandatory dependencies with your packet manager. See [Dependencies](#Dependencies).
2) Clone this repository (including submodules) and enter it:
   ```
   git clone --recursive git@github.com:brummer-simon/text_to_morse.git
   cd text_to_morse
   ```
3) Build the entire development environment (full build takes ~45m):
   ```
   make build_env build_module login
   ```

On success, you are greeted by the message:
```
kernel_hacking_environment#
```
To leave the environment enter `exit`.

### Kernel module development workflow

1) Select the kernel module you work on, by setting 'MODULE_NAME' in the main Makefile
   or specify it as parameter to all module related make calls. By default, the "text_to_morse"
   example module is selected.
2) Edit the modules code with the editor of your choice.
3) Build your module via `make build_module`.
4) Kernel modules are heavily relaying on the kernels logging facilities. Open a new terminal
   and enter `make login_kernel_log` to follow the kernel log.
5) Deploy your module via `make load_module`. On success, the kernel log is now containing
   a message that the deployed model was loaded.
6) Open a new terminal, enter `make login` to login to the development environment and
   interact with the loaded module.


### Useful make targets

- `make help`                - Print all available make targets
- `make configure_buildroot` - Starts buildroots menuconfig to configure buildroot
- `make configure_linux`     - Starts linux menuconfig to configure linux
- `make build_linux`         - Start dedicated linux kernel build. Run after reconfiguration
- `make login`               - Log into virtual environment
- `make login_kernel_log`    - Log into virtual environment and follow kernel log
- `make open_rustdoc`        - Open generated rustdoc of linux kernel in browser

### Dependencies

Mandatory:
- Buildroot dependencies. See [buildroot documentation](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory).
- Linux dependencies. See See [Linux documentation](https://www.kernel.org/doc/html/latest/process/changes.html).
- llvm (The Rust <-> C language binding generator uses LLVM under the hood.)
- clang
- ssh
- sshpass
- awk
- jq

Optional:
- shellcheck. Uses to sanity check all contained shell scripts
- xdg-utils. Used to find the default web browser to open rustdoc

### Buildroot configuration adjustments

The base configuration "qemu_x86_64_defconfig" shipped with buildroot
was changed in the following way:

- Use pre-built external toolchain to speedup buildroot builds.
- Remove linux from buildroot. It is built directly from source.
- Add sshd + custom sshd configuration. It provides access from the host system.
- Add vim
- Add zsh

## How to integrate my own modules?

1) Use text_to_morse as template:
    ```
    cp -r modules/text_to_morse modules/<module_name>
    mv modules/<module_name>/text_to_morse.rs modules/<module_name>/<module_name>.rs
    ```

2) Set new module temporarily for module related targets (e.g. build_module):
    ```
    make MODULE_NAME=<module name> build_module
    ```

3) Set new module as selected default module: Rewrite variable "MODULE_NAME" in Makefile.
4) [Start development](#Kernel-module-development-workflow)


## Special thanks

This project would not be possible without possibly millions of hours
spent on developing and maintaining countless open sources projects.
I am standing here on the shoulders of giants and I want to thank all of you
for your work and dedication.

If you have suggestions or want open a bug, please open an issue and/or feel free to contact me.
