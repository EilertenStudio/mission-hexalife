# Test visual grooms

Tre sprite PNG RGBA da 32×32 per la scena canonica omonima: cubo metallico,
sfera luminosa e piramide. Conservano silhouette e bande di superficie nette;
Arcade ne converte la luminanza in grigi, applica la luce radiale che segue il
puntatore e accende i bordi nell'area illuminata.

La stanza non usa un fondale raster: soffitto, pareti e pavimento provengono
dalla geometria canonica e ricevono shading runtime. Gli spigoli riflettenti
sono descritti in `geometry.json`; colore, intensità e falloff della luce
radiale sono in `lighting.json`, insieme alla posizione della torcia stilizzata
fissa sul lato destro. Lo sfondo mantiene una luce ambientale debole; linee e
superfici diventano più leggibili attorno al puntatore. Il lieve bagliore
pulsante della sfera è calcolato da Arcade e non è incorporato nello sprite.
