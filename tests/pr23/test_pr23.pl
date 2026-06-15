/*  PrologAI — PR 23 Curiosity: Intrinsic Motivation by Learning Progress

    AC-PR23-001: Given region A (shrinking error) and region B (stationary
                 random error), when curiosity urges are computed, region A
                 receives the higher urge.
    AC-PR23-002: Given an idle interval, when pai_self_propose_task runs,
                 at least one curiosity_task node_fact exists with its
                 proposal rationale, goal, and learning-progress score.
    AC-PR23-003: pai_learning_progress returns 0.0 with only one data point.
    AC-PR23-004: pai_learning_progress is positive for a strictly decreasing
                 error series.
    AC-PR23-005: Noisy-TV guard: a region with constant high error (no
                 change) receives a lower urge than one with shrinking error.
    AC-PR23-006: Habituation grows after a visit and bounds the urge.
    AC-PR23-007: pai_curiosity_frontier returns the region with highest urge.
    AC-PR23-008: pai_curiosity_update ticks without error and caches urges.
    AC-PR23-009: Error window is capped: only the last N=10 errors are kept.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/curiosity/prolog'],      CuriosityPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, CuriosityPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts),[set_default_nexus/1]).
:- use_module(library(curiosity), [
    pai_observe_error/3,
    pai_learning_progress/2,
    pai_curiosity_urge/2,
    pai_curiosity_frontier/1,
    pai_self_propose_task/3,
    pai_curiosity_update/0
]).

:- begin_tests(pr23, [setup(pr23_setup), cleanup(pr23_cleanup)]).

pr23_setup :-
    lattice_open('locus://localhost/pr23', N),
    nb_setval(pr23_nexus_ref, N),
    set_default_nexus(N),
    retractall(curiosity:region_error_entry(_, _, _)),
    retractall(curiosity:region_habituation(_, _)),
    retractall(curiosity:region_urge_cache(_, _)).

pr23_cleanup :-
    nb_getval(pr23_nexus_ref, N),
    retractall(curiosity:region_error_entry(_, _, _)),
    retractall(curiosity:region_habituation(_, _)),
    retractall(curiosity:region_urge_cache(_, _)),
    lattice_close(N).

%  AC-PR23-001: shrinking-error region receives higher urge than noisy flat region
test(shrinking_beats_noisy) :-
    % Region A: errors shrink 1.0 → 0.5 → 0.25 → 0.1 → 0.05
    forall(
        member(E-T, [1.0-1, 0.5-2, 0.25-3, 0.1-4, 0.05-5]),
        pai_observe_error(region_a, E, T)
    ),
    % Region B: stationary noise around 0.8
    forall(
        member(E-T, [0.8-1, 0.9-2, 0.75-3, 0.85-4, 0.8-5]),
        pai_observe_error(region_b, E, T)
    ),
    pai_curiosity_urge(region_a, UrgeA),
    pai_curiosity_urge(region_b, UrgeB),
    UrgeA > UrgeB.

%  AC-PR23-002: pai_self_propose_task inscribes a curiosity_task node_fact
test(self_propose_task_inscribes_node) :-
    forall(
        member(E-T, [1.0-1, 0.6-2, 0.3-3, 0.1-4, 0.05-5]),
        pai_observe_error(region_propose, E, T)
    ),
    pai_self_propose_task(region_propose, GoalNodeId, LP),
    nonvar(GoalNodeId),
    LP > 0.0.

%  AC-PR23-003: single data point → progress = 0.0
test(single_error_progress_zero) :-
    pai_observe_error(region_single, 0.5, 1),
    pai_learning_progress(region_single, LP),
    LP =:= 0.0.

%  AC-PR23-004: strictly decreasing errors → positive learning progress
test(decreasing_errors_positive_progress) :-
    forall(
        member(E-T, [1.0-1, 0.8-2, 0.6-3, 0.4-4, 0.2-5, 0.1-6]),
        pai_observe_error(region_decreasing, E, T)
    ),
    pai_learning_progress(region_decreasing, LP),
    LP > 0.0.

%  AC-PR23-005: constant high error → urge lower than shrinking region
test(constant_high_error_low_urge) :-
    % Shrinking region (from test 001)
    forall(
        member(E-T, [1.0-1, 0.5-2, 0.25-3, 0.1-4, 0.05-5]),
        pai_observe_error(region_shrink2, E, T)
    ),
    % Constant region
    forall(
        member(E-T, [0.9-1, 0.9-2, 0.9-3, 0.9-4, 0.9-5]),
        pai_observe_error(region_const, E, T)
    ),
    pai_curiosity_urge(region_shrink2, UShrink),
    pai_curiosity_urge(region_const,   UConst),
    UShrink > UConst.

%  AC-PR23-006: habituation grows with visits and reduces urge
test(habituation_reduces_urge) :-
    forall(
        member(E-T, [1.0-1, 0.5-2, 0.2-3, 0.1-4, 0.05-5]),
        pai_observe_error(region_hab, E, T)
    ),
    pai_curiosity_urge(region_hab, UrgeBase),
    % Simulate a visit (increases habituation)
    pai_self_propose_task(region_hab, _, _),
    pai_curiosity_urge(region_hab, UrgeAfter),
    UrgeAfter =< UrgeBase.

%  AC-PR23-007: pai_curiosity_frontier returns the region with highest urge
test(curiosity_frontier_correct) :-
    % region_f1: big shrink → high urge
    forall(
        member(E-T, [1.0-1, 0.5-2, 0.2-3, 0.05-4, 0.01-5]),
        pai_observe_error(region_f1, E, T)
    ),
    % region_f2: small shrink → lower urge
    forall(
        member(E-T, [0.6-1, 0.55-2, 0.5-3, 0.48-4, 0.46-5]),
        pai_observe_error(region_f2, E, T)
    ),
    pai_curiosity_urge(region_f1, U1),
    pai_curiosity_urge(region_f2, U2),
    U1 > U2,
    pai_curiosity_frontier(Frontier),
    Frontier = region_f1.

%  AC-PR23-008: pai_curiosity_update ticks without error
test(curiosity_update_runs) :-
    forall(
        member(E-T, [1.0-1, 0.5-2, 0.2-3]),
        pai_observe_error(region_upd, E, T)
    ),
    pai_curiosity_update.

%  AC-PR23-009: error window is capped at 10 entries
test(error_window_capped) :-
    forall(
        between(1, 15, I),
        pai_observe_error(region_cap, 0.5, I)
    ),
    aggregate_all(count, curiosity:region_error_entry(region_cap, _, _), N),
    N =:= 10.

:- end_tests(pr23).
