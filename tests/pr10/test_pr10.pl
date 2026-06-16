/*  PrologAI — PR 10 Mind-Body Interface Acceptance Tests

    AC-PR10-001: manifest_body then body_vitals returns enrolled body with
                 correct needs and capabilities.
    AC-PR10-002: body_vitals/2 returns the correct needs list.
    AC-PR10-003: body_vitals/2 returns the correct capabilities list.
    AC-PR10-004: relay_percept with perception_signal stores percept node_fact.
    AC-PR10-005: relay_percept with interoceptive_signal stores percept node_fact.
    AC-PR10-006: relay_percept with proprioceptive_signal stores percept node_fact.
    AC-PR10-007: dispatch_command records command as Lattice node_fact.
    AC-PR10-008: Re-enrolling the same address updates the registration.
    AC-PR10-009: body_enrolled/1 succeeds for enrolled body, fails for unknown.
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
   atomic_list_concat([ProjectRoot, '/packs/mindbody/prolog'],       MindBodyPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, MindBodyPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),[set_default_nexus/1, default_nexus/1,
                                   % Continue the multi-line expression started above.
                                   traverse_nexus/4]).
% Load the built-in 'mindbody' library so its predicates are available here.
:- use_module(library(mindbody),  [manifest_body/3, body_vitals/2,
                                   % Continue the multi-line expression started above.
                                   relay_percept/2, dispatch_command/2,
                                   % Continue the multi-line expression started above.
                                   body_enrolled/1]).

% Execute the compile-time directive: begin_tests(pr10, [setup(pr10_setup), cleanup(pr10_cleanup)]).
:- begin_tests(pr10, [setup(pr10_setup), cleanup(pr10_cleanup)]).

% Execute: pr10_setup :-.
pr10_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr10', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr10_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr10_cleanup :-.
pr10_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr10_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR10-001
% Define a clause for 'test': succeed when the following conditions hold.
test(body_enrollment_succeeds) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-01',
                  % Continue the multi-line expression started above.
                  [need(battery_level, 80.0, percent)],
                  % Continue the multi-line expression started above.
                  [capability(move_forward, [param(distance, float, true)])]),
    % State the fact: body vitals('herald://robot-01', vitals('herald://robot-01', _, _)).
    body_vitals('herald://robot-01', vitals('herald://robot-01', _, _)).

%  AC-PR10-002
% Define a clause for 'test': succeed when the following conditions hold.
test(body_vitals_needs_correct) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-02',
                  % Continue the multi-line expression started above.
                  [need(battery_level, 80.0, percent),
                   % Continue the multi-line expression started above.
                   need(temperature, 37.0, celsius)],
                  % Continue the multi-line expression started above.
                  []),
    % State a fact for 'body vitals' with the arguments listed below.
    body_vitals('herald://robot-02', vitals(_, Needs, _)),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(need(battery_level, 80.0, percent), Needs),
    % State the fact: memberchk(need(temperature, 37.0, celsius), Needs).
    memberchk(need(temperature, 37.0, celsius), Needs).

%  AC-PR10-003
% Define a clause for 'test': succeed when the following conditions hold.
test(body_vitals_capabilities_correct) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-03',
                  % Continue the multi-line expression started above.
                  [],
                  % Continue the multi-line expression started above.
                  [capability(move_forward, [param(distance, float, true)]),
                   % Continue the multi-line expression started above.
                   capability(turn_left, [])]),
    % State a fact for 'body vitals' with the arguments listed below.
    body_vitals('herald://robot-03', vitals(_, _, Caps)),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(capability(move_forward, _), Caps),
    % State the fact: memberchk(capability(turn_left, []), Caps).
    memberchk(capability(turn_left, []), Caps).

%  AC-PR10-004
% Define a clause for 'test': succeed when the following conditions hold.
test(relay_perception_signal_anchors_node_fact) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://sensor-01', [], []),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'relay percept' with the arguments listed below.
    relay_percept('herald://sensor-01',
                  % Continue the multi-line expression started above.
                  perception_signal(visual, frame(42), T)),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://sensor-01', _], _), 10, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR10-005
% Define a clause for 'test': succeed when the following conditions hold.
test(relay_interoceptive_signal_anchors_node_fact) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://sensor-02', [need(battery_level, 80.0, percent)], []),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'relay percept' with the arguments listed below.
    relay_percept('herald://sensor-02',
                  % Continue the multi-line expression started above.
                  interoceptive_signal(battery_level, 72.3, T)),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://sensor-02', _], _), 10, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR10-006
% Define a clause for 'test': succeed when the following conditions hold.
test(relay_proprioceptive_signal_anchors_node_fact) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-04', [], [capability(move_forward, [])]),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % State a fact for 'relay percept' with the arguments listed below.
    relay_percept('herald://robot-04',
                  % Continue the multi-line expression started above.
                  proprioceptive_signal(cmd_123, true, [], T)),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://robot-04', _], _), 10, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR10-007
% Define a clause for 'test': succeed when the following conditions hold.
test(dispatch_command_records_node_fact) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-05', [], [capability(move_forward, [])]),
    % State a fact for 'dispatch command' with the arguments listed below.
    dispatch_command('herald://robot-05', move_forward(1.0)),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nx),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nx, node_fact(body_command, ['herald://robot-05'|_], _), 10, Results),
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR10-008
% Define a clause for 'test': succeed when the following conditions hold.
test(re_enrollment_updates_registration) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-06',
                  % Continue the multi-line expression started above.
                  [need(battery_level, 80.0, percent)], []),
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-06',
                  % Continue the multi-line expression started above.
                  [need(battery_level, 90.0, percent)], [capability(stop, [])]),
    % State a fact for 'body vitals' with the arguments listed below.
    body_vitals('herald://robot-06', vitals(_, Needs2, Caps2)),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(need(battery_level, 90.0, percent), Needs2),
    % State the fact: memberchk(capability(stop, []), Caps2).
    memberchk(capability(stop, []), Caps2).

%  AC-PR10-009
% Define a clause for 'test': succeed when the following conditions hold.
test(body_enrolled_query) :-
    % State a fact for 'manifest body' with the arguments listed below.
    manifest_body('herald://robot-07', [], []),
    % State a fact for 'body enrolled' with the arguments listed below.
    body_enrolled('herald://robot-07'),
    % Succeed only if 'body_enrolled('herald://unknown-99'' cannot be proved (negation as failure).
    \+ body_enrolled('herald://unknown-99').

% Execute the compile-time directive: end_tests(pr10).
:- end_tests(pr10).
