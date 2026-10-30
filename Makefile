PREFIX ?= /usr
BINDIR  = $(PREFIX)/bin
ETCDIR  = /etc
SHAREDIR = $(PREFIX)/share/pkgmake
DOCDIR = $(PREFIX)/share/doc/pkgmake

BIN_FILES = usr/bin/pkgmake usr/bin/makepkg usr/bin/pkgmake-docker usr/bin/makepkg-docker
ETC_FILES = etc/pkgmake.conf
SHARE_FILES = usr/share/pkgmake/*.sh
DOCKER_FILES = usr/share/pkgmake/docker/Dockerfile usr/share/pkgmake/docker/entrypoint.sh

all:
	@echo "Nada a compilar. Use: make install"

install:
	install -d $(DESTDIR)$(BINDIR)
	install -d $(ETCDIR)
	install -d $(DESTDIR)$(SHAREDIR)
	install -d $(DESTDIR)$(DOCDIR)

	install -m 755 $(BIN_FILES) $(DESTDIR)$(BINDIR)
	install -m 755 $(ETC_FILES) $(ETCDIR)
	install -m 644 $(SHARE_FILES) $(DESTDIR)$(SHAREDIR)
	install -d $(DESTDIR)$(SHAREDIR)/docker
	install -m 644 $(DOCKER_FILES) $(DESTDIR)$(SHAREDIR)/docker
	install -m 644 README.md $(DESTDIR)$(DOCDIR)/README.md

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/pkgmake
	rm -f $(DESTDIR)$(BINDIR)/makepkg
	rm -f $(DESTDIR)$(BINDIR)/pkgmake-docker
	rm -f $(DESTDIR)$(BINDIR)/makepkg-docker
	rm -f $(ETCDIR)/pkgmake.conf
	rm -rf $(DESTDIR)$(SHAREDIR)
	rm -rf $(DESTDIR)$(DOCDIR)

.PHONY: all install uninstall

