/*  PrologAI — Clause Induction (Inductive Logic Programming)  (Specification PR 37)

    Gives the mind the ability to learn new relational structure from examples.

    Algorithm:  learn-from-failures loop (Popper-style)
        1. Generate a candidate clause from a metarule instantiated with
           predicates from the allowed-relations set.
        2. Test the candidate against positive and negative examples using a
           small backward meta-interpreter over background + candidate.
        3. If the candidate entails a negative example → add a specialization
           constraint and skip structurally similar candidates.
        4. If the candidate fails a positive example → add a generalization
           constraint and continue search.
        5. Repeat until a consistent hypothesis is found or budget is exhausted.
        6. Failed constraints are stored as induction_failure_constraint node_facts
           so the generic chainer can prune related searches later.
        7. Before returning, a constitutional guard rejects hypotheses that
           reference disallowed predicates.

    Metarules define second-order clause templates:
        chain: P(X,Z) :- Q(X,Y), R(Y,Z)  — transitive patterns
        ident: P(X)   :- Q(X)             — classification by proxy
        curry: P(X,Y) :- Q(X)             — lifting unary to binary
        inv:   P(X,Y) :- Q(Y,X)           — symmetric / inverse

    Predicates:
        pai_induce/5           — +Examples, +Background, +Space, +Budget, -Hypothesis
        pai_metarule_declare/2 — +Name, +Template
        pai_induction_examples/3 — +Relation, +Scope, -Examples
*/

% Declare this file as the 'induction' module and list its exported predicates.
:- module(induction, [
    % Supply 'pai_induce/5' as the next argument to the expression above.
    pai_induce/5,
    % Supply 'pai_metarule_declare/2' as the next argument to the expression above.
    pai_metarule_declare/2,
    % Supply 'pai_induction_examples/3' as the next argument to the expression above.
    pai_induction_examples/3
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, memberchk/2, append/3] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, memberchk/2, append/3]).

% ---------------------------------------------------------------------------
% Built-in metarules
% ---------------------------------------------------------------------------

% Declare 'metarule_def/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic metarule_def/2.
% Define a clause for 'metarule def': succeed when the following conditions hold.
metarule_def(chain, chain).   % P(X,Z) :- Q(X,Y), R(Y,Z)
% Define a clause for 'metarule def': succeed when the following conditions hold.
metarule_def(ident, ident).   % P(X)   :- Q(X)
% Define a clause for 'metarule def': succeed when the following conditions hold.
metarule_def(curry, curry).   % P(X,Y) :- Q(X)
% Define a clause for 'metarule def': succeed when the following conditions hold.
metarule_def(inv,   inv).     % P(X,Y) :- Q(Y,X)

% ---------------------------------------------------------------------------
% pai_metarule_declare/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai metarule declare': succeed when the following conditions hold.
pai_metarule_declare(Name, Template) :-
    % Execute: ( metarule_def(Name, _) -> true.
    ( metarule_def(Name, _) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(metarule_def(Name, Template))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_induction_examples/3
%
%   Query the Lattice for examples recorded by the induction_actor.
%   Examples are node_facts with relation induction_example and
%   Referents = [sign(pos|neg), scope(Scope)].
% ---------------------------------------------------------------------------

% Declare 'induction_example/4.   % Scope, Sign(pos|neg), Relation, Args' as dynamic — its facts may be added or removed at runtime.
:- dynamic induction_example/4.   % Scope, Sign(pos|neg), Relation, Args

% Define a clause for 'pai induction examples': succeed when the following conditions hold.
pai_induction_examples(Relation, Scope, examples(Pos, Neg)) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Goal, (
        % Continue the multi-line expression started above.
        induction_example(Scope, pos, Relation, Args),
        % Continue the multi-line expression started above.
        Goal =.. [Relation|Args]
    % Continue the multi-line expression started above.
    ), Pos),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Goal, (
        % Continue the multi-line expression started above.
        induction_example(Scope, neg, Relation, Args),
        % Continue the multi-line expression started above.
        Goal =.. [Relation|Args]
    % Continue the multi-line expression started above.
    ), Neg).

% ---------------------------------------------------------------------------
% pai_induce/5
% ---------------------------------------------------------------------------

