/*  PrologAI — Causalontology Affect Test Suite  (WP-412)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/affect/test/test_affect.pl
*/

% Declare this file as a test module.
:- module(test_affect, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(affect)).

% Open the test block.
:- begin_tests(affect).

% Valence tracks goal congruence; arousal rises with surprise.
test(appraise_valence_arousal) :-
    affect:affect_reset,
    % A very good, very unexpected event: valence high, arousal high.
    affect:affect_appraise(win, 1.0, 0.0, appraisal(V, A)),
    assertion(V =:= 1.0),
    % arousal = 0.5*(1-0) + 0.5*1 = 1.0
    assertion(A =:= 1.0).

% A negative event yields a negative valence.
test(negative_event) :-
    affect:affect_reset,
    affect:affect_appraise(hurt, -0.8, 1.0, appraisal(V, _)),
    assertion(V =:= -0.8).

% The temperament is the mean of the feelings seen.
test(temper_is_mean) :-
    affect:affect_reset,
    affect:affect_appraise(e1, 1.0, 1.0, _),   % valence 1.0
    affect:affect_appraise(e2, -1.0, 1.0, _),  % valence -1.0
    affect:affect_temper(V, _),
    assertion(abs(V - 0.0) < 0.0001).

% An option is pre-flavoured by the remembered feeling of that event.
test(flavor_from_memory) :-
    affect:affect_reset,
    affect:affect_appraise(spikes, -0.9, 1.0, _),
    affect:affect_flavor(spikes, Bias),
    assertion(Bias =:= -0.9),
    % An unfelt option is neutral.
    affect:affect_flavor(unknown, B2),
    assertion(B2 =:= 0.0).

% Preference picks the best-felt option.
test(prefer_best_felt) :-
    affect:affect_reset,
    affect:affect_appraise(good_door, 0.9, 1.0, _),
    affect:affect_appraise(bad_door, -0.9, 1.0, _),
    affect:affect_prefer([bad_door, good_door, unknown], Best, _),
    assertion(Best == good_door).

% The coping signal reads a sour mood as struggling.
test(coping_struggling) :-
    affect:affect_reset,
    affect:affect_appraise(f1, -0.9, 1.0, _),
    affect:affect_appraise(f2, -0.8, 1.0, _),
    affect:affect_coping(Signal),
    assertion(Signal == struggling).

% The coping signal reads a bright mood as thriving.
test(coping_thriving) :-
    affect:affect_reset,
    affect:affect_appraise(w1, 0.9, 1.0, _),
    affect:affect_appraise(w2, 0.8, 1.0, _),
    affect:affect_coping(Signal),
    assertion(Signal == thriving).

% Close the test block.
:- end_tests(affect).
