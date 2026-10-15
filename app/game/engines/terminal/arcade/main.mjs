import { spawnSync } from 'node:child_process';
import {
  GeometryBuilder,
  OrbitCamera,
  RenderTarget,
  Scene,
  SceneRenderer,
  cube,
  downsample,
  mat4MulDir,
  mat4MulVec4,
  normalize3,
  toHalfBlock,
  toShapeGlyph,
  worldUniforms,
} from 'ascii-arcade/engine';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { loadCryogenicRoom } from './cryogenic-room.mjs';

const sceneNameArgument = process.argv[2];
let sceneName = sceneNameArgument ?? 'cryogenic-room';
let sceneSelectionOpen = false;
let selectedSceneIndex = sceneName === 'cryogenic-room' ? 1 : 0;
if (!['room', 'cryogenic-room'].includes(sceneName)) {
  console.error(`Scena sconosciuta: ${sceneName}`);
  process.exit(1);
}

if (!process.stdin.isTTY || !process.stdout.isTTY) {
  console.error('Arcade richiede un terminale interattivo.');
  process.exit(1);
}

const scene = new Scene();
const renderer = new SceneRenderer();
let cryogenicRoom;
let activeScene = scene;
let cameraOrbit;
let cameraProjection;

function activateScene(name) {
  sceneName = name;
  if (name === 'cryogenic-room') cryogenicRoom ??= loadCryogenicRoom();
  const camera = cryogenicRoom && name === 'cryogenic-room'
    ? cryogenicRoom.camera
    : {
        eye: { x: 4.5, y: 2.5, z: 6.5 },
        target: { x: 0, y: -0.35, z: 0 },
        minDistance: 2.5,
        maxDistance: 20,
        projection: {
          up: { x: 0, y: 1, z: 0 },
          fovy: 48 * Math.PI / 180,
          near: 0.1,
          far: 40,
        },
      };
  const offset = {
    x: camera.eye.x - camera.target.x,
    y: camera.eye.y - camera.target.y,
    z: camera.eye.z - camera.target.z,
  };
  cameraOrbit = new OrbitCamera({
    azimuth: Math.atan2(offset.x, offset.z),
    elevation: Math.atan2(offset.y, Math.hypot(offset.x, offset.z)),
    distance: Math.hypot(offset.x, offset.y, offset.z),
    target: { ...camera.target },
  }, camera.minDistance, camera.maxDistance);
  cameraProjection = camera.projection;
  activeScene = name === 'cryogenic-room' ? cryogenicRoom.scene : scene;
}

activateScene(sceneName);
let cameraMenuOpen = false;
let cameraDragMode = null;
let lastMousePosition = null;
const enhancedFlightKeys = new Map();
const repeatedFlightKeys = new Map();
const flightModifiers = new Set();
let flightTimer;
let lastFlightUpdateAt = 0;
let kittyKeyboardSeen = false;
let kittyKeyboardModePushed = false;

const light = {
  position: { x: 0, y: 1.5, z: 0 },
  direction: { x: 0, y: -1, z: 0 },
  color: { x: 255, y: 177, z: 91 },
  intensity: 12,
  innerCone: Math.cos(16 * Math.PI / 180),
  outerCone: Math.cos(27 * Math.PI / 180),
};

const fixedLights = [
  { position: { x: -2.2, y: 1.5, z: -2.45 }, color: { x: 115, y: 181, z: 255 }, intensity: 2.8 },
  { position: { x: 2.2, y: 1.5, z: -2.45 }, color: { x: 255, y: 122, z: 194 }, intensity: 2.8 },
  { position: { x: -2.2, y: 1.5, z: 2.45 }, color: { x: 122, y: 255, z: 199 }, intensity: 2.8 },
];
const lights = [light, ...fixedLights];

const clamp01 = (value) => Math.max(0, Math.min(1, value));
const roomPixel = { r: 0, g: 0, b: 0, a: 1 };
const lampPixel = { r: 255, g: 208, b: 124, a: 1 };
const beamPixel = { r: 0, g: 0, b: 0, a: 0.13 };

