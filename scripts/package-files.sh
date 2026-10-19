#!/bin/sh
# Run from the repository root, locally with APK 3 or inside the pinned container.
set -eu
APK=${APK:-apk}
"$APK" mkpkg --compat 3.0.0 --compression deflate:9 --sign-key build/cudyroute-private.pem --files build/stage-app --info name:luci-app-cudyroute --info version:0.4.1-r1 --info arch:aarch64_cortex-a53 --info license:GPL-3.0-or-later --info description:"CudyRoute LuCI subscriptions, DNS and routing for Cudy WR3000U" --info depends:"luci-base rpcd jsonfilter ca-bundle kmod-tun kmod-nft-nat kmod-nft-queue ip-full nftables-json" --script post-install:scripts/post-install --script pre-deinstall:scripts/pre-deinstall --output dist/luci-app-cudyroute-0.4.1-r1.apk
"$APK" mkpkg --compat 3.0.0 --compression deflate:9 --sign-key build/cudyroute-private.pem --files build/stage-core --info name:cudyroute-core --info version:1.14.2-r14 --info arch:aarch64_cortex-a53 --info license:GPL-3.0-or-later --info description:"Compressed sing-box-lx ARM64 core for Cudy WR3000U" --output dist/cudyroute-core-1.14.2-r14.apk
"$APK" --keys-dir "$PWD/dist/keys" verify dist/luci-app-cudyroute-0.4.1-r1.apk dist/cudyroute-core-1.14.2-r14.apk
"$APK" adbdump dist/luci-app-cudyroute-0.4.1-r1.apk > build/app-package-metadata.txt
"$APK" adbdump dist/cudyroute-core-1.14.2-r14.apk > build/core-package-metadata.txt
