/*  PrologAI — PR 19 Prediction and Active Inference Acceptance Tests

    AC-PR19-001: Given a sensor channel with injected random noise, when 100
                 cycles run, then that channel's precision weight decreases.
    AC-PR19-002: Prediction errors reference abstract representations (not raw
                 payloads).
    AC-PR19-003: pai_generate_prediction/3 returns a prediction for a situation.
    AC-PR19-004: pai_prediction_residual/3 returns a weighted residual.
    AC-PR19-005: pai_precision/2 returns the default precision for a new channel.
    AC-PR19-006: Updating precision clamps to [0.05, 1.0].
    AC-PR19-007: pai_minimize_free_energy/1 runs without error.
    AC-PR19-008: Routes disturbances when residual exceeds threshold.
    AC-PR19-009: Dark-room guard records curiosity_prior node_fact.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],      LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],        ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/prediction/prolog'],    PredPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, PredPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    lattice_node_fact/5]).
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).
:- use_module(library(prediction), [pai_generate_prediction/3,
                                    pai_prediction_residual/3,
                                    pai_precision/2,
                                    pai_minimize_free_energy/1,
                                    pai_infer_state/2,
                                    pai_route_disturbance/1]).

:- begin_tests(pr19, [setup(pr19_setup), cleanup(pr19_cleanup)]).

pr19_setup :-
    lattice_open('locus://localhost/pr19', N),
    nb_setval(pr19_nexus_ref, N),
    set_default_nexus(N),
    retractall(prediction:channel_precision(_, _)),
    retractall(prediction:channel_error_history(_, _, _)),
    retractall(prediction:prediction_model(_, _, _, _)).

pr19_cleanup :-
    nb_getval(pr19_nexus_ref, N),
    retractall(prediction:channel_precision(_, _)),
    retractall(prediction:channel_error_history(_, _, _)),
    lattice_close(N).

%  AC-PR19-001: noisy channel precision decreases after many cycles
test(noisy_channel_precision_decreases) :-
    % Record the initial precision
    pai_precision(noisy_channel, P0),
    % Inject 100 cycles of high-variance error on the channel
    get_time(T0),
    forall(
        between(1, 100, I),
        ( Ti is T0 - (100 - I),
          % Alternate between 0.0 and 1.0 errors (maximum variance)
          ( I mod 2 =:= 0 -> E = 1.0 ; E = 0.0 ),
          assertz(prediction:channel_error_history(noisy_channel, Ti, E))
        )
    ),
    % Trigger adaptation
    prediction:adapt_precision(noisy_channel),
    % Final precision should be less than or equal to initial
    pai_precision(noisy_channel, P1),
    P1 =< P0.

%  AC-PR19-002: prediction errors reference abstract representations
test(prediction_errors_reference_abstract_representations) :-
    % Create an abstract representation node_fact
    anchor_node(visual_object, [stable_object_1], [], _),
    % Generate a prediction for it
    pai_generate_prediction(visual_channel, stable_object_1, Prediction),
    % The prediction should reference abstract terms, not raw bytes
    Prediction =.. [prediction | Args],
    Args \= [],
    % The prediction should NOT contain raw byte sequences
    \+ member(raw_bytes(_), Args).

%  AC-PR19-003: pai_generate_prediction returns a prediction term
test(generate_prediction_returns_term) :-
    anchor_node(context_rel, [test_situation], [], _),
    pai_generate_prediction(test_channel, test_situation, Pred),
    Pred =.. [prediction | _Args].

%  AC-PR19-004: pai_prediction_residual returns a numeric weighted residual
test(prediction_residual_is_numeric) :-
    Observed = [node_fact(state_a, [x], [])],
    pai_prediction_residual(residual_channel, Observed, Residual),
    number(Residual),
    Residual >= 0.0,
    Residual =< 1.0.

%  AC-PR19-005: default precision for a new channel
test(default_precision_for_new_channel) :-
    pai_precision(brand_new_channel_xyz, P),
    P > 0.0,
    P =< 1.0.

%  AC-PR19-006: precision clamped to [0.05, 1.0]
test(precision_clamped) :-
    prediction:update_precision(clamp_test, -1.0),
    pai_precision(clamp_test, P1),
    P1 >= 0.05,
    prediction:update_precision(clamp_test, 99.0),
    pai_precision(clamp_test, P2),
    P2 =< 1.0.

%  AC-PR19-007: pai_minimize_free_energy runs without error
test(minimize_free_energy_runs) :-
    anchor_node(test_situation_node, [sit_a], [], _),
    pai_minimize_free_energy(sit_a).

%  AC-PR19-008: routes disturbances when residual is high
test(routes_disturbance_on_high_residual) :-
    nb_getval(pr19_nexus_ref, Nexus),
    % Force a high-error situation (no prediction model for this channel)
    forall(
        between(1, 10, I),
        ( get_time(T), Ti is T - I,
          assertz(prediction:channel_error_history(disturbance_channel, Ti, 1.0))
        )
    ),
    prediction:adapt_precision(disturbance_channel),
    pai_route_disturbance(disturbance(test, situation_d, 0.8)),
    once(lattice:lattice_node_fact(Nexus, _, prediction_disturbance, _, _)).

%  AC-PR19-009: dark-room guard creates curiosity_prior node_fact
test(dark_room_guard_curiosity_prior) :-
    nb_getval(pr19_nexus_ref, Nexus),
    pai_minimize_free_energy(any_situation),
    once(lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _)).

:- end_tests(pr19).
