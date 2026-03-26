PKGNAME ?= timeshift-autosnap-apt

.PHONY: install uninstall

install:
	@install -Dm644 -t "$(DESTDIR)/etc/apt/apt.conf.d/" 80-timeshift-autosnap-apt
	@install -Dm755 -t "$(DESTDIR)/usr/bin/" timeshift-autosnap-apt
	@install -Dm644 -t "$(LIB_DIR)/etc/" timeshift-autosnap-apt.conf
	@install -dm755 "$(DESTDIR)/etc/timeshift-autosnap-apt/pre-snapshot.d"
	@install -dm755 "$(DESTDIR)/etc/timeshift-autosnap-apt/post-snapshot.d"

uninstall:
	rm -f $(DESTDIR)/etc/apt/apt.conf.d/80-timeshift-autosnap-apt
	rm -f $(DESTDIR)/usr/bin/timeshift-autosnap-apt
	rm -f $(LIB_DIR)/etc/timeshift-autosnap-apt.conf
	rmdir $(DESTDIR)/etc/timeshift-autosnap-apt/pre-snapshot.d || true
	rmdir $(DESTDIR)/etc/timeshift-autosnap-apt/post-snapshot.d || true

