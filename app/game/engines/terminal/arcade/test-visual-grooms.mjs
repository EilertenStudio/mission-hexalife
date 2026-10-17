import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { RenderTarget, toHalfBlock, toShapeGlyph } from 'ascii-arcade/engine';
import { decodePng } from 'ascii-arcade/engine/png';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { copyFrameToClipboard } from './frame-clipboard.mjs';
import { createSystemOverlay } from './system-overlay.mjs';

const sceneDir = new URL('../../../src/scenes/test-visual-grooms/', import.meta.url);
const readJson = (name) => JSON.parse(readFileSync(new URL(name, sceneDir), 'utf8'));
const manifest = readJson('scene.json');
const geometry = readJson(manifest.state.geometry);
const lighting = readJson(manifest.state.lighting);
const camera = readJson(manifest.state.camera);
const menus = readJson(manifest.state.menus);
const debugSettings = menus.menus.system_debug.items;
const sprites = new Map(geometry.objects.map((object) => [
  object.id,
  decodePng(readFileSync(new URL(object.sprite_asset, sceneDir))),
]));
if (camera.initial_view.mode !== 'fixed' || camera.projection.type !== 'orthographic') {
  throw new Error('La sonda visiva richiede una camera ortografica fissa.');
}

const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
const [minX, minY, maxX, maxY] = camera.projection.frame_bounds;
if (maxX - minX !== frameWidth || maxY - minY !== frameHeight) {
  throw new Error('I limiti della camera devono corrispondere alla dimensione del framebuffer.');
}
const objectsById = new Map(geometry.objects.map((object) => {
  if (!geometry.materials[object.material]) {
    throw new Error(`Materiale non definito per l'oggetto: ${object.id}`);
  }
  return [object.id, object];
}));
const hotspots = geometry.interaction.hotspots;
if (objectsById.size !== 3 || hotspots.length !== 3 ||
  hotspots.some(({ id }) => !objectsById.has(id)) ||
  [...objectsById.keys()].some((id) => !sprites.has(id))) {
  throw new Error('La scena richiede tre oggetti sprite e tre hotspot corrispondenti.');
}

const mainLight = lighting.lights.find((light) => light.id === 'mouse-torch');
const orb = objectsById.get(lighting.animations[0]?.target);
if (!mainLight || mainLight.type !== 'point' || !mainLight.follows_pointer ||
  !mainLight.visual?.fixture || !orb) {
  throw new Error('La sonda richiede una torcia legata al puntatore e un elemento luminoso animato.');
}
let lightPosition = [...mainLight.position];

const background = manifest.rendering.background_color_rgb;
let target = new RenderTarget(1, 1);
let viewport = { left: 0, top: 0, scale: 1 };
let hoveredId = null;
let clickedId = null;
let clickedAt = 0;
let running = true;
let paused = false;
let pausedAt = 0;
let lastPicture = '';
let frozenPicture = '';
let clipboardMessage = '';
let clipboardMessageUntil = 0;
let animationStart = performance.now();
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
    const pauseDuration = now - pausedAt;
    paused = false;
    animationStart += pauseDuration;
    if (clickedId) clickedAt += pauseDuration;
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
    ? `FRAME COPIATO ${result.width}x${result.height} PNG`
    : `COPIA FALLITA: ${result.reason}`;
  clipboardMessageUntil = performance.now() + 3000;
}

function sceneToTarget([x, y]) {
  return [
    viewport.left + (x - minX) * viewport.scale,
    viewport.top + (maxY - y) * viewport.scale,
  ];
}

function targetToScene(x, y) {
  const sceneX = (x - viewport.left) / viewport.scale + minX;
  const sceneY = maxY - (y - viewport.top) / viewport.scale;
  if (sceneX < minX || sceneX >= maxX || sceneY < minY || sceneY >= maxY) return null;
  return [sceneX, sceneY];
}

