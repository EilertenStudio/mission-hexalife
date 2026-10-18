const toKey = (key) => String(key ?? '').toLowerCase();

export function createSystemOverlay({
  menus,
  getRuntimeState,
  adjustTargetFps,
  cycleRenderMode,
  toggleFramePause,
  copyFrame,
  reloadScene,
  selectScene,
}) {
  const prefix = menus?.shortcut_prefix;
  const systemMenus = menus?.menus;
  const debugMenu = systemMenus?.system_debug;
  const sceneMenu = systemMenus?.scene_select;
  const fpsSetting = debugMenu?.items.find(({ id }) => id === 'target_fps');
  const renderSetting = debugMenu?.items.find(({ id }) => id === 'render_mode');
  const pauseAction = debugMenu?.items.find(({ id }) => id === 'frame_pause');
  const commandKey = (command) => Object.entries(prefix?.commands ?? {})
    .find(([, value]) => value === command)?.[0];

  if (!prefix?.keys?.length || !debugMenu || !sceneMenu || !fpsSetting ||
    !renderSetting || !pauseAction || !commandKey('frame_copy')) {
    throw new Error('Configurazione incompleta per l’overlay di sistema Arcade.');
  }

  const prefixLabel = prefix.keys[0].toUpperCase();
  let activeMenu = null;

  function open(menu) {
    activeMenu = menu;
  }

  function close() {
    activeMenu = null;
  }

  function shortcutLines() {
    const commands = Object.entries(prefix.commands);
    const labels = {
      system_debug: debugMenu.title.toUpperCase(),
      scene_select: sceneMenu.title.toUpperCase(),
      scene_reload: 'RICARICA SCENA',
      frame_copy: 'COPIA FRAME',
    };
    const callbacks = {
      system_debug: () => open('system_debug'),
      scene_select: () => open('scene_select'),
      scene_reload: reloadScene,
      frame_copy: copyFrame,
    };
    const rows = [{ text: `ARCADE // ${prefixLabel}` }];
    for (const [key, command] of commands) {
      if (!labels[command] || !callbacks[command]) continue;
      rows.push({
        text: `${key.toUpperCase()}  ${labels[command]}`,
        action: callbacks[command],
      });
    }
    const state = getRuntimeState();
    if (state.clipboardMessage && performance.now() < state.clipboardMessageUntil) {
      rows.push({ text: state.clipboardMessage });
    }
    rows.push({ text: 'ESC  CHIUDI', action: close });
    return rows;
  }

  function debugLines() {
    const state = getRuntimeState();
    const decreaseKeys = fpsSetting.adjustment_keys.decrease.map((key) => key.toUpperCase()).join('/');
    const increaseKeys = fpsSetting.adjustment_keys.increase.map((key) => key.toUpperCase()).join('/');
    return [
      { text: `${debugMenu.title.toUpperCase()} // ESC CHIUDE` },
      { text: `FPS EFFETTIVI: ${Number(state.measuredFps).toFixed(1)}` },
      {
        text: `${decreaseKeys} / ${increaseKeys}  ${fpsSetting.label.toUpperCase()}: ${state.targetFps}`,
        action: 'adjust_fps',
      },
      {
        text: `${renderSetting.cycle_key.toUpperCase()}  ${renderSetting.label.toUpperCase()}: ${String(state.renderMode).toUpperCase()}`,
        action: cycleRenderMode,
      },
      {
        text: `${pauseAction.key.toUpperCase()}  ${pauseAction.label.toUpperCase()}  [${state.paused ? 'IN PAUSA' : 'ATTIVO'}]`,
        action: toggleFramePause,
      },
      { text: 'ESC  CHIUDI', action: close },
    ];
  }

  function sceneLines() {
    return [
      { text: `${sceneMenu.title.toUpperCase()} // ESC CHIUDE` },
      ...sceneMenu.items.map((item) => ({
        text: `${item.key.toUpperCase()}  ${item.label.toUpperCase()}`,
        action: () => {
          close();
          selectScene(item.scene);
        },
      })),
      { text: 'ESC  CHIUDI', action: close },
    ];
  }

  function getLines() {
    if (activeMenu === 'shortcut_prefix') return shortcutLines();
    if (activeMenu === 'system_debug') return debugLines();
    if (activeMenu === 'scene_select') return sceneLines();
    return [];
  }

  function panelWidth(lines, columns = process.stdout.columns || 80) {
    return Math.min(columns, Math.max(24, ...lines.map(({ text }) => text.length)) + 2);
  }

  function executeShortcut(key) {
    const command = prefix.commands[toKey(key)];
    if (!command) return false;
    if (command === 'system_debug') open('system_debug');
    else if (command === 'scene_select') open('scene_select');
    else if (command === 'scene_reload') reloadScene();
    else if (command === 'frame_copy') copyFrame();
    else return false;
    return true;
  }

  function handleKey(event) {
    if (event.enhanced && event.eventType !== 'press') return false;
    if (event.meta) return false;
    const key = toKey(event.name);
    const prefixKey = toKey(prefix.keys[0].replace(/^ctrl\+/, ''));

    if (event.ctrl && key === prefixKey) {
      open('shortcut_prefix');
      return true;
    }
    if (!activeMenu) return false;

    if (key === 'escape') {
      close();
      return true;
    }
    if (activeMenu === 'shortcut_prefix') {
      executeShortcut(key);
      return true;
    }
    if (activeMenu === 'scene_select') {
      const item = sceneMenu.items.find((candidate) => toKey(candidate.key) === key);
      if (item) {
        close();
        selectScene(item.scene);
      }
      return true;
    }
    if (activeMenu === 'system_debug') {
      if (key === toKey(pauseAction.key)) toggleFramePause();
      else if (fpsSetting.adjustment_keys.decrease.some((candidate) => toKey(candidate) === key)) {
        adjustTargetFps(-fpsSetting.step);
      } else if (fpsSetting.adjustment_keys.increase.some((candidate) => toKey(candidate) === key)) {
        adjustTargetFps(fpsSetting.step);
      } else if (key === toKey(renderSetting.cycle_key)) cycleRenderMode();
      return true;
    }
    return false;
  }

  function handleMouse(event) {
    if (!activeMenu || event.type !== 'down' || event.button !== 0) return false;
    const lines = getLines();
    const width = panelWidth(lines);
    if (event.x > width || event.y > lines.length) return true;
    const line = lines[event.y - 1];
    if (line?.action === 'adjust_fps') {
      const middle = Math.max(1, Math.floor(width / 2));
      adjustTargetFps(event.x <= middle ? -fpsSetting.step : fpsSetting.step);
    } else if (typeof line?.action === 'function') {
      line.action();
    }
    return true;
  }

  function render(columns) {
    if (!activeMenu) return '';
    const lines = getLines();
    const width = panelWidth(lines, columns);
    return lines.map(({ text }, index) => {
      const clipped = text.slice(0, Math.max(0, width - 2));
      const padding = ' '.repeat(Math.max(0, width - clipped.length - 2));
      const color = index === 0 ? '38;2;140;231;241' : '38;2;213;225;237';
      return `\x1b[${index + 1};1H\x1b[48;2;8;13;20m\x1b[${color}m ${clipped}${padding} \x1b[0m`;
    }).join('');
  }

  return {
    handleKey,
    handleMouse,
    render,
    close,
    get isOpen() {
      return activeMenu !== null;
    },
  };
}
