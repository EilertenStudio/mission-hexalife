"""Riduce il file nave alla reference piana ed esporta OBJ/MTL."""

import json
from pathlib import Path
from shutil import copyfile

import bpy

ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "deep_space_freighter.blend"
REFERENCE_FILE = ASSET_DIR / "references" / "deep_space_freighter-orthographic_reference-v002.png"
EXPORT_DIR = ASSET_DIR / "exports"
SCENE_DIR = EXPORT_DIR / "deep_space_freighter-reference"
MESH_NAME = "GEO-deep_space_freighter-reference_image"
MATERIAL_NAME = "MAT-deep_space_freighter-reference_image"
OBJ_FILE = EXPORT_DIR / "deep_space_freighter-reference.obj"
TEXTURE_NAME = REFERENCE_FILE.name


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


require(Path(bpy.data.filepath).resolve() == BLEND_FILE.resolve(),
        f"Aprire prima il file Blender {BLEND_FILE}")
require(REFERENCE_FILE.is_file(), f"Reference mancante: {REFERENCE_FILE}")
scene = bpy.data.scenes.get("main")
require(scene is not None, "Manca la scena main")
root = scene.collection.children.get("LI-deep_space_freighter")
require(root is not None, "Manca la collection radice della nave")
geometry = root.children.get("deep_space_freighter-geometry")
require(geometry is not None, "Manca la collection geometry")

# The image plane is the only scene object; clear the old ship blockout,
# reference empties and render helpers.
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for mesh in list(bpy.data.meshes):
    if mesh.users == 0:
        bpy.data.meshes.remove(mesh)
for camera in list(bpy.data.cameras):
    if camera.users == 0:
        bpy.data.cameras.remove(camera)
for light in list(bpy.data.lights):
    if light.users == 0:
        bpy.data.lights.remove(light)
for material in list(bpy.data.materials):
    if material.users == 0:
        bpy.data.materials.remove(material)
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)

image = bpy.data.images.load(str(REFERENCE_FILE), check_existing=True)
image.pack()
image_width, image_height = image.size
plane_width = 20.0
plane_height = plane_width * image_height / image_width
mesh = bpy.data.meshes.new(MESH_NAME)
mesh.from_pydata(
    [(-plane_width / 2, 0, -plane_height / 2),
     ( plane_width / 2, 0, -plane_height / 2),
     ( plane_width / 2, 0,  plane_height / 2),
     (-plane_width / 2, 0,  plane_height / 2)],
    [],
    [(0, 1, 2, 3)],
)
uv_layer = mesh.uv_layers.new(name="UVMap")
uv_by_vertex = ((0, 0), (1, 0), (1, 1), (0, 1))
for loop in mesh.polygons[0].loop_indices:
    uv_layer.data[loop].uv = uv_by_vertex[mesh.loops[loop].vertex_index]
mesh.update()
plane = bpy.data.objects.new(MESH_NAME, mesh)
geometry.objects.link(plane)

material = bpy.data.materials.new(MATERIAL_NAME)
material.diffuse_color = (1, 1, 1, 1)
material.use_nodes = True
nodes = material.node_tree.nodes
nodes.clear()
output = nodes.new("ShaderNodeOutputMaterial")
principled = nodes.new("ShaderNodeBsdfPrincipled")
texture = nodes.new("ShaderNodeTexImage")
texture.image = image
texture.interpolation = "Linear"
material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Emission Color"])
principled.inputs["Emission Strength"].default_value = 1.0
material.node_tree.links.new(principled.outputs["BSDF"], output.inputs["Surface"])
mesh.materials.append(material)

plane.select_set(True)
bpy.context.view_layer.objects.active = plane
EXPORT_DIR.mkdir(parents=True, exist_ok=True)
SCENE_DIR.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.obj_export(
    filepath=str(OBJ_FILE),
    export_selected_objects=True,
    forward_axis="NEGATIVE_Z",
    up_axis="Y",
    apply_modifiers=True,
    export_uv=True,
    export_normals=False,
    export_materials=True,
    export_object_groups=True,
    export_triangulated_mesh=False,
)

