/*  Arm B (stigmergy) — THALAMUS / relay.  Layer 1 (lowest of the three).

    A PrologAI cyclic_actor.  Reacts to phase 2, stamps the token, and wraps the
    beat back to phase 0 while incrementing the lap.  THIS is the reentrant,
    loop-closing write.

    Compare with the mailbox arm's thalamus, which contains the literal address
    'signal://mbx/cortex'.  Here the relay writes phase 0 and lap L+1 into the
    shared environment and mentions NO ONE.  There is not even a data reference
    to the origin: the origin elects, on its own, to read phase 0.  So the
    upward (layer 1 -> layer 3) reference does not exist at all — not as an
    import, not as an address constant.  That is the stigmergy arm's answer to
    the strict layer rule.
*/
:- module(stg_thalamus, [ thalamus_step/0 ]).

:- use_module(spike('arm_stigmergy/stg_blackboard.pl'),
              [ blackboard_open/1, read_beat/4, put_beat/4, beat_mutex/1 ]).
:- use_module(spike('common/trace.pl'), [ trace_hop/3 ]).

thalamus_step :-
    beat_mutex(M),
    with_mutex(M, thalamus_step_locked).

thalamus_step_locked :-
    blackboard_open(Nexus),
    ( read_beat(Nexus, Lap, 2, Counter)      % phase 2 == thalamus's turn
    ->  Token is Counter + 1,
        trace_hop(lattice, thalamus, Token),
        Lap1 is Lap + 1,
        put_beat(Nexus, Lap1, 0, Token)       % wrap to phase 0, next lap: the loop closes
    ;   true
    ).