const roomMaterial = {
  cull: 'none',
  vertex(uniforms, vertex) {
    const point = vertex.position;
    const clip = mat4MulVec4(uniforms.mvp, { x: point.x, y: point.y, z: point.z, w: 1 });
    const world = mat4MulVec4(uniforms.model, { x: point.x, y: point.y, z: point.z, w: 1 });
    return {
      clip,
      world: { x: world.x, y: world.y, z: world.z },
      normal: mat4MulDir(uniforms.model, vertex.normal),
      uv: vertex.uv,
      color: vertex.color,
      bary: { x: 0, y: 0, z: 0 },
    };
  },
  fragment(uniforms, point) {
    const normalLength = Math.hypot(point.normal.x, point.normal.y, point.normal.z) || 1;
    let red = point.color.x * uniforms.ambient;
    let green = point.color.y * uniforms.ambient;
    let blue = point.color.z * uniforms.ambient;

    for (const source of uniforms.lights) {
      const dx = point.world.x - source.position.x;
      const dy = point.world.y - source.position.y;
      const dz = point.world.z - source.position.z;
      const distance = Math.hypot(dx, dy, dz) || 1;
      const rayX = dx / distance;
      const rayY = dy / distance;
      const rayZ = dz / distance;
      let cone = 1;

      if (source.direction) {
        const coneDot = rayX * source.direction.x
          + rayY * source.direction.y
          + rayZ * source.direction.z;
        const coneT = clamp01((coneDot - source.outerCone) / (source.innerCone - source.outerCone));
        cone = coneT * coneT * (3 - 2 * coneT);
      }

      const diffuse = Math.max(0, -(point.normal.x * rayX + point.normal.y * rayY + point.normal.z * rayZ) / normalLength);
      const attenuation = 1 / (1 + 0.16 * distance + 0.035 * distance * distance);
      const strength = cone * diffuse * attenuation * source.intensity * 0.24;
      red += source.color.x * strength;
      green += source.color.y * strength;
      blue += source.color.z * strength;
    }

    roomPixel.r = red;
    roomPixel.g = green;
    roomPixel.b = blue;
    return roomPixel;
  },
};

const roomUniforms = worldUniforms(() => ({
  lights,
  ambient: 0.18,
}));

const walls = new GeometryBuilder();
const point = (x, y, z) => ({ x, y, z });
walls.quad(
  point(-3, -2, -3.4), point(3, -2, -3.4), point(3, -2, 3.4), point(-3, -2, 3.4),
  { color: { x: 91, y: 103, z: 126 } }, point(0, 1, 0),
);
walls.quad(
  point(-3, -2, -3.4), point(3, -2, -3.4), point(3, 2, -3.4), point(-3, 2, -3.4),
  { color: { x: 80, y: 95, z: 124 } }, point(0, 0, 1),
);
walls.quad(
  point(-3, -2, 3.4), point(-3, -2, -3.4), point(-3, 2, -3.4), point(-3, 2, 3.4),
  { color: { x: 101, y: 112, z: 139 } }, point(1, 0, 0),
);
walls.quad(
  point(3, -2, -3.4), point(3, -2, 3.4), point(3, 2, 3.4), point(3, 2, -3.4),
  { color: { x: 75, y: 87, z: 112 } }, point(-1, 0, 0),
);
scene.mesh(walls.mesh(), roomMaterial, roomUniforms);

const lampMaterial = {
  cull: 'none',
  vertex(uniforms, vertex) {
    const point = vertex.position;
    return {
      clip: mat4MulVec4(uniforms.mvp, { x: point.x, y: point.y, z: point.z, w: 1 }),
      world: point,
      normal: vertex.normal,
      uv: vertex.uv,
      color: vertex.color,
      bary: { x: 0, y: 0, z: 0 },
    };
  },
  fragment(_uniforms, point) {
    lampPixel.r = point.color.x;
    lampPixel.g = point.color.y;
    lampPixel.b = point.color.z;
    return lampPixel;
  },
};

const lampGeometry = cube(0.115);
for (const vertex of lampGeometry.vertices) vertex.color = { x: 255, y: 208, z: 124 };
const lamp = scene.mesh(lampGeometry, lampMaterial, worldUniforms({}));
lamp.position.y = 1.67;

