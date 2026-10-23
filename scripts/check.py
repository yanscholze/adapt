#!/usr/bin/env python3
"""Reproducible offline verification. Never contacts Roblox or publishes anything."""
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from world_python import interpreter as world_python

ROOT = Path(__file__).resolve().parents[1]


def run(*args, quiet=False):
    result = subprocess.run(args, cwd=ROOT, stdout=subprocess.DEVNULL if quiet else None, stderr=subprocess.PIPE if quiet else None, text=True, errors="replace")
    if result.returncode:
        if quiet:
            print(result.stderr)
        raise SystemExit(result.returncode)


def static_contracts():
    """Resolve all source requires against their generated Roblox hierarchy."""
    tree = ET.parse(ROOT / "build/ADAPT.rbxlx")
    parents, children, scripts = {}, {}, {}
    for item in tree.iter("Item"):
        children[item] = {}
        for child in item.findall("Item"):
            parents[child] = item
            children[item][child.findtext("./Properties/string[@name='Name']")] = child
        if item.attrib["class"] in ("ModuleScript", "Script", "LocalScript"):
            source = item.findtext("./Properties/*[@name='Source']")
            assert source, "Empty or unreadable embedded script source"
            scripts[item] = source
    expected_sources = sorted(path.read_text() for path in (ROOT / "src").rglob("*.luau"))
    assert sorted(scripts.values()) == expected_sources, "Embedded scripts differ from current source files"
    services = {}
    for item in tree.getroot().findall("Item"):
        services[item.findtext("./Properties/string[@name='Name']")] = item
    shared = children[services["ReplicatedStorage"]]["Shared"]
    graph = {}
    for script, source in scripts.items():
        source = re.sub(r"--[^\n]*", "", source)
        aliases = {"script": script, "Shared": shared}
        for name, service in re.findall(r'local (\w+) = game:GetService\("(\w+)"\)', source):
            if service in services and name != "Shared":
                aliases[name] = services[service]
        for name, expr in re.findall(r"local (\w+) = (script(?:\.\w+)+)\s", source):
            aliases[name] = resolve(expr, aliases, parents, children)
        graph[script] = []
        for expr in re.findall(r"require\(([^)]+)\)", source):
            target = resolve(expr.strip(), aliases, parents, children)
            assert target is not None and target.attrib["class"] == "ModuleScript", f"Bad require: {expr}"
            graph[script].append(target)
    visited, active = set(), set()

    def visit(item):
        assert item not in active, "Circular require detected"
        if item in visited:
            return
        active.add(item)
        for dependency in graph[item]:
            visit(dependency)
        active.remove(item)
        visited.add(item)

    for script in scripts:
        visit(script)
    edge_count = sum(len(dependencies) for dependencies in graph.values())
    assert edge_count > len(scripts), "Require scanner unexpectedly found too few dependencies"
    config = (ROOT / "src/shared/Config.luau").read_text()
    remote_names = set(re.findall(r'"(\w+)"', config.split("Remotes =")[1]))
    for script, source in scripts.items():
        for remote in re.findall(r"(?:remotes|self\.remotes)\.(\w+)", source):
            assert remote in remote_names, f"Undefined remote: {remote}"
    print(f"PASS contracts: {len(scripts)} embedded sources match disk; {edge_count} valid requires; acyclic graph; declared remotes")


def resolve(expr, aliases, parents, children):
    path = expr.split(".")
    assert path[0] in aliases, f"Unknown require alias {expr}"
    item = aliases[path[0]]
    for segment in path[1:]:
        item = parents[item] if segment == "Parent" else children[item].get(segment)
        assert item is not None, f"Unresolved require {expr}"
    return item


def main():
    for binary in ["rojo", "luau-compile", "luau-analyze", "lune"]:
        if not (ROOT / ".tools" / binary).exists():
            raise SystemExit("Tools missing: run python3 scripts/setup_tools.py first.")
    run(str(ROOT / ".tools/lune"), "run", "scripts/export_world.luau")
    run(world_python(), "scripts/build_terrain.py")
    sources = list((ROOT / "src").rglob("*.luau")) + list((ROOT / "tests").glob("*.luau")) + list((ROOT / "scripts").glob("*.luau"))
    for source in sources:
        run(str(ROOT / ".tools/luau-compile"), str(source), quiet=True)
    print(f"PASS Luau syntax: {len(sources)} files")
    # Pure typed modules use strict; engine-bound modules use nonstrict checking.
    # Engine API types are not included in the standalone analyzer.
    run(str(ROOT / ".tools/luau-analyze"), "src")
    run(str(ROOT / ".tools/rojo"), "build", "default.project.json", "-o", "build/ADAPT.rbxlx")
    static_contracts()
    for test in ["core", "integration", "client", "world", "journey"]:
        run(str(ROOT / ".tools/lune"), "run", f"tests/{test}.luau")
    run(str(ROOT / ".tools/lune"), "run", "scripts/bake.luau")
    run(str(ROOT / ".tools/lune"), "run", "scripts/export_release.luau")
    static_contracts()
    run(world_python(), "tests/test_terrain.py")
    run(world_python(), "scripts/render_atlas.py")
    print("PASS ALL OFFLINE CHECKS. Studio playtest, real devices and cloud APIs remain manual.")


if __name__ == "__main__":
    main()
