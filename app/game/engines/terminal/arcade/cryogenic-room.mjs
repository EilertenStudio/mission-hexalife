import { readFileSync } from 'node:fs';
import { decodePng } from 'ascii-arcade/engine/png';
import {
  mat4Multiply,
  mat4MulDir,
  mat4MulVec4,
  mat4RotX,
  mat4RotY,
  mat4RotZ,
  mat4Scale,
  mat4Translate,
  quad,
  sampleTexture,
  Scene,
  worldUniforms,
} from 'ascii-arcade/engine';

const sceneDir = new URL('../../../src/scenes/cryogenic-room/', import.meta.url);
const readJson = (name) => JSON.parse(readFileSync(new URL(name, sceneDir), 'utf8'));
const vec3 = ([x, y, z]) => ({ x, y, z });
const pixel = { r: 0, g: 0, b: 0, a: 1 };

const imageMaterial = {
  cull: 'none',
  blend: 'opaque',
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
    const color = sampleTexture(uniforms.texture, point.uv[0], point.uv[1]);
    pixel.r = color[0];
    pixel.g = color[1];
    pixel.b = color[2];
    pixel.a = color[3];
    return pixel;
  },
};

const alphaImageMaterial = { ...imageMaterial, blend: 'alpha' };

export function loadCryogenicRoom() {
  const manifest = readJson('scene.json');
  const imagePlanes = readJson(manifest.state.geometry).image_planes;
  const cameraState = readJson(manifest.state.camera);

  const scene = new Scene();
  const textures = new Map();
  for (const imagePlane of imagePlanes) {
    let texture = textures.get(imagePlane.image);
    if (!texture) {
      texture = decodePng(readFileSync(new URL(imagePlane.image, sceneDir)));
      textures.set(imagePlane.image, texture);
    }

    const [x, y, z] = imagePlane.position;
    const [rx, ry, rz] = imagePlane.rotation_degrees.map((degrees) => degrees * Math.PI / 180);
    const [width, height] = imagePlane.size;
    const rotation = mat4Multiply(
      mat4RotZ(rz),
      mat4Multiply(mat4RotY(ry), mat4RotX(rx)),
    );
    const model = mat4Multiply(
      mat4Translate(x, y, z),
      mat4Multiply(rotation, mat4Scale(width, height, 1)),
    );
    const material = imagePlane.material.blend === 'alpha' ? alphaImageMaterial : imageMaterial;
    scene.mesh(quad(), material, worldUniforms({ texture }), model);
  }

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
