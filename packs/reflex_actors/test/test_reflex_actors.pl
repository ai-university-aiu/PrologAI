/*  PrologAI — Reflex Actors Test Suite  (WP-13, Reflection Pattern)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/reflex_actors/test/test_reflex_actors.pl

    Exercises the pure cycle-body predicates of the reflex_actors pack directly,
    without starting the live scheduler threads (install/uninstall spawn real
    cyclic-actor threads and are deliberately left out of the in-pack regression):
      reflex_actors_motivation_cycle/0   — homeostatic delta -> objective
      reflex_actors_regulation_cycle/0    — proprioceptive result -> regulation_outcome
      reflex_actors_impasse_cycle/0       — planless objective -> subgoal
      reflex_actors_exploration_cycle/0   — spontaneous explore_objective
      reflex_actors_meta_control_cycle/0  — actor-health scan runs clean
      reflex_actors_gating_cycle/0        — objective gating scan runs clean
*/

% Declare this file as a test module exporting nothing.
:- module(test_reflex_actors, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load lattice open/close so tests can stand up a private nexus.
:- use_module(library(lattice),     [lattice_open/2, lattice_close/1]).
% Load node_facts helpers for setting the default nexus, anchoring, and reading facts.
:- use_module(library(node_facts),  [set_default_nexus/1, anchor_node/4, default_nexus/1]).
% Load the body manifest helper used to enroll a test body with a need.
:- use_module(library(mind_body),   [manifest_body/3]).
% Load the module under test — the reflex-actor cycle bodies.
:- use_module(library(reflex_actors), [reflex_actors_motivation_cycle/0,
                                       % Continue the import list started above.
                                       reflex_actors_regulation_cycle/0,
                                       % Continue the import list started above.
                                       reflex_actors_impasse_cycle/0,
                                       % Continue the import list started above.
                                       reflex_actors_exploration_cycle/0,
                                       % Continue the import list started above.
                                       reflex_actors_meta_control_cycle/0,
                                       % Close the import list started above.
                                       reflex_actors_gating_cycle/0]).

% Open the test block, standing up a fresh nexus before and tearing it down after.
:- begin_tests(reflex_actors, [setup(test_reflex_actors_setup),
                               % Close the options list with the cleanup hook.
                               cleanup(test_reflex_actors_cleanup)]).

% Setup: open a private lattice nexus and make it the default for the cycle bodies.
test_reflex_actors_setup :-
    % Open a fresh nexus at a test-only locus.
    lattice_open('locus://localhost/test_reflex_actors', N),
    % Remember the nexus reference so cleanup can close it.
    nb_setval(test_reflex_actors_nexus, N),
    % Make this nexus the default that every cycle body reads and writes.
    set_default_nexus(N).

% Cleanup: recover the remembered nexus and close it.
test_reflex_actors_cleanup :-
    % Fetch the nexus reference stashed during setup.
    nb_getval(test_reflex_actors_nexus, N),
    % Close the nexus, releasing its store.
    lattice_close(N).

% A homeostatic delta above threshold makes motivation inscribe a battery objective.
test(motivation_cycle_inscribes_objective) :-
    % Enroll a test body carrying a battery need with an 80 percent target.
    manifest_body('herald://test_reflex_actors_body', [need(battery, 80.0, percent)], []),
    % Grab the default nexus so we can inspect it afterwards.
    default_nexus(Nx),
    % Read a timestamp for the interoceptive signal.
    get_time(T),
    % Publish an interoceptive battery reading of 60 percent, twenty below target.
    anchor_node(percept_signal,
                % The signal names the body and the actual battery level.
                ['herald://test_reflex_actors_body', interoceptive_signal(battery, 60.0, T)],
                % Publish it onto the motivation channel.
                ['channel://motivation'],
                % Discard the returned node id.
                _),
    % Run the motivation cycle body once.
    reflex_actors_motivation_cycle,
    % Assert that a battery objective node_fact was inscribed by the cycle.
    assertion(node_facts:lattice_node_fact(Nx, _, objective, [battery|_], _)).

% A confirmed proprioceptive result makes regulation classify the outcome as confirmation.
test(regulation_cycle_classifies_confirmation) :-
    % Grab the default nexus for later inspection.
    default_nexus(Nx),
    % Record the original body command whose outcome we will confirm.
    anchor_node(body_command, ['herald://test_reflex_actors_robot', cmd_regtest, do_thing], [], _),
    % Read a timestamp for the proprioceptive result.
    get_time(T),
    % Publish a successful proprioceptive result for that command.
    anchor_node(percept_signal,
                % The result names the command id and a success flag of true.
                ['herald://test_reflex_actors_robot', proprioceptive_signal(cmd_regtest, true, [], T)],
                % Publish it onto the regulation channel.
                ['channel://regulation'],
                % Discard the returned node id.
                _),
    % Run the regulation cycle body once.
    reflex_actors_regulation_cycle,
    % Assert the outcome was classified as a confirmation for that command.
    assertion(node_facts:lattice_node_fact(Nx, _, regulation_outcome, [cmd_regtest, confirmation], [])).

% An objective with no matching plan makes the impasse cycle inscribe a subgoal.
test(impasse_cycle_inscribes_subgoal) :-
    % Grab the default nexus for later inspection.
    default_nexus(Nx),
    % Inscribe an objective for which no causal_plan exists (a dead end).
    anchor_node(objective, [need_regtest, reduce_delta], [], _),
    % Run the impasse cycle body once.
    reflex_actors_impasse_cycle,
    % Assert an impasse-resolution subgoal was inscribed for the planless objective.
    assertion(once(node_facts:lattice_node_fact(Nx, _, subgoal, [impasse_resolution|_], _))).

% The exploration cycle spontaneously inscribes an explore_objective on an open nexus.
test(exploration_cycle_inscribes_explore_objective) :-
    % Run the exploration cycle body once.
    reflex_actors_exploration_cycle,
    % Grab the default nexus for inspection.
    default_nexus(Nx),
    % Assert a spontaneous explore_objective node_fact was inscribed.
    assertion(once(node_facts:lattice_node_fact(Nx, _, explore_objective, _, _))).

% The meta-control cycle scans actor health and completes without error on a fresh nexus.
test(meta_control_cycle_runs_clean) :-
    % Assert the meta-control cycle body succeeds deterministically.
    assertion(reflex_actors_meta_control_cycle).

% The gating cycle scans objectives for readiness and completes without error.
test(gating_cycle_runs_clean) :-
    % Seed one objective so the gating scan has something to iterate over.
    anchor_node(objective, [need_gatetest, reduce_delta], [], _),
    % Assert the gating cycle body succeeds deterministically.
    assertion(reflex_actors_gating_cycle).

% Close the test block.
:- end_tests(reflex_actors).
