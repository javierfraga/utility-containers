#!/bin/bash

# 📍 Resolve the absolute path to this script, even when sourced
SOURCE="${BASH_SOURCE[0]:-$0}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
REPO_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# Source helper function
source "${REPO_DIR}/helpers.sh"

# 🧠 Parse service name and optional tag (format: service[:tag])
_parse_service_tag() {
  local raw="$1"
  SERVICE="${raw%%:*}"                     # everything before colon
  IMAGE_TAG="${raw#*:}"
  [[ "$SERVICE" == "$IMAGE_TAG" ]] && IMAGE_TAG="latest"  # No colon? Default to latest
}

_detect_shell_in_container() {
  local container="$1"
  for SHELL_CANDIDATE in zsh bash sh; do
    if docker exec "$container" which "$SHELL_CANDIDATE" >/dev/null 2>&1; then
      echo "$SHELL_CANDIDATE"
      return
    fi
  done
  echo ""  # fallback if none found
}

dcrun() {
  _parse_service_tag "$1"
  shift
  local REQUESTED_SHELL="$1"
  shift

  echo "🚀 Running ephemeral container: ${SERVICE}:${IMAGE_TAG}"

  # Start a temp container to detect shell if not specified
  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "🔍 Detecting shell for image: ${SERVICE}:${IMAGE_TAG}"
    CONTAINER_ID=$(docker create --rm javiersfraga/utilcntr-${SERVICE}:${IMAGE_TAG})
    REQUESTED_SHELL=$(_detect_shell_in_container "$CONTAINER_ID")
    docker rm "$CONTAINER_ID" >/dev/null
    [[ -z "$REQUESTED_SHELL" ]] && {
      echo "❌ No shell found in image."
      return 1
    }
    echo "✅ Using shell: $REQUESTED_SHELL"
  else
    echo "✅ Using user-requested shell: $REQUESTED_SHELL"
  fi

  docker compose \
    --file "${REPO_DIR}/docker-compose.yaml" \
    run \
    --rm \
    --interactive \
    --tty \
    "${SERVICE}" "$REQUESTED_SHELL"
}

dcup() {
  _parse_service_tag "$1"
  shift
  local REQUESTED_SHELL="$1"
  shift

  echo "🔧 Starting persistent container: ${SERVICE}:${IMAGE_TAG}"
  docker compose \
    --file "${REPO_DIR}/docker-compose.yaml" \
    up \
    --detach \
    "${SERVICE}"

  # 🔍 Find most recently created/started container for the service
  local CONTAINER_NAME
  CONTAINER_NAME=$(_find_latest_container "$SERVICE") || return 1

  # 🧠 Auto-detect best shell if none was explicitly requested
  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "🔍 Detecting shell in container: $CONTAINER_NAME"
    REQUESTED_SHELL=$(_detect_shell_in_container "$CONTAINER_NAME")
    if [[ -z "$REQUESTED_SHELL" ]]; then
      echo "❌ No shell found in container '$CONTAINER_NAME'" >&2
      return 1
    fi
    echo "✅ Using shell: $REQUESTED_SHELL"
  else
    echo "✅ Using user-requested shell: $REQUESTED_SHELL"
  fi

  echo "🛠  Attaching to container: $CONTAINER_NAME"
  docker exec \
    --interactive \
    --tty \
    "$CONTAINER_NAME" "$REQUESTED_SHELL"
}

