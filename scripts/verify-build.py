#!/usr/bin/env python3
"""Check that a release really contains the advertised static ARM64 binaries."""
import gzip
import hashlib
import json
import pathlib
import struct

root = pathlib.Path(__file__).resolve().parent.parent
manifest = json.loads((root / 'dist/manifest.json').read_text())
assert manifest['arch'] == 'aarch64_cortex-a53'
assert manifest['size'] == (root / 'dist/sing-box-arm64').stat().st_size
for name in ('cudyroute-arm64', 'sing-box-arm64'):
    data = (root / 'dist' / name).read_bytes()
    assert data[:6] == b'\x7fELF\x02\x01', (name, 'not little-endian ELF64')
    assert struct.unpack_from('<H', data, 18)[0] == 183, (name, 'not AArch64')
    offset = struct.unpack_from('<Q', data, 32)[0]
    size, count = struct.unpack_from('<HH', data, 54)
    assert all(struct.unpack_from('<I', data, offset + i * size)[0] != 3 for i in range(count)), (name, 'dynamic interpreter')
    print(name + ': static ARM64 ELF verified')
compressed = (root / 'dist/sing-box-1.14.2-lx.12-wr3000u.gz').read_bytes()
assert hashlib.sha256(compressed).hexdigest() == manifest['sha256']
assert hashlib.sha256(gzip.decompress(compressed)).hexdigest() == manifest['binary_sha256']
print('Core gzip and manifest hashes verified')
