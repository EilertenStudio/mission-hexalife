# Asset 3D — regole per ACT

## Struttura degli asset

Ogni asset è autonomo e appartiene a una categoria.

```text
<categoria>/<oggetto>/
├── PROMPT.md
├── references/
├── <tipo>-<nome_asset>-<fase>.blend
├── scripts/
└── exports/
```

Regola fondamentale:

**1 oggetto = 1 PROMPT.md = 1 file Blender = N script ACT = N export**

## PROMPT.md — SOURCE per l'Agent

`PROMPT.md` è la SOURCE per ACT e l'unica fonte autorevole per l'intento
dell'asset. Contiene il prompt operativo e la descrizione dettagliata
dell'oggetto da creare: forme, proporzioni, materiali, riferimenti, vincoli e
risultato atteso.

- Leggere `PROMPT.md` prima di modificare uno script o un file Blender.
- Modellare seguendo le richieste e la gerarchia dei riferimenti indicati nel
  prompt.
- Non inventare decisioni sostanziali non descritte o supportate da
  `PROMPT.md` e dai suoi riferimenti. Se un dettaglio determinante è aperto,
  chiedere chiarimenti prima di fissarlo nel modello.
- Aggiornare `PROMPT.md` quando l'utente cambia o approva nuovi requisiti; non
  riscriverlo per giustificare un risultato già prodotto.
- `PROMPT.md` descrive l'asset da creare, non il suo avanzamento o le
  caratteristiche accidentali dell'implementazione corrente.
- Non mantenere una seconda fonte testuale parallela per l'intento dell'asset.

Gli script, i file `.blend`, i render e gli export sono implementazioni o
derivati del prompt. Non diventano fonti autonome del design.

## Blender

Il file `.blend` materializza l'asset descritto in `PROMPT.md`. Il nome segue
il formato Blender Studio `<tipo>-<nome_asset>-<fase>.blend`, usando parole in
minuscolo, `_` tra le parole e `-` per separare tipo, asset e fase. Per
esempio, una stanza modellata come set usa
`set-cryogenic_room-modeling.blend`.

ACT non modifica direttamente il formato `.blend`. Ogni modifica viene
effettuata tramite Blender e la sua Python API:

- `bpy`
- `bmesh`
- `mathutils`
- altre API Blender quando necessarie

Blender deve essere invocato tramite la toolchain Mise del repository.

`template.blend` è la base generica e reale di Blender: conserva i nomi
predefiniti dei suoi oggetti e delle sue collection, si apre nel workspace
`Modelling` e usa `main` per Scene e View Layer. Quando un asset necessita di
una base specializzata, materializzarla nella propria categoria partendo da
questo file. Per set e stanze, il template specializzato è
`rooms/template-room/set-template_room-modelling.blend`; usa il namespace
`template_room` e mantiene `main` per Scene e View Layer. I generatori delle
stanze devono partire dal template specializzato e preservare la sua
trasformazione della camera. Il template e la cryogenic-room condividono la
geometria e l'illuminazione definite in `rooms/room_geometry.py`.
Materializzare il template dalla base generica con il task Mise
`materialize:room-template`.

La base generica non va rinominata secondo il namespace di un singolo asset.
Le convenzioni Blender Studio per i datablock si applicano ai template
specializzati e agli asset derivati.

La camera della stanza criogenica viene letta da Arcade in
`app/game/src/scenes/cryogenic-room/camera.json`. Per sincronizzare le modifiche
alla camera salvate nel `.blend`, usare il task Mise
`export:cryogenic-room-camera`.

## Nomi in Blender

Per collection, oggetti e altri datablock nei file `.blend`, seguire la
[convenzione di Blender Studio](https://studio.blender.org/tools/naming-conventions/in-file-prefixes):

- usare un identificatore univoco dell'asset in tutti i suoi datablock, per
  esempio `cryogenic_room`;
- usare nomi di base in `lower_underscore_case`, senza spazi; separare i
  prefissi e i livelli della gerarchia con `-`;
- nominare la collection radice con il prefisso del tipo di asset, per esempio
  `SE-cryogenic_room` per un set o `LI-cryogenic_room` per un asset di ambiente;
- prefissare gli oggetti secondo la funzione: `GEO` per la geometria, `LGT`
  per le luci, `HLP` per gli helper e `TMP` per i segnaposto; per esempio
  `GEO-cryogenic_room-floor` e `LGT-cryogenic_room-key`;
- dare ai mesh datablock lo stesso nome degli oggetti che li contengono;
  sostituire i suffissi automatici `.001` con `_001` quando indicano un numero
  progressivo; riservare `.L` e `.R` agli elementi simmetrici.

I nomi dei file e degli script del repository seguono la struttura e la
sequenza definite in questo documento.

## Script ACT

Gli script prodotti da ACT risiedono in `scripts/`.

Ogni script Python segue il nome `XX_<azione>.py`: `XX` è un numero progressivo
a due cifre (`01`, `02`, ...), mentre `<azione>` descrive l'intervento in
`snake_case`, per esempio `01_crea_volume.py`.

Gli script devono:

- operare sull'asset della propria directory;
- essere leggibili e mantenibili;
- usare Blender Python invece di automazione della GUI;
- evitare complessità non necessaria;
- preservare quanto già corretto quando raffinano un asset;
- leggere i requisiti da `PROMPT.md` e produrre un risultato coerente con esso.

ACT può creare più script successivi quando questo rende chiara l'evoluzione
dell'implementazione.

## Autonomia e gate visivi

Quando `PROMPT.md` definisce fasi e criteri di completamento, ACT deve
completarle autonomamente e nell'ordine indicato. Può iterare all'interno di
una fase finché il relativo gate visivo non è soddisfatto, poi passa alla
successiva senza chiedere approvazione.

ACT si ferma e chiede chiarimenti solo in caso di impossibilità reale, ambiguità
che impedisce di procedere o rischio concreto di compromettere lavoro già
valido. Ogni fase successiva deve preservare i risultati validati nelle fasi
precedenti. Le reference guidano prima di tutto proporzioni e silhouette: i
dettagli non devono compensare una forma primaria errata.

## Iterazione

Il ciclo normale è:

```text
PROMPT.md
   ↓
ACT
   ↓
script Blender
   ↓
<tipo>-<nome_asset>-<fase>.blend
   ↓
export / render
   ↓
ispezione ACT rispetto a PROMPT.md
   ↓
eventuale iterazione
```

ACT deve correggere gli script e rieseguire Blender per modificare l'asset.
Non deve effettuare correzioni manuali non riproducibili tramite GUI.

## Controllo

In questa fase non sono richiesti task automatici di validazione.

ACT deve comunque ispezionare il risultato prodotto con Blender e confrontarlo
con `PROMPT.md` e i riferimenti indicati, inclusi quando rilevanti:

- dimensioni;
- posizione;
- rotazione;
- scala;
- geometria;
- numero e tipo degli oggetti;
- proprietà Blender richieste dal prompt.

La validazione automatizzata appartiene a una futura fase di hardening.

## Export

Gli output destinati all'ispezione o all'uso esterno risiedono in `exports/`.

Possono includere:

- render;
- immagini di riferimento;
- mesh esportate;
- altri formati derivati.

Gli export sono derivati dal `.blend` e non sostituiscono `PROMPT.md` né il file
Blender.
