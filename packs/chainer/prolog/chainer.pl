/*  PrologAI — Generic Chainer and Meta-Reasoning  (Specification PR 34)

    Provides one inference engine — the chainer — parameterized by rule bases
    stored in the Lattice, with control knowledge (policies) also stored in the
    Lattice so the mind can reason about how it reasons.

    Rule base:
        A rule base is a named collection of chain_fact and chain_rule
        node_facts.  `pai_rule_base/2` declares one from a list of
        fact(F) and rule(Antecedent, Consequent) terms.

    Backward chaining:
        DFS from goal; at each step find a rule whose Consequent unifies
        with the current subgoal and recurse on its Antecedent.
        Base-fact check takes priority; base facts close branches at
        any depth (a fact satisfies a subgoal immediately).
        Returns chain(Provenance) with the successful chain, or
        no_chain(frontier(Goal)) on exhaustion.

    Forward chaining:
        BFS fixpoint: starting from base facts plus any caller-supplied
        extra facts, repeatedly apply rules until no new facts can be
        derived or budget is exhausted.
        Returns chain(Provenance) with the full derived set.

    Control policies:
        Each named policy for a rule base tracks successes and attempts.
        pai_chain/5 accepts policy(Name) in Options and records outcomes.
        pai_control_policy/3 queries stats and finds the best policy.

    Predicates:
        pai_chain/5          — +Direction, +RuleBase, +Start, -Result, +Options
        pai_rule_base/2      — +Name, +Rules
        pai_control_policy/3 — +RuleBase, ?PolicyName, ?Stats
*/

:- module(chainer, [
    pai_chain/5,
    pai_rule_base/2,
    pai_control_policy/3
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, memberchk/2, append/3, last/2]).
:- use_module(library(aggregate),  [aggregate_all/3]).
:- use_module(library(option),     [option/3]).

:- dynamic policy_record/4.   % RuleBase, PolicyName, Successes, Attempts

% ---------------------------------------------------------------------------
% pai_rule_base/2
%
%   Register a rule base as Lattice node_facts.
%   Rules is a list of fact(F) and rule(Antecedent, Consequent) terms.
% ---------------------------------------------------------------------------

pai_rule_base(Name, Rules) :-
    forall(member(fact(F), Rules),
           anchor_node(chain_fact, [Name, F], [], _)),
    forall(member(rule(Ante, Cons), Rules),
           anchor_node(chain_rule, [Name, Ante, Cons], [], _)).

% ---------------------------------------------------------------------------
% pai_chain/5
% ---------------------------------------------------------------------------

pai_chain(backward, RuleBase, Goal, Result, Options) :-
    option(max_depth(MaxD), Options, 10),
    option(max_steps(MaxS), Options, 100),
    option(policy(Policy), Options, default),
    dfs_b(RuleBase, Goal, MaxD, MaxS, 0, Steps, Chain),
    ( Chain = no_chain
    ->  Result = no_chain(frontier(Goal)),
        record_outcome(RuleBase, Policy, failure)
    ;   Result = chain(provenance(RuleBase, Chain, MaxD, Steps)),
        record_outcome(RuleBase, Policy, success)
    ).

pai_chain(forward, RuleBase, Start, Result, Options) :-
    option(max_steps(MaxS), Options, 100),
    option(policy(Policy), Options, default),
    ( is_list(Start) -> InitExtra = Start ; InitExtra = [Start] ),
    findall(F, lattice_node_fact(_, _, chain_fact, [RuleBase, F], _), BaseFacts),
    append(BaseFacts, InitExtra, All0),
    sort(All0, Known0),
    fwd_fixpoint(RuleBase, Known0, MaxS, 0, Derived, Steps),
    ( Steps >= MaxS
    ->  Result = no_chain(frontier(Derived)),
        record_outcome(RuleBase, Policy, failure)
    ;   Result = chain(provenance(RuleBase, Derived, 0, Steps)),
        record_outcome(RuleBase, Policy, success)
    ).

% ---------------------------------------------------------------------------
% Backward DFS
%
%   dfs_b(+RB, +Goal, +MaxD, +MaxS, +S0, -Steps, -Chain)
%   Chain = [step(Ante,Goal)|SubChain] | [fact(Goal)] | no_chain
%   Always succeeds.
% ---------------------------------------------------------------------------

