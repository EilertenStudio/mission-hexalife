# Istruzioni per gli asset

Segui `app/game/CONVENTIONS.md` per struttura, naming e flusso delle cartelle
di ogni asset.

- Modifica i file sorgente nella cartella radice dell'asset. La scena `.tscn`
  è la sorgente identitaria Godot dell'elemento componibile; gli script `.gd`
  accoppiati ne controllano o estendono il comportamento.
- Mantieni un solo file `.blend` per asset e organizza i contenuti con
  collection. Usa l'Asset Manager di Blender per condividere o comporre asset
  tra file Blender.
- Tratta `references/` come input, `concepts/` come lavorazioni intermedie e
  `exports/` come output derivati dai sorgenti. Non usare gli export come
  sorgente identitaria dell'asset.
- Metti in `scripts/` gli strumenti di authoring e supporto, raggruppandoli per
  tool quando utile.
- Un sidecar `<asset>.json` è facoltativo, documentale e non configura il
  runtime.

Per gli script che materializzano node tree nelle scene o PoC, segui la regola
`GENERATE` definita in `app/game/AGENTS.md`.
