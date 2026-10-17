import { spawnSync } from 'node:child_process';
import { RenderTarget, toHalfBlock, toShapeGlyph } from 'ascii-arcade/engine';
import { createInputParser, enterTerminal, leaveTerminal } from 'ascii-arcade/platform';
import { Box, Button, Screen, Text, wrapText } from 'ascii-arcade/tui';
import { copyFrameToClipboard } from './frame-clipboard.mjs';
import { loadCryogenicRoom } from './cryogenic-room-state.mjs';
import { createSystemOverlay } from './system-overlay.mjs';

const room = loadCryogenicRoom();
const debugSettings = room.menus.menus.system_debug.items;
if (!process.stdin.isTTY || !process.stdout.isTTY) {
  console.error('Arcade richiede un terminale interattivo.');
  process.exit(1);
}

const View = Object.freeze({
  Wakeup: 'wakeup',
  Room: 'room',
  Capsule: 'capsule',
  Terminal: 'terminal',
  Map: 'map',
  QcAlert: 'qc-alert',
  Blackout: 'blackout',
  End: 'end',
});

const colors = {
  alert: [255, 154, 154],
  alertPanel: [120, 53, 62],
  data: [140, 231, 241],
  dataPanel: [45, 130, 144],
  good: [141, 230, 194],
  goodPanel: [57, 125, 108],
  muted: [185, 200, 213],
  text: [213, 225, 237],
  panel: [8, 13, 20],
};

let running = true;
let frameCount = 0;
let measuredFps = 0;
let fpsWindowStart = performance.now();
let targetFps = debugSettings.find(({ id }) => id === 'target_fps').default;
let renderMode = debugSettings.find(({ id }) => id === 'render_mode').default;
let paused = false;
let lastPicture = '';
let frozenPicture = '';
let clipboardMessage = '';
let clipboardMessageUntil = 0;
let target = new RenderTarget(1, 2);
let imageRect = { left: 0, top: 0, width: 1, height: 1 };
let frameRect = { left: 0, top: 0, width: 1, height: 1 };
let ui = new Screen(1, 1);
let timer;
let kittyKeyboardModePushed = false;
let pendingKittyInput = '';

const story = {
  view: View.Wakeup,
  selectedTarget: 0,
  capsuleExamined: false,
  terminalSeen: false,
  rebooted: false,
  roomMessage: [
    'RESTI SEDUTO FINCHE LA STANZA RALLENTA.',
    'LA GUARNIZIONE DELLA CAPSULA E NERA.',
    'LE ALTRE CAPSULE SONO VUOTE. SEI SOLO.',
    'IL TERMINALE LAMPEGGIA. PORTA BLOCCATA.',
  ],
};

const storyTargets = room.interactiveElements.map((element) => ({
  id: element.id,
  label: ({ capsule: 'CAPSULA', terminal: 'TERMINALE', door: 'PORTA' })[element.role] ?? element.id,
}));

