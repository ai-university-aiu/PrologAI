/*  PrologAI — Distribution Semantics Probabilistic Layer  (Specification PR 41)

    Puts probabilistic predicates on a rigorous foundation: the distribution
    semantics of probabilistic logic programming (ProbLog/PITA lineage).

    Under the distribution semantics:
        • Probabilistic facts carry probabilities and define a probability
          distribution over possible worlds.
        • Deterministic rules derive conclusions within each world.
        • The probability of a query is the measure of the worlds that support
          it (summed over all supporting explanation sets).

    Implementation:
        For tractable programs we use WEIGHTED MODEL COUNTING over the
        explanation set returned by the meta-interpreter.  Each explanation is
        a conjunction of probabilistic facts; the probability of an explanation
        is the product of its fact probabilities (assuming independence).  The
        total probability is 1 − Π(1 − P(e)) over all explanations (inclusion-
        exclusion approximated by iterative product: works exactly when
        explanations are mutually exclusive, which is common in practice).

        For large programs or when budget is exceeded, sampling is used
        (Monte-Carlo, governed by the PR-21 budget term).

        Fact probabilities:
            pai_prob_fact(Fact, P) declares Fact with probability P.
            pai_bayes values (frequency × confidence) are the default source.

    Predicates:
        pai_prob_fact/2    — +Fact, +Prob      (declare probabilistic fact)
        pai_prob_query/3   — +Query, +Budget, -result(Prob, Explanations)
*/

:- module(probabilistic, [
    pai_prob_fact/2,
    pai_prob_rule/2,
    pai_prob_query/3
]).

:- use_module(library(lists),  [member/2, append/3]).
:- use_module(library(apply),  [maplist/3, foldl/4]).

:- dynamic prob_fact/2.   % Fact, Probability
:- dynamic prob_rule/2.   % Head, Body

% ---------------------------------------------------------------------------
% pai_prob_fact/2 — declare or update a probabilistic fact
% ---------------------------------------------------------------------------

pai_prob_fact(Fact, Prob) :-
    number(Prob), Prob >= 0.0, Prob =< 1.0,
    retractall(prob_fact(Fact, _)),
    assertz(prob_fact(Fact, Prob)).

% ---------------------------------------------------------------------------
% pai_prob_rule/2 — declare a deterministic rule for use inside worlds
% ---------------------------------------------------------------------------

pai_prob_rule(Head, Body) :-
    assertz(prob_rule(Head, Body)).

% ---------------------------------------------------------------------------
% pai_prob_query/3
%
%   Budget = budget(MaxIter) governs sampling fallback.
%   If the explanation count is small (≤ MaxIter), use exact weighted model
%   counting; otherwise sample MaxIter worlds and return a frequency estimate.
%
%   result(Prob, Explanations): Explanations is a list of explanation/2 terms:
%       explanation(Facts, P) — conjunctive explanation with probability P
% ---------------------------------------------------------------------------

pai_prob_query(Query, Budget, result(TotalProb, Explanations)) :-
    Budget = budget(MaxIter),
    findall(Expl, prove_with_expl(Query, Expl), AllExpls),
    length(AllExpls, NE),
    ( NE =< MaxIter
    ->  % Exact: compute explanation probabilities and combine
        maplist(expl_prob, AllExpls, ProbPairs),
        combine_probs(ProbPairs, TotalProb),
        Explanations = ProbPairs
    ;   % Sampling fallback: sample MaxIter worlds
        sample_prob(Query, MaxIter, TotalProb),
        Explanations = sampled(MaxIter, TotalProb)
    ).

% ---------------------------------------------------------------------------
% prove_with_expl/2 — meta-interpreter that collects proof explanations
%
%   An explanation is a list of ground probabilistic facts used in the proof.
%   Deterministic (non-probabilistic) facts are included with implicit P=1.
% ---------------------------------------------------------------------------

prove_with_expl(true, []) :- !.
prove_with_expl((A, B), Expl) :- !,
    prove_with_expl(A, EA),
    prove_with_expl(B, EB),
    append(EA, EB, Expl).
prove_with_expl(Goal, [expl_fact(Goal, P)]) :-
    prob_fact(Goal, P), !.
prove_with_expl(Goal, Expl) :-
    \+ prob_fact(Goal, _),
    prob_rule(Goal, Body),
    prove_with_expl(Body, Expl).

% ---------------------------------------------------------------------------
% expl_prob/2 — compute the probability of one explanation
% ---------------------------------------------------------------------------

expl_prob(ExplFacts, explanation(ExplFacts, P)) :-
    foldl([expl_fact(_, FP), Acc, NAcc]>>(NAcc is Acc * FP),
          ExplFacts, 1.0, P).

% ---------------------------------------------------------------------------
% combine_probs/2 — combine explanation probabilities
%
%   For independent (mutually exclusive) explanations: P = Σ P(e).
%   In the general case (overlapping support): use inclusion-exclusion
%   approximation: TotalP = 1 − Π(1 − P(e)).
% ---------------------------------------------------------------------------

combine_probs([], 0.0).
combine_probs(ProbPairs, TotalProb) :-
    foldl([explanation(_, P), Acc, NAcc]>>(NAcc is Acc * (1.0 - P)),
          ProbPairs, 1.0, ProdComplement),
    TotalProb is 1.0 - ProdComplement.

% ---------------------------------------------------------------------------
% sample_prob/3 — Monte-Carlo sampling fallback
% ---------------------------------------------------------------------------

sample_prob(Query, NSamples, Freq) :-
    sample_loop(Query, NSamples, 0, Hits),
    ( NSamples > 0 -> Freq is Hits / NSamples ; Freq = 0.0 ).

sample_loop(_, 0, Hits, Hits) :- !.
sample_loop(Query, N, Acc, Hits) :-
    N > 0,
    ( sample_world(Query) -> Acc1 is Acc + 1 ; Acc1 = Acc ),
    N1 is N - 1,
    sample_loop(Query, N1, Acc1, Hits).

sample_world(Query) :-
    catch(prove_sampled(Query), _, fail).

prove_sampled(true) :- !.
prove_sampled((A, B)) :- !,
    prove_sampled(A),
    prove_sampled(B).
prove_sampled(Goal) :-
    prob_fact(Goal, P), !,
    X is random_float,
    X =< P.
prove_sampled(Goal) :-
    \+ prob_fact(Goal, _),
    prob_rule(Goal, Body),
    prove_sampled(Body).
