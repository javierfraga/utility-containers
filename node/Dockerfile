# ===========
# BASE STAGE
# ===========
FROM node:latest AS base

ARG USERNAME=node
ARG UID=1000
ARG GID=1000

ENV PATH="/home/${USERNAME}/.local/bin:$PATH" \
    APP_DIR="/app" \
    MNT_DIR="/mnt" \
    NODE_ENV=production

# Don't need this node image already has user I can use
# Create non-root user
# RUN groupadd --gid "${GID}" "${USERNAME}" \
#  && useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}"

# Mount here so can copy and Bind Mount (in dev) will not overwrite these files
WORKDIR ${MNT_DIR}
COPY ./Dockerfile ./app.mjs ./readme.md ./package*.json ./

# ============
# DEV STAGE (Default for dcbuild)
# ============
FROM base AS dev

# Special filter: docker image prune --all --filter "label=keep=true"
# LABEL keep=true

# Override to dev mode
ENV NODE_ENV=development

# Install dev tools and shell
RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
      zsh \
      git \
      fd-find \
      lf \
      zsh-autosuggestions \
      zsh-syntax-highlighting \
      stow \
      man-db \
      tree \
      # neovim \ # this fails the build, install below, see below
      dumb-init && \
    git clone https://github.com/MenkeTechnologies/zsh-expand "$HOME"/.zsh/zsh-expand && \
    git clone https://github.com/zsh-users/zsh-completions.git /usr/local/share/zsh-completions && \
    chmod -R 755 /usr/local/share/zsh-completions && \
    ln -s $(which fdfind) /usr/local/bin/fd && \
    git clone --recurse-submodules https://gitlab.com/javierfraga/dotfiles.git "$HOME"/dotfiles && \
    cd "$HOME"/dotfiles && \
    git submodule update --remote --merge && \
    mv "$HOME"/.bashrc "$HOME"/.bashrc.bak && \
    stow --target="$HOME" stow-target-files && \
    git config --global commit.template "$HOME/.config/git/commit-template.txt" && \
    "$HOME"/dotfiles/nvim/pack/nvim-plugins/start/run-me.sh && \
    rm -rf /var/lib/apt/lists/*


# ✅ Install latest version of neovim
ARG TARGETPLATFORM

RUN set -e && \
    mkdir -p /opt/build && \
    cd /opt/build && \
    case "${TARGETPLATFORM}" in \
      "linux/amd64")  NEOVIM_PKG="nvim-linux-x86_64.tar.gz" ;; \
      "linux/arm64")  NEOVIM_PKG="nvim-linux-arm64.tar.gz" ;; \
      *) echo "❌ Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac && \
    echo "📦 Downloading Neovim package: ${NEOVIM_PKG} for ${TARGETPLATFORM}" && \
    wget --tries=3 --timeout=30 "https://github.com/neovim/neovim/releases/download/v0.11.0/${NEOVIM_PKG}" && \
    tar -xzf "${NEOVIM_PKG}" && \
    mkdir -p /opt/nvim && mv nvim-* /opt/nvim && \
    ln -sf /opt/nvim/nvim-*/bin/nvim /usr/local/bin/nvim && \
    cd / && rm -rf /opt/build

# Install LunarVim without Python or Rust support
# printf are prompt answers
RUN bash -c ' \
  LV_BRANCH="release-1.4/neovim-0.9"; \
  printf "yes\nno\nno\n" | bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh) '

# ✅ Stay as root
# USER ${USERNAME} ← ❌ Remove this
USER root

# Set working directory to /app (which will be bind-mounted)
WORKDIR ${APP_DIR}

# Anonymous volume for node_modules to isolate from host
VOLUME ["/app/node_modules"]

# For dev servers listening on port 80
EXPOSE 80

# Use dumb-init to:
# - Act as PID 1 inside the container
# - Properly forward signals (e.g., SIGINT, SIGTERM)
# - Reap zombie child processes (e.g., editors, background tasks)
# Especially useful in long-lived, interactive dev sessions
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# ===============
# PRODUCTION STAGE
# ===============
FROM base AS prod

# Keep NODE_ENV=production
ENV NODE_ENV=production

USER ${USERNAME}
WORKDIR ${APP_DIR}

# Only install production dependencies
RUN npm install --omit=dev

# Copy source code
COPY --chown=${USERNAME}:${USERNAME} . .

# Inform Docker this container listens on port 80
EXPOSE 80

# Start the app (adjust entrypoint as needed)
CMD ["node", "index.js"]

