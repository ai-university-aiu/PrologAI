/*  PrologAI — Situational Awareness Test Suite  (PR 51)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/awareness/test/test_awareness.pl

    Exercises the core evolving-regards behaviour: the developmental ladder,
    the active standpoint, holding and querying propositions, theory-of-mind
    attribution and divergence, and avowed/disavowed reconciliation.
*/

% Declare this file as a test module with no exports.
:- module(test_awareness, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the awareness module under test from the library path.
:- use_module(library(awareness)).

% Open the test block for awareness.
:- begin_tests(awareness).

% AC-AW-001: the ladder lists the five standing kinds in developmental order.
test(ladder_order) :-
    % Read the standing regard kinds.
    awareness_regard_kinds(Kinds),
    % Confirm the exact ladder order, ambient through disavowed.
    assertion(Kinds == [ambient_regard, selfward_regard, otherward_regard,
                        avowed_regard, disavowed_regard]).

% AC-AW-002: the default active standpoint is ambient awareness.
test(default_active) :-
    % Query the current active standpoint.
    awareness_regard_active(R),
    % Confirm it defaults to ambient_regard on a freshly booted mind.
    assertion(R == ambient_regard).

% AC-AW-003: a held proposition can be queried back under its regard.
test(hold_and_query) :-
    % Hold a preference under the self-interested regard.
    awareness_regard_hold(selfward_regard, prefers(charging)),
    % Confirm the same proposition reads back under that regard.
    assertion(awareness_regard_held(selfward_regard, prefers(charging))).

% AC-AW-004: shifting the standpoint changes the active regard, then restores it.
test(shift_active) :-
    % Shift the standpoint to the owned (avowed) regard.
    awareness_regard_shift(avowed_regard),
    % Read the active standpoint after the shift.
    awareness_regard_active(Shifted),
    % Confirm the active standpoint moved to the avowed regard.
    assertion(Shifted == avowed_regard),
    % Restore the ambient standpoint to avoid cross-test interference.
    awareness_regard_shift(ambient_regard),
    % Confirm the ambient standpoint is restored.
    assertion(awareness_regard_active(ambient_regard)).

% AC-AW-005: the developmental levels strictly increase along the ladder.
test(level_ordering) :-
    % Read the ambient general-awareness level.
    awareness_regard_level(ambient_regard, L1),
    % Read the self-interested level.
    awareness_regard_level(selfward_regard, L2),
    % Read the theory-of-mind level for a named other.
    awareness_regard_level(otherward_regard(alice), L3),
    % Read the owned (avowed) level.
    awareness_regard_level(avowed_regard, L4),
    % Read the disowned (disavowed) level.
    awareness_regard_level(disavowed_regard, L5),
    % Confirm the level indices strictly increase up the ladder.
    assertion((L1 < L2, L2 < L3, L3 < L4, L4 < L5)).

% AC-AW-006: a belief can be attributed to another mind's otherward regard.
test(tom_attribute) :-
    % Attribute a location belief to agent alice.
    awareness_tom_attribute(alice, location(ball, basket)),
    % Confirm it is held under alice's own otherward viewpoint.
    assertion(awareness_regard_held(otherward_regard(alice), location(ball, basket))).

% AC-AW-007: a false belief surfaces as a divergence between self and other.
test(tom_false_belief) :-
    % The self believes the ball is in the box.
    awareness_regard_hold(selfward_regard, location(ball, box)),
    % The self models bob as believing it is NOT in the box.
    awareness_tom_attribute(bob, not(location(ball, box))),
    % Compute the divergences between the self view and bob's view.
    awareness_tom_divergence(bob, Divs),
    % Confirm the contradictory pair is surfaced.
    assertion(member(divergence(location(ball, box), not(location(ball, box))), Divs)).

% AC-AW-008: agreement between self and other yields no divergence.
test(tom_agreement) :-
    % The self believes the sky is clear.
    awareness_regard_hold(selfward_regard, weather(clear)),
    % Agent carol is modelled as agreeing the sky is clear.
    awareness_tom_attribute(carol, weather(clear)),
    % Compute the divergences with carol.
    awareness_tom_divergence(carol, Divs),
    % Confirm no contradiction over the weather proposition is reported.
    assertion(\+ member(divergence(weather(clear), _), Divs)).

% AC-AW-009: reconciliation integrates owned and disowned material into one account.
test(reconcile) :-
    % The mind owns a value under the avowed regard.
    awareness_regard_hold(avowed_regard, values(helpfulness)),
    % The mind disowns an aversion under the disavowed regard.
    awareness_regard_hold(disavowed_regard, avoids(conflict)),
    % Reconcile the owned and disowned views into one self-account.
    awareness_regard_reconcile(Integrated),
    % Confirm the owned material is present, tagged as avowed.
    assertion(member(avowed(values(helpfulness)), Integrated)),
    % Confirm the disowned material is surfaced, tagged as disavowed.
    assertion(member(disavowed(avoids(conflict)), Integrated)).

% AC-AW-010: opening an otherward regard with an unbound agent is rejected.
test(reject_ungrounded_other, [fail]) :-
    % Attempt to open an otherward regard for an unbound agent; this must fail.
    awareness_regard_open(otherward_regard(_Unbound)).

% Close the test block for awareness.
:- end_tests(awareness).
