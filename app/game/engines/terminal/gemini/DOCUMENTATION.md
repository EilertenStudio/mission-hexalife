# Gemini Engine nel terminale

Questo esempio usa `gemini-engine` come libreria Rust per disegnare la stanza
3D definita in `app/game/src/scenes/room/`. Il crate è bloccato alla versione
1.2.1 nel `Cargo.toml`; non è un eseguibile installabile dal backend Cargo di
mise. mise installa Rust, mentre Cargo risolve la libreria e le dipendenze del
programma.

Dalla radice del repository, installa Rust e avvia il task `play`:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/game/engines/terminal/gemini install

MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/game/engines/terminal/gemini run play
```

Il task usa `Cargo.lock` e richiede un terminale interattivo. Premi `c` per
aprire o chiudere i controlli della camera; il terminale deve inoltrare gli
eventi mouse per usarli. Nel menu della camera,
`Alt+sinistro` orbita, `Ctrl+Alt+sinistro` fa pan e `Alt+destro` regola lo zoom.
`Esc` chiude il menu; `q` o `Esc` escono dalla schermata principale.

La configurazione desiderata dei menu condivisi è in
[`app/game/src/scenes/room/menus.json`](../../../src/scenes/room/menus.json).
Questa implementazione offre il menu camera con orbita, pan e zoom, ma non il
volo in prima persona né il menu di debug sistema; il limite resta fissato a 6
FPS. Non sono implementati neppure i gesti alternativi di pan con il tasto
centrale e zoom con la rotella definiti nello stato condiviso.

## Differenze rispetto allo stato desiderato

Gemini Engine proietta mesh 3D nel terminale e supporta modalità wireframe,
solida e illuminata. In questa scena mantiene le quattro superfici, i quattro
bulbi colorati, la camera orbitale iniziale e l'oscillazione del cono visivo.
Il frame rate predefinito è 6 FPS.

La modalità illuminata sceglie caratteri in scala di luminosità per ogni faccia.
Le luci non hanno colore, non attenuano con la distanza e non supportano il cono
di una spotlight. L'oscillazione viene quindi resa spostando una luce puntiforme
e ruotando il cono visivo; i tre punti luce fissi restano puntiformi, ma il loro
colore non illumina le superfici. Il motore non offre blending alpha: il cono è
opaco e non equivale al fascio trasparente con opacità 0,13 dello stato
desiderato. Il clipping vicino è impostato a 0,1; il motore non espone un piano
di clipping lontano configurabile.

## Riferimenti

- [Documentazione di Gemini Engine](https://docs.rs/gemini-engine/1.2.1/gemini_engine/)
- [Esempi ufficiali 3D di Gemini Engine](https://docs.rs/crate/gemini-engine/1.2.1/source/examples/)
- [Sorgente ufficiale delle luci e della modalità illuminata](https://docs.rs/crate/gemini-engine/1.2.1/source/src/view3d/display_mode/lighting.rs)
- [Backend Rust di mise](https://mise.jdx.dev/dev-tools/backends/rust.html)
- [Backend Cargo di mise](https://mise.jdx.dev/dev-tools/backends/cargo.html)
