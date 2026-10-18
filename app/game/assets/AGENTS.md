# Struttura e fonti degli asset

Un soggetto è un asset autonomo del progetto, per esempio un personaggio, un
prop, un set o una scena. Organizzare ogni soggetto con queste cartelle,
creandole quando servono:

```text
<subject>/
├── concepts/
├── references/
├── exports/
├── sources/
│   ├── description.json
│   ├── animations.json
│   └── ...
└── scripts/
    ├── blender/
    └── pixelorama/
```

- `sources/` contiene i JSON canonici che definiscono identità, funzione,
  aspetto e comportamento stabile del soggetto. Usare file distinti per
  argomento, come `description.json`, `animations.json`, `geometry.json` o
  altri file specifici del soggetto.
- `sources/description.json` descrive in dettaglio il soggetto e il suo stato
  desiderato. Non è un changelog né un indice dei file presenti. In caso di
  divergenza prevale sulla resa dei concept, sulle reference e sulle
  implementazioni degli script.
- `sources/animations.json`, quando applicabile, descrive ogni animazione con
  colonna iniziale, numero di frame in colonne, azione e durata o cadenza
  definite. Non aggiungere informazioni generali sullo spritesheet.
- I JSON in `sources/` sono indipendenti dal motore. Gli engine li interpretano
  e li implementano senza diventare una fonte autonoma dello stato desiderato.
- `concepts/` raccoglie proposte ed esplorazioni visive. Non imporre vincoli
  preventivi di stile, tecnica o composizione ai concept.
- `references/` raccoglie immagini e documenti esterni che informano il lavoro,
  ma non stabiliscono né modificano da soli lo stato desiderato.
- `exports/` contiene gli asset finali prodotti per essere usati dal progetto.
- `scripts/blender/` e `scripts/pixelorama/` contengono gli script, separati
  per applicazione, che generano o aggiornano gli asset finali in `exports/` a
  partire dalle fonti in `sources/`.
- `SOURCE.md` e `ANIMATION.md` non sono più formati canonici: i loro contenuti
  vanno registrati nei JSON pertinenti dentro `sources/`.

# Convenzioni di naming per Blender

Per collection, oggetti e altri datablock nei file `.blend`, seguire la
[convenzione di Blender Studio](https://studio.blender.org/tools/naming-conventions/in-file-prefixes):

- usare un identificatore univoco dell'asset in tutti i suoi datablock, per
  esempio `cryogenic_room`;
- usare nomi di base in `lower_underscore_case`, senza spazi; separare i
  prefissi e i livelli della gerarchia con `-`;
- nominare la collection radice con il prefisso del tipo di asset, per esempio
  `SE-cryogenic_room` per un set o `LI-cryogenic_room` per un asset di ambiente;
- prefissare gli oggetti secondo la funzione: `GEO` per la geometria, `LGT` per
  le luci, `HLP` per gli helper e `TMP` per i segnaposto; per esempio
  `GEO-cryogenic_room-floor` e `LGT-cryogenic_room-key`;
- dare ai mesh datablock lo stesso nome degli oggetti che li contengono;
  sostituire i suffissi automatici `.001` con `_001` quando indicano un numero
  progressivo; riservare `.L` e `.R` agli elementi simmetrici.
