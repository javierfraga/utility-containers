# ===========
# BASE STAGE
# ===========
# Use official latest bash image as base
FROM bash:latest AS base

# Accept build-time variables for user and folder structure
ARG USERNAME=pyuser
ARG LABEL_KEEP=false
ARG UID=1000
ARG GID=1000

# These values are passed from `.env` → `dcbuild` → Dockerfile via `--build-arg`
ARG APP_DIR               # Default bind-mounted working directory (e.g., /mnt)
ARG FILES_DIR             # Location for copying files into image (e.g., /files)

# Define environment variables used in the container
# APP_DIR=${APP_DIR} :                         # Set app directory env var
# FILES_DIR=${FILES_DIR} :                     # Set files directory env var
# IMAGE_ENV=production :                        # Default to production environment
ENV APP_DIR=${APP_DIR}
ENV FILES_DIR=${FILES_DIR}
ENV IMAGE_ENV=production

# 🧑💻 Optional non-root user — not needed in dev image, so skipped here

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
ENV LV_BRANCH="release-1.4/neovim-0.9"

# 🧰 Install dev tools, plugins, dotfiles
# Install development tools, common utilities, Zsh, Git, Neovim, Python, Rust tooling, and other essentials.
# Also clone Zsh plugins, personal dotfiles, set up dotfiles using stow, and run custom setup scripts.
# RUN \
#   apk add --no-cache --update \
#   # Update package list and install packages without caching indices afterward.
#   # Note: `--update` is not a standard flag for `apk add`; `apk update` should typically be run *before* `apk add`.
#   # However, `--no-cache` implicitly handles fetching the index. This line is kept as provided in the request.
#   \
#   alpine-sdk \ # Provides essential build tools like make, gcc, g++, etc., often needed for compiling native dependencies.
#   bash \ # Installs the Bash shell.
#   zsh \ # Installs the Z shell, a popular alternative shell.
#   zsh-vcs \ # Installs Zsh Version Control System plugin (shows repo status in prompt).
#   zsh-autosuggestions \ # Installs Zsh Autosuggestions plugin (suggests commands based on history).
#   zsh-completions \ # Installs Zsh Completions plugin (provides enhanced tab-completion).
#   zsh-syntax-highlighting \ # Installs Zsh Syntax Highlighting plugin (highlights commands in the prompt).
#   git \ # Installs Git for version control.
#   fd \ # Installs fd, a fast alternative to the 'find' command.
#   lf \ # Installs lf (List Files), a terminal file manager.
#   jq \ # Installs jq, a command-line JSON processor.
#   iproute2 \ # Installs iproute2, providing networking utilities like 'ip'.
#   stow \ # Installs GNU Stow, used for managing dotfiles via symlinks.
#   man-db \ # Installs the man pages database and reader. TODO: e.g. `apk update grep-doc`
#   tree \ # Installs tree, a utility to display directory structures.
#   yarn \ # Installs Yarn, a JavaScript package manager.
#   cargo \ # Installs Cargo, Rust's package manager and build tool.
#   curl \ # Installs curl, a tool for transferring data using various protocols (e.g., HTTP).
#   python3 \ # Installs the Python 3 interpreter.
#   py3-pip \ # Installs pip, the package installer for Python 3.
#   ripgrep \ # Installs ripgrep (rg), a fast code-searching tool.
#   neovim \ # Installs Neovim, a modern Vim-based text editor.
#   unzip \ # Installs unzip, a utility for extracting zip archives.
#   wget \ # Installs wget, a non-interactive network downloader.
#   dumb-init && \ # Installs dumb-init, a lightweight init system for containers to handle signals and zombie processes.
#   \
#   git clone https://github.com/MenkeTechnologies/zsh-expand "$HOME"/.zsh/zsh-expand && \
#   git clone --recurse-submodules https://gitlab.com/javierfraga/dotfiles.git "$HOME"/dotfiles && \
#   cd "$HOME"/dotfiles && \
#   git submodule update --remote --merge && \ # Update all Git submodules to their latest versions from the remote, merging changes.
#   if [ -f "$HOME/.bashrc" ]; then \ # Check if a .bashrc file already exists in the home directory.
#   echo "Backing up existing $HOME/.bashrc to $HOME/.bashrc.bak" && \
#   mv "$HOME/.bashrc" "$HOME/.bashrc.bak"; \
#   fi && \ # End the conditional check for .bashrc.
#   stow --target="$HOME" stow-target-files && \
#   git config --global commit.template "$HOME/.config/git/commit-template.txt" && \
#   "$HOME"/dotfiles/nvim/pack/nvim-plugins/start/run-me.sh && \
#   "$HOME"/dotfiles/lvim/lua/run-me.sh

