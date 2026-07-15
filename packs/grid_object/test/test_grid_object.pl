% Test suite for gridobj (gob_*, Layer 242).
:- use_module('../prolog/grid_object.pl').

:- begin_tests(grid_object).

% AC-GOB-001: grid_object_object_cells for single cell.
test('AC-GOB-001: object_cells single') :-
    grid_object_object_cells([[r,b],[b,b]], 0, 0, Cells),
    Cells = [r(0,0)].

% AC-GOB-002: grid_object_object_cells for 2-cell horizontal component.
test('AC-GOB-002: object_cells horizontal') :-
    grid_object_object_cells([[r,r,b],[b,b,b]], 0, 0, Cells),
    msort(Cells, [r(0,0),r(0,1)]).

% AC-GOB-003: grid_object_object_cells L-shape component (4-connected).
test('AC-GOB-003: object_cells L-shape') :-
    Grid = [[r,r,b],[r,b,b]],
    grid_object_object_cells(Grid, 0, 0, Cells),
    msort(Cells, [r(0,0),r(0,1),r(1,0)]).

% AC-GOB-004: grid_object_object_color returns correct color.
test('AC-GOB-004: object_color basic') :-
    grid_object_object_color([[r,b],[b,b]], 0, 0, r).

% AC-GOB-005: grid_object_object_color on non-first cell.
test('AC-GOB-005: object_color position') :-
    grid_object_object_color([[r,g],[b,b]], 0, 1, g).

% AC-GOB-006: grid_object_object_size single cell = 1.
test('AC-GOB-006: object_size single') :-
    grid_object_object_size([[r,b],[b,b]], 0, 0, 1).

% AC-GOB-007: grid_object_object_size 3-cell component.
test('AC-GOB-007: object_size three') :-
    grid_object_object_size([[r,r,r],[b,b,b]], 0, 0, 3).

% AC-GOB-008: grid_object_object_bbox single cell.
test('AC-GOB-008: object_bbox single') :-
    grid_object_object_bbox([[r,b],[b,b]], 0, 0, r0(0,0,0,0)).

% AC-GOB-009: grid_object_object_bbox 2x2 block.
test('AC-GOB-009: object_bbox 2x2 block') :-
    Grid = [[r,r],[r,r]],
    grid_object_object_bbox(Grid, 0, 0, r0(0,0,1,1)).

% AC-GOB-010: grid_object_object_bbox L-shape.
test('AC-GOB-010: object_bbox L-shape') :-
    Grid = [[r,r,b],[r,b,b]],
    grid_object_object_bbox(Grid, 0, 0, r0(0,0,1,1)).

% AC-GOB-011: grid_object_object_mask single cell.
test('AC-GOB-011: object_mask single') :-
    grid_object_object_mask([[r,b],[b,b]], 0, 0, b, [[r,b],[b,b]]).

% AC-GOB-012: grid_object_object_mask isolates one of two components.
test('AC-GOB-012: object_mask isolates') :-
    Grid = [[r,b,g],[b,b,b]],
    grid_object_object_mask(Grid, 0, 0, b, [[r,b,b],[b,b,b]]).

% AC-GOB-013: grid_object_object_mask full-row component.
test('AC-GOB-013: object_mask full row') :-
    Grid = [[r,r,r],[b,b,b]],
    grid_object_object_mask(Grid, 0, 0, b, [[r,r,r],[b,b,b]]).

% AC-GOB-014: grid_object_extract_object single cell.
test('AC-GOB-014: extract_object single') :-
    grid_object_extract_object([[r,b],[b,b]], 0, 0, b, [[r]]).

% AC-GOB-015: grid_object_extract_object 2-cell horizontal.
test('AC-GOB-015: extract_object horizontal') :-
    Grid = [[b,r,r,b],[b,b,b,b]],
    grid_object_extract_object(Grid, 0, 1, b, [[r,r]]).

