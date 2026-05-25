# Git worktree helpers (zsh).
# Requires worktree.local.zsh (see worktree.config.example.zsh in this directory).
# Direnv-safe: never cd into worktrees; git runs with a minimal PATH.

[[ -n "$WORKTREE_REPO" ]] || {
  echo "worktree.zsh: set WORKTREE_REPO in ~/.config/zsh/worktree.local.zsh (see newComputerSetup/scripts/worktree/worktree.config.example.zsh)" >&2
  return 1
}

: "${WORKTREE_PARENT_DIR:=${WORKTREE_REPO:h}}"

[[ -n "$WORKTREE_BRANCH_PREFIX" ]] || {
  echo "worktree.zsh: set WORKTREE_BRANCH_PREFIX in ~/.config/zsh/worktree.local.zsh (see newComputerSetup/scripts/worktree/worktree.config.example.zsh)" >&2
  return 1
}

if [[ -z "$WORKTREE_BASE_REF" ]]; then
  WORKTREE_BASE_REF="$(git -C "$WORKTREE_REPO" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)" || true
fi
[[ -n "$WORKTREE_BASE_REF" ]] || {
  echo "worktree.zsh: set WORKTREE_BASE_REF in ~/.config/zsh/worktree.local.zsh (could not detect origin/HEAD)" >&2
  return 1
}

: "${WORKTREE_SUBMODULES:=}"
: "${WORKTREE_EDITOR_CMD:=}"
: "${WORKTREE_PROJECT_LABEL:=${WORKTREE_REPO:t}}"

worktree:_repo() { print -r "$WORKTREE_REPO" }

worktree:_checkout_dir() { print -r "${WORKTREE_PARENT_DIR}/$1" }

worktree:_branch_name() { print -r "${WORKTREE_BRANCH_PREFIX}$1" }

worktree:_git_setup() {
  emulate -L zsh
  export PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
  _WORKTREE_GIT="$(whence -p git 2>/dev/null)"
  [[ -z "$_WORKTREE_GIT" && -x /opt/homebrew/bin/git ]] && _WORKTREE_GIT=/opt/homebrew/bin/git
  [[ -n "$_WORKTREE_GIT" ]] || { echo "git not found in PATH" >&2; return 1 }
  _WORKTREE_GIT_PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:${PATH}"
}

worktree:_git() {
  PATH="$_WORKTREE_GIT_PATH" HOME="$HOME" "$_WORKTREE_GIT" "$@"
}

worktree:_parse_line() {
  local line="$1"
  if [[ "$line" =~ '^([^[:space:]]+)[[:space:]]+([0-9a-f]+)[[:space:]]+\[([^]]+)\]$' ]]; then
    reply=("$match[1]" "$match[2]" "$match[3]")
  elif [[ "$line" =~ '^([^[:space:]]+)[[:space:]]+([0-9a-f]+)' ]]; then
    reply=("$match[1]" "$match[2]" "(detached)")
  else
    reply=()
  fi
}

worktree:_init_submodules() {
  local dir="$1" sub
  for sub in ${=WORKTREE_SUBMODULES}; do
    [[ -n "$sub" ]] || continue
    worktree:_git -C "$dir" submodule update --init "$sub" || return 1
  done
}

worktree() {
  emulate -L zsh
  local repo="$(worktree:_repo)" short_name="$1" branch_name worktree_dir

  if [[ "$PWD" != "$repo"* ]]; then
    echo "Run this from inside the repo"
    echo "Expected: $repo"
    return 1
  fi

  if [[ -z "$short_name" ]]; then
    cat <<EOF
Usage: worktree <feature-name>
       worktree:list    (show open worktrees)
       worktree:clean   (remove a worktree)
Example: worktree checkout-redesign
EOF
    return 1
  fi

  branch_name="$(worktree:_branch_name "$short_name")"
  worktree_dir="$(worktree:_checkout_dir "$short_name")"

  worktree:_git_setup || return 1
  worktree:_git -C "$repo" fetch "${WORKTREE_BASE_REF%%/*}" "${WORKTREE_BASE_REF#*/}" || return 1
  worktree:_git -C "$repo" worktree add -b "$branch_name" "$worktree_dir" "$WORKTREE_BASE_REF" || return 1
  worktree:_init_submodules "$worktree_dir" || return 1

  if [[ -n "$WORKTREE_EDITOR_CMD" ]]; then
    command "$WORKTREE_EDITOR_CMD" "$worktree_dir"
  fi
}

