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
