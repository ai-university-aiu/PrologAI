/*  PrologAI — PR 13 Reflection Pattern Actors Acceptance Tests

    AC-PR13-001: reflection_install_actors/0 starts all 10 cyclic actors.
    AC-PR13-002: reflection_uninstall_actors/0 stops them all.
    AC-PR13-003: reflection_motivation_cycle/0 inscribes an objective node_fact when
                 a homeostatic delta exceeds threshold.
    AC-PR13-004: reflection_exploration_cycle/0 inscribes an explore_objective.
    AC-PR13-005: reflection_meta_control_cycle/0 runs without error on a fresh nexus.
    AC-PR13-006: reflection_regulation_cycle/0 classifies a confirmed outcome.
    AC-PR13-007: compensation_actor sentinel is registered after install.
    AC-PR13-008: discovery_actor sentinel is registered after install.
    AC-PR13-009: reflection_impasse_cycle/0 inscribes subgoal for objective without plan.
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
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/mindbody/prolog'],       MindBodyPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/scopes/prolog'],         ScopesPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/reflection/prolog'],     ReflectionPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SentinelPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, MindBodyPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SonaPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ScopesPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ReflectionPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [lattice_open/2, lattice_close/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [set_default_nexus/1, anchor_node/4,
                                     % Continue the multi-line expression started above.
                                     default_nexus/1]).
% Import [cyclic_actor_list/1, cyclic_actor_stop/1] from the built-in 'cyclic_actor' library.
:- use_module(library(cyclic_actor),[cyclic_actor_list/1, cyclic_actor_stop/1]).
% Import [sentinels_list/2] from the built-in 'sentinels' library.
:- use_module(library(sentinels),   [sentinels_list/2]).
% Import [manifest_body/3] from the built-in 'mindbody' library.
:- use_module(library(mindbody),    [manifest_body/3]).
% Load the built-in 'reflection' library so its predicates are available here.
:- use_module(library(reflection),  [reflection_install_actors/0,
                                     % Supply 'reflection_uninstall_actors/0' as the next argument to the expression above.
                                     reflection_uninstall_actors/0,
                                     % Continue the multi-line expression started above.
                                     reflection_motivation_cycle/0, reflection_exploration_cycle/0,
                                     % Continue the multi-line expression started above.
                                     reflection_meta_control_cycle/0, reflection_regulation_cycle/0,
                                     % Continue the multi-line expression started above.
                                     reflection_impasse_cycle/0]).

% Execute the compile-time directive: begin_tests(pr13, [setup(pr13_setup), cleanup(pr13_cleanup)]).
:- begin_tests(pr13, [setup(pr13_setup), cleanup(pr13_cleanup)]).

% Execute: pr13_setup :-.
pr13_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr13', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr13_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr13_cleanup :-.
pr13_cleanup :-
    % Call the goal 'reflection_uninstall_actors'.
    reflection_uninstall_actors,
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr13_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% State a fact for 'reflection actor names' with the arguments listed below.
reflection_actor_names([
    % Continue the multi-line expression started above.
    motivation_actor, daydream_actor, regulation_actor,
    % Continue the multi-line expression started above.
    coping_actor, exploration_actor, imitation_actor,
    % Continue the multi-line expression started above.
    play_actor, meta_control_actor, gating_actor, impasse_actor
% Close the expression opened above.
]).

%  AC-PR13-001
% Define a clause for 'test': succeed when the following conditions hold.
test(install_starts_all_cyclic_actors) :-
    % Call the goal 'reflection_install_actors'.
    reflection_install_actors,
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Running),
    % State a fact for 'reflection actor names' with the arguments listed below.
    reflection_actor_names(Expected),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Name, Expected),
        % Continue the multi-line expression started above.
        memberchk(Name, Running)
    % Close the expression opened above.
    ).

%  AC-PR13-002
% Define a clause for 'test': succeed when the following conditions hold.
test(uninstall_stops_all_cyclic_actors) :-
    % Call the goal 'reflection_install_actors'.
    reflection_install_actors,
    % Call the goal 'reflection_uninstall_actors'.
    reflection_uninstall_actors,
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Running),
    % State a fact for 'reflection actor names' with the arguments listed below.
    reflection_actor_names(Expected),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Name, Expected),
        % Continue the multi-line expression started above.
        \+ memberchk(Name, Running)
    % Close the expression opened above.
    ).

%  AC-PR13-003
% Define a clause for 'test': succeed when the following conditions hold.
test(motivation_cycle_inscribes_objective) :-
    % Enroll a body with a need and provide an interoceptive signal
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://test-body', [need(battery, 80.0, percent)], []),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept_signal,
                % Continue the multi-line expression started above.
                ['herald://test-body',
                 % Continue the multi-line expression started above.
                 interoceptive_signal(battery, 60.0, T)],
                % Continue the multi-line expression started above.
                ['channel://motivation'],
                % Supply '_' as the next argument to the expression above.
                _),
    % Call the goal 'reflection_motivation_cycle'.
    reflection_motivation_cycle,
    % Check that an objective node_fact was inscribed
    % Execute: node_facts:lattice_node_fact(Nx, _, objective, [battery|_], _)..
    node_facts:lattice_node_fact(Nx, _, objective, [battery|_], _).

%  AC-PR13-004
% Define a clause for 'test': succeed when the following conditions hold.
test(exploration_cycle_inscribes_explore_objective) :-
    % Call the goal 'reflection_exploration_cycle'.
    reflection_exploration_cycle,
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State the fact: once(node_facts:lattice_node_fact(Nx, _, explore_objective, _, _)).
    once(node_facts:lattice_node_fact(Nx, _, explore_objective, _, _)).

%  AC-PR13-005
% Define a clause for 'test': succeed when the following conditions hold.
test(meta_control_cycle_runs) :-
    % State the zero-argument fact 'reflection_meta_control_cycle'.
    reflection_meta_control_cycle.

%  AC-PR13-006
% Define a clause for 'test': succeed when the following conditions hold.
test(regulation_cycle_classifies_outcome) :-
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % Inscribe a body_command and a matching proprioceptive result
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(body_command, ['herald://robot', cmd_99, test_cmd], [], _),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept_signal,
                % Continue the multi-line expression started above.
                ['herald://robot',
                 % Continue the multi-line expression started above.
                 proprioceptive_signal(cmd_99, true, [], T)],
                % Continue the multi-line expression started above.
                ['channel://regulation'],
                % Supply '_' as the next argument to the expression above.
                _),
    % Call the goal 'reflection_regulation_cycle'.
    reflection_regulation_cycle,
    % Execute: node_facts:lattice_node_fact(Nx, _, regulation_outcome, [cmd_99, confirmation], [])..
    node_facts:lattice_node_fact(Nx, _, regulation_outcome, [cmd_99, confirmation], []).

%  AC-PR13-007
% Define a clause for 'test': succeed when the following conditions hold.
test(compensation_sentinel_registered) :-
    % Call the goal 'reflection_install_actors'.
    reflection_install_actors,
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinels_list(compensation_actor, L),
    % Check that 'L' is not unifiable with '[]'.
    L \= [].

%  AC-PR13-008
% Define a clause for 'test': succeed when the following conditions hold.
test(discovery_sentinel_registered) :-
    % Call the goal 'reflection_install_actors'.
    reflection_install_actors,
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinels_list(discovery_actor, L),
    % Check that 'L' is not unifiable with '[]'.
    L \= [].

%  AC-PR13-009
% Define a clause for 'test': succeed when the following conditions hold.
test(impasse_cycle_inscribes_subgoal) :-
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(objective, [need_battery, reduce_delta], [], _),
    % Call the goal 'reflection_impasse_cycle'.
    reflection_impasse_cycle,
    % State the fact: once(node_facts:lattice_node_fact(Nx, _, subgoal, [impasse_resolution|_], _)).
    once(node_facts:lattice_node_fact(Nx, _, subgoal, [impasse_resolution|_], _)).

% Execute the compile-time directive: end_tests(pr13).
:- end_tests(pr13).
