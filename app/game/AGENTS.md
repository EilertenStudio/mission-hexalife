# Regole per gli engine di gioco

## Stato desiderato della scena

- I file in `app/game/src/scenes/` sono la fonte canonica e indipendente dal motore per lo stato desiderato delle scene: geometria, oggetti, materiali, illuminazione, vista iniziale e configurazione dei menu condivisi di sistema e camera.
- Ogni implementazione dentro `app/game/engines/**` deve seguire questi file. Prima di cambiare una scena in un engine, aggiorna lo stato in `src/` e poi adatta l'implementazione.
- Non introdurre nell'engine dettagli visivi o comportamentali della scena che non siano descritti in `src/`. Il contenuto, le impostazioni e le interazioni desiderate dei menu condivisi di sistema e camera vanno definiti nei documenti della scena; layout, HUD e adattamenti dei comandi alle API dell'engine possono restare nell'implementazione.
- Se un engine non supporta una caratteristica, conserva la caratteristica nello stato desiderato e documenta in `DOCUMENTATION.md` la differenza e l'eventuale approssimazione. Non descrivere un'approssimazione come se fosse equivalente.
- Prima di aggiungere una scena a `engines/**`, crea i relativi file in `src/scenes/<nome-scena>/`.

## Formato delle scene

- Ogni cartella `src/scenes/<nome-scena>/` contiene `scene.json`, che identifica la scena e collega i suoi documenti di stato, oltre ai file specifici per geometria, luci, camera e menu condivisi quando presenti.
- I documenti sono JSON indipendente dal linguaggio, con coordinate Y-up, colori RGB interi da 0 a 255 e misure nelle unità locali della scena.
- La scena `room` è stata definita prendendo come riferimento l'implementazione Arcade. Da questo momento i file in `src/scenes/room/` descrivono lo stato desiderato; Arcade è un'implementazione di riferimento, non una seconda fonte canonica.
