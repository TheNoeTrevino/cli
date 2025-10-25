# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of shell scripts for automating development workflows, particularly for managing tmux sessions and git worktrees. The repository uses git worktrees to manage multiple working directories from a single repository.

## Repository Structure

The repository uses git worktrees:
- Main repository: `/home/noetrevino/projects/cli/cli.git`
- Worktrees are created as siblings (e.g., `/home/noetrevino/projects/cli/feature`)

Scripts are organized in directories:
- `startups/`: tmux session startup scripts for different projects
- `cli/`: command-line utilities for repository/worktree management

## Key Scripts

### startups/tremolo.sh

Creates a tmux session for the "tremolo" project with multiple windows:
- Expects a worktree name as argument
- Sets up windows for: editor (nvim), frontend (npm), music backend (Python/Django), main backend (Go)
- Automatically runs setup commands (npm ci, pip install, migrations, etc.)
- Sources environment from `~/scripts/envs/tremolo.sh`

Usage: `./startups/tremolo.sh <worktree-name>`

### cli/worktrees.sh

Interactive worktree selector and script runner:
- Uses `gum` for interactive selection menus
- Uses `fd` for fast repository discovery
- Scans for git repositories under `$HOME/projects`
- Lists available worktrees for selected repository
- Allows running scripts from parent directory on selected worktree

Dependencies: `gum`, `fd`

## Development Notes

### Script Conventions

- All scripts use bash with `set -euo pipefail` (where applicable)
- Scripts check for required arguments and provide usage messages
- tmux session names follow pattern: `<project>-<worktree>`
- Worktree directory structure: `$HOME/projects/<repo>/<worktree-name>`

### Adding New Startup Scripts

When adding new project startup scripts to `startups/`:
1. Accept worktree name as first argument
2. Validate worktree directory exists
3. Create/kill existing tmux session with unique name
4. Set up windows with appropriate working directories
5. Source environment variables as needed
6. Use `send_env()` pattern if environment setup is repeated

### Git Worktree Workflow

This repository itself uses worktrees:
- Main branch: `main` (in cli.git)
- Feature branches: separate worktree directories
- Use `git worktree list` to see all worktrees
- Use `cli/worktrees.sh` for interactive worktree selection

## Project Goal

The eventual goal is to create a CLI that facilitates worktree creation:
1. Scan projects directory and list available repositories
2. Allow user to select a repository
3. Prompt for worktree creation (branch name, base branch, etc.)
4. After creation, optionally run startup scripts from the project directory