function drawBackground() {
  target.clear(...room.color);

  const frameScale = Math.min(target.width / room.frameWidth, target.height / room.frameHeight);
  const frameWidth = room.frameWidth * frameScale;
  const frameHeight = room.frameHeight * frameScale;
  frameRect = {
    left: (target.width - frameWidth) / 2,
    top: (target.height - frameHeight) / 2,
    width: frameWidth,
    height: frameHeight,
  };
  const imageScale = room.fit === 'cover'
    ? Math.max(frameWidth / room.texture.width, frameHeight / room.texture.height)
    : Math.min(frameWidth / room.texture.width, frameHeight / room.texture.height);
  const imageWidth = Math.max(1, Math.round(room.texture.width * imageScale));
  const imageHeight = Math.max(1, Math.round(room.texture.height * imageScale));
  const left = Math.floor((target.width - imageWidth) / 2);
  const top = Math.floor((target.height - imageHeight) / 2);
  imageRect = { left, top, width: imageWidth, height: imageHeight };

  const pixels = target.color;
  const source = room.texture.data;
  for (let y = 0; y < imageHeight; y++) {
    const targetY = top + y;
    if (targetY < 0 || targetY >= target.height) continue;
    const sourceY = Math.min(room.texture.height - 1, Math.floor(y * room.texture.height / imageHeight));
    for (let x = 0; x < imageWidth; x++) {
      const targetX = left + x;
      if (targetX < 0 || targetX >= target.width) continue;
      const sourceX = Math.min(room.texture.width - 1, Math.floor(x * room.texture.width / imageWidth));
      const sourceIndex = (sourceY * room.texture.width + sourceX) * 4;
      const targetIndex = (targetY * target.width + targetX) * 3;
      const alpha = source[sourceIndex + 3] / 255;
      if (alpha >= 1) {
        pixels[targetIndex] = source[sourceIndex];
        pixels[targetIndex + 1] = source[sourceIndex + 1];
        pixels[targetIndex + 2] = source[sourceIndex + 2];
      } else if (alpha > 0) {
        const inverseAlpha = 1 - alpha;
        pixels[targetIndex] = source[sourceIndex] * alpha + pixels[targetIndex] * inverseAlpha;
        pixels[targetIndex + 1] = source[sourceIndex + 1] * alpha + pixels[targetIndex + 1] * inverseAlpha;
        pixels[targetIndex + 2] = source[sourceIndex + 2] * alpha + pixels[targetIndex + 2] * inverseAlpha;
      }
    }
  }

  if (!story.rebooted) {
    for (let index = 0; index < pixels.length; index++) pixels[index] *= 0.68;
  }
}

