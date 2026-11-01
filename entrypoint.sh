#!/bin/sh
set -e

CONFIG_DIR="$HOME/.reticulum"
CONFIG_FILE="$CONFIG_DIR/config"
GENERATED_FILE="$CONFIG_DIR/.config.generated"
mkdir -p "$CONFIG_DIR"

generate_config() {
  cat <<EOF
[reticulum]
  enable_transport = ${RNS_ENABLE_TRANSPORT:-True}
  share_instance = Yes
  panic_on_interface_error = No

[logging]
  loglevel = ${RNS_LOGLEVEL:-2}

[interfaces]
  [[Default Interface]]
    type = AutoInterface
    enabled = ${RNS_AUTO_INTERFACE:-yes}
    # Restrict discovery to specific interfaces to reduce CPU and threads,
    # e.g. RNS_AUTO_DEVICES=eth0 or RNS_AUTO_IGNORED_DEVICES=docker0,br0,veth0
${RNS_AUTO_DEVICES:+    devices = $RNS_AUTO_DEVICES
}${RNS_AUTO_IGNORED_DEVICES:+    ignored_devices = $RNS_AUTO_IGNORED_DEVICES
}
  [[TCP Server Interface]]
    type = TCPServerInterface
    enabled = ${RNS_TCP_ENABLED:-yes}
    listen_ip = 0.0.0.0
    listen_port = ${RNS_TCP_PORT:-4242}
EOF
}

# A config is treated as user-provided when it exists and differs from the
# last config this script generated. Auto-generated configs are rewritten on
# every start, so environment changes apply without deleting the volume.
# Editing the config makes it user-provided and it will no longer be touched.
if [ -f "$CONFIG_FILE" ] && { [ ! -f "$GENERATED_FILE" ] || ! cmp -s "$CONFIG_FILE" "$GENERATED_FILE"; }; then
  echo "Using existing config at $CONFIG_FILE"
else
  if [ -f "$CONFIG_FILE" ]; then
    echo "Regenerating auto-generated config at $CONFIG_FILE"
  else
    echo "No config found, writing default to $CONFIG_FILE"
  fi
  generate_config > "$CONFIG_FILE"
  cp "$CONFIG_FILE" "$GENERATED_FILE"
fi

exec "$@"
