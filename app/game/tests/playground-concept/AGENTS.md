# Playground Concept

- Questa scena è una PoC autonoma per esaminare gli elementi visibili, provare
  la risposta tattile per materiale e sperimentare azioni contestuali. Non
  aggiungere fatti o contenuti della storia.
- Asset e suoni provvisori restano locali a questa cartella; estrarre in
  assets/ solo dopo una scelta esplicita di riuso nel gioco.
- I bersagli riutilizzano features/interaction/surface_tap/ locale: i pixel con alpha
  maggiore di zero definiscono l'area cliccabile; nome, descrizione di esame,
  materiale e suono si configurano nella scena Godot. Il tasto sinistro mantiene
  esame e tap; il tasto destro apre le azioni contestuali. L'ispezione ravvicinata
  e la raccolta sperimentali sono locali all'ampolla e alla fascetta metallica.
  La raccolta nasconde l'oggetto dalla scena e lo aggiunge all'inventario del
  playground. Selezionare uno slot mostra nome e descrizione; un click su un
  altro oggetto tenta la combinazione, mentre un bersaglio prova l'uso. Ampolla e
  fascetta producono un'ampolla modificata; combinare un oggetto con sé stesso
  dà un feedback non valido. L'ampolla si può appoggiare sul banco; gli altri
  usi non validi mantengono la selezione. ESC o tasto destro annullano la
  selezione. Le osservazioni selezionate su oblò, pannello, armadio e dettagli
  dell'ampolla vengono registrate una sola volta in un taccuino consultabile;
  alcune coppie definite dalla PoC possono essere collegate per aggiungere una
  deduzione al taccuino. Le combinazioni non previste mostrano un feedback senza
  aggiungere informazioni. Inventario, taccuino e regole restano locali alla
  PoC e senza canone. I pulsanti SALVA e RIPRISTINA conservano e recuperano
  manualmente stanza, oggetti, informazioni e stati dell'indagine; il ripristino
  non parte automaticamente. Un
  interlocutore marcato POC apre dal tasto destro una breve sequenza di battute;
  CONTINUA sostituisce la battuta visibile e poi presenta risposte cliccabili.
  Dopo la prima replica si possono chiedere due argomenti iniziali; ciascun
  argomento può essere chiesto una volta per progressione salvata e aggiunge la
  testimonianza al taccuino. Collegare i dettagli del tappo e del liquido
  dell'ampolla sblocca
  un terzo argomento sul tecnico e l'ampolla. Durante la conversazione si può
  anche scegliere una voce del taccuino e mostrarla al tecnico; ogni prova riceve
  una reazione contestuale una volta per progressione salvata. Nel taccuino si
  possono selezionare due voci e tentare un collegamento: le coppie configurate
  aggiungono una deduzione; una coppia già
  usata o non prevista non aggiunge altre voci. ESC chiude il dialogo. Battute,
  deduzioni e interlocutore sono provvisori e non stabiliscono contenuti della
  storia. Dal taccuino si può anche formulare un'ipotesi scegliendo persona,
  azione ed elemento; il Playground controlla se è sostenuta dalle informazioni
  raccolte e annota il solo caso previsto dalla PoC.
- Mantenere accessibile la scena dal SceneManager e apribile direttamente
  dall'editor. Non cambiare la scena predefinita del progetto.
- Il pannello a parete ha un contatto ausiliario vuoto che alimenta il fermo
  elettrico dell'armadio. Esaminare il pannello registra l'indizio; raccogliere
  la fascetta e usarla sul pannello chiude il circuito. È possibile anche
  combinare prima la fascetta con l'ampolla e poi usare l'ampolla modificata sul
  pannello: la fascetta viene trasferita al contatto e l'ampolla torna semplice.
  Solo dopo il ripristino si può aprire l'armadio. Pannello riparato, armadio e
  oggetti sono inclusi nel salvataggio manuale. Questo enigma è un esperimento
  locale, senza canone narrativo.
- Durante il dialogo il pulsante CRONOLOGIA apre un elenco scorrevole di battute,
  scelte del giocatore e reazioni alle prove. La cronologia resta locale alla
  PoC e non è collegata a Ink o alla storia; SALVA la conserva e RIPRISTINA la
  recupera solo su richiesta esplicita.
- Il testo del dialogo appare carattere per carattere quando SCRITTURA è ON;
  COMPLETA mostra subito la battuta intera e il click successivo prosegue. Il
  pulsante SCRITTURA ON/OFF mantiene la scelta nella sessione della scena. La
  velocità resta fissa e non è configurabile.
- La navigazione della PoC collega l'officina a quattro ambienti temporanei:
  SINISTRA e DESTRA raggiungono due stanze laterali distinte; AVANTI conduce al
  corridoio frontale e INDIETRO all'ingresso posteriore. Ogni stanza laterale
  riporta all'officina dalla direzione opposta; il corridoio rientra con INDIETRO
  e l'ingresso con AVANTI. Nascondere gli elementi interattivi dell'officina
  fuori dalla sua vista e conservarne lo stato durante gli spostamenti. Mantieni
  i controlli direzionali in posizioni stabili tra le stanze e non sovrapporli
  agli hotspot, alle porte rappresentate o ai pannelli della UI. Questi ambienti
  restano scollegati dalla storia. Nelle stanze fuori dall'officina, sovrapponi
  a ciascuna porta disegnata un hotspot trasparente con un feedback hover chiaro;
  il click deve chiamare la stessa transizione del relativo pulsante
  direzionale. Nell'officina aggiungi hotspot ai margini sinistro e destro,
  dove non coprono gli oggetti visibili; avanti e indietro restano disponibili
  tramite pulsante, perché lo sfondo attuale non mostra quelle uscite.
