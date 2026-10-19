#!/bin/sh
# After publishing v0.4.0 or newer, download a signed release bundle.
set -eu
REPO=${CUDYROUTE_REPOSITORY:-henk911/RouterBox_CUDY}
MODE=${1:---flash}
case "$MODE" in --flash|--check|--disabled|--app-only) ;; *) echo 'Unknown installation mode' >&2; exit 1;; esac
case "$REPO" in *[!A-Za-z0-9_./-]*|../*|*/../*|/*) echo 'Invalid repository' >&2; exit 1;; esac
[ "$(id -u)" = 0 ] || { echo 'Run as root' >&2; exit 1; }
TASK_DIR=$(mktemp -d /tmp/cudyroute-install.XXXXXX)
trap 'rm -rf "$TASK_DIR"' EXIT INT TERM
fetch() {
 if command -v curl >/dev/null 2>&1; then curl -fL --retry 2 --connect-timeout 15 --max-time 300 "$1" -o "$2"
 else wget -O "$2" "$1"
 fi
}
BASE="https://github.com/$REPO/releases/latest/download"
fetch "$BASE/cudyroute-wr3000u.tar.gz" "$TASK_DIR/cudyroute-wr3000u.tar.gz"
fetch "$BASE/SHA256SUMS.bundle" "$TASK_DIR/SHA256SUMS.bundle"
cd "$TASK_DIR"
sha256sum -c SHA256SUMS.bundle
tar -xzf cudyroute-wr3000u.tar.gz
cd cudyroute-wr3000u
sh ./install.sh "$MODE"
