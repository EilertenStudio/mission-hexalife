# Struttura degli asset

Ogni asset autonomo appartiene a un dominio e vive in
`app/game/assets/<dominio>/<nome-asset>/`, per esempio un personaggio in
`characters/`, una stanza in `rooms/` o una nave in `ships/`.

Una cartella asset può contenere:

```text
<nome-asset>/
├── concepts/       # proposte ed esplorazioni
├── references/     # materiale di riferimento
├── exports/        # file finali usati dal progetto
├── scripts/<tool>/ # strumenti di authoring e generazione
├── <asset>.tscn    # identità Godot dell'elemento componibile
├── <asset>.tres    # risorse Godot associate, se utili
└── <asset>.json    # contesto facoltativo per l'Agent
```

- I file Godot definiscono identità, composizione e comportamento dell'asset.
  Associare script `.gd` o shader `.gdshader` quando servono a controllarli o
  estenderli.
- `concepts/` raccoglie esplorazioni visive; `references/` raccoglie materiale
  esterno. Nessuna delle due cartelle determina da sola l'asset finale.
- `exports/` contiene i file finali prodotti per l'uso nel progetto. Gli
  strumenti in `scripts/<tool>/` possono generarli o aggiornarli a partire dai
  sorgenti nativi dello strumento, dalle reference o dai file Godot.
- Il JSON facoltativo `<nome-asset>.json` fornisce contesto all'Agent. Non è la
  sorgente dell'identità Godot e non va usato come configurazione runtime; gli
  strumenti offline possono leggerlo per produrre export.
## Convenzioni di naming per Blender

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
