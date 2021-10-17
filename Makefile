
.PHONY: all install uninstall
PREFIX ?= /app

install:
	cd src && make polyml
	install -D -m 0755 src/com.github.jeysonflores.sml $(PREFIX)/bin/com.github.jeysonflores.sml


uninstall:
	rm -f $(PREFIX)/bin/com.github.jeysonflores.sml