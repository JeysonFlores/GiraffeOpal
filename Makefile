
.PHONY: all install uninstall
PREFIX ?= /app

install:
	cd src && make polyml
	install -D -m 0755 src/com.github.jeysonflores.giraffeflatpak $(PREFIX)/bin/com.github.jeysonflores.giraffeflatpak


uninstall:
	rm -f $(PREFIX)/bin/com.github.jeysonflores.giraffeflatpak