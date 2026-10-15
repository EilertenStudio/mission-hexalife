# Arcade: guida generale all'engine

Questa applicazione usa le API pubbliche di `ascii-arcade` per disegnare scene
3D in un terminale. L'engine è un renderer software: esegue i calcoli sulla CPU
e non richiede una GPU.

## Flusso di rendering

Il gioco descrive una scena con oggetti 3D, geometrie, materiali e una camera.
Ad ogni fotogramma aggiorna lo stato necessario, poi `SceneRenderer` proietta la
scena nel `RenderTarget`, un buffer di pixel. Il renderer gestisce la proiezione
prospettica, la profondità e i materiali; il codice del gioco può fornire
materiali personalizzati per determinare come le superfici reagiscono alla
luce.

Il presenter converte il buffer in caratteri, glifi e colori ANSI. In questo
modo l'immagine 3D diventa un'uscita che un terminale può mostrare. Il modulo
`ascii-arcade/platform` gestisce l'interazione con il terminale, come la
modalità di input e il ripristino dello schermo all'uscita.

Il ciclo di gioco, le animazioni, i comandi e le regole restano responsabilità
dell'applicazione. In questo esempio il codice importa `ascii-arcade/engine` e
`ascii-arcade/platform` direttamente; non avvia la CLI completa di Arcade.
La configurazione desiderata dei menu condivisi di debug e camera è definita
in [`app/game/src/scenes/room/menus.json`](../../../src/scenes/room/menus.json).
`Esc` chiude il menu attivo; `q` o `Esc` escono solo quando entrambi i menu
sono chiusi.

Il task `play` avvia `sandbox-room`. Premi `m` durante il
gioco per aprire il selettore: `1` avvia `room`, `2` `cryogenic-room`, `3`
`sandbox-room`. `Esc` torna alla scena attiva e `q` esce. I task `play:room`,
`play:cryogenic-room` avviano direttamente le rispettive scene.

Dalla root dell’engine si avvia con `mise run play`; dalla root di `app/game`
con `mise run arcade:play`, oppure dalla root del repository con
`mise run game arcade:play`.

La `sandbox-room` carica i dati canonici da
[`app/game/src/scenes/sandbox-room/`](../../../src/scenes/sandbox-room/): il
fondale della base-room e le due capsule sono piani immagine sovrapposti, con
campionamento nearest e alpha per gli sprite. Lo stato richiede una proiezione
ortografica; Arcade espone una camera prospettica, quindi la scena usa una
camera con vista iniziale frontale calibrata sulla cornice 160×100. I piani 2D
quasi complanari mantengono la composizione piatta; la prospettiva resta una
approssimazione del modello ortografico richiesto dallo stato.

La scena `cryogenic-room` compone il PNG della stanza
[`base-room-concept-v1.png`](../../../assets/rooms/base-room/concepts/base-room-concept-v1.png)
con due piani immagine alpha del prop
[`cryogenic-capsule-modular.png`](../../../assets/rooms/cryogenic-room/exports/cryogenic-capsule-modular.png),
posizionati ai lati. La camera iniziale resta fissa per mantenere la
composizione 2D allineata. `mise run play:cryogenic-room` la avvia direttamente;
questa scena non carica la geometria OBJ.

Nel menu debug, `v` alterna la resa a glifi ASCII (`toShapeGlyph`) e quella a
pixel colorati (`toHalfBlock`), che è la modalità iniziale. Usa un mezzo blocco
Unicode per cella del terminale, con un colore per ciascuna delle due metà
verticali.

## Riferimenti upstream

- [README ufficiale: rendering engine e package API](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Guida upstream: verifica e visualizzazione dell'output](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [Pacchetto `ascii-arcade` su npm](https://www.npmjs.com/package/ascii-arcade)