% Define a clause for 'pai induce': succeed when the following conditions hold.
pai_induce(Examples, Background, HypothesisSpace, Budget, Hypothesis) :-
    % Check that 'Examples' is unifiable with 'examples(PosExamples, NegExamples)'.
    Examples = examples(PosExamples, NegExamples),
    % Check that 'Budget' is unifiable with 'budget(MaxIter)'.
    Budget = budget(MaxIter),
    % Check that 'HypothesisSpace' is unifiable with 'space(MaxClauses, MaxLits, AllowedRels)'.
    HypothesisSpace = space(MaxClauses, MaxLits, AllowedRels),
    % Check that '( PosExamples' is unifiable with '[First|_]'.
    ( PosExamples = [First|_]
    % If the condition above succeeded, perform the following action.
    ->  functor(First, TargetFun, TargetArity)
    % Otherwise (else branch), perform the following action.
    ;   TargetFun = unknown, TargetArity = 0
    % Close the expression opened above.
    ),
    % State a fact for 'run induction' with the arguments listed below.
    run_induction(TargetFun, TargetArity, PosExamples, NegExamples,
                  % Continue the multi-line expression started above.
                  Background, MaxClauses, MaxLits, AllowedRels, MaxIter,
                  % Continue the multi-line expression started above.
                  HypothesisSpace, Result),
    % Check that '( Result' is unifiable with 'hypothesis(Clauses)'.
    ( Result = hypothesis(Clauses)
    % If the condition above succeeded, perform the following action.
    ->  ( constitutional_check(Clauses)
        % If the condition above succeeded, perform the following action.
        ->  Hypothesis = hypothesis(Clauses, provenance(Examples, MaxIter))
        % Otherwise (else branch), perform the following action.
        ;   Hypothesis = rejected(constitutional_violation)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   Hypothesis = no_hypothesis(Result)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Induction loop
% ---------------------------------------------------------------------------

% State a fact for 'run induction' with the arguments listed below.
run_induction(TargetFun, TargetArity, Pos, Neg, BG, _MaxClauses, MaxLits,
              % Continue the multi-line expression started above.
              AllowedRels, MaxIter, HypSpace, Result) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Candidate,
        % Continue the multi-line expression started above.
        generate_candidate(TargetFun, TargetArity, AllowedRels, MaxLits, Candidate),
        % Supply 'Candidates' as the next argument to the expression above.
        Candidates),
    % State the fact: search candidates(Candidates, Pos, Neg, BG, MaxIter, 0, HypSpace, Result).
    search_candidates(Candidates, Pos, Neg, BG, MaxIter, 0, HypSpace, Result).

% Define a clause for 'search candidates': succeed when the following conditions hold.
search_candidates([], _, _, _, _, _, HypSpace, constraints(Cs)) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(C, lattice_node_fact(_, _, induction_failure_constraint, [HypSpace, C], _), Cs).
% Define a clause for 'search candidates': succeed when the following conditions hold.
search_candidates([_|_], _, _, _, MaxIter, Iter, HypSpace, constraints(Cs)) :-
    % Check that 'Iter' is greater than or equal to 'MaxIter, !'.
    Iter >= MaxIter, !,
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(C, lattice_node_fact(_, _, induction_failure_constraint, [HypSpace, C], _), Cs).
% Define a clause for 'search candidates': succeed when the following conditions hold.
search_candidates([Cand|Rest], Pos, Neg, BG, MaxIter, Iter, HypSpace, Result) :-
    % Evaluate the arithmetic expression 'Iter + 1' and bind the result to 'Iter1'.
    Iter1 is Iter + 1,
    % Execute: ( test_candidate(Cand, BG, Pos, Neg).
    ( test_candidate(Cand, BG, Pos, Neg)
    % If the condition above succeeded, perform the following action.
    ->  Result = hypothesis([Cand])
    % Otherwise (else branch), perform the following action.
    ;   % Record failure constraint
        % Continue the multi-line expression started above.
        catch(anchor_node(induction_failure_constraint, [HypSpace, Cand], [], _), _, true),
        % Continue the multi-line expression started above.
        search_candidates(Rest, Pos, Neg, BG, MaxIter, Iter1, HypSpace, Result)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Candidate generator — instantiates metarules with allowed relations
% ---------------------------------------------------------------------------

% Define a clause for 'generate candidate': succeed when the following conditions hold.
generate_candidate(TargetFun, TargetArity, AllowedRels, MaxLits, Clause) :-
    % State a fact for 'metarule def' with the arguments listed below.
    metarule_def(MetaName, _),
    % State the fact: instantiate metarule(MetaName, TargetFun, TargetArity, AllowedRels, MaxLits, Clause).
    instantiate_metarule(MetaName, TargetFun, TargetArity, AllowedRels, MaxLits, Clause).

% Define a clause for 'instantiate metarule': succeed when the following conditions hold.
instantiate_metarule(chain, P, 2, AllowedRels, MaxLits, Clause) :-
    % Check that 'MaxLits' is greater than or equal to '2'.
    MaxLits >= 2,
    % Succeed for each element 'Q/2' that is a member of the list.
    member(Q/2, AllowedRels),
    % Succeed for each element 'R/2' that is a member of the list.
    member(R/2, AllowedRels),
    % Check that 'Clause' is unifiable with '(Head :- Literal1, Literal2)'.
    Clause = (Head :- Literal1, Literal2),
    % Execute: Head     =.. [P, X, Z],.
    Head     =.. [P, X, Z],
    % Execute: Literal1 =.. [Q, X, Y],.
    Literal1 =.. [Q, X, Y],
    % Execute: Literal2 =.. [R, Y, Z]..
    Literal2 =.. [R, Y, Z].

% Define a clause for 'instantiate metarule': succeed when the following conditions hold.
instantiate_metarule(ident, P, 1, AllowedRels, MaxLits, Clause) :-
    % Check that 'MaxLits' is greater than or equal to '1'.
    MaxLits >= 1,
    % Succeed for each element 'Q/1' that is a member of the list.
    member(Q/1, AllowedRels),
    % Check that 'Clause' is unifiable with '(Head :- Literal)'.
    Clause = (Head :- Literal),
    % Execute: Head    =.. [P, X],.
    Head    =.. [P, X],
    % Execute: Literal =.. [Q, X]..
    Literal =.. [Q, X].

% Define a clause for 'instantiate metarule': succeed when the following conditions hold.
instantiate_metarule(curry, P, 2, AllowedRels, MaxLits, Clause) :-
    % Check that 'MaxLits' is greater than or equal to '1'.
    MaxLits >= 1,
    % Succeed for each element 'Q/1' that is a member of the list.
    member(Q/1, AllowedRels),
    % Check that 'Clause' is unifiable with '(Head :- Literal)'.
    Clause = (Head :- Literal),
    % Execute: Head    =.. [P, X, _Y],.
    Head    =.. [P, X, _Y],
    % Execute: Literal =.. [Q, X]..
    Literal =.. [Q, X].

% Define a clause for 'instantiate metarule': succeed when the following conditions hold.
instantiate_metarule(inv, P, 2, AllowedRels, MaxLits, Clause) :-
    % Check that 'MaxLits' is greater than or equal to '1'.
    MaxLits >= 1,
    % Succeed for each element 'Q/2' that is a member of the list.
    member(Q/2, AllowedRels),
    % Check that 'Clause' is unifiable with '(Head :- Literal)'.
    Clause = (Head :- Literal),
    % Execute: Head    =.. [P, X, Y],.
    Head    =.. [P, X, Y],
    % Execute: Literal =.. [Q, Y, X]..
    Literal =.. [Q, Y, X].

% ---------------------------------------------------------------------------
% Candidate test — meta-interpreter for Horn clauses
% ---------------------------------------------------------------------------

% Define a clause for 'test candidate': succeed when the following conditions hold.
test_candidate(Clause, BG, Pos, Neg) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(member(PosGoal, Pos), prove(PosGoal, Clause, BG)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(member(NegGoal, Neg), \+ prove(NegGoal, Clause, BG)).

% Two-clause prove with member/2 for backtracking over BG alternatives.
% BG lookup comes first; clause application second.
% This allows the prover to try all matching BG facts before trying the clause.
% Define a clause for 'prove': succeed when the following conditions hold.
prove(Goal, _, BG) :-
    % Succeed for each element 'Goal' that is a member of the list.
    member(Goal, BG).
% Define a clause for 'prove': succeed when the following conditions hold.
prove(Goal, Clause, BG) :-
    % Define a clause for 'copy term': succeed when the following conditions hold.
    copy_term(Clause, Head :- Body),
    % Check that 'Head' is unifiable with 'Goal'.
    Head = Goal,
    % State a fact for 'goals list' with the arguments listed below.
    goals_list(Body, BodyGoals),
    % State the fact: prove all(BodyGoals, Clause, BG).
    prove_all(BodyGoals, Clause, BG).

% State the fact: prove all([], _, _).
prove_all([], _, _).
% Define a clause for 'prove all': succeed when the following conditions hold.
prove_all([G|Gs], Clause, BG) :-
    % State a fact for 'prove' with the arguments listed below.
    prove(G, Clause, BG),
    % State the fact: prove all(Gs, Clause, BG).
    prove_all(Gs, Clause, BG).

% Define a clause for 'goals list': succeed when the following conditions hold.
goals_list((A, B), [A|Bs]) :-
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % State the fact: goals list(B, Bs).
    goals_list(B, Bs).
% State the fact: goals list(A, [A]).
goals_list(A, [A]).

% ---------------------------------------------------------------------------
% Constitutional guard
%
%   Rejects hypotheses that reference execution-modifying predicates.
% ---------------------------------------------------------------------------

% Define a clause for 'constitutional check': succeed when the following conditions hold.
constitutional_check(Clauses) :-
    % Check that 'DisallowedFunctors' is unifiable with '[halt, assert, retract, abolish, shell'.
    DisallowedFunctors = [halt, assert, retract, abolish, shell,
                          % Continue the multi-line expression started above.
                          clause_erasing, retractall],
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Clause, Clauses),
        % Continue the multi-line expression started above.
        \+ clause_violates(Clause, DisallowedFunctors)
    % Close the expression opened above.
    ).

% Define a clause for 'clause violates': succeed when the following conditions hold.
clause_violates(Clause, Disallowed) :-
    % State a fact for 'term variables' with the arguments listed below.
    term_variables(Clause, _),
    % State a fact for 'clause term goals' with the arguments listed below.
    clause_term_goals(Clause, Goals),
    % Succeed for each element 'G' that is a member of the list.
    member(G, Goals),
    % State a fact for 'functor' with the arguments listed below.
    functor(G, F, _),
    % State the fact: memberchk(F, Disallowed).
    memberchk(F, Disallowed).

% Define a clause for 'clause term goals': succeed when the following conditions hold.
clause_term_goals((_ :- Body), Goals) :-
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % State the fact: goals list(Body, Goals).
    goals_list(Body, Goals).
% State the fact: clause term goals(Head, [Head]).
clause_term_goals(Head, [Head]).
