const fs = require("node:fs");

const [source, target] = process.argv.slice(2);
if (!source || !target) {
  process.stderr.write("Uso: node story-to-js.cjs <story.json> <story.js>\n");
  process.exit(2);
}

const storyJson = fs.readFileSync(source, "utf8").replace(/^\uFEFF/, "");
fs.writeFileSync(target, `window.storyContent = ${JSON.stringify(storyJson)};\n`);
