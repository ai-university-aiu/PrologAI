/*  PrologAI — Causalontology Hinge Test Suite  (WP-392)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_hinge/test/test_co_hinge.pl
*/

% Declare this file as a test module.
:- module(test_co_hinge, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_hinge)).

:- begin_tests(co_hinge).

% Qualities are exhibited whenever borne.
test(quality_roundtrip) :-
    % A fresh hinge.
    co_hinge_reset,
    % A ball bears roundness.
    co_quality_add(q1, round, ball),
    % Query it back.
    co_quality(q1, round, ball).

% Only dispositions, functions, and roles are lawful realizable kinds.
test(realizable_kinds) :-
    % A fresh hinge.
    co_hinge_reset,
    % A disposition is lawful.
    co_realizable_add(d1, disposition, button),
    % A function is lawful.
    co_realizable_add(f1, function, key),
    % A role is lawful.
    co_realizable_add(r1, role, guard),
    % Anything else is refused.
    \+ co_realizable_add(x1, habit, cat).

% The realization seam ties a realizable to its occurrent, both ways.
test(realization_seam) :-
    % A fresh hinge.
    co_hinge_reset,
    % A pressable disposition on a button.
    co_realizable_add(d1, disposition, button),
    % Realized in the pressing occurrent.
    co_realized_in_add(d1, press(button)),
    % Read the seam forward.
    co_realized_in(d1, press(button)),
    % And backward, from the occurrent to the hinge.
    co_hinge_of_occurrent(press(button), d1).

% Realization requires a recorded realizable.
test(realization_needs_realizable, [fail]) :-
    % A fresh hinge.
    co_hinge_reset,
    % No such realizable exists.
    co_realized_in_add(ghost, press(button)).

% A bearer's realizables are enumerable.
test(bearer_realizables) :-
    % A fresh hinge.
    co_hinge_reset,
    % Two realizables on one key.
    co_realizable_add(d1, disposition, key),
    % The second.
    co_realizable_add(f1, function, key),
    % Enumerate them.
    co_bearer_realizables(key, Rs),
    % Both are present.
    memberchk(realizable(d1, disposition), Rs),
    % The function too.
    memberchk(realizable(f1, function), Rs).

:- end_tests(co_hinge).
