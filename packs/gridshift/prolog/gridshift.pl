:- module(gridshift, [
    gsh_shift_right/4,
    gsh_shift_left/4,
    gsh_shift_down/4,
    gsh_shift_up/4,
    gsh_roll_right/3,
    gsh_roll_left/3,
    gsh_roll_down/3,
    gsh_roll_up/3,
    gsh_roll_row/4,
    gsh_roll_col/4,
    gsh_shift_color/6,
    gsh_offset/5,
    gsh_shift_row/5,
    gsh_shift_col/5
]).
% gridshift.pl - Layer 230: Grid Shifting and Cyclic Rolling (gsh_* prefix).
% Fourteen predicates for shifting an entire grid (linear, with bg fill),
% rolling a grid cyclically (toroidal), rolling individual rows or columns,
% shifting cells of a specific color, offsetting the entire grid by (DR,DC),
% and shifting a single row or column.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, append/2, append/3, last/2]).

% --- PRIVATE HELPERS ---

% gsh_dims_(+Grid, -H, -W): grid dimensions.
gsh_dims_(Grid, H, W) :-
% Count rows for height.
    length(Grid, H),
% Use first row for width.
    Grid = [Row|_], length(Row, W).

% gsh_bg_row_(+W, +BgColor, -Row): create a row of W BgColor values.
gsh_bg_row_(W, BgColor, Row) :-
% Generate W copies of BgColor using between/3.
    findall(BgColor, between(1, W, _), Row).

% gsh_roll_list_(+List, +N, -Rolled): cyclically roll List right by N positions.
% The last N elements move to the front.
gsh_roll_list_(List, N, Rolled) :-
% Compute effective shift within list length.
    length(List, Len),
    N2 is N mod Len,
    PrefixLen is Len - N2,
% Split list at PrefixLen: Prefix goes to back, Suffix to front.
    length(Prefix, PrefixLen),
    append(Prefix, Suffix, List),
    append(Suffix, Prefix, Rolled).

% gsh_transpose_(+Grid, -T): transpose a rectangular grid.
gsh_transpose_([], []) :- !.
gsh_transpose_([[]|_], []) :- !.
gsh_transpose_(Grid, [Heads|Tails]) :-
% Split each row into its first element (head) and the rest (tail).
    gsh_heads_tails_(Grid, Heads, RestRows),
    gsh_transpose_(RestRows, Tails).

% gsh_heads_tails_(+Rows, -Heads, -Tails): split rows into head elements and tail lists.
gsh_heads_tails_([], [], []).
gsh_heads_tails_([[H|T]|Rest], [H|Hs], [T|Ts]) :-
% Recurse over remaining rows.
    gsh_heads_tails_(Rest, Hs, Ts).

% gsh_shift_row_r_(+Row, +N, +BgColor, -Shifted): shift one row right by N, fill left with BgColor.
gsh_shift_row_r_(Row, N, BgColor, Shifted) :-
% Clamp N to row width.
    length(Row, W), N2 is min(N, W),
    TakeLen is W - N2,
% Keep only the first TakeLen elements of the row.
    length(Keep, TakeLen), append(Keep, _, Row),
% Build N2-element bg pad.
    findall(BgColor, between(1, N2, _), Pad),
    append(Pad, Keep, Shifted).

% gsh_shift_row_l_(+Row, +N, +BgColor, -Shifted): shift one row left by N, fill right with BgColor.
gsh_shift_row_l_(Row, N, BgColor, Shifted) :-
% Clamp N to row width.
    length(Row, W), N2 is min(N, W),
    KeepLen is W - N2,
% Drop first N2 elements; keep the rest.
    length(Drop, N2), append(Drop, Keep, Row),
    length(Keep, KeepLen),
% Build N2-element bg pad.
    findall(BgColor, between(1, N2, _), Pad),
    append(Keep, Pad, Shifted).

% --- PUBLIC PREDICATES ---

