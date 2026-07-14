/*  PrologAI — Causalontology Hinge Test Suite  (WP-392)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/realizable_hinge/test/test_co_hinge.pl
*/

% Declare this file as a test module.
:- module(test_co_hinge, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(realizable_hinge)).

:- begin_tests(realizable_hinge).

% Qualities are exhibited whenever borne.
test(quality_roundtrip) :-
    % A fresh hinge.
    realizable_hinge_reset,
    % A ball bears roundness.
    realizable_hinge_quality_add(q1, round, ball),
    % Query it back.
    realizable_hinge_quality(q1, round, ball).

% Only dispositions, functions, and roles are lawful realizable kinds.
test(realizable_kinds) :-
    % A fresh hinge.
    realizable_hinge_reset,
    % A disposition is lawful.
    realizable_hinge_realizable_add(d1, disposition, button),
    % A function is lawful.
    realizable_hinge_realizable_add(f1, function, key),
    % A role is lawful.
    realizable_hinge_realizable_add(r1, role, guard),
    % Anything else is refused.
    \+ realizable_hinge_realizable_add(x1, habit, cat).

% The realization seam ties a realizable to its occurrent, both ways.
test(realization_seam) :-
    % A fresh hinge.
    realizable_hinge_reset,
    % A pressable disposition on a button.
    realizable_hinge_realizable_add(d1, disposition, button),
    % Realized in the pressing occurrent.
    realizable_hinge_realized_in_add(d1, press(button)),
    % Read the seam forward.
    realizable_hinge_realized_in(d1, press(button)),
    % And backward, from the occurrent to the hinge.
    realizable_hinge_of_occurrent(press(button), d1).

% Realization requires a recorded realizable.
test(realization_needs_realizable, [fail]) :-
    % A fresh hinge.
    realizable_hinge_reset,
    % No such realizable exists.
    realizable_hinge_realized_in_add(ghost, press(button)).

% A bearer's realizables are enumerable.
test(bearer_realizables) :-
    % A fresh hinge.
    realizable_hinge_reset,
    % Two realizables on one key.
    realizable_hinge_realizable_add(d1, disposition, key),
    % The second.
    realizable_hinge_realizable_add(f1, function, key),
    % Enumerate them.
    realizable_hinge_bearer_realizables(key, Rs),
    % Both are present.
    memberchk(realizable(d1, disposition), Rs),
    % The function too.
    memberchk(realizable(f1, function), Rs).

:- end_tests(realizable_hinge).
