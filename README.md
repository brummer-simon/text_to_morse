# text_to_morse

A linux kernel module to convert text to morse code written in Rust! This repository
contains all resources created in the preparation of my talk held at the RustFest 2024.
TODO (add link here after publishing). This repo is an educational resource so feel free to use and distribute it.

## Development environment

This repository contains a linux kernel module development environment with
pre-configured kernel supporting Rust modules. It can be used for general kernel development as well.

In general, the best way to test kernel hacking results is in a virtual environment, it
avoids "biting the hand that feeds you" problems.

This setup uses the [buildroot](http://www.buildroot.org) project to build a tiny linux environment. Additionally buildroot is
configured to build [qemu](http://www.qemu.org), a hardware emulator. Qemu can emulate must computer architectures. Using it together with buildroots cross-compiling
capabilities, the result in a flexible test environment that is able to mimic most existing computer architectures.

In our case, we use plain old x86_64. After building, the test environment can be started
started via qemu. As soon as the environment it running, it can be accessed via SSH. Build artifacts
are deployed via SCP.

To ensure a convenient user experience of all of those steps are scripted away using make.

### Environment setup

1) Clone submodule recursively (it uses submodules):
   ```
   git clone --recursive git@github.com:brummer-simon/text_to_morse.git
   ```
2) Install all dependencies with your packet manager. See [Dependencies](#Dependencies).
3) Build the development environment (the initial build takes a while):
   ```
   make build_env
   ```
4) Start the development environment:
   ```
   make start_env
   ```
5) Login into the development environment:
   ```
   make login
   ```

### Environment configuration

Although the environment is pre-configured, the configuration can be changed
with menuconfig. Just remember to rebuild with `make build_env` afterwards for
the changes to take effect.

To configure the system image, enter:
```
make configure_env
```

The linux kernel is configured by:
```
make configure_kernel
```

### Dependencies

Mandatory:
- All buildroot dependencies. See [buildroot documentation](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory).
- ssh
- sshpass
- jq
- rustup
- awk

Optional:
TODO (add dependencies to build slides as soon as they exist)

### Image adjustments

The following changes were made on top of the base configuration "qemu_x86_64_defconfig"
shipped with buildroot:

- Use latest available linux kernel version
- Add zsh
- Add vim
- Add ssh
- Add custom sshd configuration

## Special thanks

TODO(mention all major FOSS projects making this possible)
