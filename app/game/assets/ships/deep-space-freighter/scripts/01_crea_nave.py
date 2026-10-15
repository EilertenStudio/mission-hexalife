"""Materializza il primo blocco 3D esterno della deep-space freighter."""

from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


ASSET_DIR = Path(__file__).resolve().parent.parent
BASE_FILE = ASSET_DIR.parents[1] / "template.blend"
BLEND_FILE = ASSET_DIR / "prop-deep_space_freighter-modeling.blend"
PREVIEW_FILE = ASSET_DIR / "exports" / "deep-space-freighter-hull-v1.png"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def relink_collection(collection, name):
    require(collection is not None, f"Collection mancante: {name}")
    collection.name = name
    return collection


def clear_collection(collection):
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def set_normals(mesh):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def make_material(name, color, metallic=0.18, roughness=0.58):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return material


def add_bevel(obj, width=0.075):
    bevel = obj.modifiers.new(
        "MOD-deep_space_freighter-edge_bevel", "BEVEL"
    )
    bevel.width = width
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    bevel.harden_normals = True

    normals = obj.modifiers.new(
        "MOD-deep_space_freighter-weighted_normals", "WEIGHTED_NORMAL"
    )
    normals.keep_sharp = True
    normals.weight = 40


def create_loft(name, stations, collection, material, bevel=0.07):
    """Create a closed, angular hull volume along the ship's X axis.

    Each station is (x, half_width_y, center_z, half_height_z).
    """
    vertices = []
    for x, half_width, center_z, half_height in stations:
        profile = (
            (-0.70 * half_width, center_z - half_height),
            (0.70 * half_width, center_z - half_height),
            (half_width, center_z - 0.58 * half_height),
            (half_width, center_z + 0.58 * half_height),
            (0.70 * half_width, center_z + half_height),
            (-0.70 * half_width, center_z + half_height),
            (-half_width, center_z + 0.58 * half_height),
            (-half_width, center_z - 0.58 * half_height),
        )
        vertices.extend((x, y, z) for y, z in profile)

    ring_size = 8
    faces = [tuple(reversed(range(ring_size)))]
    for ring in range(len(stations) - 1):
        current = ring * ring_size
        following = (ring + 1) * ring_size
        for edge in range(ring_size):
            next_edge = (edge + 1) % ring_size
            faces.append(
                (
                    current + edge,
                    current + next_edge,
                    following + next_edge,
                    following + edge,
                )
            )
    final = (len(stations) - 1) * ring_size
    faces.append(tuple(final + edge for edge in range(ring_size)))

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    set_normals(mesh)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    mesh.materials.append(material)
    add_bevel(obj, bevel)
    return obj


def create_box(name, location, dimensions, collection, material, bevel=0.07):
    half_x, half_y, half_z = (dimension / 2 for dimension in dimensions)
    vertices = [
        (-half_x, -half_y, -half_z),
        (half_x, -half_y, -half_z),
        (half_x, half_y, -half_z),
        (-half_x, half_y, -half_z),
        (-half_x, -half_y, half_z),
        (half_x, -half_y, half_z),
        (half_x, half_y, half_z),
        (-half_x, half_y, half_z),
    ]
    faces = (
        (0, 3, 2, 1),
        (4, 5, 6, 7),
        (0, 1, 5, 4),
        (1, 2, 6, 5),
        (2, 3, 7, 6),
        (3, 0, 4, 7),
    )
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    set_normals(mesh)
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    collection.objects.link(obj)
    mesh.materials.append(material)
    add_bevel(obj, bevel)
    return obj


def point_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def create_area_light(name, location, target, power, size, collection):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = location
    point_at(obj, target)
    collection.objects.link(obj)
    return obj


