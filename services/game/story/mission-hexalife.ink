INCLUDE lib/metadata.ink
INCLUDE lib/rooms.ink
INCLUDE lib/events.ink
INCLUDE lib/props.ink
INCLUDE lib/characters.ink
INCLUDE lib/utils.ink

// ============================================================================================================= //
//                                                   METADATA                                                    //
// ============================================================================================================= //
<- print.separator

Titolo: Mission HeXalife

Versione: 0.0.4

Autori:
    \- JervNorsk
    \- GrumpyWolverine
    \- Chinni2D
    \- Raino98

<- print.separator

Introduzione:

    In un futuro distopico...

+ [ Atto 1 \| Risveglio \| Scena 1 ]
    -> sh_player_waking.ph_1

+ [ Atto 1 \| Risveglio \| Scena 2 ]
    -> sh_doctor_encounter.ph_1

// ============================================================================================================= //
//                                                   STORYBOARD                                                  //
// ============================================================================================================= //

== sh_player_waking ==
    
    = ph_1
        # CLEAR
        - (context)
            <- print.location(-> rm_cryogenic_room)
            <- print.event(-> ev_ship.emergency)
            <- print.narration
    
            <- ch_player
                Ti svegli dopo aver passato non sai quanto tempo nella capsula criogenica
                
        - (spend_time)
            {spend_time <= 3: 
                <- print.actions
                <- ch_player
                    Puoi interagire con la stanza
                    \- Sei da solo nella stanza
                    \- Sei in uno stato di confusione
                    \- Vedi lo schermo di un terminale che brilla di una luce rossa
                    \- Vedi altre 3 capsule criogeniche aperte e vuote
                    \- Vedi una porta chiusa sulla parete di sinistra, <>
                    {spend_time <= 3: c'e' una spia rossa sulla parte alta a destra }
                    {spend_time > 3: c'e' una spia verde sulla parte alta a destra }
            }
                
        
            * [ Ispeziona il terminale ]
                -> rm_cryogenic_room.terminal_inspect(-> ch_player, -> spend_time)
                
            * [ Ispeziona le altre capsule ]
                -> rm_cryogenic_room.capsule_inspect(-> ch_player, -> spend_time)
            
            * [ Attraversa la porta a sinistra ]
                -> rm_cryogenic_room.door_sx_locked(-> ch_player, -> spend_time)
                
            * -> sh_player_waking.ph_2
                    
    = ph_2
        - (context)
            <- print.narration
            
            <- ch_environment
                Le luci si spegnono per qualche secondo facendo piombare tutto nel buio
            
            <- print.event(-> ev_ship.normal)
            
            // <- print.narration
            
            // <- ch_player
            //     "La nave sembra essere uscita dallo stato di emergenza. Ora dovrei riuscire ad uscire..."
        
        - (exit_room)
            <- print.actions
            
            <- ch_player
                Puoi interagire con la stanza
                
            * [ Attraversa la porta a sinistra ]
                -> rm_cryogenic_room.door_sx_walk(-> ch_player, -> sh_doctor_encounter.ph_1)
            
