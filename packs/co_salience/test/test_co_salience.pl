/*  PrologAI — Causalontology Attention & Broadcast Test Suite  (WP-410)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_salience/test/test_co_salience.pl
*/

% Declare this file as a test module.
:- module(test_co_salience, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_salience)).

% Open the test block.
:- begin_tests(co_salience).

% Salience is the weighted sum of the three signals (affect by magnitude).
test(score_weighted_sum) :-
    co_salience:sl_reset,
    % Default weights are (1.0, 1.0, 0.5).
    co_salience:sl_offer(thing, 0.4, 0.2, -0.6),
    co_salience:sl_score(thing, S),
    % 1.0*0.4 + 1.0*0.2 + 0.5*0.6 = 0.9
    assertion(abs(S - 0.9) < 0.0001).

% The single most salient item is broadcast.
test(broadcast_winner) :-
    co_salience:sl_reset,
    co_salience:sl_offer(quiet, 0.1, 0.1, 0.0),
    co_salience:sl_offer(loud,  0.9, 0.8, 0.5),
    co_salience:sl_broadcast(Item, _),
    assertion(Item == loud).

% The working set keeps at most K items, most salient first.
test(working_set_bounded_ordered) :-
    co_salience:sl_reset,
    co_salience:sl_offer(a, 0.9, 0.9, 0.0),   % high
    co_salience:sl_offer(b, 0.5, 0.5, 0.0),   % mid
    co_salience:sl_offer(c, 0.1, 0.1, 0.0),   % low
    co_salience:sl_working_set(2, Items),
    assertion(Items == [a, b]).

% Re-offering an item replaces its earlier signals.
test(reoffer_replaces) :-
    co_salience:sl_reset,
    co_salience:sl_offer(x, 0.1, 0.1, 0.0),
    co_salience:sl_offer(x, 0.9, 0.9, 0.0),
    co_salience:sl_count(N),
    assertion(N =:= 1),
    co_salience:sl_score(x, S),
    assertion(S > 1.0).

% Custom weights change the ranking.
test(weights_change_ranking) :-
    co_salience:sl_reset,
    % Weigh affect heavily so an emotionally charged item wins.
    co_salience:sl_set_weights(0.1, 0.1, 5.0),
    co_salience:sl_offer(dull,   0.9, 0.9, 0.0),
    co_salience:sl_offer(charged, 0.1, 0.1, 1.0),
    co_salience:sl_broadcast(Item, _),
    assertion(Item == charged).

% Forgetting drops a candidate.
test(forget_removes) :-
    co_salience:sl_reset,
    co_salience:sl_offer(keep, 0.5, 0.5, 0.0),
    co_salience:sl_offer(drop, 0.5, 0.5, 0.0),
    co_salience:sl_forget(drop),
    co_salience:sl_count(N),
    assertion(N =:= 1).

% Close the test block.
:- end_tests(co_salience).
