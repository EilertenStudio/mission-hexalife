# Architettura del gioco

Questo documento orienta chi contribuisce allo sviluppo di *Missione Hexalife*:
descrive le responsabilità principali, la struttura di riferimento e le ragioni
delle scelte. È una guida tecnica evolutiva, non un contratto rigido. Aggiornarla
quando il progetto prende una direzione architetturale diversa o quando una
scelta diventa più concreta.

## Stato e perimetro

`app/game/` è il progetto Godot reale. `scenes/main/main.tscn` è la scena
principale configurata come avvio del progetto. Al momento è uno shell con i
rami `Persistent`, `World` e `UI`; i servizi di gioco e le stanze verranno
aggiunti quando saranno implementati. La scena `tests/test-gameplay-ink/` resta
una PoC autonoma, non la scena principale né la struttura definitiva del gioco.

Per il canone narrativo fanno fede `app/gamebook/NOTE.md`, `ENVIRONMENT.md` e
`PROPS.md`. Le decisioni narrative aperte restano TBD finché non vengono
approvate e registrate lì. Questa pagina documenta l'organizzazione tecnica, non
aggiunge fatti alla storia.

## Principi di organizzazione

- **Comporre scene da scene riutilizzabili.** Una stanza combina ambiente,
  terminali, porte, oggetti e personaggi presenti. Ogni scena gestisce il
  comportamento che le appartiene e limita le dipendenze dal contesto esterno.
- **Separare per responsabilità e durata.** Il mondo attivo, l'interfaccia e i
  sistemi che devono sopravvivere ai cambi di stanza sono rami distinti.
- **Collegare i componenti tramite interfacce esplicite.** Preferire segnali,
  riferimenti inizializzati dal compositore e chiamate con uno scopo chiaro a
  percorsi rigidi verso nodi di altre scene.
- **Aggiungere sistemi globali solo se servono.** Un servizio persistente è
  appropriato quando possiede dati propri usati in più scene o deve durare tra
  transizioni; non è un contenitore generico per ogni funzionalità.
- **Tenere separati albero runtime e cartelle sorgenti.** L'albero descrive le
  relazioni tra nodi attivi; le cartelle descrivono dove vivono le scene e gli
  asset nel progetto.

Questi criteri seguono le indicazioni di Godot su scene autonome, composizione
`Main`/`World`/`GUI` e uso mirato degli autoload. Sono principi di partenza da
adattare ai bisogni reali del gioco, non regole universali.

## Albero runtime di riferimento

```text
ROOT GODOT
└── Main                         # ingresso e coordinamento
    ├── Persistent               # solo sistemi che attraversano transizioni
    │   ├── GameState            # stato e progressi della partita
    │   ├── InkStoryDirector     # runtime Ink e avanzamento narrativo
    │   ├── SceneFlow            # sostituzione/transizione del contenuto World
    │   ├── SaveSystem           # persistenza su disco, quando implementata
    │   └── SceneManager         # menu debug, presente nello shell Main
    ├── World                    # contenuto di gioco attivo
    │   ├── CurrentShipArea
    │   │   └── Room             # una stanza attiva
    │   │       ├── Environment  # geometria, luci, atmosfera
    │   │       ├── Interactables
    │   │       │   ├── Terminal # mappa, QC, messaggi e registri
    │   │       │   ├── Doors
    │   │       │   └── Props
    │   │       ├── Crew         # membri presenti nella stanza
    │   │       └── RoomAudio
    │   └── PlayerPerspective    # input e punto di vista dell'Ingegnere
    └── UI                       # presentazione e input dell'interfaccia
        ├── NarrativeBox
        ├── ActionDialogBox
        ├── NotifyDialog
        └── Menus
```

La scena principale attuale materializza i rami `Main`, `Persistent`, `World` e
`UI/Root`; sotto `Persistent` è istanziato il feature `SceneManager` per il
debug. La scorciatoia iniziale è `CTRL+P` ed è configurabile sull'istanza
nell'Inspector. `GameState`, `InkStoryDirector`, `SceneFlow`, `SaveSystem`, il
contenuto stanza e i widget nel diagramma sono ruoli di riferimento, non
implementazioni già presenti. Se un servizio non ha bisogno di attraversare una
transizione, tenerlo nella scena che lo usa. Il diagramma non decide se
l'Ingegnere debba avere una rappresentazione visibile nella stanza:
`PlayerPerspective` indica il controllo del punto di vista e dell'input, non un
personaggio 3D già definito.

