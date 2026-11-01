#!/bin/sh
set -eu

CONFIG_DIR="${HOME:-/root}/.reticulum"
CONFIG_FILE="$CONFIG_DIR/config"

# `reticulum-go status` talks to the shared-instance RPC, which does not
# exist when share_instance is disabled. In that case fall back to a process
# liveness check so a valid standalone config does not make the container
# permanently unhealthy.
if [ -f "$CONFIG_FILE" ] && grep -qiE '^[[:space:]]*share_instance[[:space:]]*=[[:space:]]*(no|false|off|0|n)([[:space:]]*#.*)?[[:space:]]*$' "$CONFIG_FILE"; then
  for comm in /proc/[0-9]*/comm; do
    [ -r "$comm" ] || continue
    name=
    IFS= read -r name < "$comm" || continue
    if [ "$name" = "reticulum-go" ]; then
      exit 0
    fi
  done
  echo "reticulum-go process not found" >&2
  exit 1
fi

exec reticulum-go status -config "$CONFIG_DIR" >/dev/null 2>&1
