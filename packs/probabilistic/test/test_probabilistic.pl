/*  PrologAI — Probabilistic Pack Test Suite  (PR 41)

    Behavioural acceptance tests for the distribution-semantics probabilistic
    layer. Exercises the three exported predicates — probabilistic_fact/2,
    probabilistic_rule/2, probabilistic_query/3 — with hand-computed numeric
    checks: certain and impossible facts, the inclusion-exclusion combination
    of two disjunctive paths (the wet-grass model), the product rule for a
    conjunctive rule body, explanation-set non-emptiness, and idempotent
    re-declaration.

    Run with:
        swipl -g "run_tests, halt" test_probabilistic.pl
*/

% Declare this file as its own module exporting nothing.
:- module(test_probabilistic, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the probabilistic pack under test from the library path.
:- use_module(library(probabilistic)).

% clear_probabilistic: wipe the pack's dynamic store before each test.
clear_probabilistic :-
    % Remove every previously declared probabilistic fact.
    retractall(probabilistic:prob_fact(_, _)),
    % Remove every previously declared probabilistic rule.
    retractall(probabilistic:prob_rule(_, _)).

% Open the test block, clearing the store before and after the whole run.
:- begin_tests(probabilistic, [setup(clear_probabilistic), cleanup(clear_probabilistic)]).

% probabilistic_fact/2 records the declared probability in the store.
test(fact_declares_and_stores, [setup(clear_probabilistic)]) :-
    % Declare a fact with a mid-range probability.
    probabilistic_fact(smoke, 0.4),
    % The exact probability must be retrievable from the pack's store.
    probabilistic:prob_fact(smoke, 0.4).

% A certain fact (probability 1.0) yields query probability 1.0.
test(certain_fact_probability_one, [setup(clear_probabilistic)]) :-
    % Declare a fact that is certain to hold.
    probabilistic_fact(sunrise, 1.0),
    % Query it under a small exact budget.
    probabilistic_query(sunrise, budget(10), result(P, _)),
    % The computed probability must be one.
    abs(P - 1.0) < 1.0e-9.

% An impossible fact (probability 0.0) yields query probability 0.0.
test(impossible_fact_probability_zero, [setup(clear_probabilistic)]) :-
    % Declare a fact that can never hold.
    probabilistic_fact(dragon, 0.0),
    % Query it under a small exact budget.
    probabilistic_query(dragon, budget(10), result(P, _)),
    % The computed probability must be zero.
    abs(P - 0.0) < 1.0e-9.

% Two disjunctive paths combine by inclusion-exclusion: 1-(1-0.3)(1-0.5)=0.65.
test(wet_grass_inclusion_exclusion, [setup(clear_probabilistic)]) :-
    % Rain occurs with probability 0.3.
    probabilistic_fact(rain, 0.3),
    % The sprinkler runs with probability 0.5.
    probabilistic_fact(sprinkler, 0.5),
    % Rain makes the grass wet.
    probabilistic_rule(wet_grass, rain),
    % The sprinkler also makes the grass wet.
    probabilistic_rule(wet_grass, sprinkler),
    % Query the combined probability of wet grass.
    probabilistic_query(wet_grass, budget(100), result(P, _)),
    % The two explanations combine to 0.65.
    abs(P - 0.65) < 0.01.

% A conjunctive rule body multiplies independent fact probabilities: 0.4*0.6=0.24.
test(conjunction_product_rule, [setup(clear_probabilistic)]) :-
    % Rain occurs with probability 0.4.
    probabilistic_fact(rain2, 0.4),
    % Cold occurs with probability 0.6.
    probabilistic_fact(cold2, 0.6),
    % Rainy-and-cold needs both facts to hold together.
    probabilistic_rule(rainy_cold, (rain2, cold2)),
    % Query the conjunctive conclusion.
    probabilistic_query(rainy_cold, budget(10), result(P, _)),
    % The product of the two probabilities is 0.24.
    abs(P - 0.24) < 0.01.

% A provable query returns a concrete, non-sampled explanation set.
test(explanations_non_empty, [setup(clear_probabilistic)]) :-
    % Declare a single probabilistic event.
    probabilistic_fact(event, 0.7),
    % Query it under an exact budget.
    probabilistic_query(event, budget(10), result(_, Expls)),
    % The explanation set must not be empty.
    Expls \= [],
    % The explanation set must be exact rather than a sampling summary.
    Expls \= sampled(_, _).

% Re-declaring a fact updates its probability rather than duplicating it.
test(fact_idempotent_redeclare, [setup(clear_probabilistic)]) :-
    % Declare the fact with an initial probability.
    probabilistic_fact(flaky, 0.3),
    % Re-declare the same fact with a new probability.
    probabilistic_fact(flaky, 0.7),
    % Only one stored clause may remain for the fact.
    aggregate_all(count, probabilistic:prob_fact(flaky, _), Count),
    % The count must be exactly one.
    Count =:= 1,
    % The retained probability must be the latest one.
    probabilistic:prob_fact(flaky, 0.7).

% Close the test block.
:- end_tests(probabilistic).
