CC=gcc
CFLAGS=-Wall -W -O2

# avoid dpkg-dev dependency; fish out the version with sed
VERSION := $(shell sed 's/.*(\(.*\)).*/\1/; q' debian/changelog)

ARCH := $(shell dpkg --print-architecture)

MAKEDEV := $(shell if [ -e /dev/MAKEDEV ]; then echo /dev/MAKEDEV; else echo /sbin/MAKEDEV; fi)

all: pkgdetails devices.tar.gz debootstrap-arch
clean:
	rm -f pkgdetails pkgdetails.o devices.tar.gz
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

	ln -s gutsy $(DSDIR)/scripts/hardy

	install -o root -g root -m 0755 debootstrap.8 $(DESTDIR)/usr/share/man/man8/
	sed 's/@VERSION@/$(VERSION)/g' debootstrap >$(DESTDIR)/usr/sbin/debootstrap
	chown root:root $(DESTDIR)/usr/sbin/debootstrap
	chmod 0755 $(DESTDIR)/usr/sbin/debootstrap

	install -o root -g root -m 0644 devices.tar.gz $(DSDIR)/

install-udeb: install
	install -o root -g root -m 0755 pkgdetails $(DSDIR)/
	install -o root -g root -m 0644 debootstrap-arch $(DSDIR)/arch

pkgdetails: pkgdetails.o
	$(CC) -o $@ $^

debootstrap-arch:
	echo $(ARCH) >debootstrap-arch

devices.tar.gz:
	rm -rf dev
	mkdir -p dev
	chown 0:0 dev
	chmod 755 dev
	(cd dev && $(MAKEDEV) std ptmx fd)
	tar cf - dev | gzip -9 >devices.tar.gz
	rm -rf dev
