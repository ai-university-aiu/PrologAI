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

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/mindbody/prolog'],       MindBodyPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, MindBodyPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts),[set_default_nexus/1, default_nexus/1,
                                   traverse_nexus/4]).
:- use_module(library(mindbody),  [manifest_body/3, body_vitals/2,
                                   relay_percept/2, dispatch_command/2,
                                   body_enrolled/1]).

:- begin_tests(pr10, [setup(pr10_setup), cleanup(pr10_cleanup)]).

pr10_setup :-
    lattice_open('locus://localhost/pr10', N),
    nb_setval(pr10_nexus_ref, N),
    set_default_nexus(N).

pr10_cleanup :-
    nb_getval(pr10_nexus_ref, N),
    lattice_close(N).

%  AC-PR10-001
test(body_enrollment_succeeds) :-
    manifest_body('herald://robot-01',
                  [need(battery_level, 80.0, percent)],
                  [capability(move_forward, [param(distance, float, true)])]),
    body_vitals('herald://robot-01', vitals('herald://robot-01', _, _)).

%  AC-PR10-002
test(body_vitals_needs_correct) :-
    manifest_body('herald://robot-02',
                  [need(battery_level, 80.0, percent),
                   need(temperature, 37.0, celsius)],
                  []),
    body_vitals('herald://robot-02', vitals(_, Needs, _)),
    memberchk(need(battery_level, 80.0, percent), Needs),
    memberchk(need(temperature, 37.0, celsius), Needs).

%  AC-PR10-003
test(body_vitals_capabilities_correct) :-
    manifest_body('herald://robot-03',
                  [],
                  [capability(move_forward, [param(distance, float, true)]),
                   capability(turn_left, [])]),
    body_vitals('herald://robot-03', vitals(_, _, Caps)),
    memberchk(capability(move_forward, _), Caps),
    memberchk(capability(turn_left, []), Caps).

%  AC-PR10-004
test(relay_perception_signal_anchors_node_fact) :-
    manifest_body('herald://sensor-01', [], []),
    get_time(T),
    relay_percept('herald://sensor-01',
                  perception_signal(visual, frame(42), T)),
    default_nexus(Nx),
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://sensor-01', _], _), 10, Results),
    Results \= [].

%  AC-PR10-005
test(relay_interoceptive_signal_anchors_node_fact) :-
    manifest_body('herald://sensor-02', [need(battery_level, 80.0, percent)], []),
    get_time(T),
    relay_percept('herald://sensor-02',
                  interoceptive_signal(battery_level, 72.3, T)),
    default_nexus(Nx),
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://sensor-02', _], _), 10, Results),
    Results \= [].

%  AC-PR10-006
test(relay_proprioceptive_signal_anchors_node_fact) :-
    manifest_body('herald://robot-04', [], [capability(move_forward, [])]),
    get_time(T),
    relay_percept('herald://robot-04',
                  proprioceptive_signal(cmd_123, true, [], T)),
    default_nexus(Nx),
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://robot-04', _], _), 10, Results),
    Results \= [].

%  AC-PR10-007
test(dispatch_command_records_node_fact) :-
    manifest_body('herald://robot-05', [], [capability(move_forward, [])]),
    dispatch_command('herald://robot-05', move_forward(1.0)),
    default_nexus(Nx),
    traverse_nexus(Nx, node_fact(body_command, ['herald://robot-05'|_], _), 10, Results),
    Results \= [].

%  AC-PR10-008
test(re_enrollment_updates_registration) :-
    manifest_body('herald://robot-06',
                  [need(battery_level, 80.0, percent)], []),
    manifest_body('herald://robot-06',
                  [need(battery_level, 90.0, percent)], [capability(stop, [])]),
    body_vitals('herald://robot-06', vitals(_, Needs2, Caps2)),
    memberchk(need(battery_level, 90.0, percent), Needs2),
    memberchk(capability(stop, []), Caps2).

%  AC-PR10-009
test(body_enrolled_query) :-
    manifest_body('herald://robot-07', [], []),
    body_enrolled('herald://robot-07'),
    \+ body_enrolled('herald://unknown-99').

:- end_tests(pr10).
