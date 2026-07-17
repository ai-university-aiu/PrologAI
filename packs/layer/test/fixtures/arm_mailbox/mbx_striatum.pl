/*  Arm A (mailbox) — STRIATUM / selector.  Layer 2.

    A PrologAI receptor.  Receives the token from cortex, stamps it, forwards
    to thalamus.  Depends only on layer-0 substrate; names thalamus by address.
*/
:- module(mbx_striatum, [ striatum_start/0 ]).

:- use_module(prologai('packs/actors/prolog/receptor.pl'),
              [ receptor/2, send_message/2 ]).
:- use_module(spike('common/trace.pl'), [ trace_hop/3 ]).

my_address('signal://mbx/striatum').
next_address('signal://mbx/thalamus').   % 2 -> 1: allowed (higher depends on lower)

striatum_start :-
    my_address(Addr),
    receptor(Addr, striatum_handle).

striatum_handle(tok(From, Counter)) :-
    Token is Counter + 1,
    trace_hop(From, striatum, Token),
    next_address(Next),
    send_message(Next, tok(striatum, Token)).
