# Ink

## Guide ufficiali

- [Repository ufficiale di Ink](https://github.com/inkle/ink): compilatore `inklecate`, formato e istruzioni CLI nel README.
- [Writing with Ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md): guida alla sintassi, alle scelte, ai knot e alle variabili.
- [Running your Ink](https://github.com/inkle/ink/blob/master/Documentation/RunningYourInk.md): esecuzione della storia e compilazione dei file `.ink` in JSON da terminale.
- [Inky](https://github.com/inkle/inky): editor/preview ufficiale per Ink.

## Esempi e risorse

- [ink-library](https://github.com/inkle/ink-library): raccolta di snippet, storie complete e progetti che usano Ink.
- [The Intercept](https://github.com/inkle/the-intercept): progetto open source di esempio realizzato da inkle.

## Prima prova giocabile

- [story.ink](story.ink) contiene l'apertura giocabile, dal risveglio dell'Ingegnere alla manovra sugli asteroidi. Il turno di sei ore e la scadenza al dodicesimo turno sono parametri di prova, non decisioni canoniche.
- Dalla radice del progetto, con i runtime mise tenuti in `.local/` come richiesto da `AGENTS.md`:

  ```sh
  MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" MISE_CACHE_DIR="$PWD/.local/mise/cache" MISE_STATE_DIR="$PWD/.local/mise/state" MISE_DATA_DIR="$PWD/.local/mise/data" mise -C app/gamebook run --raw --skip-tools play
  ```

Il task `play` compila la storia con l'`inklecate` della toolchain e la esegue nel terminale con un renderer a colori basato su [inkjs](https://github.com/y-lohse/inkjs). L'introduzione spiega le regole e i colori delle informazioni di gioco. Per scegliere un'azione si digita il suo numero; `q` chiude la partita.

Il renderer usa colori ANSI a 256 tonalità: grigio azzurro per la narrazione, ciano per il QC, rosso per gli allarmi, grigio attenuato per lo stato della nave, giallo per le scelte che consumano un turno e verde per quelle che non lo consumano. I personaggi hanno colori distinti; quando un ruolo compare nella narrazione o in una scelta, il colore si applica soltanto al nome del ruolo.

### Checkpoint per la revisione

Durante `play`, digita `:scene` per vedere le sezioni disponibili e `:jump ponte` (o un altro ID mostrato) per saltarci. Per iniziare direttamente da una sezione, imposta `HEXALIFE_START` prima del comando, per esempio:

```sh
HEXALIFE_START=ponte MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" MISE_CACHE_DIR="$PWD/.local/mise/cache" MISE_STATE_DIR="$PWD/.local/mise/state" MISE_DATA_DIR="$PWD/.local/mise/data" mise -C app/gamebook run --raw --skip-tools play
```

I checkpoint disponibili sono `inizio`, `risveglio`, `medico`, `motori`, `silenzio`, `ponte`, `corpo` e `asteroidi`. Ogni salto avvia una nuova partita con valori preimpostati per tempo, energia e indizi pertinenti. Non conserva le decisioni prese prima del salto: serve a rivedere una sezione in modo riproducibile. Le configurazioni sono in [scripts/checkpoints.js](scripts/checkpoints.js).

`MISE_GLOBAL_CONFIG_FILE` evita che mise carichi i tool configurati globalmente nell'ambiente; `--skip-tools` evita installazioni durante l'avvio. Alla prima esecuzione il task installa la versione bloccata di `inkjs` in `.local/gamebook/ink-cli/`, con cache npm in `.local/npm/cache`, poi riusa i file locali. I colori sono attivi anche se l'ambiente imposta `NO_COLOR`.

## Esportazione web

Dalla radice del progetto:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" MISE_CACHE_DIR="$PWD/.local/mise/cache" MISE_STATE_DIR="$PWD/.local/mise/state" MISE_DATA_DIR="$PWD/.local/mise/data" mise -C app/gamebook run --raw --skip-tools export-web
```

Il task genera `app/gamebook/dist/index.html` insieme al runtime `ink.js`, alla storia compilata `story.js` e ai checkpoint in `checkpoints.js`. Apri `index.html` direttamente nel browser; la pagina funziona senza server e mantiene i colori delle scelte e dei messaggi. Il selettore in alto salta a un checkpoint. Per iniziare da una sezione tramite URL, aggiungi il suo ID dopo `#`, per esempio `index.html#ponte`. Per condividere il gioco, copia insieme tutti e quattro i file della cartella `dist/`.