function setPixel(x, y, color) {
  const px = Math.round(x);
  const py = Math.round(y);
  if (px < 0 || px >= target.width || py < 0 || py >= target.height) return;
  const index = (py * target.width + px) * 3;
  target.color[index] = color[0];
  target.color[index + 1] = color[1];
  target.color[index + 2] = color[2];
}

function addPixel(x, y, color, opacity) {
  const px = Math.round(x);
  const py = Math.round(y);
  if (px < 0 || px >= target.width || py < 0 || py >= target.height) return;
  const index = (py * target.width + px) * 3;
  target.color[index] = Math.min(255, target.color[index] + color[0] * opacity);
  target.color[index + 1] = Math.min(255, target.color[index + 1] + color[1] * opacity);
  target.color[index + 2] = Math.min(255, target.color[index + 2] + color[2] * opacity);
}

function mixColor(a, b, amount) {
  return a.map((channel, index) => Math.round(channel + (b[index] - channel) * amount));
}

function lightFalloffAt(x, y) {
  const dx = x - lightPosition[0];
  const dy = y - lightPosition[1];
  return Math.exp(-(dx * dx + dy * dy) / (mainLight.falloff_radius ** 2));
}

function drawLightPool() {
  const visual = mainLight.visual;
  for (let py = 0; py < target.height; py++) {
    for (let px = 0; px < target.width; px++) {
      const worldPosition = targetToScene(px + 0.5, py + 0.5);
      if (!worldPosition) continue;
      const [worldX, worldY] = worldPosition;
      const falloff = lightFalloffAt(worldX, worldY);
      const opacity = visual.pool_opacity * Math.sqrt(falloff);
      if (opacity > 0.001) addPixel(px, py, visual.pool_color_rgb, opacity);
    }
  }
}

function fillPolygon(vertices, color, lit = false) {
  const points = vertices.map(sceneToTarget);
  const lowX = Math.max(0, Math.floor(Math.min(...points.map(([x]) => x))));
  const highX = Math.min(target.width - 1, Math.ceil(Math.max(...points.map(([x]) => x))));
  const lowY = Math.max(0, Math.floor(Math.min(...points.map(([, y]) => y))));
  const highY = Math.min(target.height - 1, Math.ceil(Math.max(...points.map(([, y]) => y))));

  for (let py = lowY; py <= highY; py++) {
    for (let px = lowX; px <= highX; px++) {
      if (!insidePolygon(px + 0.5, py + 0.5, points)) continue;
      if (!lit) {
        setPixel(px, py, color);
        continue;
      }
      const [worldX, worldY] = targetToScene(px + 0.5, py + 0.5);
      const falloff = lightFalloffAt(worldX, worldY);
      const brightness = Math.min(1, lighting.ambient_intensity + mainLight.intensity * falloff);
      setPixel(px, py, [
        Math.min(255, color[0] * brightness),
        Math.min(255, color[1] * brightness),
        Math.min(255, color[2] * brightness),
      ]);
    }
  }
}

function insidePolygon(x, y, points) {
  let inside = false;
  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const [xi, yi] = points[i];
    const [xj, yj] = points[j];
    const crosses = (yi > y) !== (yj > y) &&
      x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    if (crosses) inside = !inside;
  }
  return inside;
}

function drawLine(from, to, color, width = 1, colorAtPixel = null) {
  const [x0, y0] = sceneToTarget(from);
  const [x1, y1] = sceneToTarget(to);
  let x = Math.round(x0);
  let y = Math.round(y0);
  const endX = Math.round(x1);
  const endY = Math.round(y1);
  const dx = Math.abs(endX - x);
  const sx = x < endX ? 1 : -1;
  const dy = -Math.abs(endY - y);
  const sy = y < endY ? 1 : -1;
  let error = dx + dy;
  const stroke = Math.max(1, Math.round(width * viewport.scale));

  while (true) {
    for (let offsetY = 0; offsetY < stroke; offsetY++) {
      for (let offsetX = 0; offsetX < stroke; offsetX++) {
        const pixelX = x + offsetX;
        const pixelY = y + offsetY;
        setPixel(pixelX, pixelY, colorAtPixel ? colorAtPixel(pixelX, pixelY) : color);
      }
    }
    if (x === endX && y === endY) break;
    const doubleError = error * 2;
    if (doubleError >= dy) {
      error += dy;
      x += sx;
    }
    if (doubleError <= dx) {
      error += dx;
      y += sy;
    }
  }
}

