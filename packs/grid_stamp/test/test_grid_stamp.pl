% Test suite for gridstamp (gst_*, Layer 238).
:- use_module('../prolog/grid_stamp.pl').

:- begin_tests(grid_stamp).

% AC-GST-001: grid_stamp_canvas creates a 2x3 all-bg grid.
test('AC-GST-001: canvas 2x3') :-
    grid_stamp_canvas(2, 3, b, Canvas),
    Canvas = [[b,b,b],[b,b,b]].

% AC-GST-002: grid_stamp_canvas creates a 1x1 grid.
test('AC-GST-002: canvas 1x1') :-
    grid_stamp_canvas(1, 1, b, Canvas),
    Canvas = [[b]].

% AC-GST-003: grid_stamp_canvas with H=0 creates empty list.
test('AC-GST-003: canvas 0 rows') :-
    grid_stamp_canvas(0, 3, b, Canvas),
    Canvas = [].

% AC-GST-004: grid_stamp_stamp places non-bg cell from stamp onto grid.
test('AC-GST-004: stamp basic') :-
    Grid = [[b,b,b],[b,b,b]],
    grid_stamp_stamp(Grid, [[r]], 0, 1, b, Result),
    Result = [[b,r,b],[b,b,b]].

% AC-GST-005: grid_stamp_stamp at position (0,0).
test('AC-GST-005: stamp at origin') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_stamp(Grid, [[r,g],[y,p]], 0, 0, b, Result),
    Result = [[r,g],[y,p]].

% AC-GST-006: grid_stamp_stamp bg cells in stamp are transparent (do not overwrite).
test('AC-GST-006: stamp transparent bg') :-
    Grid = [[r,b],[b,g]],
    grid_stamp_stamp(Grid, [[b,x]], 0, 0, b, Result),
    Result = [[r,x],[b,g]].

% AC-GST-007: grid_stamp_stamp_all pastes stamp at multiple positions.
test('AC-GST-007: stamp_all multiple') :-
    Grid = [[b,b,b],[b,b,b]],
    grid_stamp_stamp_all(Grid, [[r]], [r(0,0),r(1,2)], b, Result),
    Result = [[r,b,b],[b,b,r]].

% AC-GST-008: grid_stamp_stamp_all with empty position list returns grid unchanged.
test('AC-GST-008: stamp_all empty positions') :-
    Grid = [[r,b],[b,g]],
    grid_stamp_stamp_all(Grid, [[x]], [], b, Result),
    Result = [[r,b],[b,g]].

% AC-GST-009: grid_stamp_stamp_all at a single position.
test('AC-GST-009: stamp_all single') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_stamp_all(Grid, [[r,g]], [r(1,0)], b, Result),
    Result = [[b,b],[r,g]].

% AC-GST-010: grid_stamp_scatter places color at all listed positions.
test('AC-GST-010: scatter basic') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_scatter(Grid, r, [r(0,0),r(1,1)], b, Result),
    Result = [[r,b],[b,r]].

% AC-GST-011: grid_stamp_scatter with empty positions returns grid unchanged.
test('AC-GST-011: scatter empty') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_scatter(Grid, r, [], b, Result),
    Result = [[b,b],[b,b]].

% AC-GST-012: grid_stamp_scatter places color at a single position.
test('AC-GST-012: scatter single') :-
    Grid = [[b,b,b]],
    grid_stamp_scatter(Grid, r, [r(0,1)], b, Result),
    Result = [[b,r,b]].

% AC-GST-013: grid_stamp_find_matches finds all positions of a 1x1 pattern.
test('AC-GST-013: find_matches 1x1') :-
    Grid = [[r,b,r],[b,b,b]],
    grid_stamp_find_matches(Grid, [[r]], b, Matches),
    Matches = [r(0,0),r(0,2)].

% AC-GST-014: grid_stamp_find_matches returns empty when no match exists.
test('AC-GST-014: find_matches no match') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_find_matches(Grid, [[r]], b, Matches),
    Matches = [].

% AC-GST-015: grid_stamp_find_matches finds a 2x2 pattern.
test('AC-GST-015: find_matches 2x2') :-
    Grid = [[r,r,b],[r,r,b],[b,b,b]],
    grid_stamp_find_matches(Grid, [[r,r],[r,r]], b, Matches),
    Matches = [r(0,0)].

