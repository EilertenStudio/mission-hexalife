"""Rigenera soltanto il blockout P0 della nave dalla reference ortografica v2."""

from pathlib import Path

import bmesh
import bpy
from mathutils import Quaternion, Vector

ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "prop-deep_space_freighter-modeling.blend"
EXPORT_DIR = ASSET_DIR / "exports"
PREFIX = "GEO-deep_space_freighter-"
EXPECTED_GEO_NAMES = {
    PREFIX + suffix for suffix in (
        "forward_core", "forward_upper_mass", "forward_lower_rail.L",
        "forward_lower_rail.R", "forward_lower_support.L",
        "forward_lower_support.R", "central_transition", "central_aft_core",
        "central_aft_lateral_mass.L", "central_aft_lateral_mass.R",
        "upper_aft_mass", "tapered_stern",
    )
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def mesh_object(name, vertices, faces, collection, material):
    obj = bpy.data.objects.get(name)
    require(obj is not None and obj.type == "MESH", f"Oggetto P0 mancante: {name}")
    require(obj.name in collection.objects, f"Oggetto fuori da Geometry: {name}")
    mesh = obj.data
    require(mesh.users == 1, f"Mesh condivisa, modifica non sicura: {name}")
    mesh.clear_geometry()
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    mesh.materials.clear()
    mesh.materials.append(material)
    return obj


def loft(name, stations, collection, material, center_y=0.0):
    """Closed faceted loft; optional final pair makes an inset lower section.

    Stations are (x, half_width, center_z, half_height[, inset_width,
    inset_bottom]). The six-value profile belongs to the same mesh object.
    """
    vertices = []
    size = None
    for station in stations:
        x, half_width, center_z, half_height = station[:4]
        main_bottom = center_z - half_height
        if len(station) == 6:
            inset_width, inset_bottom = station[4:]
            profile = (
                (-inset_width, inset_bottom),
                (inset_width, inset_bottom),
                (inset_width, main_bottom),
                (0.68 * half_width, main_bottom),
                (half_width, center_z - 0.58 * half_height),
                (half_width, center_z + 0.58 * half_height),
                (0.68 * half_width, center_z + half_height),
                (-0.68 * half_width, center_z + half_height),
                (-half_width, center_z + 0.58 * half_height),
                (-half_width, center_z - 0.58 * half_height),
                (-0.68 * half_width, main_bottom),
                (-inset_width, main_bottom),
            )
        else:
            profile = (
                (-0.68 * half_width, main_bottom),
                (0.68 * half_width, main_bottom),
                (half_width, center_z - 0.58 * half_height),
                (half_width, center_z + 0.58 * half_height),
                (0.68 * half_width, center_z + half_height),
                (-0.68 * half_width, center_z + half_height),
                (-half_width, center_z + 0.58 * half_height),
                (-half_width, center_z - 0.58 * half_height),
            )
        if size is None:
            size = len(profile)
        require(len(profile) == size, f"Sezioni incompatibili: {name}")
        vertices.extend((x, center_y + y, z) for y, z in profile)
    faces = [tuple(reversed(range(size)))]
    for ring in range(len(stations) - 1):
        a, b = ring * size, (ring + 1) * size
        for i in range(size):
            j = (i + 1) % size
            faces.append((a + i, a + j, b + j, b + i))
    last = (len(stations) - 1) * size
    faces.append(tuple(last + i for i in range(size)))
    return mesh_object(PREFIX + name, vertices, faces, collection, material)


def box(name, position, dimensions, collection, material):
    x, y, z = position
    dx, dy, dz = (v / 2 for v in dimensions)
    vertices = [(x + sx * dx, y + sy * dy, z + sz * dz)
                for sz in (-1, 1) for sy in (-1, 1) for sx in (-1, 1)]
    faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
             (1, 3, 7, 5), (3, 2, 6, 7), (2, 0, 4, 6)]
    return mesh_object(PREFIX + name, vertices, faces, collection, material)


def activate_collection(layer, target):
    if layer.collection == target:
        layer.exclude = False
        layer.hide_viewport = False
        bpy.context.view_layer.active_layer_collection = layer
        return True
    return any(activate_collection(child, target) for child in layer.children)


