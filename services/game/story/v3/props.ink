// ============================================================================================================= //
//                                                      PROPS                                                    //
// ============================================================================================================= //

== pr_door ==

    = inspect(-> actor)
        <- actor
            Ti avvicini alla porta
            -> DONE
    
    = inspect_locked(-> actor)
        <- ch_player
            Ti avvicini alla porta ma non sembra funzionare
            -> DONE
    
    = walk(-> actor, -> return_to)
        // <- actor
        //     Attraversi la porta
            
        + [Continue]
            -> clear(return_to)

== pr_terminal ==
    
    = inspect(-> actor)
        <- actor
            Ti avvicini al terminale per analizzarne il contenuto
            \ - A schermo e' presente lo stato della nave e dove il personale e' richiesto
            \ - A schermo e' presente il tempo di scongelamento delle capsule
            \ - A schermo e' presente il tempo di criogenesi del presonale
            -> DONE
                
== pr_cryogenic_capsule ==
    
    = inspect(-> actor)
        <- actor
            Ti avvicini ad una capsula e la ispezioni
            -> DONE