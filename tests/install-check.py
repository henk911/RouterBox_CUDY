#!/usr/bin/env python3
"""Exercise --check against synthetic OpenWrt files; never mutate host /etc."""
import json
import os
import pathlib
import shutil
import subprocess
import tarfile
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='cudyroute-check-') as temp:
    base = pathlib.Path(temp)
    with tarfile.open(root / 'dist/cudyroute-wr3000u-0.4.0.tar.gz') as tar:
        tar.extractall(base, filter='data')
    bundle = base / 'cudyroute-wr3000u'
    system = base / 'system'
    for rel in ('etc/apk', 'tmp/sysinfo', 'proc', 'bin'):
        (system / rel).mkdir(parents=True, exist_ok=True)
    original = (bundle / 'install.sh').read_text()
    for prefix in ('/etc/', '/tmp/sysinfo/', '/proc/meminfo'):
        original = original.replace(prefix, str(system) + prefix)
    test_script = bundle / 'check-fixture.sh'
    test_script.write_text(original)
    helpers = {
        'id': '#!/bin/sh\necho 0\n',
        'apk': '#!/bin/sh\necho "ERROR: check attempted to install" >&2\nexit 99\n',
        'df': '#!/bin/sh\nprintf "Filesystem 1024-blocks Used Available Capacity Mounted\\nfixture 524288 65536 458752 12%% /fixture\\n"\n',
        'jsonfilter': '#!/usr/bin/env python3\nimport json,sys\na=sys.argv[1:];j=json.load(open(a[a.index("-i")+1]));print(j[a[a.index("-e")+1][2:]])\n',
    }
    for name, content in helpers.items():
        p = system / 'bin' / name
        p.write_text(content)
        p.chmod(0o755)
    env = dict(os.environ, PATH=str(system / 'bin') + ':' + os.environ['PATH'])
    def check(label, *, arch='aarch64_cortex-a53', board='cudy,wr3000u-v1', release='25.12.6', ram=300000, success=False, message=''):
        (system / 'etc/openwrt_release').write_text(f"DISTRIB_TARGET='mediatek/filogic'\nDISTRIB_RELEASE='{release}'\n")
        (system / 'etc/apk/arch').write_text(arch + '\n')
        (system / 'tmp/sysinfo/board_name').write_text(board + '\n')
        (system / 'proc/meminfo').write_text(f'MemAvailable: {ram} kB\n')
        result = subprocess.run(['sh', str(test_script), '--check'], cwd=bundle, env=env, capture_output=True, text=True)
        output = result.stdout + result.stderr
        assert (result.returncode == 0) == success, (label, result.returncode, output)
        assert message in output, (label, output)
        assert 'check attempted to install' not in output, output
        print(label + ': OK')
    check('WR3000U ARM64 accepted without mutation', success=True, message='роутер не изменён')
    check('MIPS rejected', arch='mipsel_24kc', message='архитектура')
    check('Different board rejected', board='cudy,wr3000-v1', message='WR3000U')
    check('Incompatible release rejected', release='24.10.7', message='25.12.x')
    check('Low available memory rejected', ram=10000, message='Недостаточно свободной RAM')
