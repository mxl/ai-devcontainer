# AI Agents Devcontainer

A sandboxed development container for running [Claude Code](https://code.claude.com), [OpenAI Codex](https://github.com/openai/codex), and [OpenCode](https://opencode.ai) with network isolation via firewall rules.

## Requirements

- [Docker](https://www.docker.com/)
- [Dev Container CLI](https://github.com/devcontainers/cli): `npm install -g @devcontainers/cli`

## Setup

To use this setup in another repository:

1. Copy the `.devcontainer/` directory into the root of your project.
2. To use the host helper commands, either add `source /path/to/ai-devcontainer/env.sh` to your `~/.zshrc` or `~/.bashrc`, or run that `source` command manually in the current shell.
3. Before starting the container for the first time, make sure `~/.claude/settings.json` and `~/.codex/config.toml` exist on your host. Docker requires bind-mounted files to be present before the container starts:

```bash
mkdir -p ~/.claude && touch ~/.claude/settings.json
mkdir -p ~/.codex && touch ~/.codex/config.toml
```

These files are mounted read-write, so settings changes made inside the container are reflected on your host and vice versa.

4. From the target project's root, start the container:

```bash
devcontainer up --workspace-folder .
```

Codex stores its state under `~/.codex` inside the container. Claude stores its state under `~/.claude`. OpenCode stores config under `~/.config/opencode` and data under `~/.local/share/opencode`. GitHub CLI uses `~/.config/gh`. All of them are persisted with bind mounts and/or named Docker volumes, so authentication and local state survive container rebuilds.

## Usage

Source the included shell script to get `claude`, `codex`, and `opencode` commands that start the devcontainer and launch the selected CLI in one step, plus `claude-no-dc`, `codex-no-dc`, and `opencode-no-dc` for launching the host-installed CLIs directly:

```bash
# Add to your ~/.zshrc or ~/.bashrc
source /path/to/env.sh

# Run from any project directory
cd ~/my-project
claude # OR codex OR opencode

# Pass additional Claude flags
claude --help

# Pass additional Codex flags
codex --help

# Pass additional OpenCode flags
opencode --help

# Bypass the devcontainer and run the host CLI directly
claude-no-dc --help
codex-no-dc --help
opencode-no-dc --help

# Run an arbitrary command inside the devcontainer from the project root
devcontainer exec /bin/zsh
```

The workspace is automatically inferred from your current directory.

## OpenCode CLIProxy Setup

The repository includes a default OpenCode config in `.devcontainer/opencode.json` that points OpenCode at CLIProxy through `http://host.docker.internal:8317/v1` from inside the devcontainer.

Create a local API key file before using the proxy-backed OpenCode config:

```bash
cp .devcontainer/.cliproxyapi-key.example .devcontainer/.cliproxyapi-key
$EDITOR .devcontainer/.cliproxyapi-key
```

Add only the real API key to `.devcontainer/.cliproxyapi-key`. That file is ignored by git and is loaded by OpenCode from `.devcontainer/opencode.json` using a file substitution.

If your current devcontainer was created before the proxy config was added, recreate it once so `OPENCODE_CONFIG` and the host alias are available:

```bash
devcontainer up --workspace-folder . --remove-existing-container
```

If the container is already using the current `.devcontainer/devcontainer.json`, editing `.devcontainer/.cliproxyapi-key` does not require a rebuild.

You can verify the proxy wiring from inside the container with:

```bash
devcontainer exec --workspace-folder . printenv OPENCODE_CONFIG
devcontainer exec --workspace-folder . curl http://host.docker.internal:8317/v1/models
```

When those checks succeed, running `opencode` from the project root will use the proxy-backed provider defined in `.devcontainer/opencode.json`.

## Git identity inside the container

This devcontainer does not mount your host `~/.gitconfig`, so you should configure `git user.name` and `git user.email` inside the container before creating commits.

Set them manually inside the container:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Or copy the values from your host into the container from the project root:

```bash
devcontainer exec git config --global user.name "$(git config --global --get user.name)"
devcontainer exec git config --global user.email "$(git config --global --get user.email)"
```

## Safe `gh` setup for YOLO mode

If you plan to run Claude or Codex with broad local execution permissions, keep the container's GitHub access scoped to a single repository:

1. Open GitHub: `Settings` -> `Developer settings` -> `Personal access tokens` -> `Fine-grained tokens` -> `Generate new token`
2. Give the token a descriptive name such as `ai-devcontainer-my-project`.
3. Set a short expiration, for example 30 or 90 days.
4. Choose the correct `Resource owner` (your user or the target organization).
5. Under `Repository access`, choose `Only select repositories`.
6. Select only the repository you want the container to access.
7. Grant only the minimum permissions you need:
   - `Contents: Read and write` for clone, fetch, pull, and push
   - `Pull requests: Read and write` only if you want `gh pr create`, `gh pr edit`, or similar commands
   - Leave everything else disabled unless you have a specific need
8. Generate the token and copy it somewhere temporary so you can paste it into `gh auth login` inside the container.
9. Recreate the devcontainer if needed, then run `gh auth login` inside the container and use that token.

PAT authentication requires the repository remote to use an `https://` URL, not an SSH URL such as `git@github.com:owner/repo.git`.

Example:

```bash
git remote set-url origin https://github.com/owner/repo.git
```

Example inside the container:

```bash
gh auth login --hostname github.com --git-protocol https
```

When prompted:

1. Choose `Paste an authentication token`.
2. Paste the fine-grained PAT.
3. Verify access:

```bash
gh auth status
gh repo view
```
4. Configure git to use GitHub CLI as a credential helper:
```bash
gh auth setup-git
```

For branch safety, also enable branch protection or a ruleset on GitHub for `main`/`master` and any other protected branches:

1. Open the repository on GitHub.
2. Go to `Settings` -> `Rules` -> `Rulesets`.
3. Create or edit a ruleset that applies to your protected branches.
4. Keep force pushes blocked.
5. Optionally also require pull requests or linear history.

The token limits which repositories the container can access. The ruleset prevents accidental history rewrites in the allowed repository.

## Applying changes to the container

After editing `Dockerfile` or `devcontainer.json`, rebuild and restart the container:

```bash
# Rebuild the image and recreate the container
devcontainer up --workspace-folder . --remove-existing-container --build-no-cache

# Or just recreate without a full rebuild (e.g. after devcontainer.json changes only)
devcontainer up --workspace-folder . --remove-existing-container
```

## Why Codex `config.toml` is not bind-mounted

This devcontainer does not mount `${HOME}/.codex/config.toml` into `/home/node/.codex/config.toml`.

Codex persists configuration with an atomic write pattern: it writes a temporary file and then replaces `config.toml`. A single-file bind mount makes `/home/node/.codex/config.toml` its own mount target inside the container, which can cause the final replace step to fail with a cross-device rename error such as `EXDEV` or `Invalid cross-device link`.

That failure shows up in Codex as errors like `failed to persist config.toml` when changing the default model, trust settings, or other saved preferences.

To avoid that, the devcontainer mounts the whole `/home/node/.codex` directory as a writable volume instead of bind-mounting the config file itself. This lets Codex manage `config.toml` normally and keeps atomic saves working.

If host-side persistence is needed, mount the entire `${HOME}/.codex` directory to `/home/node/.codex`. Do not mount only `config.toml`.

## What's inside

- **Node 20** base image with zsh, git, fzf, gh, and common dev tools
- **Claude** installed via the native installer (`curl -fsSL https://claude.ai/install.sh | bash`)
- **Codex** installed globally from npm (`npm install -g @openai/codex`)
- **OpenCode** installed via the native installer (`curl -fsSL https://opencode.ai/install | bash`)
- **Firewall** (`init-firewall.sh`) that restricts outbound traffic to an allowlist:
  - GitHub
  - npm registry
  - Anthropic API
  - OpenAI API and authentication/static endpoints needed by Codex
  - Sentry, Statsig, VS Code marketplace

The devcontainer firewall is disabled by default. To enable it, set `DEVCONTAINER_FIREWALL_ENABLED=true` in `.devcontainer/devcontainer.json` before starting the container.
