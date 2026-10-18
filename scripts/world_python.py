"""Locate a Python with the world-building dependencies; no system installation."""
from pathlib import Path
import os,shutil,subprocess,sys

def interpreter():
    candidates=[os.environ.get('ADAPT_WORLD_PYTHON'),sys.executable,shutil.which('python3'),str(Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3')]
    for candidate in dict.fromkeys(c for c in candidates if c):
        if Path(candidate).is_file() and subprocess.run([candidate,'-c','import numpy; from PIL import Image'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:return candidate
    raise RuntimeError('World build needs NumPy + Pillow. Install requirements-world.txt in a virtual environment and set ADAPT_WORLD_PYTHON to its Python. The ready .rbxl needs no Python.')