worktree:list() {
  emulate -L zsh
  local repo="$(worktree:_repo)" line path sha branch
  local -i extra_count=0

  worktree:_git_setup || return 1

  print -l "${WORKTREE_PROJECT_LABEL} worktrees:\n"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    worktree:_parse_line "$line"
    path=$reply[1] sha=$reply[2] branch=$reply[3]
    if [[ "$path" == "$repo" ]]; then
      print -l "  main  $path\n        $branch  ${sha:0:8}\n"
    else
      (( extra_count++ ))
      print -l "  • ${path##*/}\n    $path\n    $branch  ${sha:0:8}\n"
    fi
  done < <(worktree:_git -C "$repo" worktree list 2>&1) || {
    echo "Failed to list worktrees" >&2
    return 1
  }

  if (( extra_count == 0 )); then
    echo "No extra worktrees (only main checkout)."
  else
    echo "${extra_count} extra worktree(s). Remove with: worktree:clean"
  fi
}

worktree:_clean_warn() {
  local path="$1"
  typeset -ga WORKTREE_CLEAN_WARN WORKTREE_CLEAN_INFO
  WORKTREE_CLEAN_WARN=() WORKTREE_CLEAN_INFO=()
  local -a submodule_paths
  local wt_status sub_status pline subpath relpath ls_line
  local index_sha head_sha index_short head_short head_subject diff_line

  typeset -A submodule_map
  while IFS= read -r ls_line; do
    [[ "${ls_line%% *}" == "160000" ]] || continue
    subpath="${ls_line#*$'\t'}"
    [[ "$subpath" == "$ls_line" ]] && subpath="${ls_line##* }"
    if [[ -n "$subpath" ]]; then
      submodule_paths+=("$subpath")
      submodule_map[$subpath]=1
    fi
  done < <(worktree:_git -C "$path" ls-files -s 2>/dev/null)

  wt_status=$(worktree:_git -C "$path" status --porcelain 2>/dev/null)
  if [[ -n "$wt_status" ]]; then
    local -a dirty_paths
    local -i dirty_count=0 max_show=12
    local diff_short
    while IFS= read -r pline; do
      [[ -z "$pline" ]] && continue
      relpath="${pline:3}"
      [[ -n "${submodule_map[$relpath]}" ]] && continue
      (( dirty_count++ ))
      (( dirty_count <= max_show )) && dirty_paths+=("$relpath")
    done <<< "$wt_status"
    if (( dirty_count )); then
      WORKTREE_CLEAN_WARN+=("Worktree has uncommitted changes (will be lost):")
      diff_short=$(worktree:_git -C "$path" diff --shortstat 2>/dev/null)
      [[ -n "$diff_short" ]] && WORKTREE_CLEAN_WARN+=("  ${diff_short}")
      for relpath in "${dirty_paths[@]}"; do
        WORKTREE_CLEAN_WARN+=("  ${relpath}")
      done
      (( dirty_count > max_show )) \
        && WORKTREE_CLEAN_WARN+=("  … and $(( dirty_count - max_show )) more file(s)")
    fi
  fi

  for subpath in "${submodule_paths[@]}"; do
    [[ -e "$path/$subpath/.git" || -f "$path/$subpath/.git" ]] || continue

    sub_status=$(worktree:_git -C "$path/$subpath" status --porcelain 2>/dev/null)
    if [[ -n "$sub_status" ]]; then
      WORKTREE_CLEAN_WARN+=("Submodule ${subpath} has uncommitted file changes (will be lost):")
      while IFS= read -r pline; do WORKTREE_CLEAN_WARN+=("  $pline"); done <<< "$sub_status"
      continue
    fi

    index_sha=$(worktree:_git -C "$path" rev-parse ":$subpath" 2>/dev/null) || continue
    head_sha=$(worktree:_git -C "$path/$subpath" rev-parse HEAD 2>/dev/null) || continue
    [[ "$index_sha" == "$head_sha" ]] && continue

    index_short="${index_sha:0:8}" head_short="${head_sha:0:8}"
    head_subject=$(worktree:_git -C "$path/$subpath" log -1 --oneline 2>/dev/null)
    WORKTREE_CLEAN_INFO+=(
      "Submodule ${subpath}: parent index pins ${index_short}, checkout is ${head_short}"
      "  checkout commit: ${head_subject}"
      "  (No uncommitted files inside submodule. Commits are kept in .git/modules.)"
    )
  done
}

