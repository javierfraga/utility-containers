#!/bin/bash

########################################################################
# 🛠️ helpers.sh: Shared utilities for dcup/dcrun workflows
########################################################################

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

# 🔍 Parse arguments (dcup / dcrun shared)
_parse_args() {
  USER_PORTS=()

  local POSITIONAL_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port)
        if [[ -z "$2" || "$2" == --* ]]; then
          echo "❌ Missing value for --port"
          return 1
        fi
        USER_PORTS+=("$2")
        shift 2
        ;;
      --help|-h)
        echo "DESCRIPTION:"
        echo "  🌀 dcrun  → Runs an ephemeral interactive container with a shell (default: zsh)"
        echo "  🔁 dcup   → Runs a persistent container (detached), then attaches with a shell (default: zsh)"
        echo
        echo "USAGE:"
        echo "  dcrun <service>:<tag> [shell] [--port HOST:CONTAINER ...]"
        echo "  dcrun <service> <tag> [shell] [--port ...]"
        echo "  dcrun <service> [shell]           # defaults to latest + zsh"
        echo
        echo "  dcup <service>:<tag> [shell] [project] [--port ...]"
        echo "  dcup <service> <tag> [shell] [project]"
        echo "  dcup <service> [shell] [project]  # defaults to latest + zsh"
        return 1
        ;;
      *)
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  # Restore positional args
  set -- "${POSITIONAL_ARGS[@]}"
  local arg1="$1" arg2="$2" arg3="$3" arg4="$4"

  if [[ "$arg1" == *:* ]]; then
    SERVICE="${arg1%%:*}"
    IMAGE_TAG="${arg1#*:}"
    REQUESTED_SHELL="${arg2:-zsh}"
    PROJECT_NAME="$3"
  else
    SERVICE="$arg1"
    case "$arg2" in
      sh|bash|zsh)
        IMAGE_TAG="latest"
        REQUESTED_SHELL="$arg2"
        PROJECT_NAME="$3"
        ;;
      *)
        IMAGE_TAG="${arg2:-latest}"
        REQUESTED_SHELL="${arg3:-zsh}"
        PROJECT_NAME="$4"
        ;;
    esac
  fi

  IMAGE_TAG="${IMAGE_TAG:-latest}"
  REQUESTED_SHELL="${REQUESTED_SHELL:-zsh}"  # Final fallback
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

