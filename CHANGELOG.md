# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed

- Restore the target's geometry from a snapshot taken by window ID instead of
  undoing the pulse with a relative `+N`. niri clamps a relative change at the
  screen edge, so `-50` on a full-width column is clamped while the matching
  `+50` is not; the column ended up wider than the screen. Absolute values
  remove the drift entirely.
- Run the pulse and the restore synchronously, on a worker thread. The pulse
  used fire-and-forget `niri msg` calls, so under IPC contention its
  `set-window-height` could be delivered after the restore's
  `reset-window-height`, freezing the window at its shrunk height.
- Verify the final geometry and correct it: a user-fixed height is re-applied,
  and a column that was maximized-to-edges (tile size equal to window size) is
  re-maximized, because any size change clears that state.
- Skip the pulse when the target window no longer exists or never gains focus,
  instead of resizing whatever window happens to be focused.

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
