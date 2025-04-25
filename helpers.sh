#!/bin/bash

########################################################################
# 🛠️ helpers.sh: Shared utilities for dcup/dcrun workflows
# Contains argument parsing, shell validation, and container lookup
########################################################################

# 🔍 _find_latest_container: Return name of most recently started container for a given service
_find_latest_container() {
  local service="$1"  # Capture service name passed in as the first argument

  # Get latest container name that matches the service filter
  local name
  name=$(docker ps \
    --filter "name=${service}" \        # Filter containers by name matching service
    --format '{{.Names}}' | head -n 1)  # Get only container names, return the most recent

  # If no container was found, print error and return failure
  if [[ -z "$name" ]]; then
    echo "❌ No running container found for service '$service'" >&2
    return 1
  fi

  # Return the container name
  echo "$name"
}

# 🔍 _parse_args: Shared argument parser used by both dcup and dcrun
_parse_args() {
  USER_PORTS=()  # Global variable: holds port overrides passed via --port

  local POSITIONAL_ARGS=()  # Temporarily collect positional args here

  # 🔁 Loop over all input args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port)
        # If --port is given but no value follows, or next value is another option, show error
        if [[ -z "$2" || "$2" == --* ]]; then
          echo "❌ Missing value for --port"
          return 1
        fi

        # Store valid port mapping, like "3000:80"
        USER_PORTS+=("$2")
        shift 2
        ;;
      --help|-h)
        # 📜 Print help for dcrun and dcup argument formats
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
        # Store anything not matched above as a positional argument
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  # 🎯 Reset positional parameters ($1, $2, ...) to only the non-option arguments
  # This allows the rest of the script to use normal $1/$2 logic (e.g. service, tag, shell)
  # e.g. prev
  # - POSITIONAL_ARGS = ( "node:dev" "zsh" )
  # - USER_PORTS = ( "3000:80" )
  set -- "${POSITIONAL_ARGS[@]}"
  # e.g. post
  # - $1 = "node:dev"
  # - $2 = "zsh"
  local arg1="$1" arg2="$2" arg3="$3" arg4="$4"

  # 🧩 CASE A: Service + tag combined (e.g. node:v0.01)
  if [[ "$arg1" == *:* ]]; then
    SERVICE="${arg1%%:*}"            # Extract service name before :
    IMAGE_TAG="${arg1#*:}"           # Extract tag after :
    REQUESTED_SHELL="${arg2:-zsh}"   # Optional shell (default to zsh)
    PROJECT_NAME="$3"                # Optional project name
  else
    # 🧩 CASE B: Separated inputs (e.g. node v0.01 zsh)
    SERVICE="$arg1"
    case "$arg2" in
      sh|bash|zsh)
        IMAGE_TAG="latest"   # If arg2 is a shell, assume default image tag
        REQUESTED_SHELL="$arg2"
        PROJECT_NAME="$3"
        ;;
      *)
        IMAGE_TAG="${arg2:-latest}"    # Otherwise assume it's a tag
        REQUESTED_SHELL="${arg3:-zsh}" # Next is shell (default zsh)
        PROJECT_NAME="$4"
        ;;
    esac
  fi

  # 🔁 Final fallbacks to ensure safety
  IMAGE_TAG="${IMAGE_TAG:-latest}"
  REQUESTED_SHELL="${REQUESTED_SHELL:-zsh}"
}

# ❗ _validate_shell: Check if the shell exists in the image
_validate_shell() {
  local image="$1"  # Full image name (e.g. javierfraga/utilcntr-node:v0.01)
  local shell="$2"  # Shell to test (e.g. zsh, bash, sh)

  echo "🔎 Validating shell '$shell' in image: $image"

  # Create a temporary container with the shell as entrypoint
  # If it fails to create, the shell likely does not exist
  local container
  container=$(docker create --entrypoint "$shell" "$image" -c "exit 0" 2>/dev/null) || return 1

  # Clean up the container after test
  docker rm -f "$container" >/dev/null 2>&1

  # ✅ Success
  return 0
}