for (const source of fixedLights) {
  const geometry = cube(0.09);
  for (const vertex of geometry.vertices) vertex.color = source.color;
  const bulb = scene.mesh(geometry, lampMaterial, worldUniforms({}));
  bulb.position.x = source.position.x;
  bulb.position.y = source.position.y + 0.17;
  bulb.position.z = source.position.z;
}

const beamGeometry = new GeometryBuilder();
const beamSegments = 32;
const beamLength = 3.4;
const beamRadius = Math.tan(28 * Math.PI / 180) * beamLength;
const beamApex = point(0, 0, 0);
for (let i = 0; i < beamSegments; i++) {
  const a = (i / beamSegments) * Math.PI * 2;
  const b = ((i + 1) / beamSegments) * Math.PI * 2;
  const edgeA = point(Math.cos(a) * beamRadius, -beamLength, Math.sin(a) * beamRadius);
  const edgeB = point(Math.cos(b) * beamRadius, -beamLength, Math.sin(b) * beamRadius);
  beamGeometry.triangle(beamApex, edgeA, edgeB, { color: { x: 255, y: 177, z: 91 } });
}

const beamMaterial = {
  blend: 'alpha',
  cull: 'none',
  vertex(uniforms, vertex) {
    const point = vertex.position;
    const world = mat4MulVec4(uniforms.model, { x: point.x, y: point.y, z: point.z, w: 1 });
    return {
      clip: mat4MulVec4(uniforms.mvp, { x: point.x, y: point.y, z: point.z, w: 1 }),
      world: { x: world.x, y: world.y, z: world.z },
      normal: mat4MulDir(uniforms.model, vertex.normal),
      uv: vertex.uv,
      color: vertex.color,
      bary: { x: 0, y: 0, z: 0 },
    };
  },
  fragment(_uniforms, point) {
    beamPixel.r = point.color.x;
    beamPixel.g = point.color.y;
    beamPixel.b = point.color.z;
    return beamPixel;
  },
};
const beam = scene.mesh(beamGeometry.mesh(), beamMaterial, worldUniforms({}));
beam.position.y = light.position.y - 0.08;
beam.renderOrder = 1;

let running = true;
let startTime = performance.now();
let paused = false;
let pausedElapsed = 0;
let debugMenuOpen = false;
let frameCount = 0;
let measuredFps = 0;
let fpsWindowStart = performance.now();
let targetFps = 6;
let target = new RenderTarget(1, 1);
let pixelTarget = new RenderTarget(1, 2);
let renderMode = 'half-block';
let timer;
let interactionRenderTimer;
let lastDrawAt = performance.now();