% AC-GST-016: grid_stamp_stamp_count returns 2 for two occurrences.
test('AC-GST-016: stamp_count two') :-
    Grid = [[r,b,r],[b,b,b]],
    grid_stamp_stamp_count(Grid, [[r]], b, Count),
    Count = 2.

% AC-GST-017: grid_stamp_stamp_count returns 0 when pattern absent.
test('AC-GST-017: stamp_count zero') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_stamp_count(Grid, [[r]], b, Count),
    Count = 0.

% AC-GST-018: grid_stamp_stamp_count returns 3 for a single-cell pattern.
test('AC-GST-018: stamp_count three') :-
    Grid = [[r,b,r],[b,r,b]],
    grid_stamp_stamp_count(Grid, [[r]], b, Count),
    Count = 3.

% AC-GST-019: grid_stamp_pad adds rows and columns of bg.
test('AC-GST-019: pad adds rows and cols') :-
    Grid = [[r,b],[g,b]],
    grid_stamp_pad(Grid, 3, 4, b, Result),
    Result = [[r,b,b,b],[g,b,b,b],[b,b,b,b]].

% AC-GST-020: grid_stamp_pad on already-correct-size grid makes no change.
test('AC-GST-020: pad no change needed') :-
    Grid = [[r,b],[g,b]],
    grid_stamp_pad(Grid, 2, 2, b, Result),
    Result = [[r,b],[g,b]].

% AC-GST-021: grid_stamp_pad adds columns only (height already sufficient).
test('AC-GST-021: pad cols only') :-
    Grid = [[r],[g]],
    grid_stamp_pad(Grid, 2, 3, b, Result),
    Result = [[r,b,b],[g,b,b]].

% AC-GST-022: grid_stamp_unpad removes all-bg border rows and columns.
test('AC-GST-022: unpad basic') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    grid_stamp_unpad(Grid, b, Result),
    Result = [[r]].

% AC-GST-023: grid_stamp_unpad on tight grid returns the grid unchanged.
test('AC-GST-023: unpad already tight') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_unpad(Grid, b, Result),
    Result = [[r,g],[y,p]].

% AC-GST-024: grid_stamp_unpad on all-bg grid returns [].
test('AC-GST-024: unpad all bg') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_unpad(Grid, b, Result),
    Result = [].

% AC-GST-025: grid_stamp_replicate_h repeats grid 2 times horizontally.
test('AC-GST-025: replicate_h basic') :-
    Grid = [[r,b],[g,b]],
    grid_stamp_replicate_h(Grid, 2, b, Result),
    Result = [[r,b,r,b],[g,b,g,b]].

% AC-GST-026: grid_stamp_replicate_h with N=1 returns grid unchanged.
test('AC-GST-026: replicate_h N=1') :-
    Grid = [[r,b],[g,b]],
    grid_stamp_replicate_h(Grid, 1, b, Result),
    Result = [[r,b],[g,b]].

% AC-GST-027: grid_stamp_replicate_v repeats grid 3 times vertically.
test('AC-GST-027: replicate_v N=3') :-
    Grid = [[r,g]],
    grid_stamp_replicate_v(Grid, 3, b, Result),
    Result = [[r,g],[r,g],[r,g]].

% AC-GST-028: grid_stamp_border adds a border of thickness 1.
test('AC-GST-028: border thickness 1') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_border(Grid, x, 1, b, Result),
    Result = [[x,x,x,x],[x,r,g,x],[x,y,p,x],[x,x,x,x]].

% AC-GST-029: grid_stamp_border with thickness 2 adds 2 cells on each side.
test('AC-GST-029: border thickness 2') :-
    Grid = [[r]],
    grid_stamp_border(Grid, x, 2, b, Result),
    Result = [[x,x,x,x,x],[x,x,x,x,x],[x,x,r,x,x],[x,x,x,x,x],[x,x,x,x,x]].

% AC-GST-030: grid_stamp_border with thickness 0 returns grid unchanged.
test('AC-GST-030: border thickness 0') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_border(Grid, x, 0, b, Result),
    Result = [[r,g],[y,p]].

% AC-GST-031: grid_stamp_center places grid at center of larger canvas.
test('AC-GST-031: center basic') :-
    Grid = [[r]],
    grid_stamp_center(Grid, 3, 3, b, Result),
    Result = [[b,b,b],[b,r,b],[b,b,b]].

