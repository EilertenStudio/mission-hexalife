"""Esporta la camera Blender nel file di stato letto da Arcade."""

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ASSET_DIR = Path(__file__).resolve().parent.parent
BLEND_FILE = ASSET_DIR / "set-cryogenic_room-modeling.blend"
CAMERA_FILE = ASSET_DIR.parents[2] / "src" / "scenes" / "cryogenic-room" / "camera.json"
ARCADE_ASPECT_RATIO = 16 / 9


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def to_arcade_vector(vector):
    """Converte Blender Z-up in Arcade Y-up, come l'export OBJ della scena."""
    return Vector((vector.x, vector.z, -vector.y))


def json_vector(vector):
    return [round(float(value), 6) for value in vector]


require(
    Path(bpy.data.filepath).resolve() == BLEND_FILE.resolve(),
    f"Aprire prima {BLEND_FILE}",
)
scene = bpy.context.scene
camera = scene.camera
require(
    camera is not None and camera.type == "CAMERA",
    "La scena non ha una camera attiva",
)
require(camera.data.type == "PERSP", "Arcade supporta solo una camera prospettica")
require(camera.data.lens > 0, "La focale della camera deve essere positiva")
require(
    abs(camera.data.shift_x) < 1e-8 and abs(camera.data.shift_y) < 1e-8,
    "Arcade non supporta lo spostamento decentrato della lente",
)

camera_state = json.loads(CAMERA_FILE.read_text(encoding="utf-8"))
view = camera_state["initial_view"]
previous_eye = Vector(view["eye"])
previous_target = Vector(view["target"])
target_distance = (previous_target - previous_eye).length
require(target_distance > 0, "La distanza orbitale iniziale deve essere positiva")

rotation = camera.matrix_world.to_quaternion()
eye = to_arcade_vector(camera.matrix_world.translation)
forward = to_arcade_vector(rotation @ Vector((0, 0, -1))).normalized()
up = to_arcade_vector(rotation @ Vector((0, 1, 0))).normalized()
target = eye + forward * target_distance

sensor_fit = camera.data.sensor_fit
if sensor_fit == "AUTO":
    sensor_fit = "HORIZONTAL" if ARCADE_ASPECT_RATIO >= 1 else "VERTICAL"
if sensor_fit == "HORIZONTAL":
    vertical_sensor_size = camera.data.sensor_width / ARCADE_ASPECT_RATIO
else:
    vertical_sensor_size = camera.data.sensor_height
vertical_fov = math.degrees(
    2 * math.atan(vertical_sensor_size / (2 * camera.data.lens))
)

projection = camera_state["projection"]
projection["type"] = "perspective"
projection["focal_length_mm"] = round(float(camera.data.lens), 6)
projection["vertical_fov_degrees_at_16_9"] = round(vertical_fov, 6)
view["eye"] = json_vector(eye)
view["target"] = json_vector(target)
view["up"] = json_vector(up)

CAMERA_FILE.write_text(
    json.dumps(camera_state, indent=2) + "\n",
    encoding="utf-8",
)
print(f"Camera Arcade aggiornata da {BLEND_FILE}")
print(f"eye={view['eye']} target={view['target']} up={view['up']}")
print(
    f"lens={projection['focal_length_mm']}mm "
    f"fovy={projection['vertical_fov_degrees_at_16_9']}°"
)
