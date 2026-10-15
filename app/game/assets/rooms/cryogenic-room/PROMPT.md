# PROMPT — Concept della sala criogenica

Esplorare visivamente proposte sketchate per l'ambiente e i props della sala
criogenica. Questa fase serve a scegliere una direzione di design; non creare o
modificare file Blender.

## Ambiente comune

La stanza è un ambiente chiuso, prevalentemente largo, con pavimento, parete
posteriore, due pareti laterali e soffitto. L'inquadratura principale è da
vicino all'ingresso, centrata e rivolta lungo la stanza, con una lieve vista
dall'alto che renda leggibili volume e profondità.

Ogni proposta deve mostrare chiaramente:

- capsule criogeniche riconoscibili come unità verticali individuali;
- almeno un terminale di controllo accessibile;
- una porta di accesso integrata in una parete.

Si possono esplorare disposizione, numero e silhouette delle capsule, forma
della porta e del terminale, illuminazione, pannelli modulari, canaline e
piccoli elementi di servizio. Mantenere una costruzione credibile e lasciare
leggibili i tre elementi essenziali.

## Concepts

La base-room vuota è conservata in
`../base-room/concepts/base-room-concept-v1.png` e rappresenta solo l'involucro
architettonico. Capsule, terminale e porta appartengono ai concept della sala
criogenica descritti qui sotto.

Restano come alternative esplorative:

- `concepts/cryogenic-room-concept-02.png` — sala di manutenzione industriale,
  con capsule in nicchie e terminale su una console laterale;
- `concepts/cryogenic-room-concept-03.png` — ambiente compatto con capsule
  raggruppate in una zona e terminale vicino alla porta.

Le alternative non sono requisiti da fondere nella base scelta.

## Props: capsule criogeniche

Creare quattro concept di una singola capsula verticale inserita nella vista
vuota di `../base-room/concepts/base-room-concept-v1.png`. Ogni variante deve
conservare camera, prospettiva, architettura, pavimento e illuminazione della
base; cambia soltanto il design della capsula, mantenuta nella stessa posizione
per consentire il confronto.

La capsula deve stare sul pavimento e risultare credibile in una stanza alta
3,2 m: circa 2,1 m di altezza e meno di 1 m di larghezza sono riferimenti
visivi, non misure definitive. Usare una struttura metallica chiara, pannelli
freddi e un inserto frontale azzurro pallido, coerenti con i materiali e gli
accenti luminosi della stanza. Le quattro varianti possono esplorare profili
arrotondati, sfaccettati e modulari, senza cambiare scala o aggiungere altri
props.

Il concept 03 è la direzione scelta per la capsula. Materializzarlo come
immagine PNG isolata con trasparenza e usarlo due volte nella scena Arcade, sui
lati sinistro e destro della base-room. L'export è
`exports/cryogenic-capsule-modular.png`. Mantenere la camera fissa e la capsula
frontale; il prop deve restare leggibile sopra lo sfondo senza coprire il volume
centrale della stanza.

Le altre varianti restano esplorative:

- `concepts/cryogenic-capsule-concept-01.png` — profilo arrotondato;
- `concepts/cryogenic-capsule-concept-02.png` — profilo sfaccettato;
- `concepts/cryogenic-capsule-concept-03.png` — guscio modulare, direzione
  selezionata;
- `concepts/cryogenic-capsule-concept-04.png` — guscio rastremato con fasce di
  chiusura.

## Stile e vincoli

- Sketch di concept art con linee intenzionali e pulite, volumi chiari e
  prospettiva coerente.
- Usare pochi accenti cromatici freddi e luminosi per distinguere capsule,
  terminale e illuminazione; mantenere la lettura del disegno a matita.
- Niente testo leggibile, didascalie, watermark o interfacce sovrapposte.
- Evitare persone visibili, dettagli minuti confusi e resa fotorealistica.
- Non creare geometria o nuovi file `.blend` in questa fase. L'immagine PNG
  trasparente della capsula selezionata è un export per la composizione 2D in
  Arcade.

La direzione selezionata è descritta sopra. Un nuovo aggiornamento del prompt
sarà necessario se cambieranno forma, materiali o disposizione delle capsule.
