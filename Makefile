# avoid dpkg-dev dependency; fish out the version with sed
VERSION := $(shell sed 's/.*(\(.*\)).*/\1/; q' debian/changelog)

MAKEDEV := $(shell if [ -e /dev/MAKEDEV ]; then echo /dev/MAKEDEV; else echo /sbin/MAKEDEV; fi)

all: devices.tar.gz
clean:
	rm -f devices.tar.gz
	rm -rf dev

DSDIR=$(DESTDIR)/usr/share/debootstrap
install:
	mkdir -p $(DSDIR)/scripts
	mkdir -p $(DESTDIR)/usr/sbin

	cp -a scripts/* $(DSDIR)/scripts/
	install -o root -g root -m 0644 functions $(DSDIR)/

	sed 's/@VERSION@/$(VERSION)/g' debootstrap >$(DESTDIR)/usr/sbin/debootstrap
	chown root:root $(DESTDIR)/usr/sbin/debootstrap
	chmod 0755 $(DESTDIR)/usr/sbin/debootstrap

	install -o root -g root -m 0644 devices.tar.gz $(DSDIR)/

devices.tar.gz:
	rm -rf dev
	mkdir -p dev
	chown 0:0 dev
	chmod 755 dev
	(cd dev && $(MAKEDEV) std ptmx fd consoleonly)
	tar cf - dev | gzip -9 >devices.tar.gz
	rm -rf dev
