import { spawnSync } from 'node:child_process';
import { encodePng } from 'ascii-arcade/engine/png';

export function copyFrameToClipboard(target, frame) {
  const { width, height, color } = target;
  const {
    left = 0,
    top = 0,
    width: frameWidth = width,
    height: frameHeight = height,
    outputWidth = frameWidth,
    outputHeight = frameHeight,
  } = frame ?? {};
  if (!Number.isInteger(width) || !Number.isInteger(height) || color.length !== width * height * 3 ||
    !Number.isFinite(left) || !Number.isFinite(top) || !Number.isFinite(frameWidth) ||
    !Number.isFinite(frameHeight) || frameWidth <= 0 || frameHeight <= 0 ||
    !Number.isInteger(outputWidth) || !Number.isInteger(outputHeight) || outputWidth <= 0 || outputHeight <= 0) {
    return { ok: false, reason: 'framebuffer non valido' };
  }

  const data = new Uint8Array(outputWidth * outputHeight * 4);
  for (let y = 0; y < outputHeight; y++) {
    const sourceY = Math.max(0, Math.min(height - 1, Math.floor(top + (y + 0.5) * frameHeight / outputHeight)));
    for (let x = 0; x < outputWidth; x++) {
      const sourceX = Math.max(0, Math.min(width - 1, Math.floor(left + (x + 0.5) * frameWidth / outputWidth)));
      const sourceIndex = (sourceY * width + sourceX) * 3;
      const targetIndex = (y * outputWidth + x) * 4;
      data[targetIndex] = color[sourceIndex];
      data[targetIndex + 1] = color[sourceIndex + 1];
      data[targetIndex + 2] = color[sourceIndex + 2];
      data[targetIndex + 3] = 255;
    }
  }

  const png = Buffer.from(encodePng({ width: outputWidth, height: outputHeight, data }));
  const commands = process.env.WAYLAND_DISPLAY
    ? [
      ['wl-copy', ['--type', 'image/png']],
      ['xclip', ['-selection', 'clipboard', '-t', 'image/png', '-i']],
    ]
    : [
      ['xclip', ['-selection', 'clipboard', '-t', 'image/png', '-i']],
      ['wl-copy', ['--type', 'image/png']],
    ];
  let available = false;

  for (const [command, args] of commands) {
    const result = spawnSync(command, args, {
      input: png,
      encoding: 'utf8',
      timeout: 2500,
      maxBuffer: 1024 * 1024,
    });
    if (result.error?.code === 'ENOENT') continue;
    available = true;
    if (!result.error && result.status === 0) return { ok: true, width: outputWidth, height: outputHeight };
  }

  return {
    ok: false,
    reason: available ? 'clipboard non raggiungibile' : 'wl-copy o xclip non installato',
  };
}
