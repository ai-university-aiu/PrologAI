/*  Arm B (stigmergy) — STRIATUM / selector.  Layer 2.

    A PrologAI cyclic_actor.  Reacts to phase 1, stamps the token, advances the
    beat to phase 2.  Sets only a number; names no actor; imports no actor.
*/
:- module(stg_striatum, [ striatum_step/0 ]).

:- use_module(spike('arm_stigmergy/stg_blackboard.pl'),
              [ blackboard_open/1, read_beat/4, put_beat/4, beat_mutex/1 ]).
:- use_module(spike('common/trace.pl'), [ trace_hop/3 ]).

striatum_step :-
    beat_mutex(M),
    with_mutex(M, striatum_step_locked).

striatum_step_locked :-
    blackboard_open(Nexus),
    ( read_beat(Nexus, Lap, 1, Counter)      % phase 1 == striatum's turn
    ->  Token is Counter + 1,
        trace_hop(lattice, striatum, Token),
        put_beat(Nexus, Lap, 2, Token)        % hand on to phase 2
    ;   true
    ).