% gsh_shift_right(+Grid, +N, +BgColor, -Result)
% Shift each row of Grid right by N cells; vacated left cells become BgColor.
gsh_shift_right(Grid, N, BgColor, Result) :-
% Apply row shift to every row.
    findall(NewRow,
        (member(GRow, Grid),
         gsh_shift_row_r_(GRow, N, BgColor, NewRow)),
        Result).

% gsh_shift_left(+Grid, +N, +BgColor, -Result)
% Shift each row left by N cells; vacated right cells become BgColor.
gsh_shift_left(Grid, N, BgColor, Result) :-
% Apply left row shift to every row.
    findall(NewRow,
        (member(GRow, Grid),
         gsh_shift_row_l_(GRow, N, BgColor, NewRow)),
        Result).

% gsh_shift_down(+Grid, +N, +BgColor, -Result)
% Shift all rows down by N; N new BgColor rows are added at the top;
% the bottom N rows fall off.
gsh_shift_down(Grid, N, BgColor, Result) :-
% Measure height and width.
    gsh_dims_(Grid, H, W),
    N2 is min(N, H),
    TakeLen is H - N2,
% Keep only the top TakeLen rows (they move down).
    length(TakeRows, TakeLen), append(TakeRows, _, Grid),
% Build a single bg row.
    gsh_bg_row_(W, BgColor, BgRow),
% Create N2 bg rows for the top.
    findall(BgRow, between(1, N2, _), PadRows),
    append(PadRows, TakeRows, Result).

% gsh_shift_up(+Grid, +N, +BgColor, -Result)
% Shift all rows up by N; N new BgColor rows are appended at the bottom;
% the top N rows fall off.
gsh_shift_up(Grid, N, BgColor, Result) :-
% Measure height and width.
    gsh_dims_(Grid, H, W),
    N2 is min(N, H),
    KeepLen is H - N2,
% Drop the top N2 rows; keep the rest.
    length(Drop, N2), append(Drop, KeepRows, Grid),
    length(KeepRows, KeepLen),
% Build a single bg row.
    gsh_bg_row_(W, BgColor, BgRow),
% Create N2 bg rows for the bottom.
    findall(BgRow, between(1, N2, _), PadRows),
    append(KeepRows, PadRows, Result).

% gsh_roll_right(+Grid, +N, -Result)
% Cyclically roll each row right by N cells (toroidal; last N cells wrap to front).
gsh_roll_right(Grid, N, Result) :-
% Apply cyclic row roll to every row.
    findall(NewRow,
        (member(GRow, Grid),
         gsh_roll_list_(GRow, N, NewRow)),
        Result).

% gsh_roll_left(+Grid, +N, -Result)
% Cyclically roll each row left by N cells (toroidal; first N cells wrap to back).
gsh_roll_left(Grid, N, Result) :-
% Roll left by N = roll right by (W - N mod W).
    findall(NewRow,
        (member(GRow, Grid),
         length(GRow, W),
         RN is (W - (N mod W)) mod W,
         gsh_roll_list_(GRow, RN, NewRow)),
        Result).

% gsh_roll_down(+Grid, +N, -Result)
% Cyclically roll the entire grid down by N rows (last N rows wrap to top).
gsh_roll_down(Grid, N, Result) :-
% Roll the list of rows cyclically.
    gsh_roll_list_(Grid, N, Result).

% gsh_roll_up(+Grid, +N, -Result)
% Cyclically roll the entire grid up by N rows (first N rows wrap to bottom).
gsh_roll_up(Grid, N, Result) :-
% Roll up by N = roll down by (H - N mod H).
    length(Grid, H),
    RN is (H - (N mod H)) mod H,
    gsh_roll_list_(Grid, RN, Result).

