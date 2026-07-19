#!/usr/bin/env bash
# Shared gate for the bootstrap scripts' network-fetching install steps.
# SETUP_SKIP_NETWORK_INSTALLS is a test-only escape hatch: unlike
# SETUP_DRY_RUN, it skips only these installs, letting tests exercise real
# symlinking without also hitting the network.

skip_network_install() {
  [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]
}
