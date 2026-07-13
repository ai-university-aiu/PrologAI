/*  PrologAI — Causalontology Whole-Grid Perception Test Suite  (WP-403, Layer 378)

    Run with the full library path (co_see needs the grid and gridobj packs):
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_see/test/test_co_see.pl
*/

% Declare this file as a test module.
:- module(test_co_see, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(co_see)).

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

% Open the test block for co_see.
:- begin_tests(co_see).

% AC-CS-001: the background is the most common colour (0).
test(background_is_most_common) :-
    % The single test frame.
    frame_a(FA),
    % Read its background.
    cs_background(FA, Bg),
    % The most common colour is 0.
    assertion(Bg =:= 0).

% AC-CS-002: it sees more than one object (it does not fixate on one spot).
test(sees_several_objects) :-
    % The single test frame.
    frame_a(FA),
    % Count the objects.
    cs_object_count(FA, N),
    % At least three (block, two dots, and the bar).
    assertion(N >= 3).

% AC-CS-003: the largest object is the colour-3 block (salience order).
test(largest_object_first) :-
    % The single test frame.
    frame_a(FA),
    % Read the objects, largest first.
    cs_objects(FA, Objects),
    % The head of the list is the colour-3 block.
    assertion(Objects = [obj(3, _, _, _) | _]).

% AC-CS-004: the inventory tags the bottom bar as a meter.
test(inventory_tags_bar_as_meter) :-
    % The single test frame.
    frame_a(FA),
    % Read the inventory.
    cs_inventory(FA, Items),
    % The colour-2 bar is tagged meter.
    assertion(member(seen(_, 2, _, _, meter), Items)).

% AC-CS-005: the inventory tags a single cell as a dot.
test(inventory_tags_cell_as_dot) :-
    % The single test frame.
    frame_a(FA),
    % Read the inventory.
    cs_inventory(FA, Items),
    % A colour-4 single cell is tagged dot.
    assertion(member(seen(_, 4, _, _, dot), Items)).

% AC-CS-006: cs_bars finds the horizontal life-bar of colour 2.
test(bars_find_horizontal_meter) :-
    % The single test frame.
    frame_a(FA),
    % Read the bars.
    cs_bars(FA, Bars),
    % A horizontal colour-2 bar at least five cells long.
    assertion(( member(bar(2, horizontal, L, _), Bars), L >= 5 )).

% AC-CS-007: salient cells are returned, largest object first.
test(salient_cells_returned) :-
    % The single test frame.
    frame_a(FA),
    % Read the salient cells.
    cs_salient_cells(FA, Cells),
    % The list leads with a cell (the largest object's centroid).
    assertion(Cells = [cell(_, _) | _]).

% AC-CS-008: changed cells between the two frames are detected.
test(changed_cells_detected) :-
    % The two frames.
    frame_a(FA), frame_b(FB),
    % The cells that differ.
    cs_changed_cells(FA, FB, Changed),
    % Something changed.
    assertion(Changed \== []).

% AC-CS-009: the avatar move is located near where the dot arrived (row 3, col 6).
test(avatar_move_located) :-
    % The two frames.
    frame_a(FA), frame_b(FB),
    % Locate what moved.
    cs_avatar_move(FA, FB, cell(AR, AC)),
    % It lands near the dot's new position.
    assertion(( AR >= 2, AR =< 4, AC >= 5 )).

% Close the test block.
:- end_tests(co_see).
