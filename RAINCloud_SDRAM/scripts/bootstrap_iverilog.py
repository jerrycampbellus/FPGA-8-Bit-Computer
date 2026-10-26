"""Optional Windows project-local simulator. Downloads MSYS2 packages, checks SHA256.
No PATH/registry/machine installation. Requires Python 3 and Windows tar.
"""
import hashlib
import re
import subprocess
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'build' / 'tools'
root.mkdir(parents=True, exist_ok=True)
packages = ['iverilog', 'cc-libs', 'libgcc', 'libstdc++', 'libwinpthread',
            'readline', 'termcap', 'bzip2', 'zlib']
for name in packages:
    package = 'mingw-w64-ucrt-x86_64-' + name
    page = urllib.request.urlopen('https://packages.msys2.org/packages/' + package, timeout=30).read().decode()
    url = re.search(r'https://mirror.msys2.org/mingw/ucrt64/[^"<> ]+\.pkg\.tar\.zst', page).group()
    sha = re.search(r'[a-f0-9]{64}', page[page.index('SHA256:'):]).group()
    archive = root / (name + '.tar.zst')
    if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest() != sha:
        archive.write_bytes(urllib.request.urlopen(url.replace('mirror.msys2.org', 'repo.msys2.org'), timeout=60).read())
    if hashlib.sha256(archive.read_bytes()).hexdigest() != sha:
        raise RuntimeError('Checksum mismatch: ' + name)
    subprocess.run(['tar', '-xf', str(archive), '-C', str(root)], check=True)
    print(name, sha, flush=True)
