import { readFileSync } from 'node:fs';
import { decodePng } from 'ascii-arcade/engine/png';

const sceneDir = new URL('../../../src/scenes/cryogenic-room/', import.meta.url);
const readJson = (name) => JSON.parse(readFileSync(new URL(name, sceneDir), 'utf8'));

export function loadCryogenicRoom() {
  const manifest = readJson('scene.json');
  const geometry = readJson(manifest.state.geometry);
  const menus = readJson(manifest.state.menus);
  const background = geometry.background;
  if (background.sampling !== 'nearest') {
    throw new Error(`Campionamento non supportato: ${background.sampling}`);
  }

  const texture = decodePng(readFileSync(new URL(background.image, sceneDir)));
  const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
  const interactiveElements = background.interactive_elements ?? [];
  for (const element of interactiveElements) {
    if (!Array.isArray(element.hit_regions) || element.hit_regions.some((region) =>
      !Array.isArray(region) || region.length !== 4 || region.some((value) => !Number.isFinite(value)),
    )) {
      throw new Error(`Aree cliccabili non valide per l'elemento: ${element.id}`);
    }
  }

  return {
    texture,
    frameWidth,
    frameHeight,
    fit: background.fit,
    color: manifest.rendering.background_color_rgb,
    interactiveElements,
    menus,
  };
}
