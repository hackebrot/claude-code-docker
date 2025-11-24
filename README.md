# claude-code-docker

Multi-stage Docker setup for running [Claude Code][claude-code] with optional Go and Python environments.

[claude-code]: https://github.com/anthropics/claude-code

## Prerequisites

Set an environment variable pointing to this repo (add to `~/.zshrc`):

```zsh
export CLAUDE_CODE_DOCKER=~/Code/claude-code-docker
```

Copy the example files into your project and customize them:

```zsh
cp $CLAUDE_CODE_DOCKER/.env.example ./.env
cp $CLAUDE_CODE_DOCKER/compose.go.yml ./compose.yml
```

Create the shared settings volume (used to persist claude settings):

```zsh
docker volume create claude-settings
```

## Available Variants

- `claude-base` - Claude Code only
- `claude-go` - Claude Code + Go
- `claude-py` - Claude Code + Python (via uv)
- `claude-all` - Claude Code + Go + Python

## Usage

### Build and Run

Use compose file overrides to select your variant:

```bash
# Base variant (Claude only)
docker compose -p myproject --env-file .env -f $CLAUDE_CODE_DOCKER/compose.base.yml up -d --build

# Python variant
docker compose -p myproject --env-file .env -f $CLAUDE_CODE_DOCKER/compose.base.yml -f $CLAUDE_CODE_DOCKER/compose.py.yml up -d --build

# Go variant
docker compose -p myproject --env-file .env -f $CLAUDE_CODE_DOCKER/compose.base.yml -f $CLAUDE_CODE_DOCKER/compose.go.yml up -d --build

# All (Go + Python)
docker compose -p myproject --env-file .env -f $CLAUDE_CODE_DOCKER/compose.base.yml -f $CLAUDE_CODE_DOCKER/compose.all.yml up -d --build
```

### Attach to Container

```bash
docker compose -p myproject attach claude-code
```

### Stop Container

```bash
docker compose -p myproject down
```

## Configuration

Set versions in `.env` file or environment variables:
```bash
CLAUDE_CODE_VERSION=latest
GO_VERSION=1.25.4
PYTHON_VERSION=3.14
WORKSPACE_DIR=/path/to/workspace
```
