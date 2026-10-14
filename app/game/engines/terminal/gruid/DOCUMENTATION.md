# Engine terminale Gruid

`mise.toml` installa Go 1.27.2 e offre il task `play`. Le dipendenze Go sono
dichiarate in `go.mod` e verificate con `go.sum`: Gruid v0.28.0 e il driver
terminale `gruid-tcell` v0.5.0. Il driver è scritto in Go puro e non richiede
librerie native da installare separatamente.

Da una shell nella radice del repository:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/game/engines/terminal/gruid run play
```

Il programma richiede un terminale interattivo di almeno 28x16 celle. Muovi
`@` con le frecce o `WASD`, raccogli le tre stelle `*` e aggira i muri `#`.
Premi `r` per ricominciare e `q` o `Esc` per uscire. Questo esempio è autonomo
e non usa contenuti del gamebook.
