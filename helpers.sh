#!/bin/bash

########################################################################
# 🛠️ helpers.sh: Shared utilities for dcup/dcrun workflows
# Contains argument parsing, shell validation, and container lookup
########################################################################

# 🔍 _find_latest_container: Return name of most recently started container for a given service
_find_latest_container() {
  local service="$1"  # Capture service name passed in as the first argument

  # Get latest container name that matches the service filter
  #   --filter "name=${service}" \        # Filter containers by name matching service
  #   --format '{{.Names}}' | head -n 1)  # Get only container names, return the most recent
  local name
  name=$(docker ps \
    --filter "name=${service}" \
    --format '{{.Names}}' | head -n 1)

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
        echo "  🌀 dcrun  → Runs an ephemeral interactive container with a shell (default fallback: auto-detect zsh/bash/sh)"
        echo "  🔁 dcup   → Runs a persistent container (detached), then attaches with a shell (default fallback: auto-detect zsh/bash/sh)"
        echo
        echo "USAGE:"
        echo "  dcrun <service>:<tag> [shell] [--port HOST:CONTAINER ...]"
        echo "  dcrun <service> <tag> [shell] [--port ...]"
        echo "  dcrun <service> [shell]           # defaults to latest + auto-detected shell"
        echo
        echo "  dcup <service>:<tag> [shell] [project] [--port ...]"
        echo "  dcup <service> <tag> [shell] [project]"
        echo "  dcup <service> [shell] [project]  # defaults to latest + auto-detected shell"
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
  set -- "${POSITIONAL_ARGS[@]}"
  # Post-reset:
  # - $1 = first non-option argument
  # - $2 = second non-option argument
  # - $3 = third non-option argument, etc.
  local arg1="$1" arg2="$2" arg3="$3" arg4="$4"

  # 🧩 CASE A: Service + tag combined (e.g. node:v0.01)
  if [[ "$arg1" == *:* ]]; then
    SERVICE="${arg1%%:*}"         # Extract service name before the colon
    IMAGE_TAG="${arg1#*:}"         # Extract tag after the colon
    REQUESTED_SHELL="$arg2"        # Explicitly provided shell (optional, might be empty)
    PROJECT_NAME="$3"              # Optional project name
  else
    # 🧩 CASE B: Separate arguments (e.g. node v0.01 zsh)
    SERVICE="$arg1"
    case "$arg2" in
      sh|bash|zsh)
        # If arg2 looks like a known shell name, assume default image tag
        IMAGE_TAG="latest"
        REQUESTED_SHELL="$arg2"
        PROJECT_NAME="$3"
        ;;
      *)
        # Otherwise, assume second arg is a tag (e.g. v0.01), third arg may be shell
        IMAGE_TAG="${arg2:-latest}"  # Default to "latest" if missing
        REQUESTED_SHELL="$arg3"       # Third arg is optional shell (might be empty)
        PROJECT_NAME="$4"
        ;;
    esac
  fi

  # 🔁 Final fallbacks to ensure we never break the script downstream
  IMAGE_TAG="${IMAGE_TAG:-latest}"

  # IMPORTANT ⚡:
  # - DO NOT set default shell here anymore
  # - Leave REQUESTED_SHELL empty if not provided
  # - It will be *resolved dynamically* later (using _select_preferred_shell)
  # - This allows dynamic auto-detection (zsh → bash → sh) without being forced
}

# 🔎 _check_shell_exists: Attempt to create a container with a specific shell
#    - Used to determine if a given shell (e.g., zsh, bash, sh) exists inside the image
#    - Returns 0 if shell exists, 1 if it does not
#    - All success output is silent (stdout suppressed), only failure visible
_check_shell_exists() {
  local image="$1"  # Full image name (e.g. javierfraga/utilcntr-node:v0.01)
  local shell="$2"  # Shell to test (e.g. zsh, bash, sh)

  # 🌟 Try creating a temporary container with the shell as entrypoint
  #   - If the shell doesn't exist in the image, creation will fail
  #   - -c "exit 0" trick ensures it tries to execute cleanly if it does exist
  local container
  container=$(docker create --entrypoint "$shell" "$image" -c "exit 0" 2>/dev/null) || return 1

  # 🧹 Clean up the temporary container immediately after test
  docker rm -f "$container" >/dev/null 2>&1

  return 0  # ✅ Shell exists
}

# 🧠 _select_preferred_shell: Choose the best available shell to use inside the container
#    - If REQUESTED_SHELL is provided, validate it exists
#    - If not provided, fallback dynamically: try zsh → bash → sh
#    - Print success/failure messages cleanly to stderr
#    - Important: does NOT affect stdout, only prints user-facing info to stderr
_select_preferred_shell() {
  if [[ -n "$REQUESTED_SHELL" ]]; then
    # 📝 User explicitly requested a shell → validate it
    if _check_shell_exists "$image" "$REQUESTED_SHELL"; then
      printf "✅ Using explicitly requested shell: %s\n" "$REQUESTED_SHELL" >&2
    else
      printf "❌ Requested shell '%s' not found in image: %s\n" "$REQUESTED_SHELL" "$image" >&2
      exit 1
    fi
  else
    # 🔎 No shell specified → fallback sequence: zsh, then bash, then sh
    for candidate in zsh bash sh; do
      if _check_shell_exists "$image" "$candidate"; then
        REQUESTED_SHELL="$candidate"
        printf "✅ Auto-selected available shell: %s\n" "$REQUESTED_SHELL" >&2
        return 0
      fi
    done

    # ❌ No compatible shells found in image
    printf "❌ No supported shell found in image: %s\n" "$image" >&2
    exit 1
  fi
}

