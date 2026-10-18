import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { RenderTarget, toHalfBlock, toShapeGlyph } from 'ascii-arcade/engine';
import { decodePng } from 'ascii-arcade/engine/png';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { copyFrameToClipboard } from './frame-clipboard.mjs';
import { createSystemOverlay } from './system-overlay.mjs';

const sceneDir = new URL('../../assets/scenes/test-gameplay-action-adventure/sources/', import.meta.url);
const readJson = (path) => JSON.parse(readFileSync(new URL(path, sceneDir), 'utf8'));
const manifest = readJson('description.json');
const map = readJson(manifest.state.map).map;
const interior = readJson(manifest.state.interior).room;
const grid = readJson(manifest.state.grid);
const character = readJson(manifest.state.character).player;
character.animations = JSON.parse(readFileSync(new URL(character.animations_source, sceneDir), 'utf8')).animations;
const controls = readJson(manifest.state.controls).movement;
const camera = readJson(manifest.state.camera);
const menus = readJson(manifest.state.menus);
const debugSettings = menus.menus.system_debug.items;
const spriteSheet = decodePng(readFileSync(new URL(character.sprite_sheet, sceneDir)));
const mapTexture = decodePng(readFileSync(new URL(map.raster_asset, sceneDir)));
const interiorTexture = decodePng(readFileSync(new URL(interior.raster_asset, sceneDir)));

const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
const [columns, rows] = [grid.grid.columns, grid.grid.rows];
const [tileWidth, tileHeight] = grid.grid.metatile_size_pixels;
const [mapWidth, mapHeight] = map.size_pixels;
const [spriteWidth, spriteHeight] = character.frame_size_pixels;
const [minX, minY, maxX, maxY] = camera.projection.frame_bounds;
if (columns * tileWidth !== frameWidth || rows * tileHeight !== frameHeight ||
  mapWidth !== frameWidth || mapHeight !== frameHeight ||
  mapTexture.width !== mapWidth || mapTexture.height !== mapHeight ||
  interior.size_pixels[0] !== frameWidth || interior.size_pixels[1] !== frameHeight ||
  interiorTexture.width !== frameWidth || interiorTexture.height !== frameHeight ||
  maxX - minX !== frameWidth || maxY - minY !== frameHeight) {
  throw new Error('Mappe, griglia e limiti della camera devono coincidere con il framebuffer.');
}

const directionRows = character.direction_rows_top_to_bottom;
const directions = {
  down: { dx: 0, dy: -1, row: directionRows.indexOf('down') },
  left: { dx: -1, dy: 0, row: directionRows.indexOf('left') },
  top: { dx: 0, dy: 1, row: directionRows.indexOf('top') },
  right: { dx: 1, dy: 0, row: directionRows.indexOf('right') },
};
const directionByKey = new Map(controls.keys.map(({ key, direction }) => [key.toLowerCase(), direction]));
const blockedCells = {
  outdoor: new Set((grid.grid.blocked_cells_bottom_left || [])
    .map(([x, y]) => `${x},${y}`)),
  interior: new Set((interior.grid.blocked_cells_bottom_left || [])
    .map(([x, y]) => `${x},${y}`)),
};
const background = manifest.rendering.background_color_rgb;
let currentArea = 'outdoor';
let playerTile = [...character.starting_tile];
let playerDirection = 'down';
let movement = null;
let target = new RenderTarget(1, 1);
let viewport = { left: 0, top: 0, scale: 1 };
let running = true;
let paused = false;
let pausedAt = 0;
let lastPicture = '';
let frozenPicture = '';
let clipboardMessage = '';
let clipboardMessageUntil = 0;
let frameTimer;
let targetFps = debugSettings.find(({ id }) => id === 'target_fps').default;
let renderMode = debugSettings.find(({ id }) => id === 'render_mode').default;
let frameCount = 0;
let measuredFps = 0;
let fpsWindowStart = performance.now();

function setFrameRate() {
  clearInterval(frameTimer);
  frameTimer = paused ? undefined : setInterval(draw, 1000 / targetFps);
}

function adjustTargetFps(amount) {
  const setting = debugSettings.find(({ id }) => id === 'target_fps');
  targetFps = Math.max(setting.minimum, Math.min(setting.maximum, targetFps + amount));
  setFrameRate();
}

function cycleRenderMode() {
  renderMode = renderMode === 'half-block' ? 'shape-glyph' : 'half-block';
}

function toggleFramePause() {
  const now = performance.now();
  if (!paused) {
    paused = true;
    pausedAt = now;
    frozenPicture = lastPicture;
    clearInterval(frameTimer);
    frameTimer = undefined;
  } else {
    if (movement) movement.startedAt += now - pausedAt;
    paused = false;
    frozenPicture = '';
    frameCount = 0;
    measuredFps = 0;
    fpsWindowStart = now;
    setFrameRate();
  }
}

