/*  PrologAI — Mind-Body Interface  in-pack PLUnit suite  (WP-mind_body)

    Exercises the core exported predicates of the mind_body pack against a
    freshly opened Lattice nexus:
      manifest_body/3              — enroll a body and record its vitals
      body_vitals/2                — read back needs and capabilities
      relay_percept/2              — anchor an incoming sensory percept
      mind_body_dispatch_command/2 — dispatch a command and resolve it
      body_enrolled/1              — query whether an address is enrolled

    Run with:
      swipl -p library=... -g "run_tests, halt" test_mind_body.pl
*/

% Declare this file as the 'test_mind_body' module exporting nothing.
:- module(test_mind_body, []).
% Load the built-in 'plunit' library so its test predicates are available here.
:- use_module(library(plunit)).
% Load the 'lattice' library so a nexus can be opened and closed for the tests.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Load the 'node_facts' library so the default nexus can be set and traversed.
:- use_module(library(node_facts),  [set_default_nexus/1, default_nexus/1,
                                    % Continue the multi-line import list started above.
                                     traverse_nexus/4]).
% Load the 'mind_body' library — the pack under test.
:- use_module(library(mind_body),   [manifest_body/3, body_vitals/2,
                                    % Continue the multi-line import list started above.
                                     relay_percept/2, mind_body_dispatch_command/2,
                                    % Continue the multi-line import list started above.
                                     body_enrolled/1]).

% Open the test group 'mind_body' with a nexus setup and a matching cleanup.
:- begin_tests(mind_body, [setup(mind_body_setup), cleanup(mind_body_cleanup)]).

% Define the per-suite setup: open a nexus and make it the default store.
mind_body_setup :-
    % Open an in-memory Lattice nexus for the test run.
    lattice_open('locus://localhost/test_mind_body', N),
    % Stash the nexus reference so cleanup can close the same nexus.
    nb_setval(test_mind_body_nexus_ref, N),
    % Make the opened nexus the default target for anchor_node and traversal.
    set_default_nexus(N).

% Define the per-suite cleanup: close the nexus opened during setup.
mind_body_cleanup :-
    % Retrieve the stashed nexus reference.
    nb_getval(test_mind_body_nexus_ref, N),
    % Close the nexus, releasing its resources.
    lattice_close(N).

% Test: enrolling a body then reading its vitals returns the same address.
test(manifest_then_vitals_returns_address) :-
    % Enroll a robot body with one need and one capability.
    manifest_body('herald://mb-01',
                  % Provide the body's homeostatic needs list.
                  [need(battery_level, 80.0, percent)],
                  % Provide the body's capability list.
                  [capability(move_forward, [param(distance, float, true)])]),
    % Read the vitals back and assert the address round-trips exactly.
    body_vitals('herald://mb-01', vitals('herald://mb-01', _, _)).

% Test: body_vitals returns the exact needs list that was enrolled.
test(vitals_reports_enrolled_needs) :-
    % Enroll a body carrying two distinct homeostatic needs.
    manifest_body('herald://mb-02',
                  % First need: battery level target of eighty percent.
                  [need(battery_level, 80.0, percent),
                   % Second need: temperature target of thirty-seven celsius.
                   need(temperature, 37.0, celsius)],
                  % This body has no declared capabilities.
                  []),
    % Read back the vitals and capture the needs list.
    body_vitals('herald://mb-02', vitals(_, Needs, _)),
    % Assert the battery-level need survived enrollment.
    assertion(memberchk(need(battery_level, 80.0, percent), Needs)),
    % Assert the temperature need survived enrollment.
    assertion(memberchk(need(temperature, 37.0, celsius), Needs)).

% Test: body_vitals returns the exact capabilities list that was enrolled.
test(vitals_reports_enrolled_capabilities) :-
    % Enroll a body with two capabilities and no needs.
    manifest_body('herald://mb-03',
                  % This body declares no homeostatic needs.
                  [],
                  % Capability list: a parameterised move and a plain turn.
                  [capability(move_forward, [param(distance, float, true)]),
                   % Second capability: turning left, taking no parameters.
                   capability(turn_left, [])]),
    % Read back the vitals and capture the capabilities list.
    body_vitals('herald://mb-03', vitals(_, _, Caps)),
    % Assert the move_forward capability is present.
    assertion(memberchk(capability(move_forward, _), Caps)),
    % Assert the turn_left capability is present.
    assertion(memberchk(capability(turn_left, []), Caps)).

% Test: relaying a perception signal anchors a retrievable percept node_fact.
test(relay_percept_anchors_node_fact) :-
    % Enroll a sensor body with no needs and no capabilities.
    manifest_body('herald://mb-04', [], []),
    % Read the wall-clock time for the percept timestamp.
    get_time(T),
    % Relay a visual perception signal from the sensor into the mind.
    relay_percept('herald://mb-04', perception_signal(visual, frame(42), T)),
    % Obtain the default nexus so the stored percept can be traversed.
    default_nexus(Nx),
    % Traverse the nexus for percept_signal node_facts from this address.
    traverse_nexus(Nx, node_fact(percept_signal, ['herald://mb-04', _], _), 10, Results),
    % Assert at least one percept node_fact was anchored.
    assertion(Results \= []).

% Test: dispatching a command records a body_command node_fact and resolves.
test(dispatch_command_records_node_fact) :-
    % Enroll a robot body able to move forward.
    manifest_body('herald://mb-05', [], [capability(move_forward, [])]),
    % Dispatch a move_forward command; every command resolves (timeout-safe).
    mind_body_dispatch_command('herald://mb-05', move_forward(1.0)),
    % Obtain the default nexus so the stored command can be traversed.
    default_nexus(Nx),
    % Traverse the nexus for body_command node_facts from this address.
    traverse_nexus(Nx, node_fact(body_command, ['herald://mb-05'|_], _), 10, Results),
    % Assert the command was recorded as at least one node_fact.
    assertion(Results \= []).

% Test: body_enrolled/1 succeeds for an enrolled address and fails otherwise.
test(body_enrolled_true_and_false) :-
    % Enroll a body so its address becomes known to the registry.
    manifest_body('herald://mb-06', [], []),
    % Assert the enrolled address is reported as enrolled.
    assertion(body_enrolled('herald://mb-06')),
    % Assert an unknown address is not reported as enrolled.
    assertion(\+ body_enrolled('herald://mb-unknown-99')).

% Close the test group 'mind_body'.
:- end_tests(mind_body).
