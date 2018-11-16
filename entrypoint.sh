#!/bin/bash

LOGGING="--log-level $LOG_LEVEL"

DAEMON_OPTIONS="--daemon-host $DAEMON_HOST --daemon-port $DAEMON_PORT"

# used for aeon and aeon-wallet-rpc
RPC_OPTIONS="$LOGGING --confirm-external-bind --rpc-bind-ip $RPC_BIND_IP --rpc-bind-port $RPC_BIND_PORT"
# used for aeond
AEOND_OPTIONS="--p2p-bind-ip $P2P_BIND_IP --p2p-bind-port $P2P_BIND_PORT"

AEOND="aeond $@ $RPC_OPTIONS $AEOND_OPTIONS --check-updates disabled"

if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $AEOND
elif [[ "$1" = aeon-wallet-rpc* ]]; then
  set -- "$@ $DAEMON_OPTIONS $RPC_OPTIONS"
elif [[ "$1" = aeon-wallet-cli* ]]; then
  set -- "$@ $DAEMON_OPTIONS $LOGGING"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (DOckerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false aeon &> /dev/null
  exec su-exec aeon $@
fi


exec $@
