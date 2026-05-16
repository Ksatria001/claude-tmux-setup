#!/bin/zsh
# Claude Code workspace — run from iTerm2 or Terminal
#
# Layout:
#   +------------------+--------------+
#   |                  |  1.2 Live    |
#   |  1.1  Claude     |  View        |
#   |  (full height)   +--------------+
#   |                  |  1.3 lint +  |
#   |                  |       git    |
#   +------------------+--------------+
#
# Usage: claude-workspace.sh           # attach if session exists, else create
#        claude-workspace.sh --fresh   # always recreate

SESSION="claude"

if [[ "$1" == "--fresh" ]]; then
  tmux kill-session -t $SESSION 2>/dev/null
fi

# Attach to existing session if present
if tmux has-session -t $SESSION 2>/dev/null; then
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
  exec tmux attach-session -t $SESSION
fi

# Create new session — left pane (1.1): Claude Code, full height
tmux new-session -d -s $SESSION -c "$HOME"

# Tokyo Night theme — pane borders + titles
tmux set -t $SESSION pane-border-status top
tmux set -t $SESSION pane-border-style "fg=#565f89"
tmux set -t $SESSION pane-active-border-style "fg=#7dcfff"
tmux set -t $SESSION pane-border-format " #[fg=#7aa2f7]#{pane_title} #[default]"

# Tokyo Night theme — status bar
tmux set -t $SESSION status on
tmux set -t $SESSION status-interval 5
tmux set -t $SESSION status-style "bg=#1a1b26,fg=#c0caf5"
tmux set -t $SESSION status-left " #[fg=#7dcfff,bold]#S#[default] "
tmux set -t $SESSION status-left-length 30
tmux set -t $SESSION status-right "#(~/.local/bin/workspace-status) #[fg=#ff9e64]%H:%M "
tmux set -t $SESSION status-right-length 60

# Split right (40% width) — right column
tmux split-window -t $SESSION:1.1 -h -l 40% -c "$HOME"

# Split right column bottom (40% height) — shell
tmux split-window -t $SESSION:1.2 -v -l 40% -c "$HOME"

# Set pane titles
tmux select-pane -t $SESSION:1.1 -T "claude"
tmux select-pane -t $SESSION:1.2 -T "live view"
tmux select-pane -t $SESSION:1.3 -T "lint + git"

# Start watchers (tmux panes are interactive zsh — .zshrc auto-sources)
tmux send-keys -t $SESSION:1.2 "live-view" Enter
tmux send-keys -t $SESSION:1.3 "lint-status" Enter

# Start Claude Code in left pane
tmux send-keys -t $SESSION:1.1 "claude" Enter

# Focus on Claude pane
tmux select-pane -t $SESSION:1.1

# Attach to session
exec tmux attach-session -t $SESSION
