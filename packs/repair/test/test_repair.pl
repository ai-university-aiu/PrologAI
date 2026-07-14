/*  PrologAI — Causalontology Repair Test Suite  (WP-415)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/repair/test/test_repair.pl
*/

% Declare this file as a test module.
:- module(test_repair, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(repair)).

% Open the test block.
:- begin_tests(repair).

% An action with a known inverse is repaired by inversion.
test(inversion_preferred) :-
    repair:repair_reset,
    repair:repair_inverse_add(open(door), close(door)),
    repair:repair_compensate(disturbance(open(door), draft), Plan, Grade),
    assertion(Plan == undo(close(door))),
    assertion(Grade == inversion).

% With no inverse but a neutralizer, the side effect is cancelled.
test(neutralization) :-
    repair:repair_reset,
    repair:repair_neutralizer_add(spill, mop_up),
    repair:repair_compensate(disturbance(tip(cup), spill), Plan, Grade),
    assertion(Plan == neutralize(mop_up)),
    assertion(Grade == neutralization).

% Inversion is preferred over neutralization when both are available.
test(inversion_beats_neutralization) :-
    repair:repair_reset,
    repair:repair_inverse_add(push(block), pull(block)),
    repair:repair_neutralizer_add(moved, reset_block),
    repair:repair_compensate(disturbance(push(block), moved), Plan, Grade),
    assertion(Grade == inversion),
    assertion(Plan == undo(pull(block))).

% A blocked goal is re-routed to an alternate.
test(reroute_blocked_goal) :-
    repair:repair_reset,
    repair:repair_reroute_add(reach(exit_a), reach(exit_b)),
    repair:repair_compensate(blocked(reach(exit_a)), Plan, Grade),
    assertion(Plan == reroute(reach(exit_b))),
    assertion(Grade == reroute).

% With no repair known, the disturbance is accepted.
test(accept_when_helpless) :-
    repair:repair_reset,
    repair:repair_compensate(disturbance(strange(act), odd), Plan, Grade),
    assertion(Plan == accept),
    assertion(Grade == none).

% Classification names the kind of a disturbance.
test(classify_kinds) :-
    repair:repair_reset,
    repair:repair_inverse_add(a, ia),
    repair:repair_neutralizer_add(fx, cancel),
    repair:repair_reroute_add(g, g2),
    repair:repair_classify(disturbance(a, anything), K1),
    assertion(K1 == reversible),
    repair:repair_classify(disturbance(other, fx), K2),
    assertion(K2 == side_effect),
    repair:repair_classify(blocked(g), K3),
    assertion(K3 == blocked),
    repair:repair_classify(disturbance(zzz, zzz), K4),
    assertion(K4 == unknown).

% can_compensate is true only when a real repair exists.
test(can_compensate) :-
    repair:repair_reset,
    repair:repair_inverse_add(a, ia),
    assertion(repair:repair_can_compensate(disturbance(a, e))),
    assertion(\+ repair:repair_can_compensate(disturbance(b, e))).

% Close the test block.
:- end_tests(repair).
