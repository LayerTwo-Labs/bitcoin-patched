#!/bin/bash
set -e

if [ -n "${UID+x}" ] && [ "${UID}" != "0" ]; then
  usermod -u "$UID" drivechain
fi

if [ -n "${GID+x}" ] && [ "${GID}" != "0" ]; then
  groupmod -g "$GID" drivechain
fi

echo "$0: assuming uid:gid for drivechain:drivechain of $(id -u drivechain):$(id -g drivechain)"

if [ "$(echo "$1" | cut -c1)" = "-" ]; then
  echo "$0: assuming arguments for drivechaind"

  set -- drivechaind "$@"
fi

if [ "$(echo "$1" | cut -c1)" = "-" ] || [ "$1" = "drivechaind" ]; then
  mkdir -p "$DRIVECHAIN_DATA"
  chmod 700 "$DRIVECHAIN_DATA"
  # Fix permissions for home dir.
  chown -R drivechain:drivechain "$(getent passwd drivechain | cut -d: -f6)"
  # Fix permissions for drivechain data dir.
  chown -R drivechain:drivechain "$DRIVECHAIN_DATA"

  echo "$0: setting data directory to $DRIVECHAIN_DATA"

  set -- "$@" -datadir="$DRIVECHAIN_DATA"
fi

if [ "$1" = "drivechaind" ] || [ "$1" = "drivechain-cli" ]; then
  echo
  exec gosu drivechain "$@"
fi

echo
exec "$@"
