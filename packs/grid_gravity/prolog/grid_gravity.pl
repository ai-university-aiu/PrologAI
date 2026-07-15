% Module declaration with all fourteen public predicates.
:- module(grid_gravity, [
% Fall predicates: slide non-bg cells toward an edge.
    grid_gravity_fall_down/3,
% Fall up direction.
    grid_gravity_fall_up/3,
% Fall left direction.
    grid_gravity_fall_left/3,
% Fall right direction.
    grid_gravity_fall_right/3,
% Direction dispatch: call fall in a named direction.
    grid_gravity_fall/4,
% Column extraction: non-bg values top-to-bottom.
    grid_gravity_col_nonbg/4,
% Row extraction: non-bg values left-to-right.
    grid_gravity_row_nonbg/4,
% Column setter: pack values at bottom of column.
    grid_gravity_set_col_bottom/5,
% Column setter: pack values at top of column.
    grid_gravity_set_col_top/5,
% Row setter: pack values at left of row.
    grid_gravity_set_row_left/5,
% Row setter: pack values at right of row.
    grid_gravity_set_row_right/5,
% Blocked fall: cells stop before BlockColor walls.
    grid_gravity_blocked_fall/5,
% Settled test: true if fall_down would not change the grid.
    grid_gravity_is_settled/2,
% Gravity score: number of cells displaced by fall_down.
    grid_gravity_gravity_score/3
]).
% gridgrav.pl - Layer 237: Grid Gravity and Sliding Operations (gra_* prefix).
% Fourteen predicates for making non-bg cells fall or slide toward edges of
% rows and columns. Supports all four directions, blocked gravity (immovable
% wall cells), individual column/row setters, and a settled-state test.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% grid_gravity_cols_to_grid_/3: transpose list of column-lists to list of row-lists.
% Cols is a list of W column-lists each of height H; Grid is H rows of W cells.
grid_gravity_cols_to_grid_(Cols, H, Grid) :-
% H1 is the inclusive upper bound for row indices 0..H-1.
    H1 is H - 1,
% For each row index, collect the R-th cell from each column in order.
    findall(Row,
        (between(0, H1, R),
         findall(V, (member(Col, Cols), nth0(R, Col, V)), Row)),
        Grid).

% grid_gravity_settle_segment_/4: pack non-bg values to one end of a list segment.
% Dir=down or Dir=right: bg padding first, then values (pack to the end).
% Dir=up or Dir=left: values first, then bg padding (pack to the start).
grid_gravity_settle_segment_(Seg, Bg, Dir, Settled) :-
% Count total cells and collect non-bg values in order.
    length(Seg, N),
% Collect all non-bg values preserving their left-to-right order.
    findall(V, (member(V, Seg), V \= Bg), Vals),
% Compute how many bg padding cells are needed.
    length(Vals, NV), NBg is N - NV,
% Build the bg padding list.
    findall(Bg, between(1, NBg, _), BgPad),
% Pack toward end (down/right) or toward start (up/left).
    (Dir = down -> append(BgPad, Vals, Settled)
    ;Dir = right -> append(BgPad, Vals, Settled)
    ;append(Vals, BgPad, Settled)
    ).

% grid_gravity_split_at_first_/4: split List at the first occurrence of BlockColor.
% Before is the prefix before BlockColor; After is the tail after it.
% Fails if BlockColor does not appear in List.
grid_gravity_split_at_first_([BlockColor|After], BlockColor, [], After) :- !.
% Recurse while current head differs from BlockColor.
grid_gravity_split_at_first_([H|T], BlockColor, [H|Before], After) :-
    grid_gravity_split_at_first_(T, BlockColor, Before, After).

% grid_gravity_segment_apply_/5: split at BlockColor walls; settle each segment; reassemble.
% Empty list base case.
grid_gravity_segment_apply_([], _, _, _, []) :- !.
% Find next BlockColor, settle before it, recurse after it.
grid_gravity_segment_apply_(Vals, Bg, BlockColor, Dir, Result) :-
    (grid_gravity_split_at_first_(Vals, BlockColor, Before, After) ->
        grid_gravity_settle_segment_(Before, Bg, Dir, SettledBefore),
        grid_gravity_segment_apply_(After, Bg, BlockColor, Dir, SettledAfter),
        append(SettledBefore, [BlockColor|SettledAfter], Result)
    ;
% No BlockColor found: settle the whole remaining segment.
        grid_gravity_settle_segment_(Vals, Bg, Dir, Result)
    ).

