// ============================================================================================================= //
//                                                      UTILS                                                    //
// ============================================================================================================= //

== clear(-> next) ==
    #CLEAR
    -> next

== print ==
    = separator
        \============================================================
        -> DONE

    = scene(-> scene_id)
        <- print.separator
        SCENE: <> <- scene_id
        -> DONE

    = location(-> location)
        // <- print.separator
        // [Location] <>
        \=== [ LOCATION ] ===========================================
        <- location
        -> DONE

    = event(-> event)
        // <- print.separator
        // [Event] <>
        \=== [ EVENT ] ==============================================
        <- event
        -> DONE

    = narration
        // <- print.separator
        // [Narration] <>
        \=== [ NARRATION ] ==========================================
        -> DONE
    
    = actions
        // <- print.separator
        // [Action] <>
        \=== [ ACTIONS ] ============================================
        -> DONE
    
    = puzzle
        // <- print.separator
        // [Action] <>
        \=== [ PUZZLE ] ============================================
        -> DONE
        
== do ==
    = action
        > <>
        -> DONE

    = speak
        : <>
        -> DONE