# niri-notify-focus

Focus the source application window when you click a desktop notification in [niri](https://github.com/YaLTeR/niri).

When running many instances of the same application (e.g. multiple terminal windows), clicking a notification will jump to the **exact window** that sent it — not just any instance of that app.

## Features

- Maps notifications to source windows via D-Bus PID tracking and process tree walking
- Works with any application that sends notifications (terminals, browsers, etc.)
- Visual pulse effect (brief column width + height expansion) to highlight the focused window
- Runs as a lightweight systemd user service
- Zero configuration required

## Dependencies

- [niri](https://github.com/YaLTeR/niri) (Wayland compositor)
- Python 3
- [dbus-python](https://dbus.freedesktop.org/doc/dbus-python/)
- [PyGObject](https://pygobject.gnome.org/)

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

## Usage

Enable and start the systemd user service:

```bash
systemctl --user enable --now niri-notify-focus
```

That's it. Click any notification action button and the source window will be focused with a brief visual pulse.

### Debug mode

Run in foreground with debug logging:

```bash
niri-notify-focus -d
```

## How it works

1. Monitors D-Bus notification traffic using the `BecomeMonitor` API
2. When a `Notify` method call arrives, resolves the sender PID via `sender-pid` hint or `GetConnectionUnixProcessID`
3. Walks up the process tree (`/proc/<pid>/status` PPid) to find the matching niri window
4. When the user clicks a notification action (`ActionInvoked` signal), focuses the mapped window
5. Briefly pulses the window size as a visual cue to identify it among similar windows

## Note on notification daemons

This tool requires a notification daemon that emits `ActionInvoked` D-Bus signals when the user interacts with a notification. Notifications **must include at least one action button** for the click-to-focus behavior to work. Most notification daemons (mako, dunst, swaync, DMS) support this.

## License

[MIT](LICENSE)
