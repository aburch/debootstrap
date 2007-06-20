CC=gcc
CFLAGS=-Wall -W -O2

ARCH := $(shell dpkg --print-architecture)
setarchdevs = $(if $(findstring $(ARCH),$(1)),$(2))

DEVS := generic hde hdf hdg hdh sde sdf sdg sdh scd-all initrd input usb md lp rtc video \
        $(call setarchdevs,i386,isdn-io eda edb sonycd mcd mcdx cdu535 \
                                optcd sjcd cm206cd gscd lmscd sbpcd \
                                aztcd bpcd dac960 ida fd0 fd1 ataraid cciss) \
        $(call setarchdevs,sparc,hdc hdd busmice) \
        $(call setarchdevs,m68k,fd0 fd1 adc add ade adf hdc hdd) \
        $(call setarchdevs,powerpc,hdc hdd fd0 fd1 isdn-io m68k-mice) \
        $(call setarchdevs,ia64,ida fd0 fd1 ataraid cciss)

MAKEDEV := $(shell if [ -e /dev/MAKEDEV ]; then echo /dev/MAKEDEV; else echo /sbin/MAKEDEV; fi)

all: pkgdetails devices-std.tar.gz devices.tar.gz debootstrap-arch
clean:
	rm -f pkgdetails pkgdetails.o devices-std.tar.gz devices.tar.gz
	rm -f debootstrap-arch
	rm -rf dev

DSDIR=$(DESTDIR)/usr/lib/debootstrap
install:
	mkdir -p $(DSDIR)/scripts
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/usr/share/man/man8
	install -o root -g root -m 0644 scripts/debian/* $(DSDIR)/scripts/
	install -o root -g root -m 0644 scripts/ubuntu/* $(DSDIR)/scripts/
	install -o root -g root -m 0644 functions $(DSDIR)/

        # no special script for etch anymore
	ln -s sid $(DSDIR)/scripts/etch
	ln -s sid $(DSDIR)/scripts/lenny

	install -o root -g root -m 0755 debootstrap.8 $(DESTDIR)/usr/share/man/man8/
	install -o root -g root -m 0755 debootstrap $(DESTDIR)/usr/sbin/

install-allarch: install
	install -o root -g root -m 0644 devices-std.tar.gz \
		$(DSDIR)/devices.tar.gz

install-arch: install
	install -o root -g root -m 0755 pkgdetails $(DSDIR)/
	install -o root -g root -m 0644 devices.tar.gz $(DSDIR)/
	install -o root -g root -m 0644 debootstrap-arch $(DSDIR)/arch

pkgdetails: pkgdetails.o
	$(CC) -o $@ $^

debootstrap-arch:
	echo $(ARCH) >debootstrap-arch

devices-std.tar.gz:
	rm -rf dev
	mkdir -p dev
	chown 0:0 dev
	chmod 755 dev
	(cd dev && $(MAKEDEV) std ptmx fd)
	tar cf - dev | gzip -9 >devices-std.tar.gz
	rm -rf dev

devices.tar.gz:
	rm -rf dev

	mkdir -p dev
	chown 0:0 dev
	chmod 755 dev

	(cd dev && $(MAKEDEV) $(DEVS))

ifeq ($(ARCH),powerpc)
#	Maybe remove amiga/atari mice also? What about usbmouse?
	rm -f dev/adbmouse
	ln -sf input/mice dev/mouse
	ln -sf input/js0 dev/js0
	ln -sf input/js1 dev/js1
endif

	@if ! find dev -maxdepth 0 -perm 755 -uid 0 -gid 0 | \
	        grep -q "^dev$$"; \
	then \
	   echo "======================================================="; \
	   echo "ERROR"; echo; \
	   echo "./dev has bad permissions! should be 755 root.root. Was:"; \
	   ls -ld ./dev; \
	   echo "======================================================="; \
	   false; \
	fi

	tar cf - dev | gzip -9 >devices.tar.gz
	rm -rf dev

