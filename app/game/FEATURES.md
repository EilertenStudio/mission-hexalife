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
verifica runtime. Il Playground Concept conserva gli esperimenti già realizzati
e non li rende disponibili nella scena di gioco. Playground V1 è uno scaffold
vuoto da cui partire per le prove visuali e le meccaniche reali. Il codice del
plugin Ink è presente, ma non è integrato nella scena di gioco attuale.
Aggiornare stati, limiti e riferimenti quando cambia concretamente
un'implementazione, specificando cosa è stato verificato.

## Dialoghi e lettura

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico e limiti |
| --- | --- | --- | --- | --- |
| DLG-01 | Dialogo sequenziale e avanzamento manuale | Leggere una battuta e proseguire volontariamente. | P0 | Parziale: il [plugin Ink](addons/ink_scene_director/README.md) emette paragrafi; una UI prototipale nel Playground Concept mostra battute una alla volta e consente l'avanzamento manuale. Codice aggiunto, non verificato a runtime; non è ancora integrata nelle scene di gioco né collegata a Ink. |
| DLG-02 | Scelte di risposta | Selezionare una domanda, un atteggiamento o una decisione e ricevere una risposta coerente. | P0 | Parziale: il plugin Ink espone e seleziona scelte; nel Playground Concept il dialogo del tecnico presenta due risposte cliccabili con repliche diverse. Codice aggiunto, non verificato a runtime; interazione locale, non collegata a Ink né alle scene di gioco. |
| DLG-03 | Scrittura progressiva configurabile | Vedere il testo apparire, completarlo con un input e poter disabilitare l'effetto. | P1 | Parziale: nel dialogo del Playground Concept il testo appare carattere per carattere; il pulsante COMPLETA mostra subito la battuta intera, poi CONTINUA avanza. L'interruttore SCRITTURA ON/OFF controlla l'effetto anche sulle battute successive. Velocità fissa; la preferenza è inclusa nel salvataggio manuale (SYS-05); non è collegata a Ink o alla storia. Codice aggiunto, non verificato a runtime. |
| DLG-04 | Argomenti di conversazione | Scegliere temi di discussione, riconoscere quelli già affrontati e sbloccarne di nuovi dopo una scoperta. | P1 | Parziale: nel Playground Concept il tecnico ha due argomenti iniziali; collegare tappo e liquido dell'ampolla nel taccuino sblocca un terzo argomento. Gli argomenti si possono chiedere una volta per progressione salvata; dialogo e sblocco sono locali alla PoC, senza integrazione con Ink o la storia; codice aggiunto, non verificato a runtime. |
| DLG-05 | Cronologia dei dialoghi | Rileggere le informazioni ricevute senza doverle ricordare o annotare fuori dal gioco. | P1 | Parziale: nel Playground Concept il pulsante CRONOLOGIA apre un pannello scorrevole con battute, risposte del giocatore, argomenti chiesti e reazioni alle prove. La cronologia resta locale e non è collegata a Ink o alla storia; il salvataggio manuale della PoC la conserva. Codice aggiunto, non verificato a runtime. |
| DLG-06 | Velocità del testo | Adattare la velocità della scrittura progressiva alle proprie preferenze. | P2 | Non implementata: la scrittura progressiva del Playground Concept usa una velocità fissa non configurabile. |
| DLG-07 | Avanzamento automatico | Leggere una sequenza senza confermare ogni battuta. | P2 | Non implementata. |
| DLG-08 | Salto del testo già letto | Attraversare rapidamente contenuti già conosciuti fermandosi alle scelte. | P2 | Non implementata. |
| DLG-09 | Rollback | Tornare a uno stato precedente del dialogo, eventualmente rivedendo una scelta. | P2 | Non implementata; ammissibilità e possibilità di cambiare decisione restano da valutare. |

La cronologia rilegge il passato; il rollback cambia lo stato del gioco. Vanno
valutati come capacità distinte.