% grid_gravity_set_col_/4: replace column Col in Grid with values from ColVals.
% Base case: empty grid and empty values list.
grid_gravity_set_col_([], _, [], []) :- !.
% Recursive case: replace one cell per row using grid_gravity_set_nth_.
grid_gravity_set_col_([Row|Rows], Col, [V|Vs], [NewRow|Rest]) :-
    grid_gravity_set_nth_(Row, Col, V, NewRow),
    grid_gravity_set_col_(Rows, Col, Vs, Rest).

% grid_gravity_set_nth_/4: replace element at 0-indexed position N in List with V.
% Base case: N=0, replace head.
grid_gravity_set_nth_([_|T], 0, V, [V|T]) :- !.
% Recursive case: keep head, decrement index, recurse.
grid_gravity_set_nth_([H|T], N, V, [H|Rest]) :-
    N1 is N - 1,
    grid_gravity_set_nth_(T, N1, V, Rest).

% grid_gravity_set_row_/4: replace the row at 0-indexed RowIdx in Grid with NewRow.
grid_gravity_set_row_(Grid, RowIdx, NewRow, Result) :-
% Iterate all row indices; swap only at RowIdx.
    length(Grid, H), H1 is H - 1,
    findall(R,
        (between(0, H1, I),
         nth0(I, Grid, OldRow),
         (I =:= RowIdx -> R = NewRow ; R = OldRow)),
        Result).

% grid_gravity_count_diff_/3: count cell positions where two grids differ (base case).
grid_gravity_count_diff_([], [], 0) :- !.
% Recursive case: sum per-row differences.
grid_gravity_count_diff_([R1|T1], [R2|T2], Score) :-
    grid_gravity_count_diff_(T1, T2, Score1),
    grid_gravity_row_diff_count_(R1, R2, D),
    Score is Score1 + D.

% grid_gravity_row_diff_count_/3: count positions where two rows differ (base case).
grid_gravity_row_diff_count_([], [], 0) :- !.
% Equal cell: cut to avoid backtracking, do not increment.
grid_gravity_row_diff_count_([V|T1], [V|T2], N) :- !,
    grid_gravity_row_diff_count_(T1, T2, N).
% Different cell: increment counter.
grid_gravity_row_diff_count_([_|T1], [_|T2], N) :-
    grid_gravity_row_diff_count_(T1, T2, N1), N is N1 + 1.

% --- PUBLIC PREDICATES ---

% grid_gravity_col_nonbg(+Grid, +Col, +Bg, -Vals)
% Collect all non-Bg values from 0-indexed column Col, top to bottom.
grid_gravity_col_nonbg(Grid, Col, Bg, Vals) :-
% H1 is the inclusive row index upper bound.
    length(Grid, H), H1 is H - 1,
% Iterate rows in order; collect non-bg cell values from column Col.
    findall(V,
        (between(0, H1, R),
         nth0(R, Grid, Row),
         nth0(Col, Row, V),
         V \= Bg),
        Vals).

% grid_gravity_row_nonbg(+Grid, +RowIdx, +Bg, -Vals)
% Collect all non-Bg values from 0-indexed row RowIdx, left to right.
grid_gravity_row_nonbg(Grid, RowIdx, Bg, Vals) :-
% Extract the target row.
    nth0(RowIdx, Grid, Row),
% W1 is the inclusive column index upper bound.
    length(Row, W), W1 is W - 1,
% Iterate columns in order; collect non-bg cell values.
    findall(V, (between(0, W1, C), nth0(C, Row, V), V \= Bg), Vals).

% grid_gravity_fall_down(+Grid, +Bg, -Result)
% Each column: non-Bg values sink to the bottom; Bg fills above.
grid_gravity_fall_down(Grid, Bg, Result) :-
% Empty grid shortcut.
    (Grid = [] -> Result = [] ;
% Get column count W from the first row.
     Grid = [FR|_], length(FR, W), W1 is W - 1,
% Get row count H.
     length(Grid, H), H1 is H - 1,
% For each column index, extract all cell values and settle downward.
     findall(NewCol,
         (between(0, W1, C),
          findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), ColVals),
          grid_gravity_settle_segment_(ColVals, Bg, down, NewCol)),
         Cols),
% Transpose settled column lists back into row-major grid.
     grid_gravity_cols_to_grid_(Cols, H, Result)).

