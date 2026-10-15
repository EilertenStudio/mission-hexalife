# PROMPT — Template stanza per interni

Derivare dalla base generica `app/game/assets/template.blend` usando il task
Mise `materialize:room-template`.

Il template contiene una stanza completa, con la stessa geometria e
illuminazione della `cryogenic-room`. La stanza misura 10 m in larghezza,
6 m in profondità e 3,2 m in altezza, con pareti e pavimento spessi 0,16 m.
Comprende pavimento, parete posteriore, due pareti laterali e soffitto; il
fronte rimane aperto. Non contiene arredi, capsule, terminali o decorazioni.

## Struttura Blender

- Scene e View Layer si chiamano `main`.
- Il workspace iniziale è `Modelling`.
- La collection asset è `SE-template_room`, con collection per geometria e
  rigging.
- `template_room-reference` e `template_room-render` raccolgono i riferimenti,
  la camera e le luci.
- I datablock della stanza usano il namespace `template_room`.

## Camera

Usare la stessa camera della `cryogenic-room`, con posizione e orientamento
letti da `src/scenes/cryogenic-room/camera.json`. Il template e la stanza
criogenica devono mantenere la stessa inquadratura.
