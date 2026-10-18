.PHONY: setup check build serve
setup:
	python3 scripts/setup_tools.py
check:
	python3 scripts/check.py
build:
	.tools/lune run scripts/export_world.luau
	python3 scripts/build_world_terrain.py
	.tools/rojo build default.project.json -o build/ADAPT.rbxlx
	.tools/lune run scripts/bake.luau
serve:
	.tools/rojo serve default.project.json
