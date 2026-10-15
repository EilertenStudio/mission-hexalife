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

Il task `play` avvia direttamente `cryogenic-room`. Premi `m` durante il gioco
per aprire il selettore delle scene: usa `↑`/`↓` e `Invio`, oppure `1`/`2` per
scegliere `room` o `cryogenic-room`. `Esc` torna alla scena attiva e `q` esce.
`play:cryogenic-room` resta disponibile come avvio diretto della sala
criogenica.

La scena `cryogenic-room` carica l'OBJ e il MTL da
[`src/scenes/cryogenic-room/`](../../../src/scenes/cryogenic-room/) tramite
`parseObj`. Si avvia con `mise run play:cryogenic-room`. Arcade usa i colori
diffusi del MTL e approssima le luci area di Blender con luci puntiformi;
quindi l'illuminazione non coincide esattamente con il render di Blender.

Nel menu debug, `v` alterna la resa a glifi ASCII (`toShapeGlyph`) e quella a
pixel colorati (`toHalfBlock`), che è la modalità iniziale. Usa un mezzo blocco
Unicode per cella del terminale, con un colore per ciascuna delle due metà
verticali.

## Riferimenti upstream

- [README ufficiale: rendering engine e package API](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Guida upstream: verifica e visualizzazione dell'output](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [Pacchetto `ascii-arcade` su npm](https://www.npmjs.com/package/ascii-arcade)
