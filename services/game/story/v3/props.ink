// ============================================================================================================= //
//                                                      PROPS                                                    //
// ============================================================================================================= //

== pr_door ==

    = walk(-> return_to)
    Ti avvicini alla porta
    # TODO: animazione
    \ - La porta si apre
    # TODO: transizione VFX
    Attraversi la porta
    + [Continue]
        -> return_to


== pr_terminal ==
    
    = inspect(-> return_to)
        Ti avvicini al terminale per analizzarne il contenuto
        \ - A schermo e' presente lo stato della nave e dove il personale e' richiesto
        \ - A schermo e' presente il tempo di scongelamento delle capsule
        \ - A schermo e' presente il tempo di criogenesi del presonale
        + [Back] 
            -> return_to