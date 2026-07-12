/*  PrologAI — Causalontology Repair Test Suite  (WP-415)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_mend/test/test_co_mend.pl
*/

% Declare this file as a test module.
:- module(test_co_mend, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_mend)).

% Open the test block.
:- begin_tests(co_mend).

% An action with a known inverse is repaired by inversion.
test(inversion_preferred) :-
    co_mend:md_reset,
    co_mend:md_inverse_add(open(door), close(door)),
    co_mend:md_compensate(disturbance(open(door), draft), Plan, Grade),
    assertion(Plan == undo(close(door))),
    assertion(Grade == inversion).

% With no inverse but a neutralizer, the side effect is cancelled.
test(neutralization) :-
    co_mend:md_reset,
    co_mend:md_neutralizer_add(spill, mop_up),
    co_mend:md_compensate(disturbance(tip(cup), spill), Plan, Grade),
    assertion(Plan == neutralize(mop_up)),
    assertion(Grade == neutralization).

% Inversion is preferred over neutralization when both are available.
test(inversion_beats_neutralization) :-
    co_mend:md_reset,
    co_mend:md_inverse_add(push(block), pull(block)),
    co_mend:md_neutralizer_add(moved, reset_block),
    co_mend:md_compensate(disturbance(push(block), moved), Plan, Grade),
    assertion(Grade == inversion),
    assertion(Plan == undo(pull(block))).

% A blocked goal is re-routed to an alternate.
test(reroute_blocked_goal) :-
    co_mend:md_reset,
    co_mend:md_reroute_add(reach(exit_a), reach(exit_b)),
    co_mend:md_compensate(blocked(reach(exit_a)), Plan, Grade),
    assertion(Plan == reroute(reach(exit_b))),
    assertion(Grade == reroute).

% With no repair known, the disturbance is accepted.
test(accept_when_helpless) :-
    co_mend:md_reset,
    co_mend:md_compensate(disturbance(strange(act), odd), Plan, Grade),
    assertion(Plan == accept),
    assertion(Grade == none).

% Classification names the kind of a disturbance.
test(classify_kinds) :-
    co_mend:md_reset,
    co_mend:md_inverse_add(a, ia),
    co_mend:md_neutralizer_add(fx, cancel),
    co_mend:md_reroute_add(g, g2),
    co_mend:md_classify(disturbance(a, anything), K1),
    assertion(K1 == reversible),
    co_mend:md_classify(disturbance(other, fx), K2),
    assertion(K2 == side_effect),
    co_mend:md_classify(blocked(g), K3),
    assertion(K3 == blocked),
    co_mend:md_classify(disturbance(zzz, zzz), K4),
    assertion(K4 == unknown).

% can_compensate is true only when a real repair exists.
test(can_compensate) :-
    co_mend:md_reset,
    co_mend:md_inverse_add(a, ia),
    assertion(co_mend:md_can_compensate(disturbance(a, e))),
    assertion(\+ co_mend:md_can_compensate(disturbance(b, e))).

% Close the test block.
:- end_tests(co_mend).
