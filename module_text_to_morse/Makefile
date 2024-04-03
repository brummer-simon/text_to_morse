obj-m := text_to_morse.o

BUILDDIR ?= $$PWD/build
SRCDIR ?= $$PWD/src

modules:
	$(MAKE) -C $(KDIR) M=$(BUILDDIR) src=$(SRCDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(BUILDDIR) src=$(SRCDIR) clean
