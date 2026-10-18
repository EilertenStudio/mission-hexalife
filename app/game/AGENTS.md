# Regole per gli engine di gioco

## Stato desiderato della scena

- I file in `app/game/assets/scenes/<nome-scena>/sources/` sono la fonte canonica e indipendente dal motore per lo stato desiderato delle scene: descrizione, geometria, oggetti, materiali, illuminazione, vista iniziale, controlli e configurazione dei menu condivisi.
- Ogni implementazione dentro `app/game/engines/**` deve seguire questi file. Prima di cambiare una scena in un engine, aggiorna lo stato in `assets/scenes/<nome-scena>/sources/` e poi adatta l'implementazione.
- Non introdurre nell'engine dettagli visivi o comportamentali della scena che non siano descritti nei file di `sources/`. Il contenuto, le impostazioni e le interazioni desiderate dei menu condivisi di sistema e camera vanno definiti nei documenti della scena; layout, HUD e adattamenti dei comandi alle API dell'engine possono restare nell'implementazione.
- Se un engine non supporta una caratteristica, conserva la caratteristica nello stato desiderato e documenta in `DOCUMENTATION.md` la differenza e l'eventuale approssimazione. Non descrivere un'approssimazione come se fosse equivalente.
- Prima di aggiungere una scena a `engines/**`, crea i relativi file in `assets/scenes/<nome-scena>/sources/`, incluso `description.json`.

## Formato delle scene

- Ogni cartella `assets/scenes/<nome-scena>/` organizza il soggetto in `concepts/`, `references/`, `exports/` e `sources/`. `sources/description.json` identifica la scena e collega i suoi documenti di stato, oltre ai file specifici per geometria, luci, camera, controlli e menu quando presenti.
- I documenti sono JSON indipendente dal linguaggio, con coordinate Y-up, colori RGB interi da 0 a 255 e misure nelle unità locali della scena.
- `test-gameplay-rhythm` è la scena predefinita di Arcade; `test-gameplay-action-adventure` resta disponibile dal selettore scena. Arcade è l'implementazione di riferimento, non una seconda fonte canonica.
