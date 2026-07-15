/*  PrologAI — SONA (Synaptic Ontological Neural Aggregator) Test Suite  (PR 11)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" \
            packs/synaptic_ontological_neural_aggregator/test/test_synaptic_ontological_neural_aggregator.pl

    Behavioural assertions on the continuous-learning ReasoningBank:
      absorb + retrieve round-trip, metrics snapshot, pattern separation
      (dual recall of same-situation/different-outcome), exact-duplicate
      suppression, retrieve/3 K-limit, and crystallize's min-count skip.
*/

% Declare this file as a test module.
:- module(test_synaptic_ontological_neural_aggregator, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(synaptic_ontological_neural_aggregator)).

% Reset SONA's dynamic state so each test starts from an empty ReasoningBank.
sona_test_reset :-
    % Drop every stored trajectory entry.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_trajectory_entry(_, _, _, _, _, _)),
    % Drop every EWC++ importance record.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_importance(_, _)),
    % Drop every retrieval-count record.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_retrieval_count(_, _)),
    % Clear the entry-id counter and reseed it to zero.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_trajectory_id_counter(_)),
    % Reseed the entry-id counter at zero.
    assertz(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_trajectory_id_counter(0)),
    % Clear the consolidation-cycle counter.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_consolidation_cycle(_)),
    % Reseed the consolidation-cycle counter at zero.
    assertz(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_consolidation_cycle(0)),
    % Clear the last-crystallize timestamp.
    retractall(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_last_crystallize_time(_)),
    % Reseed the last-crystallize timestamp at zero.
    assertz(synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_last_crystallize_time(0.0)).

% Open the test block for the aggregator.
:- begin_tests(synaptic_ontological_neural_aggregator).

% AC-001: an absorbed trajectory can be recalled by its situation pattern.
test(absorb_then_retrieve, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectory.
    get_time(T),
    % Absorb a single successful pick trajectory.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_pick, [pick(apple)], success, 1.0, T)),
    % Retrieve trajectories cued by the same situation id.
    synaptic_ontological_neural_aggregator_retrieve(sit_pick, Results),
    % Recall must return at least one trajectory.
    assertion(Results \== []),
    % The recalled trajectory carries the original situation and outcome.
    assertion(memberchk(trajectory(sit_pick, [pick(apple)], success, _, _), Results)).

% AC-002: the metrics snapshot reports the bank after an absorption.
test(metrics_after_absorb, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectory.
    get_time(T),
    % Absorb one trajectory so the bank is non-empty.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_move, [move(north)], success, 0.8, T)),
    % Ask SONA for its operational metrics snapshot.
    synaptic_ontological_neural_aggregator_metrics(M),
    % Exactly one trajectory is now counted.
    assertion(get_dict(trajectory_count, M, 1)),
    % No consolidation cycle has run yet.
    assertion(get_dict(consolidation_cycle, M, 0)),
    % The learning rate is the fixed 0.01 value.
    assertion(get_dict(learning_rate, M, 0.01)).

% AC-004: same situation with differing outcomes yields dual recall, not a merged hybrid.
test(pattern_separation_dual_recall, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectories.
    get_time(T),
    % Absorb the fork situation with a success outcome.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_fork, [push(button)], success, 1.0, T)),
    % Absorb the same fork situation with a failure outcome.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_fork, [push(button)], failure, -1.0, T)),
    % Retrieve trajectories cued by the fork situation.
    synaptic_ontological_neural_aggregator_retrieve(sit_fork, Results),
    % Measure how many trajectories came back.
    length(Results, N),
    % Both separated trajectories must be present.
    assertion(N >= 2),
    % The success branch survived separation.
    assertion(memberchk(trajectory(sit_fork, _, success, _, _), Results)),
    % The failure branch survived separation.
    assertion(memberchk(trajectory(sit_fork, _, failure, _, _), Results)).

% AC-006: an exact-duplicate trajectory is not stored a second time.
test(exact_duplicate_not_stored, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectories.
    get_time(T),
    % Absorb a trajectory once.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    % Absorb the identical trajectory a second time.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    % Count how many entries match the duplicated situation, actions and outcome.
    aggregate_all(count,
                  synaptic_ontological_neural_aggregator:synaptic_ontological_neural_aggregator_trajectory_entry(_, sit_dup, [do(x)], success, _, _),
                  N),
    % Only one copy is retained.
    assertion(N =:= 1).

% AC-007: retrieve/3 never returns more than the requested K trajectories.
test(retrieve_respects_k, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectories.
    get_time(T),
    % Absorb eight distinct situations into the bank.
    forall(between(1, 8, I),
           ( SitId =.. [batch_sit, I],
             synaptic_ontological_neural_aggregator_absorb(trajectory(SitId, [act(I)], success, 0.5, T)) )),
    % Retrieve at most three trajectories for the first situation.
    synaptic_ontological_neural_aggregator_retrieve(batch_sit(1), 3, Results),
    % Measure how many were actually returned.
    length(Results, N),
    % The K cap of three is respected.
    assertion(N =< 3).

% AC-008: crystallize skips consolidation when the bank is below the min-count threshold.
test(crystallize_skips_when_too_few, [setup(sona_test_reset)]) :-
    % Read the wall-clock time to stamp the trajectory.
    get_time(T),
    % Absorb a single trajectory (well below any large threshold).
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_small, [step(1)], success, 0.5, T)),
    % Record the consolidation cycle before crystallizing.
    synaptic_ontological_neural_aggregator_metrics(M0),
    % Read the pre-crystallize cycle counter.
    get_dict(consolidation_cycle, M0, CC0),
    % Ask for crystallization that requires far more trajectories than exist.
    synaptic_ontological_neural_aggregator_crystallize([min_trajectory_count(9999)]),
    % Record the consolidation cycle after the skipped crystallize.
    synaptic_ontological_neural_aggregator_metrics(M1),
    % Read the post-crystallize cycle counter.
    get_dict(consolidation_cycle, M1, CC1),
    % The cycle counter is unchanged because the threshold was not met.
    assertion(CC1 =:= CC0).

% Close the test block for the aggregator.
:- end_tests(synaptic_ontological_neural_aggregator).
