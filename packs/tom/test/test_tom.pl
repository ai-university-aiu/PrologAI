/*  PrologAI — Theory of Mind Pack Test Suite  (WP-389)

    Acceptance tests for all tm_* predicates, built around the classic
    Sally-Anne false-belief scenario, including the second-order
    question that requires beliefs about beliefs.

    Run with:
        swipl -g "run_tests, halt" test_tom.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/tom').

% ===========================================================================
% TEST FIXTURE — THE SALLY-ANNE SCENARIO
% ===========================================================================

% The scenario after the marble is placed with both children watching.
sally_anne_before(M) :-
    % Start from an empty mental model.
    tm_new(M0),
    % Sally puts the marble in the basket; both children witness it.
    tm_event(M0, loc(marble, basket), [sally, anne], M).

% The scenario after Anne moves the marble while Sally is away.
sally_anne_after(M) :-
    % Build the shared starting scenario.
    sally_anne_before(M0),
    % Anne moves the marble to the box; only Anne witnesses it.
    tm_event(M0, loc(marble, box), [anne], M).

% ===========================================================================
% WORLD AND BELIEF BASICS
% ===========================================================================

:- begin_tests(tom_basics).

% A new model is empty.
test(new_model_empty) :-
    % Build the empty model.
    tm_new(M),
    % Its world holds nothing.
    tm_world(M, []).

% Adding a fact makes it queryable.
test(world_add_and_query) :-
    % Build the empty model.
    tm_new(M0),
    % Add one fact.
    tm_world_add(M0, loc(marble, basket), M),
    % Query it back.
    tm_fact(M, loc(marble, basket)),
    % Commit to the single answer.
    !.

% Upserting a conflicting fact replaces the old one.
test(world_upsert_replaces) :-
    % Build the empty model.
    tm_new(M0),
    % The marble starts in the basket.
    tm_world_add(M0, loc(marble, basket), M1),
    % The marble moves to the box.
    tm_world_add(M1, loc(marble, box), M2),
    % The new location holds.
    tm_fact(M2, loc(marble, box)),
    % The old location is gone.
    \+ tm_fact(M2, loc(marble, basket)).

% Unrelated facts about different subjects coexist.
test(world_no_false_conflict, [nondet]) :-
    % Build the empty model.
    tm_new(M0),
    % Two facts about different subjects.
    tm_world_add(M0, loc(marble, basket), M1),
    % The second subject.
    tm_world_add(M1, loc(book, shelf), M2),
    % Both facts survive.
    tm_fact(M2, loc(marble, basket)),
    % The second fact too.
    tm_fact(M2, loc(book, shelf)).

% Believing revises the agent's own store only.
test(believe_isolated_per_agent) :-
    % Build the empty model.
    tm_new(M0),
    % Sally forms a belief.
    tm_believe(M0, sally, loc(marble, basket), M),
    % Sally holds the belief.
    tm_belief(M, sally, loc(marble, basket)),
    % Anne holds nothing.
    tm_beliefs(M, anne, []).

% Belief revision replaces a conflicting belief.
test(believe_revises) :-
    % Build the empty model.
    tm_new(M0),
    % An initial belief.
    tm_believe(M0, sally, loc(marble, basket), M1),
    % A revised belief about the same subject.
    tm_believe(M1, sally, loc(marble, box), M2),
    % Only the revision remains.
    tm_beliefs(M2, sally, [loc(marble, box)]).

:- end_tests(tom_basics).

% ===========================================================================
% THE SALLY-ANNE FALSE-BELIEF TEST
% ===========================================================================

:- begin_tests(tom_sally_anne).

% After the placement, both children believe the marble is in the basket.
test(shared_initial_belief, [nondet]) :-
    % Build the starting scenario.
    sally_anne_before(M),
    % Sally believes basket.
    tm_belief(M, sally, loc(marble, basket)),
    % Anne believes basket.
    tm_belief(M, anne, loc(marble, basket)).

% The first-order question: Sally will look where she falsely believes.
test(first_order_false_belief) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Where does Sally think the marble is?
    tm_belief(M, sally, loc(marble, Where)),
    % She still thinks it is in the basket.
    Where == basket,
    % Commit to the single answer.
    !.

% Reality moved on: the world holds the box location.
test(world_moved_on) :-
    % Build the full scenario.
    sally_anne_after(M),
    % The marble is really in the box.
    tm_fact(M, loc(marble, box)),
    % Commit to the single answer.
    !.

% Anne, who watched the move, knows the truth.
test(anne_knows) :-
    % Build the full scenario.
    sally_anne_after(M),
    % True belief is knowledge.
    tm_knows(M, anne, loc(marble, box)),
    % Commit to the single answer.
    !.

% Sally believes, but does not know, because her belief is false.
test(sally_does_not_know, [fail]) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Her basket belief is not knowledge.
    tm_knows(M, sally, loc(marble, basket)).

% The false-belief detector flags exactly Sally's stale belief.
test(false_belief_detected) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Sally's false beliefs.
    tm_false_beliefs(M, sally, Sally),
    % Exactly the stale marble location.
    Sally == [loc(marble, basket)],
    % Anne's false beliefs.
    tm_false_beliefs(M, anne, Anne),
    % Anne has none.
    Anne == [].

% The second-order question: Anne models Sally's outdated belief.
test(second_order_attribution) :-
    % Build the full scenario.
    sally_anne_after(M),
    % What does Anne think Sally believes?
    tm_attribute(M, anne, sally, Beliefs),
    % Anne knows Sally never saw the move.
    Beliefs == [loc(marble, basket)].

% The two children now diverge on the marble's location.
test(divergence_detected) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Compare the two belief stores.
    tm_divergent(M, sally, anne, Pairs),
    % Exactly one contradiction exists.
    Pairs == [diverge(loc(marble, basket), loc(marble, box))].

% Before the move, the location was common belief; afterwards it is not.
test(common_belief_shifts) :-
    % Build the starting scenario.
    sally_anne_before(M0),
    % Both children share the basket belief.
    tm_common(M0, [sally, anne], Common0),
    % The shared location is among the common beliefs.
    memberchk(loc(marble, basket), Common0),
    % Build the full scenario.
    sally_anne_after(M),
    % Recompute the common beliefs.
    tm_common(M, [sally, anne], Common),
    % No location is common any more.
    \+ memberchk(loc(marble, _), Common).

% Perspective taking: inside Sally's head, the marble is in the basket.
test(perspective_shift) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Re-seat the model inside Sally's head.
    tm_perspective(M, sally, MP),
    % In her world, the basket holds the marble.
    tm_fact(MP, loc(marble, basket)),
    % Commit to the single answer.
    !.

% Perspective taking carries nested beliefs down one level.
test(perspective_carries_nesting) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Re-seat the model inside Anne's head.
    tm_perspective(M, anne, MP),
    % In Anne's model, Sally believes the basket location.
    tm_belief(MP, sally, loc(marble, basket)),
    % Commit to the single answer.
    !.

:- end_tests(tom_sally_anne).

% ===========================================================================
% DESIRES AND INTENTIONS
% ===========================================================================

:- begin_tests(tom_bdi).

% Desires are recorded and read back in order.
test(desires) :-
    % Build the empty model.
    tm_new(M0),
    % Record two desires.
    tm_desire(M0, sally, find(marble), M1),
    % The second desire.
    tm_desire(M1, sally, play(outside), M2),
    % Read them back.
    tm_desires(M2, sally, Goals),
    % Both are present in order.
    Goals == [find(marble), play(outside)].

% Recording the same desire twice keeps one copy.
test(desire_deduplicated) :-
    % Build the empty model.
    tm_new(M0),
    % Record one desire twice.
    tm_desire(M0, anne, hide(marble), M1),
    % The duplicate recording.
    tm_desire(M1, anne, hide(marble), M2),
    % Only one copy remains.
    tm_desires(M2, anne, [hide(marble)]).

% Intentions are recorded per agent.
test(intentions) :-
    % Build the empty model.
    tm_new(M0),
    % Sally commits to searching the basket.
    tm_intend(M0, sally, search(basket), M1),
    % Read the intention back.
    tm_intentions(M1, sally, Acts),
    % The commitment is recorded.
    Acts == [search(basket)],
    % Anne committed to nothing.
    tm_intentions(M1, anne, []).

:- end_tests(tom_bdi).
