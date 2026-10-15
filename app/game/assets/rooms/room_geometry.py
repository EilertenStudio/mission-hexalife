"""Geometria, materiali e illuminazione condivisi dai set per interni."""

import bpy
from mathutils import Vector


WIDTH = 10.0
DEPTH = 6.0
HEIGHT = 3.2
THICKNESS = 0.16


def aim_at(obj, point):
    direction = Vector(point) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def matte_material(namespace, name, gray):
    material = bpy.data.materials.new(f"{namespace}-matte_{name}")
    material.diffuse_color = (gray, gray, gray, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (gray, gray, gray, 1.0)
    shader.inputs["Metallic"].default_value = 0.0
    shader.inputs["Roughness"].default_value = 0.85
    return material


def box(collection, namespace, part, dimensions, center, material):
    name = f"GEO-{namespace}-{part}"
    half_x, half_y, half_z = (dimension / 2 for dimension in dimensions)
    vertices = [
        (-half_x, -half_y, -half_z),
        (+half_x, -half_y, -half_z),
        (+half_x, +half_y, -half_z),
        (-half_x, +half_y, -half_z),
        (-half_x, -half_y, +half_z),
        (+half_x, -half_y, +half_z),
        (+half_x, +half_y, +half_z),
        (-half_x, +half_y, +half_z),
    ]
    faces = [
        (3, 2, 1, 0),
        (4, 5, 6, 7),
        (0, 1, 5, 4),
        (2, 3, 7, 6),
        (1, 2, 6, 5),
        (3, 0, 4, 7),
    ]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = center
    mesh.materials.append(material)
    return obj


def area_light(collection, namespace, name, location, target, energy, size):
    data = bpy.data.lights.new(f"{namespace}-{name}", "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(f"LGT-{namespace}-{name}", data)
    collection.objects.link(obj)
    obj.location = location
    aim_at(obj, target)
    return obj


def clear_geometry(collection):
    for obj in list(collection.objects):
        data = obj.data if obj.type == "MESH" else None
        bpy.data.objects.remove(obj, do_unlink=True)
        if data is not None and data.users == 0:
            bpy.data.meshes.remove(data)
    for material in list(bpy.data.materials):
        if material.users == 0:
            bpy.data.materials.remove(material)


def rebuild_room(scene, geometry, render, namespace):
    """Ricrea la stanza e le luci con un namespace Blender Studio."""
    camera = next((obj for obj in render.objects if obj.type == "CAMERA"), None)
    sun = next(
        (
            obj
            for obj in render.objects
            if obj.type == "LIGHT" and obj.data.type == "SUN"
        ),
        None,
    )
    if camera is None:
        raise RuntimeError("Manca la camera nella collection Render")
    if sun is None:
        raise RuntimeError("Manca la luce Sun nella collection Render")

    clear_geometry(geometry)
    for obj in list(render.objects):
        if obj.type == "LIGHT" and obj != sun:
            data = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if data.users == 0:
                bpy.data.lights.remove(data)

    camera.name = f"HLP-{namespace}-camera"
    camera.data.name = f"{namespace}-camera"
    sun.name = f"LGT-{namespace}-sun"
    sun.data.name = f"{namespace}-sun"
    scene.camera = camera

    floor_material = matte_material(namespace, "floor", 0.48)
    wall_material = matte_material(namespace, "wall", 0.70)
    ceiling_material = matte_material(namespace, "ceiling", 0.78)

    box(
        geometry,
        namespace,
        "floor",
        (WIDTH + 2 * THICKNESS, DEPTH + 2 * THICKNESS, THICKNESS),
        (0, DEPTH / 2, -THICKNESS / 2),
        floor_material,
    )
    box(
        geometry,
        namespace,
        "back_wall",
        (WIDTH + 2 * THICKNESS, THICKNESS, HEIGHT),
        (0, DEPTH + THICKNESS / 2, HEIGHT / 2),
        wall_material,
    )
    box(
        geometry,
        namespace,
        "left_wall",
        (THICKNESS, DEPTH, HEIGHT),
        (-WIDTH / 2 - THICKNESS / 2, DEPTH / 2, HEIGHT / 2),
        wall_material,
    )
    box(
        geometry,
        namespace,
        "right_wall",
        (THICKNESS, DEPTH, HEIGHT),
        (+WIDTH / 2 + THICKNESS / 2, DEPTH / 2, HEIGHT / 2),
        wall_material,
    )
    box(
        geometry,
        namespace,
        "ceiling",
        (WIDTH + 2 * THICKNESS, DEPTH + 2 * THICKNESS, THICKNESS),
        (0, DEPTH / 2, HEIGHT + THICKNESS / 2),
        ceiling_material,
    )

    sun.location = (-3, -5, 6)
    aim_at(sun, (0, DEPTH / 2, 1.2))
    sun.data.energy = 0.45
    sun.data.angle = 0.45
    sun.data.color = (1.0, 1.0, 1.0)
    area_light(
        render,
        namespace,
        "area_key",
        (-2.7, -1.0, 2.5),
        (0, 3.0, 1.2),
        220,
        5.0,
    )
    area_light(
        render,
        namespace,
        "area_fill",
        (2.7, -1.2, 1.5),
        (0, 3.5, 2.2),
        140,
        5.0,
    )

    world = scene.world
    if world is None:
        world = bpy.data.worlds.new(f"{namespace}-world")
        scene.world = world
    world.name = f"{namespace}-world"
    world.use_nodes = True
    background = next(
        (node for node in world.node_tree.nodes if node.type == "BACKGROUND"), None
    )
    if background is None:
        background = world.node_tree.nodes.new("ShaderNodeBackground")
    background.inputs["Color"].default_value = (0.12, 0.12, 0.12, 1.0)
    background.inputs["Strength"].default_value = 0.4

    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False
