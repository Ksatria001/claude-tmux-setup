# claude-tmux-setup

A 3-pane tmux workspace for [Claude Code](https://claude.com/claude-code) with a live file renderer and a per-language linter + git status companion.

> **Platform:** macOS only. The scripts hardcode `/bin/zsh` shebangs and assume macOS home-directory conventions (`~/Developer`, `~/Documents`, `~/Desktop`). They have not been tested on Linux or WSL.

## Layout

```
+------------------+--------------+
|                  |  Live View   |
|     Claude       |  (file       |
|     Code         |   renderer)  |
|  (full height)   +--------------+
|                  |  lint + git  |
+------------------+--------------+
```

- **`claude-workspace.sh`** — launcher. Idempotent: attaches to an existing `claude` tmux session, or builds a fresh one. Pass `--fresh` to force rebuild.
- **`live-view`** — fswatch + bat: renders any code file you edit (in watched locations) into the top-right pane.
- **`lint-status`** — runs the appropriate linter on the changed file (`shellcheck`, `dart analyze`, `php -l`, `jq`, `ruby -ryaml`, etc.) and shows `git status -sb` for the file's repo, in the bottom-right pane.
- **`workspace-status`** — emits a tmux status-line indicator (green/red dots for claude / live-view / lint).

## Requirements

Install via Homebrew:

```sh
brew install tmux fswatch bat shellcheck jq
```

Optional (lint-status uses them when present):

```sh
brew install ruff phpstan
# dart/flutter: install Flutter SDK directly
# eslint/biome: install locally in your JS/TS project (npm i -D)
```

## Install

```sh
git clone https://github.com/Ksatria001/claude-tmux-setup.git
cp claude-tmux-setup/claude-workspace.sh ~/
chmod +x ~/claude-workspace.sh
mkdir -p ~/.local/bin
cp claude-tmux-setup/{live-view,lint-status,workspace-status} ~/.local/bin/
chmod +x ~/.local/bin/{live-view,lint-status,workspace-status}
```

Make sure `~/.local/bin` is on your `PATH`.

## Run

### Single workspace (legacy default)

```sh
~/claude-workspace.sh           # attach if a `claude` session exists, else build fresh
~/claude-workspace.sh --fresh   # kill the session and rebuild
```

### Multiple named workspaces (one tmux session per project)

```sh
~/claude-workspace.sh omenqa ~/Developer/Projects/omenqa
~/claude-workspace.sh tmux-setup ~/Developer/claude-tmux-setup
~/claude-workspace.sh --fresh omenqa ~/Developer/Projects/omenqa
```

The first argument is the project name; the second (optional) is the working directory each pane starts in. Each named workspace becomes its own tmux session called `claude-<name>` with the same 3-pane layout. The status-bar dots reflect each session's own panes.

Switch between sessions from inside tmux with `Ctrl-B s` (session picker) or run `tmux switch-client -t claude-<name>` directly.

### Notes

Run from a terminal **outside** any session you intend to `--fresh` — killing the session also kills the Claude Code process running inside it.

## Theme

Tokyo Night. Adjust the hex colors in `claude-workspace.sh` (status bar, pane borders) and the `bat --theme=` flag in `live-view` to swap palettes.
