/*  PrologAI — PR 13 Reflection Pattern Actors Acceptance Tests

    AC-PR13-001: install_reflection_actors/0 starts all 10 cyclic actors.
    AC-PR13-002: uninstall_reflection_actors/0 stops them all.
    AC-PR13-003: motivation_cycle/0 inscribes an objective node_fact when
                 a homeostatic delta exceeds threshold.
    AC-PR13-004: exploration_cycle/0 inscribes an explore_objective.
    AC-PR13-005: meta_control_cycle/0 runs without error on a fresh nexus.
    AC-PR13-006: regulation_cycle/0 classifies a confirmed outcome.
    AC-PR13-007: compensation_actor sentinel is registered after install.
    AC-PR13-008: discovery_actor sentinel is registered after install.
    AC-PR13-009: impasse_cycle/0 inscribes subgoal for objective without plan.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   atomic_list_concat([ProjectRoot, '/packs/mindbody/prolog'],       MindBodyPath),
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   atomic_list_concat([ProjectRoot, '/packs/scopes/prolog'],         ScopesPath),
   atomic_list_concat([ProjectRoot, '/packs/reflection/prolog'],     ReflectionPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, SentinelPath)),
   assertz(file_search_path(library, MindBodyPath)),
   assertz(file_search_path(library, SonaPath)),
   assertz(file_search_path(library, ScopesPath)),
   assertz(file_search_path(library, ReflectionPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),     [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts),  [set_default_nexus/1, anchor_node/4,
                                     default_nexus/1]).
:- use_module(library(cyclic_actor),[cyclic_actor_list/1, cyclic_actor_stop/1]).
:- use_module(library(sentinels),   [sentinel_list/2]).
:- use_module(library(mindbody),    [manifest_body/3]).
:- use_module(library(reflection),  [install_reflection_actors/0,
                                     uninstall_reflection_actors/0,
                                     motivation_cycle/0, exploration_cycle/0,
                                     meta_control_cycle/0, regulation_cycle/0,
                                     impasse_cycle/0]).

:- begin_tests(pr13, [setup(pr13_setup), cleanup(pr13_cleanup)]).

pr13_setup :-
    lattice_open('locus://localhost/pr13', N),
    nb_setval(pr13_nexus_ref, N),
    set_default_nexus(N).

pr13_cleanup :-
    uninstall_reflection_actors,
    nb_getval(pr13_nexus_ref, N),
    lattice_close(N).

reflection_actor_names([
    motivation_actor, daydream_actor, regulation_actor,
    coping_actor, exploration_actor, imitation_actor,
    play_actor, meta_control_actor, gating_actor, impasse_actor
]).

%  AC-PR13-001
test(install_starts_all_cyclic_actors) :-
    install_reflection_actors,
    cyclic_actor_list(Running),
    reflection_actor_names(Expected),
    forall(
        member(Name, Expected),
        memberchk(Name, Running)
    ).

%  AC-PR13-002
test(uninstall_stops_all_cyclic_actors) :-
    install_reflection_actors,
    uninstall_reflection_actors,
    cyclic_actor_list(Running),
    reflection_actor_names(Expected),
    forall(
        member(Name, Expected),
        \+ memberchk(Name, Running)
    ).

%  AC-PR13-003
test(motivation_cycle_inscribes_objective) :-
    % Enroll a body with a need and provide an interoceptive signal
    manifest_body('herald://test-body', [need(battery, 80.0, percent)], []),
    default_nexus(Nx),
    get_time(T),
    anchor_node(percept_signal,
                ['herald://test-body',
                 interoceptive_signal(battery, 60.0, T)],
                ['channel://motivation'],
                _),
    motivation_cycle,
    % Check that an objective node_fact was inscribed
    node_facts:lattice_node_fact(Nx, _, objective, [battery|_], _).

%  AC-PR13-004
test(exploration_cycle_inscribes_explore_objective) :-
    exploration_cycle,
    default_nexus(Nx),
    once(node_facts:lattice_node_fact(Nx, _, explore_objective, _, _)).

%  AC-PR13-005
test(meta_control_cycle_runs) :-
    meta_control_cycle.

%  AC-PR13-006
test(regulation_cycle_classifies_outcome) :-
    default_nexus(Nx),
    % Inscribe a body_command and a matching proprioceptive result
    anchor_node(body_command, ['herald://robot', cmd_99, test_cmd], [], _),
    get_time(T),
    anchor_node(percept_signal,
                ['herald://robot',
                 proprioceptive_signal(cmd_99, true, [], T)],
                ['channel://regulation'],
                _),
    regulation_cycle,
    node_facts:lattice_node_fact(Nx, _, regulation_outcome, [cmd_99, confirmation], []).

%  AC-PR13-007
test(compensation_sentinel_registered) :-
    install_reflection_actors,
    sentinel_list(compensation_actor, L),
    L \= [].

%  AC-PR13-008
test(discovery_sentinel_registered) :-
    install_reflection_actors,
    sentinel_list(discovery_actor, L),
    L \= [].

%  AC-PR13-009
test(impasse_cycle_inscribes_subgoal) :-
    default_nexus(Nx),
    anchor_node(objective, [need_battery, reduce_delta], [], _),
    impasse_cycle,
    once(node_facts:lattice_node_fact(Nx, _, subgoal, [impasse_resolution|_], _)).

:- end_tests(pr13).
