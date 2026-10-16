# Funkey

Funkey è un engine Rust per giochi a pixel nel terminale. Usa un framebuffer a
colori, presentato con mezzi blocchi Unicode oppure, se abilitato e supportato,
con pixel reali tramite il protocollo Kitty. Include anche un renderer 3D
software sulla CPU; la scena di questo engine usa esclusivamente il disegno 2D.

## Installazione e avvio

Mise gestisce Rust `stable`. Funkey è una libreria: il task `play` prepara i
sorgenti upstream fissati e Cargo compila e avvia la scena.

Dalla root del repository:

```sh
mise run game funkey:play
```

Oppure dalla cartella dell’engine:

```sh
mise run play
```

Al primo avvio serve Internet per scaricare i sorgenti e le dipendenze. Funkey
0.8.1, Crust 0.1.62 e Glow 0.1.49 sono fissati ai rispettivi tag e commit; i
checkout e gli artefatti Cargo restano sotto `.local/mise/data/`.

## Scena del risveglio

La scena implementa l'apertura nella sala criogenica a partire dal knot
[`risveglio`](../../../../gamebook/engines/ink/story.ink). Usa come fondale
statico
[`cryogenic-room-pixelart-v2.png`](../../../assets/rooms/cryogenic-room/exports/cryogenic-room-pixelart-v2.png),
che mostra quattro capsule lungo le pareti, la porta e il terminale. La camera è
fissa dentro la stanza: l'Ingegnere è il punto di vista del giocatore e non viene
disegnato come personaggio. La mappa del terminale mostra i segnali degli altri
membri della crew e non aggiunge una posizione dell'Ingegnere.

Si comincia dal risveglio con allarme rosso, poi si possono esaminare la propria
capsula, consultare il terminale o provare la porta. Il terminale permette di
leggere il messaggio del Capitano, la mappa e l'allarme del QC. Dopo aver
osservato capsula e terminale, il blackout riavvia la riserva locale e sblocca
la porta; la scena termina quando la si apre. Gli sfondi restano fermi e il
passaggio tra allarme, blackout e riavvio cambia soltanto lo stato mostrato.

Controlli: `1`/`C` capsula, `2`/`T` terminale, `3`/`P` porta; frecce e `Invio`
selezionano un oggetto. Nel terminale `M` apre la mappa, `A` l'allarme QC,
`Esc` torna indietro. `Q` esce. Funkey 0.8.1 espone input da tastiera ma non
eventi mouse, quindi questa scena usa selezione da tastiera.

Lo stato spaziale è in
[`app/game/src/scenes/cryogenic-room/`](../../../src/scenes/cryogenic-room/);
i fatti narrativi e i testi approvati sono in
[`app/gamebook/`](../../../../gamebook/).

## Riferimenti upstream

- [Repository e guida ufficiale Funkey](https://github.com/isene/funkey)
- [Backend Cargo di Mise](https://mise.jdx.dev/dev-tools/backends/cargo)