function drawLitLine(from, to, baseColor, reflectivity = 1, width = 1) {
  const highlightColor = mainLight.visual.edge_highlight_color_rgb;
  const strength = mainLight.visual.edge_highlight_strength;
  drawLine(from, to, baseColor, width, (x, y) => {
    const worldX = (x + 0.5 - viewport.left) / viewport.scale + minX;
    const worldY = maxY - (y + 0.5 - viewport.top) / viewport.scale;
    const reflection = lightFalloffAt(worldX, worldY) * mainLight.intensity * reflectivity * strength;
    return mixColor(baseColor, highlightColor, Math.min(1, reflection));
  });
}

function outline(points, color, width = 1, closed = true) {
  const edgeCount = closed ? points.length : points.length - 1;
  for (let index = 0; index < edgeCount; index++) {
    drawLine(points[index], points[(index + 1) % points.length], color, width);
  }
}

function drawRectangleOutline(center, width, height, color) {
  const [x, y] = center;
  outline([
    [x - width / 2, y - height / 2],
    [x + width / 2, y - height / 2],
    [x + width / 2, y + height / 2],
    [x - width / 2, y + height / 2],
  ], color);
}

function spriteTargetBounds(object) {
  const [centerX, centerY] = sceneToTarget(object.position);
  const width = Math.max(1, Math.round(object.size[0] * viewport.scale));
  const height = Math.max(1, Math.round(object.size[1] * viewport.scale));
  return {
    left: Math.round(centerX - width / 2),
    top: Math.round(centerY - height / 2),
    width,
    height,
  };
}

function spritePixel(sprite, x, y, width, height) {
  const sourceX = Math.min(sprite.width - 1, Math.floor((x + 0.5) * sprite.width / width));
  const sourceY = Math.min(sprite.height - 1, Math.floor((y + 0.5) * sprite.height / height));
  return (sourceY * sprite.width + sourceX) * 4;
}

