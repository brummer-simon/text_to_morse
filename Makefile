# TODO Describe targets
# TODO Add target to log "into kernel log"

help:
	echo "+-----------------------------------------------+"
	echo "| This makefile supports the following targets: |"
	echo "| - configure_env                               |"
	echo "| - configure_kernel                            |"
	echo "| - build_env                                   |"
	echo "| - clean_env                                   |"
	echo "| - start_env                                   |"
	echo "| - stop_env                                    |"
	echo "| - login                                       |"
	echo "+-----------------------------------------------+"

configure_env:
	./scripts/configure_buildroot.sh

configure_kernel:
	./scripts/configure_kernel.sh

build_env:
	./scripts/build_buildroot.sh

clean_env:
	./scripts/clean_buildroot.sh

start_env:
	./scripts/start_qemu.sh

stop_env:
	./scripts/stop_qemu.sh

login:
	./scripts/login_qemu.sh

.PHONY:\
	help\
	configure_env\
	configure_kernel\
	build_env\
	clean_env\
	start_env\
	stop_env\
	login

.SILENT:\
	help\
	configure_env\
	configure_kernel\
	build_env\
	clean_env\
	start_env\
	stop_env\
	login
