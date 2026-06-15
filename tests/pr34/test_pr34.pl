/*  PrologAI — PR 34 Generic Chainer and Meta-Reasoning Acceptance Tests

    AC-PR34-001: Given a causal rule base and a goal state, when pai_chain is
                 run backward within budget, then a chain from current situation
                 to goal is returned with full provenance, or no_chain with the
                 frontier reached.
    AC-PR34-002: Given two control policies for one rule base, when 50 mixed
                 problems run under each, then regulation updates the policies'
                 reliability statistics and the chainer prefers the better
                 policy thereafter.
    AC-PR34-003: Backward chain succeeds when goal is a direct base fact.
    AC-PR34-004: Forward chaining derives all consequences from initial facts.
    AC-PR34-005: Backward chain returns no_chain when depth limit exceeded.
    AC-PR34-006: Budget (max_steps) is respected.
    AC-PR34-007: Provenance records rule base, chain, depth, and steps used.
    AC-PR34-008: Multiple rule bases coexist without cross-contamination.
    AC-PR34-009: pai_control_policy returns stats for a named policy.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/chainer/prolog'],        ChnPath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, ChnPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),   [member/2, memberchk/2]).
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(chainer), [
    pai_chain/5,
    pai_rule_base/2,
    pai_control_policy/3
]).

:- begin_tests(pr34, [setup(pr34_setup), cleanup(pr34_cleanup)]).

pr34_setup :-
    lattice_open('locus://localhost/pr34', N),
    nb_setval(pr34_nexus_ref, N),
    set_default_nexus(N),
    retractall(chainer:policy_record(_, _, _, _)).

pr34_cleanup :-
    nb_getval(pr34_nexus_ref, N),
    retractall(chainer:policy_record(_, _, _, _)),
    lattice_close(N).

%  AC-PR34-001: backward chain from current situation to goal with provenance;
%               returns no_chain for unreachable goals
test(backward_chain_causal, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_causal, [
        fact(is_raining),
        rule(is_raining, wet_ground),
        rule(wet_ground, slippery_road)
    ]),
    % Reachable goal
    pai_chain(backward, rb34_causal, slippery_road, Result1, [max_depth(5), max_steps(100)]),
    Result1 = chain(provenance(rb34_causal, Chain, _, _)),
    Chain \= [],
    % Unreachable goal
    pai_chain(backward, rb34_causal, sunshine, Result2, [max_depth(5), max_steps(100)]),
    Result2 = no_chain(frontier(sunshine)).

%  AC-PR34-002: two control policies; regulation updates stats; better policy preferred
test(control_policy_reliability, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_pol, [
        fact(a34),
        rule(a34, b34),
        rule(b34, c34)
    ]),
    % Declare two policies
    pai_control_policy(rb34_pol, shallow34, _),
    pai_control_policy(rb34_pol, deep34,    _),
    % 25 easy (b34, depth 1) + 25 hard (c34, depth 1 → fails) under shallow
    forall(between(1, 25, _),
           pai_chain(backward, rb34_pol, b34, _, [max_depth(1), policy(shallow34)])),
    forall(between(1, 25, _),
           pai_chain(backward, rb34_pol, c34, _, [max_depth(1), policy(shallow34)])),
    % 50 hard (c34, depth 5 → succeeds) under deep
    forall(between(1, 50, _),
           pai_chain(backward, rb34_pol, c34, _, [max_depth(5), policy(deep34)])),
    % Stats updated: shallow < 50 successes, deep = 50 successes
    pai_control_policy(rb34_pol, shallow34, policy_stats(shallow34, S1, 50, _)),
    pai_control_policy(rb34_pol, deep34,    policy_stats(deep34,    50, 50, _)),
    S1 < 50,
    % Chainer prefers deep34 (higher reliability)
    pai_control_policy(rb34_pol, BestPolicy, _),
    BestPolicy = deep34.

%  AC-PR34-003: backward chain succeeds when goal is a direct base fact
test(backward_chain_base_fact, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_base, [fact(sunshine34)]),
    pai_chain(backward, rb34_base, sunshine34, Result, [max_depth(1), max_steps(10)]),
    Result = chain(provenance(rb34_base, [fact(sunshine34)], _, _)).

%  AC-PR34-004: forward chaining derives all consequences from base facts
test(forward_chain_derives_consequences, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_fwd, [
        fact(rain34),
        rule(rain34, wet34),
        rule(wet34,  slippery34)
    ]),
    pai_chain(forward, rb34_fwd, [], Result, [max_steps(100)]),
    Result = chain(provenance(rb34_fwd, Derived, _, _)),
    memberchk(rain34,     Derived),
    memberchk(wet34,      Derived),
    memberchk(slippery34, Derived).

%  AC-PR34-005: backward chain returns no_chain when depth limit is too low
test(backward_chain_depth_limit, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_deep, [
        fact(root34),
        rule(root34, mid34),
        rule(mid34,  leaf34)
    ]),
    % leaf34 needs depth 2; limit to 1 → no_chain
    pai_chain(backward, rb34_deep, leaf34, Result, [max_depth(1), max_steps(100)]),
    Result = no_chain(frontier(leaf34)).

%  AC-PR34-006: max_steps budget is respected
test(budget_respected, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_budg, [
        fact(seed34),
        rule(seed34, s134),
        rule(s134,   s234),
        rule(s234,   s334),
        rule(s334,   s434),
        rule(s434,   s534)
    ]),
    % goal s534 needs 5 steps; budget = 3 → no_chain
    pai_chain(backward, rb34_budg, s534, Result, [max_depth(10), max_steps(3)]),
    Result = no_chain(_).

%  AC-PR34-007: provenance records rule base, chain list, depth, steps used
test(provenance_complete, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_prov, [fact(p_start), rule(p_start, p_goal)]),
    pai_chain(backward, rb34_prov, p_goal, Result, [max_depth(5), max_steps(100)]),
    Result = chain(provenance(rb34_prov, Chain, _MaxD, Steps)),
    Chain = [step(p_start, p_goal), fact(p_start)],
    Steps > 0.

%  AC-PR34-008: multiple rule bases do not contaminate each other
test(rule_bases_isolated, [setup(pr34_setup)]) :-
    pai_rule_base(rb34_x, [fact(x34), rule(x34, x_result34)]),
    pai_rule_base(rb34_y, [fact(y34), rule(y34, y_result34)]),
    % x_result34 reachable from rb34_x
    pai_chain(backward, rb34_x, x_result34, R1, [max_depth(5)]),
    R1 = chain(_),
    % x_result34 NOT reachable from rb34_y
    pai_chain(backward, rb34_y, x_result34, R2, [max_depth(5)]),
    R2 = no_chain(_).

%  AC-PR34-009: pai_control_policy returns stats for a named policy
test(control_policy_stats, [setup(pr34_setup)]) :-
    pai_control_policy(rb34_q, my_policy34, Stats),
    Stats = policy_stats(my_policy34, 0, 0, 0.0).

:- end_tests(pr34).
