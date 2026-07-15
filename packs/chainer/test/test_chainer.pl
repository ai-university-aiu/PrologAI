%% Declare this file as the 'test_chainer' module with no exported predicates.
:- module(test_chainer, []).

%% Load the built-in 'plunit' library so its test predicates are available here.
:- use_module(library(plunit)).
%% Import [memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists), [memberchk/2]).
%% Import [lattice_open/2, lattice_close/1] from the 'lattice' library.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
%% Import [set_default_nexus/1] from the 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
%% Load the 'chainer' library under test with its three exported predicates.
:- use_module(library(chainer), [
    %% Supply 'chainer_chain/5' as an imported predicate.
    chainer_chain/5,
    %% Supply 'chainer_rule_base/2' as an imported predicate.
    chainer_rule_base/2,
    %% Supply 'chainer_control_policy/3' as an imported predicate.
    chainer_control_policy/3
%% Close the import list opened above.
]).

%% Open the test block named 'chainer' with a shared setup and cleanup.
:- begin_tests(chainer, [setup(chainer_setup), cleanup(chainer_cleanup)]).

%% Define the setup step run before each test in this block.
chainer_setup :-
    %% Open an in-memory Lattice nexus at a test-local address, binding it to N.
    lattice_open('locus://localhost/test_chainer', N),
    %% Store the nexus reference so cleanup can close the same nexus later.
    nb_setval(test_chainer_nexus_ref, N),
    %% Make N the default nexus so anchor_node/4 writes rule bases into it.
    set_default_nexus(N),
    %% Clear any policy statistics left over from a previous test run.
    retractall(chainer:policy_record(_, _, _, _)).

%% Define the cleanup step run after each test in this block.
chainer_cleanup :-
    %% Retrieve the nexus reference stored during setup.
    nb_getval(test_chainer_nexus_ref, N),
    %% Clear any policy statistics accumulated during the test.
    retractall(chainer:policy_record(_, _, _, _)),
    %% Close the test nexus, releasing its stored node_facts.
    lattice_close(N).

%% Test that backward chaining builds a full provenance chain to a reachable goal.
test(backward_chain_reachable, [setup(chainer_setup)]) :-
    %% Register a three-link causal rule base: rain -> wet -> slippery.
    chainer_rule_base(rb_reach, [
        %% Seed the base fact that it is raining.
        fact(raining),
        %% Rule deriving wet ground from rain.
        rule(raining, wet_ground),
        %% Rule deriving a slippery road from wet ground.
        rule(wet_ground, slippery_road)
    %% Close the rule list opened above.
    ]),
    %% Backward-chain from the slippery_road goal within a generous budget.
    chainer_chain(backward, rb_reach, slippery_road, Result, [max_depth(5), max_steps(100)]),
    %% Assert the result is a proven chain carrying this rule base's provenance.
    Result = chain(provenance(rb_reach, Chain, _Depth, Steps)),
    %% Assert the returned chain terminates on the seeded base fact.
    assertion(memberchk(fact(raining), Chain)),
    %% Assert the chain records the final derivation step to the goal.
    assertion(memberchk(step(wet_ground, slippery_road), Chain)),
    %% Assert at least one inference step was consumed to reach the goal.
    assertion(Steps > 0).

%% Test that an unreachable goal yields no_chain naming the goal as the frontier.
test(backward_chain_unreachable, [setup(chainer_setup)]) :-
    %% Register a rule base with a single seeded fact and one rule.
    chainer_rule_base(rb_unreach, [fact(seed), rule(seed, midway)]),
    %% Backward-chain toward a goal that no fact or rule can establish.
    chainer_chain(backward, rb_unreach, no_such_goal, Result, [max_depth(5), max_steps(100)]),
    %% Assert the engine reports failure with the goal echoed as the frontier.
    assertion(Result == no_chain(frontier(no_such_goal))).

%% Test that a goal which is itself a base fact closes immediately with a fact node.
test(backward_chain_base_fact, [setup(chainer_setup)]) :-
    %% Register a rule base whose only content is one base fact.
    chainer_rule_base(rb_base, [fact(sunshine)]),
    %% Backward-chain for the base fact directly.
    chainer_chain(backward, rb_base, sunshine, Result, [max_depth(1), max_steps(10)]),
    %% Assert the chain is exactly the single fact node for the goal.
    assertion(Result == chain(provenance(rb_base, [fact(sunshine)], 1, 0))).