function draw() {
  if (interactionRenderTimer) {
    clearTimeout(interactionRenderTimer);
    interactionRenderTimer = undefined;
  }
  lastDrawAt = performance.now();
  const cols = Math.max(30, process.stdout.columns || 80);
  const rows = Math.max(16, process.stdout.rows || 24);
  const width = cols - 1;
  const supersampling = 3;
  const now = performance.now();
  const elapsed = paused ? pausedElapsed : (now - startTime) / 1000;
  const angle = Math.sin(elapsed * 1.15) * 0.43;
  frameCount++;
  if (now - fpsWindowStart >= 500) {
    measuredFps = frameCount * 1000 / (now - fpsWindowStart);
    frameCount = 0;
    fpsWindowStart = now;
  }
  const hudLineCount = sceneSelectionOpen ? 5 : debugMenuOpen ? 5 : cameraMenuOpen ? 4 : 1;
  const sceneRows = Math.max(8, rows - hudLineCount);
  const height = sceneRows * 2 * supersampling;
  const hudLines = sceneSelectionOpen
    ? [
        'ARCADE  /  SELEZIONE SCENA',
        `${selectedSceneIndex === 0 ? '▶' : ' '}  1  Room 3D`,
        `${selectedSceneIndex === 1 ? '▶' : ' '}  2  Sala criogenica`,
        '↑/↓ seleziona   Invio avvia   1/2 avvio rapido',
        'Esc torna alla scena   q esce',
      ]
    : debugMenuOpen
      ? [
        'DEBUG SISTEMA  [D: chiudi]',
        `FPS EFFETTIVI: ${measuredFps.toFixed(1)}   LIMITE: ${targetFps}`,
        `RESA: ${renderMode === 'half-block' ? 'PIXEL A BLOCCHI' : 'GLIFI ASCII'}  [V: cambia]`,
        `TERMINALE: ${cols}x${rows}   BUFFER RENDER: ${width * supersampling}x${height}`,
        '- o [: diminuisci   +, = o ]: aumenta FPS (1-30)',
      ]
    : cameraMenuOpen
      ? [
          `${cameraDragMode === 'fly' ? 'CAMERA / VOLO' : 'CAMERA / PRONTA AL VOLO'}  [C/Esc: chiudi menu]`,
          'Ctrl+Alt+sinistro pan  Alt+sinistro orbita  Alt+destro zoom',
          'centrale pan  rotella zoom',
          `Tieni destro: mouse guarda; WASD + E/Q o Space/X${kittyKeyboardSeen ? ' continuo' : ' (rilascio stimato)'}; Shift accelera`,
        ]
      : [`${sceneName.toUpperCase()}  M: scene  C: camera  D: debug sistema  Shift+R: ricarica  q: esci`];
  if (sceneName === 'room') {
    light.direction = normalize3({ x: Math.sin(angle), y: -Math.cos(angle), z: 0 });
    beam.rotation.z = angle;
  }

  target.resize(width * supersampling, height);
  target.clear(3, 4, 8);
  renderer.render(target, activeScene, cameraOrbit.toCamera(cameraProjection));

  const hud = hudLines.map((line, index) =>
    `\x1b[${sceneRows + index + 1};1H\x1b[38;2;190;204;226m${line.slice(0, width)}\x1b[0m`,
  ).join('');
  let picture;
  if (renderMode === 'half-block') {
    pixelTarget = downsample(target, supersampling, pixelTarget);
    picture = toHalfBlock(pixelTarget);
  } else {
    picture = toShapeGlyph(target, width, sceneRows, { color: true, hybrid: true });
  }
  process.stdout.write(
    '\x1b[2J'
      + picture
      + hud,
  );
}

function requestInteractionDraw() {
  if (interactionRenderTimer) return;
  const minimumFrameMs = 1000 / 20;
  const delay = Math.max(0, minimumFrameMs - (performance.now() - lastDrawAt));
  interactionRenderTimer = setTimeout(() => {
    interactionRenderTimer = undefined;
    draw();
  }, delay);
}

function close() {
  if (!running) return;
  running = false;
  clearInterval(timer);
  clearInterval(flightTimer);
  clearTimeout(interactionRenderTimer);
  process.stdin.off('data', parseTerminalInput);
  process.stdout.off('resize', draw);
  restoreKittyKeyboardMode();
  leaveTerminal();
  process.exit(0);
}

function chooseScene(name) {
  activateScene(name);
  selectedSceneIndex = name === 'cryogenic-room' ? 1 : 0;
  sceneSelectionOpen = false;
  cameraMenuOpen = false;
  debugMenuOpen = false;
  cameraDragMode = null;
  lastMousePosition = null;
  draw();
}

function handleSceneSelectionKey(event) {
  const { name } = event;
  if (name === 'escape') {
    sceneSelectionOpen = false;
    draw();
    return;
  }
  if (name === 'q') {
    close();
    return;
  }
  if (name === 'enter' || name === 'return') {
    chooseScene(selectedSceneIndex === 0 ? 'room' : 'cryogenic-room');
    return;
  }
  if (name === '1') {
    chooseScene('room');
    return;
  }
  if (name === '2') {
    chooseScene('cryogenic-room');
    return;
  }
  if (name === 'up' || name === 'w') selectedSceneIndex = 0;
  else if (name === 'down' || name === 's') selectedSceneIndex = 1;
  else return;
  draw();
}

