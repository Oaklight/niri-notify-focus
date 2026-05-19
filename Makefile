PREFIX ?= /usr
DESTDIR ?=

BIN_DIR = $(DESTDIR)$(PREFIX)/bin
SERVICE_DIR = $(DESTDIR)$(PREFIX)/lib/systemd/user
LICENSE_DIR = $(DESTDIR)$(PREFIX)/share/licenses/niri-notify-focus
DOC_DIR = $(DESTDIR)$(PREFIX)/share/doc/niri-notify-focus

# Read current version from PKGBUILD
VERSION := $(shell grep '^pkgver=' PKGBUILD | cut -d= -f2)

# AUR clone dir (temp)
AUR_DIR := /tmp/aur-niri-notify-focus

.PHONY: install uninstall release release-github release-aur help

install:
	install -Dm755 niri-notify-focus $(BIN_DIR)/niri-notify-focus
	install -Dm644 niri-notify-focus.service $(SERVICE_DIR)/niri-notify-focus.service
	install -Dm644 LICENSE $(LICENSE_DIR)/LICENSE
	install -Dm644 config.toml.example $(DOC_DIR)/config.toml.example

uninstall:
	rm -f $(BIN_DIR)/niri-notify-focus
	rm -f $(SERVICE_DIR)/niri-notify-focus.service
	rm -rf $(LICENSE_DIR)
	rm -rf $(DOC_DIR)

# Full release: tag + GitHub release + AUR
release: release-github release-aur
	@echo "Released v$(VERSION)"

# Push tag and create GitHub release (reads notes from CHANGELOG.md)
release-github:
	@echo "==> Tagging v$(VERSION)"
	git tag v$(VERSION) 2>/dev/null || echo "Tag v$(VERSION) already exists, skipping"
	git push origin main
	git push origin v$(VERSION) 2>/dev/null || true
	@echo "==> Computing sha256sum"
	$(eval SHA256 := $(shell curl -sL https://github.com/Oaklight/niri-notify-focus/archive/v$(VERSION).tar.gz | sha256sum | cut -d' ' -f1))
	@echo "sha256: $(SHA256)"
	@sed -i "s/sha256sums=.*/sha256sums=('$(SHA256)')/" PKGBUILD
	@git add PKGBUILD
	@git diff --cached --quiet || git commit -m "chore: update PKGBUILD sha256sum for v$(VERSION)"
	@git push origin main
	@echo "==> Creating GitHub release"
	$(eval NOTES := $(shell awk '/^## \[$(VERSION)\]/{found=1; next} found && /^## \[/{exit} found{print}' CHANGELOG.md))
	gh release create v$(VERSION) --title "v$(VERSION)" --notes "$$(awk '/^## \[$(VERSION)\]/{found=1; next} found && /^## \[/{exit} found{print}' CHANGELOG.md)" 2>/dev/null || \
		gh release edit v$(VERSION) --notes "$$(awk '/^## \[$(VERSION)\]/{found=1; next} found && /^## \[/{exit} found{print}' CHANGELOG.md)"

# Push updated PKGBUILD to AUR
release-aur:
	@echo "==> Updating AUR"
	@if [ ! -d "$(AUR_DIR)/.git" ]; then \
		rm -rf $(AUR_DIR); \
		proxychains -q git clone ssh://aur@aur.archlinux.org/niri-notify-focus.git $(AUR_DIR); \
	fi
	cp PKGBUILD $(AUR_DIR)/PKGBUILD
	cd $(AUR_DIR) && makepkg --printsrcinfo > .SRCINFO
	cd $(AUR_DIR) && git add PKGBUILD .SRCINFO
	cd $(AUR_DIR) && git diff --cached --quiet || git commit -m "chore: bump to v$(VERSION)"
	cd $(AUR_DIR) && proxychains -q git push

help:
	@echo "Available targets:"
	@echo "  install        - Install script and systemd service"
	@echo "  uninstall      - Remove installed files"
	@echo "  release        - Full release: GitHub tag + release + AUR (VERSION from PKGBUILD)"
	@echo "  release-github - Tag, push, compute sha256, create GitHub release"
	@echo "  release-aur    - Push updated PKGBUILD to AUR"
	@echo ""
	@echo "Variables:"
	@echo "  DESTDIR=<path>  - Staging directory for packaging"
	@echo "  PREFIX=<path>   - Install prefix (default: /usr)"
	@echo ""
	@echo "After install:"
	@echo "  systemctl --user enable --now niri-notify-focus"