% grid_gravity_fall_up(+Grid, +Bg, -Result)
% Each column: non-Bg values rise to the top; Bg fills below.
grid_gravity_fall_up(Grid, Bg, Result) :-
% Empty grid shortcut.
    (Grid = [] -> Result = [] ;
% Get column count W from the first row.
     Grid = [FR|_], length(FR, W), W1 is W - 1,
% Get row count H.
     length(Grid, H), H1 is H - 1,
% For each column, extract cell values and settle upward.
     findall(NewCol,
         (between(0, W1, C),
          findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), ColVals),
          grid_gravity_settle_segment_(ColVals, Bg, up, NewCol)),
         Cols),
% Transpose settled columns back to rows.
     grid_gravity_cols_to_grid_(Cols, H, Result)).

% grid_gravity_fall_left(+Grid, +Bg, -Result)
% Each row: non-Bg values slide to the left; Bg fills to the right.
grid_gravity_fall_left(Grid, Bg, Result) :-
% Empty grid shortcut.
    (Grid = [] -> Result = [] ;
% Get row count H.
     length(Grid, H), H1 is H - 1,
% For each row, settle leftward using grid_gravity_settle_segment_.
     findall(NewRow,
         (between(0, H1, R),
          nth0(R, Grid, Row),
          grid_gravity_settle_segment_(Row, Bg, left, NewRow)),
         Result)).

% grid_gravity_fall_right(+Grid, +Bg, -Result)
% Each row: non-Bg values slide to the right; Bg fills to the left.
grid_gravity_fall_right(Grid, Bg, Result) :-
% Empty grid shortcut.
    (Grid = [] -> Result = [] ;
% Get row count H.
     length(Grid, H), H1 is H - 1,
% For each row, settle rightward using grid_gravity_settle_segment_.
     findall(NewRow,
         (between(0, H1, R),
          nth0(R, Grid, Row),
          grid_gravity_settle_segment_(Row, Bg, right, NewRow)),
         Result)).

% grid_gravity_fall(+Grid, +Bg, +Dir, -Result)
% Dispatch gravity in direction Dir: down, up, left, or right.
grid_gravity_fall(Grid, Bg, down, Result) :- !, grid_gravity_fall_down(Grid, Bg, Result).
% Fall up direction.
grid_gravity_fall(Grid, Bg, up, Result) :- !, grid_gravity_fall_up(Grid, Bg, Result).
% Fall left direction.
grid_gravity_fall(Grid, Bg, left, Result) :- !, grid_gravity_fall_left(Grid, Bg, Result).
% Fall right direction (no cut needed as last clause).
grid_gravity_fall(Grid, Bg, right, Result) :- grid_gravity_fall_right(Grid, Bg, Result).

% grid_gravity_set_col_bottom(+Grid, +Col, +Vals, +Bg, -Result)
% Replace column Col with Vals packed to the bottom; cells above become Bg.
grid_gravity_set_col_bottom(Grid, Col, Vals, Bg, Result) :-
% Compute how many bg cells are needed above Vals.
    length(Grid, H),
    length(Vals, NV), NBg is H - NV,
% Build bg prefix.
    findall(Bg, between(1, NBg, _), BgTop),
% Assemble full column: bg at top, values at bottom.
    append(BgTop, Vals, ColVals),
% Replace the column in the grid.
    grid_gravity_set_col_(Grid, Col, ColVals, Result).

% grid_gravity_set_col_top(+Grid, +Col, +Vals, +Bg, -Result)
% Replace column Col with Vals packed to the top; cells below become Bg.
grid_gravity_set_col_top(Grid, Col, Vals, Bg, Result) :-
% Compute how many bg cells are needed below Vals.
    length(Grid, H),
    length(Vals, NV), NBg is H - NV,
% Build bg suffix.
    findall(Bg, between(1, NBg, _), BgBottom),
% Assemble full column: values at top, bg at bottom.
    append(Vals, BgBottom, ColVals),
% Replace the column in the grid.
    grid_gravity_set_col_(Grid, Col, ColVals, Result).

% grid_gravity_set_row_left(+Grid, +RowIdx, +Vals, +Bg, -Result)
% Replace row RowIdx with Vals packed to the left; cells to the right become Bg.
grid_gravity_set_row_left(Grid, RowIdx, Vals, Bg, Result) :-
% Get row width from the target row.
    nth0(RowIdx, Grid, Row), length(Row, W),
% Compute how many bg cells are needed to the right.
    length(Vals, NV), NBg is W - NV,