def render_ortho(scene, filename, position, target, scale, width, height):
    camera_data = bpy.data.cameras.new("TMP-deep_space_freighter-review_camera")
    camera = bpy.data.objects.new(camera_data.name, camera_data)
    scene.collection.objects.link(camera)
    camera.location = position
    camera.rotation_euler = (Vector(target) - Vector(position)).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = scale
    old_camera = scene.camera
    old_size = (scene.render.resolution_x, scene.render.resolution_y)
    old_path = scene.render.filepath
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.filepath = str(EXPORT_DIR / filename)
    bpy.ops.render.render(write_still=True)
    scene.camera = old_camera
    scene.render.resolution_x, scene.render.resolution_y = old_size
    scene.render.filepath = old_path
    bpy.data.objects.remove(camera, do_unlink=True)
    bpy.data.cameras.remove(camera_data)


require(Path(bpy.data.filepath).resolve() == BLEND_FILE.resolve(),
        f"Aprire il file di lavoro {BLEND_FILE}")
scene = bpy.data.scenes.get("main")
require(scene is not None, "Manca la scena main")
root = scene.collection.children.get("PR-deep_space_freighter")
require(root is not None, "Manca la collection radice")
geometry = root.children.get("deep_space_freighter-geometry")
references = scene.collection.children.get("deep_space_freighter-reference")
require(geometry is not None and references is not None, "Mancano Geometry o Reference")
require(len([o for o in references.objects if o.name.startswith("REF-")]) == 4,
        "Servono le quattro reference ortografiche")

# Preserve every existing P0 Blender object and update only its mesh geometry.
existing_geo_names = {obj.name for obj in bpy.data.objects if obj.name.startswith(PREFIX)}
require(existing_geo_names == EXPECTED_GEO_NAMES,
        f"Gli oggetti P0 non coincidono con quelli attesi: {existing_geo_names ^ EXPECTED_GEO_NAMES}")
for mat in list(bpy.data.materials):
    if mat.name.startswith("MAT-deep_space_freighter-") and mat.users == 0:
        bpy.data.materials.remove(mat)
material = bpy.data.materials.get("MAT-deep_space_freighter-blockout")
if material is None:
    material = bpy.data.materials.new("MAT-deep_space_freighter-blockout")
material.diffuse_color = (0.50, 0.55, 0.58, 1.0)

# Longitudinal sections remain separate editable masses. Total X extent is 21.
loft("forward_core", [
    (-10.5, 1.10, -0.22, 0.72), (-10.1, 1.38, -0.22, 0.99),
    (-9.1, 1.36, -0.27, 0.98), (-8.6, 1.10, -0.29, 0.74),
    (-3.1, 1.10, -0.29, 0.74), (-2.5, 1.22, -0.30, 0.79),
], geometry, material)
loft("forward_upper_mass", [
    (-9.65, 0.71, 0.61, 0.21), (-9.25, 0.95, 0.82, 0.45),
    (-8.8, 0.98, 0.82, 0.46), (-6.55, 0.98, 0.82, 0.46),
    (-6.05, 0.79, 0.66, 0.30), (-2.25, 0.77, 0.63, 0.27),
], geometry, material)

# An open pair of long rails reads as the forward lower collector in side,
# plan and bow views. The three short supports simply join it to the core.
for suffix, side in (("L", -1), ("R", 1)):
    loft(f"forward_lower_rail.{suffix}", [
        (-10.05, 0.17, -1.77, 0.29), (-9.6, 0.18, -1.78, 0.30),
        (-7.25, 0.17, -1.79, 0.27), (-6.95, 0.17, -1.79, 0.27),
        (-5.55, 0.27, -1.79, 0.37), (-2.80, 0.31, -1.79, 0.37),
        (-2.35, 0.20, -1.64, 0.23),
    ], geometry, material, center_y=side * 0.96)
    box(f"forward_lower_support.{suffix}", (-7.9, side * 0.96, -1.34),
        (0.28, 0.29, 0.88), geometry, material)

loft("central_transition", [
    (-2.7, 1.22, -0.31, 0.78), (-2.2, 1.66, -0.04, 1.28),
    (-0.7, 1.67, -0.04, 1.28), (-0.2, 1.70, -0.18, 1.23),
], geometry, material)
loft("central_aft_core", [
    (-0.35, 1.59, -0.35, 1.04, 1.02, -1.77),
    (0.35, 1.65, -0.24, 0.93, 1.04, -1.94),
    (1.15, 1.65, -0.16, 1.16, 1.05, -1.95),
    (6.3, 1.65, -0.16, 1.16, 1.05, -1.98),
    (7.3, 1.65, -0.16, 1.16, 1.05, -1.98),
    (8.1, 1.54, -0.28, 0.93, 0.98, -1.92),
], geometry, material)

