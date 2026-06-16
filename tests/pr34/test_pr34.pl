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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/chainer/prolog'],        ChnPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ChnPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),   [member/2, memberchk/2]).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'chainer' library so its predicates are available here.
:- use_module(library(chainer), [
    % Supply 'pai_chain/5' as the next argument to the expression above.
    pai_chain/5,
    % Supply 'pai_rule_base/2' as the next argument to the expression above.
    pai_rule_base/2,
    % Supply 'pai_control_policy/3' as the next argument to the expression above.
    pai_control_policy/3
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr34, [setup(pr34_setup), cleanup(pr34_cleanup)]).
:- begin_tests(pr34, [setup(pr34_setup), cleanup(pr34_cleanup)]).

% Execute: pr34_setup :-.
pr34_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr34', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr34_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(chainer:policy_record(_, _, _, _)).

% Execute: pr34_cleanup :-.
pr34_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr34_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(chainer:policy_record(_, _, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR34-001: backward chain from current situation to goal with provenance;
%               returns no_chain for unreachable goals
% Define a clause for 'test': succeed when the following conditions hold.
test(backward_chain_causal, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_causal, [
        % Continue the multi-line expression started above.
        fact(is_raining),
        % Continue the multi-line expression started above.
        rule(is_raining, wet_ground),
        % Continue the multi-line expression started above.
        rule(wet_ground, slippery_road)
    % Close the expression opened above.
    ]),
    % Reachable goal
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_causal, slippery_road, Result1, [max_depth(5), max_steps(100)]),
    % Check that 'Result1' is unifiable with 'chain(provenance(rb34_causal, Chain, _, _))'.
    Result1 = chain(provenance(rb34_causal, Chain, _, _)),
    % Check that 'Chain' is not unifiable with '[]'.
    Chain \= [],
    % Unreachable goal
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_causal, sunshine, Result2, [max_depth(5), max_steps(100)]),
    % Check that 'Result2' is unifiable with 'no_chain(frontier(sunshine))'.
    Result2 = no_chain(frontier(sunshine)).

%  AC-PR34-002: two control policies; regulation updates stats; better policy preferred
% Define a clause for 'test': succeed when the following conditions hold.
test(control_policy_reliability, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_pol, [
        % Continue the multi-line expression started above.
        fact(a34),
        % Continue the multi-line expression started above.
        rule(a34, b34),
        % Continue the multi-line expression started above.
        rule(b34, c34)
    % Close the expression opened above.
    ]),
    % Declare two policies
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_pol, shallow34, _),
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_pol, deep34,    _),
    % 25 easy (b34, depth 1) + 25 hard (c34, depth 1 → fails) under shallow
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 25, _),
           % Continue the multi-line expression started above.
           pai_chain(backward, rb34_pol, b34, _, [max_depth(1), policy(shallow34)])),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 25, _),
           % Continue the multi-line expression started above.
           pai_chain(backward, rb34_pol, c34, _, [max_depth(1), policy(shallow34)])),
    % 50 hard (c34, depth 5 → succeeds) under deep
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 50, _),
           % Continue the multi-line expression started above.
           pai_chain(backward, rb34_pol, c34, _, [max_depth(5), policy(deep34)])),
    % Stats updated: shallow < 50 successes, deep = 50 successes
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_pol, shallow34, policy_stats(shallow34, S1, 50, _)),
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_pol, deep34,    policy_stats(deep34,    50, 50, _)),
    % Check that 'S1' is less than '50'.
    S1 < 50,
    % Chainer prefers deep34 (higher reliability)
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_pol, BestPolicy, _),
    % Check that 'BestPolicy' is unifiable with 'deep34'.
    BestPolicy = deep34.

%  AC-PR34-003: backward chain succeeds when goal is a direct base fact
% Define a clause for 'test': succeed when the following conditions hold.
test(backward_chain_base_fact, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_base, [fact(sunshine34)]),
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_base, sunshine34, Result, [max_depth(1), max_steps(10)]),
    % Check that 'Result' is unifiable with 'chain(provenance(rb34_base, [fact(sunshine34)], _, _))'.
    Result = chain(provenance(rb34_base, [fact(sunshine34)], _, _)).

