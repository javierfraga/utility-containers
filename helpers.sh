#!/bin/bash

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

