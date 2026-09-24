# Athena Kanban for Omarchy

A lightweight, keyboard-friendly task management plugin for the Omarchy shell. Replaces simple lists with a native floating window Kanban board, featuring WIP limits and detailed time-tracking.

---

## Features

- 📋 **Floating Window Board:** A full, independent Wayland surface for organizing tasks across To Do, In Progress, and Done lanes.
- 🛡️ **WIP Limit Management:** Built-in Work-In-Progress (WIP) limits with visual badges that turn red when your focus lane is overloaded.
- ⏱️ **Advanced Time Tracking:**
  - **Creation Timestamps:** Every task displays its exact creation date and time.
  - **Live Stopwatch:** Tasks in the "In Progress" lane feature a real-time `HH:mm:ss` counter.
  - **Lifecycle Metrics:** Completed tasks show a summary of time spent:
    - `[l]`: Lead time (Creation $\rightarrow$ Progress)
    - `[d]`: Cycle time (Progress $\rightarrow$ Done)
    - `[t]`: Total time (Creation $\rightarrow$ Done)
- 📊 **Bar Integration:** Compact status bar widget showing current WIP count and serving as a one-click launcher for the board.

---

## Dependencies & Requirements

- **Omarchy Linux** (Quickshell compositor shell)
- **Hyprland** (for window rules and keybindings)

---

## Installation

### Via Omarchy Marketplace / CLI (Recommended)

```bash
omarchy plugin add https://github.com/renefoster/athena-kanban --enable
```

### Manual Git Installation

```bash
git clone https://github.com/renefoster/athena-kanban \
  ~/.config/omarchy/plugins/renefoster.athena-kanban

omarchy plugin enable renefoster.athena-kanban
omarchy-restart-shell
```

### Recommended Keybinding

Add this to your `~/.config/hypr/bindings.lua` to toggle the board with `Super+Shift+K`:

```lua
o.bind("SUPER SHIFT", "K", "omarchy-shell shell toggle renefoster.athena-kanban '{}'")
```

---

## Removal

To disable and remove the plugin:

```bash
omarchy plugin disable renefoster.athena-kanban
omarchy plugin remove renefoster.athena-kanban --yes
omarchy-restart-shell
```

---

## Implementation Details

Athena Kanban follows the Omarchy plugin architecture using QML for the interface and pure JavaScript for state management. Data is persisted in a local JSON file (`~/.config/omarchy/kanban_data.json`) to ensure fast load times and CLI interoperability.
