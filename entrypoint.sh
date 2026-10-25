#!/bin/sh
set -e

if [ ! -f /config/config ]; then
  echo "No config found, writing default to /config/config"
  cat > /config/config <<EOF
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

exec "$@"
