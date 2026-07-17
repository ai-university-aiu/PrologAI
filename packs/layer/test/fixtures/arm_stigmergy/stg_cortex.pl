/*  Arm B (stigmergy) — CORTEX.  Layer 3 (highest).  ORIGIN of the loop.

    A PrologAI cyclic_actor (proactive: the runner runs cortex_step/0 on a
    background thread every few ms).  Each poll, cortex reads the shared
    blackboard; when the beat is at phase 0 (its turn) it stamps the token and
    hands the beat on to phase 1.  It NEVER addresses another actor and NEVER
    imports one: its only dependencies are the shared environment and the trace,
    both layer 0.  The reentrant return arrives simply because the relay left
    the beat at phase 0 again — cortex reaches down to the environment to find it.
*/
:- module(stg_cortex, [ cortex_step/0 ]).

:- use_module(spike('arm_stigmergy/stg_blackboard.pl'),
              [ blackboard_open/1, read_beat/4, put_beat/4, beat_mutex/1 ]).
:- use_module(spike('arm_stigmergy/stg_config.pl'), [ cycles_n/1, done_queue/1 ]).
:- use_module(spike('common/trace.pl'), [ trace_hop/3 ]).

cortex_step :-
    beat_mutex(M),
    with_mutex(M, cortex_step_locked).

cortex_step_locked :-
    blackboard_open(Nexus),
    ( read_beat(Nexus, Lap, 0, Counter)      % phase 0 == cortex's turn
    ->  Token is Counter + 1,
        trace_hop(lattice, cortex, Token),   % learned from the environment, not a sender
        cycles_n(N),
        ( Lap >= N
        ->  put_beat(Nexus, Lap, halt, Token),          % terminal: put loop to rest
            done_queue(Q), thread_send_message(Q, done(Token))
        ;   put_beat(Nexus, Lap, 1, Token)              % hand on to phase 1
        )
    ;   true                                             % not cortex's turn yet
    ).
