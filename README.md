# Claude + Codex Devcontainer

A sandboxed development container for running [Claude Code](https://code.claude.com) and [OpenAI Codex](https://github.com/openai/codex) with network isolation via firewall rules.

## Requirements

- [Docker](https://www.docker.com/)
- [Dev Container CLI](https://github.com/devcontainers/cli): `npm install -g @devcontainers/cli`

## Usage

Source the included shell script to get `claude` and `codex` commands that start the devcontainer and launch the selected CLI in one step, plus `claude-no-dc` / `codex-no-dc` for launching the host-installed CLIs directly:

```bash
# Add to your ~/.zshrc or ~/.bashrc
source /path/to/env.sh

# Run from any project directory
cd ~/my-project
claude # OR codex

# Pass additional Claude flags
claude --help

# Pass additional Codex flags
codex --help

# Bypass the devcontainer and run the host CLI directly
claude-no-dc --help
codex-no-dc --help
```

The workspace is automatically inferred from your current directory.

## Setup

Before starting the container for the first time, make sure `~/.claude/settings.json` and `~/.codex/config.toml` exist on your host. Docker requires bind-mounted files to be present before the container starts:

```bash
mkdir -p ~/.claude && touch ~/.claude/settings.json
mkdir -p ~/.codex && touch ~/.codex/config.toml
```

These files are mounted read-write, so settings changes made inside the container are reflected on your host and vice versa.

Codex stores its state under `~/.codex` inside the container. Claude stores its state under `~/.claude`. Both directories are also persisted with named Docker volumes, so authentication and the rest of each tool's local state survive container rebuilds.

## Applying changes to the container

After editing `Dockerfile` or `devcontainer.json`, rebuild and restart the container:

```bash
# Rebuild the image and recreate the container
devcontainer up --workspace-folder . --remove-existing-container --build-no-cache

# Or just recreate without a full rebuild (e.g. after devcontainer.json changes only)
devcontainer up --workspace-folder . --remove-existing-container
```

## What's inside

- **Node 20** base image with zsh, git, fzf, gh, and common dev tools
- **Claude** installed via the native installer (`curl -fsSL https://claude.ai/install.sh | bash`)
- **Codex** installed globally from npm (`npm install -g @openai/codex`)
- **Firewall** (`init-firewall.sh`) that restricts outbound traffic to an allowlist:
  - GitHub
  - npm registry
  - Anthropic API
  - OpenAI API and authentication/static endpoints needed by Codex
  - Sentry, Statsig, VS Code marketplace
