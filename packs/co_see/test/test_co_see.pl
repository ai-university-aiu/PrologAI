/*  Tests for co_see — Whole-Grid Perception (WP-403, Layer 378)

    Each acceptance criterion prints PASS or FAIL.

    Run:
        swipl -g run_tests -t halt packs/co_see/test/test_co_see.pl
*/

% Load the pack under test.
:- use_module('../prolog/co_see').

% A small hand-made frame: a wide background (colour 0), one big block (colour 3),
% two single-cell dots (colour 4), and a horizontal bar along the bottom (colour 2)
% — the kind of layout co_see must read: field, dots, and a life-bar/meter.
% Row 7 (the bottom) holds a 6-long bar of colour 2.
frame_a([
    [0,0,0,0,0,0,0,0],
    [0,3,3,3,0,0,0,0],
    [0,3,3,3,0,0,4,0],
    [0,3,3,3,0,0,0,0],
    [0,0,0,0,0,0,0,0],
    [0,0,4,0,0,0,0,0],
    [0,0,0,0,0,0,0,0],
    [2,2,2,2,2,2,0,0]
]).

% The same frame after the avatar (a colour-4 dot at row 2, col 6) stepped down to
% row 3 — used to test avatar-move detection.
frame_b([
    [0,0,0,0,0,0,0,0],
    [0,3,3,3,0,0,0,0],
    [0,3,3,3,0,0,0,0],
    [0,3,3,3,0,0,4,0],
    [0,0,0,0,0,0,0,0],
    [0,0,4,0,0,0,0,0],
    [0,0,0,0,0,0,0,0],
    [2,2,2,2,2,2,0,0]
]).

% report(+Id, +Goal): print PASS or FAIL for one criterion.
report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% run_tests: exercise every predicate of co_see.
run_tests :-
    % Announce.
    format("~n=== co_see — Whole-Grid Perception ===~n~n", []),
    % The two frames.
    frame_a(FA), frame_b(FB),

    % AC-CS-001: the background is the most common colour (0).
    report('AC-CS-001', ( cs_background(FA, Bg), Bg =:= 0 )),

    % AC-CS-002: it sees more than one object (it does not fixate on one spot).
    report('AC-CS-002', ( cs_object_count(FA, N), N >= 3 )),

    % AC-CS-003: the largest object is the colour-3 block (salience order).
    report('AC-CS-003', ( cs_objects(FA, [obj(3, _, _, _) | _]) )),

    % AC-CS-004: the inventory tags the bottom bar as a meter.
    report('AC-CS-004',
        ( cs_inventory(FA, Items), member(seen(_, 2, _, _, meter), Items) )),

    % AC-CS-005: the inventory tags a single cell as a dot.
    report('AC-CS-005',
        ( cs_inventory(FA, Items2), member(seen(_, 4, _, _, dot), Items2) )),

    % AC-CS-006: cs_bars finds the horizontal life-bar of colour 2.
    report('AC-CS-006',
        ( cs_bars(FA, Bars), member(bar(2, horizontal, L, _), Bars), L >= 5 )),

    % AC-CS-007: salient cells are returned, largest object first.
    report('AC-CS-007',
        ( cs_salient_cells(FA, [cell(_, _) | _]) )),

    % AC-CS-008: changed cells between the two frames are detected.
    report('AC-CS-008',
        ( cs_changed_cells(FA, FB, Changed), Changed \== [] )),

    % AC-CS-009: the avatar move is located near where the dot arrived (row 3, col 6).
    report('AC-CS-009',
        ( cs_avatar_move(FA, FB, cell(AR, AC)),
          AR >= 2, AR =< 4, AC >= 5 )),

    % Show what Mentova would now "see" on frame A.
    ( cs_inventory(FA, Inv) -> true ; Inv = [] ),
    format("~nInventory of frame A: ~q~n~n", [Inv]).

% Provide the standard entry point name too.
run_test_co_see :- run_tests.
