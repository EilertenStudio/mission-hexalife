# Game Design Document

Il GDD raccoglie le decisioni di design che definiscono l'esperienza
complessiva di Mission Hexalife: cosa fa il giocatore, come il gioco risponde e
come gameplay e presentazione contribuiscono all'esperienza. Non è una
specifica tecnica dell'implementazione.

Il catalogo delle capacità disponibili, degli esperimenti e delle priorità di
sviluppo è in [FEATURES.md](FEATURES.md). Una meccanica presente nel catalogo
diventa parte del design del gioco finale quando viene approvata nel GDD.

## Esperienza complessiva

Mission Hexalife è un'avventura punta e clicca. Le interazioni con ciò che il
giocatore vede devono contribuire all'atmosfera e rendere percepibile il mondo,
anche prima che un oggetto sia coinvolto in un enigma o in un passaggio
narrativo.

## Gameplay

Il gameplay loop è ancora in valutazione. Le meccaniche saranno provate in
playground indipendenti dalla storia prima di decidere come combinarle nel
gioco finale.

### Esplorazione e interazione

Il giocatore può cliccare gli elementi visibili nella scena. Il click dà una
risposta percettiva immediata; le azioni di gameplay associate agli oggetti
verranno definite quando saranno progettate.

## Presentazione audiovisiva

### Suono delle interazioni

Il click produce un suono breve e tattile, simile a un tap dato con un dito
sulla superficie. Il timbro deve riflettere con precisione il materiale
percepito: legno, metallo, vetro o parete devono avere risposte distinguibili.
Questo feedback dà presenza e atmosfera al mondo attraverso un gesto minimo.

*Shroud of Gloom* è un riferimento d'ispirazione per la cura con cui il suono
del click comunica il materiale dell'oggetto. I suoni di Mission Hexalife
saranno originali o utilizzabili con licenza compatibile; il riferimento non
implica copiare o estrarre audio dal gioco.

### Arte e interfaccia

La direzione artistica e le scelte d'interfaccia legate all'esplorazione saranno
documentate qui quando definite.

## Esperienza narrativa

Il GDD descrive come il giocatore incontra e vive la narrazione: presentazione
delle informazioni, ritmo, scelte e relazione tra racconto e interazioni. Non
riporta il canone, i profili dei personaggi o la trama in dettaglio.

I documenti di `app/gamebook/` restano il riferimento per il contenuto
narrativo: [NOTE.md](../gamebook/NOTE.md) raccoglie i fatti approvati,
[CHARACTERS.md](../gamebook/CHARACTERS.md) i profili e le voci, e
[ROADMAP.md](../gamebook/ROADMAP.md) la struttura e le proposte ancora da
sviluppare. Per il processo e i materiali Ink, vedere
[DOCUMENTATION.md](../gamebook/DOCUMENTATION.md).

## Decisioni aperte

- Quali materiali e varianti sonore servono oltre a legno, metallo, vetro e
  parete.
- Come produrre o reperire i campioni audio definitivi.
- Quali elementi della scena saranno cliccabili e quali azioni, oltre al
  feedback sonoro, attiveranno.
- Quali principi guideranno arte e interfaccia durante l'esplorazione.