function restart() {
  if (!running) return;
  running = false;
  clearInterval(timer);
  clearInterval(flightTimer);
  clearTimeout(interactionRenderTimer);
  process.stdin.off('data', parseTerminalInput);
  process.stdout.off('resize', draw);
  restoreKittyKeyboardMode();
  leaveTerminal();

  const result = spawnSync(process.execPath, process.argv.slice(1), {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function adjustTargetFps(amount) {
  const nextTargetFps = Math.max(1, Math.min(30, targetFps + amount));
  if (nextTargetFps === targetFps) return;
  targetFps = nextTargetFps;
  clearInterval(timer);
  timer = setInterval(draw, 1000 / targetFps);
  frameCount = 0;
  measuredFps = 0;
  fpsWindowStart = performance.now();
  draw();
}

function setCameraTargetFromEye(eye) {
  const horizontalDistance = Math.cos(cameraOrbit.elevation) * cameraOrbit.distance;
  cameraOrbit.target = {
    x: eye.x - horizontalDistance * Math.sin(cameraOrbit.azimuth),
    y: eye.y - Math.sin(cameraOrbit.elevation) * cameraOrbit.distance,
    z: eye.z - horizontalDistance * Math.cos(cameraOrbit.azimuth),
  };
}

function lookFromCurrentPosition(dx, dy) {
  const eye = cameraOrbit.eye();
  cameraOrbit.orbit(dx, dy);
  setCameraTargetFromEye(eye);
}

function moveCameraInFlight(forwardAmount, rightAmount, verticalAmount, speed) {
  const { forward, right } = cameraOrbit.basis();
  const dx = (forward.x * forwardAmount + right.x * rightAmount) * speed;
  const dy = (forward.y * forwardAmount + right.y * rightAmount + verticalAmount) * speed;
  const dz = (forward.z * forwardAmount + right.z * rightAmount) * speed;
  cameraOrbit.target = {
    x: cameraOrbit.target.x + dx,
    y: cameraOrbit.target.y + dy,
    z: cameraOrbit.target.z + dz,
  };
}

const flightDirections = {
  w: [1, 0, 0],
  s: [-1, 0, 0],
  a: [0, -1, 0],
  d: [0, 1, 0],
  e: [0, 0, 1],
  q: [0, 0, -1],
  space: [0, 0, 1],
  x: [0, 0, -1],
};

function updateFlightMovement() {
  if (cameraDragMode !== 'fly') return;
  const now = performance.now();
  const elapsed = Math.min((now - lastFlightUpdateAt) / 1000, 0.1);
  lastFlightUpdateAt = now;

  for (const [name, input] of repeatedFlightKeys) {
    if (input.expiresAt <= now) repeatedFlightKeys.delete(name);
  }

  let forward = 0;
  let right = 0;
  let vertical = 0;
  let fast = flightModifiers.size > 0;
  for (const [name, input] of [...enhancedFlightKeys, ...repeatedFlightKeys]) {
    const direction = flightDirections[name];
    if (!direction) continue;
    forward += direction[0];
    right += direction[1];
    vertical += direction[2];
    fast ||= input.shift;
  }

  if (forward === 0 && right === 0 && vertical === 0) return;
  const magnitude = Math.hypot(forward, right, vertical);
  const speed = fast ? 7.5 : 2.5;
  moveCameraInFlight(forward / magnitude, right / magnitude, vertical / magnitude, speed * elapsed);
  requestInteractionDraw();
}

function startFlight() {
  enhancedFlightKeys.clear();
  repeatedFlightKeys.clear();
  flightModifiers.clear();
  lastFlightUpdateAt = performance.now();
  clearInterval(flightTimer);
  flightTimer = setInterval(updateFlightMovement, 1000 / 30);
}

function stopFlight() {
  clearInterval(flightTimer);
  flightTimer = undefined;
  enhancedFlightKeys.clear();
  repeatedFlightKeys.clear();
  flightModifiers.clear();
}

function handleFlightInput(event) {
  if (event.ctrl || event.meta) return false;
  const direction = flightDirections[event.name];
  if (direction) {
    if (event.enhanced) {
      if (event.eventType === 'release') enhancedFlightKeys.delete(event.name);
      else enhancedFlightKeys.set(event.name, { shift: event.shift });
    } else {
      // Legacy terminal input has no key-up event. Treat repeated key presses as
      // a short lease so movement stays smooth and stops shortly after release.
      repeatedFlightKeys.set(event.name, {
        shift: event.shift,
        expiresAt: performance.now() + 140,
      });
    }
    return true;
  }

  if (event.enhanced && ['left_shift', 'right_shift'].includes(event.name)) {
    if (event.eventType === 'release') flightModifiers.delete(event.name);
    else flightModifiers.add(event.name);
    return true;
  }
  return false;
}

function onKey(event) {
  const { name, raw, shift, ctrl, meta } = event;
  if (event.enhanced) kittyKeyboardSeen = true;

  if (sceneSelectionOpen) {
    if (event.eventType !== 'release') handleSceneSelectionKey(event);
    return;
  }

  if (event.enhanced && event.eventType === 'release') {
    if (cameraMenuOpen && cameraDragMode === 'fly') handleFlightInput(event);
    return;
  }
  if (event.enhanced && event.eventType === 'repeat') {
    if (cameraMenuOpen && cameraDragMode === 'fly') handleFlightInput(event);
    return;
  }

  if (name === 'escape') {
    if (cameraMenuOpen) {
      if (cameraDragMode === 'fly') stopFlight();
      cameraMenuOpen = false;
      cameraDragMode = null;
      lastMousePosition = null;
      draw();
      return;
    }
    if (debugMenuOpen) {
      debugMenuOpen = false;
      draw();
      return;
    }
    close();
    return;
  }
  if ((name === 'q' && !cameraMenuOpen && !debugMenuOpen) || (name === 'c' && ctrl)) close();
  if (name === 'r' && shift) restart();

  if (name === 'm' && !ctrl && !meta) {
    if (cameraMenuOpen && cameraDragMode === 'fly') stopFlight();
    cameraMenuOpen = false;
    debugMenuOpen = false;
    cameraDragMode = null;
    lastMousePosition = null;
    selectedSceneIndex = sceneName === 'cryogenic-room' ? 1 : 0;
    sceneSelectionOpen = true;
    draw();
    return;
  }

  if (cameraMenuOpen && cameraDragMode === 'fly' && handleFlightInput(event)) {
    return;
  }
  if (cameraMenuOpen && cameraDragMode !== 'fly' && name === 'r' && !shift && !ctrl && !meta) {
    cameraOrbit.reset();
    requestInteractionDraw();
    return;
  }

  if (name === 'c' && !ctrl && !meta) {
    if (cameraDragMode === 'fly') stopFlight();
    cameraMenuOpen = !cameraMenuOpen;
    if (cameraMenuOpen) debugMenuOpen = false;
    cameraDragMode = null;
    lastMousePosition = null;
    draw();
    return;
  }
  if (!cameraMenuOpen && name === 'd' && !ctrl && !meta) {
    debugMenuOpen = !debugMenuOpen;
    draw();
    return;
  }
  if (name === 'space') {
    if (paused) {
      startTime = performance.now() - pausedElapsed * 1000;
      paused = false;
    } else {
      pausedElapsed = (performance.now() - startTime) / 1000;
      paused = true;
    }
    draw();
  }
  if (debugMenuOpen && (name === '-' || name === '[')) adjustTargetFps(-1);
  if (debugMenuOpen && (name === '+' || name === '=' || name === ']')) adjustTargetFps(1);
  if (debugMenuOpen && name === 'v' && !ctrl && !meta) {
    renderMode = renderMode === 'half-block' ? 'shape-glyph' : 'half-block';
    draw();
  }
}

function onMouse(event) {
  if (!cameraMenuOpen) return;

  if (event.type === 'down') {
    cameraDragMode = event.button === 0 && event.ctrl && event.meta
      ? 'pan'
      : event.button === 1
        ? 'pan'
        : event.button === 0 && event.meta
          ? 'orbit'
          : event.button === 2 && event.meta
            ? 'zoom'
            : event.button === 2
              ? 'fly'
              : null;
    lastMousePosition = { x: event.x, y: event.y };
    if (cameraDragMode === 'fly') {
      startFlight();
      const eye = cameraOrbit.eye();
      cameraOrbit.distance = 2.5;
      setCameraTargetFromEye(eye);
      requestInteractionDraw();
    }
    return;
  }
  if (event.type === 'up') {
    const wasFlying = cameraDragMode === 'fly';
    if (wasFlying) stopFlight();
    cameraDragMode = null;
    lastMousePosition = null;
    if (wasFlying) requestInteractionDraw();
    return;
  }
  if (event.type === 'drag' && cameraDragMode && lastMousePosition) {
    const dx = event.x - lastMousePosition.x;
    const dy = event.y - lastMousePosition.y;
    if (cameraDragMode === 'orbit') cameraOrbit.orbit(dx, dy);
    else if (cameraDragMode === 'zoom') cameraOrbit.zoomBy(Math.exp(dy * 0.012));
    else if (cameraDragMode === 'fly') lookFromCurrentPosition(dx, dy);
    else cameraOrbit.pan(dx, dy);
    lastMousePosition = { x: event.x, y: event.y };
    requestInteractionDraw();
    return;
  }
  if (event.type === 'wheel' && event.wheelAxis === 'vertical') {
    cameraOrbit.zoomBy(event.wheel === -1 ? 0.9 : 1.1);
    requestInteractionDraw();
  }
}

const legacyInputParser = createInputParser({ onKey, onMouse });
let pendingKittyInput = '';

function decodeKittyKey(sequence) {
  const match = /^\x1b\[(\d+)(?:;(\d+)(?::(\d+))?)?u$/.exec(sequence);
  if (!match) return null;

  const code = Number(match[1]);
  const modifier = Number(match[2] || 1);
  const modifierBits = Math.max(0, modifier - 1);
  const type = Number(match[3] || 1);
  const eventType = ({ 1: 'press', 2: 'repeat', 3: 'release' })[type] || 'press';
  const specialNames = {
    9: 'tab',
    13: 'enter',
    27: 'escape',
    32: 'space',
    127: 'backspace',
    57352: 'up',
    57353: 'down',
    57354: 'right',
    57355: 'left',
    57441: 'left_shift',
    57447: 'right_shift',
  };
  let name = specialNames[code];
  let raw = '';
  if (!name && code >= 0 && code <= 0x10ffff) {
    raw = String.fromCodePoint(code);
    name = raw.length === 1 ? raw.toLowerCase() : raw;
  }
  if (!name) return null;

  return {
    name,
    raw,
    sequence,
    shift: (modifierBits & 1) !== 0 || (raw >= 'A' && raw <= 'Z'),
    meta: (modifierBits & 2) !== 0 || (modifierBits & 32) !== 0,
    ctrl: (modifierBits & 4) !== 0,
    eventType,
    enhanced: true,
  };
}

function parseTerminalInput(chunk) {
  let input = pendingKittyInput + chunk;
  pendingKittyInput = '';
  let legacyInput = '';

  while (input.length > 0) {
    const csiAt = input.indexOf('\x1b[');
    if (csiAt < 0) {
      legacyInput += input;
      break;
    }
    legacyInput += input.slice(0, csiAt);
    input = input.slice(csiAt);

    let finalAt = -1;
    for (let index = 2; index < input.length; index++) {
      const code = input.charCodeAt(index);
      if (code >= 0x40 && code <= 0x7e) {
        finalAt = index;
        break;
      }
    }

    if (finalAt < 0) {
      if (/^\x1b\[[0-9;:]*$/.test(input)) {
        legacyInputParser(legacyInput);
        pendingKittyInput = input;
        return;
      }
      legacyInput += input;
      break;
    }

    const sequence = input.slice(0, finalAt + 1);
    if (sequence.endsWith('u')) {
      const keyEvent = decodeKittyKey(sequence);
      if (keyEvent) {
        legacyInputParser(legacyInput);
        legacyInput = '';
        onKey(keyEvent);
      } else {
        legacyInput += sequence;
      }
    } else {
      legacyInput += sequence;
    }
    input = input.slice(sequence.length);
  }

  if (legacyInput) legacyInputParser(legacyInput);
}

function restoreKittyKeyboardMode() {
  if (!kittyKeyboardModePushed) return;
  kittyKeyboardModePushed = false;
  process.stdout.write('\x1b[<u');
}

process.once('exit', restoreKittyKeyboardMode);
enterTerminal();
process.stdout.write('\x1b[>11u');
kittyKeyboardModePushed = true;
process.stdin.on('data', parseTerminalInput);
process.stdout.on('resize', draw);
draw();
timer = setInterval(draw, 1000 / targetFps);
