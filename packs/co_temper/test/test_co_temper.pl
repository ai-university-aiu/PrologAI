/*  PrologAI — Causalontology Affect Test Suite  (WP-412)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_temper/test/test_co_temper.pl
*/

% Declare this file as a test module.
:- module(test_co_temper, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_temper)).

% Open the test block.
:- begin_tests(co_temper).

% Valence tracks goal congruence; arousal rises with surprise.
test(appraise_valence_arousal) :-
    co_temper:tp_reset,
    % A very good, very unexpected event: valence high, arousal high.
    co_temper:tp_appraise(win, 1.0, 0.0, appraisal(V, A)),
    assertion(V =:= 1.0),
    % arousal = 0.5*(1-0) + 0.5*1 = 1.0
    assertion(A =:= 1.0).

% A negative event yields a negative valence.
test(negative_event) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(hurt, -0.8, 1.0, appraisal(V, _)),
    assertion(V =:= -0.8).

% The temperament is the mean of the feelings seen.
test(temper_is_mean) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(e1, 1.0, 1.0, _),   % valence 1.0
    co_temper:tp_appraise(e2, -1.0, 1.0, _),  % valence -1.0
    co_temper:tp_temper(V, _),
    assertion(abs(V - 0.0) < 0.0001).

% An option is pre-flavoured by the remembered feeling of that event.
test(flavor_from_memory) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(spikes, -0.9, 1.0, _),
    co_temper:tp_flavor(spikes, Bias),
    assertion(Bias =:= -0.9),
    % An unfelt option is neutral.
    co_temper:tp_flavor(unknown, B2),
    assertion(B2 =:= 0.0).

% Preference picks the best-felt option.
test(prefer_best_felt) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(good_door, 0.9, 1.0, _),
    co_temper:tp_appraise(bad_door, -0.9, 1.0, _),
    co_temper:tp_prefer([bad_door, good_door, unknown], Best, _),
    assertion(Best == good_door).

% The coping signal reads a sour mood as struggling.
test(coping_struggling) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(f1, -0.9, 1.0, _),
    co_temper:tp_appraise(f2, -0.8, 1.0, _),
    co_temper:tp_coping(Signal),
    assertion(Signal == struggling).

% The coping signal reads a bright mood as thriving.
test(coping_thriving) :-
    co_temper:tp_reset,
    co_temper:tp_appraise(w1, 0.9, 1.0, _),
    co_temper:tp_appraise(w2, 0.8, 1.0, _),
    co_temper:tp_coping(Signal),
    assertion(Signal == thriving).

% Close the test block.
:- end_tests(co_temper).