function drawSprite(object, sprite, pulse = 0) {
  const bounds = spriteTargetBounds(object);
  const material = geometry.materials[object.material];
  const reflectivity = material.reflectivity ?? 0.5;
  const highlightColor = mainLight.visual.edge_highlight_color_rgb;
  const highlightValue = Math.round((highlightColor[0] + highlightColor[1] + highlightColor[2]) / 3);
  const highlightStrength = mainLight.visual.edge_highlight_strength;
  const opaqueAt = (x, y) => {
    if (x < 0 || x >= bounds.width || y < 0 || y >= bounds.height) return false;
    const index = spritePixel(sprite, x, y, bounds.width, bounds.height);
    return sprite.data[index + 3] >= 128;
  };

  for (let y = 0; y < bounds.height; y++) {
    for (let x = 0; x < bounds.width; x++) {
      const sourceIndex = spritePixel(sprite, x, y, bounds.width, bounds.height);
      const alpha = sprite.data[sourceIndex + 3] / 255;
      if (alpha <= 0) continue;
      const targetX = bounds.left + x;
      const targetY = bounds.top + y;
      if (targetX < 0 || targetX >= target.width || targetY < 0 || targetY >= target.height) continue;
      const targetIndex = (targetY * target.width + targetX) * 3;
      const inverseAlpha = 1 - alpha;
      const [worldX, worldY] = targetToScene(targetX + 0.5, targetY + 0.5);
      const falloff = lightFalloffAt(worldX, worldY);
      const diffuse = Math.max(0.08, Math.min(1,
        lighting.ambient_intensity + mainLight.intensity * falloff * (material.diffuse_response ?? 1),
      ));
      const sourceLuminance = Math.round(
        sprite.data[sourceIndex] * 0.2126 +
        sprite.data[sourceIndex + 1] * 0.7152 +
        sprite.data[sourceIndex + 2] * 0.0722,
      );
      const luminance = Math.round(255 * (sourceLuminance / 255) ** 0.72);
      let shade = luminance * diffuse;

      let normalX = 0;
      let normalY = 0;
      if (!opaqueAt(x - 1, y)) normalX--;
      if (!opaqueAt(x + 1, y)) normalX++;
      if (!opaqueAt(x, y - 1)) normalY++;
      if (!opaqueAt(x, y + 1)) normalY--;
      const normalLength = Math.hypot(normalX, normalY);
      if (normalLength > 0) {
        const lightX = lightPosition[0] - worldX;
        const lightY = lightPosition[1] - worldY;
        const lightLength = Math.hypot(lightX, lightY) || 1;
        const facing = Math.max(0, (normalX * lightX + normalY * lightY) / (normalLength * lightLength));
        const reflection = falloff * mainLight.intensity * reflectivity * highlightStrength * facing ** 1.35;
        shade += (highlightValue - shade) * Math.min(0.92, reflection);
      }

      const gray = Math.round(Math.min(255, shade + (255 - shade) * pulse * 0.42));
      target.color[targetIndex] = Math.round(gray * alpha + target.color[targetIndex] * inverseAlpha);
      target.color[targetIndex + 1] = Math.round(gray * alpha + target.color[targetIndex + 1] * inverseAlpha);
      target.color[targetIndex + 2] = Math.round(gray * alpha + target.color[targetIndex + 2] * inverseAlpha);
    }
  }
}

function drawSpriteOutline(object, sprite, color, width = 1) {
  const bounds = spriteTargetBounds(object);
  const stroke = Math.max(1, Math.round(width * viewport.scale));
  const opaqueAt = (x, y) => {
    if (x < 0 || x >= bounds.width || y < 0 || y >= bounds.height) return false;
    const index = spritePixel(sprite, x, y, bounds.width, bounds.height);
    return sprite.data[index + 3] >= 128;
  };

  for (let y = 0; y < bounds.height; y++) {
    for (let x = 0; x < bounds.width; x++) {
      if (!opaqueAt(x, y)) continue;
      if (opaqueAt(x - 1, y) && opaqueAt(x + 1, y) &&
        opaqueAt(x, y - 1) && opaqueAt(x, y + 1)) continue;
      for (let offsetY = 0; offsetY < stroke; offsetY++) {
        for (let offsetX = 0; offsetX < stroke; offsetX++) {
          setPixel(bounds.left + x + offsetX, bounds.top + y + offsetY, color);
        }
      }
    }
  }
}

function pulseIntensity(now) {
  const animation = lighting.animations.find((item) => item.id === orb.emission_animation);
  const elapsed = (now - animationStart) / 1000;
  const wave = (Math.sin((elapsed / animation.period_seconds) * Math.PI * 2 - Math.PI / 2) + 1) / 2;
  return animation.minimum_intensity + (animation.maximum_intensity - animation.minimum_intensity) * wave;
}

function drawRoom() {
  for (const surface of geometry.room.surfaces) {
    fillPolygon(surface.vertices, surface.base_color_rgb, true);
  }
  drawLightPool();
  for (const edge of geometry.room.edges ?? []) {
    drawLitLine(edge.vertices[0], edge.vertices[1], edge.color_rgb, edge.reflectivity ?? 0, 1);
  }
}

function orientedRectangle(center, direction, length, thickness) {
  const directionLength = Math.hypot(...direction) || 1;
  const unitDirection = direction.map((component) => component / directionLength);
  const perpendicular = [-unitDirection[1], unitDirection[0]];
  return [[-1, -1], [1, -1], [1, 1], [-1, 1]].map(([along, across]) => [
    center[0] + unitDirection[0] * along * length / 2 + perpendicular[0] * across * thickness / 2,
    center[1] + unitDirection[1] * along * length / 2 + perpendicular[1] * across * thickness / 2,
  ]);
}

