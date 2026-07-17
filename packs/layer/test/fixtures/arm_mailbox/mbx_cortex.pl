/*  Arm A (mailbox) — CORTEX.  Layer 3 (highest).

    A PrologAI receptor (reactive actor: a message queue + a handler thread,
    from packs/actors/prolog/receptor.pl).  Cortex is the ORIGIN of the loop:
    the seed token is delivered to it, and every subsequent token it receives
    has come back around the loop from thalamus.

    Static dependencies: only the receptor substrate, the shared trace, and the
    experiment config — all layer 0.  Cortex imports NO other actor.  It names
    its successor (striatum) by ADDRESS, as data, not by importing its module.
*/
:- module(mbx_cortex, [ cortex_start/0 ]).

:- use_module(prologai('packs/actors/prolog/receptor.pl'),
              [ receptor/2, send_message/2 ]).
:- use_module(spike('common/trace.pl'),     [ trace_hop/3 ]).
:- use_module(spike('arm_mailbox/mbx_config.pl'), [ cycles_n/1, done_queue/1 ]).

my_address('signal://mbx/cortex').
next_address('signal://mbx/striatum').   % cortex depends downward on striatum (3 -> 2): allowed

:- dynamic laps_emitted/1.

cortex_start :-
    retractall(laps_emitted(_)),
    assertz(laps_emitted(0)),
    my_address(Addr),
    receptor(Addr, cortex_handle).

% Handler: called as call(cortex_handle, Message) on the receptor's thread.
cortex_handle(tok(From, Counter)) :-
    Token is Counter + 1,
    trace_hop(From, cortex, Token),
    retract(laps_emitted(E)),
    cycles_n(N),
    ( E >= N
    ->  assertz(laps_emitted(E)),
        done_queue(Q),
        thread_send_message(Q, done(Token))      % loop complete: report and stop
    ;   E1 is E + 1,
        assertz(laps_emitted(E1)),
        next_address(Next),
        send_message(Next, tok(cortex, Token))    % push the token onward, next lap
    ).
