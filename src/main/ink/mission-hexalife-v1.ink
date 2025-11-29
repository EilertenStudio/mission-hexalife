// ============================================================================================================= //
//                                                       START                                                   //
// ============================================================================================================= //
+ [ New Game ]
    -> ch_1

// ============================================================================================================= //
//                                                       ROOMS                                                   //
// ============================================================================================================= //

=== rm_cryogenic_room(-> continue) ===
# LOCATION
Cryogenic Room

: Al centro della stanza ci sono disposte 4 capsule criogeniche
: Sulla parete centrale sono disposti una serie di schermi e un terminale
: Sulla parete sinistra e presente una porta che si collega al ponte

-> continue

// ============================================================================================================= //
//                                                      EVENTS                                                   //
// ============================================================================================================= //

=== ev_ship_emergency(-> continue) ===
# EVENT
Nave in emergenza

: Luci rosse di emergenza ad intermittenza, animazione lenta
: Sirena di emergenza

-> continue

// ============================================================================================================= //
//                                                     CHAPTERS                                                  //
// ============================================================================================================= //

=== ch_1 ===
- (location)
    ___________________________________________________________________________________________________________
    -> rm_cryogenic_room(-> event)
- (event)
    ___________________________________________________________________________________________________________
    -> ev_ship_emergency(-> content)
- (content)
    ___________________________________________________________________________________________________________
    : Ti svegli in preda alla confusione dopo aver passato non sai quanto tempo nella capsula criogenica
    : Vedi altre 3 capsule criogeniche, sono aperte e vuote
    : Sei da solo
    ___________________________________________________________________________________________________________
    + [Accedi al terminale]
    + [Inspeziona le altre capsule]
    + [Attraversa la porta a sinistra]



