# Ruoli dei file e delle cartelle degli asset

Ogni cartella di asset può organizzare il lavoro con questa struttura:

```text
<asset>/
├── SOURCE.md
├── ANIMATION.md
├── concepts/
├── references/
├── exports/
└── scripts/
    ├── blender/
    └── pixelorama/
```

- `SOURCE.md` descrive in dettaglio l'identità, la funzione e lo stato
  desiderato stabile dell'asset, con le informazioni necessarie a definirne
  chiaramente forma e resa. È la fonte che l'agente interpreta per capire che
  cosa rappresenta l'asset e come deve apparire. Non è una descrizione del task
  corrente, un changelog delle revisioni o un indice dei file nella cartella.
  In caso di divergenza, `SOURCE.md` prevale su concept, reference e
  implementazioni degli script.
- `ANIMATION.md` elenca per ogni animazione la colonna iniziale, il numero di
  frame espresso in colonne, una breve descrizione dell'azione e la durata o
  cadenza del ciclo quando definita. Non aggiungere altri dettagli o
  informazioni generali sullo spritesheet.
- `concepts/` raccoglie proposte ed esplorazioni visive. Non imporre vincoli
  preventivi di stile, tecnica o composizione ai concept.
- `references/` raccoglie immagini reali provenienti da fonti esterne, usate
  per rafforzare e contestualizzare `SOURCE.md`. Le reference informano il
  lavoro, ma non sostituiscono né modificano da sole lo stato desiderato.
- `exports/` contiene gli asset finali prodotti per essere usati dal progetto.
- `scripts/blender/` e `scripts/pixelorama/` contengono gli script, separati
  per applicazione, che generano o aggiornano gli asset finali in `exports/`.
  Gli script realizzano lo stato descritto in `SOURCE.md`: non diventano una
  fonte autonoma dello stato desiderato.

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
