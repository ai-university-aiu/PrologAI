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

:- module(induction, [
    pai_induce/5,
    pai_metarule_declare/2,
    pai_induction_examples/3
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, memberchk/2, append/3]).

% ---------------------------------------------------------------------------
% Built-in metarules
% ---------------------------------------------------------------------------

:- dynamic metarule_def/2.
metarule_def(chain, chain).   % P(X,Z) :- Q(X,Y), R(Y,Z)
metarule_def(ident, ident).   % P(X)   :- Q(X)
metarule_def(curry, curry).   % P(X,Y) :- Q(X)
metarule_def(inv,   inv).     % P(X,Y) :- Q(Y,X)

% ---------------------------------------------------------------------------
% pai_metarule_declare/2
% ---------------------------------------------------------------------------

pai_metarule_declare(Name, Template) :-
    ( metarule_def(Name, _) -> true
    ; assertz(metarule_def(Name, Template))
    ).

% ---------------------------------------------------------------------------
% pai_induction_examples/3
%
%   Query the Lattice for examples recorded by the induction_actor.
%   Examples are node_facts with relation induction_example and
%   Referents = [sign(pos|neg), scope(Scope)].
% ---------------------------------------------------------------------------

:- dynamic induction_example/4.   % Scope, Sign(pos|neg), Relation, Args

pai_induction_examples(Relation, Scope, examples(Pos, Neg)) :-
    findall(Goal, (
        induction_example(Scope, pos, Relation, Args),
        Goal =.. [Relation|Args]
    ), Pos),
    findall(Goal, (
        induction_example(Scope, neg, Relation, Args),
        Goal =.. [Relation|Args]
    ), Neg).

% ---------------------------------------------------------------------------
% pai_induce/5
% ---------------------------------------------------------------------------

pai_induce(Examples, Background, HypothesisSpace, Budget, Hypothesis) :-
    Examples = examples(PosExamples, NegExamples),
    Budget = budget(MaxIter),
    HypothesisSpace = space(MaxClauses, MaxLits, AllowedRels),
    ( PosExamples = [First|_]
    ->  functor(First, TargetFun, TargetArity)
    ;   TargetFun = unknown, TargetArity = 0
    ),
    run_induction(TargetFun, TargetArity, PosExamples, NegExamples,
                  Background, MaxClauses, MaxLits, AllowedRels, MaxIter,
                  HypothesisSpace, Result),
    ( Result = hypothesis(Clauses)
    ->  ( constitutional_check(Clauses)
        ->  Hypothesis = hypothesis(Clauses, provenance(Examples, MaxIter))
        ;   Hypothesis = rejected(constitutional_violation)
        )
    ;   Hypothesis = no_hypothesis(Result)
    ).

% ---------------------------------------------------------------------------
% Induction loop
% ---------------------------------------------------------------------------

run_induction(TargetFun, TargetArity, Pos, Neg, BG, _MaxClauses, MaxLits,
              AllowedRels, MaxIter, HypSpace, Result) :-
    findall(Candidate,
        generate_candidate(TargetFun, TargetArity, AllowedRels, MaxLits, Candidate),
        Candidates),
    search_candidates(Candidates, Pos, Neg, BG, MaxIter, 0, HypSpace, Result).

search_candidates([], _, _, _, _, _, HypSpace, constraints(Cs)) :-
    findall(C, lattice_node_fact(_, _, induction_failure_constraint, [HypSpace, C], _), Cs).
search_candidates([_|_], _, _, _, MaxIter, Iter, HypSpace, constraints(Cs)) :-
    Iter >= MaxIter, !,
    findall(C, lattice_node_fact(_, _, induction_failure_constraint, [HypSpace, C], _), Cs).
search_candidates([Cand|Rest], Pos, Neg, BG, MaxIter, Iter, HypSpace, Result) :-
    Iter1 is Iter + 1,
    ( test_candidate(Cand, BG, Pos, Neg)
    ->  Result = hypothesis([Cand])
    ;   % Record failure constraint
        catch(anchor_node(induction_failure_constraint, [HypSpace, Cand], [], _), _, true),
        search_candidates(Rest, Pos, Neg, BG, MaxIter, Iter1, HypSpace, Result)
    ).

% ---------------------------------------------------------------------------
% Candidate generator — instantiates metarules with allowed relations
% ---------------------------------------------------------------------------

generate_candidate(TargetFun, TargetArity, AllowedRels, MaxLits, Clause) :-
    metarule_def(MetaName, _),
    instantiate_metarule(MetaName, TargetFun, TargetArity, AllowedRels, MaxLits, Clause).

instantiate_metarule(chain, P, 2, AllowedRels, MaxLits, Clause) :-
    MaxLits >= 2,
    member(Q/2, AllowedRels),
    member(R/2, AllowedRels),
    Clause = (Head :- Literal1, Literal2),
    Head     =.. [P, X, Z],
    Literal1 =.. [Q, X, Y],
    Literal2 =.. [R, Y, Z].

instantiate_metarule(ident, P, 1, AllowedRels, MaxLits, Clause) :-
    MaxLits >= 1,
    member(Q/1, AllowedRels),
    Clause = (Head :- Literal),
    Head    =.. [P, X],
    Literal =.. [Q, X].

instantiate_metarule(curry, P, 2, AllowedRels, MaxLits, Clause) :-
    MaxLits >= 1,
    member(Q/1, AllowedRels),
    Clause = (Head :- Literal),
    Head    =.. [P, X, _Y],
    Literal =.. [Q, X].

instantiate_metarule(inv, P, 2, AllowedRels, MaxLits, Clause) :-
    MaxLits >= 1,
    member(Q/2, AllowedRels),
    Clause = (Head :- Literal),
    Head    =.. [P, X, Y],
    Literal =.. [Q, Y, X].

% ---------------------------------------------------------------------------
% Candidate test — meta-interpreter for Horn clauses
% ---------------------------------------------------------------------------

test_candidate(Clause, BG, Pos, Neg) :-
    forall(member(PosGoal, Pos), prove(PosGoal, Clause, BG)),
    forall(member(NegGoal, Neg), \+ prove(NegGoal, Clause, BG)).

% Two-clause prove with member/2 for backtracking over BG alternatives.
% BG lookup comes first; clause application second.
% This allows the prover to try all matching BG facts before trying the clause.
prove(Goal, _, BG) :-
    member(Goal, BG).
prove(Goal, Clause, BG) :-
    copy_term(Clause, Head :- Body),
    Head = Goal,
    goals_list(Body, BodyGoals),
    prove_all(BodyGoals, Clause, BG).

prove_all([], _, _).
prove_all([G|Gs], Clause, BG) :-
    prove(G, Clause, BG),
    prove_all(Gs, Clause, BG).

goals_list((A, B), [A|Bs]) :-
    !,
    goals_list(B, Bs).
goals_list(A, [A]).

% ---------------------------------------------------------------------------
% Constitutional guard
%
%   Rejects hypotheses that reference execution-modifying predicates.
% ---------------------------------------------------------------------------

constitutional_check(Clauses) :-
    DisallowedFunctors = [halt, assert, retract, abolish, shell,
                          clause_erasing, retractall],
    forall(
        member(Clause, Clauses),
        \+ clause_violates(Clause, DisallowedFunctors)
    ).

clause_violates(Clause, Disallowed) :-
    term_variables(Clause, _),
    clause_term_goals(Clause, Goals),
    member(G, Goals),
    functor(G, F, _),
    memberchk(F, Disallowed).

clause_term_goals((_ :- Body), Goals) :-
    !,
    goals_list(Body, Goals).
clause_term_goals(Head, [Head]).
