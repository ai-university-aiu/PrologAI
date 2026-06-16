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
   atomic_list_concat([ProjectRoot, '/packs/assessment/prolog'],     AssessPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AssessPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1, anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).
% Load the built-in 'assessment' library so its predicates are available here.
:- use_module(library(assessment), [assess_bayley/2, assess_piaget/3,
                                    % Continue the multi-line expression started above.
                                    assess_chc/2, assess_all/2]).

% Execute the compile-time directive: begin_tests(pr12, [setup(pr12_setup), cleanup(pr12_cleanup)]).
:- begin_tests(pr12, [setup(pr12_setup), cleanup(pr12_cleanup)]).

% Execute: pr12_setup :-.
pr12_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr12', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr12_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr12_cleanup :-.
pr12_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr12_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR12-001
% Define a clause for 'test': succeed when the following conditions hold.
test(piaget_level1_fresh_mind) :-
    % State a fact for 'assess piaget' with the arguments listed below.
    assess_piaget(mind1, 1, R),
    % Check that 'R' is unifiable with 'milestone_not_achieved'.
    R = milestone_not_achieved.

%  AC-PR12-002
% Define a clause for 'test': succeed when the following conditions hold.
test(piaget_achieved_after_evidence) :-
    % Inscribe the proxy evidence for level 1 (reflex_coordination = percept_signal)
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept_signal, [herald_test, visual_data], [], _),
    % State a fact for 'assess piaget' with the arguments listed below.
    assess_piaget(mind1, 1, R),
    % Check that 'R' is unifiable with 'milestone_achieved'.
    R = milestone_achieved.

%  AC-PR12-003
% Define a clause for 'test': succeed when the following conditions hold.
test(piaget_all_levels_fresh_fail) :-
    % Open a separate fresh nexus
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr12_fresh', FN),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(FN),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, L), (
        % Continue the multi-line expression started above.
        assess_piaget(mind_fresh, L, milestone_not_achieved)
    % Close the expression opened above.
    )),
    % State a fact for 'lattice close' with the arguments listed below.
    lattice_close(FN),
    % Restore original nexus
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr12_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

%  AC-PR12-004
% Define a clause for 'test': succeed when the following conditions hold.
test(bayley_returns_expected_keys) :-
    % State a fact for 'assess bayley' with the arguments listed below.
    assess_bayley(mind1, Report),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(mind, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(cognitive_dq, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(language_dq, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(motor_dq, Report, _),
    % State the fact: get dict(adaptive_dq, Report, _).
    get_dict(adaptive_dq, Report, _).

%  AC-PR12-005
% Define a clause for 'test': succeed when the following conditions hold.
test(chc_returns_expected_keys) :-
    % State a fact for 'assess chc' with the arguments listed below.
    assess_chc(mind1, Report),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(mind, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(fluid_reasoning, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(crystallized_knowledge, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(short_term_memory, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(processing_speed, Report, _),
    % State the fact: get dict(long_term_retrieval, Report, _).
    get_dict(long_term_retrieval, Report, _).

%  AC-PR12-006
% Define a clause for 'test': succeed when the following conditions hold.
test(assess_all_returns_all_sections) :-
    % State a fact for 'assess all' with the arguments listed below.
    assess_all(mind1, Report),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(bayley, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(chc, Report, _),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(piaget_milestones, Report, Piaget),
    % Unify '8' with the number of elements in list 'Piaget'.
    length(Piaget, 8),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(consciousness_indicators, Report, CI),
    % Check that 'CI' is not unifiable with '[]'.
    CI \= [].

%  AC-PR12-007
% Define a clause for 'test': succeed when the following conditions hold.
test(assess_all_stores_node_fact) :-
    % State a fact for 'assess all' with the arguments listed below.
    assess_all(mind_stored, _),
    % Execute: node_facts:lattice_node_fact(_, _, assessment, [mind_stored, all, _], [])..
    node_facts:lattice_node_fact(_, _, assessment, [mind_stored, all, _], []).

%  AC-PR12-008
% Define a clause for 'test': succeed when the following conditions hold.
test(consciousness_workspace_ignition_absent) :-
    % State a fact for 'assess all' with the arguments listed below.
    assess_all(mind_ci, Report),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(consciousness_indicators, Report, CI),
    % State the fact: memberchk(workspace_ignition-absent, CI).
    memberchk(workspace_ignition-absent, CI).

%  AC-PR12-009
% Define a clause for 'test': succeed when the following conditions hold.
test(piaget_out_of_range_fails, [fail]) :-
    % State the fact: assess piaget(mind1, 9, _).
    assess_piaget(mind1, 9, _).

% Execute the compile-time directive: end_tests(pr12).
:- end_tests(pr12).
