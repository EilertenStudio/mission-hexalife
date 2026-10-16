# Arcade: risveglio nella sala criogenica

Questa applicazione usa le API pubbliche di `ascii-arcade` per presentare un
framebuffer 2D nel terminale. La scena non usa mesh, proiezione 3D, luci o
controlli di camera.

## Scena

Il comando `arcade:play` avvia l'apertura del gamebook dal punto di vista dell'Ingegnere.
Il giocatore si risveglia nella stanza, ispeziona la capsula e il terminale, può
consultare la mappa e l'allarme del QC, poi assiste al riavvio della riserva
locale che sblocca la porta. La scena si ferma sulla soglia del corridoio.

Stanza e props restano un'unica immagine pixel art statica; l'Ingegnere non è
disegnato come avatar. Capsule, terminale e porta rispondono ai click. Lo
sblocco della porta è rappresentato dal testo: il fondale, porta inclusa, non
cambia stato visivo. Le aree cliccabili sono descritte in
[`geometry.json`](../../../src/scenes/cryogenic-room/geometry.json), insieme
allo stato della scena. Pannelli, testo e pulsanti vengono disegnati nel
layer TUI pubblico di `ascii-arcade`, alla dimensione delle celle del terminale;
restano leggibili indipendentemente dalla scala del framebuffer. Il fondale
rimane nel framebuffer 160×100. La sequenza segue l'apertura in
[`story.ink`](../../../../gamebook/engines/ink/story.ink).

Il fondale usato è
[`cryogenic-room-pixelart-v2.png`](../../../assets/rooms/cryogenic-room/exports/cryogenic-room-pixelart-v2.png).
Arcade lo ridimensiona con campionamento nearest nel frame 160×100.

## Comandi

- `Invio` o click sul pannello: avanza dal risveglio e conferma le schermate.
- Nella stanza, click su un prop oppure `C`/`1` (capsula), `T`/`2` (terminale),
  `P`/`3` (porta). Le frecce selezionano un prop e `Invio` lo apre.
- Nel terminale: `M`/`1` apre la mappa; `A`/`2` mostra l'allarme QC; `Esc` torna
  alla stanza.
- Nei pannelli di dettaglio, `Invio`, `Esc` o click tornano indietro.
- `D`: apre o chiude il menu debug del sistema.
- Nel menu debug, clicca i pulsanti FPS/resa oppure usa `-` o `[` per diminuire
  il limite FPS, `+`, `=` o `]` per aumentarlo, e `V` per alternare pixel a
  mezzo blocco e glifi ASCII.
- `Shift+R`: ricarica il processo del gioco.
- `Q`: esce. `Esc` chiude prima il menu debug o il pannello narrativo attivo;
  dalla stanza esce.

Il limite iniziale è 6 FPS. L'applicazione usa direttamente le API
`ascii-arcade/engine/png`, `ascii-arcade/engine` e `ascii-arcade/platform`;
non avvia la CLI completa.

L'interazione mouse richiede un terminale che supporti il reporting SGR. Arcade
abilita questa modalità tramite la piattaforma `ascii-arcade`; il gioco agisce
sul click sinistro e ignora gli eventi di movimento.

## Riferimenti upstream

- [README ufficiale: rendering engine e package API](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Guida upstream: verifica e visualizzazione dell'output](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [Pacchetto `ascii-arcade` su npm](https://www.npmjs.com/package/ascii-arcade)
