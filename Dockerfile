# =============================================================================
# Stage 1: Base system setup (common to all variants)
# =============================================================================
FROM debian:bookworm-slim AS base-system

LABEL org.opencontainers.image.authors="hello@raphael.codes" \
      org.opencontainers.image.description="Docker image for running Claude Code" \
      org.opencontainers.image.version="1.0.0"

ARG CLAUDE_CODE_VERSION=latest

ENV TZ=Europe/Berlin

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    jq \
    neovim \
    zsh \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 claude \
    && useradd --uid 1001 --gid claude --shell /bin/zsh --create-home claude

# Create workspace and config directories with proper permissions
RUN mkdir -p /workspace /home/claude/.claude \
    && chown -R claude:claude /workspace /home/claude/.claude

ENV PATH=/home/claude/.local/bin:${PATH} \
    SHELL=/bin/zsh \
    EDITOR=nvim \
    VISUAL=nvim

USER claude
WORKDIR /home/claude

COPY --chown=claude:claude zshrc /home/claude/.zshrc
RUN touch /home/claude/.zsh_history && chmod 600 /home/claude/.zsh_history

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_CODE_VERSION}

# =============================================================================
# Stage 2: Add Go
# =============================================================================
FROM base-system AS with-go

ARG GO_VERSION

USER root

# Install Go with checksum verification using JSON API
RUN set -e; \
    ARCH=$(dpkg --print-architecture); \
    GO_TAR="go${GO_VERSION}.linux-${ARCH}.tar.gz"; \
    echo "Downloading Go $GO_VERSION for $ARCH..."; \
    curl -fsSL -o /tmp/$GO_TAR "https://go.dev/dl/$GO_TAR"; \
    EXPECTED_CHECKSUM=$(curl -fsSL "https://go.dev/dl/?mode=json" | \
        jq -r --arg filename "$GO_TAR" \
        '.[] | select(.version=="go'"$GO_VERSION"'") | .files[] | select(.filename==$filename) | .sha256'); \
    if [ -z "$EXPECTED_CHECKSUM" ]; then \
        echo "Error: Could not fetch checksum for $GO_TAR"; exit 1; \
    fi; \
    echo "$EXPECTED_CHECKSUM  /tmp/$GO_TAR" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/$GO_TAR; \
    rm /tmp/$GO_TAR

USER claude

# Add Go to PATH
ENV PATH=/usr/local/go/bin:/home/claude/go/bin:${PATH}

# =============================================================================
# Stage 3: Add Python/uv
# =============================================================================
FROM base-system AS with-python

ARG PYTHON_VERSION

USER root

# Install uv to /usr/local/bin (system-wide, installed as root)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

USER claude

# Install Python as claude user (goes to ~/.local/share/uv/python/)
RUN uv python install ${PYTHON_VERSION}

# =============================================================================
# Stage 4: All (Go + Python)
# =============================================================================
FROM base-system AS with-all

ARG GO_VERSION
ARG PYTHON_VERSION

USER root

# Install Go with checksum verification using JSON API
RUN set -e; \
    ARCH=$(dpkg --print-architecture); \
    GO_TAR="go${GO_VERSION}.linux-${ARCH}.tar.gz"; \
    echo "Downloading Go $GO_VERSION for $ARCH..."; \
    curl -fsSL -o /tmp/$GO_TAR "https://go.dev/dl/$GO_TAR"; \
    EXPECTED_CHECKSUM=$(curl -fsSL "https://go.dev/dl/?mode=json" | \
        jq -r --arg filename "$GO_TAR" \
        '.[] | select(.version=="go'"$GO_VERSION"'") | .files[] | select(.filename==$filename) | .sha256'); \
    if [ -z "$EXPECTED_CHECKSUM" ]; then \
        echo "Error: Could not fetch checksum for $GO_TAR"; exit 1; \
    fi; \
    echo "$EXPECTED_CHECKSUM  /tmp/$GO_TAR" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/$GO_TAR; \
    rm /tmp/$GO_TAR

# Install uv to /usr/local/bin (system-wide, installed as root)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

USER claude

# Install Python as claude user (goes to ~/.local/share/uv/python/)
RUN uv python install ${PYTHON_VERSION}

# Add Go to PATH
ENV PATH=/usr/local/go/bin:/home/claude/go/bin:${PATH}

# =============================================================================
# Final targets
# =============================================================================

# Target: base (Claude only)
FROM base-system AS claude-base
WORKDIR /workspace
CMD ["claude"]

# Target: go (Claude + Go)
FROM with-go AS claude-go
WORKDIR /workspace
CMD ["claude"]

# Target: py (Claude + Python)
FROM with-python AS claude-py
WORKDIR /workspace
CMD ["claude"]

# Target: all (Claude + Go + Python)
FROM with-all AS claude-all
WORKDIR /workspace
CMD ["claude"]
