# PROMPT — P0, blockout volumetrico della nave mineraria

Questo file è la SOURCE dell'asset. Lo stato richiesto ora è esclusivamente il
blockout volumetrico P0 dello scafo esterno, editabile in Blender. Non passare
alle fasi di hard-surface, pannellatura o dettaglio.

## Orientamento e reference

L'asse longitudinale è X: prua verso X negativo, poppa verso X positivo. Y è la
larghezza e Z l'altezza. La nave è simmetrica rispetto al piano XZ.

La [tavola ortografica v2](references/deep-space-freighter-orthographic-reference-v2.png)
è il riferimento principale. Confrontare i ritagli [laterale](references/orthographic/deep-space-freighter-side-v2.png),
[superiore](references/orthographic/deep-space-freighter-top-v2.png),
[prua](references/orthographic/deep-space-freighter-bow-front-v2.png) e
[poppa](references/orthographic/deep-space-freighter-aft-front-v2.png).
La [ricomposizione v8](references/deep-space-freighter-sketch-v8.png) chiarisce
la disposizione dei moduli, ma la tavola ortografica v2 prevale per la forma
esterna. I dettagli dei singoli moduli non appartengono a P0.

## Proporzioni ricavate dalla discovery

Usare proporzioni relative: lunghezza totale = 1; altezza massima ≈ 0,22;
larghezza massima ≈ 0,19. Il corpo centrale ha altezza circa 0,12–0,15.
Le sezioni longitudinali sono indicativamente:

| Sezione | Posizione lungo la lunghezza |
| --- | --- |
| Prua e collarino | 0–0,10 |
| Massa anteriore superiore | 0,04–0,40 |
| Struttura inferiore anteriore aperta | 0,02–0,40 |
| Transizione centrale | 0,38–0,52 |
| Corpo e masse laterali centrali/posteriori | 0,47–0,87 |
| Massa superiore posteriore | 0,50–0,88 |
| Terminale di poppa rastremato | 0,78–1,00 |

Le sezioni si sovrappongono sull'asse X perché occupano quote o lati diversi.
Non trasformare le masse distinte in una sola fusoliera continua.

## Geometrie P0

Materializzare soltanto:

1. corpo centrale longitudinale, con sezioni semplici e sfaccettate;
2. massa anteriore superiore, lunga e più stretta del corpo;
3. struttura inferiore anteriore, semplificata e aperta;
4. transizione centrale tra corpo anteriore e corpo posteriore;
5. due masse laterali centrali/posteriori simmetriche;
6. massa superiore posteriore rialzata;
7. terminale di poppa chiuso e rastremato.

La faccia anteriore non leggibile come apertura certa resta chiusa e piatta.
Le sezioni intermedie ambigue vanno interpolate nel modo più semplice e
reversibile. Non inventare forme strutturali che non trovano riscontro nella
silhouette o nella coerenza di almeno due viste.

## Metodo e gate

Usare primitive Blender, `bpy`, `bmesh` e, se utili, modifier semplici. Non
usare Geometry Nodes. Creare i volumi principali come oggetti editabili;
produrre viste ortografiche equivalenti alla reference; confrontare silhouette
laterale, superiore, prua e poppa; correggere autonomamente proporzioni,
posizione e dimensione.

Ordine di confronto: lunghezza totale; segmentazione longitudinale; silhouette
laterale; silhouette superiore; larghezza e altezza delle sezioni; masse
superiori, inferiori e laterali.

**P0 completo:** la nave è riconoscibile dalla sola silhouette e le masse
principali sono ragionevolmente allineate con tutte le viste disponibili.
Fermarsi se una scelta che modifica sostanzialmente la forma richiede dati
assenti, se due viste sono realmente incompatibili o se occorre inventare una
caratteristica strutturale significativa.

## Divieti P0

Nessuna pannellatura, finestra, griglia, bullone, scanalatura, dettaglio tecnico,
piccolo raccordo decorativo o materiale complesso. Nessun interno. Escludere
lo scanner (3), gli ugelli (22–24), bocche di scarico, raggi e luci emissive.
Usare solo un materiale neutro per rendere leggibili i volumi.

**STOP dopo P0.**
