# Engine terminale xRenderEngine

Il task `play` compila e avvia una stanza 3D renderizzata in software da
xRenderEngine 0.2.0. `mise.toml` gestisce Rust stable e il comando ufficiale
`xre` tramite il backend Cargo di mise; il programma usa la libreria `xre-rs`,
bloccata alla stessa versione nel `Cargo.toml` e nel `Cargo.lock`.

Da una shell nella radice del repository:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/game/engines/terminal/xre install

MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/game/engines/terminal/xre run play
```

La scena riprende la stanza aperta dell'esempio Arcade: pavimento, tre pareti,
lampada centrale e tre sorgenti colorate fisse. `c` apre il menu della camera:
`Alt+sinistro` orbita, `Alt+destro` zooma e `Ctrl+Alt+sinistro` fa pan. Tenendo
premuto il tasto destro si entra nel volo in prima persona; `WASD` muove la
camera e `Space`/`X` la alzano o abbassano. Questi controlli sono attivi solo
con il menu della camera aperto; lì `q` non esce dal gioco. `d` apre il menu di
sistema, dove `[` e `]` modificano il limite degli FPS (predefinito 6). `q`
chiude il gioco dalla schermata principale, mentre `Esc` chiude un menu o esce
dalla schermata principale.

La resa non è identica alla scena Arcade: xRenderEngine 0.2.0 offre luci
puntiformi e direzionali, ma non una luce spot con cono né materiali
trasparenti. La lampada resta al centro e una luce puntiforme calda oscilla
orizzontalmente per suggerire il movimento del fascio; il fascio traslucido di
Arcade non è riprodotto.

Riferimenti tecnici: [repository xRenderEngine](https://github.com/ulpian/xRenderEngine),
[guida al rendering](https://github.com/ulpian/xRenderEngine/blob/main/docs/book/src/rendering.md),
[guida al terminale](https://github.com/ulpian/xRenderEngine/blob/main/docs/book/src/terminals.md)
e [backend Cargo di mise](https://mise.jdx.dev/dev-tools/backends/cargo.html).
