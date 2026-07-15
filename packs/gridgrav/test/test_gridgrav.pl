% Test suite for gridgrav (gra_*, Layer 237).
:- use_module('../prolog/gridgrav.pl').

:- begin_tests(gridgrav).

% AC-GRA-001: gridgrav_col_nonbg collects non-bg values from a column top to bottom.
test('AC-GRA-001: col_nonbg basic') :-
    Grid = [[b,r,b],[b,g,b]],
    gridgrav_col_nonbg(Grid, 1, b, Vals),
    Vals = [r,g].

% AC-GRA-002: gridgrav_col_nonbg on all-bg column yields empty list.
test('AC-GRA-002: col_nonbg empty column') :-
    Grid = [[b,b],[b,b]],
    gridgrav_col_nonbg(Grid, 0, b, Vals),
    Vals = [].

% AC-GRA-003: gridgrav_col_nonbg on all non-bg column yields all values.
test('AC-GRA-003: col_nonbg full column') :-
    Grid = [[r,b],[g,b]],
    gridgrav_col_nonbg(Grid, 0, b, Vals),
    Vals = [r,g].

% AC-GRA-004: gridgrav_row_nonbg collects non-bg values from a row left to right.
test('AC-GRA-004: row_nonbg basic') :-
    Grid = [[b,r,b,g]],
    gridgrav_row_nonbg(Grid, 0, b, Vals),
    Vals = [r,g].

% AC-GRA-005: gridgrav_row_nonbg on all-bg row yields empty list.
test('AC-GRA-005: row_nonbg empty row') :-
    Grid = [[b,b,b],[r,b,r]],
    gridgrav_row_nonbg(Grid, 0, b, Vals),
    Vals = [].

% AC-GRA-006: gridgrav_row_nonbg on a second row with gaps.
test('AC-GRA-006: row_nonbg partial') :-
    Grid = [[b,b,b],[r,b,g]],
    gridgrav_row_nonbg(Grid, 1, b, Vals),
    Vals = [r,g].

% AC-GRA-007: gridgrav_fall_down moves non-bg cells to the bottom of each column.
test('AC-GRA-007: fall_down basic') :-
    Grid = [[r,b],[b,b]],
    gridgrav_fall_down(Grid, b, Result),
    Result = [[b,b],[r,b]].

% AC-GRA-008: gridgrav_fall_down handles two non-bg cells in different columns.
test('AC-GRA-008: fall_down two columns') :-
    Grid = [[r,g],[b,b]],
    gridgrav_fall_down(Grid, b, Result),
    Result = [[b,b],[r,g]].

% AC-GRA-009: gridgrav_fall_down is idempotent on an already-settled grid.
test('AC-GRA-009: fall_down idempotent') :-
    Grid = [[b,b],[r,g]],
    gridgrav_fall_down(Grid, b, Result),
    Result = [[b,b],[r,g]].

% AC-GRA-010: gridgrav_fall_down on an all-bg grid makes no change.
test('AC-GRA-010: fall_down all bg') :-
    Grid = [[b,b],[b,b]],
    gridgrav_fall_down(Grid, b, Result),
    Result = [[b,b],[b,b]].

% AC-GRA-011: gridgrav_fall_up moves non-bg cells to the top of each column.
test('AC-GRA-011: fall_up basic') :-
    Grid = [[b,b],[r,b]],
    gridgrav_fall_up(Grid, b, Result),
    Result = [[r,b],[b,b]].

% AC-GRA-012: gridgrav_fall_up on three-row grid with bottom-heavy non-bg.
test('AC-GRA-012: fall_up three rows') :-
    Grid = [[b,b,b],[r,g,y]],
    gridgrav_fall_up(Grid, b, Result),
    Result = [[r,g,y],[b,b,b]].

% AC-GRA-013: gridgrav_fall_up is idempotent on a top-settled grid.
test('AC-GRA-013: fall_up idempotent') :-
    Grid = [[r,g,y],[b,b,b]],
    gridgrav_fall_up(Grid, b, Result),
    Result = [[r,g,y],[b,b,b]].

% AC-GRA-014: gridgrav_fall_left slides non-bg values to the left of each row.
test('AC-GRA-014: fall_left basic') :-
    Grid = [[b,r,b]],
    gridgrav_fall_left(Grid, b, Result),
    Result = [[r,b,b]].

