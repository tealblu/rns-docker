#!/bin/sh
set -eu
umask 077

CONFIG_DIR="${HOME:-/root}/.reticulum"
mkdir -p "$CONFIG_DIR"
# Best effort: read-only bind mounts may reject chmod.
chmod 700 "$CONFIG_DIR" 2>/dev/null || true

if [ ! -f "$CONFIG_DIR/config" ]; then
  echo "No config found, writing default to $CONFIG_DIR/config"
  cat > "$CONFIG_DIR/config" <<EOF
[reticulum]
  enable_transport = ${RNS_ENABLE_TRANSPORT:-True}
  share_instance = Yes
  panic_on_interface_error = No

[logging]
  loglevel = ${RNS_LOGLEVEL:-4}

[interfaces]
  [[Default Interface]]
    type = AutoInterface
    enabled = yes

  [[TCP Server Interface]]
    type = TCPServerInterface
    enabled = yes
    listen_ip = 0.0.0.0
    listen_port = ${RNS_TCP_PORT:-4242}
EOF
fi

chmod 600 "$CONFIG_DIR/config" 2>/dev/null || true

exec "$@"
