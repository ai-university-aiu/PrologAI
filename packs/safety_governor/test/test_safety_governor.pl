/*  PrologAI — Causalontology Safety Governor Test Suite  (WP-414)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/safety_governor/test/test_safety_governor.pl
*/

% Declare this file as a test module.
:- module(test_safety_governor, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(safety_governor)).

% Open the test block.
:- begin_tests(safety_governor).

% An action matching a constraint is vetoed with its reason.
test(veto_with_reason) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(touch(spike), sharp_and_harmful),
    safety_governor:safety_governor_check(touch(spike), Verdict),
    assertion(Verdict == veto(sharp_and_harmful)).

% An unrelated action is allowed.
test(allow_unrelated) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(touch(spike), harmful),
    safety_governor:safety_governor_check(press(button), Verdict),
    assertion(Verdict == allow).

% A constraint pattern with a variable bans a whole family of actions.
test(pattern_family) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(touch(_), no_touching),
    assertion(safety_governor:safety_governor_forbidden(touch(anything))),
    assertion(safety_governor:safety_governor_forbidden(touch(fire))).

% A learned hazard mirrored from causal_core is enforced.
test(learned_hazard) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_avoid_add(step_on(lava)),
    safety_governor:safety_governor_check(step_on(lava), Verdict),
    assertion(Verdict == veto(learned_hazard)).

% permit succeeds for allowed actions and fails for forbidden ones.
test(permit_semantics) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(jump(cliff), fatal),
    assertion(safety_governor:safety_governor_permit(walk(path))),
    assertion(\+ safety_governor:safety_governor_permit(jump(cliff))).

% Every veto is appended to the immutable log, in order.
test(veto_log_append_only) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(a, ra),
    safety_governor:safety_governor_forbid(b, rb),
    safety_governor:safety_governor_check(a, _),
    safety_governor:safety_governor_check(b, _),
    safety_governor:safety_governor_veto_log(Entries),
    assertion(Entries == [veto(1, a, ra), veto(2, b, rb)]),
    safety_governor:safety_governor_veto_count(N),
    assertion(N =:= 2).

% Allowed actions leave no veto trace.
test(allow_no_log) :-
    safety_governor:safety_governor_reset,
    safety_governor:safety_governor_forbid(bad, r),
    safety_governor:safety_governor_check(fine, allow),
    safety_governor:safety_governor_veto_count(N),
    assertion(N =:= 0).

% Close the test block.
:- end_tests(safety_governor).
