% Test suite for the coordination pack — the coordination-ergonomics affordances.
% These tests confirm the journal-free store and keyed lookup, the bounded keyed await,
% the ordered publish channel, the bounded reentrant-loop driver, the reentrant-loop
% descriptor and its two checks, the runtime layer-aware transport, and the hop trace.
% Load the coordination module under test.
:- use_module(library(coordination)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% A producer step for the await test: put the awaited keyed fact into the store.
coordination_test_produce :-
    coordination_put(await_store, ready, [k1, made]).
% A step goal for the bounded loop: increment the numeric state by one.
coordination_test_inc(S0, S1) :- S1 is S0 + 1.
% An until-condition for the bounded loop: the state has reached three.
coordination_test_at_least_3(S) :- S >= 3.
% An until-condition that never holds, to force the iteration bound.
coordination_test_never(_) :- fail.

% Open the test block for the coordination pack.
:- begin_tests(coordination).

% Clear the in-memory registries before each test so state does not leak.
coordination_test_clear :-
    retractall(coordination:coordination_fact(_, _, _)),
    retractall(coordination:coordination_channel_seq(_, _, _)),
    retractall(coordination:coordination_loop_fact(_, _, _, _)),
    retractall(coordination:coordination_actor_fact(_, _)),
    retractall(coordination:coordination_hop(_, _, _, _)),
    retractall(coordination:coordination_hop_seq(_, _)).

% L9/P8: the journal-free store puts, keyed-reads, and takes facts.
test(store_put_keyed_get_and_take, setup(coordination_test_clear)) :-
    coordination_open(s),
    coordination_put(s, phase, [warmup, data1]),
    coordination_put(s, phase, [active, data2]),
    % A keyed lookup finds the fact whose FIRST argument is the key.
    coordination_get_key(s, phase, active, Args),
    assertion(Args == [active, data2]),
    % Take removes exactly the matched fact.
    coordination_take(s, phase, [warmup, data1]),
    assertion(\+ coordination_get(s, phase, [warmup, _])).

% P8/N5: a bounded keyed await succeeds once a producer step creates the keyed fact.
test(bounded_keyed_await_succeeds_within_bound, setup(coordination_test_clear)) :-
    coordination_open(await_store),
    coordination_await_key(await_store, ready, k1, user:coordination_test_produce, 3, Args),
    assertion(Args == [k1, made]).

% P8/N5: a keyed await that never gets its fact stops at the step bound (it does not spin).
test(bounded_keyed_await_stops_at_bound, [setup(coordination_test_clear), fail]) :-
    coordination_open(empty_store),
    % No producer step ever creates the fact, so the bounded await fails after MaxSteps.
    coordination_await_key(empty_store, ready, missing, true, 2, _Args).

% L6: an ordered channel delivers messages first-in, first-out.
test(ordered_channel_is_fifo, setup(coordination_test_clear)) :-
    coordination_open(c),
    coordination_publish_ordered(c, spikes, first),
    coordination_publish_ordered(c, spikes, second),
    coordination_publish_ordered(c, spikes, third),
    coordination_consume_ordered(c, spikes, M1), assertion(M1 == first),
    coordination_consume_ordered(c, spikes, M2), assertion(M2 == second),
    coordination_consume_ordered(c, spikes, M3), assertion(M3 == third),
    % Consuming an empty channel fails, rather than delivering a phantom message.
    assertion(\+ coordination_consume_ordered(c, spikes, _)).

% L7/P9: a bounded loop completes with the iteration count when the until-condition holds.
test(bounded_loop_completes, setup(coordination_test_clear)) :-
    coordination_bounded_loop(0, user:coordination_test_inc, user:coordination_test_at_least_3,
                              10, Final, Outcome),
    assertion(Final == 3),
    assertion(Outcome == completed(3)).

% L7/P9: a bounded loop that never completes stops at its iteration bound with a signal.
test(bounded_loop_stops_at_bound, setup(coordination_test_clear)) :-
    coordination_bounded_loop(0, user:coordination_test_inc, user:coordination_test_never,
                              5, Final, Outcome),
    assertion(Final == 5),
    assertion(Outcome == bounded_stop(5)).

% P10: a well-formed reentrant-loop descriptor passes both checks on one object.
test(loop_descriptor_wellformed, setup(coordination_test_clear)) :-
    coordination_declare_loop(cortico_loop, [cortex, striatum, thalamus],
                              [cortex-striatum, striatum-thalamus], thalamus-cortex),
    coordination_loop_check(cortico_loop, Result),
    assertion(Result == ok).

% P10: a forward graph with a cycle is rejected (the static acyclicity check).
test(loop_descriptor_rejects_forward_cycle, setup(coordination_test_clear)) :-
    coordination_declare_loop(bad_loop, [a, b],
                              [a-b, b-a], b-a),
    coordination_loop_check(bad_loop, Result),
    assertion(Result == invalid(forward_graph_has_a_cycle)).

% P10: a closure edge that is not a genuine back-edge is rejected.
test(loop_descriptor_rejects_non_back_closure, setup(coordination_test_clear)) :-
    coordination_declare_loop(fwd_loop, [a, b, c],
                              [a-b, b-c], a-c),
    coordination_loop_check(fwd_loop, Result),
    assertion(Result == invalid(closure_edge_is_not_a_back_edge)).

% P10: an undeclared loop is a finding, not a crash.
test(loop_check_undeclared_is_a_finding, setup(coordination_test_clear)) :-
    coordination_loop_check(no_such_loop, Result),
    assertion(Result == invalid(undeclared_loop(no_such_loop))).

% L5/N4: the runtime transport delivers a downward or level send and refuses an upward one.
test(layer_aware_transport_refuses_upward, setup(coordination_test_clear)) :-
    coordination_register_actor(striatum_actor, 2),
    coordination_register_actor(cortex_actor, 4),
    % A send from the higher (cortex, 4) down to the lower (striatum, 2) is delivered.
    coordination_send(cortex_actor, striatum_actor, go, Down),
    assertion(Down == sent),
    % A send from the lower (striatum, 2) UP to the higher (cortex, 4) is refused at runtime.
    coordination_send(striatum_actor, cortex_actor, go, Up),
    assertion(Up = refused(upward_send(striatum_actor, 2, cortex_actor, 4))),
    % An unregistered endpoint cannot be addressed.
    coordination_send(striatum_actor, ghost_actor, go, Ghost),
    assertion(Ghost = refused(unregistered_actor(_, _))).

% L8: the hop trace records hops in order and reads them back as a sequence.
test(hop_trace_is_ordered, setup(coordination_test_clear)) :-
    coordination_trace_hop(t1, cortex, striatum),
    coordination_trace_hop(t1, striatum, thalamus),
    coordination_trace_hop(t1, thalamus, cortex),
    coordination_trace(t1, Hops),
    assertion(Hops == [cortex-striatum, striatum-thalamus, thalamus-cortex]).

% Close the test block.
:- end_tests(coordination).
