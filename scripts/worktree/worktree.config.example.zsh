# Copy to ~/.config/zsh/worktree.local.zsh and adjust for your machine.
# Sourced from ~/.zshrc before newComputerSetup/scripts/worktree/worktree.zsh

export WORKTREE_REPO="$HOME/Development/company"
# WORKTREE_PARENT_DIR defaults to the parent of WORKTREE_REPO (sibling checkouts)
# export WORKTREE_PARENT_DIR="$HOME/Development/company"
export WORKTREE_BRANCH_PREFIX="${USER}/"   # e.g. milok/my-feature
# WORKTREE_BASE_REF is optional; defaults to origin/HEAD (e.g. origin/main)
# export WORKTREE_BASE_REF="origin/master"
export WORKTREE_SUBMODULES=""  # space-separated; leave empty for none
export WORKTREE_EDITOR_CMD=""          # e.g. cursor, code, or "" to skip
export WORKTREE_PROJECT_LABEL="Worktree"
