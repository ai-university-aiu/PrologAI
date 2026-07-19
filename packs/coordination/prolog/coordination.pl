% coordination — ergonomic coordination affordances for the single-threaded
% reentrant-loop model: an in-memory (journal-free) store with keyed lookup and a
% bounded keyed await, an ordered publish channel, a bounded reentrant-loop driver, a
% reentrant-loop descriptor, a runtime layer-aware transport, and a glass-box hop trace.
% Work Package WP-437, Layer 0 (base infrastructure).
% Closes the Requirements Ledger's Theme F (coordination and closure primitives),
% the bounded ergonomics gaps the Wave 1 closure hybrid left: L5, L6, L7, L8, L9, P8,
% P9, P10, N4, N5. (N1, the lattice_transaction/2 meta_predicate, is a one-line additive
% fix on the lattice pack in the same stage; N2, a SWI-Prolog thread_wait/2 behaviour, is
% documented and avoided here — this construct is driven synchronously and never relies
% on push-reactivity.)
%
% The store is module-dynamic and writes NO journal (L9). Coordination in the connectome
% is single-threaded and reentrant — a step function drives a loop that settles — so
% "await" here is a BOUNDED retry of a producer step, not a blocking thread primitive,
% which is deterministic and needs no fairness scheduler beyond its step bound (N5).

% Declare the module and its public interface.
:- module(coordination,
    [ % --- An in-memory, journal-free store (L9) with keyed lookup (P8) ---
      coordination_open/1,            % +Store
      coordination_put/3,             % +Store, +Relation, +Args
      coordination_get/3,             % +Store, ?Relation, ?Args
      coordination_take/3,            % +Store, +Relation, +Args
      coordination_get_key/4,         % +Store, +Relation, +Key, -Args
      coordination_await_key/6,       % +Store, +Relation, +Key, :StepGoal, +MaxSteps, -Args
      % --- An ordered, durable publish channel (L6) ---
      coordination_publish_ordered/3, % +Store, +Channel, +Message
      coordination_consume_ordered/3, % +Store, +Channel, -Message
      % --- A bounded reentrant-loop driver with an until-condition (L7, P9) ---
      coordination_bounded_loop/6,    % +State0, :StepGoal, :UntilGoal, +MaxIterations, -FinalState, -Outcome
      % --- A reentrant-loop descriptor and its two-checks-on-one-object check (P10) ---
      coordination_declare_loop/4,    % +LoopName, +Nodes, +ForwardEdges, +ClosureEdge
      coordination_loop/4,            % ?LoopName, ?Nodes, ?ForwardEdges, ?ClosureEdge
      coordination_loop_check/2,      % +LoopName, -Result
      % --- A runtime layer-aware transport (L5 general case, N4) ---
      coordination_register_actor/2,  % +Actor, +Layer
      coordination_actor_layer/2,     % ?Actor, ?Layer
      coordination_send/4,            % +From, +To, +Message, -Result
      % --- A glass-box trace across coordination hops (L8) ---
      coordination_trace_hop/3,       % +TraceId, +From, +To
      coordination_trace/2            % +TraceId, -Hops
    ]).

% Use the standard list library for ordering and graph reachability.
:- use_module(library(lists)).

% The step and until goals of a bounded loop, and the await step, are called goals.
:- meta_predicate coordination_bounded_loop(+, 2, 1, +, -, -).
:- meta_predicate coordination_await_key(+, +, +, 0, +, -).

% Declare the registries dynamic — coordination state is a journal-free in-memory store.
:- dynamic coordination_fact/3.       % Store, Relation, Args
:- dynamic coordination_channel_seq/3.% Store, Channel, NextSeq
:- dynamic coordination_actor_fact/2. % Actor, Layer
:- dynamic coordination_hop/4.        % TraceId, Ordinal, From, To
:- dynamic coordination_hop_seq/2.    % TraceId, NextOrdinal

% -- coordination_open(+Store): register an in-memory store (idempotent; writes no journal).
coordination_open(_Store).
    % A store is just a namespace tag on the dynamic facts; opening it is a no-op that
    % documents intent — there is no file, no journal, nothing to allocate (L9).

