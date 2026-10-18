import { spawn, spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { RenderTarget, toHalfBlock, toShapeGlyph } from 'ascii-arcade/engine';
import { decodePng } from 'ascii-arcade/engine/png';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { copyFrameToClipboard } from './frame-clipboard.mjs';
import { createSystemOverlay } from './system-overlay.mjs';

const sourceDir = new URL('../../../../assets/scenes/test-gameplay-rhythm/sources/', import.meta.url);
const readJson = (path) => JSON.parse(readFileSync(new URL(path, sourceDir), 'utf8'));
const manifest = readJson('description.json');
const music = readJson(manifest.state.music);
const audioPlayback = music.playback;
const controlsSource = readJson(manifest.state.controls);
const controls = controlsSource.keys;
const movementControls = controlsSource.movement;
const gridSource = readJson(manifest.state.grid);
const grid = gridSource.grid;
const character = readJson(manifest.state.character).player;
character.animations = JSON.parse(readFileSync(new URL(character.animations_source, sourceDir), 'utf8')).animations;
const rhythm = readJson(manifest.state.rhythm);
const visualization = readJson(manifest.state.visualization);
const menus = readJson(manifest.state.menus);
const debugSettings = menus.menus.system_debug.items;
const audioPath = fileURLToPath(new URL(music.loop_export, sourceDir));
const spriteSheet = decodePng(readFileSync(new URL(character.sprite_sheet, sourceDir)));

const [frameWidth, frameHeight] = manifest.rendering.frame_size_pixels;
const frame = new RenderTarget(frameWidth, frameHeight);
const display = new RenderTarget(1, 1);
const background = visualization.background_rgb;
const { columns, rows, cell_size_pixels: [cellWidth, cellHeight], origin_bottom_left_pixels: [gridLeft, gridBottom] } = grid;
const appearance = gridSource.appearance;
const { bar: judgmentBar, movement: rhythmMovement, judgment } = rhythm;
const [spriteWidth, spriteHeight] = character.frame_size_pixels;
const [spriteDrawWidth, spriteDrawHeight] = character.sprite_size_pixels;
const barDuration = music.time_signature[0] * 60 / music.tempo_bpm;
const beatDuration = 60 / music.tempo_bpm;
const duration = barDuration * music.bar_count;
const playerAnimation = character.animations[character.animation_playback.animation];
const directionRows = character.direction_rows_top_to_bottom;
const directions = {
  down: { dx: 0, dy: -1, row: directionRows.indexOf('down') },
  left: { dx: -1, dy: 0, row: directionRows.indexOf('left') },
  top: { dx: 0, dy: 1, row: directionRows.indexOf('top') },
  right: { dx: 1, dy: 0, row: directionRows.indexOf('right') },
};
const directionByKey = new Map(movementControls.keys.map(({ key, direction }) => [key.toLowerCase(), direction]));

if (visualization.frame_size_pixels[0] !== frameWidth ||
  visualization.frame_size_pixels[1] !== frameHeight ||
  rows * cellHeight + gridBottom > frameHeight ||
  columns * cellWidth + gridLeft > frameWidth ||
  spriteSheet.width % spriteWidth !== 0 ||
  spriteSheet.height % spriteHeight !== 0 ||
  !character.animations.walk ||
  !playerAnimation || character.animation_playback.mode !== 'continuous_loop' ||
  character.animation_playback.time_source !== 'song_clock' ||
  character.animation_playback.independent_of_movement !== true ||
  character.animation_playback.movement_effect !== 'visual_only' ||
  !Number.isInteger(rhythmMovement.maximum_moves_per_beat) || rhythmMovement.maximum_moves_per_beat < 1 ||
  !Number.isInteger(audioPlayback.minimum_volume_percent) ||
  !Number.isInteger(audioPlayback.maximum_volume_percent) ||
  audioPlayback.minimum_volume_percent < 0 || audioPlayback.maximum_volume_percent > 100 ||
  audioPlayback.minimum_volume_percent > audioPlayback.maximum_volume_percent ||
  !Number.isInteger(audioPlayback.default_volume_percent) ||
  audioPlayback.default_volume_percent < audioPlayback.minimum_volume_percent ||
  audioPlayback.default_volume_percent > audioPlayback.maximum_volume_percent ||
  !Number.isInteger(audioPlayback.volume_step_percent) || audioPlayback.volume_step_percent < 1 ||
  Object.values(directions).some(({ row }) => row < 0)) {
  throw new Error('Griglia, spritesheet e animazioni devono corrispondere al framebuffer dichiarato.');
}

let running = true;
let framePaused = false;
let frozenPicture = '';
let lastPicture = '';
let targetFps = debugSettings.find(({ id }) => id === 'target_fps').default;
let renderMode = debugSettings.find(({ id }) => id === 'render_mode').default;
let frameTimer;
let frameCount = 0;
let measuredFps = 0;
let fpsWindowStart = performance.now();
let audioPaused = false;
let audioUnavailable = false;
let audioPlayer = null;
let audioVolume = audioPlayback.default_volume_percent;
let audioGeneration = 0;
let songElapsedSeconds = 0;
let songStartedAt = performance.now();
let audioPausedBeforeFramePause = false;
let clipboardMessage = '';
let clipboardMessageUntil = 0;
let playerCell = [...character.starting_cell_bottom_left];
let playerDirection = 'down';
let movementBeatIndex = null;
let movementCountInBeat = 0;
let lastJudgment = 'READY';
let lastJudgmentUntil = 0;

function putPixel(x, yTop, color) {
  if (x < 0 || x >= frame.width || yTop < 0 || yTop >= frame.height) return;
  const index = (yTop * frame.width + x) * 3;
  frame.color[index] = color[0];
  frame.color[index + 1] = color[1];
  frame.color[index + 2] = color[2];
}

function fillRect(left, top, width, height, color) {
  for (let y = Math.max(0, top); y < Math.min(frame.height, top + height); y++) {
    for (let x = Math.max(0, left); x < Math.min(frame.width, left + width); x++) {
      putPixel(x, y, color);
    }
  }
}

function drawGrid() {
  frame.clear(...background);
  for (let row = 0; row < rows; row++) {
    const top = frameHeight - gridBottom - (row + 1) * cellHeight;
    for (let column = 0; column < columns; column++) {
      const left = gridLeft + column * cellWidth;
      const floor = (column + row) % 2 ? appearance.alternate_floor_rgb : appearance.floor_rgb;
      for (let pixelY = 0; pixelY < cellHeight; pixelY++) {
        for (let pixelX = 0; pixelX < cellWidth; pixelX++) {
          const outer =
            (column === 0 && pixelX === 0) ||
            (column === columns - 1 && pixelX === cellWidth - 1) ||
            (row === 0 && pixelY === cellHeight - 1) ||
            (row === rows - 1 && pixelY === 0);
          const gridLine = pixelX === 0 || pixelY === 0 ||
            (column === columns - 1 && pixelX === cellWidth - 1) ||
            (row === 0 && pixelY === cellHeight - 1);
          const color = outer ? appearance.outer_border_rgb :
            gridLine ? appearance.grid_line_rgb : floor;
          putPixel(left + pixelX, top + pixelY, color);
        }
      }
    }
  }
}

const baseGridColor = (() => {
  drawGrid();
  return Uint8Array.from(frame.color);
})();

function totalSongSeconds(now = performance.now()) {
  if (audioPaused) return songElapsedSeconds;
  return songElapsedSeconds + (now - songStartedAt) / 1000;
}

function currentSongSeconds(now = performance.now()) {
  return totalSongSeconds(now) % duration;
}

function playbackStatus(now) {
  const elapsed = currentSongSeconds(now);
  const barNumber = Math.floor(elapsed / barDuration) + 1;
  const beatNumber = Math.floor((elapsed % barDuration) / beatDuration) + 1;
  const audioState = audioUnavailable ? 'AUDIO UNAVAILABLE' : audioPaused ? 'PAUSED' : 'PLAYING';
  return { barNumber, beatNumber, audioState };
}

function scaleFrame(source, destination) {
  for (let y = 0; y < destination.height; y++) {
    const sourceY = Math.min(source.height - 1, Math.floor(y * source.height / destination.height));
    for (let x = 0; x < destination.width; x++) {
      const sourceX = Math.min(source.width - 1, Math.floor(x * source.width / destination.width));
      const sourceIndex = (sourceY * source.width + sourceX) * 3;
      const destinationIndex = (y * destination.width + x) * 3;
      destination.color[destinationIndex] = source.color[sourceIndex];
      destination.color[destinationIndex + 1] = source.color[sourceIndex + 1];
      destination.color[destinationIndex + 2] = source.color[sourceIndex + 2];
    }
  }
}

function setFrameRate() {
  clearInterval(frameTimer);
  frameTimer = framePaused ? undefined : setInterval(draw, 1000 / targetFps);
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
  if (!framePaused) {
    audioPausedBeforeFramePause = audioPaused;
    if (!audioPaused) setAudioPaused(true);
    framePaused = true;
    frozenPicture = lastPicture;
    clearInterval(frameTimer);
    frameTimer = undefined;
  } else {
    framePaused = false;
    if (!audioPausedBeforeFramePause && audioPaused) setAudioPaused(false);
    frozenPicture = '';
    frameCount = 0;
    measuredFps = 0;
    fpsWindowStart = now;
    setFrameRate();
  }
}

function setAudioPaused(paused) {
  const now = performance.now();
  if (paused && !audioPaused) {
    songElapsedSeconds = totalSongSeconds(now);
    audioPaused = true;
    audioPlayer?.kill('SIGSTOP');
  } else if (!paused && audioPaused) {
    songStartedAt = now;
    audioPaused = false;
    audioPlayer?.kill('SIGCONT');
  }
}

function toggleAudioPlayback() {
  setAudioPaused(!audioPaused);
}

function stopAudio() {
  audioGeneration++;
  const player = audioPlayer;
  audioPlayer = null;
  if (player && player.exitCode === null && player.signalCode === null) {
    if (audioPaused) player.kill('SIGCONT');
    player.kill('SIGTERM');
  }
}

function spawnAudioPlayer(startAtSeconds = 0) {
  const generation = audioGeneration;
  const args = ['-nodisp', '-loglevel', 'error', '-volume', String(audioVolume)];
  if (startAtSeconds > 0) args.push('-ss', String(startAtSeconds));
  args.push('-loop', '0', audioPath);
  const player = spawn('ffplay', args, { stdio: 'ignore' });
  audioPlayer = player;
  player.once('spawn', () => {
    if (audioPaused && audioPlayer === player) player.kill('SIGSTOP');
  });
  player.once('error', () => {
    if (generation !== audioGeneration || !running) return;
    audioUnavailable = true;
    audioPlayer = null;
    draw();
  });
  player.once('close', (code) => {
    if (audioPlayer === player) audioPlayer = null;
    if (generation !== audioGeneration || !running || code === 0) return;
    audioUnavailable = true;
    draw();
  });
}

function startAudio() {
  stopAudio();
  audioUnavailable = false;
  audioPaused = false;
  songElapsedSeconds = 0;
  songStartedAt = performance.now();
  playerCell = [...character.starting_cell_bottom_left];
  playerDirection = 'down';
  movementBeatIndex = null;
  movementCountInBeat = 0;
  lastJudgment = 'READY';
  lastJudgmentUntil = 0;
  spawnAudioPlayer();
}

function adjustAudioVolume(amount) {
  const nextVolume = Math.max(audioPlayback.minimum_volume_percent,
    Math.min(audioPlayback.maximum_volume_percent, audioVolume + amount));
  if (nextVolume === audioVolume) return;

  const now = performance.now();
  const songTime = totalSongSeconds(now);
  audioVolume = nextVolume;
  if (audioPlayer && !audioUnavailable) {
    stopAudio();
    songElapsedSeconds = songTime;
    songStartedAt = now;
    spawnAudioPlayer(songTime % duration);
  }
}

function copyCurrentFrame() {
  const result = copyFrameToClipboard(frame, {
    outputWidth: frameWidth,
    outputHeight: frameHeight,
  });
  clipboardMessage = result.ok
    ? `FRAME COPIATO ${result.width}x${result.height} PNG`
    : `COPIA FALLITA: ${result.reason}`;
  clipboardMessageUntil = performance.now() + 3000;
}

function recordJudgment(label, now) {
  lastJudgment = label;
  lastJudgmentUntil = now + 800;
}

function requestMovement(directionName, now = performance.now()) {
  if (audioPaused) {
    recordJudgment('PAUSED', now);
    return;
  }

  const direction = directions[directionName];
  playerDirection = directionName;
  const songTime = totalSongSeconds(now);
  const beatIndex = Math.round(songTime / beatDuration);
  const beatTime = beatIndex * beatDuration;
  const errorSeconds = Math.abs(songTime - beatTime);
  const perfectWindow = judgment.perfect_window_ms / 1000;
  const goodWindow = judgment.good_window_ms / 1000;

  if (errorSeconds > goodWindow) {
    recordJudgment('MISS', now);
    return;
  }
  if (movementBeatIndex !== beatIndex) {
    movementBeatIndex = beatIndex;
    movementCountInBeat = 0;
  }
  if (movementCountInBeat >= rhythmMovement.maximum_moves_per_beat) {
    recordJudgment('LOCKED', now);
    return;
  }

  const destination = [
    playerCell[0] + direction.dx,
    playerCell[1] + direction.dy,
  ];
  if (destination[0] < 0 || destination[0] >= columns ||
    destination[1] < 0 || destination[1] >= rows) {
    recordJudgment('BLOCKED', now);
    return;
  }

  recordJudgment(errorSeconds <= perfectWindow ? 'PERFECT' : 'GOOD', now);
  playerCell = destination;
  movementCountInBeat++;
}

function drawPlayer(now) {
  const animationSeconds = totalSongSeconds(now);
  const cycleSeconds = playerAnimation.cycle_duration_seconds;
  const frameOffset = Math.min(playerAnimation.frame_count_columns - 1,
    Math.floor((animationSeconds % cycleSeconds) / cycleSeconds * playerAnimation.frame_count_columns));
  const column = playerAnimation.start_column - 1 + frameOffset;
  const row = directions[playerDirection].row;
  const sourceLeft = column * spriteWidth;
  const sourceTop = row * spriteHeight;
  const left = Math.round(gridLeft +
    (playerCell[0] * cellWidth + (cellWidth - spriteDrawWidth) / 2));
  const top = Math.round(frameHeight -
    (gridBottom + playerCell[1] * cellHeight + (cellHeight + spriteDrawHeight) / 2));

  for (let dy = 0; dy < spriteDrawHeight; dy++) {
    const sy = sourceTop + Math.min(spriteHeight - 1,
      Math.floor(dy * spriteHeight / spriteDrawHeight));
    for (let dx = 0; dx < spriteDrawWidth; dx++) {
      const sx = sourceLeft + Math.min(spriteWidth - 1,
        Math.floor(dx * spriteWidth / spriteDrawWidth));
      const sourceIndex = (sy * spriteSheet.width + sx) * 4;
      const alpha = spriteSheet.data[sourceIndex + 3] / 255;
      if (alpha <= 0) continue;
      const x = left + dx;
      const y = top + dy;
      if (x < 0 || x >= frame.width || y < 0 || y >= frame.height) continue;
      const targetIndex = (y * frame.width + x) * 3;
      const inverseAlpha = 1 - alpha;
      frame.color[targetIndex] = spriteSheet.data[sourceIndex] * alpha +
        frame.color[targetIndex] * inverseAlpha;
      frame.color[targetIndex + 1] = spriteSheet.data[sourceIndex + 1] * alpha +
        frame.color[targetIndex + 1] * inverseAlpha;
      frame.color[targetIndex + 2] = spriteSheet.data[sourceIndex + 2] * alpha +
        frame.color[targetIndex + 2] * inverseAlpha;
    }
  }
}

function drawJudgmentBar(now) {
  const [left, bottom] = judgmentBar.position_bottom_left_pixels;
  const [width, height] = judgmentBar.size_pixels;
  const top = frameHeight - bottom - height;
  const colors = judgmentBar.colors_rgb;
  fillRect(left, top, width, height, colors.border);
  fillRect(left + 1, top + 1, width - 2, height - 2, colors.track);

  const innerWidth = width - 2;
  const innerHeight = height - 2;
  const center = left + 1 + Math.round((innerWidth - 1) / 2);
  const goodPixels = Math.max(1, Math.round(innerWidth * judgment.good_window_ms / 1000 / beatDuration));
  const perfectPixels = Math.max(1, Math.round(innerWidth * judgment.perfect_window_ms / 1000 / beatDuration));
  fillRect(center - goodPixels, top + 1, goodPixels * 2 + 1, innerHeight, colors.good_zone);
  fillRect(center - perfectPixels, top + 1, perfectPixels * 2 + 1, innerHeight, colors.perfect_zone);

  const beatPosition = totalSongSeconds(now) / beatDuration;
  const phase = beatPosition - Math.round(beatPosition) + 0.5;
  const playhead = left + 1 + Math.round(phase * (innerWidth - 1));
  const playheadColor = now < lastJudgmentUntil
    ? colors[lastJudgment.toLowerCase()] || colors.playhead
    : colors.playhead;
  fillRect(playhead, top, 1, height, playheadColor);
}

function drawGameFrame(now) {
  frame.color.set(baseGridColor);
  drawPlayer(now);
  drawJudgmentBar(now);
}

function stopScene() {
  if (!running) return;
  running = false;
  clearInterval(frameTimer);
  process.stdin.off('data', inputParser);
  process.stdout.off('resize', draw);
  stopAudio();
  leaveTerminal();
}

function close() {
  if (!running) return;
  stopScene();
  process.exit(0);
}

function launchScene(scene, reload = false) {
  const implementations = {
    [manifest.id]: fileURLToPath(import.meta.url),
    'test-gameplay-action-adventure': fileURLToPath(new URL('./test-gameplay-action-adventure.mjs', import.meta.url)),
  };
  const entry = implementations[scene];
  if (!entry || (!reload && scene === manifest.id)) return;
  stopScene();
  const result = spawnSync(process.execPath, [entry], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function reloadScene() {
  launchScene(manifest.id, true);
}

function selectScene(scene) {
  launchScene(scene);
}

function onKey(event) {
  if (systemOverlay.handleKey(event)) {
    draw();
    return;
  }
  if (event.meta || event.ctrl) return;
  const key = String(event.name).toLowerCase();
  if (key === controls.quit[0] || key === controls.quit[1]) {
    close();
    return;
  }
  if (key === controls.toggle_playback[0]) toggleAudioPlayback();
  else if (key === controls.restart_loop[0]) startAudio();
  else if (controls.volume_up.includes(key)) adjustAudioVolume(audioPlayback.volume_step_percent);
  else if (controls.volume_down.includes(key)) adjustAudioVolume(-audioPlayback.volume_step_percent);
  else if (directionByKey.has(key)) requestMovement(directionByKey.get(key));
  draw();
}

function draw(now = performance.now()) {
  if (!running) return;
  const terminalColumns = Math.max(1, process.stdout.columns || 80);
  const terminalRows = Math.max(12, process.stdout.rows || 24);
  let picture = framePaused && frozenPicture ? frozenPicture : '';
  const status = playbackStatus(now);
  if (!picture) {
    drawGameFrame(now);
    frameCount++;
    if (now - fpsWindowStart >= 500) {
      measuredFps = frameCount * 1000 / (now - fpsWindowStart);
      frameCount = 0;
      fpsWindowStart = now;
    }
    const maxWidth = Math.max(1, (terminalColumns - 1) * 2);
    const maxHeight = Math.max(1, (terminalRows - 2) * 2);
    const scale = Math.min(maxWidth / frameWidth, maxHeight / frameHeight);
    const outputWidth = Math.max(1, Math.round(frameWidth * scale));
    const outputHeight = Math.max(1, Math.round(frameHeight * scale));
    display.resize(outputWidth, outputHeight);
    scaleFrame(frame, display);
    picture = renderMode === 'half-block'
      ? toHalfBlock(display)
      : toShapeGlyph(display, outputWidth, Math.ceil(outputHeight / 2), { color: true, hybrid: true });
    lastPicture = picture;
  }
  if (clipboardMessage && now >= clipboardMessageUntil) clipboardMessage = '';
  const bar = String(status.barNumber).padStart(2, '0');
  const beat = String(status.beatNumber).padStart(2, '0');
  const keyLabel = (key) => ({ space: 'SPACE', pageup: 'PGUP', pagedown: 'PGDN' })[key] || key.toUpperCase();
  const controlHelp = [
    `${controls.toggle_playback.map(keyLabel).join('/')} PLAY/PAUSE`,
    `${controls.restart_loop.map(keyLabel).join('/')} RESTART`,
    `${controls.volume_up.map(keyLabel).join('/')} / ${controls.volume_down.map(keyLabel).join('/')} VOLUME`,
    `${controls.quit.map(keyLabel).join('/')} QUIT`,
  ].join('  ');
  const judgmentLabel = now < lastJudgmentUntil ? lastJudgment : 'READY';
  const help = `${music.tempo_bpm} BPM // ${music.key.toUpperCase()} // VOL ${audioVolume}% // BAR ${bar} BEAT ${beat} // ${status.audioState} // ${judgmentLabel} // K/J/I/L MOVE // ${controlHelp}`;
  process.stdout.write('\x1b[2J\x1b[H' + picture + '\n' + help + systemOverlay.render(terminalColumns));
}

const systemOverlay = createSystemOverlay({
  menus,
  getRuntimeState: () => ({ measuredFps, targetFps, renderMode, paused: framePaused, clipboardMessage, clipboardMessageUntil }),
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
startAudio();
draw();
setFrameRate();
