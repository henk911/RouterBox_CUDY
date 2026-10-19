#!/usr/bin/env python3
import hashlib,io,json,pathlib,tarfile,gzip,shutil,os
root=pathlib.Path(__file__).resolve().parent.parent
dist=root/'dist'
files=['luci-app-cudyroute-0.4.1-r1.apk','cudyroute-core-1.14.2-r14.apk','keys/cudyroute.pub','manifest.json','install.sh','README.ru.md','INSTALL.ru.md','LICENSE','UPSTREAM.md','VALIDATION.md','cudyroute-ui.js','update-ui.sh']
shutil.copyfile(root/'install.sh',dist/'install.sh')
shutil.copyfile(root/'files/www/luci-static/resources/view/cudyroute/main.js',dist/'cudyroute-ui.js')
ui_sha=hashlib.sha256((dist/'cudyroute-ui.js').read_bytes()).hexdigest()
ui_update=(root/'scripts/update-ui.template.sh').read_text().replace('@SHA@',ui_sha).replace('@REPO@',os.environ.get('CUDYROUTE_REPOSITORY','henk911/RouterBox_CUDY')).replace('@TAG@','v0.4.1')
(dist/'update-ui.sh').write_text(ui_update)
shutil.copyfile(root/'LICENSE',dist/'LICENSE')
shutil.copyfile(root/'VALIDATION.md',dist/'VALIDATION.md')
shutil.copyfile(root/'docs/UPSTREAM.md',dist/'UPSTREAM.md')
(dist/'README.ru.md').write_text((root/'README.md').read_text().replace('](docs/screenshots/', '](https://raw.githubusercontent.com/henk911/RouterBox_CUDY/main/docs/screenshots/').replace('](docs/INSTALL.md', '](https://github.com/henk911/RouterBox_CUDY/blob/main/docs/INSTALL.md'))
(dist/'INSTALL.ru.md').write_text((root/'docs/INSTALL.md').read_text().replace('](../README.md)', '](README.ru.md)'))
checks=''.join(hashlib.sha256((dist/name).read_bytes()).hexdigest()+'  '+name+'\n' for name in files)
(dist/'SHA256SUMS').write_text(checks)
files.append('SHA256SUMS')
with (dist/'cudyroute-wr3000u-0.4.1.tar.gz').open('wb') as f:
 with gzip.GzipFile(fileobj=f,mode='wb',mtime=0,filename='') as gz:
  with tarfile.open(fileobj=gz,mode='w|') as tar:
   for name in sorted(files):
    data=(dist/name).read_bytes();info=tarfile.TarInfo('cudyroute-wr3000u/'+name);info.size=len(data);info.mode=0o755 if name=='install.sh' else 0o644;info.mtime=0;tar.addfile(info,io.BytesIO(data))
print(json.dumps({'bundle_bytes':(dist/'cudyroute-wr3000u-0.4.1.tar.gz').stat().st_size,'app_apk_bytes':(dist/files[0]).stat().st_size,'core_apk_bytes':(dist/files[1]).stat().st_size}))

shutil.copyfile(dist/'cudyroute-wr3000u-0.4.1.tar.gz', dist/'cudyroute-wr3000u.tar.gz')
(dist/'SHA256SUMS.bundle').write_text(hashlib.sha256((dist/'cudyroute-wr3000u.tar.gz').read_bytes()).hexdigest()+'  cudyroute-wr3000u.tar.gz\n')
