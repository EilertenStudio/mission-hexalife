# Playground: Surface Taps

- Questa scena è una PoC autonoma per click sugli elementi visibili e risposta
  tattile per materiale. Non aggiungere fatti o contenuti della storia.
- Asset e suoni provvisori restano locali a tests/playground/; estrarre in
  assets/ solo dopo una scelta esplicita di riuso nel gioco.
- I bersagli riutilizzano features/interaction/surface_tap/: i pixel con alpha
  maggiore di zero definiscono l'area cliccabile; materiale e suono si
  configurano nella scena Godot.
- Mantenere accessibile la scena dal SceneManager e apribile direttamente
  dall'editor. Non cambiare la scena predefinita del progetto.
