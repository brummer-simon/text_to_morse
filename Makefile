# Currently selected kernel module to build
MODULE_NAME ?= "text_to_morse"

help:
	echo "This makefile supports the following targets:"
	echo
	echo "Configuration targets:"
	echo "    - configure_buildroot - Configure buildroot environment"
	echo "    - configure_linux     - Configure linux kernel"
	echo
	echo "Build targets:"
	echo "    - build_env               - Build entire kernel development environment"
	echo "    - build_buildroot         - Build buildroot environment"
	echo "    - build_linux             - Build linux with rustdoc and rust-project.json"
	echo "    - build_linux_kernel      - Build linux kernel only"
	echo "    - build_linux_rustdoc     - Build rustdoc from linux kernel"
	echo "    - build_linux_rustproject - Build rust-project.json from linux kernel"
	echo "    - build_module            - Build out-of-tree kernel module"
	echo
	echo "Cleanup targets:"
	echo "    - clean_env       - Delete virtual environment"
	echo "    - clean_buildroot - Delete buildroot build artifacts"
	echo "    - clean_linux     - Delete linux kernel build artifacts"
	echo "    - clean_module    - Delete out-of-tree kernel module build artifacts"
	echo
	echo "Development targets:"
	echo "    - load_module      - Deploy kernel module into linux environment and load it"
	echo "    - unload_module    - Unload kernel module"
	echo "    - start_env        - Start linux environment"
	echo "    - stop_env         - Shutdown linux environment"
	echo "    - login            - Login into linux environment"
	echo "    - login_kernel_log - Login into linux environment and follow kernel log"
	echo "    - open_rustdoc     - Open rustdoc for linux kernel facilities."
	echo
	echo "Other targets:"
	echo "    - slides           - Build slides"
	echo "    - presentation     - Build slides and spawn presentation mode"
	echo "    - shellcheck       - Check bash scripts under scripts"

# Configuration targets
configure_buildroot:
	./scripts/configure_buildroot.sh

configure_linux:
	./scripts/configure_linux.sh

# Build targets
build_env:
	./scripts/build_env.sh

build_buildroot:
	./scripts/build_buildroot.sh

build_linux:
	./scripts/build_linux.sh

build_linux_kernel:
	./scripts/build_linux.sh "ONLY_LINUX"

build_linux_rustdoc:
	./scripts/build_linux.sh "ONLY_LINUX_RUSTDOC"

build_linux_rustproject:
	./scripts/build_linux.sh "ONLY_LINUX_RUSTPROJECT"

build_module:
	./scripts/build_module.sh $(MODULE_NAME)

# Clean targets
clean_env:
	./scripts/clean_env.sh

clean_buildroot:
	./scripts/clean_buildroot.sh

clean_linux:
	./scripts/clean_linux.sh

clean_module:
	./scripts/clean_module.sh $(MODULE_NAME)

# Development targets
load_module:
	./scripts/load_module.sh $(MODULE_NAME)

unload_module:
	./scripts/unload_module.sh $(MODULE_NAME)

start_env:
	./scripts/start_qemu.sh

stop_env:
	./scripts/stop_qemu.sh

login:
	./scripts/login_qemu.sh

login_kernel_log:
	./scripts/login_qemu_kernel_log.sh

open_rustdoc:
	./scripts/open_rustdoc.sh

# Other targets
slides:
	./scripts/build_slides.sh

presentation:
	./scripts/start_slides.sh

shellcheck:
	shellcheck -a -s bash scripts/*

.PHONY:\
	help\
	configure_buildroot\
	configure_linux\
	build_buildroot\
	build_linux\
	build_linux_kernel\
	build_linux_rustdoc\
	build_linux_rustproject\
	build_module\
	build_env\
	clean_env\
	clean_module\
	load_module\
	unload_module\
	start_env\
	stop_env\
	login\
	login_kernel_log\
	open_rustdoc\
	slides\
	presentation\
	shellcheck

.SILENT:\
	help\
	configure_buildroot\
	configure_linux\
	build_buildroot\
	build_linux\
	build_linux_kernel\
	build_linux_rustdoc\
	build_linux_rustproject\
	build_module\
	build_env\
	clean_env\
	clean_module\
	load_module\
	unload_module\
	start_env\
	stop_env\
	login\
	login_kernel_log\
	open_rustdoc\
	slides\
	presentation\
	shellcheck
