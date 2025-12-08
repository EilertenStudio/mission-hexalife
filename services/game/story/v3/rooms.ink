// ============================================================================================================= //
//                                                      ROOMS                                                    //
// ============================================================================================================= //

== rm_cryogenic_room ==
    Cryogenic Room
    \ - Al centro della stanza ci sono disposte 4 capsule criogeniche
    \ - Sulla parete centrale sono disposti una serie di schermi e un terminale
    \ - Sulla parete sinistra e' presente una porta che si collega al ponte
    -> DONE

    = terminal_inspect(-> actor, -> return_to)
        - (intro)
            <- pr_terminal.inspect(actor)
        
        - (actions)
            + [Back] 
                -> return_to

    = capsule_inspect(-> actor, -> return_to)
        - (intro)
            <- pr_cryogenic_capsule.inspect(actor)
        
        - (dialogues)
            <- actor
                "Sembra che siano state aperte diversi minuti fa"
        
        - (actions)
            + [Back] 
                -> return_to

    = door_sx_locked(-> actor, -> return_to)
        - (intro)
            <- pr_door.inspect_locked(actor)
            
        -(actions)
            + [Back]
                -> return_to
    
    = door_sx_walk(-> actor, -> return_to)
        - (intro)
            <- pr_door.inspect(actor)
            -> pr_door.walk(actor, return_to)
    

== rm_ship_bridge ==
    Ponte della nave
    \ - Collega le stanze della nave
    -> DONE
