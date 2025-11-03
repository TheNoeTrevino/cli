#!/usr/bin/env bash
set -euo pipefail

root_dir="$HOME/projects"
scripts_dir="$root_dir/" # centralized scripts folder, one level above all projects

echo "⚡ Scanning for Git repositories under: $root_dir"
echo

# --- Fast repo search using fd ---
repos=$(fd ".git$" "$root_dir" --type d --hidden --prune --absolute-path 2>/dev/null | sed 's|/.git$||')

if [[ -z "$repos" ]]; then
  gum style --foreground 1 "No git repositories found under $root_dir"
  exit 0
fi

# --- Select a repository ---
selected_repo=$(echo "$repos" | gum choose --header "Select a repository:")

echo
gum style --foreground 2 "📂 Repository:"
gum style --border normal --padding "1 2" "$selected_repo"
echo

# --- Choose action: select existing or create new ---
action=$(printf "Select existing worktree\nCreate new worktree\nDelete worktree" | gum choose --header "What would you like to do?")

if [[ "$action" == "Create new worktree" ]]; then
  gum style --foreground 3 "🌱 Creating new worktree..."
  echo

  # Move into the repository to access git commands
  cd "$selected_repo"

  # --- Select base branch ---
  gum style --foreground 6 "Step 1: Select base branch"
  branches=$(git branch -a | sed 's/^[* ]*//' | sed 's/remotes\/origin\///' | sort -u | grep -v '^HEAD')
  base_branch=$(echo "$branches" | gum filter --placeholder "Search branches..." --header "Select base branch to branch from:" --height 10)

  echo
  gum style --foreground 2 "Base branch: $base_branch"
  echo

  # --- Input new branch name ---
  gum style --foreground 6 "Step 2: Enter new branch name"
  new_branch=$(gum input --placeholder "my-feature-branch")

  if [[ -z "$new_branch" ]]; then
    gum style --foreground 1 "Error: Branch name cannot be empty"
    exit 1
  fi

  echo
  gum style --foreground 2 "New branch: $new_branch"
  echo

  # --- Generate worktree path ---
  gum style --foreground 6 "Step 3: Enter worktree directory name"
  repo_parent=$(dirname "$selected_repo")
  default_worktree_name="$new_branch"
  worktree_name=$(gum input --placeholder "$default_worktree_name" --value "$default_worktree_name")

  if [[ -z "$worktree_name" ]]; then
    worktree_name="$default_worktree_name"
  fi

  worktree_path="$repo_parent/$worktree_name"

  echo
  gum style --foreground 2 "Worktree path: $worktree_path"
  echo

  # --- Create worktree ---
  gum style --foreground 6 "Creating worktree..."
  if git worktree add -b "$new_branch" "$worktree_path" "$base_branch" 2>&1; then
    gum style --foreground 2 "✅ Worktree created successfully!"
    selected_tree="$worktree_path"
  else
    gum style --foreground 1 "❌ Failed to create worktree"
    exit 1
  fi

  echo
fi

if [[ "$action" == "Delete worktree" ]]; then
  gum style --foreground 3 "🗑️  Delete worktree..."
  echo

  # Move into the repository to access git commands
  cd "$selected_repo"

  # --- List worktrees ---
  worktrees=$(git worktree list --porcelain 2>/dev/null | awk '/worktree / {print $2}')

  if [[ -z "$worktrees" ]]; then
    gum style --foreground 1 "No worktrees found to delete"
    exit 0
  fi

  # Filter out the main worktree (usually we don't want to delete it)
  main_worktree=$(git worktree list --porcelain 2>/dev/null | awk '/worktree / {print $2; exit}')
  worktrees_to_delete=$(echo "$worktrees" | grep -v "^$main_worktree$")

  if [[ -z "$worktrees_to_delete" ]]; then
    gum style --foreground 1 "No additional worktrees found to delete (only main worktree exists)"
    exit 0
  fi

  # --- Select worktree to delete ---
  worktree_to_delete=$(echo "$worktrees_to_delete" | gum choose --header "Select worktree to delete:")

  if [[ -z "$worktree_to_delete" ]]; then
    gum style --foreground 3 "No worktree selected. Exiting."
    exit 0
  fi

  echo
  gum style --foreground 1 "⚠️  Warning: You are about to delete:"
  gum style --border normal --padding "1 2" --foreground 1 "$worktree_to_delete"
  echo

  # --- Confirm deletion ---
  if gum confirm "Are you sure you want to delete this worktree?"; then
    gum style --foreground 6 "Deleting worktree..."
    if git worktree remove "$worktree_to_delete" 2>&1; then
      gum style --foreground 2 "✅ Worktree deleted successfully!"
    else
      gum style --foreground 1 "❌ Failed to delete worktree. It may have uncommitted changes."
      echo
      if gum confirm "Force delete anyway? (This will discard any changes)"; then
        if git worktree remove --force "$worktree_to_delete" 2>&1; then
          gum style --foreground 2 "✅ Worktree force deleted successfully!"
        else
          gum style --foreground 1 "❌ Failed to force delete worktree"
          exit 1
        fi
      else
        gum style --foreground 3 "Deletion cancelled."
        exit 0
      fi
    fi
  else
    gum style --foreground 3 "Deletion cancelled."
    exit 0
  fi

  exit 0
fi

# --- Check for worktrees ---
cd "$selected_repo"

main_worktree="$selected_repo"
worktrees=$(git worktree list --porcelain 2>/dev/null | awk '/worktree / {print $2}')

if [[ -z "$worktrees" ]]; then
  gum style --foreground 3 "No additional worktrees found."
  echo
  gum style --foreground 6 "Main worktree:"
  gum style --border normal --padding "1 2" "$main_worktree"
  selected_tree="$main_worktree"
else
  # --- Let the user select one worktree ---
  selected_tree=$(echo "$worktrees" | gum choose --header "Select a worktree:")
  echo
  gum style --foreground 2 "✅ You selected worktree:"
  gum style --border normal --padding "1 2" "$selected_tree"
fi

# --- List scripts in the centralized scripts dir ---
if [[ ! -d "$scripts_dir" ]]; then
  gum style --foreground 1 "Scripts directory not found: $scripts_dir"
  exit 1
fi

scripts=(".."/*.sh)
if [[ ${#scripts[@]} -eq 0 ]]; then
  gum style --foreground 3 "No scripts found in $scripts_dir"
  exit 0
fi

echo
gum style --foreground 2 "Available scripts:"
script_choice=$(printf "%s\n" "${scripts[@]##*/}" | gum choose --header "Select a script to run:")

# --- Run the selected script ---
selected_script="$scripts_dir/$script_choice"
gum style --foreground 2 "🚀 Running script '$selected_script' on worktree '$selected_tree'..."
"$selected_script" "$selected_tree"
