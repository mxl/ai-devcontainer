# Claude Devcontainer

A sandboxed development container for running [Claude Code](https://code.claude.com) with network isolation via firewall rules.

## Requirements

- [Docker](https://www.docker.com/)
- [Dev Container CLI](https://github.com/devcontainers/cli): `npm install -g @devcontainers/cli`

## Usage

Source the included shell script to get a `claude` command that starts the devcontainer and launches Claude in one step:

```bash
# Add to your ~/.zshrc or ~/.bashrc
source /path/to/claude.sh

# Run from any project directory
cd ~/my-project
claude

# Pass additional Claude flags
claude --dangerously-skip-permissions
```

The workspace is automatically inferred from your current directory.

## Setup

Before starting the container for the first time, make sure `~/.claude/settings.json` exists on your host — Docker requires the file to be present before it can bind-mount it:

```bash
mkdir -p ~/.claude && touch ~/.claude/settings.json
```

The file is mounted read-write, so any settings changes made inside the container are reflected on your host and vice versa.

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
- **Firewall** (`init-firewall.sh`) that restricts outbound traffic to an allowlist:
  - GitHub
  - npm registry
  - Anthropic API
  - Sentry, Statsig, VS Code marketplace
