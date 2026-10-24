# Catalogo delle funzionalità

Questo documento raccoglie le capacità disponibili e le meccaniche candidate
per le avventure punta e clicca investigative e le visual novel. Serve a
orientare sviluppo e playground e fornisce contesto agli agenti.

[GDD.md](GDD.md) descrive il design del gioco finale. Inserire una feature in
questo catalogo non significa approvarla per il gioco. Il gameplay loop è
ancora in valutazione; i contenuti narrativi restano in `app/gamebook/`.

## Come leggere e aggiornare il catalogo

Ogni voce ha un identificatore stabile, una descrizione, una priorità e uno
stato tecnico. Conservare gli identificatori quando si aggiorna il documento.

| Priorità | Significato |
| --- | --- |
| P0 | Fondamenta che vogliamo disponibili fin dall'inizio: basi comuni prima. |
| P1 | Esperimenti successivi, per valutare oggetti, inventario e indagine. |
| P2 | Estensioni, aiuti e controlli avanzati da valutare più avanti. |

| Stato tecnico | Significato |
| --- | --- |
| Disponibile | L'implementazione della capacità descritta è presente nel progetto. |
| Parziale | Esiste una parte del supporto, con i limiti indicati. |
| Non implementata | La capacità descritta non ha ancora un'implementazione nel progetto attuale. |

Priorità, stato tecnico e selezione per il gioco finale sono informazioni
distinte. Le priorità sono modificabili sulla base delle prove e non avviano
automaticamente il lavoro su una feature.

Lo stato iniziale deriva dalla lettura del codice attuale, non da una nuova
verifica runtime. Il codice del plugin Ink è presente, ma le vecchie scene
PoC sono state rimosse: non costituiscono funzionalità disponibili nella scena
di gioco attuale. Aggiornare stati, limiti e riferimenti quando cambia
concretamente un'implementazione, specificando cosa è stato verificato.

## Dialoghi e lettura

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico e limiti |
| --- | --- | --- | --- | --- |
| DLG-01 | Dialogo sequenziale e avanzamento manuale | Leggere una battuta e proseguire volontariamente. | P0 | Parziale: il [plugin Ink](addons/ink_scene_director/README.md) emette paragrafi e consente di avanzare; manca una UI di dialogo integrata nel gioco attuale. |
| DLG-02 | Scelte di risposta | Selezionare una domanda, un atteggiamento o una decisione e ricevere una risposta coerente. | P0 | Parziale: il plugin Ink espone e seleziona scelte; manca la presentazione al giocatore. |
| DLG-03 | Scrittura progressiva configurabile | Vedere il testo apparire, completarlo con un input e poter disabilitare l'effetto. | P1 | Non implementata. |
| DLG-04 | Argomenti di conversazione | Scegliere temi di discussione, riconoscere quelli già affrontati e sbloccarne di nuovi dopo una scoperta. | P1 | Non implementata: le scelte e le variabili Ink sono una base, non un sistema di argomenti già pronto. |
| DLG-05 | Cronologia dei dialoghi | Rileggere le informazioni ricevute senza doverle ricordare o annotare fuori dal gioco. | P1 | Non implementata. |
| DLG-06 | Velocità del testo | Adattare la velocità della scrittura progressiva alle proprie preferenze. | P2 | Non implementata. |
| DLG-07 | Avanzamento automatico | Leggere una sequenza senza confermare ogni battuta. | P2 | Non implementata. |
| DLG-08 | Salto del testo già letto | Attraversare rapidamente contenuti già conosciuti fermandosi alle scelte. | P2 | Non implementata. |
| DLG-09 | Rollback | Tornare a uno stato precedente del dialogo, eventualmente rivedendo una scelta. | P2 | Non implementata; ammissibilità e possibilità di cambiare decisione restano da valutare. |

La cronologia rilegge il passato; il rollback cambia lo stato del gioco. Vanno
valutati come capacità distinte.

