// ============================================================================================================= //
//                                                       START                                                   //
// ============================================================================================================= //
+ [ New Game ]
    -> ch_1.sh_0

// ============================================================================================================= //
//                                                     LIBRARY                                                   //
// ============================================================================================================= //

== pr_door ==
    ] Ti avvicini alla porta
    # TODO: animazione
    ] > La porta si apre
    # TODO: transizione VFX
    ] > Attraversi la porta
    = walk(-> return_to)


== pr_terminal ==

    = inspect(-> return_to)
        ] Ti avvicini al terminale per analizzarne il contenuto
        ] - A schermo e' presente lo stato della nave e dove il personale e' richiesto
        ] - A schermo e' presente il tempo di scongelamento delle capsule
        ] - A schermo e' presente il tempo di criogenesi del presonale
        + [Back] -> return_to

== rm_cryogenic_room ==
    ] Cryogenic Room
    ] - Al centro della stanza ci sono disposte 4 capsule criogeniche
    ] - Sulla parete centrale sono disposti una serie di schermi e un terminale
    ] - Sulla parete sinistra e presente una porta che si collega al ponte
    -> DONE

    = terminal_inspect(-> return_to)
        -> pr_terminal.inspect(return_to)

    = capsule_inspect(-> return_to)
        ] "Sembra che siano state aperte diversi minuti fa"
        -> return_to

    = door_sx_walk(-> return_to)
        -> pr_door.walk(return_to)

== rm_ship_bridge ==
    ] Ponte della nave
    -> DONE


// ============================================================================================================= //
//                                                      EVENTS                                                   //
// ============================================================================================================= //

== ev_ship_emergency ==
    ] Nave in emergenza
    ] - Luci rosse di emergenza ad intermittenza, animazione lenta
    ] - Sirena di emergenza

-> DONE

// ============================================================================================================= //
//                                                      UTILS                                                    //
// ============================================================================================================= //

== print ==
    = shot_header(-> location, -> event)
        # LOCATION
        ________________________________________________________________________________________________________________
        <- location

        # EVENT
        ________________________________________________________________________________________________________________
        <- event

    = shot_context
        # CONTEXT
        ________________________________________________________________________________________________________________
        -> DONE

    = shot_actions
        # ACTIONS
        ________________________________________________________________________________________________________________
        -> DONE

// ============================================================================================================= //
//                                                     CHAPTERS                                                  //
// ============================================================================================================= //

=== ch_1 ===

    = sh_0
        - (header)
            <- print.shot_header(-> rm_cryogenic_room,-> ev_ship_emergency)

        - (context)
            <- print.shot_context

            ] Ti svegli in preda alla confusione dopo aver passato non sai quanto tempo nella capsula criogenica
            ] - Vedi altre 3 capsule criogeniche aperte e vuote
            ] - Sei da solo nella stanza

        - (action)
            <- print.shot_actions

            + [Inspeziona il terminale] -> rm_cryogenic_room.terminal_inspect(-> action)
            + [Ispeziona le altre capsule] -> rm_cryogenic_room.capsule_inspect(-> action)
            + [Attraversa la porta a sinistra] -> rm_cryogenic_room.door_sx_walk(-> ch_1.shot_1)

    = sh_1
        - (header)
            <- print.shot_header(-> rm_ship_bridge,-> ev_ship_emergency)

        - (context)
            <- print.shot_context

            ] TBD

        - (action)
            <- print.shot_actions

            + [TBD] -> DONE