% gsh_roll_row(+Grid, +R, +N, -Result)
% Cyclically roll row R right by N positions; all other rows are unchanged.
gsh_roll_row(Grid, R, N, Result) :-
% Iterate over all rows by index.
    length(Grid, H), H1 is H - 1,
    findall(NewRow,
        (between(0, H1, RI),
         nth0(RI, Grid, GRow),
% Only modify the target row; pass others through unchanged.
         (RI =:= R ->
             gsh_roll_list_(GRow, N, NewRow)
         ;   NewRow = GRow
         )),
        Result).

% gsh_roll_col(+Grid, +C, +N, -Result)
% Cyclically roll column C down by N positions; all other columns are unchanged.
gsh_roll_col(Grid, C, N, Result) :-
% Transpose to treat columns as rows, roll the target row, transpose back.
    gsh_transpose_(Grid, TGrid),
    gsh_roll_row(TGrid, C, N, TRolled),
    gsh_transpose_(TRolled, Result).

% gsh_shift_color(+Grid, +Color, +DR, +DC, +BgColor, -Result)
% Shift all cells of Color by (DR, DC). Cells that move out-of-bounds disappear.
% Vacated positions become BgColor. Non-Color cells other than BgColor are unchanged.
% If a Color cell moves onto a non-Color cell, the Color cell takes precedence.
gsh_shift_color(Grid, Color, DR, DC, BgColor, Result) :-
% Compute grid bounds.
    gsh_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         findall(V2,
             (between(0, W1, C),
% Check if a Color source exists at the position that would shift to (R,C).
              SR is R - DR, SC is C - DC,
              (   SR >= 0, SR =< H1, SC >= 0, SC =< W1,
                  nth0(SR, Grid, SRow), nth0(SC, SRow, Color)
% Source exists: destination cell becomes Color.
              ->  V2 = Color
              ;
% No Color source: if current cell was Color (it moved away), it becomes BgColor.
                  nth0(R, Grid, GRow), nth0(C, GRow, V0),
                  (V0 = Color -> V2 = BgColor ; V2 = V0)
              )),
             NewRow)),
        Result).

% gsh_offset(+Grid, +DR, +DC, +BgColor, -Result)
% Shift the entire grid by (DR, DC): Result[R][C] = Grid[R-DR][C-DC] if in bounds,
% else BgColor. Equivalent to shifting all non-BgColor cells, including BgColor cells.
gsh_offset(Grid, DR, DC, BgColor, Result) :-
% Compute grid bounds.
    gsh_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         findall(V,
             (between(0, W1, C),
              SR is R - DR, SC is C - DC,
% In-bounds source: use grid value. OOB: use BgColor.
              (   SR >= 0, SR =< H1, SC >= 0, SC =< W1
              ->  nth0(SR, Grid, SRow), nth0(SC, SRow, V)
              ;   V = BgColor
              )),
             NewRow)),
        Result).

% gsh_shift_row(+Grid, +R, +N, +BgColor, -Result)
% Shift row R horizontally by N cells (positive = right, negative = left);
% vacated cells become BgColor. All other rows are unchanged.
gsh_shift_row(Grid, R, N, BgColor, Result) :-
% Iterate over all rows by index.
    length(Grid, H), H1 is H - 1,
    findall(NewRow,
        (between(0, H1, RI),
         nth0(RI, Grid, GRow),
% Apply shift only to the target row.
         (RI =:= R ->
             (N >= 0 ->
                 gsh_shift_row_r_(GRow, N, BgColor, NewRow)
             ;   N2 is -N,
                 gsh_shift_row_l_(GRow, N2, BgColor, NewRow)
             )
         ;   NewRow = GRow
         )),
        Result).

% gsh_shift_col(+Grid, +C, +N, +BgColor, -Result)
% Shift column C vertically by N cells (positive = down, negative = up);
% vacated cells become BgColor. All other columns are unchanged.
gsh_shift_col(Grid, C, N, BgColor, Result) :-
% Transpose to treat column C as a row, shift it, then transpose back.
    gsh_transpose_(Grid, TGrid),
    gsh_shift_row(TGrid, C, N, BgColor, TShifted),
    gsh_transpose_(TShifted, Result).