function storyPanel() {
  switch (story.view) {
    case View.Wakeup:
      return {
        title: 'RISVEGLIO // POV INGEGNERE',
        lines: [
          'IL SUONO ARRIVA PRIMA DEI PENSIERI.',
          'LA LUCE ROSSA PULSA OLTRE IL VETRO.',
          'TIRI LA LEVA. L ARIA SIBILA.',
          'LE GAMBE CEDONO. SEI SOLO.',
        ],
        accent: colors.alert,
        status: ['ALLARME', colors.alert],
        actions: [{ id: 'wakeup-continue', label: 'INVIO  GUARDA LA SALA', onClick: () => activateFooter(0) }],
        onPanelClick: () => activateFooter(0),
      };
    case View.Room:
      return {
        title: 'SALA CRIOGENICA // 1-3 O FRECCE',
        lines: story.roomMessage,
        accent: story.rebooted ? colors.goodPanel : colors.alertPanel,
        status: story.rebooted ? ['RISERVA LOCALE ATTIVA', colors.good] : ['SIRENA / SETTORE ISOLATO', colors.alert],
        actions: storyTargets.map((target, index) => ({
          id: `room-${index}`,
          label: `${index + 1}  ${target.label}`,
          selected: story.selectedTarget === index,
          onClick: () => {
            openTarget(target.id);
            draw();
          },
        })),
      };
    case View.Capsule:
      return {
        title: 'LA TUA CAPSULA',
        lines: [
          'UN FERMO DEL COPERCHIO E DEFORMATO.',
          'LA SPIA DI MANUTENZIONE LAMPEGGIA.',
          'IL DISPLAY NON MOSTRA LA CRONOLOGIA.',
          'APPOGGI LA MANO. LE DITA SI CALMANO.',
        ],
        accent: colors.alert,
        status: ['CAPSULA / ISPEZIONE', colors.alert],
        actions: [{ id: 'capsule-close', label: 'INVIO  TORNA ALLA SALA', onClick: () => activateFooter(0) }],
        onPanelClick: () => activateFooter(0),
      };
    case View.Terminal:
      return {
        title: 'TERMINALE // MESSAGGIO IN ATTESA',
        lines: [
          'REGISTRAZIONE AUDIO DEL CAPITANO.',
          'INGEGNERE. SALA MOTORI.',
          'QC STABILE. IMPIANTI VITALI ATTIVI.',
        ],
        accent: colors.dataPanel,
        status: ['TERMINALE / ARCHIVIO', colors.data],
        actions: [
          { id: 'terminal-map', label: 'M  MAPPA', onClick: () => activateFooter(0) },
          { id: 'terminal-qc', label: 'A  ALLARME QC', onClick: () => activateFooter(1) },
          { id: 'terminal-close', label: 'ESC  CHIUDI', onClick: () => activateFooter(2) },
        ],
      };
    case View.Map:
      return {
        title: 'MAPPA // SEGNALI DEI TERMINALI',
        lines: [
          'CAPITANO: CENTRO DI COMANDO',
          'PRIMO UFFICIALE: CORRIDOIO',
          'MEDICO: VERSO SALA CRIOGENICA',
          'SCIENZIATO: VICINO AL LABORATORIO',
          'SEGNALI. NON VEDI NESSUNO.',
        ],
        accent: colors.dataPanel,
        status: ['TERMINALE / MAPPA', colors.data],
        actions: [{ id: 'map-back', label: 'ESC  TORNA AL TERMINALE', onClick: () => activateFooter(0) }],
      };
    case View.QcAlert:
      return {
        title: 'QC // ALLARME ATTIVO',
        lines: [
          'ENERGIA DEI REATTORI IN CALO.',
          'RITORNO INTERROTTO.',
          'ASTEROIDI: CIRCA TRE GIORNI.',
          'STIMA ATTUALE. COLLISIONE NON CERTA.',
        ],
        accent: colors.dataPanel,
        status: ['TERMINALE / QC', colors.data],
        actions: [{ id: 'qc-back', label: 'ESC  TORNA AL TERMINALE', onClick: () => activateFooter(0) }],
      };
    case View.Blackout:
      return {
        title: 'BLACKOUT',
        lines: [
          'IL TERMINALE SI SPEGNE.',
          'UN CLIC NEL BUIO. LA SIRENA TACE.',
          'LA RISERVA LOCALE SI RIAVVIA.',
        ],
        accent: colors.alertPanel,
        status: ['SEGNALE ASSENTE', colors.alert],
        actions: [{ id: 'blackout-continue', label: 'INVIO  CONTINUA', onClick: () => activateFooter(0) }],
        onPanelClick: () => activateFooter(0),
      };
    case View.End:
      return {
        title: 'PORTA SBLOCCATA',
        lines: [
          'IL CORRIDOIO E OLTRE LA SOGLIA.',
          'IL MEDICO TI ASPETTA LI.',
          'LA SCENA DEL RISVEGLIO TERMINA QUI.',
        ],
        accent: colors.goodPanel,
        status: ['RISERVA LOCALE ATTIVA', colors.good],
        actions: [{ id: 'end-back', label: 'ESC  TORNA ALLA SALA', onClick: () => activateFooter(0) }],
        onPanelClick: () => activateFooter(0),
      };
  }
}

function focusedActionId(content) {
  if (story.view === View.Room) return `room-${story.selectedTarget}`;
  return content.actions[0]?.id ?? null;
}

