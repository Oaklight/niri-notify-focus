# niri-notify-focus

**中文** | [English](README_en.md)

点击桌面通知时，自动跳转到 [niri](https://github.com/YaLTeR/niri) 中发送通知的源窗口。

## 问题

当你同时运行多个相同应用的实例——多个 [Claude Code](https://github.com/anthropics/claude-code) 终端窗口、多个浏览器配置等——通知只会告诉你*发生了某事*，但点击它无法跳转到**发送通知的那个窗口**。你只能手动在工作区间翻找。

## 解决方案

`niri-notify-focus` 是一个轻量守护进程，它被动监控 D-Bus 通知流量，将每条通知映射回其源窗口，并在你点击通知操作按钮时聚焦该窗口。短暂的窗口尺寸脉冲效果帮助你在外观相同的窗口中快速定位目标。

## 特性

- **精准窗口定位** — 通过 D-Bus PID 追踪和进程树遍历，将通知映射到源窗口，即使通知进程是窗口进程的子进程也能正确识别
- **适用于任何应用** — 终端（kitty、alacritty、wezterm）、浏览器、IDE 等任何发送桌面通知的应用
- **视觉脉冲反馈** — 短暂脉冲窗口宽度和高度后恢复，让你在相似窗口中立即识别目标（可配置：内缩、外扩或无效果）
- **非阻塞** — 所有 niri IPC 调用和定时器通过 GLib 异步运行，无卡顿
- **自动恢复** — D-Bus 错误时自动重连，作为 systemd 用户服务运行，失败自动重启
- **可选配置** — 开箱即用，提供合理默认值；需要时通过简单的 TOML 文件自定义

## 依赖

- [niri](https://github.com/YaLTeR/niri)（滚动平铺 Wayland 合成器）
- Python 3
- [dbus-python](https://dbus.freedesktop.org/doc/dbus-python/)
- [PyGObject](https://pygobject.gnome.org/)（GLib 主循环集成）
- 支持发出 `ActionInvoked` D-Bus 信号的通知守护进程（mako、dunst、swaync、[DMS](https://github.com/System64fumo/dankshell) 等）

## 安装

### Arch Linux (AUR)

```bash
# 使用 AUR 助手
paru -S niri-notify-focus

# 或手动安装
git clone https://aur.archlinux.org/niri-notify-focus.git
cd niri-notify-focus
makepkg -si
```

### 手动安装

```bash
git clone https://github.com/Oaklight/niri-notify-focus.git
cd niri-notify-focus
sudo make install
```

### 卸载

```bash
sudo make uninstall
systemctl --user disable niri-notify-focus
```

## 使用

启用并启动 systemd 用户服务：

```bash
systemctl --user enable --now niri-notify-focus
```

就这样。点击任何通知操作按钮，源窗口将被聚焦并伴有短暂的视觉脉冲。

### 配置

可选创建 `~/.config/niri-notify-focus/config.toml` 来自定义行为。所有设置都有合理的默认值——该文件不是必需的。

```toml
# 聚焦窗口时的视觉效果
# 选项："shrink"（内缩脉冲）、"expand"（外扩脉冲）、"none"（仅聚焦）
effect = "shrink"

# 脉冲动画的像素偏移量
pulse_pixels = 50
```

示例配置文件安装在 `/usr/share/doc/niri-notify-focus/config.toml.example`。

### 测试

发送一条带操作按钮的测试通知：

```bash
notify-send "测试" "点击按钮跳转" --action="default=跳转"
```

切换到其他工作区，然后点击操作按钮——你应该会被带到发送通知的工作区和窗口，并看到可见的尺寸脉冲。

### 调试模式

在前台运行并输出详细日志以排查问题：

```bash
# 先停止服务
systemctl --user stop niri-notify-focus

# 手动运行并输出调试信息
niri-notify-focus -d
```

## 工作原理

```
┌─────────────┐    D-Bus Notify     ┌───────────────────┐
│  应用程序    │ ──────────────────► │  通知守护进程      │
│  (kitty,    │    (携带 PID 提示   │  (mako/dunst/DMS)  │
│   浏览器)   │     或总线发送者)   │                    │
└─────────────┘                     └───────┬───────────┘
       │                                    │
       │ PID                                │ ActionInvoked 信号
       ▼                                    ▼
┌─────────────────────────────────────────────────────┐
│                 niri-notify-focus                    │
│                                                     │
│  1. 通过 BecomeMonitor 拦截 Notify 调用             │
│  2. 解析发送者 PID（提示或 GetConnectionPID）        │
│  3. 遍历 /proc PID 树 → 找到 niri 窗口              │
│  4. 存储：notification_id → window_id               │
│  5. 收到 ActionInvoked → 聚焦 + 脉冲窗口            │
└─────────────────────────────────────────────────────┘
```

1. 使用 D-Bus `BecomeMonitor` API 被动观察所有通知流量
2. 当 `Notify` 方法调用到达时，通过 `sender-pid` 提示（由 libnotify 设置）解析发送者 PID，或回退到 `GetConnectionUnixProcessID`
3. 通过 `/proc/<pid>/status`（PPid 字段）向上遍历进程树，找到匹配的 niri 窗口——这处理了通知进程是窗口进程子进程的情况
4. 将 `Notify` 调用与其方法返回关联，映射 `notification_id → window_id`
5. 当用户点击通知操作（`ActionInvoked` 信号）时，聚焦映射的窗口并通过 `GLib.timeout_add` 触发短暂的尺寸脉冲（宽度和高度 ±像素后恢复），实现非阻塞动画

## 兼容性

### 通知守护进程

本工具需要能发出 `ActionInvoked` D-Bus 信号的通知守护进程。通知**必须包含至少一个操作按钮**才能触发点击聚焦。

| 守护进程 | 状态 | 备注 |
|---------|------|------|
| [mako](https://github.com/emersion/mako) | 可用 | |
| [dunst](https://github.com/dunst-project/dunst) | 可用 | |
| [swaync](https://github.com/ErikReider/SwayNotificationCenter) | 可用 | |
| [DMS](https://github.com/System64fumo/dankshell) | 可用 | 仅限带操作的通知 |

### 应用程序

| 应用 | 状态 | 备注 |
|-----|------|------|
| Claude Code（在 kitty 中） | 可用 | 使用 kitty 的 OSC 通知协议，包含 `default` 操作 |
| notify-send | 可用 | 使用 `--action="default=标签"` 添加操作按钮 |
| 浏览器（Firefox、Chromium） | 可用 | Web 通知通常包含操作 |
| 普通 notify-send（无操作） | 无法聚焦 | 没有操作按钮 = 没有 `ActionInvoked` 信号 |

## 贡献

欢迎在 [GitHub](https://github.com/Oaklight/niri-notify-focus) 上提交 Issue 和 Pull Request。

## 许可证

[MIT](LICENSE)
