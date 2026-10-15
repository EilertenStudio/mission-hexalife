"""Materializza il template per i set interni dalla base Blender generica."""

import json
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector


ASSET_DIR = Path(__file__).resolve().parent.parent
BASE_FILE = ASSET_DIR.parents[1] / "template.blend"
BLEND_FILE = ASSET_DIR / "set-template_room-modelling.blend"
CAMERA_FILE = (
    ASSET_DIR.parents[2]
    / "src"
    / "scenes"
    / "cryogenic-room"
    / "camera.json"
)
sys.path.insert(0, str(ASSET_DIR.parent))
from room_geometry import rebuild_room


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def rename_collection(collection, name):
    require(collection is not None, f"Collection mancante: {name}")
    collection.name = name
    return collection


def from_arcade(vector):
    """Converte coordinate Arcade Y-up in coordinate Blender Z-up."""
    x, y, z = vector
    return Vector((x, -z, y))


require(
    Path(bpy.data.filepath).resolve() == BASE_FILE.resolve(),
    f"Aprire prima {BASE_FILE}",
)

scene = bpy.data.scenes.get("main") or bpy.data.scenes.get("Main")
require(scene is not None, "La base non contiene la scena main")
scene.name = "main"
view_layer = scene.view_layers.get("main") or scene.view_layers.get("Main")
require(view_layer is not None, "La base non contiene il View Layer main")
view_layer.name = "main"

asset_roots = [
    collection
    for collection in scene.collection.children
    if collection.asset_data is not None
]
require(len(asset_roots) == 1, "La base deve avere una sola collection asset")
asset = rename_collection(asset_roots[0], "SE-template_room")
geometry = rename_collection(asset.children.get("Geometry"), "template_room-geometry")
rigging = rename_collection(asset.children.get("Rigging"), "template_room-rigging")
reference = rename_collection(
    scene.collection.children.get("Reference"), "template_room-reference"
)
render = rename_collection(scene.collection.children.get("Render"), "template_room-render")

camera = render.objects.get("Camera")
require(camera is not None and camera.type == "CAMERA", "Manca Camera nel template base")
camera.name = "HLP-template_room-camera"
camera.data.name = "template_room-camera"

sun = render.objects.get("Sun")
require(sun is not None and sun.type == "LIGHT", "Manca Sun nel template base")
sun.name = "LGT-template_room-sun"
sun.data.name = "template_room-sun"

for old_name, new_name in (
    ("Dots Stroke", "template_room-dots_stroke"),
    ("Material", "template_room-default_material"),
):
    material = bpy.data.materials.get(old_name)
    if material is not None:
        material.name = new_name

world = bpy.data.worlds.get("Main") or bpy.data.worlds.get("World")
if world is not None:
    world.name = "template_room-world"

camera_state = json.loads(CAMERA_FILE.read_text(encoding="utf-8"))
camera_view = camera_state["initial_view"]
projection = camera_state["projection"]
eye = from_arcade(camera_view["eye"])
forward = (from_arcade(camera_view["target"]) - eye).normalized()
up = from_arcade(camera_view["up"]).normalized()
right = forward.cross(up).normalized()
camera_up = right.cross(forward).normalized()
rotation_matrix = Matrix((right, camera_up, -forward)).transposed()

camera.location = eye
camera.rotation_mode = "XYZ"
camera.rotation_euler = rotation_matrix.to_euler("XYZ")
camera.data.type = "PERSP"
camera.data.lens = float(projection["focal_length_mm"])
camera.data.clip_start = float(projection["near"])
camera.data.clip_end = float(projection["far"])
scene.camera = camera
asset.asset_data.description = "Template riutilizzabile per set e stanze interne"
rebuild_room(scene, geometry, render, "template_room")

workspace = bpy.data.workspaces.get("Modelling")
require(workspace is not None, "Manca il workspace Modelling")
require(bpy.context.window is not None, "Manca la finestra Blender attiva")
bpy.context.window.workspace = workspace

BLEND_FILE.parent.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
print(f"Template per set interni materializzato: {BLEND_FILE}")
