# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2026-05-19

### Fixed

- Sync column-width restore before `reset-window-height` so auto height is
  calculated with the correct column width already in place. The previous async
  restore caused a spurious fixed-height override that left windows shorter
  after fractional display scaling.
- Preserve window height as a float (drop `int()` truncation) and use
  `round()` when passing back to niri, avoiding precision loss under fractional
  scale factors.

## [0.2.0] - 2026-05-17

### Added

- TOML configuration support (`~/.config/niri-notify-focus/config.toml`):
  configurable pulse effect (`shrink` / `expand` / `none`) and `pulse_pixels`.

### Changed

- Default pulse effect changed from outward expand to inward shrink.
- Pulse now applies to both column width and window height simultaneously.

### Fixed

- Use symmetric `±pixel` offsets for the height pulse to avoid drift.
- Preserve window height mode (auto vs fixed) after pulse animation.

## [0.1.0] - 2026-05-15

### Added

- Initial release.
- Monitor D-Bus notification traffic via `BecomeMonitor`.
- Map sender PIDs to niri windows by walking the process tree.
- Focus the source window when the user clicks a notification action or
  dismisses it.
- Inward shrink pulse animation as a visual focus cue.
- Systemd user service (`niri-notify-focus.service`).
- PKGBUILD for Arch Linux / AUR.
