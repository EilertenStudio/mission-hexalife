# SOURCE — Sala criogenica

La sala criogenica è una scena 2D pixel art vista dall'interno, da altezza
umana, verso la parete di fondo. L'inquadratura non è incorniciata da un ingresso
né da colonne laterali. Architettura e props sono composti in un unico fondale
statico.

## Composizione

- Stanza metallica chiusa, larga, con pavimento in primo piano e pareti che
  convergono verso il fondo.
- Quattro capsule criogeniche verticali, due lungo ciascuna parete laterale,
  distribuite a profondità diverse. Hanno guscio metallico chiaro, contorni scuri
  e vetro azzurro luminoso.
- Una porta scorrevole chiusa sulla parete di fondo.
- Un terminale di controllo con schermo ciano, vicino alla porta.
- Nessun personaggio, testo leggibile o interfaccia sovrapposta.

## Resa visiva

Pixel art nitida, leggibile nel framebuffer 160×100, con gruppi di pixel
intenzionali, bordi a gradini e aree di colore compatte. La palette usa grigi
metallici e blu-grigi, contorni antracite e accenti ciano limitati a capsule,
illuminazione e terminale. La camera è fissa dentro la stanza; un corridoio
centrale libero e un'ampia porzione di pavimento mantengono leggibili profondità
e distribuzione delle capsule.

La scena usa un solo file immagine completo:
`exports/cryogenic-room-pixelart-v2.png`. Capsule, porta e terminale non sono
sprite separati nella scena runtime.