% AC-GOB-016: grid_object_extract_object L-shape with bg fill in bbox.
test('AC-GOB-016: extract_object L-shape') :-
    Grid = [[r,r,b],[r,b,b],[b,b,b]],
    grid_object_extract_object(Grid, 0, 0, b, [[r,r],[r,b]]).

% AC-GOB-017: grid_object_all_objects on grid with two objects.
test('AC-GOB-017: all_objects two') :-
    Grid = [[r,b,g],[b,b,b]],
    grid_object_all_objects(Grid, b, Objects),
    length(Objects, 2),
    member(ob(r,[r(0,0)],r0(0,0,0,0)), Objects),
    member(ob(g,[r(0,2)],r0(0,2,0,2)), Objects).

% AC-GOB-018: grid_object_all_objects on all-bg grid returns empty.
test('AC-GOB-018: all_objects all bg') :-
    grid_object_all_objects([[b,b],[b,b]], b, []).

% AC-GOB-019: grid_object_all_objects single object.
test('AC-GOB-019: all_objects single') :-
    Grid = [[r,r],[r,r]],
    grid_object_all_objects(Grid, b, [ob(r,_,r0(0,0,1,1))]).

% AC-GOB-020: grid_object_object_count two objects.
test('AC-GOB-020: object_count two') :-
    grid_object_object_count([[r,b,g],[b,b,b]], b, 2).

% AC-GOB-021: grid_object_object_count zero for all-bg.
test('AC-GOB-021: object_count zero') :-
    grid_object_object_count([[b,b],[b,b]], b, 0).

% AC-GOB-022: grid_object_object_count one for single-color grid.
test('AC-GOB-022: object_count one') :-
    grid_object_object_count([[r,r],[r,r]], b, 1).

% AC-GOB-023: grid_object_largest_object returns larger component.
test('AC-GOB-023: largest_object basic') :-
    Grid = [[r,r,b],[b,b,g]],
    grid_object_largest_object(Grid, b, Cells),
    length(Cells, 2),
    msort(Cells, [r(0,0),r(0,1)]).

% AC-GOB-024: grid_object_largest_object single object.
test('AC-GOB-024: largest_object single') :-
    grid_object_largest_object([[r,r],[r,r]], b, Cells),
    length(Cells, 4).

% AC-GOB-025: grid_object_largest_object three objects returns largest.
test('AC-GOB-025: largest_object three') :-
    Grid = [[r,r,r],[g,b,y]],
    grid_object_largest_object(Grid, b, Cells),
    length(Cells, 3).

% AC-GOB-026: grid_object_smallest_object returns smaller component.
test('AC-GOB-026: smallest_object basic') :-
    Grid = [[r,r,b],[b,b,g]],
    grid_object_smallest_object(Grid, b, Cells),
    length(Cells, 1),
    Cells = [r(1,2)].

% AC-GOB-027: grid_object_smallest_object single object.
test('AC-GOB-027: smallest_object single') :-
    grid_object_smallest_object([[r,r],[r,r]], b, Cells),
    length(Cells, 4).

% AC-GOB-028: grid_object_smallest_object three objects returns smallest.
test('AC-GOB-028: smallest_object three') :-
    Grid = [[r,r,r],[g,b,y]],
    grid_object_smallest_object(Grid, b, Cells),
    length(Cells, 1).

% AC-GOB-029: grid_object_flood_fill on single cell.
test('AC-GOB-029: flood_fill single') :-
    grid_object_flood_fill([[r,b],[b,b]], 0, 0, x, [[x,b],[b,b]]).

% AC-GOB-030: grid_object_flood_fill entire same-color region.
test('AC-GOB-030: flood_fill region') :-
    grid_object_flood_fill([[r,r],[r,b]], 0, 0, g, [[g,g],[g,b]]).

% AC-GOB-031: grid_object_flood_fill does not cross Bg.
test('AC-GOB-031: flood_fill no bg cross') :-
    Grid = [[r,b,r],[r,b,r]],
    grid_object_flood_fill(Grid, 0, 0, x, [[x,b,r],[x,b,r]]).

