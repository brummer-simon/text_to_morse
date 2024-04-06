# Note: All used variables are supplied externally by the module related
# scripts located under ./scripts
obj-m := $(MOD_NAME).o

modules:
	make -s -C $(LINUX_BUILD_DIR) M=$(MOD_BUILD_DIR) src=$$PWD modules

clean:
	make -C $(LINUX_BUILD_DIR) M=$(MOD_BUILD_DIR) src=$$PWD clean

rustfmt:
	make -C $(LINUX_BUILD_DIR) src=$$PWD rustfmt
