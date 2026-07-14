/*  PrologAI — Theory of Mind Test Suite  (WP-418; converged with the AGI-Foundations tom pack, WP-389)

    The union proof: the movement/goal-inference + false-belief half (from
    co_kin) and the nested mental-model half (from the tom pack) both pass under
    the one converged pack's pack-qualified names.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/theory_of_mind/test/test_theory_of_mind.pl
*/

% Declare this file as a test module.
:- module(test_theory_of_mind, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the converged module under test.
:- use_module(library(theory_of_mind)).

:- begin_tests(theory_of_mind_movement).

% Net approach measures how much distance the agent closed toward a target.
test(approach_measures_closing) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_candidate_add(rival, cell(0,0)),
    % Two steps heading toward the origin: (5,0)->(4,0)->(3,0).
    theory_of_mind:theory_of_mind_note_move(rival, cell(5,0), cell(4,0)),
    theory_of_mind:theory_of_mind_note_move(rival, cell(4,0), cell(3,0)),
    theory_of_mind:theory_of_mind_approach(rival, cell(0,0), Net),
    assertion(Net =:= 2).

% The inferred goal is the target the agent moves toward, not away from.
test(infer_goal_toward) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_candidate_add(rival, cell(0,0)),   % the agent approaches this
    theory_of_mind:theory_of_mind_candidate_add(rival, cell(9,9)),   % the agent moves away from this
    theory_of_mind:theory_of_mind_note_move(rival, cell(5,5), cell(4,4)),
    theory_of_mind:theory_of_mind_note_move(rival, cell(4,4), cell(3,3)),
    theory_of_mind:theory_of_mind_infer_goal(rival, Goal),
    assertion(Goal == cell(0,0)).

% The predicted next step reduces the larger-axis gap to the goal.
test(predict_next_step) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_candidate_add(rival, cell(0,0)),
    theory_of_mind:theory_of_mind_note_move(rival, cell(5,2), cell(4,2)),
    % From (4,2) the row gap (4) exceeds the column gap (2): step in row.
    theory_of_mind:theory_of_mind_predict_next(rival, cell(4,2), Next),
    assertion(Next == cell(3,2)).

% With no net approach to any candidate, no goal is inferred.
test(no_goal_when_not_approaching) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_candidate_add(rival, cell(0,0)),
    % A step directly away from the target.
    theory_of_mind:theory_of_mind_note_move(rival, cell(1,0), cell(2,0)),
    assertion(\+ theory_of_mind:theory_of_mind_infer_goal(rival, _)).

% A belief the true state contradicts is a false belief (Sally-Anne).
test(false_belief) :-
    theory_of_mind:theory_of_mind_reset,
    % Sally believes the ball is in the basket.
    theory_of_mind:theory_of_mind_belief_add(sally, location(ball, basket)),
    % In truth it was moved to the box.
    theory_of_mind:theory_of_mind_truth_add(location(ball, box)),
    assertion(theory_of_mind:theory_of_mind_false_belief(sally, location(ball, basket))).

% A belief that matches the truth is not a false belief.
test(true_belief_not_false) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_belief_add(anne, location(ball, box)),
    theory_of_mind:theory_of_mind_truth_add(location(ball, box)),
    assertion(\+ theory_of_mind:theory_of_mind_false_belief(anne, location(ball, box))).

% Two agents can hold different beliefs about the same world.
test(agents_differ) :-
    theory_of_mind:theory_of_mind_reset,
    theory_of_mind:theory_of_mind_belief_add(sally, location(ball, basket)),
    theory_of_mind:theory_of_mind_belief_add(anne, location(ball, box)),
    theory_of_mind:theory_of_mind_truth_add(location(ball, box)),
    assertion(theory_of_mind:theory_of_mind_false_belief(sally, location(ball, basket))),
    assertion(\+ theory_of_mind:theory_of_mind_false_belief(anne, _)).

% Close the test block.
:- end_tests(theory_of_mind_movement).

% ===========================================================================
% TEST FIXTURE — THE SALLY-ANNE SCENARIO
% ===========================================================================

% The scenario after the marble is placed with both children watching.
sally_anne_before(M) :-
    % Start from an empty mental model.
    theory_of_mind_new(M0),
    % Sally puts the marble in the basket; both children witness it.
    theory_of_mind_event(M0, loc(marble, basket), [sally, anne], M).

% The scenario after Anne moves the marble while Sally is away.
sally_anne_after(M) :-
    % Build the shared starting scenario.
    sally_anne_before(M0),
    % Anne moves the marble to the box; only Anne witnesses it.
    theory_of_mind_event(M0, loc(marble, box), [anne], M).

% ===========================================================================
% WORLD AND BELIEF BASICS
% ===========================================================================

:- begin_tests(tom_basics).

% A new model is empty.
test(new_model_empty) :-
    % Build the empty model.
    theory_of_mind_new(M),
    % Its world holds nothing.
    theory_of_mind_world(M, []).

% Adding a fact makes it queryable.
test(world_add_and_query) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % Add one fact.
    theory_of_mind_world_add(M0, loc(marble, basket), M),
    % Query it back.
    theory_of_mind_fact(M, loc(marble, basket)),
    % Commit to the single answer.
    !.

% Upserting a conflicting fact replaces the old one.
test(world_upsert_replaces) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % The marble starts in the basket.
    theory_of_mind_world_add(M0, loc(marble, basket), M1),
    % The marble moves to the box.
    theory_of_mind_world_add(M1, loc(marble, box), M2),
    % The new location holds.
    theory_of_mind_fact(M2, loc(marble, box)),
    % The old location is gone.
    \+ theory_of_mind_fact(M2, loc(marble, basket)).

% Unrelated facts about different subjects coexist.
test(world_no_false_conflict, [nondet]) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % Two facts about different subjects.
    theory_of_mind_world_add(M0, loc(marble, basket), M1),
    % The second subject.
    theory_of_mind_world_add(M1, loc(book, shelf), M2),
    % Both facts survive.
    theory_of_mind_fact(M2, loc(marble, basket)),
    % The second fact too.
    theory_of_mind_fact(M2, loc(book, shelf)).

% Believing revises the agent's own store only.
test(believe_isolated_per_agent) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % Sally forms a belief.
    theory_of_mind_believe(M0, sally, loc(marble, basket), M),
    % Sally holds the belief.
    theory_of_mind_belief(M, sally, loc(marble, basket)),
    % Anne holds nothing.
    theory_of_mind_beliefs(M, anne, []).

% Belief revision replaces a conflicting belief.
test(believe_revises) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % An initial belief.
    theory_of_mind_believe(M0, sally, loc(marble, basket), M1),
    % A revised belief about the same subject.
    theory_of_mind_believe(M1, sally, loc(marble, box), M2),
    % Only the revision remains.
    theory_of_mind_beliefs(M2, sally, [loc(marble, box)]).

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
    theory_of_mind_belief(M, sally, loc(marble, basket)),
    % Anne believes basket.
    theory_of_mind_belief(M, anne, loc(marble, basket)).

% The first-order question: Sally will look where she falsely believes.
test(first_order_false_belief) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Where does Sally think the marble is?
    theory_of_mind_belief(M, sally, loc(marble, Where)),
    % She still thinks it is in the basket.
    Where == basket,
    % Commit to the single answer.
    !.

% Reality moved on: the world holds the box location.
test(world_moved_on) :-
    % Build the full scenario.
    sally_anne_after(M),
    % The marble is really in the box.
    theory_of_mind_fact(M, loc(marble, box)),
    % Commit to the single answer.
    !.

% Anne, who watched the move, knows the truth.
test(anne_knows) :-
    % Build the full scenario.
    sally_anne_after(M),
    % True belief is knowledge.
    theory_of_mind_knows(M, anne, loc(marble, box)),
    % Commit to the single answer.
    !.

% Sally believes, but does not know, because her belief is false.
test(sally_does_not_know, [fail]) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Her basket belief is not knowledge.
    theory_of_mind_knows(M, sally, loc(marble, basket)).

% The false-belief detector flags exactly Sally's stale belief.
test(false_belief_detected) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Sally's false beliefs.
    theory_of_mind_false_beliefs(M, sally, Sally),
    % Exactly the stale marble location.
    Sally == [loc(marble, basket)],
    % Anne's false beliefs.
    theory_of_mind_false_beliefs(M, anne, Anne),
    % Anne has none.
    Anne == [].

% The second-order question: Anne models Sally's outdated belief.
test(second_order_attribution) :-
    % Build the full scenario.
    sally_anne_after(M),
    % What does Anne think Sally believes?
    theory_of_mind_attribute(M, anne, sally, Beliefs),
    % Anne knows Sally never saw the move.
    Beliefs == [loc(marble, basket)].

% The two children now diverge on the marble's location.
test(divergence_detected) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Compare the two belief stores.
    theory_of_mind_divergent(M, sally, anne, Pairs),
    % Exactly one contradiction exists.
    Pairs == [diverge(loc(marble, basket), loc(marble, box))].

% Before the move, the location was common belief; afterwards it is not.
test(common_belief_shifts) :-
    % Build the starting scenario.
    sally_anne_before(M0),
    % Both children share the basket belief.
    theory_of_mind_common(M0, [sally, anne], Common0),
    % The shared location is among the common beliefs.
    memberchk(loc(marble, basket), Common0),
    % Build the full scenario.
    sally_anne_after(M),
    % Recompute the common beliefs.
    theory_of_mind_common(M, [sally, anne], Common),
    % No location is common any more.
    \+ memberchk(loc(marble, _), Common).

% Perspective taking: inside Sally's head, the marble is in the basket.
test(perspective_shift) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Re-seat the model inside Sally's head.
    theory_of_mind_perspective(M, sally, MP),
    % In her world, the basket holds the marble.
    theory_of_mind_fact(MP, loc(marble, basket)),
    % Commit to the single answer.
    !.

% Perspective taking carries nested beliefs down one level.
test(perspective_carries_nesting) :-
    % Build the full scenario.
    sally_anne_after(M),
    % Re-seat the model inside Anne's head.
    theory_of_mind_perspective(M, anne, MP),
    % In Anne's model, Sally believes the basket location.
    theory_of_mind_belief(MP, sally, loc(marble, basket)),
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
    theory_of_mind_new(M0),
    % Record two desires.
    theory_of_mind_desire(M0, sally, find(marble), M1),
    % The second desire.
    theory_of_mind_desire(M1, sally, play(outside), M2),
    % Read them back.
    theory_of_mind_desires(M2, sally, Goals),
    % Both are present in order.
    Goals == [find(marble), play(outside)].

% Recording the same desire twice keeps one copy.
test(desire_deduplicated) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % Record one desire twice.
    theory_of_mind_desire(M0, anne, hide(marble), M1),
    % The duplicate recording.
    theory_of_mind_desire(M1, anne, hide(marble), M2),
    % Only one copy remains.
    theory_of_mind_desires(M2, anne, [hide(marble)]).

% Intentions are recorded per agent.
test(intentions) :-
    % Build the empty model.
    theory_of_mind_new(M0),
    % Sally commits to searching the basket.
    theory_of_mind_intend(M0, sally, search(basket), M1),
    % Read the intention back.
    theory_of_mind_intentions(M1, sally, Acts),
    % The commitment is recorded.
    Acts == [search(basket)],
    % Anne committed to nothing.
    theory_of_mind_intentions(M1, anne, []).

:- end_tests(tom_bdi).
