# Test: Ink Scene Director

Questa PoC mostra in Godot l'apertura di `story.ink`, dal dialogo introduttivo
all'uscita dalla sala criogenica. Il dialogo presenta il contesto generale e le
regole del gameplay; l'incontro con il Medico e le scene successive sono fuori
dal percorso giocabile corrente. I cue `scene`, `actor`, `camera` e `audio`
vengono risolti solo attraverso handler registrati dalla scena.

La UI scrive progressivamente il testo nel riquadro nero in basso, sovrapposto
alla scena, e prosegue automaticamente tra i paragrafi fino a una scelta o
un'azione richiesta al giocatore. I paragrafi restano visibili insieme entro
lo stesso nodo Ink; al cambio di nodo il riquadro riparte dal suo testo. I
contenuti lunghi scorrono nel riquadro. Una battuta taggata `char:` o `actor:`
mostra il nome del personaggio su una targhetta turchese. Le scelte Ink restano
in un pannello dedicato e gli hotspot restano disponibili quando la storia li
abilita.

Quando Ink presenta le azioni della sala criogenica, clicca la capsula in primo
piano a sinistra, il terminale o la porta per scegliere il relativo passaggio
narrativo. Gli hotspot sono associati alle destinazioni delle scelte Ink e si
attivano solo quando la storia le rende disponibili. Le opzioni mostrate dal
terminale continuano a usare i pulsanti testuali.

Per compilare il JSON dalla root del progetto:

```sh
cd app/gamebook
MISE_CACHE_DIR=../../.local/mise/cache \
MISE_STATE_DIR=../../.local/mise/state \
MISE_DATA_DIR=../../.local/mise/data \
UV_CACHE_DIR=../../.local/mise/cache/uv \
mise run compile-godot
```

Poi avviare `test-gameplay-ink.tscn` dall'editor Godot o dalla riga di comando.
La scena predefinita del progetto resta invariata. Per verificare l'introduzione,
le interazioni e la conclusione all'uscita, oltre ai controlli del runtime Ink:

Per materializzare il node tree modificabile nella scena, selezionare il nodo
root nell'Inspector, premere `GENERATE` e salvare la scena.

```sh
godot --headless --path app/game \
  --script res://tests/test-gameplay-ink/scripts/verify_story.gd
```