require(
    Path(bpy.data.filepath).resolve() == BASE_FILE.resolve(),
    f"Aprire prima il template generico {BASE_FILE}",
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
asset = relink_collection(asset_roots[0], "PR-deep_space_freighter")
geometry = relink_collection(
    asset.children.get("Geometry"), "deep_space_freighter-geometry"
)
rigging = relink_collection(
    asset.children.get("Rigging"), "deep_space_freighter-rigging"
)
reference = relink_collection(
    scene.collection.children.get("Reference"),
    "deep_space_freighter-reference",
)
render = relink_collection(
    scene.collection.children.get("Render"), "deep_space_freighter-render"
)

for collection in (geometry, rigging, reference, render):
    clear_collection(collection)

asset.asset_data.description = (
    "Scafo esterno geometrico della deep-space freighter; senza interni, "
    "scanner o ugelli."
)
asset["source_prompt"] = "PROMPT.md"
asset["source_reference"] = "references/deep-space-freighter-sketch-v8.png"
asset["iteration"] = "exterior_hull_blockout_v1"

outer = make_material(
    "MAT-deep_space_freighter-hull_outer", (0.40, 0.45, 0.48), 0.22, 0.56
)
armor = make_material(
    "MAT-deep_space_freighter-hull_armor", (0.49, 0.53, 0.55), 0.20, 0.60
)
secondary = make_material(
    "MAT-deep_space_freighter-hull_secondary", (0.32, 0.37, 0.40), 0.16, 0.62
)

# Main body. The ship's long axis is X: bow at -X, aft at +X.
create_loft(
    "GEO-deep_space_freighter-main_hull",
    (
        (-10.4, 0.65, 0.00, 0.58),
        (-9.5, 1.45, 0.00, 1.02),
        (-7.0, 2.25, 0.00, 1.35),
        (-2.5, 2.75, 0.00, 1.58),
        (3.5, 3.00, 0.00, 1.58),
        (7.0, 2.78, -0.02, 1.40),
        (9.4, 2.28, -0.02, 1.12),
        (10.5, 1.25, -0.02, 0.66),
    ),
    geometry,
    outer,
    0.11,
)

# Closed upper forward armor casing, following the long mining spine silhouette.
create_loft(
    "GEO-deep_space_freighter-forward_armor_casing",
    (
        (-9.65, 0.72, 0.68, 0.52),
        (-8.9, 1.40, 0.78, 0.78),
        (-6.2, 1.58, 0.80, 0.77),
        (-2.0, 1.63, 0.76, 0.70),
        (0.8, 1.45, 0.65, 0.56),
        (1.5, 1.10, 0.55, 0.40),
    ),
    geometry,
    armor,
    0.09,
)

# Lower forward collector cradle: exterior rails only, with no emitter or internals.
create_box(
    "GEO-deep_space_freighter-collector_cradle_port",
    (-7.35, -1.22, -1.27),
    (4.70, 0.34, 0.38),
    geometry,
    secondary,
    0.09,
)
create_box(
    "GEO-deep_space_freighter-collector_cradle_starboard",
    (-7.35, 1.22, -1.27),
    (4.70, 0.34, 0.38),
    geometry,
    secondary,
    0.09,
)
create_box(
    "GEO-deep_space_freighter-collector_cradle_forward_crossmember",
    (-9.58, 0.0, -1.27),
    (0.34, 2.75, 0.38),
    geometry,
    armor,
    0.08,
)

# One-piece exterior fairings represent the cooler, compressor, filter and router.
create_box(
    "GEO-deep_space_freighter-cooler_outer_fairing",
    (-2.55, -2.25, -0.94),
    (6.00, 0.42, 0.48),
    geometry,
    armor,
    0.10,
)
create_box(
    "GEO-deep_space_freighter-compressor_outer_fairing",
    (-3.30, -2.32, -1.39),
    (2.95, 0.38, 0.62),
    geometry,
    outer,
    0.09,
)
create_box(
    "GEO-deep_space_freighter-filter_outer_fairing",
    (-0.45, -2.34, -1.37),
    (2.45, 0.40, 0.58),
    geometry,
    armor,
    0.09,
)
create_box(
    "GEO-deep_space_freighter-router_outer_fairing",
    (1.72, -2.58, -0.92),
    (2.25, 0.48, 1.12),
    geometry,
    secondary,
    0.11,
)

# Opaque, closed storage shell and simple raised exterior cargo-bay volumes.
create_box(
    "GEO-deep_space_freighter-storage_shell_09",
    (1.18, -2.79, 0.68),
    (2.32, 0.38, 1.22),
    geometry,
    armor,
    0.10,
)
storage_columns = (2.80, 4.18, 5.56)
storage_rows = (0.72, -0.16)
storage_ids = ((12, 13, 14), (15, 16, 17))
for z, row in zip(storage_rows, storage_ids):
    for x, storage_id in zip(storage_columns, row):
        create_box(
            f"GEO-deep_space_freighter-storage_shell_{storage_id:02d}",
            (x, -2.86, z),
            (1.16, 0.32, 0.72),
            geometry,
            outer if storage_id % 2 else armor,
            0.075,
        )
create_box(
    "GEO-deep_space_freighter-storage_shell_11",
    (1.70, -2.80, -0.22),
    (0.92, 0.32, 0.64),
    geometry,
    secondary,
    0.075,
)
create_box(
    "GEO-deep_space_freighter-storage_upper_spine_21",
    (4.55, -2.42, 1.43),
    (5.30, 0.38, 0.40),
    geometry,
    secondary,
    0.08,
)

# Sealed crew hull; no glazing, doors or internal structures.
create_loft(
    "GEO-deep_space_freighter-crew_outer_shell",
    (
        (3.45, 1.72, 1.39, 0.50),
        (4.10, 2.12, 1.76, 0.82),
        (5.20, 2.20, 1.82, 0.88),
        (7.75, 2.10, 1.70, 0.78),
        (9.05, 1.75, 1.40, 0.48),
    ),
    geometry,
    armor,
    0.09,
)

# Shielded reactor casing as a closed lower-aft exterior volume.
create_loft(
    "GEO-deep_space_freighter-reactor_outer_casing",
    (
        (2.45, 2.10, -1.37, 0.38),
        (3.10, 2.58, -1.52, 0.53),
        (7.55, 2.55, -1.52, 0.53),
        (8.45, 2.10, -1.35, 0.38),
    ),
    geometry,
    secondary,
    0.09,
)

# Neutral studio lighting and a three-quarter side camera for inspection.
camera_data = bpy.data.cameras.new("deep_space_freighter-camera")
camera = bpy.data.objects.new("HLP-deep_space_freighter-camera", camera_data)
camera.location = (-4.0, -34.0, 11.0)
point_at(camera, (0.0, 0.0, 0.0))
camera_data.lens = 50.0
camera_data.clip_start = 0.1
camera_data.clip_end = 250.0
render.objects.link(camera)
scene.camera = camera

create_area_light(
    "LGT-deep_space_freighter-key",
    (-8.0, -14.0, 16.0),
    (0.0, 0.0, 0.0),
    2300.0,
    10.0,
    render,
)
create_area_light(
    "LGT-deep_space_freighter-fill",
    (2.0, 9.0, 10.0),
    (0.0, 0.0, 0.0),
    1700.0,
    9.0,
    render,
)
create_area_light(
    "LGT-deep_space_freighter-rim",
    (10.0, -1.0, -5.0),
    (0.0, 0.0, 0.0),
    950.0,
    7.0,
    render,
)

world = bpy.data.worlds.get("Main") or bpy.data.worlds.get("World")
if world is None:
    world = bpy.data.worlds.new("deep_space_freighter-world")
else:
    world.name = "deep_space_freighter-world"
world.node_tree.nodes["Background"].inputs["Color"].default_value = (
    0.018,
    0.026,
    0.040,
    1.0,
)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.42
scene.world = world

scene.render.engine = "BLENDER_WORKBENCH"
shading = scene.display.shading
shading.light = "STUDIO"
shading.color_type = "MATERIAL"
shading.background_type = "WORLD"
shading.show_shadows = True
shading.show_cavity = True
shading.cavity_type = "BOTH"
shading.curvature_ridge_factor = 1.25
shading.curvature_valley_factor = 1.1
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.render.filepath = str(PREVIEW_FILE)
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_percentage = 100
scene.render.filepath = str(PREVIEW_FILE)
scene.view_settings.view_transform = "AgX"
scene.render.image_settings.color_depth = "8"
scene.camera.data.dof.use_dof = False
scene.unit_settings.system = "NONE"

workspace = bpy.data.workspaces.get("Modelling")
require(workspace is not None, "Manca il workspace Modelling")
if bpy.context.window is not None:
    bpy.context.window.workspace = workspace

for obj in geometry.objects:
    require(obj.type == "MESH", f"Lo scafo contiene un oggetto inatteso: {obj.name}")
    require("scanner" not in obj.name, "Lo scanner deve restare escluso")
    require("nozzle" not in obj.name and "engine" not in obj.name, "Gli ugelli devono restare esclusi")
require(
    not any("scanner" in obj.name.lower() for obj in bpy.data.objects),
    "Non devono esserci oggetti dello scanner",
)
require(
    not any(
        "nozzle" in obj.name.lower() or "engine" in obj.name.lower()
        for obj in bpy.data.objects
    ),
    "Non devono esserci ugelli o oggetti dei motori",
)
require(scene.camera == camera, "La scena deve usare la camera di ispezione")

world_bounds = [
    obj.matrix_world @ Vector(corner)
    for obj in geometry.objects
    for corner in obj.bound_box
]
minimum = Vector(tuple(min(point[axis] for point in world_bounds) for axis in range(3)))
maximum = Vector(tuple(max(point[axis] for point in world_bounds) for axis in range(3)))
dimensions = maximum - minimum
require(dimensions.x > 20.0, "La lunghezza dello scafo non corrisponde allo state")

PREVIEW_FILE.parent.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
bpy.ops.render.render(write_still=True)

print(f"Modello esterno salvato: {BLEND_FILE}")
print(f"Anteprima salvata: {PREVIEW_FILE}")
print(
    "Ingombro approssimativo dello scafo: "
    f"{dimensions.x:.1f} x {dimensions.y:.1f} x {dimensions.z:.1f} unità"
)