function drawTorchFixture() {
  const fixture = mainLight.visual.fixture;
  const directionLength = Math.hypot(...fixture.direction) || 1;
  const direction = fixture.direction.map((component) => component / directionLength);
  const perpendicular = [-direction[1], direction[0]];
  const [length, thickness] = fixture.size;
  const body = orientedRectangle(fixture.position, direction, length, thickness);
  fillPolygon(body, fixture.body_color_rgb);
  outline(body, fixture.edge_color_rgb);

  const gripCenter = [
    fixture.position[0] - direction[0] * length * 0.24 + perpendicular[0] * thickness * 0.9,
    fixture.position[1] - direction[1] * length * 0.24 + perpendicular[1] * thickness * 0.9,
  ];
  const grip = orientedRectangle(gripCenter, perpendicular, thickness * 1.4, thickness * 0.62);
  fillPolygon(grip, fixture.body_color_rgb);
  outline(grip, fixture.edge_color_rgb);

  const lensCenter = [
    fixture.position[0] + direction[0] * (length / 2 - 1),
    fixture.position[1] + direction[1] * (length / 2 - 1),
  ];
  const lens = orientedRectangle(lensCenter, direction, 3.5, thickness - 1);
  fillPolygon(lens, fixture.lens_color_rgb);
  outline(lens, fixture.lens_color_rgb);
}

function drawObject(object, emission) {
  if (object.id === 'lumen-orb') {
    const [x, y] = object.position;
    const material = geometry.materials[object.material];
    const glow = (material.emissive_glow_strength ?? 0.02) * (0.35 + emission * 0.65);
    fillGlow([x, y], object.size[0] * 0.5, object.size[1] * 0.5, material.emissive_color_rgb, glow);
  }
  const sprite = sprites.get(object.id);
  if (!sprite) throw new Error(`Sprite non trovato per l'oggetto: ${object.id}`);
  drawSprite(object, sprite, object.emission_animation ? emission : 0);
}

function fillGlow(center, radiusX, radiusY, color, strength) {
  const [screenX, screenY] = sceneToTarget(center);
  const pxRadius = Math.ceil(radiusX * viewport.scale);
  const pyRadius = Math.ceil(radiusY * viewport.scale);
  for (let y = Math.floor(screenY - pyRadius); y <= Math.ceil(screenY + pyRadius); y++) {
    for (let x = Math.floor(screenX - pxRadius); x <= Math.ceil(screenX + pxRadius); x++) {
      const dx = (x + 0.5 - screenX) / Math.max(1, pxRadius);
      const dy = (y + 0.5 - screenY) / Math.max(1, pyRadius);
      const distance = dx * dx + dy * dy;
      if (distance < 1) addPixel(x, y, color, (1 - distance) ** 2 * strength);
    }
  }
}

function drawInteractionFeedback(now) {
  const feedback = geometry.interaction;
  if (hoveredId) {
    const object = objectsById.get(hoveredId);
    drawSpriteOutline(
      object,
      sprites.get(hoveredId),
      feedback.hover_feedback.outline_color_rgb,
      feedback.hover_feedback.outline_width_pixels,
    );
  }

  const age = (now - clickedAt) / 1000;
  if (clickedId && age >= 0 && age < feedback.click_feedback.duration_seconds) {
    const object = objectsById.get(clickedId);
    const progress = age / feedback.click_feedback.duration_seconds;
    const [x, y] = object.position;
    const [width, height] = object.size;
    const color = mixColor(feedback.click_feedback.flash_color_rgb, background, progress * 0.72);
    drawSpriteOutline(object, sprites.get(clickedId), color, 2);
    for (let ring = 0; ring < feedback.click_feedback.ring_count; ring++) {
      const padding = feedback.click_feedback.ring_padding_pixels * (ring + 1);
      drawRectangleOutline([x, y], width + padding * 2, height + padding * 2, color);
    }
  }
}

