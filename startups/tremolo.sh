if [ $# -ne 1 ]; then
  echo "Usage: $0 <worktree-name>"
  exit 1
fi

WORKTREE="$1"
REPO_DIR="$HOME/projects/tremolo.git"
WORKTREE_DIR="$REPO_DIR/$WORKTREE"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "Error: Worktree directory '$WORKTREE_DIR' does not exist."
  echo "Usage: $0 <worktree-name>"
  exit 1
fi

SESSION_NAME="tremolo-$WORKTREE"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

send_env() {
  local target="$1"
  tmux send-keys -t "$target" "source ~/scripts/envs/tremolo.sh && dev && echo $DATABASE_URL" C-m
}

tmux new-session -d -s $SESSION_NAME -c "$WORKTREE_DIR" -n "editor"
tmux send-keys -t $SESSION_NAME:editor "npm ci && clear" C-m

# nvim window
tmux send-keys -t $SESSION_NAME:editor "nvim" C-m
send_env "$SESSION_NAME:nvim"

# npm dev window
tmux new-window -t $SESSION_NAME -n "frontend" -c "$WORKTREE_DIR/frontend"
send_env "$SESSION_NAME:frontend"
tmux send-keys -t $SESSION_NAME:frontend "npm ci && npm run dev" C-m

# python music service window
tmux new-window -t $SESSION_NAME -n "music" -c "$WORKTREE_DIR/backend/music"
send_env "$SESSION_NAME:music"
tmux send-keys -t $SESSION_NAME:music "python3 -m venv env" C-m
tmux send-keys -t $SESSION_NAME:music "source env/bin/activate" C-m
tmux send-keys -t $SESSION_NAME:music "pip install -r requirements.txt" C-m
tmux send-keys -t $SESSION_NAME:music "python3 manage.py migrate" C-m
tmux send-keys -t $SESSION_NAME:music "python3 manage.py runserver" C-m

# go user service window
tmux new-window -t $SESSION_NAME -n "main" -c "$WORKTREE_DIR/backend/main"
send_env "$SESSION_NAME:main"
tmux send-keys -t $SESSION_NAME:main "go run main.go" C-m

tmux attach -t $SESSION_NAME