% -- coordination_put(+Store, +Relation, +Args): store a fact in the in-memory store.
coordination_put(Store, Relation, Args) :-
    % Assert the fact under its store namespace.
    assertz(coordination_fact(Store, Relation, Args)).

% -- coordination_get(+Store, ?Relation, ?Args): read a matching fact without removing it.
coordination_get(Store, Relation, Args) :-
    % Unify against any stored fact in this store.
    coordination_fact(Store, Relation, Args).

% -- coordination_take(+Store, +Relation, +Args): read AND remove one matching fact.
coordination_take(Store, Relation, Args) :-
    % Bind the first matching fact, then retract exactly it.
    once(coordination_fact(Store, Relation, Args)),
    retract(coordination_fact(Store, Relation, Args)).

% -- coordination_get_key(+Store, +Relation, +Key, -Args): a KEYED lookup (P8).
% Find a fact of Relation whose FIRST argument is Key — the match lattice_await/5 could
% not express (it matched on the functor and returned on any matching fact).
coordination_get_key(Store, Relation, Key, Args) :-
    % A keyed fact is one whose argument list begins with the key.
    coordination_fact(Store, Relation, Args),
    Args = [Key|_].

% -- coordination_await_key(+Store, +Relation, +Key, :StepGoal, +MaxSteps, -Args):
% a BOUNDED keyed await (P8, N5). Check for the keyed fact; if absent, run StepGoal (a
% producer step) and re-check, up to MaxSteps times. Deterministic and bounded — it can
% never spin forever and needs no fairness scheduler.
coordination_await_key(Store, Relation, Key, StepGoal, MaxSteps, Args) :-
    % The step bound must be a non-negative integer.
    must_be(nonneg, MaxSteps),
    % Try to satisfy the keyed await within the step bound.
    coordination_await_key_loop(Store, Relation, Key, StepGoal, MaxSteps, Args).

% -- coordination_await_key_loop/6: the bounded retry itself.
coordination_await_key_loop(Store, Relation, Key, _StepGoal, _Steps, Args) :-
    % Succeed immediately if the keyed fact is already present.
    coordination_get_key(Store, Relation, Key, Args), !.
coordination_await_key_loop(Store, Relation, Key, StepGoal, Steps, Args) :-
    % Otherwise, if steps remain, run one producer step and re-check.
    Steps > 0,
    call(StepGoal),
    Steps1 is Steps - 1,
    coordination_await_key_loop(Store, Relation, Key, StepGoal, Steps1, Args).

% -- coordination_publish_ordered(+Store, +Channel, +Message): an ORDERED publish (L6).
% Each message gets a monotonic sequence number, so delivery has an order, the message is
% durable in the store, and a consumer is not racing a fire-and-forget send.
coordination_publish_ordered(Store, Channel, Message) :-
    % Read and advance the channel's next sequence number.
    ( retract(coordination_channel_seq(Store, Channel, Seq)) -> true ; Seq = 0 ),
    Seq1 is Seq + 1,
    assertz(coordination_channel_seq(Store, Channel, Seq1)),
    % Store the message keyed by its sequence number under a per-channel relation.
    assertz(coordination_fact(Store, ordered_message(Channel), [Seq, Message])).

% -- coordination_consume_ordered(+Store, +Channel, -Message): consume the NEXT message.
% Deliver, and remove, the lowest-sequence message on the channel — first-in, first-out.
coordination_consume_ordered(Store, Channel, Message) :-
    % Collect every pending message on the channel with its sequence number.
    findall(Seq-M, coordination_fact(Store, ordered_message(Channel), [Seq, M]), Pending),
    % There must be at least one message to consume.
    Pending \== [],
    % The next message is the one with the lowest sequence number.
    sort(Pending, [MinSeq-Message|_]),
    % Remove exactly that message so it is delivered once.
    retract(coordination_fact(Store, ordered_message(Channel), [MinSeq, Message])).