function copyCurrentFrame() {
  const result = copyFrameToClipboard(target, {
    left: viewport.left,
    top: viewport.top,
    width: frameWidth * viewport.scale,
    height: frameHeight * viewport.scale,
    outputWidth: frameWidth,
    outputHeight: frameHeight,
  });
  clipboardMessage = result.ok
    ? 'FRAME COPIATO ' + result.width + 'x' + result.height + ' PNG'
    : 'COPIA FALLITA: ' + result.reason;
  clipboardMessageUntil = performance.now() + 3000;
}

function drawMap() {
  const texture = currentArea === 'outdoor' ? mapTexture : interiorTexture;
  const destinationWidth = Math.max(1, Math.round(mapWidth * viewport.scale));
  const destinationHeight = Math.max(1, Math.round(mapHeight * viewport.scale));
  const left = Math.round(viewport.left);
  const top = Math.round(viewport.top);
  for (let dy = 0; dy < destinationHeight; dy++) {
    const sy = Math.min(mapHeight - 1, Math.floor(dy / viewport.scale));
    const y = top + dy;
    if (y < 0 || y >= target.height) continue;
    for (let dx = 0; dx < destinationWidth; dx++) {
      const x = left + dx;
      if (x < 0 || x >= target.width) continue;
      const sx = Math.min(mapWidth - 1, Math.floor(dx / viewport.scale));
      const sourceIndex = (sy * mapWidth + sx) * 4;
      const alpha = texture.data[sourceIndex + 3] / 255;
      if (alpha <= 0) continue;
      const targetIndex = (y * target.width + x) * 3;
      const inverseAlpha = 1 - alpha;
      target.color[targetIndex] = texture.data[sourceIndex] * alpha +
        target.color[targetIndex] * inverseAlpha;
      target.color[targetIndex + 1] = texture.data[sourceIndex + 1] * alpha +
        target.color[targetIndex + 1] * inverseAlpha;
      target.color[targetIndex + 2] = texture.data[sourceIndex + 2] * alpha +
        target.color[targetIndex + 2] * inverseAlpha;
    }
  }
}

function movementProgress(now) {
  if (!movement) return 1;
  return Math.max(0, Math.min(1, (now - movement.startedAt) / movement.duration));
}

function drawPlayer(now) {
  if (movement && movementProgress(now) >= 1) {
    playerTile = [...movement.to];
    movement = null;
  }
  const progress = movement ? movementProgress(now) : 0;
  const [tileX, tileY] = movement
    ? [
        movement.from[0] + (movement.to[0] - movement.from[0]) * progress,
        movement.from[1] + (movement.to[1] - movement.from[1]) * progress,
      ]
    : playerTile;

  const row = directions[playerDirection].row;
  const animation = movement ? character.animations.walk : character.animations.idle;
  const frameOffset = movement
    ? Math.min(animation.frame_count_columns - 1, Math.floor(progress * animation.frame_count_columns))
    : 0;
  const column = animation.start_column - 1 + frameOffset;
  const sourceLeft = column * spriteWidth;
  const sourceTop = row * spriteHeight;
  const left = Math.round(viewport.left +
    (tileX * tileWidth + (tileWidth - spriteWidth) / 2) * viewport.scale);
  const top = Math.round(viewport.top +
    (frameHeight - (tileY * tileHeight + (tileHeight + spriteHeight) / 2)) * viewport.scale);
  const destWidth = Math.max(1, Math.round(spriteWidth * viewport.scale));
  const destHeight = Math.max(1, Math.round(spriteHeight * viewport.scale));

  for (let dy = 0; dy < destHeight; dy++) {
    const sy = sourceTop + Math.min(spriteHeight - 1, Math.floor(dy * spriteHeight / destHeight));
    for (let dx = 0; dx < destWidth; dx++) {
      const sx = sourceLeft + Math.min(spriteWidth - 1, Math.floor(dx * spriteWidth / destWidth));
      const sourceIndex = (sy * spriteSheet.width + sx) * 4;
      const alpha = spriteSheet.data[sourceIndex + 3] / 255;
      if (alpha <= 0) continue;
      const x = left + dx;
      const y = top + dy;
      if (x < 0 || x >= target.width || y < 0 || y >= target.height) continue;
      const targetIndex = (y * target.width + x) * 3;
      const inverseAlpha = 1 - alpha;
      target.color[targetIndex] =
        spriteSheet.data[sourceIndex] * alpha + target.color[targetIndex] * inverseAlpha;
      target.color[targetIndex + 1] =
        spriteSheet.data[sourceIndex + 1] * alpha + target.color[targetIndex + 1] * inverseAlpha;
      target.color[targetIndex + 2] =
        spriteSheet.data[sourceIndex + 2] * alpha + target.color[targetIndex + 2] * inverseAlpha;
    }
  }
}

