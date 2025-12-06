// ============================================================================================================= //
//                                                      ROOMS                                                    //
// ============================================================================================================= //

== rm_cryogenic_room ==
    // \# LOCATION
    Cryogenic Room
    \ - Al centro della stanza ci sono disposte 4 capsule criogeniche
    \ - Sulla parete centrale sono disposti una serie di schermi e un terminale
    \ - Sulla parete sinistra e presente una porta che si collega al ponte
    -> DONE

    = terminal_inspect(-> return_to)
        -> pr_terminal.inspect(return_to)

    = capsule_inspect(-> return_to)
        "Sembra che siano state aperte diversi minuti fa"
        -> return_to

    = door_sx_walk(-> return_to)
        -> pr_door.walk(return_to)

== rm_ship_bridge ==
    Ponte della nave
    \ - Collega diverse stanze della nave
    -> DONE

    = walk(-> return_to)
    Ti avvicini alla porta
    # TODO: animazione
    > La porta si apre
    # TODO: transizione VFX
    > Attraversi la porta
    -> return_to