worktree:clean() {
  emulate -L zsh
  local repo="$(worktree:_repo)"
  local -a paths branches labels warnings infos
  local line path branch label i choice query found wt_output

  worktree:_git_setup || return 1

  wt_output=$(worktree:_git -C "$repo" worktree list 2>&1) || {
    echo "Failed to list worktrees: $wt_output" >&2
    return 1
  }
  for line in "${(@f)wt_output}"; do
    [[ -z "$line" ]] && continue
    worktree:_parse_line "$line"
    path=$reply[1] branch=$reply[3]
    [[ "$path" == "$repo" ]] && continue
    paths+=("$path") branches+=("$branch")
    labels+=("${path##*/}  [$branch]")
  done
  (( ${#paths} )) || { echo "No extra worktrees to remove."; return 0 }

  if [[ -n "${1:-}" ]]; then
    query="$1" found=0
    for i in {1..${#paths}}; do
      if [[ "${paths[$i]}" == *"$query"* || "${branches[$i]}" == *"$query"* \
          || "${paths[$i]##*/}" == "$query" ]]; then
        choice="$i" found=1; break
      fi
    done
    if (( ! found )); then
      echo "No worktree matching: $query\n\nOpen worktrees:"
      for label in "${labels[@]}"; do echo "  • $label"; done
      return 1
    fi
  else
    echo "Open worktrees:"
    PS3="Select worktree to remove (number): "
    select label in "${labels[@]}" "Cancel"; do
      [[ -z "$REPLY" || "$label" == "Cancel" ]] && return 0
      choice="$REPLY"; break
    done
  fi

  path="${paths[$choice]}" branch="${branches[$choice]}"
  local wt_name="${path##*/}" feature_branch="$(worktree:_branch_name "$wt_name")" step=1

  print -l "" "Plan:"
  print -l "  ${step}. Remove worktree checkout: $path"
  (( step++ ))
  print -l "     Checked-out branch: $branch (local ref stays in main repo)"
  if worktree:_git -C "$repo" show-ref --verify --quiet "refs/heads/${feature_branch}" \
     && [[ "$branch" != "$feature_branch" ]]; then
    print -l "     Also kept: ${feature_branch}"
  fi
  if [[ -f "$path/.gitmodules" ]]; then
    print -l "  ${step}. Deinitialize submodules (submodule deinit -f --all)"
    (( step++ ))
  fi
  print -l "  ${step}. Unregister worktree from ${repo} (worktree remove, --force if needed)"
  (( step++ ))
  print -l "  ${step}. Prune worktree metadata (worktree prune)"
  print -l "  • Will not delete any branches"

  print -n "Checking for uncommitted changes... "
  worktree:_clean_warn "$path"
  print "done."
  warnings=("${WORKTREE_CLEAN_WARN[@]}")
  infos=("${WORKTREE_CLEAN_INFO[@]}")
  unset WORKTREE_CLEAN_WARN WORKTREE_CLEAN_INFO

  (( ${#infos} )) && print -l "" "${infos[@]}"
  if (( ${#warnings} )); then
    print -l "" "⚠️  Uncommitted work in this checkout will be lost:" "${warnings[@]}" ""
  fi

  print -n 'Proceed? [y/N] '
  read -k 1 -r _confirm
  echo
  [[ "$_confirm" == [yY] ]] || return 0

  if [[ -f "$path/.gitmodules" ]]; then
    echo "→ Deinitializing submodules..."
    worktree:_git -C "$path" submodule deinit -f --all 2>/dev/null \
      || echo "  (deinit skipped — will force-remove worktree)"
  fi

  echo "→ Removing worktree $path ..."
  worktree:_git -C "$repo" worktree remove "$path" 2>/dev/null \
    || { echo "  Retrying with --force..."; worktree:_git -C "$repo" worktree remove --force "$path" || return 1; }

  echo "→ Pruning worktree metadata..."
  worktree:_git -C "$repo" worktree prune
  echo "Done. Checkout removed; branch refs unchanged ($branch)."
}
