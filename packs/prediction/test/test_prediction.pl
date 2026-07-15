/*  PrologAI — Prediction and Active Inference Pack Test Suite  (PR 19)

    In-pack PLUnit acceptance tests for the six exported predicates:
      prediction_generate_prediction/3, prediction_prediction_residual/3,
      prediction_precision/2, prediction_minimize_free_energy/1,
      prediction_infer_state/2, prediction_route_disturbance/1.

    The suite opens a live Lattice nexus, routes anchored facts to it, and
    asserts on the real predicate outputs: the default precision weight, the
    generative model lookup and its no-change fallback, the precision-weighted
    residual for a matching and a mismatching observation, the inferred-state
    shape, the dark-room curiosity prior, and the routed disturbance node_fact.

    Run with:
        swipl -g "run_tests, halt" test_prediction.pl
*/

% Declare this test file as a private module that exports nothing.
:- module(test_prediction, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the prediction pack under test and its six public predicates.
:- use_module(library(prediction), [ prediction_generate_prediction/3, prediction_prediction_residual/3, prediction_precision/2, prediction_minimize_free_energy/1, prediction_infer_state/2, prediction_route_disturbance/1 ]).

% Load the Lattice store so the suite can open, inspect, and close a nexus.
:- use_module(library(lattice), [ lattice_open/2, lattice_close/1, lattice_node_fact/5 ]).

% Load the node_facts helpers that anchor facts and pick the default nexus.
:- use_module(library(node_facts), [ set_default_nexus/1, anchor_node/4 ]).

% Open a fresh Lattice nexus, route anchored facts to it, and clear pack state.
prediction_test_setup :-
    % Open a test-only Lattice nexus at a local address.
    lattice_open('locus://localhost/test_prediction', Nexus),
    % Remember the opened nexus handle for later cleanup and lookups.
    nb_setval(prediction_test_nexus, Nexus),
    % Route every anchor_node write from the pack to this nexus.
    set_default_nexus(Nexus),
    % Clear any channel precision weights left over from an earlier run.
    retractall(prediction:channel_precision(_, _)),
    % Clear any recorded channel error history.
    retractall(prediction:channel_error_history(_, _, _)),
    % Clear any learned generative-model entries.
    retractall(prediction:prediction_model(_, _, _, _)).

% Release the nexus that setup opened and clear the pack's dynamic state.
prediction_test_cleanup :-
    % Recall the nexus handle stored during setup.
    nb_getval(prediction_test_nexus, Nexus),
    % Drop the channel precision weights created during the suite.
    retractall(prediction:channel_precision(_, _)),
    % Drop the channel error history created during the suite.
    retractall(prediction:channel_error_history(_, _, _)),
    % Drop the generative-model entries created during the suite.
    retractall(prediction:prediction_model(_, _, _, _)),
    % Release the nexus and the facts it holds.
    lattice_close(Nexus).

% Open the suite with a shared nexus setup and matching teardown.
:- begin_tests(prediction, [setup(prediction_test_setup), cleanup(prediction_test_cleanup)]).

% A brand-new channel with no stored weight reports the default precision (0.8).
test(default_precision_for_new_channel) :-
    % Query the precision of a channel that has never been adapted.
    prediction_precision(fresh_channel_alpha, P),
    % The default precision weight is 0.8.
    assertion(P =:= 0.8).

% A stored generative-model entry is returned verbatim as the prediction.
test(generate_prediction_uses_stored_model) :-
    % Teach the model that on channel vision, scene_a contains a ball.
    assertz(prediction:prediction_model(vision, scene_a, contains, [ball])),
    % Ask for the downward prediction for that channel and situation.
    prediction_generate_prediction(vision, scene_a, Pred),
    % The prediction must echo the stored relation and arguments.
    assertion(Pred = prediction(vision, scene_a, contains, [ball])).

% With no model and no matching Lattice fact, the prediction falls back to unknown.
test(generate_prediction_falls_back_to_unknown) :-
    % Ask for a prediction on a channel and situation the model has never seen.
    prediction_generate_prediction(audio, novel_situation_zzz, Pred),
    % The no-change prior is an unknown relation with empty arguments.
    assertion(Pred = prediction(audio, novel_situation_zzz, unknown, [])).

% An observation that matches the model's predicted relation yields zero residual.
test(residual_zero_when_observation_matches_model) :-
    % Teach the model that on channel match_ch the expected relation is seen.
    assertz(prediction:prediction_model(match_ch, unknown, seen, [x])),
    % Observe a node_fact whose relation matches the prediction.
    prediction_prediction_residual(match_ch, [node_fact(seen, [y], [])], R),
    % A matching observation carries no prediction error.
    assertion(R =:= 0.0).

% A mismatching observation yields a residual equal to the channel precision.
test(residual_scales_with_precision_on_mismatch) :-
    % Teach the model that on channel miss_ch the expected relation is seen.
    assertz(prediction:prediction_model(miss_ch, unknown, seen, [x])),
    % Read the channel's precision weight before any adaptation runs.
    prediction_precision(miss_ch, P0),
    % Observe a node_fact whose relation does not match the prediction.
    prediction_prediction_residual(miss_ch, [node_fact(other_rel, [y], [])], R),
    % The precision-weighted residual is precision times a unit mismatch error.
    assertion(R =:= P0).

% Inferring state over an open nexus returns a state/2 abstraction term.
test(infer_state_returns_state_term) :-
    % Recall the open nexus handle for this suite.
    nb_getval(prediction_test_nexus, Nexus),
    % Anchor a node_fact so the nexus is not empty.
    anchor_node(landmark, [tower], [], _),
    % Perceive: infer the current abstract state from the nexus.
    prediction_infer_state(Nexus, State),
    % The inferred state is always a state(Relation, Args) term.
    assertion(State = state(_, _)).

% One free-energy minimization step records the dark-room curiosity prior.
test(minimize_free_energy_records_curiosity_prior) :-
    % Recall the open nexus handle for this suite.
    nb_getval(prediction_test_nexus, Nexus),
    % Run one perception-and-routing free-energy minimization step.
    prediction_minimize_free_energy(some_situation),
    % The dark-room guard must have anchored an active curiosity_prior fact.
    assertion(lattice_node_fact(Nexus, _, curiosity_prior, [active], _)).

% Routing a disturbance anchors a prediction_disturbance node_fact in the nexus.
test(route_disturbance_anchors_disturbance_fact) :-
    % Recall the open nexus handle for this suite.
    nb_getval(prediction_test_nexus, Nexus),
    % Route a large unresolved error to the regulation and compensation actors.
    prediction_route_disturbance(disturbance(test, situation_q, 0.9)),
    % The routed disturbance must appear as a prediction_disturbance fact.
    assertion(lattice_node_fact(Nexus, _, prediction_disturbance, _, _)).

% Close the prediction test suite.
:- end_tests(prediction).