function drawUi(cols, rows) {
  const content = storyPanel();
  const isWide = cols >= 56;
  const bodyWidth = Math.max(12, cols - 8);
  const bodyLines = content.lines.flatMap((line) => wrapText(line, bodyWidth));
  const actionsHeight = isWide ? 3 : content.actions.length;
  const panelHeight = Math.min(rows - 1, bodyLines.length + actionsHeight + 3);
  const actionNodes = content.actions.map((action) => {
    const selected = action.selected === true;
    const normalBg = selected ? [20, 51, 47] : [14, 23, 26];
    const normalFg = selected ? colors.good : colors.text;
    return Button({
      id: action.id,
      label: action.label,
      onClick: action.onClick,
      style: {
        width: 'auto',
        height: isWide ? 3 : 1,
        padding: [0, 1],
        border: isWide ? 'square' : 'none',
        borderColor: selected ? colors.good : content.accent,
        background: normalBg,
        color: normalFg,
        bold: true,
        hover: { background: [38, 58, 66], color: colors.text, borderColor: colors.data },
        focus: { background: [38, 58, 66], color: colors.text, borderColor: colors.data },
        pressed: { background: [66, 100, 108], color: colors.text },
      },
    });
  });
  const panelNode = Box({
    position: 'absolute',
    left: 0,
    bottom: 0,
    width: cols,
    height: panelHeight,
    padding: [0, 1],
    flexDirection: 'column',
    gap: 0,
    background: colors.panel,
    border: 'square',
    borderColor: content.accent,
    overflow: 'hidden',
  }, [
    Text({ text: content.title, style: { height: 1, color: content.accent, bold: true } }),
    ...bodyLines.map((line) => Text({ text: line, style: { height: 1, color: colors.text } })),
    Box({ flexDirection: isWide ? 'row' : 'column', gap: isWide ? 1 : 0 }, actionNodes),
  ]);
  if (content.onPanelClick) panelNode.onClick = content.onPanelClick;

  const status = Box({
    position: 'absolute',
    left: 0,
    top: 0,
    width: cols,
    height: 1,
    padding: [0, 1],
    background: story.rebooted ? [9, 23, 25] : [38, 9, 13],
  }, [Text({ text: content.status[0], style: { height: 1, color: content.status[1], bold: true } })]);
  const root = Box({ width: cols, height: rows, flexDirection: 'column', background: 'transparent', overflow: 'hidden' }, [status, panelNode]);
  ui.resize(cols, rows);
  ui.setRoot(root, { x: 0, y: 0, w: cols, h: rows });
  ui.setFocus(focusedActionId(content));
  return ui.frame();
}

function draw() {
  const cols = Math.max(30, process.stdout.columns || 80);
  const rows = Math.max(16, process.stdout.rows || 24);
  const width = cols - 1;
  const height = Math.max(16, rows - 1) * 2;
  const now = performance.now();
  let picture = paused && frozenPicture ? frozenPicture : '';

  if (!picture) {
    frameCount++;
    if (now - fpsWindowStart >= 500) {
      measuredFps = frameCount * 1000 / (now - fpsWindowStart);
      frameCount = 0;
      fpsWindowStart = now;
    }

    target.resize(width, height);
    drawBackground();
    if (story.view === View.Blackout) target.clear(2, 4, 7);

    picture = renderMode === 'half-block'
      ? toHalfBlock(target)
      : toShapeGlyph(target, width, rows - 1, { color: true, hybrid: true });
    lastPicture = picture;
  }

  if (clipboardMessage && now >= clipboardMessageUntil) clipboardMessage = '';
  const interfaceLayer = drawUi(width, rows - 1);
  process.stdout.write('\x1b[2J\x1b[H' + picture + interfaceLayer + systemOverlay.render(width));
}

function close() {
  if (!running) return;
  running = false;
  clearInterval(timer);
  process.stdin.off('data', parseTerminalInput);
  process.stdout.off('resize', draw);
  restoreKittyKeyboardMode();
  leaveTerminal();
  process.exit(0);
}

