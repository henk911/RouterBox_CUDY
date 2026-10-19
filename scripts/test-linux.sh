#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export GOTOOLCHAIN=go1.26.8
export GOMODCACHE="$PWD/build/gomod"
export GOCACHE="$PWD/build/gocache"
export CGO_ENABLED=0
mkdir -p build
ARCH=$(go env GOARCH)
case "$ARCH" in amd64|arm64) ;; *) echo "Unsupported test host: $ARCH" >&2; exit 1;; esac
./scripts/patch-core.sh
GOOS=linux GOARCH="$ARCH" go test -c -o "build/cudyroute-tests-linux-$ARCH" ./internal/cudyroute
(
 cd build/core-source
 GOOS=linux GOARCH="$ARCH" go build -trimpath -tags with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,with_xhttp,with_awg -ldflags '-s -w -buildid= -checklinkname=0 -X github.com/sagernet/sing-box/constant.Version=1.14.2-lx.12-cudy.1' -o "../sing-box-linux-$ARCH" ./cmd/sing-box
)
if [ "${CUDYROUTE_NATIVE_TEST:-0}" = 1 ]; then
 CUDYROUTE_TEST_CORE="$PWD/build/sing-box-linux-$ARCH" ./"build/cudyroute-tests-linux-$ARCH" -test.v
else
 docker run --rm -v "$PWD:/work:ro" -e "CUDYROUTE_TEST_CORE=/work/build/sing-box-linux-$ARCH" -e CUDYROUTE_TEST_SERVICES alpine@sha256:020dfcbaaf4cc1078bf2d9c7ba31a8466e334061dcd2f248001d68f79e52c000 /work/"build/cudyroute-tests-linux-$ARCH" -test.v
fi
