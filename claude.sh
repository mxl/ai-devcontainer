# Source this file to get the `claude` command:
#   source /path/to/claude.sh
# Or add to your ~/.zshrc / ~/.bashrc:
#   source /path/to/claude.sh

claude() {
  local workspace="$PWD"

  echo "Starting devcontainer at: $workspace"
  devcontainer up --workspace-folder "$workspace" || return 1

  echo "Launching Claude..."
  devcontainer exec \
    --workspace-folder "$workspace" \
    claude --dangerously-skip-permissions "$@"
}