% AC-GST-032: grid_stamp_center with same-size canvas returns grid unchanged.
test('AC-GST-032: center same size') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_center(Grid, 2, 2, b, Result),
    Result = [[r,g],[y,p]].

% AC-GST-033: grid_stamp_center with 1x3 grid in 1x5 canvas.
test('AC-GST-033: center horizontal') :-
    Grid = [[r,g,y]],
    grid_stamp_center(Grid, 1, 5, b, Result),
    Result = [[b,r,g,y,b]].

% AC-GST-034: grid_stamp_extract extracts a 2x2 subgrid.
test('AC-GST-034: extract 2x2') :-
    Grid = [[a,b,c],[d,e,f],[g,h,i]],
    grid_stamp_extract(Grid, 0, 1, 2, 2, Subgrid),
    Subgrid = [[b,c],[e,f]].

% AC-GST-035: grid_stamp_extract extracts the full grid.
test('AC-GST-035: extract full grid') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_extract(Grid, 0, 0, 2, 2, Subgrid),
    Subgrid = [[r,g],[y,p]].

% AC-GST-036: grid_stamp_extract extracts a single cell.
test('AC-GST-036: extract single cell') :-
    Grid = [[a,b,c],[d,e,f]],
    grid_stamp_extract(Grid, 1, 2, 1, 1, Subgrid),
    Subgrid = [[f]].

% AC-GST-037: grid_stamp_replace replaces a 2x2 patch at (1,1).
test('AC-GST-037: replace 2x2 patch') :-
    Grid = [[b,b,b],[b,b,b],[b,b,b]],
    grid_stamp_replace(Grid, 1, 1, [[r,g],[y,p]], Result),
    Result = [[b,b,b],[b,r,g],[b,y,p]].

% AC-GST-038: grid_stamp_replace overwrites bg cells in the patch region.
test('AC-GST-038: replace overwrites bg') :-
    Grid = [[r,r],[r,r]],
    grid_stamp_replace(Grid, 0, 0, [[b,b],[b,b]], Result),
    Result = [[b,b],[b,b]].

% AC-GST-039: grid_stamp_replace partial patch: only in-bounds rows are replaced.
test('AC-GST-039: replace at edge clips') :-
    Grid = [[b,b],[b,b]],
    grid_stamp_replace(Grid, 1, 1, [[r,g],[y,p]], Result),
    Result = [[b,b],[b,r]].

% AC-GST-040: grid_stamp_replicate_v with N=2 stacks grid twice.
test('AC-GST-040: replicate_v N=2') :-
    Grid = [[r,b],[g,b]],
    grid_stamp_replicate_v(Grid, 2, b, Result),
    Result = [[r,b],[g,b],[r,b],[g,b]].

% AC-GST-041: grid_stamp_replicate_h with two-row grid.
test('AC-GST-041: replicate_h two rows') :-
    Grid = [[r,g],[y,p]],
    grid_stamp_replicate_h(Grid, 3, b, Result),
    Result = [[r,g,r,g,r,g],[y,p,y,p,y,p]].

% AC-GST-042: grid_stamp_stamp_all multiple stamps at same position stack.
test('AC-GST-042: stamp_all overlap') :-
    Grid = [[b,b,b]],
    grid_stamp_stamp_all(Grid, [[r]], [r(0,0),r(0,0)], b, Result),
    Result = [[r,b,b]].

% AC-GST-043: integration: canvas then stamp_all then find_matches.
test('AC-GST-043: integration canvas stamp find') :-
    grid_stamp_canvas(3, 3, b, Canvas),
    grid_stamp_stamp_all(Canvas, [[r]], [r(0,0),r(1,1),r(2,2)], b, Diagonal),
    grid_stamp_find_matches(Diagonal, [[r]], b, Matches),
    length(Matches, 3).

% AC-GST-044: integration: stamp then extract recovers stamp content.
test('AC-GST-044: integration stamp extract') :-
    Grid = [[b,b,b],[b,b,b],[b,b,b]],
    Stamp = [[r,g],[y,p]],
    grid_stamp_stamp(Grid, Stamp, 1, 1, b, Stamped),
    grid_stamp_extract(Stamped, 1, 1, 2, 2, Extracted),
    Extracted = [[r,g],[y,p]].

:- end_tests(grid_stamp).
