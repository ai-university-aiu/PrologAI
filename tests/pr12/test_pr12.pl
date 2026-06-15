/*  PrologAI — PR 12 Intelligence Assessment Acceptance Tests

    AC-PR12-001: Given a fresh mind, when assess_piaget(mind1, 1, R), then
                 R = milestone_not_achieved.
    AC-PR12-002: assess_piaget/3 returns milestone_achieved after the proxy
                 Lattice evidence is inscribed.
    AC-PR12-003: assess_piaget/3 covers all 8 levels for a fresh mind.
    AC-PR12-004: assess_bayley/2 returns a dict with the expected keys.
    AC-PR12-005: assess_chc/2 returns a dict with the expected keys.
    AC-PR12-006: assess_all/2 returns bayley, chc, piaget, and consciousness
                 indicator fields.
    AC-PR12-007: assess_all/2 stores an assessment node_fact in the Lattice.
    AC-PR12-008: consciousness_indicator workspace_ignition is absent for a
                 fresh mind.
    AC-PR12-009: assess_piaget/3 for an out-of-range level throws or fails.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/assessment/prolog'],     AssessPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, AssessPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).
:- use_module(library(assessment), [assess_bayley/2, assess_piaget/3,
                                    assess_chc/2, assess_all/2]).

:- begin_tests(pr12, [setup(pr12_setup), cleanup(pr12_cleanup)]).

pr12_setup :-
    lattice_open('locus://localhost/pr12', N),
    nb_setval(pr12_nexus_ref, N),
    set_default_nexus(N).

pr12_cleanup :-
    nb_getval(pr12_nexus_ref, N),
    lattice_close(N).

%  AC-PR12-001
test(piaget_level1_fresh_mind) :-
    assess_piaget(mind1, 1, R),
    R = milestone_not_achieved.

%  AC-PR12-002
test(piaget_achieved_after_evidence) :-
    % Inscribe the proxy evidence for level 1 (reflex_coordination = percept_signal)
    anchor_node(percept_signal, [herald_test, visual_data], [], _),
    assess_piaget(mind1, 1, R),
    R = milestone_achieved.

%  AC-PR12-003
test(piaget_all_levels_fresh_fail) :-
    % Open a separate fresh nexus
    lattice_open('locus://localhost/pr12_fresh', FN),
    set_default_nexus(FN),
    forall(between(1, 8, L), (
        assess_piaget(mind_fresh, L, milestone_not_achieved)
    )),
    lattice_close(FN),
    % Restore original nexus
    nb_getval(pr12_nexus_ref, N),
    set_default_nexus(N).

%  AC-PR12-004
test(bayley_returns_expected_keys) :-
    assess_bayley(mind1, Report),
    get_dict(mind, Report, _),
    get_dict(cognitive_dq, Report, _),
    get_dict(language_dq, Report, _),
    get_dict(motor_dq, Report, _),
    get_dict(adaptive_dq, Report, _).

%  AC-PR12-005
test(chc_returns_expected_keys) :-
    assess_chc(mind1, Report),
    get_dict(mind, Report, _),
    get_dict(fluid_reasoning, Report, _),
    get_dict(crystallized_knowledge, Report, _),
    get_dict(short_term_memory, Report, _),
    get_dict(processing_speed, Report, _),
    get_dict(long_term_retrieval, Report, _).

%  AC-PR12-006
test(assess_all_returns_all_sections) :-
    assess_all(mind1, Report),
    get_dict(bayley, Report, _),
    get_dict(chc, Report, _),
    get_dict(piaget_milestones, Report, Piaget),
    length(Piaget, 8),
    get_dict(consciousness_indicators, Report, CI),
    CI \= [].

%  AC-PR12-007
test(assess_all_stores_node_fact) :-
    assess_all(mind_stored, _),
    node_facts:lattice_node_fact(_, _, assessment, [mind_stored, all, _], []).

%  AC-PR12-008
test(consciousness_workspace_ignition_absent) :-
    assess_all(mind_ci, Report),
    get_dict(consciousness_indicators, Report, CI),
    memberchk(workspace_ignition-absent, CI).

%  AC-PR12-009
test(piaget_out_of_range_fails, [fail]) :-
    assess_piaget(mind1, 9, _).

:- end_tests(pr12).
