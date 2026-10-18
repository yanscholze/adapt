#!/usr/bin/env python3
"""Install pinned public CLI releases locally, without accounts or system changes."""
import hashlib
import io
import json
import platform
from pathlib import Path
import urllib.request
import zipfile

root = Path(__file__).resolve().parents[1]
if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
    raise SystemExit("This installer targets Linux x86_64. Open build/ADAPT.rbxl directly in Studio on Windows/macOS, or install the pinned CLIs for your platform.")
destination = root / ".tools"
destination.mkdir(exist_ok=True)
for name, asset in json.loads((root / "tools.lock.json").read_text()).items():
    if all((destination / binary).is_file() and hashlib.sha256((destination / binary).read_bytes()).hexdigest() == asset["binarySha256"][binary] for binary in asset["binaries"]):
        print(name, "already present; locked version", asset["version"])
        continue
    data = urllib.request.urlopen(asset["url"], timeout=90).read()
    if hashlib.sha256(data).hexdigest() != asset["sha256"]:
        raise SystemExit("Checksum mismatch: " + name)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for binary in asset["binaries"]:
            path = destination / binary
            path.write_bytes(archive.read(binary))
            path.chmod(0o755)
    print(name, asset["version"], "installed; archive SHA256 verified")
