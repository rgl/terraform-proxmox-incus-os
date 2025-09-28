#!/bin/bash
set -euo pipefail

function die {
  echo "Error: $@"
  exit 1
}

case "$INCUS_OS_SEED_DATA_COMMAND" in
  create)
    tmp_path="$INCUS_OS_SEED_DATA_ISO_PATH.tmp"
    rm -rf "$tmp_path"
    install -d "$tmp_path"
    echo -n "$INCUS_OS_SEED_DATA_NETWORK_CONFIG" >"$tmp_path/network.yaml"
    echo -n "$INCUS_OS_SEED_DATA_INCUS_CONFIG" >"$tmp_path/incus.yaml"
    xorriso \
      -as genisoimage \
      -output "$INCUS_OS_SEED_DATA_ISO_PATH" \
      -volid SEED_DATA \
      -joliet \
      -rock \
      "$tmp_path"
    rm -rf "$tmp_path"
    ;;
  destroy)
    rm -f "$INCUS_OS_SEED_DATA_ISO_PATH"
    ;;
  *)
    die "Unknown $INCUS_OS_SEED_DATA_COMMAND command."
    ;;
esac
