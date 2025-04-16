#!/bin/bash

# Finds the most recently started container for a given service name
# Outputs container name via stdout
# Returns non-zero and prints an error if none are found
_find_latest_container() {
  local service="$1"
  local container_name

  container_name=$(docker ps \
    --filter "name=^/${service}_" \
    --format '{{.Names}}' | head -n 1)

  if [[ -z "$container_name" ]]; then
    echo "❌ No running container found for service '${service}'." >&2
    return 1
  fi

  echo "$container_name"
}