% Build bg suffix.
    findall(Bg, between(1, NBg, _), BgRight),
% Assemble new row: values at left, bg at right.
    append(Vals, BgRight, NewRow),
% Replace the row in the grid.
    grid_gravity_set_row_(Grid, RowIdx, NewRow, Result).

% grid_gravity_set_row_right(+Grid, +RowIdx, +Vals, +Bg, -Result)
% Replace row RowIdx with Vals packed to the right; cells to the left become Bg.
grid_gravity_set_row_right(Grid, RowIdx, Vals, Bg, Result) :-
% Get row width from the target row.
    nth0(RowIdx, Grid, Row), length(Row, W),
% Compute how many bg cells are needed to the left.
    length(Vals, NV), NBg is W - NV,
% Build bg prefix.
    findall(Bg, between(1, NBg, _), BgLeft),
% Assemble new row: bg at left, values at right.
    append(BgLeft, Vals, NewRow),
% Replace the row in the grid.
    grid_gravity_set_row_(Grid, RowIdx, NewRow, Result).

% grid_gravity_blocked_fall(+Grid, +Bg, +BlockColor, +Dir, -Result)
% Like grid_gravity_fall but BlockColor cells are immovable walls: non-bg non-block cells
% fall in Dir but stop at the near side of each BlockColor cell.
% Dir=down: process column by column.
grid_gravity_blocked_fall(Grid, Bg, BlockColor, down, Result) :- !,
    (Grid = [] -> Result = [] ;
% Get column and row dimensions.
     Grid = [FR|_], length(FR, W), W1 is W - 1,
     length(Grid, H), H1 is H - 1,
% For each column, apply segmented gravity stopping at BlockColor.
     findall(NewCol,
         (between(0, W1, C),
          findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), ColVals),
          grid_gravity_segment_apply_(ColVals, Bg, BlockColor, down, NewCol)),
         Cols),
     grid_gravity_cols_to_grid_(Cols, H, Result)).
% Dir=up: same as down but using up direction for each segment.
grid_gravity_blocked_fall(Grid, Bg, BlockColor, up, Result) :- !,
    (Grid = [] -> Result = [] ;
% Get column and row dimensions.
     Grid = [FR|_], length(FR, W), W1 is W - 1,
     length(Grid, H), H1 is H - 1,
% For each column, apply segmented gravity stopping at BlockColor.
     findall(NewCol,
         (between(0, W1, C),
          findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), ColVals),
          grid_gravity_segment_apply_(ColVals, Bg, BlockColor, up, NewCol)),
         Cols),
     grid_gravity_cols_to_grid_(Cols, H, Result)).
% Dir=left: process row by row.
grid_gravity_blocked_fall(Grid, Bg, BlockColor, left, Result) :- !,
    (Grid = [] -> Result = [] ;
% Get row count.
     length(Grid, H), H1 is H - 1,
% For each row, apply segmented gravity stopping at BlockColor.
     findall(NewRow,
         (between(0, H1, R),
          nth0(R, Grid, Row),
          grid_gravity_segment_apply_(Row, Bg, BlockColor, left, NewRow)),
         Result)).
% Dir=right: process row by row (last clause, no cut needed).
grid_gravity_blocked_fall(Grid, Bg, BlockColor, right, Result) :-
    (Grid = [] -> Result = [] ;
% Get row count.
     length(Grid, H), H1 is H - 1,
% For each row, apply segmented gravity stopping at BlockColor.
     findall(NewRow,
         (between(0, H1, R),
          nth0(R, Grid, Row),
          grid_gravity_segment_apply_(Row, Bg, BlockColor, right, NewRow)),
         Result)).

% grid_gravity_is_settled(+Grid, +Bg)
% Succeeds if grid_gravity_fall_down(Grid, Bg, Grid): the grid is unchanged by downward gravity.
grid_gravity_is_settled(Grid, Bg) :-
% Apply fall_down and unify result with original to test for no change.
    grid_gravity_fall_down(Grid, Bg, Grid).

% grid_gravity_gravity_score(+Grid, +Bg, -Score)
% Score is the number of cell positions that differ between Grid and grid_gravity_fall_down result.
% Score=0 means the grid is already settled; Score=2*N means N cells would move.
grid_gravity_gravity_score(Grid, Bg, Score) :-
% Apply fall_down to get the settled state.
    grid_gravity_fall_down(Grid, Bg, Result),
% Count positions where Grid and Result differ.
    grid_gravity_count_diff_(Grid, Result, Score).