== sh_doctor_encounter ==
    
    // Prova di dialogo
    = ph_1
        - (context)
            <- print.location(-> rm_ship_bridge)
            <- print.event(-> ev_ship.normal)
            <- print.narration
    
            <- ch_player
                Esci dalla stanza e ti ritrovi sul ponte della nave.
                <> Dopo qualche passo incontri una figura che si avvicina velocemente
                
            <- ch_unknown
                La figura si approccia e ti forza al dialogo
            
            <- ch_doctor
                "Vedo che sei sveglio! E gia' riesci a camminare! Senza di te non possiamo risolvere il problema mio caro Ingeniere" 
            
            // IPOTESI: 
            // ! Lo stato di criogenizzazione non causa problemi di memoria il processo di congelamento/scongelamento e' veloce.
            
            // DERIVATO:
            // > Aiuterebbe il giocatore a immedesimarsi di piu'
            // > Potrebbe spiegare lo stato confusionale del giocatore
            
            
            <- ch_player
                Scopri che sei l'INGEGNERE della nave. Lo guardi in stato confusionale
            
            <- ch_doctor
                Ti guarda attenamente poi si gratta la testa. 
                <> "Ora controllero' il tuo stato di salute, cerca di non muoverti."
    
        - (talk)
            {talk <= 3: 
                <- print.actions
                <- ch_player
                    Senti il silenzio che piomba su tutto il ponte mentre il MEDICO ti controlla.
            }
            
    
            * [ Chiedi per quanto tempo sei stato criogenizzato ]
                <- ch_player
                    "Per quanto ho dormito la dentro?"
                
                <- ch_doctor
                    Senza alzare la testa risponde "Sono passati 2 mesi da quando abbiamo lasciato quel pianeta"
                
                <- ch_player
                    Strizzi gli occhi nello sforzo di ricordare
                
                <- ch_doctor
                    "Non abbiamo ancora raggiunto il punto gravitazionale"
                    -> talk
            
            * [ Chiedi perche' sei confuso ]
                
                <- ch_player
                    "Mi sento confuso, e' successo qualcosa alla mia capsula?"
                
                <- ch_doctor
                    "Si, le capsule hanno avuto un malfunzionamento, in particolare la tua. Abbiamo seguito il protocollo di emergenza con le nostre capacita' e siamo riusciti ad aggirare il blocco del computer di bordo ."
                    -> talk
                
            * [ Chiedi che cosa ha causato il problema ]
                
                <- ch_player
                    Sforzandoti di essere lucido cerchi di mettere in ordine le idee
                    <> "Cosa ha causato l'emergenza? Un asteroide ci ha colpiti?"
                
                // IPOTESI: 
                // ! Nello spazio la velocita' raggiunta e' costante perche' nel vuoto.
                // > La velocita' e' contrastata dall'atrito attraversando delle zone dense di polveri
                // > La velocita' e' contrastata anche dalle forze gravitazionali
                
                <- ch_doctor
                    "I motori della nave hanno avuto un improvviso calo della potenza riducendo cosi' la capacita' di ARTEMIS di seguire la traiettoria."
                
                <- ch_player
                    Seguendo il filo logico capisci che la situazione e' grave.
                    -> talk
            
            * -> sh_doctor_encounter.ph_2
        
    = ph_2
        - (context)
            <- print.narration
            
            <- ch_doctor
                Finisce la visita e ti guarda con aria sollevata.
            
            <- ch_doctor
                "Ok sembra tutto apposto. Relativamente intendo. Essere risvegliato cosi' lentamente e' stato motivo di preoccuppazione, poteva succedere di tutto. Letteralmente. Ictus, necrosi, paralisi muscolare, perdita della vista, cambi di identita' o della capacita' cognitiva. Beh diciamo che un sintomo ce l'hai: sembra che tu abbia una leggera commozione celebrale; ma ti passera' presto."
            
            <- ch_player
                Annuisci 
                    -> sh_captain_encounter.ph_1
                
== sh_captain_encounter ==
                
    = ph_1
        - (context)
            <- print.narration
            <- ch_doctor
                L'OloNav sulla sua tempia suona. 
                \- Risponde toccando il dispositivo.
                \- Appare un piccolo ologramma del capitano davanti a lui
            
            <- ch_captain
                Si guarda intorno e ti da l'attenzione
                \- Ti saluta rinquorato che stai bene
                \- Spiega che hanno identificato la causa del malfunzionamento: un fungo alieno sta invadendo la nave
                \- Chiede all'INGEGNERE di raggiungere immediatamente la sala macchine e di aggiornarsi con il BIOLOGO
        
        - (talk)
            <- print.actions
            
            \- TBD
            
            * [ Accetti l'incarico ]
                <- ch_player
                    Accetti l'incarico e ti dirigi verso la sala macchine
                    -> sh_player_mission_1.ph_1
   
== sh_player_mission_1 ==
   = ph_1
        - (context)
            <- print.location(-> rm_engine_room)
            <- print.narration
            
            <- ch_player
                Apri la porta della sala macchine e il calore dei motori ti inonda.
                
            <- ch_biologist
                Attira la tua attenzione
                \- Spiega che dalle analisi fatte il fungo riesce ad assorbire energia e a velocizzare la propria espansione
                \- Ti assegna l'incarico di spegnere il primo reattore e di bloccare tutti gli afflussi di energia sulla zona interessata dall'invasione del fungo
                \- Ti spiega che per interagire con i macchinari e' necessario usare il MultiTool ???
                \- Ti spiega che per interagire con i macchinari e' necessario usare il Terminale della stanza ???
                
            
         - (actions)
            <- print.actions
            
            \- TBD
            
            * [ Interagisci con il pannello di controllo dei reattori ] 
                -> sh_player_mission_1.ph_2
                
    = ph_2
        - (context)
            <- print.puzzle
                \- Introduzione alla meccanica dei puzzle ???
                \- Il BIOLOGO analizza la situazione e chiama il capitano all'OloNav per richiedere l'autorizzazione per lo spegnimento del primo reattore
                \- Svolgimento del puzzle da parte del giocatore
            
            <- print.narration
                
            <- ch_biologist
                Chiama il capitano sull'OloNav 
                \- Spiega che dopo questa operazione il sistema ha poca energia per funzionare e mantenere i sistemi vitali della nave operativi
                \- Spiega che il giocatore deve manovrare l'energia elettrica sulle porte per garantirne l'accesso
            
-> END
