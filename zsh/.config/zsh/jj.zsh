# Jujutsu (jj) shell utilities

# Create a jj workspace with a colocated git worktree so tools like codediff
# that rely on git can resolve commits in the workspace.
# Usage: jjw <path> [jj workspace add args...]
jjw() {
  local dest="$1"
  if [[ -z "$dest" ]]; then
    echo "Usage: jjw <path> [jj workspace add args...]"
    return 1
  fi
  shift

  local git_dir
  git_dir="$(git rev-parse --git-dir 2>/dev/null)" || {
    echo "Error: not in a git repository (colocated jj repo required)"
    return 1
  }
  git_dir="$(cd "$(dirname "$git_dir")" && pwd)/$(basename "$git_dir")"

  local ws_name="${dest:t}"

  jj workspace add "$dest" "$@" || return 1
  git worktree add --detach "$dest" || {
    echo "Warning: git worktree add failed — codediff may not work in this workspace"
    return 1
  }

  echo "Workspace '$ws_name' created at $dest (jj + git worktree)"
}
