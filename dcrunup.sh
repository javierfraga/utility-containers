#!/bin/bash

# 📍 Resolve absolute path to this script (even when sourced)
SOURCE="${BASH_SOURCE[0]:-$0}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
REPO_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# 🔍 Get most recently started container for a service
_find_latest_container() {
  local service="$1"
  local name
  name=$(docker ps \
    --filter "name=${service}" \
    --format '{{.Names}}' | head -n 1)

  if [[ -z "$name" ]]; then
    echo "❌ No running container found for service '$service'" >&2
    return 1
  fi

  echo "$name"
}

# 🔍 Parse arguments
_parse_args() {
  local arg1="$1"
  local arg2="$2"
  local arg3="$3"
  local arg4="$4"

  if [[ "$arg1" == "--help" || "$arg1" == "-h" ]]; then
    echo "Usage:"
    echo "  dcrun <service>:<tag> <shell>"
    echo "  dcrun <service> <tag> <shell>"
    echo "  dcrun <service> <shell>             # uses :latest"
    echo
    echo "  dcup <service>:<tag> <shell> [project]"
    echo "  dcup <service> <tag> <shell> [project]"
    echo "  dcup <service> <shell> [project]    # uses :latest"
    return 1
  fi

  if [[ "$arg1" == *:* ]]; then
    SERVICE="${arg1%%:*}"
    IMAGE_TAG="${arg1#*:}"
    REQUESTED_SHELL="$arg2"
    PROJECT_NAME="$3"
  else
    SERVICE="$arg1"
    if [[ "$arg2" =~ ^(sh|bash|zsh)$ ]]; then
      IMAGE_TAG="latest"
      REQUESTED_SHELL="$arg2"
      PROJECT_NAME="$3"
    else
      IMAGE_TAG="${arg2:-latest}"
      REQUESTED_SHELL="$arg3"
      PROJECT_NAME="$4"
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

# 🚀 Run an ephemeral container
dcrun() {
  _parse_args "$1" "$2" "$3" || return $?

  local image="javierfraga/utilcntr-${SERVICE}:${IMAGE_TAG}"

  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "❌ You must provide a shell to run (e.g. sh, bash, zsh)"
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

# 🔧 Run persistent container for a project
dcup() {
  _parse_args "$1" "$2" "$3" "$4" || return $?

  local image="javierfraga/utilcntr-${SERVICE}:${IMAGE_TAG}"
  local project="${PROJECT_NAME:-$(basename "$PWD")}"

  if [[ -z "$REQUESTED_SHELL" ]]; then
    echo "❌ You must provide a shell to run (e.g. sh, bash, zsh)"
    return 1
  fi

  _validate_shell "$image" "$REQUESTED_SHELL" || {
    echo "❌ Shell '$REQUESTED_SHELL' not found in image: $image"
    return 1
  }

  echo "🔧 Starting: $image (project: $project)"

  docker compose \
    --file "${REPO_DIR}/docker-compose.yaml" \
    --project-name "$project" \
    up \
    --detach \
    "${SERVICE}"

  local container
  container=$(_find_latest_container "$SERVICE") || return 1

  echo "🛠  Attaching to container: $container"
  docker exec \
    --interactive \
    --tty \
    "$container" "$REQUESTED_SHELL"
}