RUN apk add --no-cache --update \
  alpine-sdk \
  bash \
  zsh \
  zsh-vcs \
  zsh-autosuggestions \
  zsh-completions \
  zsh-syntax-highlighting \
  git \
  fd \
  lf \
  jq \
  iproute2 \
  stow \
  man-db \
  tree \
  yarn \
  cargo \
  curl \
  python3 \
  py3-pip \
  ipython \
  ripgrep \
  neovim \
  gzip \
  unzip \
  wget \
  dumb-init && \
  git clone https://github.com/MenkeTechnologies/zsh-expand "$HOME"/.zsh/zsh-expand && \
  git clone --recurse-submodules https://gitlab.com/javierfraga/dotfiles.git "$HOME"/dotfiles && \
  cd "$HOME"/dotfiles && \
  git submodule update --remote --merge && \
  if [ -f "$HOME/.bashrc" ]; then \
  echo "Backing up existing $HOME/.bashrc to $HOME/.bashrc.bak" && \
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"; \
  fi && \
  stow --target="$HOME" stow-target-files && \
  git config --global commit.template "$HOME/.config/git/commit-template.txt" && \
  "$HOME"/dotfiles/nvim/pack/nvim-plugins/start/run-me.sh && \
  "$HOME"/dotfiles/lvim/lua/run-me.sh

# # ✅ Install Neovim manually by platform (useful if apt version is outdated)
# ARG TARGETPLATFORM

# RUN set -e && \
#     mkdir -p /opt/build && \
#     cd /opt/build && \
#     case "${TARGETPLATFORM}" in \
#       "linux/amd64")  NEOVIM_PKG="nvim-linux-x86_64.tar.gz" ;; \
#       "linux/arm64")  NEOVIM_PKG="nvim-linux-arm64.tar.gz" ;; \
#       *) echo "❌ Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
#     esac && \
#     echo "📦 Downloading Neovim package: ${NEOVIM_PKG} for ${TARGETPLATFORM}" && \
#     wget --tries=3 --timeout=30 "https://github.com/neovim/neovim/releases/download/v0.11.0/${NEOVIM_PKG}" && \
#     tar -xzf "${NEOVIM_PKG}" && \
#     mkdir -p /opt/nvim && mv nvim-* /opt/nvim && \
#     ln -sf /opt/nvim/nvim-*/bin/nvim /usr/local/bin/nvim && \
#     cd / && rm -rf /opt/build

# # 🌙 Install LunarVim without optional language support for Python and Rust
# # Prompts are answered via printf piping to install support for Node but forfeit Python and Rust
# RUN bash -c ' \
#   LV_BRANCH="release-1.4/neovim-0.9"; \
#   printf "yes\nno\nno\n" | bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh) '

# Install LunarVim (no extra deps)
RUN curl -sL https://raw.githubusercontent.com/lunarvim/lunarvim/${LV_BRANCH}/utils/installer/install.sh \
  | bash -s -- --no-install-dependencies

# 🐳 Install Docker CLI for passthrough support
# 🐳 Install Docker CLI for passthrough support (Alpine version)
RUN  apk add --no-cache \
  ca-certificates \
  docker-cli
# ca-certificates \ # Often needed for secure downloads, good practice to include
# curl \            # Included for parity with the original command, in case it's needed later
# docker-cli        # Docker CLI package in Alpine repositories (usually 'community')
# No manual GPG key import or repository list modification is typically needed
# as docker-cli is available in the standard Alpine repositories.
# The --no-cache flag updates indexes, installs packages, and removes the cache in one step,
# eliminating the need for a separate cleanup like 'rm -rf /var/lib/apt/lists/*'.

# ✅ Stay as root for full access
# USER ${USERNAME} ← ❌ Skip non-root for dev container
USER root

# Set working directory to app mount point (bind-mounted at runtime)
WORKDIR ${APP_DIR}

# Expose for your local dev server
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
CMD ["bash"]
