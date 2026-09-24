# Athena Kanban

A lightweight, keyboard-friendly task management plugin for the Omarchy shell.

## Features
- **Floating Window Board**: Full-screen Kanban board managed as a native Wayland surface.
- **WIP Limits**: Visual indicators and badges to prevent overloading the "In Progress" lane.
- **Time Tracking**: 
  - Creation timestamps on all cards.
  - Live stopwatch for tasks in progress.
  - Detailed duration summaries for completed tasks:
    - `[l]`: Time from creation to progress.
    - `[d]`: Time spent in progress.
    - `[t]`: Total time from creation to completion.
- **Bar Integration**: Compact status bar widget showing current WIP count.

## Installation
1. Copy the plugin folder to `~/.config/omarchy/plugins/local.athena-kanban/`.
2. Add the following to your `shell.json` or use `omarchy bar` commands to add the `bar-widget`.
3. (Optional) Add a Hyprland keybinding to toggle the board:
   \`\`\`lua
   o.bind("SUPER SHIFT", "K", "omarchy-shell shell toggle local.athena-kanban '{}'")
   \`\`\`

## File Structure
- `manifest.json`: Plugin metadata and entry points.
- `BarWidget.qml`: Status bar indicator.
- `KanbanWindow.qml`: Floating window UI.
- `Model.js`: Business logic and time calculations.
