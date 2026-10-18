#!/usr/bin/env python3
"""Package the built places and inspectable sources, excluding downloaded CLIs."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[1]
paths = []
for path in root.rglob("*"):
    relative = path.relative_to(root)
    if not path.is_file() or any(part.startswith(".") and part not in (".gitignore", ".luaurc") for part in relative.parts):
        continue
    if "__pycache__" in relative.parts or path.suffix in (".zip", ".log", ".pyc") or relative.as_posix() == "build/manifest.json":
        continue
    paths.append(path)
manifest = {"files": {p.relative_to(root).as_posix(): {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(paths)}}
manifest_path = root / "build/manifest.json"
manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
archive_path = root / "build/ADAPT-WorldFoundation.zip"
with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in paths + [manifest_path]:
        archive.write(path, "ADAPT/" + path.relative_to(root).as_posix())
with zipfile.ZipFile(archive_path) as archive:
    assert archive.testzip() is None
print(f"Packaged {len(paths) + 1} files: {archive_path} ({archive_path.stat().st_size:,} bytes). ZIP integrity verified.")
