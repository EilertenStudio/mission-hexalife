# Stato desiderato delle scene

Questa cartella contiene lo stato desiderato, indipendente dal motore, delle
scene di gioco. I progetti sotto `app/game/engines/` traducono questi dati
nell'API e nelle capacità di ciascun engine.

## Convenzioni

- Ogni scena vive in `scenes/<nome-scena>/` e ha un `scene.json` che ne dichiara
  l'identità e i documenti che la compongono.
- I documenti sono JSON UTF-8, leggibili sia dagli engine JavaScript sia da
  quelli Rust o Go. Le distanze sono unità locali senza conversione implicita;
  l'asse verticale è Y e i colori sono RGB interi nell'intervallo 0–255.
- `geometry.json` descrive le superfici, gli oggetti visibili e i materiali;
  `lighting.json` descrive luce ambientale, sorgenti e animazioni; `camera.json`
  descrive la vista iniziale e i parametri di proiezione; `menus.json` definisce
  contenuto, impostazioni e interazioni desiderate per i menu condivisi di
  sistema e camera.
- I menu di sistema descrivono impostazioni runtime come il limite degli FPS;
  il menu camera descrive solo modalità e navigazione della camera. Gli engine
  possono adattare il layout alle proprie API, ma devono mantenere le azioni e
  i comandi definiti; le differenze non supportate vanno documentate.
- I valori sono lo stato voluto della scena, non una promessa che ogni engine
  supporti tutte le caratteristiche. Le differenze e le approssimazioni degli
  engine vanno indicate nella documentazione dell'engine.

La scena `room` è stata ricavata dalla scena di Arcade presente nel repository.
La sua definizione in `scenes/room/` è ora il riferimento da seguire quando si
aggiorna o si replica la scena in un engine.
