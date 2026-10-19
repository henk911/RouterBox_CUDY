#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build dist/keys
if [ ! -f build/cudyroute-private.pem ]; then
 openssl genrsa -out build/cudyroute-private.pem 2048
 chmod 600 build/cudyroute-private.pem
fi
openssl rsa -in build/cudyroute-private.pem -pubout -out dist/keys/cudyroute.pub
if [ -n "${CUDYROUTE_APK:-}" ]; then
 APK="$CUDYROUTE_APK" sh scripts/package-files.sh
else
 # Pinned upstream builder; this is used by GitHub Actions.
 docker run --rm -v "$PWD:/work" -w /work alpine@sha256:020dfcbaaf4cc1078bf2d9c7ba31a8466e334061dcd2f248001d68f79e52c000 sh scripts/package-files.sh
fi
python3 scripts/bundle.py
