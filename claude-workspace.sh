#!/bin/zsh
# Claude Code workspace — run from iTerm2 or Terminal
#
# Layout (per session):
#   +------------------+--------------+
#   |                  |  1.2 Live    |
#   |  1.1  Claude     |  View        |
#   |  (full height)   +--------------+
#   |                  |  1.3 lint +  |
#   |                  |       git    |
#   +------------------+--------------+
#
# Usage:
#   claude-workspace.sh                              # session "claude", panes in $HOME (legacy default)
#   claude-workspace.sh <name>                       # session "claude-<name>", panes in $HOME
#   claude-workspace.sh <name> <path>                # session "claude-<name>", panes start in <path>
#   claude-workspace.sh --fresh [<name>] [<path>]    # kill that session first, then create fresh
#
# Examples:
#   claude-workspace.sh omenqa ~/Developer/Projects/omenqa
#   claude-workspace.sh tmux-setup ~/Developer/Projects/claude-tmux-setup
#   claude-workspace.sh --fresh omenqa ~/Developer/Projects/omenqa
#
# Each named workspace is a SEPARATE tmux session. Switch between them
# with `tmux switch-client -t claude-<name>` (or Ctrl-B s to pick from a list).

# Parse args: optional --fresh flag, then optional <name>, then optional <path>
FRESH=0
if [[ "$1" == "--fresh" ]]; then
  FRESH=1
  shift
fi

NAME="$1"
WORKDIR="${2:-$HOME}"

# Validate WORKDIR if provided
if [[ -n "$2" && ! -d "$WORKDIR" ]]; then
  echo "claude-workspace: path does not exist: $WORKDIR" >&2
  exit 1
fi

# Session name: "claude" if no name, "claude-<name>" otherwise
if [[ -n "$NAME" ]]; then
  SESSION="claude-$NAME"
else
  SESSION="claude"
fi

if (( FRESH )); then
  tmux kill-session -t "$SESSION" 2>/dev/null
fi

# Attach to existing session if present
if tmux has-session -t "$SESSION" 2>/dev/null; then
  # Restart helpers in their panes if not already running.
  # (pane_current_command is unreliable for pipelines on macOS; check the process tree instead.
  #  macOS pgrep -P needs a pattern, so use ps to detect any child of the pane shell.)
  restart_if_idle() {
    local pane_idx=$1 cmd=$2
    local pid
    pid=$(tmux display-message -t "$SESSION:$pane_idx" -p '#{pane_pid}' 2>/dev/null)
    if [[ -n "$pid" ]] && ! ps -A -o ppid= | grep -qE "^[[:space:]]*${pid}\$"; then
      tmux send-keys -t "$SESSION:$pane_idx" "$cmd" Enter
    fi
  }
  restart_if_idle 1.2 live-view
  restart_if_idle 1.3 lint-status
  exec tmux attach-session -t "$SESSION"
fi

# Create new session — left pane (1.1): Claude Code, full height
tmux new-session -d -s "$SESSION" -c "$WORKDIR"

# Tokyo Night theme — pane borders + titles
tmux set -t "$SESSION" pane-border-status top
tmux set -t "$SESSION" pane-border-style "fg=#565f89"
tmux set -t "$SESSION" pane-active-border-style "fg=#7dcfff"
tmux set -t "$SESSION" pane-border-format " #[fg=#7aa2f7]#{pane_title} #[default]"

# Tokyo Night theme — status bar
# Pass session name to workspace-status via tmux's #S format so each
# session's status bar reports its OWN pane health (not a hardcoded "claude").
tmux set -t "$SESSION" status on
tmux set -t "$SESSION" status-interval 5
tmux set -t "$SESSION" status-style "bg=#1a1b26,fg=#c0caf5"
tmux set -t "$SESSION" status-left " #[fg=#7dcfff,bold]#S#[default] "
tmux set -t "$SESSION" status-left-length 40
tmux set -t "$SESSION" status-right "#(~/.local/bin/workspace-status #S) #[fg=#ff9e64]%H:%M "
tmux set -t "$SESSION" status-right-length 60

# Split right (40% width) — right column
tmux split-window -t "$SESSION:1.1" -h -l 40% -c "$WORKDIR"

# Split right column bottom (40% height) — shell
tmux split-window -t "$SESSION:1.2" -v -l 40% -c "$WORKDIR"

# Set pane titles
tmux select-pane -t "$SESSION:1.1" -T "claude"
tmux select-pane -t "$SESSION:1.2" -T "live view"
tmux select-pane -t "$SESSION:1.3" -T "lint + git"

# Start watchers (tmux panes are interactive zsh — .zshrc auto-sources)
tmux send-keys -t "$SESSION:1.2" "live-view" Enter
tmux send-keys -t "$SESSION:1.3" "lint-status" Enter

# Start Claude Code in left pane
tmux send-keys -t "$SESSION:1.1" "claude" Enter

# Focus on Claude pane
tmux select-pane -t "$SESSION:1.1"

# Attach to session
exec tmux attach-session -t "$SESSION"
