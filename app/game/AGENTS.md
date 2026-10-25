# Struttura del progetto Godot

`app/game/` è la root del progetto Godot reale. `project.godot` contiene le
impostazioni globali e la scena di avvio; `addons/` contiene i plugin e
`scripts/` gli script condivisi dal progetto.

```text
app/game/
├── assets/<dominio>/<asset>/  # elementi componibili riutilizzabili
├── scenes/<scena>/            # scene di gioco
├── tests/<test>/              # scene PoC isolate
├── features/<dominio>/<feature>/ # funzionalità coese con scene e script
├── addons/                    # plugin Godot
├── scripts/                   # script condivisi
└── project.godot
```

- `assets/` raccoglie gli elementi di gioco componibili e li organizza per
  dominio, per esempio `characters/`, `rooms/` o `ships/`. La convenzione
  condivisa per cartelle, file e sorgenti è in `CONVENTIONS.md`; le istruzioni
  operative per gli agenti che modificano asset sono in `assets/AGENTS.md`.
- `scenes/` contiene le scene di gioco. Una scena combina asset riutilizzabili
  e definisce le impostazioni dell'engine proprie della composizione.
- `tests/` contiene scene di prova e PoC autonome, con asset e script locali
  quando servono. Restano separate dagli asset riutilizzabili e dalle scene di
  gioco. Mantenere asset e feature specifiche di una PoC sotto la sua cartella
  `tests/<test>/`; promuoverle in `assets/` o `features/` globali solo quando
  vengono selezionate per il gioco principale.
- `features/` contiene funzionalità coese che associano scene e script, per
  esempio `features/debug/scene_manager/`. Istanziare la scena della feature
  nel compositore che ne governa la durata; non renderla un autoload senza una
  necessità globale.

## Contesto di design e funzionalità

- Consultare [GDD.md](GDD.md) per le decisioni sull'esperienza del gioco finale
  e [FEATURES.md](FEATURES.md) prima di lavorare sulle funzionalità: contiene
  capacità disponibili, limiti, meccaniche candidate e priorità.
- Le priorità del catalogo non selezionano automaticamente il lavoro della
  prossima iterazione e non approvano una meccanica per il gioco finale.
- Quando cambia concretamente una funzionalità, aggiornare in `FEATURES.md`
  lo stato tecnico, i limiti e i riferimenti pertinenti. Distinguere il supporto
  di un plugin dalla disponibilità della relativa esperienza per il giocatore;
  una funzionalità parziale o una PoC rimossa non è un sistema completo.
- Il canone narrativo resta nei documenti di `app/gamebook/`, secondo le regole
  del progetto.

## Sorgenti Godot

- I file Godot sono la sorgente identitaria dell'elemento: usare scene `.tscn`
  e risorse `.tres` per rappresentare nodi, composizione e impostazioni; gli
  script `.gd` e gli shader `.gdshader` associati controllano o estendono il
  comportamento e la resa.
- Modificare direttamente la scena o la risorsa Godot che rappresenta
  l'elemento.
- È ammesso un sidecar `<nome-elemento>.json` accanto alla scena o all'asset
  per spiegare il contesto all'Agent. È documentazione di supporto: non è una
  fonte di configurazione runtime e non prevale sui file Godot. Gli strumenti
  offline possono leggerlo per generare export.
- Creare nuove scene di gioco in `scenes/<nome-scena>/` e nuove prove isolate
  in `tests/<nome-test>/`. Non collocare PoC in `assets/` o `scenes/`.
- Quando uno script materializza il node tree di una scena o PoC, aggiungere
  all'Inspector un pulsante `GENERATE` tramite `@export_tool_button` in uno
  script `@tool`, inizializzando la proprietà con un `Callable` valido già nel
  valore dichiarato. La generazione deve essere ripetibile senza duplicare
  nodi, assegnare `owner` alla scena root per rendere persistenti i nodi e
  marcare la scena come non salvata; verificare che l'avvio runtime riusi il
  tree materializzato senza ricrearlo o duplicarlo.

## `ARCHITECTURE.md`

- Non modificare `ARCHITECTURE.md` senza autorizzazione esplicita dell'utente.
  Per ora deve essere soltanto una guida alla struttura di cartelle e file del
  progetto; non usarlo per documentare lo stato delle implementazioni o il
  comportamento corrente delle funzionalità.
