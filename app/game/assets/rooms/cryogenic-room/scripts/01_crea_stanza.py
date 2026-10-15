"""Crea la sala criogenica dal template Blender condiviso per le stanze."""

from pathlib import Path
import sys

import bpy


ASSET_DIR = Path(__file__).resolve().parent.parent
TEMPLATE = ASSET_DIR.parent / "template-room" / "set-template_room-modelling.blend"
BLEND_FILE = ASSET_DIR / "set-cryogenic_room-modeling.blend"
PREVIEW_FILE = ASSET_DIR / "exports" / "preview.png"
sys.path.insert(0, str(ASSET_DIR.parent))
from room_geometry import rebuild_room


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


require(
    Path(bpy.data.filepath).resolve() == TEMPLATE.resolve(),
    f"Aprire prima il template: {TEMPLATE}",
)
scene = bpy.data.scenes.get("main")
require(scene is not None, "Il template non contiene la scena main")
view_layer = scene.view_layers.get("main")
require(view_layer is not None, "Il template non contiene il view layer main")

asset_roots = [
    collection
    for collection in scene.collection.children
    if collection.asset_data is not None
]
require(len(asset_roots) == 1, "Il template deve avere un solo asset principale")
asset = asset_roots[0]
geometry = asset.children.get("template_room-geometry")
render = scene.collection.children.get("template_room-render")
reference = scene.collection.children.get("template_room-reference")
require(geometry is not None, "Manca SE-template_room/template_room-geometry")
require(
    render is not None and reference is not None,
    "Mancano template_room-render o template_room-reference",
)

asset.name = "SE-cryogenic_room"
geometry.name = "cryogenic_room-geometry"
asset.asset_data.description = "Stanza 3D minimale: volume, inquadratura e luce neutra"
rigging = asset.children.get("template_room-rigging")
if rigging is not None and not rigging.objects and not rigging.children:
    bpy.data.collections.remove(rigging)

rebuild_room(scene, geometry, render, "cryogenic_room")

root_layer = view_layer.layer_collection
for child in root_layer.children:
    if child.collection == render:
        child.exclude = False
    elif child.collection == reference:
        child.exclude = True
    elif child.collection == asset:
        child.exclude = False
        view_layer.active_layer_collection = next(
            grandchild
            for grandchild in child.children
            if grandchild.collection == geometry
        )

PREVIEW_FILE.parent.mkdir(parents=True, exist_ok=True)
scene.render.filepath = str(PREVIEW_FILE)
bpy.context.preferences.filepaths.save_version = 0
modeling_workspace = bpy.data.workspaces.get("Modelling")
require(modeling_workspace is not None, "Manca il workspace Modelling")
require(bpy.context.window is not None, "Manca la finestra Blender attiva")
bpy.context.window.workspace = modeling_workspace
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
bpy.ops.render.render(write_still=True)
