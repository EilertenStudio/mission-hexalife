# title: Missione Hexalife - Prima prova

// Prototipo dell'apertura. Un turno operativo equivale provvisoriamente a sei ore.
// L'incontro con gli asteroidi cade al turno 12: non è ancora una durata canonica.
VAR turno = 0
VAR giorno = 1
VAR fascia = 1
VAR collisione = 12
VAR energia = 2
VAR fungo = 1
VAR porta = 0
VAR cockpit_aperto = false
VAR turno_apertura = 0
VAR danno_porta = false
VAR qc_pronto = false
VAR visto_qc = false
VAR visto_terminale_crio = false
VAR visto_capsula_crio = false
VAR visto_mappa_crio = false
VAR visto_qc_crio = false
VAR visto_guasto_capsula = false
VAR visita_rimandata = false
VAR visto_ordine = false
VAR visto_scienziato = false
VAR visto_medico = false
VAR visto_ufficiale = false
VAR circuito_tagliato = false
VAR leva_usata = false
VAR kit_recuperato = false
VAR turno_kit = 0
VAR analisi_fungo = false
VAR medico_sa = false
VAR ingegnere_sa = false
VAR ufficiale_sa = false
VAR scelta_rivelazione = false
VAR segreto_taciuto = false
VAR rapporto_letto = false

-> istruzioni

=== istruzioni ===
MISSIONE HEXALIFE — Prima prova giocabile

Giochi dal punto di vista dell'Ingegnere. Per scegliere un'azione, digita il suo numero nel terminale oppure premi il pulsante nella pagina web. Nel terminale, digita q per uscire.

Alcune azioni fanno avanzare il tempo; altre servono a osservare, leggere o parlare. In questa prova un turno equivale a circa sei ore. La crew continua ad agire mentre tu prendi decisioni, e gli eventi principali arrivano anche se non hai finito di prepararti.

Colori del terminale:
Grigio azzurro: narrazione, ambienti e azioni compiute.
Ciano: messaggi e dati del QC. # ui:qc
Rosso: allarmi e pericoli immediati. # ui:allarme
Grigio attenuato: stato della nave e tempo rimasto. # ui:stato
Verde: scelta che non fa avanzare il tempo. # ui:scelta_gratuita
Giallo: scelta che consuma un turno. # ui:scelta_turno

* [Iniziare la storia.] -> risveglio

=== risveglio ===
Il suono arriva prima dei pensieri. Apri gli occhi: una luce rossa pulsa oltre il vetro della capsula, e la sirena le risponde a ogni intervallo.

Spingi il coperchio. Non si muove. La leva rossa è sopra la tua testa. La afferri e tiri con entrambe le mani. Il vetro si solleva di colpo; l'aria pressurizzata sibila dalle bocchette laterali.

Ti sporgi. La stanza gira e le gambe cedono. Il pavimento ti urta una spalla.

Resti seduto finché la stanza rallenta. Hai la gola secca; le dita non chiudono bene. La guarnizione della capsula è annerita. Le altre capsule sono vuote. Non c'è nessuno.

Un terminale lampeggia accanto alla porta: messaggio in attesa. Sopra la maniglia, una scritta rossa: «SETTORE CRIOGENICO ISOLATO». La porta è bloccata.
-> sala_criogenica

=== sala_criogenica ===
{ visto_capsula_crio and visto_terminale_crio:
    -> riavvio_crio
}
* {not visto_capsula_crio} [Esaminare la propria capsula.] -> capsula_crio
+ [Consultare il terminale della sala criogenica.] -> terminale_crio
* [Provare la porta del corridoio.] -> porta_crio

=== porta_crio ===
Tiri la maniglia. La porta non cede. Sul pannello, «SETTORE CRIOGENICO ISOLATO» resta acceso.
-> sala_criogenica

=== capsula_crio ===
~ visto_capsula_crio = true
Un fermo del coperchio è deformato. La spia di manutenzione lampeggia; il display non mostra la cronologia. Appoggi una mano al bordo finché le dita smettono di tremare.
-> sala_criogenica