% -- coordination_bounded_loop(+State0, :StepGoal, :UntilGoal, +MaxIterations, -FinalState, -Outcome):
% a reentrant-loop driver with a bounded lifecycle, an until-condition, and a completion
% signal (L7, P9). StepGoal(S0, S1) advances the state; UntilGoal(S) is the completion
% test; Outcome is completed(Iterations) when UntilGoal holds, or bounded_stop(Max) when
% the iteration bound is reached first — so a loop never hand-rolls a done queue or an
% external stop.
coordination_bounded_loop(State0, StepGoal, UntilGoal, MaxIterations, FinalState, Outcome) :-
    % The iteration bound must be a non-negative integer.
    must_be(nonneg, MaxIterations),
    % Drive the loop from iteration zero.
    coordination_bounded_loop_step(State0, StepGoal, UntilGoal, MaxIterations, 0, FinalState, Outcome).

% -- coordination_bounded_loop_step/7: one turn of the bounded loop.
coordination_bounded_loop_step(State, _StepGoal, UntilGoal, _Max, Iterations, State, completed(Iterations)) :-
    % The loop completes the moment the until-condition holds.
    call(UntilGoal, State), !.
coordination_bounded_loop_step(State, _StepGoal, _UntilGoal, Max, Max, State, bounded_stop(Max)) :- !.
    % If the iteration bound is reached before completion, stop and say so.
coordination_bounded_loop_step(State0, StepGoal, UntilGoal, Max, Iterations, FinalState, Outcome) :-
    % Otherwise advance one step and recur with the iteration count raised.
    call(StepGoal, State0, State1),
    Iterations1 is Iterations + 1,
    coordination_bounded_loop_step(State1, StepGoal, UntilGoal, Max, Iterations1, FinalState, Outcome).

% -- coordination_declare_loop(+LoopName, +Nodes, +ForwardEdges, +ClosureEdge): a
% reentrant-loop DESCRIPTOR (P10). Nodes are the loop's stages; ForwardEdges are the
% acyclic forward graph; ClosureEdge is the ONE sanctioned back-edge that makes the loop
% reentrant. Both the "static graph is acyclic" proof and the "this runtime edge is the
% sanctioned closure" proof become two checks on ONE declared object.
coordination_declare_loop(LoopName, Nodes, ForwardEdges, ClosureEdge) :-
    % Replace any prior declaration so a loop name has one descriptor.
    retractall(coordination_loop_fact(LoopName, _, _, _)),
    % Store the descriptor.
    assertz(coordination_loop_fact(LoopName, Nodes, ForwardEdges, ClosureEdge)).

% Declare the loop-descriptor store dynamic.
:- dynamic coordination_loop_fact/4.

% -- coordination_loop(?LoopName, ?Nodes, ?ForwardEdges, ?ClosureEdge): read a descriptor.
coordination_loop(LoopName, Nodes, ForwardEdges, ClosureEdge) :-
    % Enumerate the declared loop descriptors.
    coordination_loop_fact(LoopName, Nodes, ForwardEdges, ClosureEdge).

% -- coordination_loop_check(+LoopName, -Result): the two checks on the one object.
% (a) the forward edges must be acyclic; (b) the closure edge must run from a node back to
% an EARLIER node in the declared node order (a genuine back-edge whose endpoints are
% loop nodes). Result is ok, or invalid(Reason).
coordination_loop_check(LoopName, Result) :-
    % Read the descriptor; an undeclared loop is a finding, not a crash.
    ( coordination_loop_fact(LoopName, Nodes, ForwardEdges, ClosureEdge)
    ->  coordination_loop_check_body(Nodes, ForwardEdges, ClosureEdge, Result)
    ;   Result = invalid(undeclared_loop(LoopName)) ).

% -- coordination_loop_check_body/4: run the two checks.
coordination_loop_check_body(Nodes, ForwardEdges, ClosureEdge, Result) :-
    ( \+ coordination_edges_are_nodes(ForwardEdges, Nodes)
    ->  Result = invalid(forward_edge_off_the_loop)
    ; coordination_has_cycle(ForwardEdges)
    ->  Result = invalid(forward_graph_has_a_cycle)
    ; \+ coordination_is_back_edge(ClosureEdge, Nodes)
    ->  Result = invalid(closure_edge_is_not_a_back_edge)
    ; Result = ok ).

