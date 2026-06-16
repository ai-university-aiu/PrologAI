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

% Declare this file as the 'chainer' module and list its exported predicates.
:- module(chainer, [
    % Supply 'pai_chain/5' as the next argument to the expression above.
    pai_chain/5,
    % Supply 'pai_rule_base/2' as the next argument to the expression above.
    pai_rule_base/2,
    % Supply 'pai_control_policy/3' as the next argument to the expression above.
    pai_control_policy/3
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, memberchk/2, append/3, last/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, memberchk/2, append/3, last/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),  [aggregate_all/3]).
% Import [option/3] from the built-in 'option' library.
:- use_module(library(option),     [option/3]).

% Declare 'policy_record/4.   % RuleBase, PolicyName, Successes, Attempts' as dynamic — its facts may be added or removed at runtime.
:- dynamic policy_record/4.   % RuleBase, PolicyName, Successes, Attempts

% ---------------------------------------------------------------------------
% pai_rule_base/2
%
%   Register a rule base as Lattice node_facts.
%   Rules is a list of fact(F) and rule(Antecedent, Consequent) terms.
% ---------------------------------------------------------------------------

% Define a clause for 'pai rule base': succeed when the following conditions hold.
pai_rule_base(Name, Rules) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(member(fact(F), Rules),
           % Continue the multi-line expression started above.
           anchor_node(chain_fact, [Name, F], [], _)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(member(rule(Ante, Cons), Rules),
           % Continue the multi-line expression started above.
           anchor_node(chain_rule, [Name, Ante, Cons], [], _)).

% ---------------------------------------------------------------------------
% pai_chain/5
% ---------------------------------------------------------------------------

% Define a clause for 'pai chain': succeed when the following conditions hold.
pai_chain(backward, RuleBase, Goal, Result, Options) :-
    % State a fact for 'option' with the arguments listed below.
    option(max_depth(MaxD), Options, 10),
    % State a fact for 'option' with the arguments listed below.
    option(max_steps(MaxS), Options, 100),
    % State a fact for 'option' with the arguments listed below.
    option(policy(Policy), Options, default),
    % State a fact for 'dfs b' with the arguments listed below.
    dfs_b(RuleBase, Goal, MaxD, MaxS, 0, Steps, Chain),
    % Check that '( Chain' is unifiable with 'no_chain'.
    ( Chain = no_chain
    % If the condition above succeeded, perform the following action.
    ->  Result = no_chain(frontier(Goal)),
        % Continue the multi-line expression started above.
        record_outcome(RuleBase, Policy, failure)
    % Otherwise (else branch), perform the following action.
    ;   Result = chain(provenance(RuleBase, Chain, MaxD, Steps)),
        % Continue the multi-line expression started above.
        record_outcome(RuleBase, Policy, success)
    % Close the expression opened above.
    ).

% Define a clause for 'pai chain': succeed when the following conditions hold.
pai_chain(forward, RuleBase, Start, Result, Options) :-
    % State a fact for 'option' with the arguments listed below.
    option(max_steps(MaxS), Options, 100),
    % State a fact for 'option' with the arguments listed below.
    option(policy(Policy), Options, default),
    % Check that '( is_list(Start) -> InitExtra' is unifiable with 'Start ; InitExtra = [Start] )'.
    ( is_list(Start) -> InitExtra = Start ; InitExtra = [Start] ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(F, lattice_node_fact(_, _, chain_fact, [RuleBase, F], _), BaseFacts),
    % Unify the third argument with the concatenation of the first two lists.
    append(BaseFacts, InitExtra, All0),
    % Sort list 'All0' into 'Known0', removing duplicates.
    sort(All0, Known0),
    % State a fact for 'fwd fixpoint' with the arguments listed below.
    fwd_fixpoint(RuleBase, Known0, MaxS, 0, Derived, Steps),
    % Check that '( Steps' is greater than or equal to 'MaxS'.
    ( Steps >= MaxS
    % If the condition above succeeded, perform the following action.
    ->  Result = no_chain(frontier(Derived)),
        % Continue the multi-line expression started above.
        record_outcome(RuleBase, Policy, failure)
    % Otherwise (else branch), perform the following action.
    ;   Result = chain(provenance(RuleBase, Derived, 0, Steps)),
        % Continue the multi-line expression started above.
        record_outcome(RuleBase, Policy, success)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Backward DFS
%
%   dfs_b(+RB, +Goal, +MaxD, +MaxS, +S0, -Steps, -Chain)
%   Chain = [step(Ante,Goal)|SubChain] | [fact(Goal)] | no_chain
%   Always succeeds.
% ---------------------------------------------------------------------------

% Define a clause for 'dfs b': succeed when the following conditions hold.
dfs_b(RuleBase, Goal, _MaxD, _MaxS, S, S, [fact(Goal)]) :-
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, _, chain_fact, [RuleBase, Goal], _), !.
% Define a clause for 'dfs b': succeed when the following conditions hold.
dfs_b(_RuleBase, _Goal, MaxD, _MaxS, S, S, no_chain) :-
    % Check that 'MaxD' is less than or equal to '0, !'.
    MaxD =< 0, !.
% Define a clause for 'dfs b': succeed when the following conditions hold.
dfs_b(_RuleBase, _Goal, _MaxD, MaxS, S, S, no_chain) :-
    % Check that 'S' is greater than or equal to 'MaxS, !'.
    S >= MaxS, !.
% Define a clause for 'dfs b': succeed when the following conditions hold.
dfs_b(RuleBase, Goal, MaxD, MaxS, S0, Steps, Chain) :-
    % Evaluate the arithmetic expression 'MaxD - 1' and bind the result to 'D1'.
    D1 is MaxD - 1,
    % Evaluate the arithmetic expression 'S0 + 1' and bind the result to 'S1'.
    S1 is S0 + 1,
    % Execute: ( find_chain(RuleBase, Goal, D1, MaxS, S1, Steps, SubChain).
    ( find_chain(RuleBase, Goal, D1, MaxS, S1, Steps, SubChain)
    % If the condition above succeeded, perform the following action.
    ->  Chain = SubChain
    % Otherwise (else branch), perform the following action.
    ;   Chain = no_chain, Steps = S0
    % Close the expression opened above.
    ).

% Define a clause for 'find chain': succeed when the following conditions hold.
find_chain(RuleBase, Goal, D, MaxS, S0, Steps, Chain) :-
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, _, chain_rule, [RuleBase, Ante, Goal], _),
    % State a fact for 'dfs b' with the arguments listed below.
    dfs_b(RuleBase, Ante, D, MaxS, S0, S1, SubChain),
    % Check that 'SubChain' is not unifiable with 'no_chain, !'.
    SubChain \= no_chain, !,
    % Check that 'Chain' is unifiable with '[step(Ante, Goal)|SubChain]'.
    Chain = [step(Ante, Goal)|SubChain],
    % Check that 'Steps' is unifiable with 'S1'.
    Steps = S1.

% ---------------------------------------------------------------------------
% Forward BFS fixpoint
%
%   fwd_fixpoint(+RB, +Known, +MaxS, +S0, -Derived, -Steps)
% ---------------------------------------------------------------------------

% Define a clause for 'fwd fixpoint': succeed when the following conditions hold.
fwd_fixpoint(RuleBase, Known, MaxS, S0, Derived, Steps) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(C, (
        % Continue the multi-line expression started above.
        lattice_node_fact(_, _, chain_rule, [RuleBase, A, C], _),
        % Continue the multi-line expression started above.
        memberchk(A, Known),
        % Continue the multi-line expression started above.
        \+ memberchk(C, Known)
    % Continue the multi-line expression started above.
    ), NewFacts0),
    % Sort list 'NewFacts0' into 'NewFacts', removing duplicates.
    sort(NewFacts0, NewFacts),
    % Check that '( NewFacts' is unifiable with '[]'.
    ( NewFacts = []
    % If the condition above succeeded, perform the following action.
    ->  Derived = Known, Steps = S0
    % Otherwise (else branch), perform the following action.
    ;   length(NewFacts, Len),
        % Continue the multi-line expression started above.
        S1 is S0 + Len,
        % Continue the multi-line expression started above.
        ( S1 >= MaxS
        % If the condition above succeeded, perform the following action.
        ->  Derived = Known, Steps = S1
        % Otherwise (else branch), perform the following action.
        ;   append(Known, NewFacts, Known1),
            % Continue the multi-line expression started above.
            sort(Known1, Known2),
            % Continue the multi-line expression started above.
            fwd_fixpoint(RuleBase, Known2, MaxS, S1, Derived, Steps)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Control policy management
%
%   pai_control_policy(+RuleBase, ?PolicyName, ?Stats)
%   If PolicyName is bound: ensure policy exists, return its stats.
%   If PolicyName is unbound: bind to the highest-reliability policy.
% ---------------------------------------------------------------------------

% Define a clause for 'pai control policy': succeed when the following conditions hold.
pai_control_policy(RuleBase, PolicyName, Stats) :-
    % Execute: ( var(PolicyName).
    ( var(PolicyName)
    % If the condition above succeeded, perform the following action.
    ->  best_policy(RuleBase, PolicyName)
    % Otherwise (else branch), perform the following action.
    ;   ensure_policy(RuleBase, PolicyName)
    % Close the expression opened above.
    ),
    % Execute: ( policy_record(RuleBase, PolicyName, S, A).
    ( policy_record(RuleBase, PolicyName, S, A)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   S = 0, A = 0
    % Close the expression opened above.
    ),
    % Check that '( A' is greater than '0 -> R is S / A ; R = 0.0 )'.
    ( A > 0 -> R is S / A ; R = 0.0 ),
    % Check that 'Stats' is unifiable with 'policy_stats(PolicyName, S, A, R)'.
    Stats = policy_stats(PolicyName, S, A, R).

% Define a clause for 'best policy': succeed when the following conditions hold.
best_policy(RuleBase, PolicyName) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(R-P, (
        % Continue the multi-line expression started above.
        policy_record(RuleBase, P, S, A),
        % Continue the multi-line expression started above.
        ( A > 0 -> R is S / A ; R = 0.0 )
    % Continue the multi-line expression started above.
    ), Pairs),
    % Check that 'Pairs' is not unifiable with '[]'.
    Pairs \= [],
    % Sort list 'Pairs' into 'Sorted', keeping duplicates.
    msort(Pairs, Sorted),
    % Unify the second argument with the last element of list 'Sorted'.
    last(Sorted, _-PolicyName).

% Define a clause for 'ensure policy': succeed when the following conditions hold.
ensure_policy(RuleBase, PolicyName) :-
    % Execute: ( policy_record(RuleBase, PolicyName, _, _).
    ( policy_record(RuleBase, PolicyName, _, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(policy_record(RuleBase, PolicyName, 0, 0))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Internal: record chain outcome into a named policy
% ---------------------------------------------------------------------------

% Define a clause for 'record outcome': succeed when the following conditions hold.
record_outcome(_, default, _) :- !.
% Define a clause for 'record outcome': succeed when the following conditions hold.
record_outcome(RuleBase, Policy, Outcome) :-
    % State a fact for 'ensure policy' with the arguments listed below.
    ensure_policy(RuleBase, Policy),
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(policy_record(RuleBase, Policy, S0, A0)),
    % Evaluate the arithmetic expression 'A0 + 1' and bind the result to 'A1'.
    A1 is A0 + 1,
    % Check that '( Outcome' is unifiable with 'success -> S1 is S0 + 1 ; S1 = S0 )'.
    ( Outcome = success -> S1 is S0 + 1 ; S1 = S0 ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(policy_record(RuleBase, Policy, S1, A1)).
