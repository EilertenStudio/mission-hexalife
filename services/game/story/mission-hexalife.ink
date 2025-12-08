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

+ [ Svegliati ]
    -> sh_1.ph_1

// ============================================================================================================= //
//                                                   STORYBOARD                                                  //
// ============================================================================================================= //

== sh_1 ==
    
    = ph_1
        - (context)
            <- print.location(-> rm_cryogenic_room)
            <- print.event(-> ev_ship.emergency)
            <- print.narration
    
            <- ch_player
                Ti svegli dopo aver passato non sai quanto tempo nella capsula criogenica
                \ - Vedi altre 3 capsule criogeniche aperte e vuote
                \ - Sei da solo nella stanza
                \ - Sei in uno stato di confusione
    
        - (spend_time)
            {spend_time <= 3: 
                <- print.actions
                <- ch_player
                    Puoi interagire con la stanza
            }
                
        
            * [ Ispeziona il terminale ]
                -> rm_cryogenic_room.terminal_inspect(-> ch_player, -> spend_time)
                
            * [ Ispeziona le altre capsule ]
                -> rm_cryogenic_room.capsule_inspect(-> ch_player, -> spend_time)
            
            * [ Attraversa la porta a sinistra ]
                -> rm_cryogenic_room.door_sx_locked(-> ch_player, -> spend_time)
                
            * -> sh_1.ph_2
                    
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
                -> rm_cryogenic_room.door_sx_walk(-> ch_player, -> sh_2.ph_1)
            
== sh_2 ==
    
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
                    <> 
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
            
            * -> sh_2.ph_2
        
        = ph_2
            - (context)
                <- print.narration
                
                Improvvisamente l'OloNav del MEDICO receve una chiama dal CAPITANO.
                
                <- ch_captain
                    TBD
                    \- Spiega che parlando con ARTEMIS 
            
                    
//                 Il MEDICO ti spiega la situazione:
//                 \ - Scopri che la nave ha attivato automaticamente il protocollo di emergenza che coinvolge il risveglio delle capsule
//                 \ - Scopri che le capsule si sono aperte gradualmente per un malfunzionamento del sistema
//                 -> talk
//             * $ Chiedi cosa ha attivato il protocollo di emergenza
//                 Il MEDICO ti spiega la causa:
//                 \ - Scopri che una specie di fungo alieno sta invadendo velocemente l'astronave
//                 \ - Scopri che il fungo ha la capacita' di assorbire energia elettrica
//                 -> talk
//             * ->
//                 Il MEDICO finisce di analizzare il tuo stato di salute:
//                 \ - Scopri che la memoria dell personaggio giocante dovrebbe essere intatta
//                 \ - Il personaggio giocante esce dallo stato di confusione
//                 -> DONE
//                 // -> ch_1.sh_2_ph_2

// = sh_2_ph_2
//     - (context)
//         <- print.separator

//         Improvvisamente l'OloNav del MEDICO riceve una chiamata dal CAPITANO
//         \ - Ti viene assegnata la missione di recuperare il tuo equipaggiamento
//         \ - Ti viene assegnata la missione di indagare sullo stato della stanza dei macchinari

//     - (talk)
//         <- print.separator
        
        
        
-> END
