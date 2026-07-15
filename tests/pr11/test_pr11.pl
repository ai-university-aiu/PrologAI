/*  PrologAI — PR 11 SONA Continuous Learning Acceptance Tests

    AC-PR11-001: synaptic_ontological_neural_aggregator_absorb accepts a trajectory; synaptic_ontological_neural_aggregator_retrieve returns it.
    AC-PR11-002: synaptic_ontological_neural_aggregator_metrics returns expected fields after absorption.
    AC-PR11-003: EWC++ — learning 5 harvesting trajectories does NOT degrade
                 recall of 5 watering trajectories absorbed earlier.
    AC-PR11-004: Two trajectories identical except for outcome → synaptic_ontological_neural_aggregator_retrieve
                 returns BOTH, never one merged hybrid.
    AC-PR11-005: synaptic_ontological_neural_aggregator_crystallize writes crystallized_pattern node_facts.
    AC-PR11-006: Exact-duplicate trajectory (same SituationId, actions,
                 outcome) is NOT added a second time.
    AC-PR11-007: synaptic_ontological_neural_aggregator_retrieve/3 respects the K limit.
    AC-PR11-008: synaptic_ontological_neural_aggregator_crystallize with min_trajectory_count(N) skips when
                 bank is too small.
    AC-PR11-009: synaptic_ontological_neural_aggregator_retrieve with no entries returns empty list.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SonaPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [set_default_nexus/1, traverse_nexus/4,
                                    % Continue the multi-line expression started above.
                                    default_nexus/1]).
% Load the built-in 'sona' library so its predicates are available here.
:- use_module(library(synaptic_ontological_neural_aggregator),       [synaptic_ontological_neural_aggregator_absorb/1, synaptic_ontological_neural_aggregator_retrieve/2,
                                    % Continue the multi-line expression started above.
                                    synaptic_ontological_neural_aggregator_retrieve/3, synaptic_ontological_neural_aggregator_metrics/1,
                                    % Continue the multi-line expression started above.
                                    synaptic_ontological_neural_aggregator_crystallize/1]).

% Execute the compile-time directive: begin_tests(pr11, [setup(pr11_setup), cleanup(pr11_cleanup)]).
:- begin_tests(pr11, [setup(pr11_setup), cleanup(pr11_cleanup)]).

% Execute: pr11_setup :-.
pr11_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr11', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr11_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Clear SONA state between test runs
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_trajectory_entry(_, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_importance(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_retrieval_count(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_trajectory_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(sona:synaptic_ontological_neural_aggregator_trajectory_id_counter(0)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_consolidation_cycle(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(sona:synaptic_ontological_neural_aggregator_consolidation_cycle(0)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_last_crystallize_time(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(sona:synaptic_ontological_neural_aggregator_last_crystallize_time(0.0)).

% Execute: pr11_cleanup :-.
pr11_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr11_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR11-001
% Define a clause for 'test': succeed when the following conditions hold.
test(absorb_and_retrieve) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_001, [pick(apple)], success, 1.0, T)),
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(sit_001, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [],
    % Check that 'Results' is unifiable with '[trajectory(sit_001, _, success, _, _)|_]'.
    Results = [trajectory(sit_001, _, success, _, _)|_].

%  AC-PR11-002
% Define a clause for 'test': succeed when the following conditions hold.
test(metrics_after_absorption) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_002, [move(north)], success, 0.8, T)),
    % State a fact for 'sona metrics' with the arguments listed below.
    synaptic_ontological_neural_aggregator_metrics(M),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(trajectory_count, M, Count),
    % Check that 'Count' is greater than or equal to '1'.
    Count >= 1,
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(consolidation_cycle, M, CC),
    % Check that 'CC' is greater than or equal to '0'.
    CC >= 0,
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(bank_capacity_used, M, Cap),
    % Check that 'Cap' is greater than or equal to '0.0'.
    Cap >= 0.0.

%  AC-PR11-003: EWC++ — harvesting trajectories don't degrade watering recall
% Define a clause for 'test': succeed when the following conditions hold.
test(ewcpp_non_degradation) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Absorb 5 watering trajectories
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 5, I), (
        % Continue the multi-line expression started above.
        SitId =.. [water_sit, I],
        % Continue the multi-line expression started above.
        synaptic_ontological_neural_aggregator_absorb(trajectory(SitId, [water(plant, I)], success, 1.0, T))
    % Close the expression opened above.
    )),
    % Retrieve watering before adding harvesting (baseline)
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(water_sit(1), 5, Before),
    % Unify 'N_Before' with the number of elements in list 'Before'.
    length(Before, N_Before),
    % Absorb 5 harvesting trajectories
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 5, J), (
        % Continue the multi-line expression started above.
        SitId2 =.. [harvest_sit, J],
        % Continue the multi-line expression started above.
        synaptic_ontological_neural_aggregator_absorb(trajectory(SitId2, [harvest(crop, J)], success, 1.0, T))
    % Close the expression opened above.
    )),
    % Absorb one more watering trajectory
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(water_sit(6), [water(plant, 6)], success, 1.0, T)),
    % Recall of watering should not be degraded
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(water_sit(1), 5, After),
    % Unify 'N_After' with the number of elements in list 'After'.
    length(After, N_After),
    % Check that 'N_After' is greater than or equal to 'N_Before'.
    N_After >= N_Before.

%  AC-PR11-004: pattern separation — two trajectories same situation, different outcome
% Define a clause for 'test': succeed when the following conditions hold.
test(pattern_separation_dual_recall) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_fork, [push(button)], success, 1.0, T)),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_fork, [push(button)], failure, -1.0, T)),
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(sit_fork, Results),
    % Unify 'N' with the number of elements in list 'Results'.
    length(Results, N),
    % Check that 'N' is greater than or equal to '2'.
    N >= 2,
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(trajectory(sit_fork, _, success, _, _), Results),
    % State the fact: memberchk(trajectory(sit_fork, _, failure, _, _), Results).
    memberchk(trajectory(sit_fork, _, failure, _, _), Results).

%  AC-PR11-005: crystallize creates node_facts
% Define a clause for 'test': succeed when the following conditions hold.
test(crystallize_inscribes_node_facts) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 3, I), (
        % Continue the multi-line expression started above.
        SA =.. [crystal_sit, I],
        % Continue the multi-line expression started above.
        synaptic_ontological_neural_aggregator_absorb(trajectory(SA, [step(I)], success, 0.5, T))
    % Close the expression opened above.
    )),
    % State a fact for 'sona crystallize' with the arguments listed below.
    synaptic_ontological_neural_aggregator_crystallize([]),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nx,
        % Continue the multi-line expression started above.
        node_fact(crystallized_pattern, _, _),
        % Continue the multi-line expression started above.
        10, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR11-006: exact duplicate not added
% Define a clause for 'test': succeed when the following conditions hold.
test(duplicate_not_stored) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    % State a fact for 'sona absorb' with the arguments listed below.
    synaptic_ontological_neural_aggregator_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  sona:synaptic_ontological_neural_aggregator_trajectory_entry(_, sit_dup, [do(x)], success, _, _),
                  % Supply 'N' as the next argument to the expression above.
                  N),
    % Check that 'N' is numerically equal to '1'.
    N =:= 1.

%  AC-PR11-007: synaptic_ontological_neural_aggregator_retrieve/3 respects K limit
% Define a clause for 'test': succeed when the following conditions hold.
test(retrieve_respects_k) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, I), (
        % Continue the multi-line expression started above.
        SA =.. [batch_sit, I],
        % Continue the multi-line expression started above.
        synaptic_ontological_neural_aggregator_absorb(trajectory(SA, [act(I)], success, 0.5, T))
    % Close the expression opened above.
    )),
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(batch_sit(1), 3, Results),
    % Unify 'N' with the number of elements in list 'Results'.
    length(Results, N),
    % Check that 'N' is less than or equal to '3'.
    N =< 3.

%  AC-PR11-008: crystallize respects min_trajectory_count
% Define a clause for 'test': succeed when the following conditions hold.
test(crystallize_skips_when_too_few) :-
    % State a fact for 'sona metrics' with the arguments listed below.
    synaptic_ontological_neural_aggregator_metrics(M0),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(consolidation_cycle, M0, CC0),
    % Require more trajectories than exist in the bank
    % State a fact for 'sona crystallize' with the arguments listed below.
    synaptic_ontological_neural_aggregator_crystallize([min_trajectory_count(9999)]),
    % State a fact for 'sona metrics' with the arguments listed below.
    synaptic_ontological_neural_aggregator_metrics(M1),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(consolidation_cycle, M1, CC1),
    % Check that 'CC1' is numerically equal to 'CC0.   % cycle unchanged because threshold not met'.
    CC1 =:= CC0.   % cycle unchanged because threshold not met

%  AC-PR11-009: retrieve with empty bank returns empty list
% Define a clause for 'test': succeed when the following conditions hold.
test(retrieve_empty_bank) :-
    % Temporarily clear bank state, retrieve, then restore doesn't matter
    % Remove all matching facts from the runtime knowledge base.
    retractall(sona:synaptic_ontological_neural_aggregator_trajectory_entry(_, _, _, _, _, _)),
    % State a fact for 'sona retrieve' with the arguments listed below.
    synaptic_ontological_neural_aggregator_retrieve(no_such_situation, Results),
    % Check that 'Results' is unifiable with '[]'.
    Results = [].

% Execute the compile-time directive: end_tests(pr11).
:- end_tests(pr11).
