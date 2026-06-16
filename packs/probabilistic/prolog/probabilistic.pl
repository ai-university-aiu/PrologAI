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

% Declare this file as the 'probabilistic' module and list its exported predicates.
:- module(probabilistic, [
    % Supply 'pai_prob_fact/2' as the next argument to the expression above.
    pai_prob_fact/2,
    % Supply 'pai_prob_rule/2' as the next argument to the expression above.
    pai_prob_rule/2,
    % Supply 'pai_prob_query/3' as the next argument to the expression above.
    pai_prob_query/3
% Close the expression opened above.
]).

% Import [member/2, append/3] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, append/3]).
% Import [maplist/3, foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/3, foldl/4]).

% Declare 'prob_fact/2.   % Fact, Probability' as dynamic — its facts may be added or removed at runtime.
:- dynamic prob_fact/2.   % Fact, Probability
% Declare 'prob_rule/2.   % Head, Body' as dynamic — its facts may be added or removed at runtime.
:- dynamic prob_rule/2.   % Head, Body

% ---------------------------------------------------------------------------
% pai_prob_fact/2 — declare or update a probabilistic fact
% ---------------------------------------------------------------------------

% Define a clause for 'pai prob fact': succeed when the following conditions hold.
pai_prob_fact(Fact, Prob) :-
    % Check that 'number(Prob), Prob' is greater than or equal to '0.0, Prob =< 1.0'.
    number(Prob), Prob >= 0.0, Prob =< 1.0,
    % Remove all matching facts from the runtime knowledge base.
    retractall(prob_fact(Fact, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(prob_fact(Fact, Prob)).

% ---------------------------------------------------------------------------
% pai_prob_rule/2 — declare a deterministic rule for use inside worlds
% ---------------------------------------------------------------------------

% Define a clause for 'pai prob rule': succeed when the following conditions hold.
pai_prob_rule(Head, Body) :-
    % Add a new fact or rule to the runtime knowledge base.
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

% Define a clause for 'pai prob query': succeed when the following conditions hold.
pai_prob_query(Query, Budget, result(TotalProb, Explanations)) :-
    % Check that 'Budget' is unifiable with 'budget(MaxIter)'.
    Budget = budget(MaxIter),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Expl, prove_with_expl(Query, Expl), AllExpls),
    % Unify 'NE' with the number of elements in list 'AllExpls'.
    length(AllExpls, NE),
    % Check that '( NE' is less than or equal to 'MaxIter'.
    ( NE =< MaxIter
    % If the condition above succeeded, perform the following action.
    ->  % Exact: compute explanation probabilities and combine
        % Continue the multi-line expression started above.
        maplist(expl_prob, AllExpls, ProbPairs),
        % Continue the multi-line expression started above.
        combine_probs(ProbPairs, TotalProb),
        % Continue the multi-line expression started above.
        Explanations = ProbPairs
    % Otherwise (else branch), perform the following action.
    ;   % Sampling fallback: sample MaxIter worlds
        % Continue the multi-line expression started above.
        sample_prob(Query, MaxIter, TotalProb),
        % Continue the multi-line expression started above.
        Explanations = sampled(MaxIter, TotalProb)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% prove_with_expl/2 — meta-interpreter that collects proof explanations
%
%   An explanation is a list of ground probabilistic facts used in the proof.
%   Deterministic (non-probabilistic) facts are included with implicit P=1.
% ---------------------------------------------------------------------------

% Define a clause for 'prove with expl': succeed when the following conditions hold.
prove_with_expl(true, []) :- !.
% Define a clause for 'prove with expl': succeed when the following conditions hold.
prove_with_expl((A, B), Expl) :- !,
    % State a fact for 'prove with expl' with the arguments listed below.
    prove_with_expl(A, EA),
    % State a fact for 'prove with expl' with the arguments listed below.
    prove_with_expl(B, EB),
    % Unify the third argument with the concatenation of the first two lists.
    append(EA, EB, Expl).
% Define a clause for 'prove with expl': succeed when the following conditions hold.
prove_with_expl(Goal, [expl_fact(Goal, P)]) :-
    % State a fact for 'prob fact' with the arguments listed below.
    prob_fact(Goal, P), !.
% Define a clause for 'prove with expl': succeed when the following conditions hold.
prove_with_expl(Goal, Expl) :-
    % Succeed only if 'prob_fact(Goal, _' cannot be proved (negation as failure).
    \+ prob_fact(Goal, _),
    % State a fact for 'prob rule' with the arguments listed below.
    prob_rule(Goal, Body),
    % State the fact: prove with expl(Body, Expl).
    prove_with_expl(Body, Expl).

% ---------------------------------------------------------------------------
% expl_prob/2 — compute the probability of one explanation
% ---------------------------------------------------------------------------

% Define a clause for 'expl prob': succeed when the following conditions hold.
expl_prob(ExplFacts, explanation(ExplFacts, P)) :-
    % State a fact for 'foldl' with the arguments listed below.
    foldl([expl_fact(_, FP), Acc, NAcc]>>(NAcc is Acc * FP),
          % Continue the multi-line expression started above.
          ExplFacts, 1.0, P).

% ---------------------------------------------------------------------------
% combine_probs/2 — combine explanation probabilities
%
%   For independent (mutually exclusive) explanations: P = Σ P(e).
%   In the general case (overlapping support): use inclusion-exclusion
%   approximation: TotalP = 1 − Π(1 − P(e)).
% ---------------------------------------------------------------------------

% State the fact: combine probs([], 0.0).
combine_probs([], 0.0).
% Define a clause for 'combine probs': succeed when the following conditions hold.
combine_probs(ProbPairs, TotalProb) :-
    % State a fact for 'foldl' with the arguments listed below.
    foldl([explanation(_, P), Acc, NAcc]>>(NAcc is Acc * (1.0 - P)),
          % Continue the multi-line expression started above.
          ProbPairs, 1.0, ProdComplement),
    % Evaluate the arithmetic expression '1.0 - ProdComplement' and bind the result to 'TotalProb'.
    TotalProb is 1.0 - ProdComplement.

% ---------------------------------------------------------------------------
% sample_prob/3 — Monte-Carlo sampling fallback
% ---------------------------------------------------------------------------

% Define a clause for 'sample prob': succeed when the following conditions hold.
sample_prob(Query, NSamples, Freq) :-
    % State a fact for 'sample loop' with the arguments listed below.
    sample_loop(Query, NSamples, 0, Hits),
    % Check that '( NSamples' is greater than '0 -> Freq is Hits / NSamples ; Freq = 0.0 )'.
    ( NSamples > 0 -> Freq is Hits / NSamples ; Freq = 0.0 ).

% Define a clause for 'sample loop': succeed when the following conditions hold.
sample_loop(_, 0, Hits, Hits) :- !.
% Define a clause for 'sample loop': succeed when the following conditions hold.
sample_loop(Query, N, Acc, Hits) :-
    % Check that 'N' is greater than '0'.
    N > 0,
    % Check that '( sample_world(Query) -> Acc1 is Acc + 1 ; Acc1' is unifiable with 'Acc )'.
    ( sample_world(Query) -> Acc1 is Acc + 1 ; Acc1 = Acc ),
    % Evaluate the arithmetic expression 'N - 1' and bind the result to 'N1'.
    N1 is N - 1,
    % State the fact: sample loop(Query, N1, Acc1, Hits).
    sample_loop(Query, N1, Acc1, Hits).

% Define a clause for 'sample world': succeed when the following conditions hold.
sample_world(Query) :-
    % State the fact: catch(prove_sampled(Query), _, fail).
    catch(prove_sampled(Query), _, fail).

% Define a clause for 'prove sampled': succeed when the following conditions hold.
prove_sampled(true) :- !.
% Define a clause for 'prove sampled': succeed when the following conditions hold.
prove_sampled((A, B)) :- !,
    % State a fact for 'prove sampled' with the arguments listed below.
    prove_sampled(A),
    % State the fact: prove sampled(B).
    prove_sampled(B).
% Define a clause for 'prove sampled': succeed when the following conditions hold.
prove_sampled(Goal) :-
    % State a fact for 'prob fact' with the arguments listed below.
    prob_fact(Goal, P), !,
    % Evaluate the arithmetic expression 'random_float' and bind the result to 'X'.
    X is random_float,
    % Check that 'X' is less than or equal to 'P'.
    X =< P.
% Define a clause for 'prove sampled': succeed when the following conditions hold.
prove_sampled(Goal) :-
    % Succeed only if 'prob_fact(Goal, _' cannot be proved (negation as failure).
    \+ prob_fact(Goal, _),
    % State a fact for 'prob rule' with the arguments listed below.
    prob_rule(Goal, Body),
    % State the fact: prove sampled(Body).
    prove_sampled(Body).
