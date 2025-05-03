# ===========
# BASE STAGE
# ===========

FROM node:23-alpine AS base

# Build args (passed via dcbuild)
ARG APP_DIR
ARG FILES_DIR
ARG LABEL_KEEP=false
ARG USERNAME=node
ARG UID=1000
ARG GID=1000

# Preserve “keep” label for prune filtering
LABEL keep=${LABEL_KEEP}

# Essential env
ENV PATH="/home/${USERNAME}/.local/bin:$PATH" \
  APP_DIR=${APP_DIR} \
  FILES_DIR=${FILES_DIR} \
  NODE_ENV=production

# Avoid conflicts with your dev-bind mount
WORKDIR ${FILES_DIR}

# Copy only what’s needed to build
COPY ./Dockerfile ./app.mjs ./readme.md ./package*.json ./

# ============
# DEV STAGE
# ============

FROM base AS dev

# Now in dev mode
ENV NODE_ENV=development \
  LV_BRANCH="release-1.4/neovim-0.9"

# Install Alpine packages, Neovim & dependencies for LV
RUN apk add --no-cache \
  yarn \
  cargo \
  alpine-sdk \
  bash \
  zsh \
  zsh-vcs \
  zsh-syntax-highlighting \
  git \
  curl \
  python3 \
  py3-pip \
  ripgrep \
  neovim \
  tree \
  man-db \
  dumb-init 

# Install LunarVim (no extra deps)
RUN curl -sL https://raw.githubusercontent.com/lunarvim/lunarvim/${LV_BRANCH}/utils/installer/install.sh \
  | bash -s -- --no-install-dependencies

# (Optional) If you still want your dotfiles & plugins from your repo,
# you could add lines here to clone/run them:
# RUN git clone https://github.com/javierfraga/nvim.git ~/.config/nvim \
#     && git clone https://github.com/javierfraga/lvim.git ~/.config/lvim \
#     && zsh ~/.config/nvim/pack/nvim-plugins/start/run-me.sh \
#     && zsh ~/.config/lvim/lua/run-me.sh

# Expose for your local dev server
EXPOSE 80

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# ===============
# PRODUCTION STAGE
# ===============

FROM base AS prod

ENV NODE_ENV=production

WORKDIR ${APP_DIR}

# Only production deps
RUN npm install --omit=dev

# Copy app in as non-root
COPY --chown=${USERNAME}:${USERNAME} . .

EXPOSE 80
CMD ["node", "index.js"]