mtl_file = OBJ_FILE.with_suffix(".mtl")
require(mtl_file.is_file(), f"Manca il materiale OBJ: {mtl_file}")
mtl_lines = [line for line in mtl_file.read_text().splitlines()
             if not line.lstrip().startswith("map_Kd ")]
mtl_lines.append(f"map_Kd {TEXTURE_NAME}")
mtl_file.write_text("\n".join(mtl_lines) + "\n")
copyfile(REFERENCE_FILE, EXPORT_DIR / TEXTURE_NAME)
for source in (OBJ_FILE, mtl_file, EXPORT_DIR / TEXTURE_NAME):
    copyfile(source, SCENE_DIR / source.name)

scene_state = {
    "id": "deep_space_freighter-reference",
    "name": "Reference nave",
    "format_version": 1,
    "coordinate_system": {"up": "y", "handedness": "right", "unit": "meter"},
    "state": {"geometry": "geometry.json", "camera": "camera.json"},
    "source_asset": "app/game/assets/ships/deep_space_freighter/deep_space_freighter.blend",
}
geometry_state = {
    "reference_image": {
        "id": "deep_space_freighter-reference",
        "mesh": OBJ_FILE.name,
        "material_library": mtl_file.name,
        "texture": TEXTURE_NAME,
        "width": plane_width,
        "height": plane_height,
        "image_width": image_width,
        "image_height": image_height,
    }
}
camera_state = {
    "projection": {"type": "perspective", "vertical_fov_degrees": 37,
                   "near": 0.1, "far": 100},
    "initial_view": {
        "mode": "orbit", "eye": [0, 0, 18], "target": [0, 0, 0],
        "up": [0, 1, 0], "orbit_distance_min": 10, "orbit_distance_max": 35,
    },
}
for name, value in (("scene.json", scene_state),
                    ("geometry.json", geometry_state),
                    ("camera.json", camera_state)):
    (SCENE_DIR / name).write_text(json.dumps(value, indent=2) + "\n")

# Save the Blender file with one textured plane and a top orthographic viewport.
for collection in (geometry, scene.collection.children.get("deep_space_freighter-reference")):
    if collection is not None:
        collection.hide_viewport = False
        collection.hide_render = False
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            space = area.spaces.active
            space.shading.type = "SOLID"
            space.shading.color_type = "TEXTURE"
            space.overlay.show_overlays = False
            space.region_3d.view_perspective = "ORTHO"
            space.region_3d.view_location = (0, 0, 0)
            space.region_3d.view_distance = 24
            space.region_3d.view_rotation = (0.70710678, 0.70710678, 0, 0)
if root.asset_data:
    root.asset_data.description = "Tavola ortografica piana, esportata in OBJ/MTL."
root["context_document"] = "deep_space_freighter.json"
root["iteration"] = "flat_reference_obj"
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))

geo_objects = [obj for obj in bpy.data.objects if obj.type == "MESH"]
require(len(geo_objects) == 1 and geo_objects[0].name == MESH_NAME,
        "Il file deve contenere solo il quad della reference")
obj_text = OBJ_FILE.read_text()
require("vt " in obj_text, "L'OBJ non contiene coordinate UV")
obj_vertices = [tuple(map(float, line.split()[1:4]))
                for line in obj_text.splitlines() if line.startswith("v ")]
require(len(obj_vertices) == 4 and all(abs(z) < 1e-6 for _, _, z in obj_vertices),
        "Il quad esportato deve restare frontale nel piano XY")
require(f"map_Kd {TEXTURE_NAME}" in mtl_file.read_text(),
        "Il MTL non dichiara la texture PNG")
print(f"Oggetto Blender: {MESH_NAME} ({plane_width:.2f} x {plane_height:.2f})")
print(f"OBJ/MTL/PNG copiati in {SCENE_DIR}")
