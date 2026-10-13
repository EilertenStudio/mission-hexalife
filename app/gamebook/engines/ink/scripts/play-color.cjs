const fs = require("node:fs");
const path = require("node:path");
const readline = require("node:readline/promises");

const storyPath = process.argv[2];
const inkjsPath = process.argv[3];

if (!storyPath || !inkjsPath) {
  process.stderr.write("Uso: node play-color.cjs <story.json> <percorso-inkjs>\n");
  process.exit(2);
}

const { Story } = require(path.resolve(inkjsPath));
const checkpoints = require("./checkpoints.js");
const storyJson = fs.readFileSync(storyPath, "utf8").replace(/^\uFEFF/, "");
const checkpointIds = checkpoints.map((checkpoint) => checkpoint.id).join(", ");
const initialCheckpoint = process.env.HEXALIFE_START || "inizio";
let story;

function loadCheckpoint(id) {
  const checkpoint = checkpoints.find((item) => item.id === id);
  if (!checkpoint) throw new Error(`Checkpoint sconosciuto: ${id}. Disponibili: ${checkpointIds}`);
  const nextStory = new Story(storyJson);
  for (const [name, value] of Object.entries(checkpoint.setup)) {
    nextStory.variablesState.$(name, value);
  }
  if (checkpoint.path) nextStory.ChoosePathString(checkpoint.path);
  story = nextStory;
  return checkpoint;
}
const terminalSupportsColor = process.env.FORCE_COLOR === "1" || (
  process.stdout.isTTY && !("NO_COLOR" in process.env) && process.env.TERM !== "dumb"
);

const colors = {
  reset: "\x1b[0m",
  dim: "\x1b[2m",
  bold: "\x1b[1m",
  narrative: "\x1b[38;5;110m",
  qc: "\x1b[38;5;51m",
  alarm: "\x1b[38;5;196m",
  status: "\x1b[38;5;245m",
  choiceCost: "\x1b[38;5;220m",
  choiceFree: "\x1b[38;5;82m",
  captain: "\x1b[38;5;208m",
  officer: "\x1b[38;5;212m",
  doctor: "\x1b[38;5;79m",
  scientist: "\x1b[38;5;141m",
  engineer: "\x1b[38;5;230m",
};

function paint(text, ...codes) {
  if (!terminalSupportsColor || !text) return text;
  return `${codes.map((code) => colors[code]).join("")}${text}${colors.reset}`;
}

const roleColors = {
  capitano: "captain",
  "primo ufficiale": "officer",
  ufficiale: "officer",
  medico: "doctor",
  scienziato: "scientist",
  ingegnere: "engineer",
};
const roleReferences = /(\b(?:Primo Ufficiale|Capitano|Ufficiale|Medico|Scienziato|Ingegnere)\b)/gi;

function paintReferences(text, ...baseCodes) {
  return text.split(roleReferences)
    .map((part) => {
      const roleColor = roleColors[part.toLowerCase()];
      return roleColor ? paint(part, roleColor) : paint(part, ...baseCodes);
    })
    .join("");
}

function renderLine(text, tags) {
  const trimmed = text.trimEnd();
  if (!trimmed) return "";
  const character = tags.find((tag) => tag.startsWith("char:"))?.slice(5);
  if (character) {
    const color = roleColors[character];
    if (color) {
      return trimmed.split(/(«[^»]*»)/g)
        .map((part) => paintReferences(part, part.startsWith("«") ? color : "narrative"))
        .join("");
    }
  }

  const uiRole = tags.find((tag) => tag.startsWith("ui:"))?.slice(3);
  const uiPalette = {
    qc: ["qc"],
    allarme: ["alarm", "bold"],
    stato: ["status", "dim"],
    scelta_gratuita: ["choiceFree"],
    scelta_turno: ["choiceCost"],
  };
  return paintReferences(trimmed, ...(uiPalette[uiRole] || ["narrative"]));
}

function renderChoice(choice, index) {
  const label = choice.text.trim();
  const costsTurn = /\b(?:un|due|tre|\d+)\s+turn[oi]\b/i.test(label);
  return `${paint(`${index + 1}.`, "bold")} ${paintReferences(label, costsTurn ? "choiceCost" : "choiceFree")}`;
}

async function play() {
  const input = readline.createInterface({ input: process.stdin, output: process.stdout });
  let blankLine = true;

  function separate() {
    if (!blankLine) {
      process.stdout.write("\n");
      blankLine = true;
    }
  }

  try {
    const startingPoint = loadCheckpoint(initialCheckpoint);
    process.stdout.write(`${paint(`Checkpoint: ${startingPoint.label}`, "status")} · :scene per l'elenco, :jump <id> per saltare, q per uscire.\n`);
    while (true) {
      while (story.canContinue) {
        const line = story.Continue();
        const rendered = renderLine(line, story.currentTags);
        if (!rendered) {
          separate();
          continue;
        }
        separate();
        process.stdout.write(`${rendered}\n`);
        blankLine = false;
      }

      const choices = story.currentChoices;
      separate();
      if (choices.length === 0) {
        process.stdout.write("Fine della prova. Usa :scene o :jump <id> per ripartire, q per uscire.\n");
      } else {
        for (const [index, choice] of choices.entries()) {
          process.stdout.write(`${renderChoice(choice, index)}\n`);
        }
      }
      blankLine = false;

      let selected = -1;
      let jumped = false;
      while (selected < 0 && !jumped) {
        const answer = (await input.question(paint("> ", "qc"))).trim();
        if (answer.toLowerCase() === "q") return;
        if (answer.toLowerCase() === ":scene") {
          for (const checkpoint of checkpoints) {
            process.stdout.write(`  ${checkpoint.id.padEnd(12)} ${checkpoint.label}\n`);
          }
          continue;
        }
        if (answer.toLowerCase().startsWith(":jump")) {
          const id = answer.slice(5).trim().toLowerCase();
          const checkpoint = checkpoints.find((item) => item.id === id);
          if (!checkpoint) {
            process.stdout.write(`Indica un checkpoint valido. Disponibili: ${checkpointIds}\n`);
            continue;
          }
          loadCheckpoint(id);
          process.stdout.write(`\n${paint(`Checkpoint: ${checkpoint.label}`, "status")}\n`);
          jumped = true;
          blankLine = false;
          continue;
        }
        const number = Number(answer);
        if (choices.length && Number.isInteger(number) && number >= 1 && number <= choices.length) {
          selected = number - 1;
        } else {
          process.stdout.write("Scegli un numero mostrato, :scene per i checkpoint, oppure q per uscire.\n");
        }
      }
      if (jumped) continue;
      story.ChooseChoiceIndex(selected);
      separate();
    }
  } finally {
    input.close();
  }
}

play().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
