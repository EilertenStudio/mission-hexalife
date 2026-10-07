# Regole del progetto

- `.local/` è la cartella designata per mantenere in locale il runtime dei devtool.
- `.local/mise/{cache,state,data}` contiene rispettivamente cache, stato e dati installati di mise.
- Prima di invocare mise, impostare `MISE_CACHE_DIR`, `MISE_STATE_DIR` e `MISE_DATA_DIR` sui relativi percorsi sotto `.local/mise/`. Sono variabili di avvio e non vanno configurate con `[env]` in `mise.toml`.
