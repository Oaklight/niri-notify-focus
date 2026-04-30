# niri-notify-focus

[中文](README_zh.md) | **English**

Focus the source application window when you click a desktop notification in [niri](https://github.com/YaLTeR/niri).

## Problem

When running many instances of the same application — multiple terminal windows with [Claude Code](https://github.com/anthropics/claude-code), several browser profiles, etc. — a notification tells you *something happened*, but clicking it has no way to take you to the **exact window** that sent it. You're left hunting through workspaces manually.

## Solution

`niri-notify-focus` is a lightweight daemon that passively monitors D-Bus notification traffic, maps each notification back to its source window, and focuses that window when you click a notification action button. A brief size pulse highlights the target window so you can instantly spot it among identical-looking siblings.

## Features

- **Precise window targeting** — maps notifications to source windows via D-Bus PID tracking and process tree walking, even when the notifying process is a child of the window process
- **Works with any app** — terminals (kitty, alacritty, wezterm), browsers, IDEs — anything that sends desktop notifications
- **Visual pulse feedback** — briefly pulses the window width and height then restores, so you can instantly identify it among similar windows (configurable: shrink, expand, or none)
- **Non-blocking** — all niri IPC calls and timers run asynchronously via GLib, no jank or freezes
- **Resilient** — auto-reconnects on D-Bus errors, runs as a systemd user service with restart-on-failure
- **Optional configuration** — works out of the box with sensible defaults; customize via a simple TOML file when needed

## Requirements

- [niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor)
- Python 3
- [dbus-python](https://dbus.freedesktop.org/doc/dbus-python/)
- [PyGObject](https://pygobject.gnome.org/) (GLib main loop integration)
- A notification daemon that emits `ActionInvoked` D-Bus signals (mako, dunst, swaync, [DMS](https://github.com/System64fumo/dankshell), etc.)

## Installation

### Arch Linux (AUR)

```bash
# With an AUR helper
paru -S niri-notify-focus

# Or manually
git clone https://aur.archlinux.org/niri-notify-focus.git
cd niri-notify-focus
makepkg -si
```

### Manual

```bash
git clone https://github.com/Oaklight/niri-notify-focus.git
cd niri-notify-focus
sudo make install
```

### Uninstall

```bash
sudo make uninstall
systemctl --user disable niri-notify-focus
```

## Usage

Enable and start the systemd user service:

```bash
systemctl --user enable --now niri-notify-focus
```

That's it. Click any notification action button and the source window will be focused with a brief visual pulse.

### Configuration

Optionally create `~/.config/niri-notify-focus/config.toml` to customize behavior. All settings have sensible defaults — the file is not required.

```toml
# Visual effect when focusing a window.
# Options: "shrink" (inward pulse), "expand" (outward pulse), "none" (focus only)
effect = "shrink"

# Pixels to shrink/expand during pulse animation.
pulse_pixels = 50
```

An example config is installed to `/usr/share/doc/niri-notify-focus/config.toml.example`.

### Testing

Send a test notification with an action button:

```bash
notify-send "Test" "Click the button to jump" --action="default=Go"
```

Switch to a different workspace, then click the action button — you should be taken to the workspace and window that sent the notification, with a visible size pulse.

### Debug mode

Run in foreground with verbose logging to troubleshoot:

```bash
# Stop the service first
systemctl --user stop niri-notify-focus

# Run manually with debug output
niri-notify-focus -d
```

## How it works

```
┌─────────────┐    D-Bus Notify     ┌───────────────────┐
│  Application│ ──────────────────► │  Notification      │
│  (kitty,    │    (with PID hint   │  Daemon            │
│   browser)  │     or bus sender)  │  (mako/dunst/DMS)  │
└─────────────┘                     └───────┬───────────┘
       │                                    │
       │ PID                                │ ActionInvoked signal
       ▼                                    ▼
┌─────────────────────────────────────────────────────┐
│                 niri-notify-focus                    │
│                                                     │
│  1. Intercept Notify call via BecomeMonitor          │
│  2. Resolve sender PID (hint or GetConnectionPID)   │
│  3. Walk /proc PID tree → find niri window          │
│  4. Store: notification_id → window_id              │
│  5. On ActionInvoked → focus + pulse window         │
└─────────────────────────────────────────────────────┘
```

1. Uses D-Bus `BecomeMonitor` API to passively observe all notification traffic
2. When a `Notify` method call arrives, resolves the sender PID via the `sender-pid` hint (set by libnotify) or falls back to `GetConnectionUnixProcessID`
3. Walks up the process tree through `/proc/<pid>/status` (PPid field) to find the matching niri window — this handles cases where the notifying process is a child of the window process
4. Correlates the `Notify` call with its method return to map `notification_id → window_id`
5. When the user clicks a notification action (`ActionInvoked` signal), focuses the mapped window and triggers a brief size pulse (width and height ±pixels, then restore) via `GLib.timeout_add` for non-blocking animation

## Compatibility

### Notification daemons

This tool requires a notification daemon that emits `ActionInvoked` D-Bus signals. Notifications **must include at least one action button** for click-to-focus to work.

| Daemon | Status | Notes |
|--------|--------|-------|
| [mako](https://github.com/emersion/mako) | Works | |
| [dunst](https://github.com/dunst-project/dunst) | Works | |
| [swaync](https://github.com/ErikReider/SwayNotificationCenter) | Works | |
| [DMS](https://github.com/System64fumo/dankshell) | Works | Notifications with actions only |

### Applications

| App | Status | Notes |
|-----|--------|-------|
| Claude Code (in kitty) | Works | Uses kitty's OSC notification protocol, which includes a `default` action |
| notify-send | Works | Use `--action="default=Label"` to add an action button |
| Browsers (Firefox, Chromium) | Works | Web notifications typically include actions |
| Plain notify-send (no action) | No focus | No action button = no `ActionInvoked` signal |

## Contributing

Issues and pull requests are welcome at [GitHub](https://github.com/Oaklight/niri-notify-focus).

## License

[MIT](LICENSE)
