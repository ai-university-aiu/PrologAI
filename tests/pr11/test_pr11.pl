/*  PrologAI — PR 11 SONA Continuous Learning Acceptance Tests

    AC-PR11-001: sona_absorb accepts a trajectory; sona_retrieve returns it.
    AC-PR11-002: sona_metrics returns expected fields after absorption.
    AC-PR11-003: EWC++ — learning 5 harvesting trajectories does NOT degrade
                 recall of 5 watering trajectories absorbed earlier.
    AC-PR11-004: Two trajectories identical except for outcome → sona_retrieve
                 returns BOTH, never one merged hybrid.
    AC-PR11-005: sona_crystallize writes crystallized_pattern node_facts.
    AC-PR11-006: Exact-duplicate trajectory (same SituationId, actions,
                 outcome) is NOT added a second time.
    AC-PR11-007: sona_retrieve/3 respects the K limit.
    AC-PR11-008: sona_crystallize with min_trajectory_count(N) skips when
                 bank is too small.
    AC-PR11-009: sona_retrieve with no entries returns empty list.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, SonaPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1, traverse_nexus/4,
                                    default_nexus/1]).
:- use_module(library(sona),       [sona_absorb/1, sona_retrieve/2,
                                    sona_retrieve/3, sona_metrics/1,
                                    sona_crystallize/1]).

:- begin_tests(pr11, [setup(pr11_setup), cleanup(pr11_cleanup)]).

pr11_setup :-
    lattice_open('locus://localhost/pr11', N),
    nb_setval(pr11_nexus_ref, N),
    set_default_nexus(N),
    % Clear SONA state between test runs
    retractall(sona:sona_trajectory_entry(_, _, _, _, _, _)),
    retractall(sona:sona_importance(_, _)),
    retractall(sona:sona_retrieval_count(_, _)),
    retractall(sona:sona_trajectory_id_counter(_)),
    assertz(sona:sona_trajectory_id_counter(0)),
    retractall(sona:sona_consolidation_cycle(_)),
    assertz(sona:sona_consolidation_cycle(0)),
    retractall(sona:sona_last_crystallize_time(_)),
    assertz(sona:sona_last_crystallize_time(0.0)).

pr11_cleanup :-
    nb_getval(pr11_nexus_ref, N),
    lattice_close(N).

%  AC-PR11-001
test(absorb_and_retrieve) :-
    get_time(T),
    sona_absorb(trajectory(sit_001, [pick(apple)], success, 1.0, T)),
    sona_retrieve(sit_001, Results),
    Results \= [],
    Results = [trajectory(sit_001, _, success, _, _)|_].

%  AC-PR11-002
test(metrics_after_absorption) :-
    get_time(T),
    sona_absorb(trajectory(sit_002, [move(north)], success, 0.8, T)),
    sona_metrics(M),
    get_dict(trajectory_count, M, Count),
    Count >= 1,
    get_dict(consolidation_cycle, M, CC),
    CC >= 0,
    get_dict(bank_capacity_used, M, Cap),
    Cap >= 0.0.

%  AC-PR11-003: EWC++ — harvesting trajectories don't degrade watering recall
test(ewcpp_non_degradation) :-
    get_time(T),
    % Absorb 5 watering trajectories
    forall(between(1, 5, I), (
        SitId =.. [water_sit, I],
        sona_absorb(trajectory(SitId, [water(plant, I)], success, 1.0, T))
    )),
    % Retrieve watering before adding harvesting (baseline)
    sona_retrieve(water_sit(1), 5, Before),
    length(Before, N_Before),
    % Absorb 5 harvesting trajectories
    forall(between(1, 5, J), (
        SitId2 =.. [harvest_sit, J],
        sona_absorb(trajectory(SitId2, [harvest(crop, J)], success, 1.0, T))
    )),
    % Absorb one more watering trajectory
    sona_absorb(trajectory(water_sit(6), [water(plant, 6)], success, 1.0, T)),
    % Recall of watering should not be degraded
    sona_retrieve(water_sit(1), 5, After),
    length(After, N_After),
    N_After >= N_Before.

%  AC-PR11-004: pattern separation — two trajectories same situation, different outcome
test(pattern_separation_dual_recall) :-
    get_time(T),
    sona_absorb(trajectory(sit_fork, [push(button)], success, 1.0, T)),
    sona_absorb(trajectory(sit_fork, [push(button)], failure, -1.0, T)),
    sona_retrieve(sit_fork, Results),
    length(Results, N),
    N >= 2,
    memberchk(trajectory(sit_fork, _, success, _, _), Results),
    memberchk(trajectory(sit_fork, _, failure, _, _), Results).

%  AC-PR11-005: crystallize creates node_facts
test(crystallize_inscribes_node_facts) :-
    get_time(T),
    forall(between(1, 3, I), (
        SA =.. [crystal_sit, I],
        sona_absorb(trajectory(SA, [step(I)], success, 0.5, T))
    )),
    sona_crystallize([]),
    default_nexus(Nx),
    traverse_nexus(Nx,
        node_fact(crystallized_pattern, _, _),
        10, Results),
    Results \= [].

%  AC-PR11-006: exact duplicate not added
test(duplicate_not_stored) :-
    get_time(T),
    sona_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    sona_absorb(trajectory(sit_dup, [do(x)], success, 1.0, T)),
    aggregate_all(count,
                  sona:sona_trajectory_entry(_, sit_dup, [do(x)], success, _, _),
                  N),
    N =:= 1.

%  AC-PR11-007: sona_retrieve/3 respects K limit
test(retrieve_respects_k) :-
    get_time(T),
    forall(between(1, 8, I), (
        SA =.. [batch_sit, I],
        sona_absorb(trajectory(SA, [act(I)], success, 0.5, T))
    )),
    sona_retrieve(batch_sit(1), 3, Results),
    length(Results, N),
    N =< 3.

%  AC-PR11-008: crystallize respects min_trajectory_count
test(crystallize_skips_when_too_few) :-
    sona_metrics(M0),
    get_dict(consolidation_cycle, M0, CC0),
    % Require more trajectories than exist in the bank
    sona_crystallize([min_trajectory_count(9999)]),
    sona_metrics(M1),
    get_dict(consolidation_cycle, M1, CC1),
    CC1 =:= CC0.   % cycle unchanged because threshold not met

%  AC-PR11-009: retrieve with empty bank returns empty list
test(retrieve_empty_bank) :-
    % Temporarily clear bank state, retrieve, then restore doesn't matter
    retractall(sona:sona_trajectory_entry(_, _, _, _, _, _)),
    sona_retrieve(no_such_situation, Results),
    Results = [].

:- end_tests(pr11).
