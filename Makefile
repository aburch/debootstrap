# avoid dpkg-dev dependency; fish out the version with sed
VERSION := $(shell sed 's/.*(\(.*\)).*/\1/; q' debian/changelog)

ARCH := $(shell dpkg --print-architecture)

MAKEDEV := $(shell if [ -e /dev/MAKEDEV ]; then echo /dev/MAKEDEV; else echo /sbin/MAKEDEV; fi)

all: devices.tar.gz
clean:
	rm -f devices.tar.gz
	rm -rf dev

DSDIR=$(DESTDIR)/usr/share/debootstrap
install:
	mkdir -p $(DSDIR)/scripts
	mkdir -p $(DESTDIR)/usr/sbin

	install -o root -g root -m 0644 scripts/debian/* $(DSDIR)/scripts/
	install -o root -g root -m 0644 scripts/ubuntu/* $(DSDIR)/scripts/
	install -o root -g root -m 0644 functions $(DSDIR)/

        # no special script for etch anymore
	ln -s sid $(DSDIR)/scripts/etch
	ln -s sid $(DSDIR)/scripts/etch-m68k
	ln -s sid $(DSDIR)/scripts/lenny

	ln -s gutsy $(DSDIR)/scripts/hardy
	ln -s gutsy $(DSDIR)/scripts/intrepid
	ln -s gutsy $(DSDIR)/scripts/jaunty

	sed 's/@VERSION@/$(VERSION)/g' debootstrap >$(DESTDIR)/usr/sbin/debootstrap
	chown root:root $(DESTDIR)/usr/sbin/debootstrap
	chmod 0755 $(DESTDIR)/usr/sbin/debootstrap

	install -o root -g root -m 0644 devices.tar.gz $(DSDIR)/

devices.tar.gz:
	rm -rf dev
	mkdir -p dev
	chown 0:0 dev
	chmod 755 dev
	(cd dev && $(MAKEDEV) std ptmx fd)
	tar cf - dev | gzip -9 >devices.tar.gz
	rm -rf dev
