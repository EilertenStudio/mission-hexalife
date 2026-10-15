"""Prepara il file della nave per il blockout usando quattro reference ortografiche."""

from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector


ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "prop-deep_space_freighter-modeling.blend"
REFERENCE_DIR = ASSET_DIR / "references" / "orthographic"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def axes_rotation(horizontal, vertical, normal):
    """Build an image-plane rotation from its local X, Y and Z world axes."""
    basis = Matrix(
        (
            Vector(horizontal),
            Vector(vertical),
            Vector(normal),
        )
    ).transposed()
    return basis.to_euler()


def add_image_reference(
    name,
    filename,
    display_width,
    location,
    axes,
    visible_side="DOUBLE_SIDED",
):
    image_path = REFERENCE_DIR / filename
    require(image_path.is_file(), f"Reference mancante: {image_path}")

    image = bpy.data.images.load(str(image_path), check_existing=True)
    image.pack()

    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "IMAGE"
    obj.data = image
    obj.empty_display_size = display_width
    obj.empty_image_depth = "BACK"
    obj.empty_image_side = visible_side
    obj.show_empty_image_orthographic = True
    obj.show_empty_image_perspective = True
    obj.show_in_front = False
    obj.hide_render = True
    obj.location = location
    obj.rotation_euler = axes_rotation(*axes)
    reference_collection.objects.link(obj)
    return obj


require(
    Path(bpy.data.filepath).resolve() == BLEND_FILE.resolve(),
    f"Aprire prima il file Blender dell'asset: {BLEND_FILE}",
)

scene = bpy.data.scenes.get("main")
require(scene is not None, "Manca la scena main")
asset_root = scene.collection.children.get("PR-deep_space_freighter")
require(asset_root is not None, "Manca la collection radice dell'asset")
reference_collection = scene.collection.children.get(
    "deep_space_freighter-reference"
)
require(reference_collection is not None, "Manca la collection delle reference")
geometry_collection = asset_root.children.get("deep_space_freighter-geometry")
require(geometry_collection is not None, "Manca la collection della geometria")

# Rimuove lo scafo del blockout precedente, conservando camera e luci di scena.
for obj in list(bpy.data.objects):
    if obj.name.startswith("GEO-"):
        bpy.data.objects.remove(obj, do_unlink=True)

# Rende il task ripetibile senza duplicare immagini o Empty.
for obj in list(reference_collection.objects):
    if obj.name.startswith("REF-deep_space_freighter-"):
        bpy.data.objects.remove(obj, do_unlink=True)

for mesh in list(bpy.data.meshes):
    if mesh.name.startswith("GEO-deep_space_freighter-") and mesh.users == 0:
        bpy.data.meshes.remove(mesh)
for material in list(bpy.data.materials):
    if material.name.startswith("MAT-deep_space_freighter-") and material.users == 0:
        bpy.data.materials.remove(material)

geometry_collection.hide_viewport = False
geometry_collection.hide_render = True

# The ship's long axis is X: bow at -X, stern at +X, vertical is Z.
# Side and top drawings share X as their horizontal image axis.
add_image_reference(
    "REF-deep_space_freighter-side",
    "deep-space-freighter-side-v2.png",
    21.0,
    (0.0, 0.0, 0.05),
    ((1, 0, 0), (0, 0, 1), (0, -1, 0)),
)
add_image_reference(
    "REF-deep_space_freighter-top",
    "deep-space-freighter-top-v2.png",
    21.0,
    (0.0, 0.0, 0.0),
    ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
)

# The upper-right reference faces aft; the bow reference faces forward.
# Their opposite-facing image sides keep them from overlapping in orthographic view.
add_image_reference(
    "REF-deep_space_freighter-aft_front",
    "deep-space-freighter-aft-front-v2.png",
    6.2,
    (6.2, 0.0, 0.45),
    ((0, 1, 0), (0, 0, 1), (1, 0, 0)),
    "FRONT",
)
add_image_reference(
    "REF-deep_space_freighter-bow_front",
    "deep-space-freighter-bow-front-v2.png",
    4.0,
    (-10.4, 0.0, -0.05),
    ((0, -1, 0), (0, 0, 1), (-1, 0, 0)),
    "FRONT",
)

asset_root.asset_data.description = (
    "Setup di blockout con quattro reference ortografiche allineate agli assi; "
    "la geometria GEO precedente è stata rimossa."
)
asset_root["source_reference"] = (
    "references/deep-space-freighter-orthographic-reference-v2.png"
)
asset_root["iteration"] = "orthographic_reference_setup_v2"

# Make the four images visible in every saved 3D viewport. Keep the Modelling
# workspace selected and open on the side elevation when a UI context is present.
workspace = bpy.data.workspaces.get("Modelling")
if workspace is not None and bpy.context.window is not None:
    bpy.context.window.workspace = workspace

for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type != "VIEW_3D":
            continue
        space = area.spaces.active
        space.overlay.show_extras = True
        space.region_3d.view_perspective = "ORTHO"
        space.region_3d.view_rotation = Quaternion((1, 0, 0), 1.57079632679)
        space.region_3d.view_location = Vector((0.0, 0.0, 0.0))
        space.region_3d.view_distance = 25.0

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))

print(f"Reference inserite in: {BLEND_FILE}")
print("Reference attive: side, top, aft_front, bow_front")
print(f"Oggetti GEO rimasti: {sum(obj.name.startswith('GEO-') for obj in bpy.data.objects)}")
