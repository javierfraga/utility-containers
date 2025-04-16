#!/bin/bash

# 📍 Resolve the absolute path to this script, even when sourced
SOURCE="${BASH_SOURCE[0]:-$0}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
REPO_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# 🧰 Source helper functions
source "${REPO_DIR}/helpers.sh"

# 🧠 Parse flexible CLI args
# Accepts formats:
#   dcrun node:v0.00 sh
#   dcrun node v0.00 sh
#   dcrun node sh           ← assumes latest tag
_parse_args() {
  local arg1="$1"
  local arg2="$2"
  local arg3="$3"

  if [[ "$arg1" == *:* ]]; then
    SERVICE="${arg1%%:*}"
    IMAGE_TAG="${arg1#*:}"
    REQUESTED_SHELL="$arg2"
  else
    SERVICE="$arg1"
    IMAGE_TAG="${arg2:-latest}"
    REQUESTED_SHELL="$3"
    if [[ -z "$REQUESTED_SHELL" && "$IMAGE_TAG" =~ ^(sh|bash|zsh)$ ]]; then
      REQUESTED_SHELL="$IMAGE_TAG"
      IMAGE_TAG="latest"
    fi
  fi

  IMAGE_TAG="${IMAGE_TAG:-latest}"
}

# ❗ Ensure the shell exists in the image
_validate_shell() {
  local image="$1"
  local shell="$2"

  echo "🔎 Validating shell '$shell' in image: $image"
  local container
  container=$(docker create --entrypoint "$shell" "$image" -c "exit 0" 2>/dev/null) || return 1
  docker rm -f "$container" >/dev/null 2>&1
  return 0
}

# 🚀 Run ephemeral container
dcrun() {
  _parse_args "$1" "$2" "$3"

  local image="javierfraga/utilcntr-${SERVICE}:${IMAGE_TAG}"

  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "❌ You must provide a shell to run (e.g. 'sh', 'bash', or 'zsh')"
    return 1
  fi

  _validate_shell "$image" "$REQUESTED_SHELL" || {
    echo "❌ Shell '$REQUESTED_SHELL' not found in image: $image"
    return 1
  }

  echo "🚀 Running: $image with shell: $REQUESTED_SHELL"

  docker compose \
    --file "${REPO_DIR}/docker-compose.yaml" \
    run \
    --rm \
    --interactive \
    --tty \
    "${SERVICE}" "$REQUESTED_SHELL"
}

# 🔧 Start persistent container and attach
dcup() {
  _parse_args "$1" "$2" "$3"

  local image="javierfraga/utilcntr-${SERVICE}:${IMAGE_TAG}"

  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "❌ You must provide a shell to run (e.g. 'sh', 'bash', or 'zsh')"
    return 1
  fi

  _validate_shell "$image" "$REQUESTED_SHELL" || {
    echo "❌ Shell '$REQUESTED_SHELL' not found in image: $image"
    return 1
  }

  echo "🔧 Starting: $image"
  docker compose \
    --file "${REPO_DIR}/docker-compose.yaml" \
    up \
    --detach \
    "${SERVICE}"

  local CONTAINER_NAME
  CONTAINER_NAME=$(_find_latest_container "$SERVICE") || return 1

  echo "🛠  Attaching to container: $CONTAINER_NAME"
  docker exec \
    --interactive \
    --tty \
    "$CONTAINER_NAME" "$REQUESTED_SHELL"
}

