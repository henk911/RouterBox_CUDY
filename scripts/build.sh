#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
ROOT="$PWD"
export GOTOOLCHAIN=${GOTOOLCHAIN:-go1.26.8}
export GOMODCACHE="$ROOT/build/gomod"
export GOCACHE="$ROOT/build/gocache"
export CGO_ENABLED=0
CORE_TAG=v1.14.2-lx.12
CORE_COMMIT=a97658c1d122a64b405621a94e1db971f8939f8d
TAGS=with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,with_xhttp,with_awg
mkdir -p build dist
[ -f build/go.mod ] || printf 'module cudyroute-build-cache\n\ngo 1.25.0\n' > build/go.mod
if [ ! -d build/core-source ]; then
 git clone --depth 1 --branch "$CORE_TAG" https://github.com/Leadaxe/sing-box-lx.git build/core-source
 git -C build/core-source submodule update --init --depth 1 submodules/sing-tun submodules/gvisor submodules/utls submodules/wireguard-go
fi
[ "$(git -C build/core-source rev-parse HEAD)" = "$CORE_COMMIT" ] || { echo 'Unexpected core source revision' >&2; exit 1; }
./scripts/patch-core.sh
go mod download
RELEASE_REPO=${CUDYROUTE_REPOSITORY:-henk911/RouterBox_CUDY}
GOOS=linux GOARCH=arm64 GOARM64=v8.0 go build -trimpath -ldflags "-s -w -buildid= -X cudyroute/internal/cudyroute.ReleaseRepository=$RELEASE_REPO" -o dist/cudyroute-arm64 ./cmd/cudyroute
(
 cd build/core-source
 GOOS=linux GOARCH=arm64 GOARM64=v8.0 go build -trimpath -tags "$TAGS" -ldflags '-s -w -buildid= -checklinkname=0 -X github.com/sagernet/sing-box/constant.Version=1.14.2-lx.12-cudy.1' -o ../../dist/sing-box-arm64 ./cmd/sing-box
)
python3 scripts/stage.py
python3 scripts/verify-build.py
if [ "${CUDYROUTE_SKIP_PACKAGE:-0}" != 1 ]; then
 ./scripts/package-apk.sh
fi