Nel gioco la progressione avviene stanza per stanza, a bordo della nave. Ogni
stanza prevede un terminale e una o più porte; i terminali danno accesso a mappa,
posizioni rilevate della crew, QC e registri secondo il contesto e lo stato dei
sistemi. La scena della stanza compone gli elementi necessari e può essere
sostituita nel ramo `World` quando il giocatore si sposta.

## Confini tra Ink e Godot

La separazione dei ruoli è intenzionale:

- **Ink** esprime la progressione della storia: nodi, testo, scelte, condizioni,
  variabili narrative e conseguenze definite nel racconto.
- **Godot** è la scena reale: costruisce ambienti e interfaccia, riceve input,
  presenta testo e opzioni, gestisce audio e animazioni, e associa le
  interazioni del mondo alle scelte offerte dalla storia.
- **Il collegamento** passa attraverso un runtime/adattatore Ink-Godot. Ink può
  emettere cue identificati; Godot li risolve tramite registrazioni esplicite
  verso scene o sistemi disponibili. Il testo narrativo non deve scegliere
  liberamente percorsi di file o invocare metodi arbitrari dell'engine.
- **Gli oggetti interagibili** comunicano l'intenzione d'interazione al
  compositore/runtime. Il runtime verifica che la storia offra l'azione in quel
  momento; la scena gestisce la risposta visiva e sonora.

Quindi Ink governa la regia narrativa, ma non crea né possiede la scena Godot.
Godot interpreta quella regia nel mondo di gioco. La PoC esistente dimostra
questo modello in un ambito limitato; le sue capability e i suoi file non sono
automaticamente l'architettura completa del prodotto.

## Struttura dei sorgenti

La struttura delle cartelle è definita in `app/game/AGENTS.md` e segue questi
ruoli:

```text
app/game/
├── assets/<dominio>/<asset>/  # elementi componibili riutilizzabili
├── scenes/<scena>/            # composizioni di gioco
├── tests/<test>/              # prove e PoC isolate
├── features/<dominio>/<feature>/ # funzionalità coese con scene e script
├── addons/                    # plugin Godot
├── scripts/                   # supporto condiviso
└── project.godot              # configurazione e scena iniziale
```

I file Godot (`.tscn`, `.tres`, `.gd`, `.gdshader`) sono le sorgenti identitarie
di scene, risorse e comportamenti. Gli asset sono organizzati per dominio;
`scenes/` combina asset e impostazioni dell'engine; `tests/` resta separato dal
gioco; `features/` raccoglie funzionalità coese composte da scene e script,
istanziali dai compositori responsabili della loro durata. Consultare
`AGENTS.md` e `assets/AGENTS.md` per le regole operative complete, inclusa la
generazione del node tree.

## Convenzioni dei nomi

Usare le convenzioni idiomatiche di Godot per rendere i nomi prevedibili e
facili da cercare:

- **File e cartelle:** `snake_case`, per esempio `main.tscn`,
  `cryogenic_room/` e `ink_story_runtime.gd`.
- **Classi e tipi:** `PascalCase`, per esempio `Main` e `InkStoryDirector`.
- **Nodi nella scena:** `PascalCase`, con nomi brevi che descrivono il ruolo,
  per esempio `World`, `UI`, `Terminal` e `ActionDialogBox`.
- **Variabili e funzioni:** `snake_case`, per esempio `current_room` e
  `load_story()`.
- **Costanti:** `CONSTANT_CASE`, per esempio `MAX_TURNS`.
- **Segnali:** `snake_case`; usare il passato quando descrivono un evento
  avvenuto, per esempio `door_opened`.

Mantenere i nomi dei nodi coerenti con quelli delle scene e dei componenti
esistenti. Se una convenzione del progetto diverge da quella standard di Godot,
documentare qui la motivazione e applicarla con coerenza.

## Come evolvere questa guida

Quando una scelta architetturale cambia:

1. Modificare questo documento nello stesso cambiamento che introduce la nuova
   struttura o responsabilità.
2. Spiegare il motivo pratico della scelta e quale parte del diagramma riguarda.
3. Distinguere ciò che è già implementato, ciò che è una direzione approvata e
   ciò che resta da decidere.
4. Se la scelta tecnica introduce anche fatti o decisioni narrative, aggiornare
   prima i documenti canonici in `app/gamebook/` secondo le regole del progetto.

Evitare di mantenere qui inventari di ogni nodo o dettaglio effimero: la scena e
gli script Godot restano la fonte di verità per l'implementazione concreta.

## Riferimenti

- [Godot: Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [Godot: Autoloads versus regular nodes](https://docs.godotengine.org/en/4.4/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- [Unreal Engine: Gameplay Framework](https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-framework-in-unreal-engine)