=== terminale_crio ===
{ not visto_terminale_crio:
    ~ visto_terminale_crio = true
    Il terminale apre il messaggio in attesa. Parte una registrazione audio. La voce del Capitano arriva coperta da statica: «Ingegnere. Sala motori. Alimentazione stabile al QC. Impianti vitali attivi.» # char:capitano

    La registrazione finisce senza spiegazioni. Sullo schermo restano tre richieste: mappa, allarme del QC, ritorno alla sala.
}
* {not visto_mappa_crio} [Aprire la mappa e cercare gli altri membri della crew.] -> mappa_crio
* {not visto_qc_crio} [Interrogare il QC sull'allarme.] -> allarme_crio
+ [Chiudere il terminale.] -> sala_criogenica

=== mappa_crio ===
~ visto_mappa_crio = true
La mappa localizza il Capitano nel centro di comando, il Primo Ufficiale nel corridoio, il Medico in transito verso la sala criogenica e lo Scienziato vicino al laboratorio. Sono segnali dei terminali. Da qui non puoi vedere nessuno di loro.
-> terminale_crio

=== allarme_crio ===
~ visto_qc_crio = true
«QC, leggi l'allarme attivo.» # char:ingegnere

Sul display compare la risposta: «Energia dei reattori in calo. Ritorno interrotto. Incontro con un gruppo di asteroidi previsto fra circa tre giorni, secondo il margine attuale.» # ui:allarme

La previsione dipende dall'energia disponibile per calcolare e correggere la rotta. Il messaggio non dice se la collisione sia inevitabile.
-> terminale_crio

=== riavvio_crio ===
Il terminale si spegne di colpo. Un istante dopo si spengono anche la luce rossa e la sirena. Nel buio senti soltanto il tuo respiro e un clic dietro la parete.

La riserva locale si riavvia. Le luci bianche tornano una alla volta; sul terminale compare «ALIMENTAZIONE AUSILIARIA ATTIVA». La spia della porta passa al verde. I reattori restano in avaria.
-> uscita_crio

=== uscita_crio ===
* [Aprire la porta e uscire nel corridoio.] -> corridoio_medico

=== corridoio_medico ===
Appena apri la porta, il Medico ti viene incontro dal corridoio. Si ferma abbastanza vicino da controllarti le pupille con una piccola lampada. Aspetta che tu smetta di strizzare gli occhi.

«La tua capsula ha segnalato valori irregolari. Seguimi con gli occhi.» La luce si sposta da un lato all'altro. «Bene. Adesso lascia lo stipite.» # char:medico

Obbedisci. Resti in piedi, ma una mano torna subito alla parete. Il Medico abbassa la lampada. «Non voglio fermarti se puoi lavorare. Prima dimmi cosa ti ha ordinato il Capitano e cosa farai se ti gira di nuovo la testa.» # char:medico

* [Ammettere l'instabilità e chiedere al Medico di accompagnarti alla sala motori.] -> medico_accompagna
* [Dire che puoi lavorare da solo e rimandare il controllo.] -> medico_rimanda

=== medico_accompagna ===
«Il Capitano vuole il QC alimentato. Hai visto come cammino: sarebbe ottimismo lasciarmi solo con i reattori. Vieni?» # char:ingegnere
Il Medico guarda la mano ancora appoggiata alla parete. «Vengo fino alla porta. Se la vista si sdoppia, ti fermi e mi chiami.» Non ti prende sottobraccio; cammina abbastanza vicino da poterti afferrare. # char:medico
-> sala_motori

=== medico_rimanda ===
~ visita_rimandata = true
«Il Capitano vuole il QC alimentato. Ho già passato abbastanza tempo in una capsula. Vado da solo.» # char:ingegnere
Il Medico segue con gli occhi la mano che stacchi dalla parete. «Puoi andare. Se la vista si sdoppia, lasci gli interruttori e mi chiami. Dopo il ripristino passi in infermeria.» Resta nel corridoio finché entri nella sala motori. # char:medico
-> sala_motori

=== sala_motori ===
La porta si chiude alle tue spalle. Senti i reattori funzionare a intermittenza.

Nella sala motori, una trama pallida cresce attorno alle canaline sotto tensione. I reattori erogano energia; qualcosa la intercetta.

* [Riattivare subito la linea principale. Un turno; più energia al QC, più crescita vicino ai cavi.] -> ripristino_rapido
* [Isolare prima il ramo contaminato. Un turno; meno rischio di crescita, meno energia disponibile.] -> ripristino_cauto

=== ripristino_rapido ===
~ energia = energia + 3
~ fungo = fungo + 1
~ turno = 1
~ fascia = 2
La linea principale torna viva. I monitor del QC si accendono uno dopo l'altro. Il fungo si gonfia lungo il cavo appena alimentato.
-> silenzio

=== ripristino_cauto ===
~ energia = energia + 1
~ turno = 1
~ fascia = 2
Interrompi il ramo contaminato e riapri solo le linee indispensabili. Il QC riprende a calcolare, ma segnala una riserva troppo bassa per una correzione di rotta.
-> silenzio

=== silenzio ===
Dal terminale della sala motori chiami il Capitano. «Sala motori al centro di comando. Energia ripristinata.» # char:ingegnere

Il terminale resta aperto. Nessuna risposta. # ui:allarme

«Capitano, confermi ricezione?» La tua voce torna dagli altoparlanti con un breve ritardo. Nessun'altra voce la segue. # char:ingegnere

Il Primo Ufficiale ripete la chiamata. Il QC conferma l'ultima posizione del Capitano: centro di comando. La porta non si apre. Il fungo ha raggiunto le guide e il circuito di chiusura.

Il Primo Ufficiale rilegge sul terminale la procedura di successione. «Finché non possiamo verificare che cosa sia successo, assumo il comando provvisorio. Se apriamo a forza, rischiamo i controlli dietro quella porta. Se aspettiamo, perdiamo tempo. Prima mettiamo in sicurezza la nave; nessuno si avvicini da solo.» # char:ufficiale

Nessuno di voi ha ancora visto il Capitano. Con la porta bloccata e il fungo sui circuiti, pensi prima a un'altra avaria.

Nel corridoio centrale, il terminale accanto alla porta del centro di comando è ancora acceso. Puoi consultarlo mentre gli altri cercano un varco.
-> ponte

=== ponte ===
{ turno >= collisione:
    -> asteroidi
}
{ porta >= 2 and not cockpit_aperto:
    -> apertura
}
{ not cockpit_aperto and turno >= 8:
    -> apertura_forzata
}
{ cockpit_aperto and not medico_sa and turno > turno_apertura:
    -> scoperta_medico
}

{ visto_qc_crio or visto_qc:
    Giorno {giorno} dal tuo risveglio, turno operativo {fascia}. Riserva energetica: {energia}. Crescita del fungo: {fungo}. Mancano {collisione - turno} turni all'incontro con gli asteroidi. # ui:stato
- else:
    Giorno {giorno} dal tuo risveglio, turno operativo {fascia}. Riserva energetica: {energia}. Crescita del fungo: {fungo}. Sul terminale del corridoio lampeggia un avviso del QC. # ui:stato
}

{ not cockpit_aperto:
    Il centro di comando è ancora isolato. Ogni intervento richiede tempo, e il QC continua a chiedere energia.
- else:
    Il Capitano è nel centro di comando. Il fungo ha ricoperto le bocchette dell'aria dopo la sua morte. Il Medico lavora sul corpo.
}

* {not visto_qc} [Leggere la previsione dettagliata del QC.] -> ispezione_qc
* {turno >= 4 and not visto_guasto_capsula} [Consultare il registro della propria capsula.] -> registro_capsula
* {not visto_ordine} [Rileggere l'ultimo ordine del Capitano.] -> ispezione_ordine
* {not visto_ufficiale} [Parlare con il Primo Ufficiale.] -> dialogo_ufficiale
* {not visto_medico} [Parlare con il Medico.] -> dialogo_medico
* {not visto_scienziato} [Parlare con lo Scienziato.] -> dialogo_scienziato
* {not cockpit_aperto and not circuito_tagliato and energia >= 1} [Togliere corrente alle guide della porta e liberarle. Un turno, una unità di energia.] -> taglia_circuito
* {not cockpit_aperto and not leva_usata} [Forzare un passaggio di servizio accanto alla porta. Un turno, rischio di danni.] -> usa_leva
* {not kit_recuperato} [Recuperare l'attrezzatura per analizzare il fungo. Un turno.] -> recupera_kit
* {not qc_pronto and energia >= 1} [Preparare con il QC una rotta di emergenza. Un turno, una unità di energia.] -> prepara_qc
* {cockpit_aperto and not ingegnere_sa} [Esaminare i registri dell'aria del centro di comando.] -> registro_aria
* {cockpit_aperto and not rapporto_letto} [Consultare i file lasciati dal Capitano. Un turno.] -> rapporto
* {ingegnere_sa and not scelta_rivelazione} [Decidere cosa fare della prova tecnica.] -> divulgazione
+ [Dedicare il turno alla manutenzione dei reattori. Un turno; recuperi energia, il fungo cresce.] -> manutenzione
+ [Lasciare avanzare un turno per seguire il lavoro della crew.] -> attesa

=== ispezione_qc ===
~ visto_qc = true
Il QC mostra una nube di traiettorie. Non prevede un impatto inevitabile: prevede il momento oltre il quale la nave non avrà abbastanza energia per evitarlo. # ui:qc

La stima cambia se cambia la riserva. Puoi preparare una rotta adesso o tentare una manovra più costosa alla scadenza.
-> ponte

=== registro_capsula ===
~ visto_guasto_capsula = true
Il registro segna tre tentativi falliti di apertura della tua capsula. Il primo è di tre giorni prima del tuo risveglio. La temperatura interna è salita mentre l'alimentazione del supporto vitale scendeva.

Rileggi l'ultima curva dei parametri. Se il coperchio si fosse aperto più tardi, non saresti qui a leggerla. Nessuno ti aveva parlato del guasto.
-> ponte

=== ispezione_ordine ===
~ visto_ordine = true
La registrazione è breve: sala motori, alimentazione regolare del QC, impianti vitali. Il Capitano non nomina lo Scienziato né parla di un sospetto.

Il messaggio è firmato dal Capitano. Il terminale registra che proviene dal centro di comando.
-> ponte

=== dialogo_ufficiale ===
~ visto_ufficiale = true
{ not cockpit_aperto:
    Il Primo Ufficiale tiene un dito sullo schema della porta. «La procedura prevede di isolare il circuito prima di aprire. Costa energia che serve al QC. Forzare il telaio è più rapido, ma potremmo perdere i controlli dall'altra parte. Dimmi quale rischio sai contenere.» # char:ufficiale

    «Sull'isolamento posso dirti quanto costa. Sui danni della leva non posso darti una stima onesta.» # char:ingegnere

    «Allora non la chiameremo un'operazione sicura.» Il Primo Ufficiale lascia lo schema aperto per te. «Io tengo gli altri lontani dalla porta. Tu scegli il prossimo intervento.» # char:ufficiale
- else:
    Il Primo Ufficiale osserva il centro di comando aperto. «Il Medico si occupa del corpo. Tu dei sistemi. Se qualcuno modifica i registri prima che li leggiamo, perdiamo anche la possibilità di capire che cosa è successo.» # char:ufficiale

    «Conservo i log dell'aria. Poi controllo le bocchette.» # char:ingegnere

    «Fammi avere la copia. Procedura, finché ne abbiamo una.» # char:ufficiale
}
-> ponte

=== dialogo_medico ===
~ visto_medico = true
{ visita_rimandata:
    Il Medico vede che ti appoggi al bordo del terminale. Aspetta che tu lasci la presa. «Ti ho lasciato lavorare. Non ho detto che fosse prudente. Riesci ancora a leggere i numeri senza sdoppiarli?» # char:medico
- else:
    Il Medico guarda le tue mani, poi i tuoi occhi. «La presa è più ferma. È un dato, non una dimissione.» # char:medico
}
«Mi farai il controllo completo dopo. Adesso dimmi del Capitano.» # char:ingegnere

{ not cockpit_aperto:
    Il Medico controlla i dati dei risvegli sul terminale. «Quando l'ho visto era vigile. Non so che cosa sia successo dopo. Appena entriamo, nessuno tocchi il corpo prima di me.» # char:medico
- else:
    { medico_sa:
        Il Medico abbassa la voce. «Il campione contiene l'agente di decontaminazione. Il fungo è sulle pareti, ma quel composto viene dalla nave.» # char:medico
    - else:
        Il Medico abbassa la voce. «Ho preso un campione dalle bocchette. Il fungo è sulle pareti, ma non gli attribuisco la morte senza un'analisi.» # char:medico
    }
}
-> ponte

=== dialogo_scienziato ===
~ visto_scienziato = true
Lo Scienziato ti indica una colonia accanto al quadro elettrico. «Guarda il bordo della spia. Si accende, avanza. Si spegne, si ferma.» La luce pulsa; un filamento supera la vite più vicina e poi resta immobile. # char:scienziato

«Nel rapporto c'era scritto che assorbiva corrente. Non che sapesse seguire una linea.» # char:ingegnere

{ not kit_recuperato:
    «Nel laboratorio studiavo un campione isolato. Qui è collegato ai reattori.» Lo Scienziato non distoglie gli occhi dalla vite. «Non so ancora se al buio si ritiri. Portami i sensori e lo misuriamo sulle guide della porta.» # char:scienziato
- else:
    { analisi_fungo:
        «Con i sensori ho misurato le guide: lì perde presa senza corrente. È una misura locale. Non spegnerei l'intera nave sulla base di quella.» # char:scienziato
    - else:
        «Ho i sensori. Sto confrontando le guide con il campione del laboratorio. Finché non finisco, non chiamarla una vulnerabilità.» # char:scienziato
    }
}
-> ponte

=== taglia_circuito ===
~ circuito_tagliato = true
~ energia = energia - 1
~ fungo = fungo - 1
~ porta = porta + 1
Interrompi la linea della serratura. La trama pallida si affloscia e lascia scoperto un tratto della guida, ma la porta non basta ancora a liberarsi.
-> avanza

=== usa_leva ===
~ leva_usata = true
~ danno_porta = true
~ fungo = fungo + 1
~ porta = porta + 1
Una leva apre il pannello di servizio. Il telaio cede con un colpo secco; un sensore della paratia smette di rispondere. Si è creato uno spazio, non ancora un varco sicuro.
-> avanza

=== recupera_kit ===
~ kit_recuperato = true
~ turno_kit = turno
Il laboratorio è illuminato a metà. Dietro il vetro, il corpo alieno è quasi nascosto dalla colonia. Recuperi i sensori e li consegni allo Scienziato.

«Un intervallo di lavoro. Poi saprò se la colonia sulle guide reagisce come quella del laboratorio. Non ti prometto di liberare la porta.» # char:scienziato

«Non ti ho chiesto una promessa. Dimmi cosa posso tagliare senza perderla del tutto.» # char:ingegnere
-> avanza

=== prepara_qc ===
~ qc_pronto = true
~ energia = energia - 1
Il QC calcola una rotta corta tra i frammenti più grandi. La memorizzi nei propulsori di manovra. Senza energia sufficiente, resterà soltanto un calcolo.
-> avanza

=== manutenzione ===
~ energia = energia + 2
~ fungo = fungo + 1
Spremi altro carico dai reattori. La riserva sale. In un condotto vicino, il fungo segue il nuovo flusso di corrente.
-> avanza

=== attesa ===
Rimani disponibile mentre gli altri lavorano. Il rumore dei ventilatori cambia tono; per un momento nessuno sa dire perché.
-> avanza

=== avanza ===
~ turno = turno + 1
~ giorno = 1 + turno / 4
~ fascia = 1 + turno % 4
{ turno % 2 == 0:
    ~ energia = energia - 1
    Il fungo sottrae un'altra unità alla riserva della nave.
}
{ energia < 0:
    ~ energia = 0
}
{ turno == 3:
    Il Primo Ufficiale assegna al Medico il controllo delle capsule e allo Scienziato l'analisi dei condotti. Ti comunica le decisioni dopo averle prese.
}
{ kit_recuperato and not analisi_fungo and turno > turno_kit:
    ~ analisi_fungo = true
    ~ porta = porta + 1
    Lo Scienziato ti mostra due curve sul terminale. «Senza corrente, sulle guide perde presa prima che nel laboratorio. È un confronto tra questi due punti, non una regola per tutta la nave.» Prepara un intervento localizzato e libera un'altra parte dell'accesso. # char:scienziato
}
{ turno == 6:
    Il QC aggiorna l'allarme. I frammenti più piccoli sono già visibili ai sensori esterni. La rotta preparata richiederà meno energia di una correzione improvvisata. # ui:allarme
}
{ turno == 7 and not cockpit_aperto:
    Il Primo Ufficiale ordina alla crew di raccogliere attrezzi per aprire il centro di comando al prossimo intervallo utile. Non aspetterà un'altra tua decisione.
}
-> ponte

=== apertura_forzata ===
~ cockpit_aperto = true
~ turno_apertura = turno
~ danno_porta = true
~ energia = energia - 1
~ fungo = fungo + 1
{ energia < 0:
    ~ energia = 0
}
Il Primo Ufficiale fa aprire il centro di comando dalla crew. Il telaio e una parte dei controlli cedono. Il costo della forzatura grava sulla riserva.
-> corpo

=== apertura ===
~ cockpit_aperto = true
~ turno_apertura = turno
La porta scorre di pochi centimetri, poi il varco si allarga. Hai liberato abbastanza guide; la crew entra insieme.
-> corpo

=== corpo ===
Il Capitano è accanto alla console. Le bocchette sopra di lui sono rivestite di filamenti. Il Medico chiede di non muovere il corpo.

Il Primo Ufficiale conferma la morte e assume formalmente il comando. Per un momento guarda soltanto il Capitano; poi richiama sul terminale la procedura. «Il fungo è qui. Non basta a stabilire come è morto. Medico, preleva un campione dell'aria. Ingegnere, conserva i registri del centro di comando.» # char:ufficiale

Il Medico preleva un campione. Per l'analisi gli serve un turno; non attende che tu glielo ordini.
-> ponte

=== registro_aria ===
~ ingegnere_sa = true
Il circuito dell'aria mostra un comando di decontaminazione diretto al centro di comando mentre era occupato. La procedura avrebbe dovuto servire solo un settore vuoto.

Il registro conserva l'alterazione manuale delle protezioni, ma non l'identità affidabile di chi l'ha impartita. Il fungo ha danneggiato quella parte del tracciato.

La morte può essere un omicidio. Sapere questo non significa sapere chi lo ha commesso.
-> ponte

=== rapporto ===
~ rapporto_letto = true
Nell'archivio del Capitano trovi un confronto incompleto tra il rapporto sul fungo e l'inventario del carico. Alcuni campioni compaiono in un documento e scompaiono nell'altro.

Il Capitano aveva chiesto un chiarimento poco prima di mandarti in sala motori. I dettagli della risposta non sono qui. Una discrepanza non è ancora una confessione.
-> avanza

=== divulgazione ===
* [Consegnare subito il registro al Primo Ufficiale.] -> rivela
* [Tenere per ora la scoperta per sé.] -> tace

=== rivela ===
~ scelta_rivelazione = true
~ ufficiale_sa = true
«Ho trovato un comando manuale di decontaminazione. Le protezioni erano disattivate mentre il Capitano era dentro.» Gli passi il registro. # char:ingegnere

Il Primo Ufficiale legge la riga due volte. «Isoliamo i terminali che possono impartire quel comando. Il registro non dice chi è stato; nessuno faccia un nome finché non abbiamo altro.» # char:ufficiale
-> ponte

=== tace ===
~ scelta_rivelazione = true
~ segreto_taciuto = true
Chiudi il registro. Una prova non divulgata può essere protetta; può anche lasciare gli altri al buio mentre lavorano accanto all'assassino.
-> ponte

=== scoperta_medico ===
~ medico_sa = true
Il Medico torna dal laboratorio con il campione. Lascia che il valore sullo schermo si stabilizzi prima di parlare. «È l'agente di decontaminazione della nave. Il fungo non lo produce. So cosa ha respirato il Capitano; non so chi abbia attivato la procedura.» # char:medico

Controlla ancora una volta la cartella del Capitano, poi informa il Primo Ufficiale. Non aspetta il tuo permesso. Il composto spiega la morte; la sua presenza nell'aria richiede un'indagine su chi abbia attivato la procedura.
~ ufficiale_sa = true
{ segreto_taciuto:
    Il Primo Ufficiale controlla l'ora dell'ultimo accesso al registro. Poi ti guarda. «Hai aperto i dati dell'aria prima dell'analisi. C'era già il comando di decontaminazione?» # char:ufficiale
    -> confronto_registro
}
-> ponte

=== confronto_registro ===
* [Ammettere che avevi visto il comando e spiegare perché hai taciuto.] -> confronto_ammette
* [Limitarti a dire che il registro non identifica chi ha agito.] -> confronto_elude

=== confronto_ammette ===
«Sì. Ho visto il comando manuale. Non sapevo se il registro fosse integro e non volevo accusare qualcuno senza una prova.» # char:ingegnere
«La prossima volta dammi anche il dubbio.» Il Primo Ufficiale torna al terminale. «Avrei potuto far controllare gli accessi ore fa.» # char:ufficiale
-> ponte

=== confronto_elude ===
«Il registro non identifica chi ha dato l'ordine.» # char:ingegnere
«Non era la mia domanda.» Il Primo Ufficiale chiude la copia dei dati, senza toglierti l'accesso. «Per ora abbiamo ancora bisogno che tu li legga.» # char:ufficiale
-> ponte

=== asteroidi ===
Il QC interrompe tutte le conversazioni. «Finestra di manovra. Esecuzione ora.» # ui:allarme

Per un istante la nave sembra immobile. Poi i propulsori cercano la rotta tra i frammenti.

{
    - qc_pronto and energia >= 4 and fungo <= 3:
        La nave attraversa il varco previsto. Un frammento sfiora lo scafo senza aprirlo. La missione prosegue sulla stessa nave, con abbastanza energia per continuare l'indagine.
    - qc_pronto and energia >= 2:
        La rotta tiene, ma il fungo assorbe potenza durante la correzione. Un impatto laterale danneggia un settore. Restate vivi; la ricerca della verità sarà più difficile.
    - else:
        Il QC improvvisa con la riserva rimasta. La nave evita il blocco più grande e urta una pioggia di detriti. I sistemi reggono appena. Restate a bordo, con meno settori accessibili e una crisi più grave.
}

{ rapporto_letto:
    Nel rumore successivo all'impatto ripensi ai campioni scomparsi dall'inventario. Qualunque cosa il Capitano avesse intuito, qualcuno voleva impedirgli di agire.
}
{ not rapporto_letto:
    Il Capitano è morto prima di spiegare che cosa stava cercando. La sua ultima indagine è ancora sul terminale.
}
{ danno_porta:
    Il varco danneggiato del centro di comando resta aperto. La colonia ha trovato un altro passaggio verso i sistemi della nave.
}
{ ingegnere_sa and not scelta_rivelazione:
    Il registro dell'aria è ancora aperto davanti a te. Non hai deciso a chi mostrarlo.
}

La nave continua verso la Terra. Il fungo è ancora a bordo. Anche chi ha ucciso il Capitano.

Fine della prima prova giocabile.
-> END
