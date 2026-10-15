# PROMPT — Esperimento reference nave su Arcade

Questo file è la SOURCE dell'esperimento. L'obiettivo è visualizzare in Arcade
la tavola ortografica della nave come immagine piana esportata da Blender.
Questo esperimento non crea né rappresenta un modello tridimensionale della
nave.

## Immagine

Usare esclusivamente la tavola
[ortografica v2](references/deep-space-freighter-orthographic-reference-v2.png),
che contiene le viste laterale, superiore, di prua e di poppa. Mantenerne
l'intera immagine e le proporzioni originali.

## Blender ed export

Nel file Blender mantenere un solo oggetto mesh: un quad piano con UV da 0 a 1
e la tavola assegnata come texture. La superficie è soltanto un supporto per
trasportare l'immagine attraverso OBJ/MTL; non aggiungere volumi, geometrie
secondarie, camera, luci o altre immagini di riferimento.

Esportare OBJ con coordinate UV, MTL con `map_Kd` e il PNG accanto ai file.
Copiare OBJ, MTL e immagine nella scena sotto `app/game/src/`.

## Arcade

La scena Arcade carica l'OBJ con `parseObj`, individua la texture dichiarata
nel MTL, decodifica il PNG con l'API `ascii-arcade/engine/png` e campiona
l'immagine tramite gli UV del quad. La camera guarda la superficie frontalmente
per mostrare l'intera tavola.

La tavola deve essere leggibile senza Internet e senza dipendenze native.

## Limiti dell'esperimento

- La scena contiene solo l'immagine di riferimento piana.
- Nessuna geometria della nave o profondità tridimensionale.
- Nessun ritaglio, pannello o dettaglio sovrapposto alla reference.
- Fermarsi alla verifica della catena Blender → OBJ/MTL/PNG → Arcade.