% AC-GOB-032: grid_object_fill_enclosed fills inner Bg.
test('AC-GOB-032: fill_enclosed basic') :-
    Grid = [[r,r,r],[r,b,r],[r,r,r]],
    grid_object_fill_enclosed(Grid, b, x, [[r,r,r],[r,x,r],[r,r,r]]).

% AC-GOB-033: grid_object_fill_enclosed does not fill border-reachable Bg.
test('AC-GOB-033: fill_enclosed border open') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    grid_object_fill_enclosed(Grid, b, x, Grid).

% AC-GOB-034: grid_object_fill_enclosed multiple enclosed regions.
test('AC-GOB-034: fill_enclosed multiple') :-
    Grid = [[r,r,r,r,r],[r,b,r,b,r],[r,r,r,r,r]],
    grid_object_fill_enclosed(Grid, b, x, Result),
    Result = [[r,r,r,r,r],[r,x,r,x,r],[r,r,r,r,r]].

% AC-GOB-035: grid_object_remove_object removes single cell.
test('AC-GOB-035: remove_object single') :-
    grid_object_remove_object([[r,b],[b,b]], 0, 0, b, [[b,b],[b,b]]).

% AC-GOB-036: grid_object_remove_object removes only its component.
test('AC-GOB-036: remove_object partial') :-
    Grid = [[r,r,b],[b,b,g]],
    grid_object_remove_object(Grid, 0, 0, b, [[b,b,b],[b,b,g]]).

% AC-GOB-037: grid_object_remove_object on fully-filled grid.
test('AC-GOB-037: remove_object all') :-
    grid_object_remove_object([[r,r],[r,r]], 0, 0, b, [[b,b],[b,b]]).

% AC-GOB-038: grid_object_move_object moves single cell.
test('AC-GOB-038: move_object single') :-
    grid_object_move_object([[r,b,b],[b,b,b]], 0, 0, 0, 2, b, [[b,b,r],[b,b,b]]).

% AC-GOB-039: grid_object_move_object moves 2-cell component.
test('AC-GOB-039: move_object two cells') :-
    Grid = [[r,r,b],[b,b,b],[b,b,b]],
    grid_object_move_object(Grid, 0, 0, 1, 0, b, [[b,b,b],[r,r,b],[b,b,b]]).

% AC-GOB-040: grid_object_move_object keeps other objects.
test('AC-GOB-040: move_object preserves others') :-
    Grid = [[r,b,g],[b,b,b]],
    grid_object_move_object(Grid, 0, 0, 1, 0, b, Result),
    grid_object_object_cells(Result, 0, 2, [r(0,2)]).

% AC-GOB-041: integration - extract then flood fill.
test('AC-GOB-041: integration extract and fill') :-
    Grid = [[r,r,b],[r,b,b]],
    grid_object_extract_object(Grid, 0, 0, b, Extracted),
    grid_object_flood_fill(Extracted, 0, 0, g, Filled),
    Filled = [[g,g],[g,b]].

% AC-GOB-042: integration - count objects after remove.
test('AC-GOB-042: integration remove reduces count') :-
    Grid = [[r,b,g],[b,b,b]],
    grid_object_remove_object(Grid, 0, 0, b, Cleaned),
    grid_object_object_count(Cleaned, b, 1).

% AC-GOB-043: integration - all_objects counts match object_count.
test('AC-GOB-043: integration all_objects count') :-
    Grid = [[r,b,g],[b,y,b]],
    grid_object_all_objects(Grid, b, Objects),
    length(Objects, Count),
    grid_object_object_count(Grid, b, Count).

% AC-GOB-044: integration - largest then extract.
test('AC-GOB-044: integration largest extract') :-
    Grid = [[r,r,r],[g,b,b]],
    grid_object_largest_object(Grid, b, LargeCells),
    length(LargeCells, 3),
    grid_object_extract_object(Grid, 0, 0, b, Ext),
    Ext = [[r,r,r]].

:- end_tests(grid_object).