function switchScene(scriptName) {
  if (!running) return;
  running = false;
  clearInterval(timer);
  process.stdin.off('data', parseTerminalInput);
  process.stdout.off('resize', draw);
  restoreKittyKeyboardMode();
  leaveTerminal();

  const scriptPath = new URL(`./${scriptName}`, import.meta.url).pathname;
  const result = spawnSync(process.execPath, [scriptPath], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function restart() {
  if (!running) return;
  running = false;
  clearInterval(timer);
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
  const setting = debugSettings.find(({ id }) => id === 'target_fps');
  const nextTargetFps = Math.max(setting.minimum, Math.min(setting.maximum, targetFps + amount));
  if (nextTargetFps === targetFps) return;
  targetFps = nextTargetFps;
  setFrameTimer();
  frameCount = 0;
  measuredFps = 0;
  fpsWindowStart = performance.now();
}

function cycleRenderMode() {
  const setting = debugSettings.find(({ id }) => id === 'render_mode');
  const currentIndex = setting.values.indexOf(renderMode);
  renderMode = setting.values[(currentIndex + 1) % setting.values.length];
}

function setFrameTimer() {
  clearInterval(timer);
  timer = paused ? undefined : setInterval(draw, 1000 / targetFps);
}

function toggleFramePause() {
  const now = performance.now();
  if (!paused) {
    paused = true;
    frozenPicture = lastPicture;
    clearInterval(timer);
    timer = undefined;
  } else {
    paused = false;
    frozenPicture = '';
    frameCount = 0;
    measuredFps = 0;
    fpsWindowStart = now;
    setFrameTimer();
  }
}

function copyCurrentFrame() {
  const result = copyFrameToClipboard(target, {
    ...frameRect,
    outputWidth: room.frameWidth,
    outputHeight: room.frameHeight,
  });
  clipboardMessage = result.ok
    ? `FRAME COPIATO ${result.width}x${result.height} PNG`
    : `COPIA FALLITA: ${result.reason}`;
  clipboardMessageUntil = performance.now() + 3000;
}

function openTarget(id) {
  const element = room.interactiveElements.find((candidate) => candidate.id === id);
  if (element?.role === 'capsule') {
    story.selectedTarget = storyTargets.findIndex((target) => target.id === id);
    story.capsuleExamined = true;
    story.view = View.Capsule;
  } else if (element?.role === 'terminal') {
    story.selectedTarget = storyTargets.findIndex((target) => target.id === id);
    story.terminalSeen = true;
    story.view = View.Terminal;
  } else if (element?.role === 'door') {
    story.selectedTarget = storyTargets.findIndex((target) => target.id === id);
    if (story.rebooted) {
      story.view = View.End;
    } else {
      story.roomMessage = [
        'TIRI LA MANIGLIA. LA PORTA NON CEDE.',
        'SETTORE CRIOGENICO ISOLATO.',
        'SUL PANNELLO LA LUCE RESTA ROSSA.',
        'IL TERMINALE E ANCORA ACCESO.',
      ];
    }
  }
}

function closeCapsule() {
  story.view = story.terminalSeen && !story.rebooted ? View.Blackout : View.Room;
}

function closeTerminal() {
  if (story.capsuleExamined && !story.rebooted) {
    story.view = View.Blackout;
  } else {
    story.view = View.Room;
    story.roomMessage = [
      'IL MESSAGGIO DEL CAPITANO RESTA ATTIVO.',
      'PUOI RILEGGERE MAPPA E ALLARME QC.',
      'NESSUNO E VISIBILE NELLA SALA.',
      'SCEGLI UN OGGETTO DA ESAMINARE.',
    ];
  }
}

function rebootRoom() {
  story.rebooted = true;
  story.view = View.Room;
  story.roomMessage = [
    'LA RISERVA LOCALE SI RIAVVIA.',
    'SIRENA SPENTA. LUCI NORMALI DI NUOVO.',
    'LA SPIA DELLA PORTA PASSA AL VERDE.',
    'I REATTORI RESTANO IN AVARIA.',
  ];
}

function goBack() {
  switch (story.view) {
    case View.Capsule:
      closeCapsule();
      break;
    case View.Terminal:
      closeTerminal();
      break;
    case View.Map:
    case View.QcAlert:
      story.view = View.Terminal;
      break;
    case View.End:
      story.view = View.Room;
      break;
    case View.Room:
      close();
      return;
    case View.Wakeup:
      close();
      return;
    case View.Blackout:
      break;
  }
  draw();
}

function activateFooter(index = 0) {
  switch (story.view) {
    case View.Wakeup:
      story.view = View.Room;
      break;
    case View.Room:
      openTarget(storyTargets[index]?.id ?? storyTargets[0].id);
      break;
    case View.Capsule:
      closeCapsule();
      break;
    case View.Terminal:
      if (index === 0) story.view = View.Map;
      else if (index === 1) story.view = View.QcAlert;
      else closeTerminal();
      break;
    case View.Map:
    case View.QcAlert:
      story.view = View.Terminal;
      break;
    case View.Blackout:
      rebootRoom();
      break;
    case View.End:
      story.view = View.Room;
      break;
  }
  draw();
}

function onMouse(event) {
  if (systemOverlay.isOpen) {
    if (systemOverlay.handleMouse(event)) draw();
    return;
  }
  if (event.type !== 'down' || event.button !== 0) return;
  if (paused) return;
  if (event.x > ui.cols || event.y > ui.rows) return;
  const uiSurface = ui.pointerDown(event.x, event.y, event.button);
  ui.pointerUp();
  if (uiSurface) {
    draw();
    return;
  }
  if (story.view !== View.Room) return;

  const pixelX = event.x - 1;
  const pixelY = 2 * (event.y - 1) + 0.5;
  const imageX = (pixelX - imageRect.left) / imageRect.width;
  const imageY = (pixelY - imageRect.top) / imageRect.height;
  if (imageX < 0 || imageX > 1 || imageY < 0 || imageY > 1) return;
  const hotspot = room.interactiveElements.find((element) =>
    element.hit_regions.some(([x, y, w, h]) => imageX >= x && imageX <= x + w && imageY >= y && imageY <= y + h),
  );
  if (hotspot) {
    openTarget(hotspot.id);
    draw();
  }
}

function onKey(event) {
  if (event.enhanced && event.eventType !== 'press') return;
  if (systemOverlay.handleKey(event)) {
    draw();
    return;
  }
  if (event.meta) return;
  const { name, shift } = event;
  const confirm = name === 'enter' || name === 'space';
  const back = name === 'escape' || name === 'backspace';

  if (name === 'q') {
    close();
    return;
  }
  if (name === 'r' && shift) {
    restart();
    return;
  }
  if (paused) return;
  if (name === 'escape') {
    goBack();
    return;
  }
  if (ui.handleKey(event)) {
    draw();
    return;
  }
  switch (story.view) {
    case View.Wakeup:
      if (confirm) activateFooter(0);
      else if (back) close();
      break;
    case View.Room:
      if (back) {
        close();
      } else if (name === 'left' || name === 'up') {
        story.selectedTarget = (story.selectedTarget + storyTargets.length - 1) % storyTargets.length;
      } else if (name === 'right' || name === 'down') {
        story.selectedTarget = (story.selectedTarget + 1) % storyTargets.length;
      } else if (name === '1' || name === 'c') {
        openTarget(storyTargets[0].id);
      } else if (name === '2' || name === 't') {
        openTarget(storyTargets[1].id);
      } else if (name === '3' || name === 'p') {
        openTarget(storyTargets[2].id);
      } else if (confirm) {
        openTarget(storyTargets[story.selectedTarget].id);
      } else {
        return;
      }
      draw();
      break;
    case View.Capsule:
      if (confirm || back) activateFooter(0);
      break;
    case View.Terminal:
      if (name === 'm' || name === '1') {
        activateFooter(0);
        return;
      } else if (name === 'a' || name === '2') {
        activateFooter(1);
        return;
      } else if (back) closeTerminal();
      else return;
      draw();
      break;
    case View.Map:
    case View.QcAlert:
      if (confirm || back) {
        story.view = View.Terminal;
        draw();
      }
      break;
    case View.Blackout:
      if (confirm) activateFooter(0);
      break;
    case View.End:
      if (back) activateFooter(0);
      break;
  }
}

function selectScene(scene) {
  if (scene === 'test-visual-grooms') switchScene('test-visual-grooms.mjs');
  else if (scene === 'test-gameplay-action-adventure') switchScene('test-gameplay-action-adventure.mjs');
}

const systemOverlay = createSystemOverlay({
  menus: room.menus,
  getRuntimeState: () => ({ measuredFps, targetFps, renderMode, paused, clipboardMessage, clipboardMessageUntil }),
  adjustTargetFps,
  cycleRenderMode,
  toggleFramePause,
  copyFrame: copyCurrentFrame,
  reloadScene: restart,
  selectScene,
});

const legacyInputParser = createInputParser({ onKey, onMouse });

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
process.stdin.on('data', parseTerminalInput);
process.stdout.on('resize', draw);
draw();
setFrameTimer();
