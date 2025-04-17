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

