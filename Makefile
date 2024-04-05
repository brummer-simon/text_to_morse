# TODO: Add meta build targets. Build, Clean
# TODO: Add target: build_linux, clean_linux, clean_buildroot, build_env (buildroot + linux), clean_env (buildroot + linux)
# TODO: Add target to generate the kernel config for rust

help:
	echo "+-------------------------------------------------------------------------------------+"
	echo "| This makefile supports the following targets:                                       |"
	echo "| - configure_buildroot - Configure buildroot environment                             |"
	echo "| - configure_linux     - Configure linux kernel                                      |"
	echo "| - build_buildroot     - Build buildroot environment.                                |"
	echo "| - build_linux         - Build linux kernel.                                         |"
	echo "| - build_module        - Build text_to_morse kernel module                           |"
	echo "| - build_env           - Build entire kernel development environment.                |"
	echo "| - clean_env           - Delete virtual environment                                  |"
	echo "| - clean_module        - Delete text_to_morse kernel module artifacts                |"
	echo "| - start_env           - Start virtual environment                                   |"
	echo "| - stop_env            - Shutdown virtual environment                                |"
	echo "| - login               - Login into virtual environment                              |"
	echo "| - login_kernel_log    - Login into virtual environment and follow kernel log        |"
	echo "+-------------------------------------------------------------------------------------+"

# Configuration targets
configure_buildroot:
	./scripts/configure_buildroot.sh

configure_linux:
	./scripts/configure_linux.sh

# Build targets
build_buildroot:
	./scripts/build_buildroot.sh

build_linux:
	./scripts/build_linux.sh

build_module:
	./scripts/build_text_to_morse.sh

build_env: build_buildroot build_linux build_module

# TODO: Refactor / Test targets below
clean_env:
	./scripts/clean_buildroot.sh

clean_module:
	./scripts/clean_text_to_morse.sh

start_env:
	./scripts/start_qemu.sh

stop_env:
	./scripts/stop_qemu.sh

login:
	./scripts/login_qemu.sh

login_kernel_log:
	./scripts/login_qemu_kernel_log.sh

.PHONY:\
	help\
	configure_buildroot\
	configure_linux\
	build_buildroot\
	build_linux\
	build_module\
	build_env\
	clean_env\
	clean_module\
	start_env\
	stop_env\
	login\
	login_kernel_log

.SILENT:\
	help\
	configure_buildroot\
	configure_linux\
	build_buildroot\
	build_linux\
	build_module\
	build_env\
	clean_env\
	clean_module\
	start_env\
	stop_env\
	login\
	login_kernel_log
