# TODO: Add meta build targets. Build, Clean

help:
	echo "+----------------------------------------------------------------------------------+"
	echo "| This makefile supports the following targets:                                    |"
	echo "| - configure_env    - Configure virtual environment                               |"
	echo "| - configure_kernel - Configure linux kernel in virtual environment configuration |"
	echo "| - build_env        - Build virtual environment.                                  |"
	echo "| - build_module     - Build text_to_morse kernel module                           |"
	echo "| - clean_env        - Delete virtual environment                                  |"
	echo "| - clean_module     - Delete text_to_morse kernel module artifacts                |"
	echo "| - start_env        - Start virtual environment                                   |"
	echo "| - stop_env         - Shutdown virtual environment                                |"
	echo "| - login            - Login into virtual environment                              |"
	echo "| - login_kernel_log - Login into virtual environment and follow kernel log        |"
	echo "+----------------------------------------------------------------------------------+"

configure_env:
	./scripts/configure_buildroot.sh

configure_kernel:
	./scripts/configure_kernel.sh

build_env:
	./scripts/build_buildroot.sh

build_module:
	./scripts/build_text_to_morse.sh

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
	configure_env\
	configure_kernel\
	build_env\
	build_module\
	clean_env\
	clean_module\
	start_env\
	stop_env\
	login\
	login_kernel_log

.SILENT:\
	help\
	configure_env\
	configure_kernel\
	build_env\
	build_module\
	clean_env\
	clean_module\
	start_env\
	stop_env\
	login\
	login_kernel_log