function draw(now = performance.now()) {
  if (!running) return;
  const columns = Math.max(1, process.stdout.columns || 80);
  const rows = Math.max(12, process.stdout.rows || 24);
  let picture = paused && frozenPicture ? frozenPicture : '';

  if (!picture) {
    const width = Math.max(1, columns - 1);
    const height = (rows - 1) * 2;
    target.resize(width, height);
    target.clear(...background);

    const scale = Math.min(width / frameWidth, height / frameHeight);
    viewport = {
      left: (width - frameWidth * scale) / 2,
      top: (height - frameHeight * scale) / 2,
      scale,
    };

    drawRoom();
    drawTorchFixture();
    const emission = pulseIntensity(now);
    for (const object of geometry.objects) drawObject(object, emission);
    drawInteractionFeedback(now);

    frameCount++;
    if (now - fpsWindowStart >= 500) {
      measuredFps = frameCount * 1000 / (now - fpsWindowStart);
      frameCount = 0;
      fpsWindowStart = now;
    }

    picture = renderMode === 'half-block'
      ? toHalfBlock(target)
      : toShapeGlyph(target, width, rows - 1, { color: true, hybrid: true });
    lastPicture = picture;
  }

  if (clipboardMessage && now >= clipboardMessageUntil) clipboardMessage = '';
  process.stdout.write(`\x1b[2J\x1b[H${picture}${systemOverlay.render(columns)}`);
}

function hitTest(targetX, targetY) {
  const point = targetToScene(targetX, targetY);
  if (!point) return null;
  const [x, y] = point;
  return hotspots.find(({ bounds }) =>
    x >= bounds[0] && x <= bounds[2] && y >= bounds[1] && y <= bounds[3],
  )?.id ?? null;
}

function mousePosition(event) {
  return [event.x - 1, (event.y - 1) * 2 + 0.5];
}

function onMouse(event) {
  if (systemOverlay.isOpen) {
    if (systemOverlay.handleMouse(event)) draw();
    return;
  }
  if (paused) return;
  if (event.type !== 'move' && event.type !== 'down') return;
  const [x, y] = mousePosition(event);
  const pointerPosition = targetToScene(x, y);
  const lightMoved = pointerPosition && mainLight.follows_pointer &&
    (Math.abs(lightPosition[0] - pointerPosition[0]) >= 0.5 ||
      Math.abs(lightPosition[1] - pointerPosition[1]) >= 0.5);
  if (lightMoved) lightPosition = pointerPosition;
  const nextHover = hitTest(x, y);
  const hoverChanged = nextHover !== hoveredId;
  hoveredId = nextHover;

  if (event.type === 'down' && event.button === 0 && nextHover) {
    clickedId = nextHover;
    clickedAt = performance.now();
    draw(clickedAt);
  } else if (hoverChanged || lightMoved) {
    draw();
  }
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

function launchScene(scriptPath) {
  if (!running) return;
  running = false;
  clearInterval(frameTimer);
  process.stdin.off('data', inputParser);
  process.stdout.off('resize', draw);
  leaveTerminal();

  const result = spawnSync(process.execPath, [scriptPath], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function switchScene(scriptName) {
  launchScene(new URL(`./${scriptName}`, import.meta.url).pathname);
}

function reloadScene() {
  launchScene(new URL(import.meta.url).pathname);
}

function selectScene(scene) {
  if (scene === manifest.id) return;
  if (scene === 'cryogenic-room') switchScene('cryogenic-story.mjs');
  else if (scene === 'test-gameplay-action-adventure') switchScene('test-gameplay-action-adventure.mjs');
}

function onKey(event) {
  if (systemOverlay.handleKey(event)) {
    draw();
    return;
  }
  if (event.meta) return;
  if (event.name === 'q' || event.name === 'escape') close();
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

const inputParser = createInputParser({ onKey, onMouse });
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