function move(directionName) {
  const now = performance.now();
  if (movement && movementProgress(now) < 1) return;
  if (movement) {
    playerTile = [...movement.to];
    movement = null;
  }
  const direction = directions[directionName];
  playerDirection = directionName;

  if (currentArea === 'outdoor') {
    const entrance = map.entrance;
    const isAtThreshold = entrance.threshold_cells_bottom_left.some(([x, y]) =>
      x === playerTile[0] && y === playerTile[1]);
    if (isAtThreshold && directionName === entrance.direction) {
      currentArea = entrance.destination;
      playerTile = [...entrance.spawn_tile_bottom_left];
      playerDirection = entrance.spawn_direction;
      movement = null;
      draw(now);
      return;
    }
  } else {
    const exit = interior.exit;
    const isAtThreshold = exit.threshold_cells_bottom_left.some(([x, y]) =>
      x === playerTile[0] && y === playerTile[1]);
    if (isAtThreshold && directionName === exit.direction) {
      currentArea = exit.destination;
      playerTile = [...exit.spawn_tile_bottom_left];
      playerDirection = exit.spawn_direction;
      movement = null;
      draw(now);
      return;
    }
  }

  const destination = [playerTile[0] + direction.dx, playerTile[1] + direction.dy];
  if (destination[0] < 0 || destination[0] >= columns ||
    destination[1] < 0 || destination[1] >= rows ||
    blockedCells[currentArea].has(destination.join(','))) {
    draw(now);
    return;
  }
  movement = {
    from: [...playerTile],
    to: destination,
    startedAt: now,
    duration: character.animations.walk.cycle_duration_seconds * 1000,
  };
  draw(now);
}

function close() {
  if (!running) return;
  running = false;
  clearInterval(frameTimer);
  process.stdin.off('data', inputParser);
  process.stdout.off('resize', draw);
  leaveTerminal();
  process.exit(0);
}

function reloadScene() {
  if (!running) return;
  running = false;
  clearInterval(frameTimer);
  process.stdin.off('data', inputParser);
  process.stdout.off('resize', draw);
  leaveTerminal();
  const result = spawnSync(process.execPath, [new URL(import.meta.url).pathname], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function selectScene(scene) {
  if (scene === manifest.id) return;
}

function onKey(event) {
  if (systemOverlay.handleKey(event)) {
    draw();
    return;
  }
  if (event.meta || event.ctrl) return;
  if (event.name === 'q' || event.name === 'escape') {
    close();
    return;
  }
  if (paused) return;
  const direction = directionByKey.get(event.name.toLowerCase());
  if (direction) move(direction);
}

function draw(now = performance.now()) {
  if (!running) return;
  const terminalColumns = Math.max(1, process.stdout.columns || 80);
  const terminalRows = Math.max(12, process.stdout.rows || 24);
  let picture = paused && frozenPicture ? frozenPicture : '';
  if (!picture) {
    const width = Math.max(1, terminalColumns - 1);
    const height = (terminalRows - 1) * 2;
    target.resize(width, height);
    target.clear(...background);
    const scale = Math.min(width / frameWidth, height / frameHeight);
    viewport = {
      left: (width - frameWidth * scale) / 2,
      top: (height - frameHeight * scale) / 2,
      scale,
    };
    drawMap();
    drawPlayer(now);
    frameCount++;
    if (now - fpsWindowStart >= 500) {
      measuredFps = frameCount * 1000 / (now - fpsWindowStart);
      frameCount = 0;
      fpsWindowStart = now;
    }
    picture = renderMode === 'half-block'
      ? toHalfBlock(target)
      : toShapeGlyph(target, width, terminalRows - 1, { color: true, hybrid: true });
    lastPicture = picture;
  }
  if (clipboardMessage && now >= clipboardMessageUntil) clipboardMessage = '';
  process.stdout.write('\x1b[2J\x1b[H' + picture + systemOverlay.render(terminalColumns));
}

const systemOverlay = createSystemOverlay({
  menus,
  getRuntimeState: () => ({ measuredFps, targetFps, renderMode, paused, clipboardMessage, clipboardMessageUntil }),
  adjustTargetFps,
  cycleRenderMode,
  toggleFramePause,
  copyFrame: copyCurrentFrame,
  reloadScene,
  selectScene,
});

const inputParser = createInputParser({ onKey });
process.once('exit', leaveTerminal);
if (!process.stdin.isTTY || !process.stdout.isTTY) {
  console.error('Arcade richiede un terminale interattivo.');
  process.exit(1);
}
enterTerminal();
process.stdin.on('data', inputParser);
process.stdout.on('resize', draw);
draw();
setFrameRate();
