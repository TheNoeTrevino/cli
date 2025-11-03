# Scripts

## Worktrees Script

A script to help starting projects. Basically you have work trees, and a script
to start it all up. It is almost like a little UI for starting up your projects.
Plays super nice with Tmux

### Directory Structure

Projects directory:
``` bash
~/projects/
```

How a project with worktrees would be setup:
``` bash
cd ~/projects/project.git/
ls
- worktree1/
- worktree2/
- worktree3/
- startup.sh
- env.sh
```

### Dependencies

gum - for the UI
