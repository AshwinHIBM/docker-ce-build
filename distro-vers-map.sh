#!/bin/bash
# Shared mapping from numeric distro version to codename.
# Sourced by build-containerd.sh and test.sh.

distro_vers_to_name() {
  local vers="$1"
  case "${vers}" in
    13)   echo "trixie"   ;;
    12)   echo "bookworm" ;;
    2204) echo "jammy"    ;;
    2404) echo "noble"    ;;
    2604) echo "resolute" ;;
    *)    echo "${vers}"  ;;
  esac
}
