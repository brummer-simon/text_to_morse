# TODO: Add target to generate the kernel documentation for rust
# TODO: Add shellcheck target

help:
	echo "This makefile supports the following targets:"
	echo
	echo "Configuration targets:"
	echo "    - configure_buildroot - Configure buildroot environment"
	echo "    - configure_linux     - Configure linux kernel"
	echo
	echo "Build targets:"
	echo "    - build_env           - Build entire kernel development environment"
	echo "    - build_buildroot     - Build buildroot environment"
	echo "    - build_linux         - Build linux kernel"
	echo "    - build_module        - Build out-of-tree kernel module"
	echo
	echo "Cleanup targets:"
	echo "    - clean_env           - Delete virtual environment"
	echo "    - clean_buildroot     - Delete buildroot build artifacts"
	echo "    - clean_linux         - Delete linux kernel build artifacts"
	echo "    - clean_module        - Delete out-of-tree kernel module build artifacts"
	echo
	echo "Other targets:"
	echo "    - start_env           - Start linux environment"
	echo "    - stop_env            - Shutdown linux environment"
	echo "    - login               - Login into linux environment"
	echo "    - login_kernel_log    - Login into linux environment and follow kernel log"

# Configuration targets
configure_buildroot:
	./scripts/configure_buildroot.sh

configure_linux:
	./scripts/configure_linux.sh

# Build targets
build_env:
	./scripts/build_buildroot.sh
	./scripts/build_linux.sh
	./scripts/build_text_to_morse.sh

build_buildroot:
	./scripts/build_buildroot.sh

build_linux:
	./scripts/build_linux.sh

build_module:
	./scripts/build_text_to_morse.sh

# Clean targets
clean_env:
	./scripts/clean_env.sh

clean_buildroot:
	./scripts/clean_buildroot.sh

clean_linux:
	./scripts/clean_linux.sh

clean_module:
	./scripts/clean_text_to_morse.sh

# Other targets
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
