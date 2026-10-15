import { readFileSync } from 'node:fs';
import {
  mat4MulDir,
  mat4MulVec4,
  parseObj,
  Scene,
  worldUniforms,
} from 'ascii-arcade/engine';

const sceneDir = new URL('../../../src/scenes/cryogenic-room/', import.meta.url);
const readJson = (name) => JSON.parse(readFileSync(new URL(name, sceneDir), 'utf8'));
const vec3 = ([x, y, z]) => ({ x, y, z });

function materialColors(mtlText) {
  const colors = new Map();
  let name;
  for (const line of mtlText.split(/\r?\n/)) {
    if (line.startsWith('newmtl ')) name = line.slice(7).trim();
    if (name && line.startsWith('Kd ')) {
      const [r, g, b] = line.slice(3).trim().split(/\s+/).map(Number);
      colors.set(name, { x: r * 255, y: g * 255, z: b * 255 });
    }
  }
  return colors;
}

function coloredObj(objText, mtlText) {
  const parsed = parseObj(objText);
  const colors = materialColors(mtlText);
  const triangleColors = [];
  let currentColor;
  for (const line of objText.split(/\r?\n/)) {
    if (line.startsWith('usemtl ')) {
      currentColor = colors.get(line.slice(7).trim());
      if (!currentColor) throw new Error(`Materiale OBJ sconosciuto: ${line}`);
    }
    if (line.startsWith('f ')) {
      if (!currentColor) throw new Error('Faccia OBJ senza materiale');
      const vertices = line.trim().split(/\s+/).length - 1;
      for (let i = 2; i < vertices; i++) triangleColors.push(currentColor);
    }
  }
  if (triangleColors.length * 3 !== parsed.indices.length) {
    throw new Error('Triangolazione OBJ non coerente con i materiali');
  }
  const vertices = parsed.indices.map((index, i) => ({
    ...parsed.vertices[index],
    color: triangleColors[Math.floor(i / 3)],
  }));
  return { vertices, indices: vertices.map((_, i) => i) };
}

const pixel = { r: 0, g: 0, b: 0, a: 1 };
const matteMaterial = {
  cull: 'none',
  vertex(uniforms, vertex) {
    const position = vertex.position;
    const world = mat4MulVec4(uniforms.model, { ...position, w: 1 });
    return {
      clip: mat4MulVec4(uniforms.mvp, { ...position, w: 1 }),
      world: { x: world.x, y: world.y, z: world.z },
      normal: mat4MulDir(uniforms.model, vertex.normal),
      uv: vertex.uv,
      color: vertex.color,
      bary: { x: 0, y: 0, z: 0 },
    };
  },
  fragment(uniforms, point) {
    const length = Math.hypot(point.normal.x, point.normal.y, point.normal.z) || 1;
    let brightness = uniforms.ambient;
    for (const light of uniforms.lights) {
      const dx = point.world.x - light.position.x;
      const dy = point.world.y - light.position.y;
      const dz = point.world.z - light.position.z;
      const distance = Math.hypot(dx, dy, dz) || 1;
      const diffuse = Math.max(0, -(point.normal.x * dx + point.normal.y * dy
        + point.normal.z * dz) / (length * distance));
      brightness += diffuse * light.intensity * 0.24
        / (1 + 0.16 * distance + 0.035 * distance * distance);
    }
    pixel.r = point.color.x * brightness;
    pixel.g = point.color.y * brightness;
    pixel.b = point.color.z * brightness;
    return pixel;
  },
};

export function loadCryogenicRoom() {
  const manifest = readJson('scene.json');
  const geometry = readJson(manifest.state.geometry).room;
  const lighting = readJson(manifest.state.lighting);
  const cameraState = readJson(manifest.state.camera);
  const objText = readFileSync(new URL(geometry.mesh, sceneDir), 'utf8');
  const mtlText = readFileSync(new URL(geometry.material_library, sceneDir), 'utf8');

  const scene = new Scene();
  const lights = lighting.lights.map((light) => ({
    position: vec3(light.position),
    // Arcade non ha luci area: ogni sorgente diventa un punto neutro.
    intensity: light.type === 'area' ? light.energy_watts / 50 : light.energy,
  }));
  scene.mesh(coloredObj(objText, mtlText), matteMaterial, worldUniforms({
    lights,
    ambient: 0.55,
  }));

  const view = cameraState.initial_view;
  const projection = cameraState.projection;
  return {
    scene,
    camera: {
      eye: vec3(view.eye),
      target: vec3(view.target),
      minDistance: view.orbit_distance_min,
      maxDistance: view.orbit_distance_max,
      projection: {
        up: vec3(view.up),
        fovy: projection.vertical_fov_degrees_at_16_9 * Math.PI / 180,
        near: projection.near,
        far: projection.far,
      },
    },
  };
}
