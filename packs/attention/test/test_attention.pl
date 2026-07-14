/*  PrologAI — Attention Test Suite  (WP-410; converged with the attention-economy and attention-schema packs)

    The salience / single-winner-broadcast half (from co_salience) is exercised
    in full; the absorbed attention-economy and attention-schema predicates
    (which those packs shipped without tests) are proven present and exported
    under the converged pack-qualified names.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/attention/test/test_attention.pl
*/

% Declare this file as a test module.
:- module(test_attention, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the converged module under test.
:- use_module(library(attention)).

:- begin_tests(attention_salience).

% Salience is the weighted sum of the three signals (affect by magnitude).
test(score_weighted_sum) :-
    attention:attention_reset,
    % Default weights are (1.0, 1.0, 0.5).
    attention:attention_offer(thing, 0.4, 0.2, -0.6),
    attention:attention_score(thing, S),
    % 1.0*0.4 + 1.0*0.2 + 0.5*0.6 = 0.9
    assertion(abs(S - 0.9) < 0.0001).

% The single most salient item is broadcast.
test(broadcast_winner) :-
    attention:attention_reset,
    attention:attention_offer(quiet, 0.1, 0.1, 0.0),
    attention:attention_offer(loud,  0.9, 0.8, 0.5),
    attention:attention_broadcast(Item, _),
    assertion(Item == loud).

% The working set keeps at most K items, most salient first.
test(working_set_bounded_ordered) :-
    attention:attention_reset,
    attention:attention_offer(a, 0.9, 0.9, 0.0),   % high
    attention:attention_offer(b, 0.5, 0.5, 0.0),   % mid
    attention:attention_offer(c, 0.1, 0.1, 0.0),   % low
    attention:attention_working_set(2, Items),
    assertion(Items == [a, b]).

% Re-offering an item replaces its earlier signals.
test(reoffer_replaces) :-
    attention:attention_reset,
    attention:attention_offer(x, 0.1, 0.1, 0.0),
    attention:attention_offer(x, 0.9, 0.9, 0.0),
    attention:attention_count(N),
    assertion(N =:= 1),
    attention:attention_score(x, S),
    assertion(S > 1.0).

% Custom weights change the ranking.
test(weights_change_ranking) :-
    attention:attention_reset,
    % Weigh affect heavily so an emotionally charged item wins.
    attention:attention_set_weights(0.1, 0.1, 5.0),
    attention:attention_offer(dull,   0.9, 0.9, 0.0),
    attention:attention_offer(charged, 0.1, 0.1, 1.0),
    attention:attention_broadcast(Item, _),
    assertion(Item == charged).

% Forgetting drops a candidate.
test(forget_removes) :-
    attention:attention_reset,
    attention:attention_offer(keep, 0.5, 0.5, 0.0),
    attention:attention_offer(drop, 0.5, 0.5, 0.0),
    attention:attention_forget(drop),
    attention:attention_count(N),
    assertion(N =:= 1).

% Close the test block.
:- end_tests(attention_salience).

% Open the absorbed-predicates presence block (no-loss proof for the economy + schema halves).
:- begin_tests(attention_absorbed).

% Every attention-economy predicate is present under its new name.
test(economy_predicates_present) :-
    assertion(current_predicate(attention:attention_level/3)),
    assertion(current_predicate(attention:attention_link/2)),
    assertion(current_predicate(attention:attention_metrics/1)),
    assertion(current_predicate(attention:attention_spread/2)),
    assertion(current_predicate(attention:attention_banker_cycle/0)),
    assertion(current_predicate(attention:attention_evict_lowest_lti/1)),
    assertion(current_predicate(attention:attention_wage/3)).

% Every attention-schema predicate is present under its new name.
test(schema_predicates_present) :-
    assertion(current_predicate(attention:attention_predict/2)),
    assertion(current_predicate(attention:attention_schema/2)),
    assertion(current_predicate(attention:attention_schema_enable/0)),
    assertion(current_predicate(attention:attention_schema_disable/0)),
    assertion(current_predicate(attention:attention_schema_score/3)).

% The STI/LTI banker reads a node's importance and reports metrics (a live economy call).
test(economy_live_smoke) :-
    attention:attention_level(node_x, sti, _V),
    attention:attention_metrics(_M).

% Close the absorbed-predicates presence block.
:- end_tests(attention_absorbed).
