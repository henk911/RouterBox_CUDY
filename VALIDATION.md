# Validation — CudyRoute 0.4.1

Target: Cudy WR3000U v1, mediatek/filogic, aarch64_cortex-a53, OpenWrt 25.12.x (user device 25.12.6).

The 0.4.0 baseline also passed the full GitHub Actions integration workflow.

Completed locally for 0.4.1:

- Go 1.26.8 compiler download verified against the official Go release SHA256.
- Controller and sing-box-lx cross-compiled for Linux ARM64 / ARMv8.0 without CGO.
- Both ELF headers checked for AArch64, ELF64 little-endian and absence of a dynamic interpreter.
- Generated configurations (including separate UDP/DNS, per-direction DNS and Xray TCP/WS/gRPC/XHTTP imports) were accepted by the actual ARM64 core under QEMU.
- ARM64 controller defaults and core version executed using QEMU; core reports the pinned source commit and expected build tags.
- Controller tests with race detector and `go vet` passed.
- LuCI JavaScript syntax and existing interface smoke tests passed.
- Chromium checked cards, headings, toolbar and dialog inputs in light and dark LuCI palettes at a minimum 4.5:1 contrast, including the opposite OS colour preference. Desktop and mobile previews were visually inspected.
- Installer `--check` passed with a synthetic WR3000U environment and rejected MIPS, a different board, an incompatible OpenWrt release and insufficient RAM. These are host fixtures, not installation on physical hardware.
- APK metadata reports aarch64_cortex-a53. APK signature verification passed using APK tools 3.0.8 with package compatibility set to 3.0.0.
- Compressed core hashes and installation-bundle checksums verified.
- Workflow YAML and publication asset paths checked locally; GitHub Actions has not run for this new repository yet.

Limitations:

- There is no SSH connection to the physical router in this session. Package installation, kernel-module dependencies, DNS interception, TUN routing, IPv6, WARP reachability and game voice chat have not been tested on the device.
- The execution environment rejects network netlink sockets (`operation not permitted`). Three integration tests that start a full core therefore could not pass here. This does not confirm network operation on OpenWrt; perform on-device testing before relying on it.
- The core is the pinned upstream sing-box-lx build. No new protocol implementation, WARP registration service, universal game voice rules or independently verified AWG version has been added.
- A hosted GitHub repository and release must be created before bootstrap/update URLs become usable.
