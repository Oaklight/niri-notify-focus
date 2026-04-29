PREFIX ?= /usr
DESTDIR ?=

BIN_DIR = $(DESTDIR)$(PREFIX)/bin
SERVICE_DIR = $(DESTDIR)$(PREFIX)/lib/systemd/user
LICENSE_DIR = $(DESTDIR)$(PREFIX)/share/licenses/niri-notify-focus

.PHONY: install uninstall help

install:
	install -Dm755 niri-notify-focus $(BIN_DIR)/niri-notify-focus
	install -Dm644 niri-notify-focus.service $(SERVICE_DIR)/niri-notify-focus.service
	install -Dm644 LICENSE $(LICENSE_DIR)/LICENSE

uninstall:
	rm -f $(BIN_DIR)/niri-notify-focus
	rm -f $(SERVICE_DIR)/niri-notify-focus.service
	rm -rf $(LICENSE_DIR)

help:
	@echo "Available targets:"
	@echo "  install    - Install script and systemd service"
	@echo "  uninstall  - Remove installed files"
	@echo ""
	@echo "Variables:"
	@echo "  DESTDIR=<path>  - Staging directory for packaging"
	@echo "  PREFIX=<path>   - Install prefix (default: /usr)"
	@echo ""
	@echo "After install:"
	@echo "  systemctl --user enable --now niri-notify-focus"
