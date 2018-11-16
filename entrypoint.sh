#!/bin/bash

LOGGING="--log-level $LOG_LEVEL"

# used for monerod and monero-wallet-rpc
RPC_OPTIONS="$LOGGING --confirm-external-bind --rpc-bind-ip $RPC_BIND_IP --rpc-bind-port $RPC_BIND_PORT"
# used for monerod
AEOND_OPTIONS="--p2p-bind-ip $P2P_BIND_IP --p2p-bind-port $P2P_BIND_PORT"

AEOND="aeond $@ $RPC_OPTIONS $AEOND_OPTIONS --check-updates disabled"

if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $AEOND
# elif [ "$1" = "monero-wallet-rpc" ]; then
#   set -- "$@ $RPC_OPTIONS"
# elif [ "$1" = "monero-wallet-cli" ]; then
#   set -- "$@ $LOGGING"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (DOckerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false aeon
  exec su-exec aeon $@
fi


exec $@
