// ============================================================================================================= //
//                                                       START                                                   //
// ============================================================================================================= //
+ [ New Game ]
    -> ch_1

// ============================================================================================================= //
//                                                       ROOMS                                                   //
// ============================================================================================================= //

=== rm_cryogenic_room(-> continue) ===
________________________________________________________________________________________________________________
Cryogenic Room

: Al centro della stanza ci sono disposte 4 capsule criogeniche
: Sulla parete centrale sono disposti una serie di schermi e un terminale
: Sulla parete sinistra e presente una porta che si collega al ponte

-> continue

// ============================================================================================================= //
//                                                      EVENTS                                                   //
// ============================================================================================================= //

=== ev_ship_emergency(-> continue) ===
________________________________________________________________________________________________________________
Nave in emergenza

: Luci rosse di emergenza ad intermittenza, animazione lenta
: Sirena di emergenza

-> continue

// ============================================================================================================= //
//                                                     CHAPTERS                                                  //
// ============================================================================================================= //

=== ch_1 ===
- (location)
    # LOCATION
    -> rm_cryogenic_room(-> event)
- (event)
    # EVENT
    -> ev_ship_emergency(-> context)
- (context)
    # CONTEXT
    ________________________________________________________________________________________________________________
    : Ti svegli in preda alla confusione dopo aver passato non sai quanto tempo nella capsula criogenica
    : Vedi altre 3 capsule criogeniche, sono aperte e vuote
    : Sei da solo nella stanza
    ________________________________________________________________________________________________________________
    -> actions
- (actions)
    * [Accedi al terminale] -> actions
    + [Inspeziona le altre capsule] -> actions
    + [Attraversa la porta a sinistra] -> actions



