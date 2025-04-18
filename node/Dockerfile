# ===========
# BASE STAGE
# ===========
FROM node:latest AS base

ARG USERNAME=nodeuser
ARG UID=1000
ARG GID=1000

ENV PATH="/home/${USERNAME}/.local/bin:$PATH" \
    APP_DIR="/app" \
    NODE_ENV=production

# Create non-root user
RUN groupadd --gid "${GID}" "${USERNAME}" \
 && useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}"

WORKDIR ${APP_DIR}
COPY --chown=${USERNAME}:${USERNAME} package*.json ./

# ============
# DEV STAGE (Default for dcbuild)
# ============
FROM base AS dev

# Override to dev mode
ENV NODE_ENV=development

# Install dev tools and shell
RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
      zsh \
      git \
      zsh-autosuggestions \
      dumb-init && \
    rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
WORKDIR ${APP_DIR}

# Install dev dependencies
RUN npm install

# Copy full source code after install (caches better)
COPY --chown=${USERNAME}:${USERNAME} . .


# For dev servers listening on port 80
EXPOSE 80

# Default command in dev: shell
CMD ["zsh"]

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

