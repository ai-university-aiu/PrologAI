/*  PrologAI — Membership Contract test suite  (N8, closes ARBITER-1)

    Confirms the acceptance criteria: a member passes, the declared abstention
    passes, a non-member is REFUSED with a readable glass-box violation (the
    non-member is never returned), an unguarded predicate is unaffected, and the
    arbiter's hand-rolled membership guard is re-expressible by DECLARING the
    contract — PrologAI-side, without touching the frozen arbiter repository.
*/

% Declare this file as a test module.
:- module(test_membership_contract, []).
% Load the construct under test from the library path.
:- use_module(library(membership_contract)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Import member/2 and memberchk/2 for the assertions.
:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Guarded and unguarded demo predicates.
% ---------------------------------------------------------------------------

% A toy GUARDED selector: it returns whatever it is told to pick (a member, the
% abstention, or — if the mechanism failed — a non-member), so the contract, not
% the predicate, is what stops a non-member.
demo_select(_Offered, Pick, Pick).
% Enforce the contract: argument 3 (the output) must be a member of argument 1 (the
% offered set), or the declared abstention 'no_selection'.
:- membership_contract_enforce(demo_select/3, 3, 1, no_selection).

% A toy UNGUARDED selector: no contract is declared, so it behaves exactly as today.
demo_unguarded(_Offered, Pick, Pick).

% THE ARBITER RE-EXPRESSION: a selector standing in for a FUTURE region, whose
% membership guarantee is obtained purely by DECLARING the contract — a selection
% must be a member of the offered candidates, with an explicit no-selection allowed
% — rather than hand-rolling a guard, a throwing emit, and a battery.
region_action_select(_OfferedActions, Preference, Preference).
% Declare the arbiter's guarantee as a contract; nothing else is written.
:- membership_contract_enforce(region_action_select/3, 3, 1, no_selection).

% Open the test block for the membership contract.
:- begin_tests(membership_contract).

% AC-N8-001: a call that produces a MEMBER passes and returns it.
test(member_passes) :-
    % Selecting an offered action returns it.
    demo_select([reach, grasp, withdraw], grasp, R),
    assertion(R == grasp).

% AC-N8-002: a call that produces the declared ABSTENTION passes.
test(abstention_passes) :-
    % Choosing nothing (the declared no_selection) is legal.
    demo_select([reach, grasp], no_selection, R),
    assertion(R == no_selection).

% AC-N8-003: a call that produces a NON-member is REFUSED — the non-member is never returned.
test(non_member_refused, [throws(error(membership_contract_violation(_, teleport, _), _))]) :-
    % Trying to emit an action nobody offered raises the glass-box violation.
    demo_select([reach, grasp], teleport, _R).

% AC-N8-004: an UNGUARDED predicate is unaffected — no contract, no check, identical behaviour.
test(unguarded_unaffected) :-
    % Without a contract, the same shape of predicate returns a non-member freely (no check imposed).
    demo_unguarded([reach, grasp], teleport, R),
    assertion(R == teleport).

% AC-N8-005: the pure postcondition succeeds on a member / abstention and throws on a non-member.
test(pure_postcondition) :-
    % A member satisfies the check.
    membership_contract_check(p/3, grasp, [reach, grasp], no_selection),
    % The abstention satisfies the check.
    membership_contract_check(p/3, no_selection, [reach, grasp], no_selection),
    % A non-member throws the glass-box violation.
    assertion(catch(membership_contract_check(p/3, ghost, [reach, grasp], no_selection),
                    error(membership_contract_violation(_, ghost, _), _), true)).

% AC-N8-006: the boolean sibling never throws — true for members/abstention, false for a non-member.
test(boolean_holds) :-
    % A member holds.
    membership_contract_holds(grasp, [reach, grasp], no_selection),
    % The abstention holds.
    membership_contract_holds(no_selection, [reach, grasp], no_selection),
    % A non-member does NOT hold (and does not throw).
    \+ membership_contract_holds(ghost, [reach, grasp], no_selection).

% AC-N8-007: the declared contract is introspectable through the registry.
test(declared_registry) :-
    % The demo_select contract is recorded with its output/input positions and abstention.
    membership_contract_declared(_M:(demo_select/3), 3, 1, no_selection).

% AC-N8-008: a violation renders a readable, glass-box line.
test(violation_line_readable) :-
    % Build a violation error and render it.
    Err = error(membership_contract_violation(demo_select/3, ghost, [reach, grasp]), membership_contract),
    membership_contract_violation_line(Err, Line),
    % The line names the violation, the offending output, and the offered set.
    assertion(sub_atom(Line, _, _, _, 'membership_contract violation')),
    assertion(sub_atom(Line, _, _, _, 'ghost')).

% AC-N8-009 (THE RE-EXPRESSION): the arbiter's guarantee holds for a future selector BY DECLARATION.
% A member passes, the explicit no-selection passes, and a non-member is refused —
% exactly the arbiter's membership invariant, obtained here without hand-rolling it.
test(arbiter_guarantee_by_declaration) :-
    % A member of the offered actions is selected.
    region_action_select([reach, grasp, withdraw], withdraw, S1),
    assertion(S1 == withdraw),
    % An explicit no-selection is allowed.
    region_action_select([reach, grasp], no_selection, S2),
    assertion(S2 == no_selection),
    % An action nobody offered is refused — the guarantee holds with no hand-rolled guard.
    assertion(catch(region_action_select([reach, grasp], phantom, _),
                    error(membership_contract_violation(_, phantom, _), _), true)).

% Close the test block.
:- end_tests(membership_contract).

% ===========================================================================
% THE ACCESSOR FORM — membership against a GOAL-described set (N11, closes N9).
% ===========================================================================

% A stand-in for the hippocampus store: memories held as independent FACTS, not a list.
stored_pattern([circle, red, small]).
stored_pattern([blue, large, square]).
stored_pattern([green, small, triangle]).

% The MEMBERSHIP-TEST goal: succeeds for a candidate that is a stored memory — a single
% fact lookup, NOT a list build. This is the goal the accessor test-goal form names.
stored_pattern_member(Pattern) :-
    % A candidate is a member exactly when it is a stored_pattern fact.
    stored_pattern(Pattern).

% A materialisation counter, to PROVE the test-goal form never flattens the store.
:- dynamic accessor_materialise_count/1.
% The counter starts at zero.
accessor_materialise_count(0).
% Reset the counter before a test that asserts on it.
accessor_reset_materialise :-
    % Clear and re-seed the counter to zero.
    retractall(accessor_materialise_count(_)), assertz(accessor_materialise_count(0)).
% Increment the counter by one (called ONLY by the list producer, never by the test goal).
accessor_bump_materialise :-
    % Read, increment, and store the counter.
    retract(accessor_materialise_count(N)), N1 is N + 1, assertz(accessor_materialise_count(N1)).

% The list-PRODUCER goal: builds the whole store as a list (the O(store size) copy the
% test-goal form avoids). It bumps the counter so a test can prove whether it ran.
stored_pattern_list(List) :-
    % Record that a full materialisation happened, then flatten the store into a list.
    accessor_bump_materialise,
    findall(P, stored_pattern(P), List).

% A recall-like predicate over the fact store: argument 1 injects the output to test
% (standing in for what completion would produce), argument 2 is the guarded output.
% The contract, not this predicate, is what refuses a non-member.
store_recall(Pick, Pick).
% Declare the ACCESSOR TEST-GOAL contract: argument 2 must satisfy stored_pattern_member, or be no_recall.
:- membership_contract_enforce_goal(store_recall/2, 2, stored_pattern_member, no_recall).

% The SAME recall shape guarded by the PRODUCER form (the convenience that materialises).
store_recall_producer(Pick, Pick).
% Declare the ACCESSOR PRODUCER contract: argument 2 must be a member of the list stored_pattern_list builds.
:- membership_contract_enforce_producer(store_recall_producer/2, 2, stored_pattern_list, no_recall).

% An UNMATERIALISABLE (infinite) set: the positive even integers. There is NO list to build.
is_positive_even(N) :-
    % A candidate is in the set when it is a positive even integer.
    integer(N), N > 0, 0 is N mod 2.

% A picker guarded against the infinite even-number set by the test-goal form.
pick_even(Pick, Pick).
% Declare the contract against the infinite set; the abstention is 'none'.
:- membership_contract_enforce_goal(pick_even/2, 2, is_positive_even, none).

% Open the test block for the accessor form.
:- begin_tests(membership_contract_accessor).

% AC-N11-001: a call whose output the test goal ACCEPTS passes (a member of the fact store).
test(accessor_member_passes) :-
    store_recall([circle, red, small], R),
    assertion(R == [circle, red, small]).

% AC-N11-002: a call producing the declared abstention passes.
test(accessor_abstention_passes) :-
    store_recall(no_recall, R),
    assertion(R == no_recall).

% AC-N11-003: a call whose output the test goal REJECTS is refused with a glass-box goal violation.
test(accessor_non_member_refused,
     [throws(error(membership_contract_goal_violation(_, [phantom], _), _))]) :-
    store_recall([phantom], _R).

% AC-N11-004: the test-goal form NEVER materialises the store — the producer counter stays zero.
test(accessor_no_materialisation) :-
    accessor_reset_materialise,
    % Exercise several recalls through the test-goal-guarded predicate, including a refused one.
    store_recall([circle, red, small], _),
    store_recall(no_recall, _),
    catch(store_recall([phantom], _), error(membership_contract_goal_violation(_, _, _), _), true),
    % No full-store list was ever built.
    accessor_materialise_count(C),
    assertion(C == 0).

% AC-N11-005: the accessor form guards membership against an INFINITE set no list could hold.
test(accessor_infinite_set) :-
    % An even number is accepted.
    pick_even(4, R1), assertion(R1 == 4),
    % The abstention is accepted.
    pick_even(none, R2), assertion(R2 == none),
    % An odd number is refused — with no list ever built (the set is infinite).
    assertion(catch(pick_even(7, _), error(membership_contract_goal_violation(_, 7, _), _), true)).

% AC-N11-006: the PRODUCER form works too — and it DOES materialise (the counter rises).
test(accessor_producer_materialises) :-
    accessor_reset_materialise,
    % A member passes.
    store_recall_producer([blue, large, square], R), assertion(R == [blue, large, square]),
    % A non-member is refused (with the plain-list violation, since the producer built the list).
    assertion(catch(store_recall_producer([phantom], _),
                    error(membership_contract_violation(_, [phantom], _), _), true)),
    % The producer DID flatten the store — the counter rose above zero (unlike the test-goal form).
    accessor_materialise_count(C),
    assertion(C > 0).

% AC-N11-007: the pure test-goal postcondition succeeds on a member/abstention and throws on a non-member.
test(accessor_pure_check) :-
    membership_contract_check_goal(p/2, 4, is_positive_even, none),
    membership_contract_check_goal(p/2, none, is_positive_even, none),
    assertion(catch(membership_contract_check_goal(p/2, 7, is_positive_even, none),
                    error(membership_contract_goal_violation(_, 7, _), _), true)).

% AC-N11-008: the boolean test-goal sibling never throws — true for member/abstention, false otherwise.
test(accessor_holds_goal) :-
    membership_contract_holds_goal(4, is_positive_even, none),
    membership_contract_holds_goal(none, is_positive_even, none),
    \+ membership_contract_holds_goal(7, is_positive_even, none).

% AC-N11-009: the declared accessor contracts are introspectable (test and producer forms).
test(accessor_declared) :-
    membership_contract_declared_goal(_:(store_recall/2), 2, test, no_recall),
    membership_contract_declared_goal(_:(store_recall_producer/2), 2, producer, no_recall).

% AC-N11-010: a test-goal violation renders a readable line that NAMES the set goal (there is no list to print).
test(accessor_violation_line_readable) :-
    Err = error(membership_contract_goal_violation(store_recall/2, [phantom], stored_pattern_member), membership_contract),
    membership_contract_violation_line(Err, Line),
    assertion(sub_atom(Line, _, _, _, 'membership-test goal')),
    assertion(sub_atom(Line, _, _, _, 'stored_pattern_member')).

% AC-N11-011 (THE HIPPOCAMPUS RE-EXPRESSION): a recall over a fact store obtains the no-confabulation
% guarantee by DECLARING the accessor test-goal form, with NO flattening — so the materialize-at-boundary
% workaround (HIPPO-1) becomes unnecessary. A member passes, the explicit no_recall passes, a phantom is
% refused, and the store is never materialised.
test(accessor_hippocampus_reexpression) :-
    accessor_reset_materialise,
    % A genuinely stored memory is recalled (member).
    store_recall([green, small, triangle], S1), assertion(S1 == [green, small, triangle]),
    % An explicit no-recall is allowed.
    store_recall(no_recall, S2), assertion(S2 == no_recall),
    % A memory nobody stored is refused — no confabulation.
    assertion(catch(store_recall([never, stored], _),
                    error(membership_contract_goal_violation(_, [never, stored], _), _), true)),
    % And the whole guarantee was obtained WITHOUT ever flattening the store.
    accessor_materialise_count(C), assertion(C == 0).

% Close the accessor test block.
:- end_tests(membership_contract_accessor).

% ===========================================================================
% THE ONCE / DETERMINISTIC MODE — guard the COMMITTED single answer (N14, closes N12/N10).
% ===========================================================================

% A nondeterministic generator that yields several candidates on backtracking (a, b, c).
once_gen(_Allowed, C) :- member(C, [a, b, c]).
% Declare it in ONCE mode: argument 2 (output) must be a member of argument 1 (the allowed list); commit the first.
:- membership_contract_enforce(once_gen/2, 2, 1, no_choice, once).

% The SAME generator in the default per-solution mode, for contrast.
per_solution_gen(_Allowed, C) :- member(C, [a, b, c]).
% Declare it in the explicit per-solution mode (identical to the default enforce/4 behaviour).
:- membership_contract_enforce(per_solution_gen/2, 2, 1, no_choice, per_solution).

% A generator whose FIRST solution is a non-member (ghost), whose second would be a member (a).
once_gen_badfirst(_Allowed, C) :- member(C, [ghost, a]).
% Declare it in ONCE mode; once mode commits to the first solution (ghost) and refuses it.
:- membership_contract_enforce(once_gen_badfirst/2, 2, 1, no_choice, once).

% A once-mode plain-list predicate whose first solution is the declared abstention.
once_abstain(_Allowed, C) :- member(C, [no_choice, a]).
% Declare it in ONCE mode.
:- membership_contract_enforce(once_abstain/2, 2, 1, no_choice, once).

% A selector-like predicate over the fact store: it generates several candidates and commits the first,
% guarded in ONCE plus the TEST-GOAL accessor form (reusing stored_pattern_member), so NO set is materialised.
once_propose_stored(_Cue, P) :- member(P, [[circle, red, small], [phantom]]).
% Declare it in ONCE mode against the membership-test goal; abstention no_recall.
:- membership_contract_enforce_goal(once_propose_stored/2, 2, stored_pattern_member, no_recall, once).

% Open the test block for the once mode.
:- begin_tests(membership_contract_once).

% AC-N14-001: once mode returns exactly ONE solution (the committed first), deterministically.
test(once_commits_single) :-
    findall(C, once_gen([a,b,c], C), Cs),
    assertion(Cs == [a]).

% AC-N14-002: the per-solution DEFAULT still yields every solution (contrast; default unchanged).
test(per_solution_default_all) :-
    findall(C, per_solution_gen([a,b,c], C), Cs),
    assertion(Cs == [a,b,c]).

% AC-N14-003: once mode checks the committed member and passes.
test(once_member_passes) :-
    once_gen([a,b,c], C), assertion(C == a).

% AC-N14-004: once mode returns the abstention when it is the committed first solution.
test(once_abstention_passes) :-
    once_abstain([x,y], C), assertion(C == no_choice).

% AC-N14-005: once mode REFUSES when the committed FIRST solution is a non-member — even though a later solution would be a member.
test(once_refuses_nonmember_first,
     [throws(error(membership_contract_violation(_, ghost, _), _))]) :-
    once_gen_badfirst([a], _C).

% AC-N14-006: once plus the TEST-GOAL accessor form checks the committed output against the goal and materialises NOTHING.
test(once_accessor_no_materialisation) :-
    accessor_reset_materialise,
    once_propose_stored(cue, P),
    assertion(P == [circle, red, small]),
    accessor_materialise_count(N),
    assertion(N == 0).

% AC-N14-007: the declared mode is introspectable (once for a once contract, per_solution for a default one).
test(once_declared_mode) :-
    once(membership_contract_declared_mode(_:(once_gen/2), M1)), assertion(M1 == once),
    once(membership_contract_declared_mode(_:(per_solution_gen/2), M2)), assertion(M2 == per_solution).

% AC-N14-008: an unrecognised mode is a clear usage error.
test(once_invalid_mode_rejected,
     [throws(error(domain_error(membership_contract_mode, bogus), _))]) :-
    assertz((tmp_mode_pred(_, X) :- X = a)),
    membership_contract_enforce(tmp_mode_pred/2, 2, 1, none, bogus).

% AC-N14-009 (THE SELECTOR-LIKE RE-EXPRESSION): a predicate that generates several candidates and commits one
% obtains the "committed output is a member" guarantee by declaring once mode, with NO caller-supplied once/1.
test(once_selector_reexpression) :-
    % Exactly one committed answer comes back, deterministically.
    findall(C, once_gen([a,b,c], C), [Committed]),
    assertion(Committed == a),
    % And that committed answer is provably a member of the allowable set.
    memberchk(Committed, [a,b,c]).

% Close the once-mode test block.
:- end_tests(membership_contract_once).
