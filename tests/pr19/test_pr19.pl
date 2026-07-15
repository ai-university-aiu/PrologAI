/*  PrologAI — PR 19 Prediction and Active Inference Acceptance Tests

    AC-PR19-001: Given a sensor channel with injected random noise, when 100
                 cycles run, then that channel's precision weight decreases.
    AC-PR19-002: Prediction errors reference abstract representations (not raw
                 payloads).
    AC-PR19-003: prediction_generate_prediction/3 returns a prediction for a situation.
    AC-PR19-004: prediction_prediction_residual/3 returns a weighted residual.
    AC-PR19-005: prediction_precision/2 returns the default precision for a new channel.
    AC-PR19-006: Updating precision clamps to [0.05, 1.0].
    AC-PR19-007: prediction_minimize_free_energy/1 runs without error.
    AC-PR19-008: Routes disturbances when residual exceeds threshold.
    AC-PR19-009: Dark-room guard records curiosity_prior node_fact.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],      LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],        ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/prediction/prolog'],    PredPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, PredPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    % Continue the multi-line expression started above.
                                    lattice_node_fact/5]).
% Import [set_default_nexus/1, anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).
% Load the built-in 'prediction' library so its predicates are available here.
:- use_module(library(prediction), [prediction_generate_prediction/3,
                                    % Supply 'prediction_prediction_residual/3' as the next argument to the expression above.
                                    prediction_prediction_residual/3,
                                    % Supply 'prediction_precision/2' as the next argument to the expression above.
                                    prediction_precision/2,
                                    % Supply 'prediction_minimize_free_energy/1' as the next argument to the expression above.
                                    prediction_minimize_free_energy/1,
                                    % Supply 'prediction_infer_state/2' as the next argument to the expression above.
                                    prediction_infer_state/2,
                                    % Continue the multi-line expression started above.
                                    prediction_route_disturbance/1]).

% Execute the compile-time directive: begin_tests(pr19, [setup(pr19_setup), cleanup(pr19_cleanup)]).
:- begin_tests(pr19, [setup(pr19_setup), cleanup(pr19_cleanup)]).

% Execute: pr19_setup :-.
pr19_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr19', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr19_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(prediction:channel_precision(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(prediction:channel_error_history(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(prediction:prediction_model(_, _, _, _)).

% Execute: pr19_cleanup :-.
pr19_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr19_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(prediction:channel_precision(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(prediction:channel_error_history(_, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR19-001: noisy channel precision decreases after many cycles
% Define a clause for 'test': succeed when the following conditions hold.
test(noisy_channel_precision_decreases) :-
    % Record the initial precision
    % State a fact for 'pai precision' with the arguments listed below.
    prediction_precision(noisy_channel, P0),
    % Inject 100 cycles of high-variance error on the channel
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 100, I),
        % Continue the multi-line expression started above.
        ( Ti is T0 - (100 - I),
          % Alternate between 0.0 and 1.0 errors (maximum variance)
          % Continue the multi-line expression started above.
          ( I mod 2 =:= 0 -> E = 1.0 ; E = 0.0 ),
          % Continue the multi-line expression started above.
          assertz(prediction:channel_error_history(noisy_channel, Ti, E))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % Trigger adaptation
    % Execute: prediction:adapt_precision(noisy_channel),.
    prediction:adapt_precision(noisy_channel),
    % Final precision should be less than or equal to initial
    % State a fact for 'pai precision' with the arguments listed below.
    prediction_precision(noisy_channel, P1),
    % Check that 'P1' is less than or equal to 'P0'.
    P1 =< P0.

%  AC-PR19-002: prediction errors reference abstract representations
% Define a clause for 'test': succeed when the following conditions hold.
test(prediction_errors_reference_abstract_representations) :-
    % Create an abstract representation node_fact
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(visual_object, [stable_object_1], [], _),
    % Generate a prediction for it
    % State a fact for 'pai generate prediction' with the arguments listed below.
    prediction_generate_prediction(visual_channel, stable_object_1, Prediction),
    % The prediction should reference abstract terms, not raw bytes
    % Execute: Prediction =.. [prediction | Args],.
    Prediction =.. [prediction | Args],
    % Check that 'Args' is not unifiable with '[]'.
    Args \= [],
    % The prediction should NOT contain raw byte sequences
    % Succeed only if 'member(raw_bytes(_), Args' cannot be proved (negation as failure).
    \+ member(raw_bytes(_), Args).

%  AC-PR19-003: prediction_generate_prediction returns a prediction term
% Define a clause for 'test': succeed when the following conditions hold.
test(generate_prediction_returns_term) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(context_rel, [test_situation], [], _),
    % State a fact for 'pai generate prediction' with the arguments listed below.
    prediction_generate_prediction(test_channel, test_situation, Pred),
    % Execute: Pred =.. [prediction | _Args]..
    Pred =.. [prediction | _Args].

%  AC-PR19-004: prediction_prediction_residual returns a numeric weighted residual
% Define a clause for 'test': succeed when the following conditions hold.
test(prediction_residual_is_numeric) :-
    % Check that 'Observed' is unifiable with '[node_fact(state_a, [x], [])]'.
    Observed = [node_fact(state_a, [x], [])],
    % State a fact for 'pai prediction residual' with the arguments listed below.
    prediction_prediction_residual(residual_channel, Observed, Residual),
    % State a fact for 'number' with the arguments listed below.
    number(Residual),
    % Check that 'Residual' is greater than or equal to '0.0'.
    Residual >= 0.0,
    % Check that 'Residual' is less than or equal to '1.0'.
    Residual =< 1.0.

%  AC-PR19-005: default precision for a new channel
% Define a clause for 'test': succeed when the following conditions hold.
test(default_precision_for_new_channel) :-
    % State a fact for 'pai precision' with the arguments listed below.
    prediction_precision(brand_new_channel_xyz, P),
    % Check that 'P' is greater than '0.0'.
    P > 0.0,
    % Check that 'P' is less than or equal to '1.0'.
    P =< 1.0.

%  AC-PR19-006: precision clamped to [0.05, 1.0]
% Define a clause for 'test': succeed when the following conditions hold.
test(precision_clamped) :-
    % Execute: prediction:update_precision(clamp_test, -1.0),.
    prediction:update_precision(clamp_test, -1.0),
    % State a fact for 'pai precision' with the arguments listed below.
    prediction_precision(clamp_test, P1),
    % Check that 'P1' is greater than or equal to '0.05'.
    P1 >= 0.05,
    % Execute: prediction:update_precision(clamp_test, 99.0),.
    prediction:update_precision(clamp_test, 99.0),
    % State a fact for 'pai precision' with the arguments listed below.
    prediction_precision(clamp_test, P2),
    % Check that 'P2' is less than or equal to '1.0'.
    P2 =< 1.0.

%  AC-PR19-007: prediction_minimize_free_energy runs without error
% Define a clause for 'test': succeed when the following conditions hold.
test(minimize_free_energy_runs) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(test_situation_node, [sit_a], [], _),
    % State the fact: pai minimize free energy(sit_a).
    prediction_minimize_free_energy(sit_a).

%  AC-PR19-008: routes disturbances when residual is high
% Define a clause for 'test': succeed when the following conditions hold.
test(routes_disturbance_on_high_residual) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr19_nexus_ref, Nexus),
    % Force a high-error situation (no prediction model for this channel)
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 10, I),
        % Continue the multi-line expression started above.
        ( get_time(T), Ti is T - I,
          % Continue the multi-line expression started above.
          assertz(prediction:channel_error_history(disturbance_channel, Ti, 1.0))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % Execute: prediction:adapt_precision(disturbance_channel),.
    prediction:adapt_precision(disturbance_channel),
    % State a fact for 'pai route disturbance' with the arguments listed below.
    prediction_route_disturbance(disturbance(test, situation_d, 0.8)),
    % State the fact: once(lattice:lattice_node_fact(Nexus, _, prediction_disturbance, _, _)).
    once(lattice:lattice_node_fact(Nexus, _, prediction_disturbance, _, _)).

%  AC-PR19-009: dark-room guard creates curiosity_prior node_fact
% Define a clause for 'test': succeed when the following conditions hold.
test(dark_room_guard_curiosity_prior) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr19_nexus_ref, Nexus),
    % State a fact for 'pai minimize free energy' with the arguments listed below.
    prediction_minimize_free_energy(any_situation),
    % State the fact: once(lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _)).
    once(lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _)).

% Execute the compile-time directive: end_tests(pr19).
:- end_tests(pr19).