## Esplorazione e oggetti

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| EXP-01 | Click sugli elementi visibili | Cliccare gli elementi dell'ambiente e ricevere una risposta. | P0 | Parziale: Playground Concept seleziona le superfici campionando l'alpha delle texture; il router non usa collider. Non è ancora integrata nelle scene di gioco. |
| EXP-02 | Feedback degli hotspot | Capire al passaggio del puntatore quali elementi sono interattivi. | P0 | Parziale: cursore e tinta dell'elemento compaiono nel Playground Concept; non c'è una presentazione condivisa per le scene di gioco. |
| EXP-03 | Esaminare | Ottenere una descrizione, un commento o un'informazione dall'elemento osservato. | P0 | Parziale: nel Playground Concept il click mostra nome e descrizione specifici del bersaglio; testi e stati sono locali alla prova e non collegati alla storia o alle scene di gioco. |
| EXP-04 | Azioni contestuali | Aprire, premere, spostare, parlare o usare in base al bersaglio e al contesto. | P0 | Parziale: nel Playground Concept il tasto destro apre il menu contestuale dell'armadio e consente di aprirlo; lo stato locale si conserva con il salvataggio manuale della PoC (SYS-05), senza progressione narrativa. |
| EXP-05 | Tap sonoro per materiale | Percepire un contatto tattile attraverso un suono coerente con legno, metallo, vetro o parete. | P0 | Parziale: il Playground Concept riproduce campioni sintetici provvisori per quattro materiali; timbro e asset audio finali restano da valutare. Direzione nel [GDD](GDD.md#suono-delle-interazioni). |
| EXP-06 | Ispezione ravvicinata | Aprire una vista di dettaglio e cercare particolari nell'oggetto. | P1 | Parziale: nel Playground Concept si apre una vista ingrandita dell'ampolla con due dettagli cliccabili; contenuti locali alla PoC e non collegati alla storia. |
| EXP-07 | Raccolta degli oggetti | Prendere un oggetto dalla scena e conservarlo. | P1 | Parziale: il Playground Concept raccoglie ampolla e fascetta metallica in un inventario locale; posizione e trasformazioni si conservano con il salvataggio manuale della PoC (SYS-05). |
| EXP-08 | Inventario | Consultare, esaminare e selezionare gli oggetti raccolti. | P1 | Parziale: nel Playground Concept compaiono slot per ampolla e fascetta; selezionandoli si leggono le descrizioni e si attivano uso e combinazione. UI e contenuti restano locali alla PoC, senza modello generale; i progressi si conservano con il salvataggio manuale (SYS-05). |
| EXP-09 | Uso degli oggetti nell'ambiente | Applicare un oggetto a un bersaglio della scena. | P1 | Parziale: nel Playground Concept l'ampolla selezionata si può appoggiare sul banco da lavoro; sugli altri bersagli appare un feedback senza effetto e la selezione resta attiva. Regola locale alla PoC, senza logica narrativa o sistema generale di compatibilità. |
| EXP-10 | Combinazione degli oggetti | Unire o trasformare oggetti dell'inventario. | P1 | Parziale: combinare ampolla e fascetta produce un'ampolla con fascetta; combinare un oggetto con sé stesso dà un esito non valido. La trasformazione si conserva con il salvataggio manuale della PoC (SYS-05), senza regole o risultati narrativi. |
| EXP-13 | Enigma ambientale | Usare osservazione, raccolta e uso di un oggetto per cambiare lo stato dell'ambiente e sbloccare un elemento. | P1 | Parziale: nel Playground Concept la fascetta metallica ripristina il circuito del pannello e sblocca l'armadio. Può essere usata direttamente o dopo averla combinata con l'ampolla; stato del pannello e dell'armadio incluso nel salvataggio manuale (SYS-05). Enigma locale, senza progressione narrativa. Codice aggiunto, non verificato a runtime. |
| EXP-11 | Evidenziazione globale degli hotspot | Richiedere un aiuto per individuare gli elementi interattivi della scena. | P2 | In valutazione; non selezionata per l'implementazione nel Playground Concept. |
| EXP-12 | Navigazione tra ambienti | Spostarsi a sinistra, a destra, avanti e indietro tra stanze collegate. | P1 | Parziale: nel Playground Concept i margini laterali dell'officina sono hotspot e avanti/indietro restano sui pulsanti; nelle quattro stanze collegate le porte visibili sono cliccabili e riportano all'officina nella direzione opposta. I pulsanti restano un'alternativa. Stato mantenuto durante gli spostamenti; prova locale, senza progressione narrativa. |

## Indagine e deduzione

| ID | Feature | Esperienza da offrire | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| INV-01 | Raccolta di informazioni | Conservare nomi, fatti, osservazioni e testimonianze consultabili. | P1 | Parziale: implementazione aggiunta nel Playground Concept, non verificata a runtime; alcune osservazioni ambientali e dettagli esaminati vengono registrati una sola volta in un taccuino consultabile. Dati locali alla PoC, conservabili con il salvataggio manuale (SYS-05). |
| INV-02 | Interrogatorio | Porre domande ai personaggi per ottenere informazioni e nuove piste. | P1 | Parziale: nel Playground Concept si può interrogare il tecnico su pannello e armadio; ogni argomento è disponibile una volta per progressione salvata e la risposta viene registrata nel taccuino. Prototipo locale, non collegato a Ink o alla storia; codice aggiunto, non verificato a runtime. |
| INV-03 | Presentazione delle prove | Mostrare un indizio a un personaggio per ottenere una risposta o una nuova informazione. | P1 | Parziale: durante il dialogo col tecnico nel Playground Concept si può scegliere una voce del taccuino e mostrargliela; ogni voce produce una reazione contestuale una volta per progressione salvata. Battute e reazioni restano locali alla PoC, senza effetti sulla storia; codice aggiunto, non verificato a runtime. |
| INV-04 | Contraddizioni | Confrontare una dichiarazione con una prova incompatibile. | P1 | Esclusa dal gioco; non implementare. |
| INV-05 | Collegamento degli indizi | Mettere in relazione informazioni per ricavarne una nuova. | P1 | Parziale: nel taccuino del Playground Concept si possono selezionare due voci e tentare un collegamento. Tre coppie predefinite aggiungono una deduzione; le altre danno feedback senza creare informazioni. Dati e regole locali alla PoC; taccuino e collegamenti si conservano con il salvataggio manuale (SYS-05), senza effetti sulla storia. |
| INV-06 | Formulazione delle deduzioni | Esplicitare una ricostruzione attraverso persone, azioni o altri elementi e ricevere un riscontro. | P1 | Parziale: il Playground Concept offre una composizione guidata persona/azione/elemento per formulare l'ipotesi sulla spia verde. Il riscontro dipende dalle informazioni raccolte; una formulazione supportata viene annotata nel taccuino. Un solo caso PoC, salvabile manualmente, senza effetti sulla storia; codice aggiunto, non verificato a runtime. |
| INV-07 | Aiuti progressivi | Richiedere suggerimenti sempre più espliciti quando ci si blocca. | P2 | Esclusa dal gioco; non implementare. |

Combinare oggetti (`EXP-10`) e collegare informazioni (`INV-05`) sono due
esperimenti diversi. Un indizio può essere un'informazione senza essere un
oggetto fisico trasportato nell'inventario.

## Playground e strumenti di sviluppo

| ID | Feature | Capacità | Priorità | Stato tecnico |
| --- | --- | --- | --- | --- |
| DEV-01 | Playground indipendenti | Provare meccaniche e direzioni visuali fuori dalla storia e dal canone. | P0 | Disponibile: [Playground Concept](tests/playground-concept/playground_concept.tscn) conserva le meccaniche sperimentate; [Playground V1](tests/playground-v1/playground_v1.tscn) è lo scaffold vuoto per la prossima prova. Entrambi sono raggiungibili dal SceneManager. |
| DEV-02 | SceneManager debug | Aprire il menu con il leader configurabile, ricaricare, scegliere una scena e copiare un frame. | P0 | Parziale: [scena e script presenti](features/debug/scene_manager/scene_manager.tscn); il selettore include Title Screen e i due playground in un sottomenu; la copia immagine dipende da `wl-copy` o `xclip`. |

Le scene dei playground sono PoC in tests/, secondo le regole di
[AGENTS.md](AGENTS.md). Il Playground Concept conserva gli esperimenti di
meccaniche; Playground V1 è la base per le prossime prove visuali e di gioco.
Entrambi restano indipendenti dalle scene narrative e dal canone.

## Base di progetto disponibile

Queste capacità forniscono già il contesto di esecuzione. Non stabiliscono il
gameplay loop investigativo.

| ID | Capacità | Stato tecnico e riferimenti |
| --- | --- | --- |
| SYS-01 | Title Screen | Disponibile: [scena](scenes/title_screen/title_screen.tscn) con composizione, logo, versione e NEW GAME; OPTIONS e CREDITS sono voci senza funzione. |
| SYS-02 | Avvio e transizioni | Disponibile: [Main](scenes/main/main.gd) collega NEW GAME alla prima stanza vuota; [SceneFlow](features/core/scene_flow/scene_flow.gd) sostituisce la scena attiva. |
| SYS-03 | Pausa | Disponibile: [PauseMenu](features/ui/pause_menu/pause_menu.gd) si apre con ESC durante il gioco e offre RESUME e ritorno al Title Screen; OPTIONS e CREDITS sono disabilitati. |
| SYS-04 | Collegamento Ink–Godot | Parziale: [Ink Scene Director](addons/ink_scene_director/README.md) interpreta il sottoinsieme Ink documentato, espone righe, scelte, variabili e cue. Presentazione e hotspot devono essere collegati dalla scena Godot. |
| SYS-05 | Salvataggio e ripristino manuale | Parziale: pulsanti SALVA e RIPRISTINA nel Playground Concept conservano stanza, oggetti e trasformazioni, pannello riparato, armadio aperto, taccuino, cronologia e stati dell'indagine nel file locale `user://playground_save.json`. RIPRISTINA chiede conferma e non parte automaticamente; non è integrato nelle scene di gioco. |

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
