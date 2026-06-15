/*  PrologAI — PR 41 Distribution Semantics Probabilistic Layer Acceptance Tests

    AC-PR41-001: Given probabilistic facts rain(0.3) and sprinkler(0.5) with
                 the standard wet-grass rules, when pai_prob_query computes
                 wet_grass, the probability matches the analytically correct
                 value within tolerance, with an explanation set.
    AC-PR41-002: pai_prob_fact declares a fact with its probability.
    AC-PR41-003: Certain fact (P=1.0) gives query probability 1.0.
    AC-PR41-004: Impossible fact (P=0.0) gives query probability 0.0.
    AC-PR41-005: Explanation set is non-empty for provable query.
    AC-PR41-006: Two independent probabilistic facts combined by AND:
                 P(A ∧ B) = P(A) × P(B) (product rule).
    AC-PR41-007: Two mutually exclusive paths to same conclusion:
                 P = P(path1) + P(path2) (inclusion-exclusion).
    AC-PR41-008: Sampling budget gives result within statistical tolerance.
    AC-PR41-009: pai_prob_fact is idempotent (re-declaring updates probability).
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/probabilistic/prolog'], ProbPath),
   assertz(file_search_path(library, ProbPath)).

:- use_module(library(plunit)).
:- use_module(library(probabilistic), [pai_prob_fact/2, pai_prob_rule/2, pai_prob_query/3]).

:- begin_tests(pr41, [setup(pr41_setup), cleanup(pr41_cleanup)]).

pr41_setup :-
    retractall(probabilistic:prob_fact(_, _)),
    retractall(probabilistic:prob_rule(_, _)).

pr41_cleanup :-
    retractall(probabilistic:prob_fact(_, _)),
    retractall(probabilistic:prob_rule(_, _)).

%  AC-PR41-001: wet-grass model within tolerance
%   P(wet_grass) = 1 - (1-0.3)*(1-0.5) = 1 - 0.35 = 0.65  (via inclusion-exclusion)
test(wet_grass_probability, [setup(pr41_setup)]) :-
    pai_prob_fact(rain41,      0.3),
    pai_prob_fact(sprinkler41, 0.5),
    pai_prob_rule(wet_grass41, rain41),
    pai_prob_rule(wet_grass41, sprinkler41),
    pai_prob_query(wet_grass41, budget(100), result(P, _Expls)),
    abs(P - 0.65) < 0.01.

%  AC-PR41-002: pai_prob_fact stores the probability
test(prob_fact_stored, [setup(pr41_setup)]) :-
    pai_prob_fact(smoke41, 0.4),
    probabilistic:prob_fact(smoke41, 0.4).

%  AC-PR41-003: certain fact (P=1.0)
test(certain_fact, [setup(pr41_setup)]) :-
    pai_prob_fact(certain41, 1.0),
    pai_prob_query(certain41, budget(10), result(P, _)),
    abs(P - 1.0) < 1.0e-9.

%  AC-PR41-004: impossible fact (P=0.0)
test(impossible_fact, [setup(pr41_setup)]) :-
    pai_prob_fact(impossible41, 0.0),
    pai_prob_query(impossible41, budget(10), result(P, _)),
    abs(P - 0.0) < 1.0e-9.

%  AC-PR41-005: explanation set non-empty for provable query
test(explanations_non_empty, [setup(pr41_setup)]) :-
    pai_prob_fact(event41, 0.7),
    pai_prob_query(event41, budget(10), result(_, Expls)),
    Expls \= [],
    Expls \= sampled(_, _).

%  AC-PR41-006: conjunction — P(A ∧ B) = P(A) × P(B) for independent A, B
%   Use wet_grass model with explicit conjunction goal
test(conjunction_product_rule, [setup(pr41_setup)]) :-
    pai_prob_fact(rain41b, 0.4),
    pai_prob_fact(cold41b, 0.6),
    pai_prob_rule(rainy_cold41, (rain41b, cold41b)),
    pai_prob_query(rainy_cold41, budget(10), result(P, _)),
    abs(P - 0.24) < 0.01.   % 0.4 * 0.6 = 0.24

%  AC-PR41-007: disjunction — two paths: P ≈ 1-(1-0.3)*(1-0.4) = 0.58
test(disjunction_two_paths, [setup(pr41_setup)]) :-
    pai_prob_fact(path1_41, 0.3),
    pai_prob_fact(path2_41, 0.4),
    pai_prob_rule(goal41, path1_41),
    pai_prob_rule(goal41, path2_41),
    pai_prob_query(goal41, budget(10), result(P, _)),
    abs(P - 0.58) < 0.01.

%  AC-PR41-008: sampling budget — result within statistical tolerance
test(sampling_tolerance, [setup(pr41_setup)]) :-
    pai_prob_fact(coin41, 0.5),
    pai_prob_query(coin41, budget(200), result(P, _)),
    abs(P - 0.5) < 0.15.    % wide tolerance for stochastic test

%  AC-PR41-009: pai_prob_fact idempotent (re-declare updates)
test(prob_fact_idempotent, [setup(pr41_setup)]) :-
    pai_prob_fact(event41b, 0.3),
    pai_prob_fact(event41b, 0.7),
    aggregate_all(count, probabilistic:prob_fact(event41b, _), Count),
    Count =:= 1,
    probabilistic:prob_fact(event41b, 0.7).

:- end_tests(pr41).
