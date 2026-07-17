/*  Arm A (mailbox) — THALAMUS / relay.  Layer 1 (lowest of the three).

    A PrologAI receptor.  Receives the token from striatum and sends it back to
    CORTEX — this is the reentrant, loop-closing hop.

    HERE IS THE CRUX OF THE MAILBOX ARM'S LAYER-RULE STORY:
    thalamus is layer 1; cortex is layer 3.  The biological edge thalamus->cortex
    is a lower layer feeding a higher one.  If that were a STATIC dependency
    (`:- use_module(mbx_cortex)`), it would violate the strict layer rule.  It
    is NOT.  Thalamus imports only the layer-0 receptor substrate.  The upward
    edge survives only as a DATA CONSTANT — the address string below — resolved
    at runtime by the transport.  So the static graph stays acyclic while the
    runtime loop closes.  (See LEDGER.md: the upward reference does still exist,
    as a hard-coded address, and nothing flags it.)
*/
:- module(mbx_thalamus, [ thalamus_start/0 ]).

:- use_module(prologai('packs/actors/prolog/receptor.pl'),
              [ receptor/2, send_message/2 ]).
:- use_module(spike('common/trace.pl'), [ trace_hop/3 ]).

my_address('signal://mbx/thalamus').
next_address('signal://mbx/cortex').     % 1 -> 3 as DATA only; never a use_module

thalamus_start :-
    my_address(Addr),
    receptor(Addr, thalamus_handle).

thalamus_handle(tok(From, Counter)) :-
    Token is Counter + 1,
    trace_hop(From, thalamus, Token),
    next_address(Next),
    send_message(Next, tok(thalamus, Token)).   % the loop closes, through data
