# Regole del progetto

- `.local/` è la cartella designata per mantenere in locale il runtime dei devtool.
- `.local/mise/{cache,state,data}` contiene rispettivamente cache, stato e dati installati di mise.
- Prima di invocare mise, impostare `MISE_CACHE_DIR`, `MISE_STATE_DIR` e `MISE_DATA_DIR` sui relativi percorsi sotto `.local/mise/`. Sono variabili di avvio e non vanno configurate con `[env]` in `mise.toml`.

## Storia in `app/gamebook/`

- Usa `app/gamebook/NOTE.md` come riferimento per i fatti approvati della storia. I punti `TBD` sono aperti: non completarli con supposizioni presentandole come canoniche.
- Usa `app/gamebook/CHARACTERS.md` per profili e voci. Distingui ciò che è confermato dalle ipotesi da provare. I tratti sorteggiati restano provvisori finché non vengono approvati.
- Usa `app/gamebook/REFERENCES.md` come supporto alla ricerca e fonte d’ispirazione. I riferimenti possono informare le proposte, ma non stabiliscono fatti della storia e non vanno copiati.
- Segui `app/gamebook/ROADMAP.md` per il processo di scrittura: definisci prima una struttura semplice e lineare, poi espandila progressivamente nelle scene.
- Prima di portare una nuova decisione narrativa in un engine, aggiorna il documento di riferimento: registra i fatti approvati in `NOTE.md`, i cambiamenti dei profili in `CHARACTERS.md` e le proposte ancora da valutare in `ROADMAP.md`.
- Tratta i file degli engine come implementazioni della storia, non come fonte autonoma del canone. Mantieni coerenti eventi, prospettiva, ruoli e informazioni approvati; adatta la forma tecnica al motore scelto.
- Se una scena richiede una decisione ancora aperta o contraddice i documenti, conserva il `TBD` e segnalalo invece di risolverlo implicitamente.
- Consulta il `DOCUMENTATION.md` dell’engine per le istruzioni tecniche, mantenendo separate le regole del motore dalle decisioni narrative.