dfs_b(RuleBase, Goal, _MaxD, _MaxS, S, S, [fact(Goal)]) :-
    lattice_node_fact(_, _, chain_fact, [RuleBase, Goal], _), !.
dfs_b(_RuleBase, _Goal, MaxD, _MaxS, S, S, no_chain) :-
    MaxD =< 0, !.
dfs_b(_RuleBase, _Goal, _MaxD, MaxS, S, S, no_chain) :-
    S >= MaxS, !.
dfs_b(RuleBase, Goal, MaxD, MaxS, S0, Steps, Chain) :-
    D1 is MaxD - 1,
    S1 is S0 + 1,
    ( find_chain(RuleBase, Goal, D1, MaxS, S1, Steps, SubChain)
    ->  Chain = SubChain
    ;   Chain = no_chain, Steps = S0
    ).

find_chain(RuleBase, Goal, D, MaxS, S0, Steps, Chain) :-
    lattice_node_fact(_, _, chain_rule, [RuleBase, Ante, Goal], _),
    dfs_b(RuleBase, Ante, D, MaxS, S0, S1, SubChain),
    SubChain \= no_chain, !,
    Chain = [step(Ante, Goal)|SubChain],
    Steps = S1.

% ---------------------------------------------------------------------------
% Forward BFS fixpoint
%
%   fwd_fixpoint(+RB, +Known, +MaxS, +S0, -Derived, -Steps)
% ---------------------------------------------------------------------------

fwd_fixpoint(RuleBase, Known, MaxS, S0, Derived, Steps) :-
    findall(C, (
        lattice_node_fact(_, _, chain_rule, [RuleBase, A, C], _),
        memberchk(A, Known),
        \+ memberchk(C, Known)
    ), NewFacts0),
    sort(NewFacts0, NewFacts),
    ( NewFacts = []
    ->  Derived = Known, Steps = S0
    ;   length(NewFacts, Len),
        S1 is S0 + Len,
        ( S1 >= MaxS
        ->  Derived = Known, Steps = S1
        ;   append(Known, NewFacts, Known1),
            sort(Known1, Known2),
            fwd_fixpoint(RuleBase, Known2, MaxS, S1, Derived, Steps)
        )
    ).

% ---------------------------------------------------------------------------
% Control policy management
%
%   pai_control_policy(+RuleBase, ?PolicyName, ?Stats)
%   If PolicyName is bound: ensure policy exists, return its stats.
%   If PolicyName is unbound: bind to the highest-reliability policy.
% ---------------------------------------------------------------------------

pai_control_policy(RuleBase, PolicyName, Stats) :-
    ( var(PolicyName)
    ->  best_policy(RuleBase, PolicyName)
    ;   ensure_policy(RuleBase, PolicyName)
    ),
    ( policy_record(RuleBase, PolicyName, S, A)
    ->  true
    ;   S = 0, A = 0
    ),
    ( A > 0 -> R is S / A ; R = 0.0 ),
    Stats = policy_stats(PolicyName, S, A, R).

best_policy(RuleBase, PolicyName) :-
    findall(R-P, (
        policy_record(RuleBase, P, S, A),
        ( A > 0 -> R is S / A ; R = 0.0 )
    ), Pairs),
    Pairs \= [],
    msort(Pairs, Sorted),
    last(Sorted, _-PolicyName).

ensure_policy(RuleBase, PolicyName) :-
    ( policy_record(RuleBase, PolicyName, _, _)
    ->  true
    ;   assertz(policy_record(RuleBase, PolicyName, 0, 0))
    ).

% ---------------------------------------------------------------------------
% Internal: record chain outcome into a named policy
% ---------------------------------------------------------------------------

record_outcome(_, default, _) :- !.
record_outcome(RuleBase, Policy, Outcome) :-
    ensure_policy(RuleBase, Policy),
    retract(policy_record(RuleBase, Policy, S0, A0)),
    A1 is A0 + 1,
    ( Outcome = success -> S1 is S0 + 1 ; S1 = S0 ),
    assertz(policy_record(RuleBase, Policy, S1, A1)).