% AC-GRA-015: gridgrav_fall_left on a two-row grid, each with one non-bg cell.
test('AC-GRA-015: fall_left two rows') :-
    Grid = [[b,r,b],[g,b,b]],
    gridgrav_fall_left(Grid, b, Result),
    Result = [[r,b,b],[g,b,b]].

% AC-GRA-016: gridgrav_fall_left is idempotent on a left-settled grid.
test('AC-GRA-016: fall_left idempotent') :-
    Grid = [[r,g,b],[b,b,b]],
    gridgrav_fall_left(Grid, b, Result),
    Result = [[r,g,b],[b,b,b]].

% AC-GRA-017: gridgrav_fall_right slides non-bg values to the right of each row.
test('AC-GRA-017: fall_right basic') :-
    Grid = [[b,r,b]],
    gridgrav_fall_right(Grid, b, Result),
    Result = [[b,b,r]].

% AC-GRA-018: gridgrav_fall_right on a row with two non-bg values preserves order.
test('AC-GRA-018: fall_right two values') :-
    Grid = [[r,b,g]],
    gridgrav_fall_right(Grid, b, Result),
    Result = [[b,r,g]].

% AC-GRA-019: gridgrav_fall_right is idempotent on a right-settled grid.
test('AC-GRA-019: fall_right idempotent') :-
    Grid = [[b,b,r]],
    gridgrav_fall_right(Grid, b, Result),
    Result = [[b,b,r]].

% AC-GRA-020: gridgrav_fall/4 dispatches correctly for direction down.
test('AC-GRA-020: fall dispatch down') :-
    Grid = [[r,b],[b,b]],
    gridgrav_fall(Grid, b, down, Result),
    Result = [[b,b],[r,b]].

% AC-GRA-021: gridgrav_fall/4 dispatches correctly for direction up.
test('AC-GRA-021: fall dispatch up') :-
    Grid = [[b,b],[r,b]],
    gridgrav_fall(Grid, b, up, Result),
    Result = [[r,b],[b,b]].

% AC-GRA-022: gridgrav_fall/4 dispatches correctly for direction left.
test('AC-GRA-022: fall dispatch left') :-
    Grid = [[b,r,b]],
    gridgrav_fall(Grid, b, left, Result),
    Result = [[r,b,b]].

% AC-GRA-023: gridgrav_fall/4 dispatches correctly for direction right.
test('AC-GRA-023: fall dispatch right') :-
    Grid = [[b,r,b]],
    gridgrav_fall(Grid, b, right, Result),
    Result = [[b,b,r]].

% AC-GRA-024: gridgrav_set_col_bottom places values at the bottom of a column.
test('AC-GRA-024: set_col_bottom basic') :-
    Grid = [[b,b],[b,b],[b,b]],
    gridgrav_set_col_bottom(Grid, 1, [r,g], b, Result),
    Result = [[b,b],[b,r],[b,g]].

% AC-GRA-025: gridgrav_set_col_bottom with empty vals fills column with bg.
test('AC-GRA-025: set_col_bottom empty vals') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_col_bottom(Grid, 0, [], b, Result),
    Result = [[b,b],[b,b]].

% AC-GRA-026: gridgrav_set_col_bottom with vals equal to column height fills all rows.
test('AC-GRA-026: set_col_bottom full column') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_col_bottom(Grid, 0, [r,g], b, Result),
    Result = [[r,b],[g,b]].

% AC-GRA-027: gridgrav_set_col_top places values at the top of a column.
test('AC-GRA-027: set_col_top basic') :-
    Grid = [[b,b],[b,b],[b,b]],
    gridgrav_set_col_top(Grid, 0, [r,g], b, Result),
    Result = [[r,b],[g,b],[b,b]].

% AC-GRA-028: gridgrav_set_col_top with empty vals fills column with bg.
test('AC-GRA-028: set_col_top empty vals') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_col_top(Grid, 0, [], b, Result),
    Result = [[b,b],[b,b]].

% AC-GRA-029: gridgrav_set_col_top with vals equal to column height fills all rows.
test('AC-GRA-029: set_col_top full column') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_col_top(Grid, 1, [r,g], b, Result),
    Result = [[b,r],[b,g]].

% AC-GRA-030: gridgrav_set_row_left places values at the left of a row.
test('AC-GRA-030: set_row_left basic') :-
    Grid = [[b,b,b],[b,b,b]],
    gridgrav_set_row_left(Grid, 0, [r,g], b, Result),
    Result = [[r,g,b],[b,b,b]].