% -- coordination_edges_are_nodes(+Edges, +Nodes): every edge endpoint is a loop node.
coordination_edges_are_nodes(Edges, Nodes) :-
    % Each edge's two endpoints must both be declared nodes.
    forall(member(A-B, Edges), ( memberchk(A, Nodes), memberchk(B, Nodes) )).

% -- coordination_has_cycle(+Edges): the directed forward graph contains a cycle.
coordination_has_cycle(Edges) :-
    % A cycle exists if some node can reach itself along one or more forward edges.
    member(A-_, Edges),
    coordination_reaches(A, A, Edges, [A]).

% -- coordination_reaches(+From, +Target, +Edges, +Visited): From reaches Target.
coordination_reaches(From, Target, Edges, _Visited) :-
    % A direct edge from From to Target is a reach of length one.
    member(From-Target, Edges).
coordination_reaches(From, Target, Edges, Visited) :-
    % Otherwise step to an unvisited neighbour and continue.
    member(From-Mid, Edges),
    \+ memberchk(Mid, Visited),
    coordination_reaches(Mid, Target, Edges, [Mid|Visited]).

% -- coordination_is_back_edge(+Edge, +Nodes): the edge runs from a later node to an earlier one.
coordination_is_back_edge(From-To, Nodes) :-
    % Both endpoints are loop nodes, and To appears BEFORE From in the node order.
    nth0(FromIx, Nodes, From),
    nth0(ToIx, Nodes, To),
    ToIx < FromIx.

% -- coordination_register_actor(+Actor, +Layer): declare an actor's layer for the transport.
coordination_register_actor(Actor, Layer) :-
    % The layer must be an integer coordinate.
    must_be(integer, Layer),
    % Replace any prior layer of this actor so an actor has one layer.
    retractall(coordination_actor_fact(Actor, _)),
    % Store the actor's layer.
    assertz(coordination_actor_fact(Actor, Layer)).

% -- coordination_actor_layer(?Actor, ?Layer): read a registered actor's layer.
coordination_actor_layer(Actor, Layer) :-
    % Enumerate the registered actors.
    coordination_actor_fact(Actor, Layer).

% -- coordination_send(+From, +To, +Message, -Result): the runtime layer-aware transport
% (L5 general case, N4). A lower-layer actor may not send UP to a higher-layer one, and
% this is checked at RUNTIME against the addressed actor's layer — so a computed or
% dynamic address that a load-time import checker cannot see is still refused.
coordination_send(From, To, _Message, Result) :-
    % Both actors must have a registered layer to be addressable.
    ( coordination_actor_fact(From, FromLayer), coordination_actor_fact(To, ToLayer)
    ->  ( ToLayer =< FromLayer
        % A send to an equal-or-lower layer is delivered.
        ->  Result = sent
        % A send to a strictly-higher layer is refused — the runtime layer wall.
        ;   Result = refused(upward_send(From, FromLayer, To, ToLayer)) )
    % An unregistered endpoint cannot be addressed.
    ;   Result = refused(unregistered_actor(From, To)) ).

% -- coordination_trace_hop(+TraceId, +From, +To): record one hop in a glass-box trace (L8).
coordination_trace_hop(TraceId, From, To) :-
    % Read and advance this trace's ordinal so hops keep their order.
    ( retract(coordination_hop_seq(TraceId, Ord)) -> true ; Ord = 0 ),
    Ord1 is Ord + 1,
    assertz(coordination_hop_seq(TraceId, Ord1)),
    % Record the hop at its ordinal.
    assertz(coordination_hop(TraceId, Ord, From, To)).

% -- coordination_trace(+TraceId, -Hops): the ordered hop list of a trace (L8).
coordination_trace(TraceId, Hops) :-
    % Collect the hops keyed by ordinal, sort into order, and drop the keys.
    findall(Ord-(From-To), coordination_hop(TraceId, Ord, From, To), Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Hops).
