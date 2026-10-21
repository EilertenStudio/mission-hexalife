# Convenzioni di naming e struttura degli asset

Questo documento definisce come organizzare e nominare gli asset di gioco in
`app/game/assets/`. Le regole si ispirano alla convenzione di Blender Studio,
adattandola al flusso del progetto Godot.

## Cartelle e categorie

Organizzare gli asset per dominio, categoria e identificatore dell'asset:

```text
assets/
├── characters/<asset>/
├── rooms/<asset>/
├── environments/<asset>/
├── planets/<asset>/
├── ships/<asset>/
└── props/
    ├── terminals/<asset>/
    ├── capsules/<asset>/
    ├── clothing/<asset>/
    ├── furniture/<asset>/
    └── vegetation/<asset>/
```

Le categorie descrivono il ruolo dell'elemento nel gioco e possono essere
estese quando emergono nuovi domini o tipi di asset. Gli asset autonomi vivono
ciascuno nella propria cartella.

Usare nomi in minuscolo. Usare `_` per separare le parole che compongono un
singolo nome, per esempio `navigation_terminal` e `deep_space_freighter`.
Usare `-` per separare parti con ruoli distinti, per esempio un nome e un task
in un export. Non usare spazi.

## File radice dell'asset

I file sorgente dell'asset stanno direttamente nella sua cartella e condividono
il nome dell'asset, senza prefissi di tipo:

```text
navigation_terminal/
├── navigation_terminal.gd
├── navigation_terminal.tscn
├── navigation_terminal.blend
└── navigation_terminal.pxo
```

Ogni asset usa un solo file `.blend`. Organizzare al suo interno le collection;
per riutilizzare composizioni tra file Blender, usare l'Asset Manager invece di
creare file `.blend` aggiuntivi per lo stesso asset.

I file Godot sono le sorgenti identitarie per l'elemento nel gioco: la scena
`.tscn` definisce il nodo componibile e gli script `.gd` associati ne
controllano o estendono il comportamento. Gli altri formati nativi, come
`.blend` o `.pxo`, restano sorgenti di authoring dell'asset.

## Cartelle di supporto

```text
<asset>/
├── references/  # input e materiale di riferimento
├── concepts/    # lavorazioni intermedie
├── exports/     # output derivati dai sorgenti
└── scripts/     # strumenti e script di supporto
```

Il flusso dell'asset procede da `references/` attraverso `concepts/` ai file
sorgente nella cartella radice; gli output risultanti vanno in `exports/`.
`references/` contiene solo input, `concepts/` contiene solo esplorazioni e
lavorazioni intermedie, `exports/` contiene solo output. Gli script di
authoring possono essere raggruppati per strumento in `scripts/<tool>/`.

I nomi degli export mantengono il nome dell'asset e possono aggiungere il task
e la versione quando distinguono output diversi, per esempio
`navigation_terminal-preview-v001.png`. Non aggiungere prefissi di tipo come
`lib-` o `char-` ai nomi dei file.

Un sidecar `<asset>.json` è facoltativo e può fornire contesto agli strumenti o
agli agenti. Non è una fonte di configurazione runtime e non sostituisce i file
Godot.

## Nomi interni ai file Blender

Nei file `.blend` mantenere i prefissi Blender Studio per collection e
datablock, includendo l'identificatore univoco dell'asset. Per esempio:

- `CH-jerv` per la collection principale di un personaggio;
- `SE-cryogenic_room` per la collection principale di una stanza o set;
- `LI-navigation_terminal` per un asset di libreria non riggato;
- `PR-engineer_suit` per un prop riggato;
- `GEO-navigation_terminal-screen` per la geometria e `LGT-navigation_terminal-key`
  per una luce.

Usare `lower_underscore_case` nei nomi di base, `-` per separare prefissi e
livelli gerarchici, `_001` per numeri progressivi, e riservare `.L` e `.R` agli
elementi simmetrici. I mesh datablock usano lo stesso nome dell'oggetto che li
contiene.

Per i prefissi e i dettagli dei datablock consultare la
[convenzione di Blender Studio](https://studio.blender.org/tools/naming-conventions/in-file-prefixes).

## Ambito delle convenzioni Godot

Queste regole governano cartelle e file degli asset. Per nomi interni al codice
e alle scene Godot — classi, nodi, variabili, funzioni e segnali — mantenere le
convenzioni idiomatiche Godot descritte in `ARCHITECTURE.md`.