% AC-GRA-031: gridgrav_set_row_left with empty vals fills row with bg.
test('AC-GRA-031: set_row_left empty vals') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_row_left(Grid, 0, [], b, Result),
    Result = [[b,b],[b,b]].

% AC-GRA-032: gridgrav_set_row_left with vals equal to row width fills whole row.
test('AC-GRA-032: set_row_left full row') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_row_left(Grid, 0, [r,g], b, Result),
    Result = [[r,g],[b,b]].

% AC-GRA-033: gridgrav_set_row_right places values at the right of a row.
test('AC-GRA-033: set_row_right basic') :-
    Grid = [[b,b,b],[b,b,b]],
    gridgrav_set_row_right(Grid, 0, [r], b, Result),
    Result = [[b,b,r],[b,b,b]].

% AC-GRA-034: gridgrav_set_row_right with empty vals fills row with bg.
test('AC-GRA-034: set_row_right empty vals') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_row_right(Grid, 1, [], b, Result),
    Result = [[b,b],[b,b]].

% AC-GRA-035: gridgrav_set_row_right with vals equal to row width fills whole row.
test('AC-GRA-035: set_row_right full row') :-
    Grid = [[b,b],[b,b]],
    gridgrav_set_row_right(Grid, 1, [r,g], b, Result),
    Result = [[b,b],[r,g]].

% AC-GRA-036: gridgrav_blocked_fall down: non-bg stops above BlockColor wall.
test('AC-GRA-036: blocked_fall down basic') :-
    Grid = [[r,b],[b,b],[blk,b],[g,b]],
    gridgrav_blocked_fall(Grid, b, blk, down, Result),
    Result = [[b,b],[r,b],[blk,b],[g,b]].

% AC-GRA-037: gridgrav_blocked_fall up: non-bg stops below BlockColor wall.
test('AC-GRA-037: blocked_fall up basic') :-
    Grid = [[b,b],[r,b],[blk,b],[g,b]],
    gridgrav_blocked_fall(Grid, b, blk, up, Result),
    Result = [[r,b],[b,b],[blk,b],[g,b]].

% AC-GRA-038: gridgrav_blocked_fall left: non-bg stops to right of BlockColor wall.
test('AC-GRA-038: blocked_fall left basic') :-
    Grid = [[b,r,blk,g]],
    gridgrav_blocked_fall(Grid, b, blk, left, Result),
    Result = [[r,b,blk,g]].

% AC-GRA-039: gridgrav_blocked_fall right: non-bg stops to left of BlockColor wall.
test('AC-GRA-039: blocked_fall right basic') :-
    Grid = [[g,blk,r,b]],
    gridgrav_blocked_fall(Grid, b, blk, right, Result),
    Result = [[g,blk,b,r]].

% AC-GRA-040: gridgrav_is_settled succeeds when grid is already settled downward.
test('AC-GRA-040: is_settled true') :-
    Grid = [[b,b],[r,g]],
    gridgrav_is_settled(Grid, b).

% AC-GRA-041: gridgrav_is_settled fails when grid has unsettled cells.
test('AC-GRA-041: is_settled false') :-
    Grid = [[r,b],[b,b]],
    \+ gridgrav_is_settled(Grid, b).

% AC-GRA-042: gridgrav_gravity_score is 0 for an already-settled grid.
test('AC-GRA-042: gravity_score zero') :-
    Grid = [[b,b],[r,g]],
    gridgrav_gravity_score(Grid, b, Score),
    Score = 0.

% AC-GRA-043: gridgrav_gravity_score is 2 when one cell would move (one leave + one arrive).
test('AC-GRA-043: gravity_score nonzero') :-
    Grid = [[r,b],[b,b]],
    gridgrav_gravity_score(Grid, b, Score),
    Score = 2.

% AC-GRA-044: integration: fall_down then col_nonbg then set_col_top restores original.
test('AC-GRA-044: integration fall and restore') :-
    Grid = [[r,b,b],[b,b,b]],
    gridgrav_fall_down(Grid, b, Fallen),
    Fallen = [[b,b,b],[r,b,b]],
    gridgrav_col_nonbg(Fallen, 0, b, Vals),
    Vals = [r],
    gridgrav_set_col_top(Fallen, 0, [r], b, Restored),
    Restored = [[r,b,b],[b,b,b]],
    gridgrav_is_settled(Fallen, b).

:- end_tests(gridgrav).