%  AC-PR34-004: forward chaining derives all consequences from base facts
% Define a clause for 'test': succeed when the following conditions hold.
test(forward_chain_derives_consequences, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_fwd, [
        % Continue the multi-line expression started above.
        fact(rain34),
        % Continue the multi-line expression started above.
        rule(rain34, wet34),
        % Continue the multi-line expression started above.
        rule(wet34,  slippery34)
    % Close the expression opened above.
    ]),
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(forward, rb34_fwd, [], Result, [max_steps(100)]),
    % Check that 'Result' is unifiable with 'chain(provenance(rb34_fwd, Derived, _, _))'.
    Result = chain(provenance(rb34_fwd, Derived, _, _)),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(rain34,     Derived),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(wet34,      Derived),
    % State the fact: memberchk(slippery34, Derived).
    memberchk(slippery34, Derived).

%  AC-PR34-005: backward chain returns no_chain when depth limit is too low
% Define a clause for 'test': succeed when the following conditions hold.
test(backward_chain_depth_limit, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_deep, [
        % Continue the multi-line expression started above.
        fact(root34),
        % Continue the multi-line expression started above.
        rule(root34, mid34),
        % Continue the multi-line expression started above.
        rule(mid34,  leaf34)
    % Close the expression opened above.
    ]),
    % leaf34 needs depth 2; limit to 1 → no_chain
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_deep, leaf34, Result, [max_depth(1), max_steps(100)]),
    % Check that 'Result' is unifiable with 'no_chain(frontier(leaf34))'.
    Result = no_chain(frontier(leaf34)).

%  AC-PR34-006: max_steps budget is respected
% Define a clause for 'test': succeed when the following conditions hold.
test(budget_respected, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_budg, [
        % Continue the multi-line expression started above.
        fact(seed34),
        % Continue the multi-line expression started above.
        rule(seed34, s134),
        % Continue the multi-line expression started above.
        rule(s134,   s234),
        % Continue the multi-line expression started above.
        rule(s234,   s334),
        % Continue the multi-line expression started above.
        rule(s334,   s434),
        % Continue the multi-line expression started above.
        rule(s434,   s534)
    % Close the expression opened above.
    ]),
    % goal s534 needs 5 steps; budget = 3 → no_chain
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_budg, s534, Result, [max_depth(10), max_steps(3)]),
    % Check that 'Result' is unifiable with 'no_chain(_)'.
    Result = no_chain(_).

%  AC-PR34-007: provenance records rule base, chain list, depth, steps used
% Define a clause for 'test': succeed when the following conditions hold.
test(provenance_complete, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_prov, [fact(p_start), rule(p_start, p_goal)]),
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_prov, p_goal, Result, [max_depth(5), max_steps(100)]),
    % Check that 'Result' is unifiable with 'chain(provenance(rb34_prov, Chain, _MaxD, Steps))'.
    Result = chain(provenance(rb34_prov, Chain, _MaxD, Steps)),
    % Check that 'Chain' is unifiable with '[step(p_start, p_goal), fact(p_start)]'.
    Chain = [step(p_start, p_goal), fact(p_start)],
    % Check that 'Steps' is greater than '0'.
    Steps > 0.

%  AC-PR34-008: multiple rule bases do not contaminate each other
% Define a clause for 'test': succeed when the following conditions hold.
test(rule_bases_isolated, [setup(pr34_setup)]) :-
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_x, [fact(x34), rule(x34, x_result34)]),
    % State a fact for 'pai rule base' with the arguments listed below.
    pai_rule_base(rb34_y, [fact(y34), rule(y34, y_result34)]),
    % x_result34 reachable from rb34_x
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_x, x_result34, R1, [max_depth(5)]),
    % Check that 'R1' is unifiable with 'chain(_)'.
    R1 = chain(_),
    % x_result34 NOT reachable from rb34_y
    % State a fact for 'pai chain' with the arguments listed below.
    pai_chain(backward, rb34_y, x_result34, R2, [max_depth(5)]),
    % Check that 'R2' is unifiable with 'no_chain(_)'.
    R2 = no_chain(_).

%  AC-PR34-009: pai_control_policy returns stats for a named policy
% Define a clause for 'test': succeed when the following conditions hold.
test(control_policy_stats, [setup(pr34_setup)]) :-
    % State a fact for 'pai control policy' with the arguments listed below.
    pai_control_policy(rb34_q, my_policy34, Stats),
    % Check that 'Stats' is unifiable with 'policy_stats(my_policy34, 0, 0, 0.0)'.
    Stats = policy_stats(my_policy34, 0, 0, 0.0).

% Execute the compile-time directive: end_tests(pr34).
:- end_tests(pr34).
