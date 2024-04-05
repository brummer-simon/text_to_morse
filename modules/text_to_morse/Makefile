obj-m := text_to_morse.o

SRCDIR ?= $$PWD

modules:
	make -C $(KDIR) M=$(BUILDDIR) src=$(SRCDIR) modules

clean:
	make -C $(KDIR) M=$(BUILDDIR) src=$(SRCDIR) clean

# TODO: Add Rust Analyizer target?
