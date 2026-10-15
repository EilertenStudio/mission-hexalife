"""Esporta solo la geometria della sala criogenica in Wavefront OBJ."""

from pathlib import Path
from shutil import copyfile

import bpy


ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "set-cryogenic_room-modeling.blend"
OBJ_FILE = ASSET_DIR / "exports" / "cryogenic-room.obj"
SCENE_DIR = ASSET_DIR.parents[2] / "src" / "scenes" / "cryogenic-room"

if Path(bpy.data.filepath).resolve() != BLEND_FILE.resolve():
    raise RuntimeError(f"Aprire prima {BLEND_FILE}")

scene = bpy.context.scene
asset_roots = [collection for collection in scene.collection.children if collection.asset_data]
if len(asset_roots) != 1:
    raise RuntimeError("È richiesta una sola collection marcata come asset")

geometry = asset_roots[0].children.get("cryogenic_room-geometry")
if geometry is None:
    raise RuntimeError("Manca la collection cryogenic_room-geometry")

mesh_objects = [obj for obj in geometry.objects if obj.type == "MESH"]
if len(mesh_objects) != 5:
    raise RuntimeError("L'OBJ deve contenere le cinque superfici della stanza")

bpy.ops.object.select_all(action="DESELECT")
for obj in mesh_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = mesh_objects[0]

OBJ_FILE.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.obj_export(
    filepath=str(OBJ_FILE),
    export_selected_objects=True,
    forward_axis="NEGATIVE_Z",
    up_axis="Y",
    apply_modifiers=True,
    export_uv=False,
    export_normals=True,
    export_materials=True,
    export_object_groups=True,
    export_triangulated_mesh=True,
)
SCENE_DIR.mkdir(parents=True, exist_ok=True)
for extension in ("obj", "mtl"):
    source = OBJ_FILE.with_suffix(f".{extension}")
    copyfile(source, SCENE_DIR / source.name)
print(f"Esportato {OBJ_FILE}")
print(f"Importato OBJ e MTL in {SCENE_DIR}")
