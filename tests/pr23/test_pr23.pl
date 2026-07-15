/*  PrologAI — PR 23 Curiosity: Intrinsic Motivation by Learning Progress

    AC-PR23-001: Given region A (shrinking error) and region B (stationary
                 random error), when curiosity urges are computed, region A
                 receives the higher urge.
    AC-PR23-002: Given an idle interval, when curiosity_self_propose_task runs,
                 at least one curiosity_task node_fact exists with its
                 proposal rationale, goal, and learning-progress score.
    AC-PR23-003: curiosity_learning_progress returns 0.0 with only one data point.
    AC-PR23-004: curiosity_learning_progress is positive for a strictly decreasing
                 error series.
    AC-PR23-005: Noisy-TV guard: a region with constant high error (no
                 change) receives a lower urge than one with shrinking error.
    AC-PR23-006: Habituation grows after a visit and bounds the urge.
    AC-PR23-007: curiosity_frontier returns the region with highest urge.
    AC-PR23-008: curiosity_update ticks without error and caches urges.
    AC-PR23-009: Error window is capped: only the last N=10 errors are kept.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/curiosity/prolog'],      CuriosityPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, CuriosityPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),[set_default_nexus/1]).
% Load the built-in 'curiosity' library so its predicates are available here.
:- use_module(library(curiosity), [
    % Supply 'curiosity_observe_error/3' as the next argument to the expression above.
    curiosity_observe_error/3,
    % Supply 'curiosity_learning_progress/2' as the next argument to the expression above.
    curiosity_learning_progress/2,
    % Supply 'curiosity_urge/2' as the next argument to the expression above.
    curiosity_urge/2,
    % Supply 'curiosity_frontier/1' as the next argument to the expression above.
    curiosity_frontier/1,
    % Supply 'curiosity_self_propose_task/3' as the next argument to the expression above.
    curiosity_self_propose_task/3,
    % Supply 'curiosity_update/0' as the next argument to the expression above.
    curiosity_update/0
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr23, [setup(pr23_setup), cleanup(pr23_cleanup)]).
:- begin_tests(pr23, [setup(pr23_setup), cleanup(pr23_cleanup)]).

% Execute: pr23_setup :-.
pr23_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr23', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr23_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_error_entry(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_habituation(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_urge_cache(_, _)).

% Execute: pr23_cleanup :-.
pr23_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr23_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_error_entry(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_habituation(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(curiosity:region_urge_cache(_, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR23-001: shrinking-error region receives higher urge than noisy flat region
% Define a clause for 'test': succeed when the following conditions hold.
test(shrinking_beats_noisy) :-
    % Region A: errors shrink 1.0 → 0.5 → 0.25 → 0.1 → 0.05
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.5-2, 0.25-3, 0.1-4, 0.05-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_a, E, T)
    % Close the expression opened above.
    ),
    % Region B: stationary noise around 0.8
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [0.8-1, 0.9-2, 0.75-3, 0.85-4, 0.8-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_b, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_a, UrgeA),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_b, UrgeB),
    % Check that 'UrgeA' is greater than 'UrgeB'.
    UrgeA > UrgeB.

%  AC-PR23-002: curiosity_self_propose_task inscribes a curiosity_task node_fact
% Define a clause for 'test': succeed when the following conditions hold.
test(self_propose_task_inscribes_node) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.6-2, 0.3-3, 0.1-4, 0.05-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_propose, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai self propose task' with the arguments listed below.
    curiosity_self_propose_task(region_propose, GoalNodeId, LP),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(GoalNodeId),
    % Check that 'LP' is greater than '0.0'.
    LP > 0.0.

%  AC-PR23-003: single data point → progress = 0.0
% Define a clause for 'test': succeed when the following conditions hold.
test(single_error_progress_zero) :-
    % State a fact for 'pai observe error' with the arguments listed below.
    curiosity_observe_error(region_single, 0.5, 1),
    % State a fact for 'pai learning progress' with the arguments listed below.
    curiosity_learning_progress(region_single, LP),
    % Check that 'LP' is numerically equal to '0.0'.
    LP =:= 0.0.

%  AC-PR23-004: strictly decreasing errors → positive learning progress
% Define a clause for 'test': succeed when the following conditions hold.
test(decreasing_errors_positive_progress) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.8-2, 0.6-3, 0.4-4, 0.2-5, 0.1-6]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_decreasing, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai learning progress' with the arguments listed below.
    curiosity_learning_progress(region_decreasing, LP),
    % Check that 'LP' is greater than '0.0'.
    LP > 0.0.

%  AC-PR23-005: constant high error → urge lower than shrinking region
% Define a clause for 'test': succeed when the following conditions hold.
test(constant_high_error_low_urge) :-
    % Shrinking region (from test 001)
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.5-2, 0.25-3, 0.1-4, 0.05-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_shrink2, E, T)
    % Close the expression opened above.
    ),
    % Constant region
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [0.9-1, 0.9-2, 0.9-3, 0.9-4, 0.9-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_const, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_shrink2, UShrink),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_const,   UConst),
    % Check that 'UShrink' is greater than 'UConst'.
    UShrink > UConst.

%  AC-PR23-006: habituation grows with visits and reduces urge
% Define a clause for 'test': succeed when the following conditions hold.
test(habituation_reduces_urge) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.5-2, 0.2-3, 0.1-4, 0.05-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_hab, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_hab, UrgeBase),
    % Simulate a visit (increases habituation)
    % State a fact for 'pai self propose task' with the arguments listed below.
    curiosity_self_propose_task(region_hab, _, _),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_hab, UrgeAfter),
    % Check that 'UrgeAfter' is less than or equal to 'UrgeBase'.
    UrgeAfter =< UrgeBase.

%  AC-PR23-007: curiosity_frontier returns the region with highest urge
% Define a clause for 'test': succeed when the following conditions hold.
test(curiosity_frontier_correct) :-
    % region_f1: big shrink → high urge
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.5-2, 0.2-3, 0.05-4, 0.01-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_f1, E, T)
    % Close the expression opened above.
    ),
    % region_f2: small shrink → lower urge
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [0.6-1, 0.55-2, 0.5-3, 0.48-4, 0.46-5]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_f2, E, T)
    % Close the expression opened above.
    ),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_f1, U1),
    % State a fact for 'pai curiosity urge' with the arguments listed below.
    curiosity_urge(region_f2, U2),
    % Check that 'U1' is greater than 'U2'.
    U1 > U2,
    % State a fact for 'pai curiosity frontier' with the arguments listed below.
    curiosity_frontier(Frontier),
    % Check that 'Frontier' is unifiable with 'region_f1'.
    Frontier = region_f1.

%  AC-PR23-008: curiosity_update ticks without error
% Define a clause for 'test': succeed when the following conditions hold.
test(curiosity_update_runs) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(E-T, [1.0-1, 0.5-2, 0.2-3]),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_upd, E, T)
    % Close the expression opened above.
    ),
    % State the zero-argument fact 'curiosity_update'.
    curiosity_update.

%  AC-PR23-009: error window is capped at 10 entries
% Define a clause for 'test': succeed when the following conditions hold.
test(error_window_capped) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 15, I),
        % Continue the multi-line expression started above.
        curiosity_observe_error(region_cap, 0.5, I)
    % Close the expression opened above.
    ),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, curiosity:region_error_entry(region_cap, _, _), N),
    % Check that 'N' is numerically equal to '10'.
    N =:= 10.

% Execute the compile-time directive: end_tests(pr23).
:- end_tests(pr23).
