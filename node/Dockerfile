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

