import { readFileSync } from 'node:fs';
import { decodePng } from 'ascii-arcade/engine/png';
import {
  mat4Multiply,
  mat4MulVec4,
  mat4Scale,
  mat4Translate,
  quad,
  Scene,
  worldUniforms,
} from 'ascii-arcade/engine';

const sceneDir = new URL('../../../src/scenes/sandbox-room/', import.meta.url);
const readJson = (name) => JSON.parse(readFileSync(new URL(name, sceneDir), 'utf8'));
const clamp01 = (value) => Math.max(0, Math.min(1, value));
const pixel = { r: 0, g: 0, b: 0, a: 1 };

function sampleNearest(texture, u, v) {
  const x = Math.min(texture.width - 1, Math.floor(clamp01(u) * texture.width));
  const y = Math.min(texture.height - 1, Math.floor(clamp01(v) * texture.height));
  const index = (y * texture.width + x) * 4;
  pixel.r = texture.data[index];
  pixel.g = texture.data[index + 1];
  pixel.b = texture.data[index + 2];
  pixel.a = texture.data[index + 3] / 255;
  return pixel;
}

function imageMaterial(blend) {
  return {
    cull: 'none',
    blend,
    vertex(uniforms, vertex) {
      const position = vertex.position;
      return {
        clip: mat4MulVec4(uniforms.mvp, { ...position, w: 1 }),
        world: mat4MulVec4(uniforms.model, { ...position, w: 1 }),
        normal: vertex.normal,
        uv: vertex.uv,
        color: vertex.color,
        bary: { x: 0, y: 0, z: 0 },
      };
    },
    fragment(uniforms, point) {
      return sampleNearest(uniforms.texture, point.uv[0], point.uv[1]);
    },
  };
}

export function loadSandboxRoom() {
  const manifest = readJson('scene.json');
  const geometry = readJson(manifest.state.geometry);
  const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
  const pixelScale = 10 / frameHeight;
  const textures = new Map();
  const scene = new Scene();
  const opaqueMaterial = imageMaterial('opaque');
  const alphaMaterial = imageMaterial('alpha');

  function loadTexture(imagePath) {
    let texture = textures.get(imagePath);
    if (!texture) {
      texture = decodePng(readFileSync(new URL(imagePath, sceneDir)));
      textures.set(imagePath, texture);
    }
    return texture;
  }

  function addImage(imagePath, x, y, width, height, z, material) {
    const model = mat4Multiply(mat4Translate(x, y, z), mat4Scale(width, height, 1));
    scene.mesh(quad(), material, worldUniforms({ texture: loadTexture(imagePath) }), model);
  }

  const background = geometry.background;
  const backgroundTexture = loadTexture(background.image);
  const frameAspect = frameWidth / frameHeight;
  const imageAspect = backgroundTexture.width / backgroundTexture.height;
  let backgroundWidth = frameWidth * pixelScale;
  let backgroundHeight = frameHeight * pixelScale;
  if (background.fit === 'contain') {
    if (imageAspect > frameAspect) backgroundHeight = backgroundWidth / imageAspect;
    else backgroundWidth = backgroundHeight * imageAspect;
  } else if (background.fit !== 'cover') {
    throw new Error(`Adattamento sfondo non supportato: ${background.fit}`);
  } else if (imageAspect > frameAspect) {
    backgroundWidth = backgroundHeight * imageAspect;
  } else {
    backgroundHeight = backgroundWidth / imageAspect;
  }

  addImage(
    background.image,
    0,
    0,
    backgroundWidth,
    backgroundHeight,
    0,
    opaqueMaterial,
  );

  for (const object of geometry.objects) {
    if (object.type !== 'sprite') throw new Error(`Tipo di oggetto non supportato: ${object.type}`);
    const [xPixels, yPixels] = object.position_pixels;
    const [widthPixels, heightPixels] = object.size_pixels;
    const width = widthPixels * pixelScale;
    const height = heightPixels * pixelScale;
    let x = xPixels * pixelScale;
    let y = yPixels * pixelScale;

    if (object.anchor === 'bottom-center') y += height / 2;
    else if (object.anchor !== 'center') throw new Error(`Ancora non supportata: ${object.anchor}`);

    addImage(object.image, x, y, width, height, 0.02, alphaMaterial);
  }

  const distance = 14;
  const verticalFov = 2 * Math.atan((frameHeight * pixelScale / 2) / distance);
  return {
    scene,
    backgroundColor: manifest.rendering.background_color_rgb,
    camera: {
      eye: { x: 0, y: 0, z: distance },
      target: { x: 0, y: 0, z: 0 },
      minDistance: 2.5,
      maxDistance: 20,
      projection: {
        up: { x: 0, y: 1, z: 0 },
        fovy: verticalFov,
        near: 0.1,
        far: 40,
      },
    },
  };
}