## Esplorazione e oggetti

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| EXP-01 | Click sugli elementi visibili | Cliccare gli elementi dell'ambiente e ricevere una risposta. | P0 | Parziale: la PoC in tests/playground/ seleziona cinque superfici campionando l'alpha delle texture; il router non usa collider. Non è ancora integrata nelle scene di gioco. |
| EXP-02 | Feedback degli hotspot | Capire al passaggio del puntatore quali elementi sono interattivi. | P0 | Parziale: cursore e tinta dell'elemento compaiono nella PoC; non c'è una presentazione condivisa per le scene di gioco. |
| EXP-03 | Esaminare | Ottenere una descrizione, un commento o un'informazione dall'elemento osservato. | P0 | Parziale: la PoC mostra una breve risposta descrittiva in base al materiale; non è collegata a contenuti o stati di gioco. |
| EXP-04 | Azioni contestuali | Aprire, premere, spostare, parlare o usare in base al bersaglio e al contesto. | P0 | Non implementata. |
| EXP-05 | Tap sonoro per materiale | Percepire un contatto tattile attraverso un suono coerente con legno, metallo, vetro o parete. | P0 | Parziale: la PoC riproduce campioni sintetici provvisori per quattro materiali; timbro e asset audio finali restano da valutare. Direzione nel [GDD](GDD.md#suono-delle-interazioni). |
| EXP-06 | Ispezione ravvicinata | Aprire una vista di dettaglio e cercare particolari nell'oggetto. | P1 | Non implementata. |
| EXP-07 | Raccolta degli oggetti | Prendere un oggetto dalla scena e conservarlo. | P1 | Non implementata. |
| EXP-08 | Inventario | Consultare, esaminare e selezionare gli oggetti raccolti. | P1 | Non implementata. |
| EXP-09 | Uso degli oggetti nell'ambiente | Applicare un oggetto a un bersaglio della scena. | P1 | Non implementata. |
| EXP-10 | Combinazione degli oggetti | Unire o trasformare oggetti dell'inventario. | P1 | Non implementata. |
| EXP-11 | Evidenziazione globale degli hotspot | Richiedere un aiuto per individuare gli elementi interattivi della scena. | P2 | Non implementata. |

## Indagine e deduzione

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| INV-01 | Raccolta di informazioni | Conservare nomi, fatti, osservazioni e testimonianze consultabili. | P1 | Non implementata. |
| INV-02 | Interrogatorio | Porre domande ai personaggi per ottenere informazioni e nuove piste. | P1 | Non implementata. |
| INV-03 | Presentazione delle prove | Mostrare un indizio a un personaggio per ottenere una risposta o una nuova informazione. | P1 | Non implementata. |
| INV-04 | Contraddizioni | Confrontare una dichiarazione con una prova incompatibile. | P1 | Non implementata. |
| INV-05 | Collegamento degli indizi | Mettere in relazione informazioni per ricavarne una nuova. | P1 | Non implementata. |
| INV-06 | Formulazione delle deduzioni | Esplicitare una ricostruzione attraverso persone, azioni o altri elementi e ricevere un riscontro. | P1 | Non implementata. |
| INV-07 | Aiuti progressivi | Richiedere suggerimenti sempre più espliciti quando ci si blocca. | P2 | Non implementata. |

Combinare oggetti (`EXP-10`) e collegare informazioni (`INV-05`) sono due
esperimenti diversi. Un indizio può essere un'informazione senza essere un
oggetto fisico trasportato nell'inventario.

## Playground e strumenti di sviluppo

| ID | Feature | Capacità | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| DEV-01 | Stanza playground | Provare le meccaniche in una stanza indipendente dalla storia e dal canone. | P0 | Disponibile: [Surface Taps](tests/playground/playground.tscn) è una PoC 2D raggiungibile dal SceneManager con M, poi G; si può anche eseguire direttamente dall'editor. |
| DEV-02 | SceneManager debug | Aprire il menu con il leader configurabile, ricaricare, scegliere una scena e copiare un frame. | P0 | Parziale: [scena e script presenti](features/debug/scene_manager/scene_manager.tscn); ora la selezione include Title Screen e playground; la copia immagine dipende da `wl-copy` o `xclip`. |

Il playground è una scena PoC in tests/, secondo le regole di
[AGENTS.md](AGENTS.md). Ospita esperimenti progressivi sulle categorie del
catalogo e resta indipendente dalle scene narrative e dal canone.

## Base di progetto disponibile

Queste capacità forniscono già il contesto di esecuzione. Non stabiliscono il
gameplay loop investigativo.

| ID | Capacità | Stato tecnico e riferimenti |
| --- | --- | --- |
| SYS-01 | Title Screen | Disponibile: [scena](scenes/title_screen/title_screen.tscn) con composizione, logo, versione e NEW GAME; OPTIONS e CREDITS sono voci senza funzione. |
| SYS-02 | Avvio e transizioni | Disponibile: [Main](scenes/main/main.gd) collega NEW GAME alla prima stanza vuota; [SceneFlow](features/core/scene_flow/scene_flow.gd) sostituisce la scena attiva. |
| SYS-03 | Pausa | Disponibile: [PauseMenu](features/ui/pause_menu/pause_menu.gd) si apre con ESC durante il gioco e offre RESUME e ritorno al Title Screen; OPTIONS e CREDITS sono disabilitati. |
| SYS-04 | Collegamento Ink–Godot | Parziale: [Ink Scene Director](addons/ink_scene_director/README.md) interpreta il sottoinsieme Ink documentato, espone righe, scelte, variabili e cue. Presentazione e hotspot devono essere collegati dalla scena Godot. |

## Prossima iterazione

**Da decidere.** Nessuna feature è selezionata per l'implementazione dalla sola
compilazione di questo catalogo. Quando si sceglierà il lavoro successivo,
indicare gli ID coinvolti, l'esperimento da realizzare e il comportamento da
valutare con il giocatore.

## Riferimenti della ricerca

Questi esempi orientano gli esperimenti; non sono una lista di requisiti per
Mission Hexalife né una classifica statistica delle meccaniche più diffuse.

- [Ren'Py: dialoghi](https://www.renpy.org/doc/html/dialogue.html),
  [cronologia](https://www.renpy.org/doc/html/history.html) e
  [preferenze](https://www.renpy.org/doc/html/preferences.html): riferimento
  per lettura, avanzamento e controlli del testo.
- [Return to Monkey Island](https://store.steampowered.com/app/2060130/Return_to_Monkey_Island/):
  interazioni contestuali, dialoghi reattivi e inventario.
- [Tangle Tower](https://store.steampowered.com/app/359510/Tangle_Tower/):
  esplorazione, interrogatori e puzzle.
- [Duck Detective](https://store.steampowered.com/app/2637990/Duck_Detective_The_Secret_Salami/):
  osservazione, interviste e deduzioni esplicite.
- [The Rise of the Golden Idol](https://www.playstack.com/games/rise/):
  raccolta di termini, osservazioni e ricostruzione degli eventi.
- [Ace Attorney Investigations: presentazione Capcom](https://news.capcomusa.com/lets/browse/ace-attorney-investigations-miles-edgeworth-demo-is-unleashed):
  prove, contraddizioni e collegamento delle informazioni.
