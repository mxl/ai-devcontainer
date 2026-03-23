# Source this file to get the `claude` and `codex` commands:
#   source /path/to/env.sh
# Or add to your ~/.zshrc / ~/.bashrc:
#   source /path/to/env.sh

claude() {
  local workspace="$PWD"

  echo "Starting devcontainer at: $workspace"
  devcontainer up --workspace-folder "$workspace" || return 1

  echo "Launching Claude..."
  devcontainer exec \
    --workspace-folder "$workspace" \
    claude --dangerously-skip-permissions "$@"
}

codex() {
  local workspace="$PWD"

  echo "Starting devcontainer at: $workspace"
  devcontainer up --workspace-folder "$workspace" || return 1

  echo "Launching Codex..."
  devcontainer exec \
    --workspace-folder "$workspace" \
    codex --yolo "$@"
}

opencode() {
  local workspace="$PWD"

  echo "Starting devcontainer at: $workspace"
  devcontainer up --workspace-folder "$workspace" || return 1

  echo "Launching OpenCode..."
  devcontainer exec \
    --workspace-folder "$workspace" \
    opencode "$@"
}

claude-no-dc() {
  command claude "$@"
}

codex-no-dc() {
  command codex "$@"
}

opencode-no-dc() {
  command opencode "$@"
}
