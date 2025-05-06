# ===========
# BASE STAGE
# ===========
# Use official latest GCC image as base
FROM gcc:latest AS base

# Accept build-time variables for user and folder structure
ARG USERNAME=gccuser
ARG LABEL_KEEP=false
ARG UID=1000
ARG GID=1000

# These values are passed from `.env` → `dcbuild` → Dockerfile via `--build-arg`
ARG APP_DIR               # Default bind-mounted working directory (e.g., /mnt)
ARG FILES_DIR             # Location for copying files into image (e.g., /files)

# Define environment variables used in the container
# PATH="/home/${USERNAME}/.local/bin:$PATH" :  # Add local bin to PATH
# APP_DIR=${APP_DIR} :                         # Set app directory env var
# FILES_DIR=${FILES_DIR} :                     # Set files directory env var
# IMAGE_ENV=production :                        # Default to production environment
ENV PATH="/home/${USERNAME}/.local/bin:$PATH" \
  APP_DIR=${APP_DIR} \
  FILES_DIR=${FILES_DIR} \
  IMAGE_ENV=production

# 🧑💻 Optional non-root user — not needed in image, so skipped here

# Use /files to avoid conflicts with /mnt bind-mount in dev
WORKDIR ${FILES_DIR}

# Copy only the Docker-relevant files into image
COPY ./ ./

# ============
# DEV STAGE (Default for dcbuild)
# ============
FROM base AS dev

# ============
# 🌟🌟🌟LABEL
# ============
# Optional cleanup support: keep=true will preserve this image when pruning
LABEL keep=${LABEL_KEEP}

# Override IMAGE_ENV to development for this stage
ENV IMAGE_ENV=development

# 🧰 Install dev tools, plugins, dotfiles
# zsh :                     # Default shell
# git :                     # Git for dotfiles and source
# fd-find :                 # Fast find replacement
# lf :                      # Terminal file manager
# jq :                      # JSON processor
# iproute2 :                # Networking commands
# zsh-autosuggestions :     # Zsh plugin
# zsh-syntax-highlighting : # Another zsh plugin
# stow :                    # For managing dotfiles
# man-db :                  # Manual page support
# tree :                    # Directory visualization
# dumb-init && :            # PID 1 helper (used in ENTRYPOINT)
# ln -s $(which fdfind) /usr/local/bin/fd && :   # Rename `fdfine` to `fd`
# mv "$HOME"/.bashrc "$HOME"/.bashrc.bak && :    # Move .bashrc, prevents stow symlinks
# stow --target="$HOME" stow-target-files && :   # Apply dotfiles via stow
# rm -rf /var/lib/apt/lists/*                    # Reduce image size

RUN apt-get update && \
  apt-get install --no-install-recommends --yes \
  zsh \
  git \
  fd-find \
  lf \
  jq \
  iproute2 \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  stow \
  man-db \
  tree \
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
  "$HOME"/dotfiles/lvim/lua/run-me.sh && \
  rm -rf /var/lib/apt/lists/*

# ✅ Install Neovim manually by platform (useful if apt version is outdated)
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

# 🌙 Install LunarVim without optional language support for Python and Rust
# Prompts are answered via printf piping to install support for Node but forfeit Python and Rust
# RUN bash -c ' \
#   LV_BRANCH="release-1.4/neovim-0.9"; \
#   printf "yes\nno\nno\n" | bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh) '

# 🐳 Install Docker CLI for passthrough support
RUN apt-get update && \
  apt-get install --no-install-recommends --yes \
  ca-certificates \
  curl \
  gnupg \
  lsb-release && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
  apt-get update && \
  apt-get install --no-install-recommends --yes docker-ce-cli && \
  rm -rf /var/lib/apt/lists/*

# ✅ Stay as root for full access
# USER ${USERNAME} ← ❌ Skip non-root for dev container
USER root

# Set working directory to app mount point (bind-mounted at runtime)
WORKDIR ${APP_DIR}

# Expose port for local dev servers
EXPOSE 80

# 🧠 Use dumb-init to manage signal forwarding and zombie reaping
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

# Keep IMAGE_ENV=production for production
ENV IMAGE_ENV=production

# Use non-root user in production
USER ${USERNAME}
WORKDIR ${APP_DIR}

# Only install production deps
RUN npm install --omit=dev

# Copy app code into container with correct ownership
COPY --chown=${USERNAME}:${USERNAME} . .

# Listen on port 80
EXPOSE 80

# Start the app (can be changed)
CMD ["gcc", "--version"]

