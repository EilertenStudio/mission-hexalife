INCLUDE v3/events.ink
INCLUDE v3/props.ink
INCLUDE v3/rooms.ink
INCLUDE v3/utils.ink


// ============================================================================================================= //
//                                                       START                                                   //
// ============================================================================================================= //
// + [ New Game ]
    -> ch_1.sh_1_ph_1


// ============================================================================================================= //
//                                                     CHAPTERS                                                  //
// ============================================================================================================= //

=== ch_1 ===

    = sh_1_ph_1
        - (context)
            <- print.location(-> rm_cryogenic_room)
            <- print.event(-> ev_ship.emergency)
            <- print.paragraph

            Ti svegli dopo aver passato non sai quanto tempo nella capsula criogenica
            \ - Vedi altre 3 capsule criogeniche aperte e vuote
            \ - Sei da solo nella stanza
            \ - Il personaggio giocante e' in stato di confusione

        - (actions)
            <- print.separator

            + $ Ispezioni il terminale
                -> rm_cryogenic_room.terminal_inspect(-> actions)
            + $ Ispezioni le altre capsule 
                -> rm_cryogenic_room.capsule_inspect(-> actions)
            + $ Attraversi la porta a sinistra 
                -> rm_cryogenic_room.door_sx_walk(-> ch_1.sh_2_ph_1)
            

    = sh_2_ph_1
        - (context)
            <- print.location(-> rm_ship_bridge)
            <- print.event(-> ev_ship.emergency)
            <- print.paragraph

            Camminando per il ponte incontri una figura che si avvicina velocemente: e' il MEDICO di bordo
            Il MEDICO ti approccia iniziando una conversazione
            \ - Scopri il nome del MEDICO e che il personaggio giocante potrebbe avere vuoti di memoria
            \ - Scopri che il personaggio giocante e' l'INGEGNERE della nave
            Il MEDICO ti chiede di fargli delle domande mentre analizza il tuo stato di salute

        - (talk)
            <- print.separator


            * $ Chiedi che cosa sta succedendo
                Il MEDICO ti spiega la situazione:
                \ - Scopri che la nave ha attivato automaticamente il protocollo di emergenza che coinvolge il risveglio delle capsule
                \ - Scopri che le capsule si sono aperte gradualmente per un malfunzionamento del sistema
                -> talk
            * $ Chiedi cosa ha attivato il protocollo di emergenza
                Il MEDICO ti spiega la causa:
                \ - Scopri che una specie di fungo alieno sta invadendo velocemente l'astronave
                \ - Scopri che il fungo ha la capacita' di assorbire energia elettrica
                -> talk
            * ->
                Il MEDICO finisce di analizzare il tuo stato di salute:
                \ - Scopri che la memoria dell personaggio giocante dovrebbe essere intatta
                \ - Il personaggio giocante esce dallo stato di confusione
                -> ch_1.sh_2_ph_2
    
    = sh_2_ph_2
        - (context)
            <- print.separator

            Improvvisamente l'OloNav del MEDICO riceve una chiamata dal CAPITANO
            \ - Ti viene assegnata la missione di recuperare il tuo equipaggiamento
            \ - Ti viene assegnata la missione di indagare sullo stato della stanza dei macchinari

        - (talk)
            <- print.separator
            
            
            
            * -> DONE
            
            
            



