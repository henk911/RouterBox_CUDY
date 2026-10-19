#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Retained upstream compatibility patch; also safe on 64-bit ARM.
PATCH="$PWD/patches/sing-tun-32bit-route-table.patch"
SOURCE="$PWD/build/core-source/submodules/sing-tun"
if git -C "$SOURCE" apply --check "$PATCH" 2>/dev/null; then
 git -C "$SOURCE" apply "$PATCH"
else
 git -C "$SOURCE" apply --reverse --check "$PATCH"
fi
