#!/usr/bin/env python3
from pathlib import Path
import subprocess
from world_python import interpreter
root=Path(__file__).resolve().parents[1]
subprocess.run([interpreter(),'scripts/build_terrain.py'],cwd=root,check=True)
