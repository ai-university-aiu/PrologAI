/*  PrologAI — Causalontology Safety Governor Test Suite  (WP-414)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_ward/test/test_co_ward.pl
*/

% Declare this file as a test module.
:- module(test_co_ward, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_ward)).

% Open the test block.
:- begin_tests(co_ward).

% An action matching a constraint is vetoed with its reason.
test(veto_with_reason) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(touch(spike), sharp_and_harmful),
    co_ward:wd_check(touch(spike), Verdict),
    assertion(Verdict == veto(sharp_and_harmful)).

% An unrelated action is allowed.
test(allow_unrelated) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(touch(spike), harmful),
    co_ward:wd_check(press(button), Verdict),
    assertion(Verdict == allow).

% A constraint pattern with a variable bans a whole family of actions.
test(pattern_family) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(touch(_), no_touching),
    assertion(co_ward:wd_forbidden(touch(anything))),
    assertion(co_ward:wd_forbidden(touch(fire))).

% A learned hazard mirrored from co_core is enforced.
test(learned_hazard) :-
    co_ward:wd_reset,
    co_ward:wd_avoid_add(step_on(lava)),
    co_ward:wd_check(step_on(lava), Verdict),
    assertion(Verdict == veto(learned_hazard)).

% permit succeeds for allowed actions and fails for forbidden ones.
test(permit_semantics) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(jump(cliff), fatal),
    assertion(co_ward:wd_permit(walk(path))),
    assertion(\+ co_ward:wd_permit(jump(cliff))).

% Every veto is appended to the immutable log, in order.
test(veto_log_append_only) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(a, ra),
    co_ward:wd_forbid(b, rb),
    co_ward:wd_check(a, _),
    co_ward:wd_check(b, _),
    co_ward:wd_veto_log(Entries),
    assertion(Entries == [veto(1, a, ra), veto(2, b, rb)]),
    co_ward:wd_veto_count(N),
    assertion(N =:= 2).

% Allowed actions leave no veto trace.
test(allow_no_log) :-
    co_ward:wd_reset,
    co_ward:wd_forbid(bad, r),
    co_ward:wd_check(fine, allow),
    co_ward:wd_veto_count(N),
    assertion(N =:= 0).

% Close the test block.
:- end_tests(co_ward).
