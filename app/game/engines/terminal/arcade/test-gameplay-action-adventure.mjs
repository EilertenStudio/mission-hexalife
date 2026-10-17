import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { RenderTarget, toHalfBlock, toShapeGlyph } from 'ascii-arcade/engine';
import { decodePng } from 'ascii-arcade/engine/png';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { copyFrameToClipboard } from './frame-clipboard.mjs';
import { createSystemOverlay } from './system-overlay.mjs';

const sceneDir = new URL('../../../src/scenes/test-gameplay-action-adventure/', import.meta.url);
const readJson = (path) => JSON.parse(readFileSync(new URL(path, sceneDir), 'utf8'));
const manifest = readJson('scene.json');
const grid = readJson(manifest.state.grid);
const character = readJson(manifest.state.character).player;
const controls = readJson(manifest.state.controls).movement;
const camera = readJson(manifest.state.camera);
const menus = readJson(manifest.state.menus);
const debugSettings = menus.menus.system_debug.items;
const spriteSheet = decodePng(readFileSync(new URL(character.sprite_sheet, sceneDir)));

const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
const [columns, rows] = [grid.grid.columns, grid.grid.rows];
const [tileWidth, tileHeight] = grid.grid.tile_size_pixels;
const [spriteWidth, spriteHeight] = character.frame_size_pixels;
const [minX, minY, maxX, maxY] = camera.projection.frame_bounds;
if (columns * tileWidth !== frameWidth || rows * tileHeight !== frameHeight ||
  maxX - minX !== frameWidth || maxY - minY !== frameHeight) {
  throw new Error('La griglia e i limiti della camera devono coincidere con il framebuffer.');
}

const directionRows = character.direction_rows_top_to_bottom;
const directions = {
  down: { dx: 0, dy: -1, row: directionRows.indexOf('down') },
  left: { dx: -1, dy: 0, row: directionRows.indexOf('left') },
  top: { dx: 0, dy: 1, row: directionRows.indexOf('top') },
  right: { dx: 1, dy: 0, row: directionRows.indexOf('right') },
};
const directionByKey = new Map(controls.keys.map(({ key, direction }) => [key.toLowerCase(), direction]));
const background = manifest.rendering.background_color_rgb;
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

function setPixel(x, y, color) {
  if (x < 0 || x >= target.width || y < 0 || y >= target.height) return;
  const index = (y * target.width + x) * 3;
  target.color[index] = color[0];
  target.color[index + 1] = color[1];
  target.color[index + 2] = color[2];
}

function fillRect(x, y, width, height, color) {
  const left = Math.max(0, Math.floor(viewport.left + x * viewport.scale));
  const top = Math.max(0, Math.floor(viewport.top + y * viewport.scale));
  const right = Math.min(target.width, Math.ceil(viewport.left + (x + width) * viewport.scale));
  const bottom = Math.min(target.height, Math.ceil(viewport.top + (y + height) * viewport.scale));
  for (let py = top; py < bottom; py++) {
    for (let px = left; px < right; px++) setPixel(px, py, color);
  }
}

function drawGrid() {
  const [colorA, colorB] = grid.appearance.floor_colors_rgb;
  for (let row = 0; row < rows; row++) {
    const screenRow = rows - 1 - row;
    for (let column = 0; column < columns; column++) {
      fillRect(
        column * tileWidth,
        screenRow * tileHeight,
        tileWidth,
        tileHeight,
        (column + row) % 2 === 0 ? colorA : colorB,
      );
    }
  }

  const lineWidth = grid.appearance.grid_line_width_pixels;
  const lineColor = grid.appearance.grid_line_color_rgb;
  for (let column = 0; column <= columns; column++) {
    fillRect(column * tileWidth - (column === columns ? lineWidth : 0), 0,
      lineWidth, frameHeight, lineColor);
  }
  for (let row = 0; row <= rows; row++) {
    fillRect(0, row * tileHeight - (row === rows ? lineWidth : 0),
      frameWidth, lineWidth, lineColor);
  }
  const border = grid.appearance.border_color_rgb;
  fillRect(0, 0, frameWidth, lineWidth, border);
  fillRect(0, frameHeight - lineWidth, frameWidth, lineWidth, border);
  fillRect(0, 0, lineWidth, frameHeight, border);
  fillRect(frameWidth - lineWidth, 0, lineWidth, frameHeight, border);
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
    ? Math.min(animation.frame_count - 1, Math.floor(progress * animation.frame_count))
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
  const destination = [playerTile[0] + direction.dx, playerTile[1] + direction.dy];
  if (destination[0] < 0 || destination[0] >= columns ||
    destination[1] < 0 || destination[1] >= rows) {
    draw(now);
    return;
  }
  movement = {
    from: [...playerTile],
    to: destination,
    startedAt: now,
    duration: character.movement.walk_cycle_duration_seconds * 1000,
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

function switchScene(scriptName) {
  if (!running) return;
  running = false;
  clearInterval(frameTimer);
  process.stdin.off('data', inputParser);
  process.stdout.off('resize', draw);
  leaveTerminal();
  const result = spawnSync(process.execPath, [new URL('./' + scriptName, import.meta.url).pathname], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
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
  if (scene === 'test-visual-grooms') switchScene('test-visual-grooms.mjs');
  else if (scene === 'cryogenic-room') switchScene('cryogenic-story.mjs');
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
    drawGrid();
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