%% Test that forward chaining derives every downstream consequence of the base facts.
test(forward_chain_derives_all, [setup(chainer_setup)]) :-
    %% Register a three-link forward rule base seeded with rain.
    chainer_rule_base(rb_fwd, [
        %% Seed the base fact that it is raining.
        fact(rain),
        %% Rule deriving wet from rain.
        rule(rain, wet),
        %% Rule deriving slippery from wet.
        rule(wet, slippery)
    %% Close the rule list opened above.
    ]),
    %% Forward-chain to fixpoint from the base facts with no extra inputs.
    chainer_chain(forward, rb_fwd, [], Result, [max_steps(100)]),
    %% Assert the result is a proven chain carrying the derived-fact set.
    Result = chain(provenance(rb_fwd, Derived, _Depth, _Steps)),
    %% Assert the seed fact is present in the derived set.
    assertion(memberchk(rain, Derived)),
    %% Assert the first consequence was derived.
    assertion(memberchk(wet, Derived)),
    %% Assert the transitive consequence was derived.
    assertion(memberchk(slippery, Derived)).

%% Test that a too-shallow depth limit prevents proving a deep goal.
test(backward_chain_depth_limit, [setup(chainer_setup)]) :-
    %% Register a two-hop rule base: root -> mid -> leaf.
    chainer_rule_base(rb_deep, [
        %% Seed the base fact at the root.
        fact(root),
        %% Rule deriving the middle node from the root.
        rule(root, mid),
        %% Rule deriving the leaf from the middle node.
        rule(mid, leaf)
    %% Close the rule list opened above.
    ]),
    %% Backward-chain for the leaf, which needs depth two, under a depth-one cap.
    chainer_chain(backward, rb_deep, leaf, Result, [max_depth(1), max_steps(100)]),
    %% Assert the depth cap forces a no_chain result naming the leaf frontier.
    assertion(Result == no_chain(frontier(leaf))).

%% Test that distinct rule bases stay isolated and do not cross-contaminate.
test(rule_bases_isolated, [setup(chainer_setup)]) :-
    %% Register rule base X with its own fact and rule.
    chainer_rule_base(rb_x, [fact(x_seed), rule(x_seed, x_result)]),
    %% Register rule base Y with a different fact and rule.
    chainer_rule_base(rb_y, [fact(y_seed), rule(y_seed, y_result)]),
    %% X's result is reachable within X's own rule base.
    chainer_chain(backward, rb_x, x_result, R1, [max_depth(5)]),
    %% Assert that chain succeeds for X.
    assertion(R1 = chain(_)),
    %% X's result must NOT be reachable from Y's rule base.
    chainer_chain(backward, rb_y, x_result, R2, [max_depth(5)]),
    %% Assert Y cannot prove X's result, confirming isolation.
    assertion(R2 = no_chain(_)).

%% Test that querying a fresh named policy returns zeroed reliability statistics.
test(control_policy_fresh_stats, [setup(chainer_setup)]) :-
    %% Ask for stats on a policy name never used before against this rule base.
    chainer_control_policy(rb_pol, brand_new_policy, Stats),
    %% Assert a fresh policy reports zero successes, zero attempts, zero reliability.
    assertion(Stats == policy_stats(brand_new_policy, 0, 0, 0.0)).

%% Test that policy statistics update on outcomes and the better policy is preferred.
test(control_policy_prefers_reliable, [setup(chainer_setup)]) :-
    %% Register a two-hop rule base for policy exercising.
    chainer_rule_base(rb_prefer, [fact(pa), rule(pa, pb), rule(pb, pc)]),
    %% Declare a shallow policy and a deep policy against this rule base.
    chainer_control_policy(rb_prefer, shallow, _),
    %% Declare the deep policy.
    chainer_control_policy(rb_prefer, deep, _),
    %% Run the deep goal pc under the shallow depth-one policy, which fails each time.
    forall(between(1, 10, _),
           %% Attempt pc at depth one under the shallow policy.
           chainer_chain(backward, rb_prefer, pc, _, [max_depth(1), policy(shallow)])),
    %% Run the deep goal pc under the deep depth-five policy, which succeeds each time.
    forall(between(1, 10, _),
           %% Attempt pc at depth five under the deep policy.
           chainer_chain(backward, rb_prefer, pc, _, [max_depth(5), policy(deep)])),
    %% Read back the shallow policy's stats: ten attempts, fewer than ten successes.
    chainer_control_policy(rb_prefer, shallow, policy_stats(shallow, SShallow, 10, _)),
    %% Assert the shallow policy under-performed on this deep goal.
    assertion(SShallow < 10),
    %% Read back the deep policy's stats: ten attempts, all successful.
    chainer_control_policy(rb_prefer, deep, policy_stats(deep, 10, 10, _)),
    %% Ask the chainer for the best policy with the name left unbound.
    chainer_control_policy(rb_prefer, Best, _),
    %% Assert the chainer prefers the more reliable deep policy.
    assertion(Best == deep).

%% Close the test block named 'chainer'.
:- end_tests(chainer).