for suffix, side in (("L", -1), ("R", 1)):
    loft(f"central_aft_lateral_mass.{suffix}", [
        (-0.30, 0.25, -0.54, 0.70), (0.20, 0.39, -0.60, 0.95),
        (5.40, 0.39, -0.60, 0.95), (5.95, 0.38, -0.62, 0.94),
        (6.55, 0.26, -0.58, 0.76),
    ], geometry, material, center_y=side * 1.63)

loft("upper_aft_mass", [
    (0.10, 0.72, 0.97, 0.11, 0.42, 0.64),
    (0.65, 0.94, 1.605, 0.505, 0.48, 0.66),
    (1.20, 0.98, 1.71, 0.61, 0.50, 0.65),
    (6.65, 0.98, 1.71, 0.61, 0.50, 0.65),
    (7.4, 0.97, 1.675, 0.575, 0.50, 0.65),
    (8.0, 0.72, 1.245, 0.165, 0.42, 0.65),
], geometry, material)
loft("tapered_stern", [
    (6.25, 1.61, -0.16, 1.16, 1.03, -2.00),
    (7.75, 1.58, -0.18, 1.03, 1.00, -1.94),
    (9.35, 1.36, -0.26, 0.80, 0.86, -1.60),
    (10.5, 0.98, -0.31, 0.63, 0.58, -1.02),
], geometry, material)

geometry.hide_viewport = False
geometry.hide_render = False
references.hide_viewport = False
references.hide_render = True
require(activate_collection(bpy.context.view_layer.layer_collection, references),
        "Non è stato possibile attivare Reference")
workspace = bpy.data.workspaces.get("Modelling")
if workspace and bpy.context.window:
    bpy.context.window.workspace = workspace
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            space = area.spaces.active
            space.overlay.show_extras = True
            space.region_3d.view_perspective = "ORTHO"
            space.region_3d.view_rotation = Quaternion((1, 0, 0), 1.57079632679)
            space.region_3d.view_location = Vector((0, 0, -0.1))
            space.region_3d.view_distance = 25.0

if root.asset_data:
    root.asset_data.description = "P0: blockout volumetrico dello scafo dalla reference ortografica v2."
root["source_reference"] = "references/deep-space-freighter-orthographic-reference-v2.png"
root["context_document"] = "deep-space-freighter.json"
root["iteration"] = "p0_orthographic_blockout"

scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = False
scene.display.shading.background_type = "WORLD"
scene.world.color = (0.10, 0.10, 0.10)
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_percentage = 100
EXPORT_DIR.mkdir(parents=True, exist_ok=True)
main_camera = bpy.data.objects.get("HLP-deep_space_freighter-camera")
if main_camera and main_camera.type == "CAMERA":
    main_camera.location = Vector((-6, -30, 10))
    main_camera.rotation_euler = (Vector((0, 0, -0.1)) - main_camera.location).to_track_quat("-Z", "Y").to_euler()
    main_camera.data.type = "PERSP"
    main_camera.data.lens = 52
    scene.camera = main_camera
scene.render.resolution_x, scene.render.resolution_y = 1500, 850
scene.render.filepath = str(EXPORT_DIR / "deep-space-freighter-p0-overview.png")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
bpy.ops.render.render(write_still=True)
render_ortho(scene, "deep-space-freighter-p0-side.png", (0, -50, -0.2),
             (0, 0, -0.2), 21.4, 1370, 390)
render_ortho(scene, "deep-space-freighter-p0-top.png", (0, 0, 50),
             (0, 0, 0), 21.4, 1370, 390)
render_ortho(scene, "deep-space-freighter-p0-bow-front.png", (-45, 0, 0),
             (0, 0, 0), 4.9, 800, 800)
render_ortho(scene, "deep-space-freighter-p0-aft-front.png", (45, 0, 0),
             (0, 0, 0), 5.3, 800, 800)
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
print(f"P0 completato: {len([o for o in geometry.objects if o.name.startswith(PREFIX)])} mesh editabili")
