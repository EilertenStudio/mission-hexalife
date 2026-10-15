"""Ripristina i nomi generici della base Blender mantenendo il workspace."""

from pathlib import Path

import bpy


ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "template.blend"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


require(
    Path(bpy.data.filepath).resolve() == BLEND_FILE.resolve(),
    f"Aprire prima {BLEND_FILE}",
)
scene = bpy.data.scenes.get("Main") or bpy.data.scenes.get("main")
require(scene is not None, "Manca la scena Main")
scene.name = "main"
view_layer = scene.view_layers.get("Main") or scene.view_layers.get("main")
require(view_layer is not None, "Manca il view layer Main")
view_layer.name = "main"

asset_roots = [
    collection
    for collection in scene.collection.children
    if collection.asset_data is not None
]
require(len(asset_roots) == 1, "La base deve avere una sola collection asset")
asset = asset_roots[0]
was_namespaced = asset.name == "SE-template"
asset.name = "Asset"
geometry = asset.children.get("template-geometry") or asset.children.get("Geometry")
rigging = asset.children.get("template-rigging") or asset.children.get("Rigging")
require(geometry is not None, "Manca la collection Geometry")
require(rigging is not None, "Manca la collection Rigging")
geometry.name = "Geometry"
rigging.name = "Rigging"
reference = scene.collection.children.get("template-reference") or scene.collection.children.get("Reference")
render = scene.collection.children.get("template-render") or scene.collection.children.get("Render")
require(reference is not None and render is not None, "Mancano Reference o Render")
reference.name = "Reference"
render.name = "Render"

placeholder = geometry.objects.get("TMP-template-sphere") or geometry.objects.get("Sphere")
camera = render.objects.get("HLP-template-camera") or render.objects.get("Camera")
sun = render.objects.get("LGT-template-sun") or render.objects.get("Sun")
require(placeholder is not None and camera is not None and sun is not None, "Mancano oggetti base")
placeholder.name = "Sphere"
placeholder.data.name = "Sphere"
camera.name = "Camera"
camera.data.name = "Camera"
sun.name = "Sun"
sun.data.name = "Sun"

for old_name, new_name in (
    ("template-dots_stroke", "Dots Stroke"),
    ("template-default_material", "Material"),
):
    material = bpy.data.materials.get(old_name)
    if material is not None:
        material.name = new_name
world = bpy.data.worlds.get("template-world")
if world is not None:
    world.name = "Main"

# La vecchia base namespaced deriva da una variante per la cryogenic-room.
# Quando la si usa per ricostruire la base generica, ripristina anche la camera
# originale del template Blender. Una base già generica mantiene le sue pose.
if was_namespaced:
    camera.location = (3.701648, -3.701649, 3.022382)
    camera.rotation_mode = "XYZ"
    camera.rotation_euler = (1.047198, 0.0, 0.785398)
    camera.data.type = "PERSP"
    camera.data.lens = 50.0
    camera.data.clip_start = 0.1
    camera.data.clip_end = 1000.0
    camera.data.sensor_width = 36.0
    camera.data.sensor_fit = "AUTO"
asset.asset_data.description = ""

require(bpy.data.workspaces.get("Modelling") is not None, "Manca il workspace Modelling")

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
print(f"Template generico preparato: {BLEND_FILE}")
