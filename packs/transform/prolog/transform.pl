% Module declaration: transform pack, Layer 52.
:- module(transform, [
    % tr_scale_up/3: expand each cell to a Factor x Factor block.
    tr_scale_up/3,
    % tr_scale_down/3: keep every Factor-th row and column.
    tr_scale_down/3,
    % tr_tile_h/3: tile the grid N times horizontally.
    tr_tile_h/3,
    % tr_tile_v/3: tile the grid N times vertically.
    tr_tile_v/3,
    % tr_tile/3: tile the grid N times in both directions.
    tr_tile/3,
    % tr_transpose/2: swap rows and columns.
    tr_transpose/2,
    % tr_flip_h/2: reverse each row (left-right mirror).
    tr_flip_h/2,
    % tr_flip_v/2: reverse the row list (top-bottom mirror).
    tr_flip_v/2,
    % tr_rot90/2: rotate the grid 90 degrees clockwise.
    tr_rot90/2,
    % tr_rot180/2: rotate the grid 180 degrees.
    tr_rot180/2,
    % tr_shift/5: shift grid content by DR rows and DC cols, filling gaps.
    tr_shift/5,
    % tr_apply_map/3: apply a list of From-To color pairs to every cell.
    tr_apply_map/3,
    % tr_replace_color/4: replace every occurrence of one color with another.
    tr_replace_color/4,
    % tr_mask_grid/4: where Mask cell is 0, replace Grid cell with Fill.
    tr_mask_grid/4
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, append/2, append/3,
                                 nth0/3, numlist/3, reverse/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4,
                                 include/3]).

% tr_grid_dims_(+Grid, -Rows, -Cols): measure grid dimensions.
tr_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from the first row; 0 if grid is empty.
    ( Rows > 0 -> Grid = [R1|_], length(R1, Cols) ; Cols = 0 ).

% tr_repeat_val_(+N, +V, -List): N copies of V in a list.
tr_repeat_val_(N, V, List) :-
    % Allocate list of length N then fill with V.
    length(List, N),
    maplist(=(V), List).

% tr_scale_row_(+Factor, +Row, -Expanded): each cell repeated Factor times.
tr_scale_row_(Factor, Row, Expanded) :-
    % Map each value to a run of Factor copies, then flatten.
    maplist(tr_repeat_val_(Factor), Row, Runs),
    append(Runs, Expanded).

% tr_replicate_rows_(+Rows, +Factor, -Result): each row duplicated Factor times.
tr_replicate_rows_([], _, []).
tr_replicate_rows_([R|Rs], Factor, Result) :-
    % Make Factor identical copies of row R.
    length(Copies, Factor),
    maplist(=(R), Copies),
    % Recurse on the remaining rows.
    tr_replicate_rows_(Rs, Factor, Rest),
    append(Copies, Rest, Result).

% tr_scale_up(+Grid, +Factor, -Scaled): each cell becomes a Factor x Factor block.
tr_scale_up(Grid, Factor, Scaled) :-
    % Require a positive factor.
    Factor > 0,
    % Expand each row horizontally.
    maplist(tr_scale_row_(Factor), Grid, WideRows),
    % Then repeat each row Factor times vertically.
    tr_replicate_rows_(WideRows, Factor, Scaled).

% tr_divisible_(+N, +X): X mod N = 0.
tr_divisible_(N, X) :- X mod N =:= 0.

% tr_pick_cols_(+Row, +ColIds, -Selected): extract cells at given column indices.
tr_pick_cols_(_Row, [], []) :- !.
tr_pick_cols_(Row, [C|Cs], [V|Vs]) :-
    % Retrieve cell at column C.
    nth0(C, Row, V),
    tr_pick_cols_(Row, Cs, Vs).

% tr_scale_down(+Grid, +Factor, -Scaled): keep every Factor-th row and column.
tr_scale_down(Grid, Factor, Scaled) :-
    % Require a positive factor.
    Factor > 0,
    tr_grid_dims_(Grid, Rows, Cols),
    % Enumerate all row indices.
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, AllRowIds) ; AllRowIds = [] ),
    % Keep only rows divisible by Factor.
    include(tr_divisible_(Factor), AllRowIds, SelRowIds),
    % Enumerate all column indices.
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, AllColIds) ; AllColIds = [] ),
    % Keep only columns divisible by Factor.
    include(tr_divisible_(Factor), AllColIds, SelColIds),
    % Extract selected rows, then selected columns from each row.
    maplist(tr_down_row_(Grid, SelColIds), SelRowIds, Scaled).

% tr_down_row_(+Grid, +SelColIds, +R, -Row): extract row R and selected columns.
tr_down_row_(Grid, SelColIds, R, Row) :-
    % Get the full row.
    nth0(R, Grid, FullRow),
    % Then pick the selected columns.
    tr_pick_cols_(FullRow, SelColIds, Row),
    !.

% tr_tile_row_(+N, +Row, -Tiled): concatenate Row with itself N times.
tr_tile_row_(N, Row, Tiled) :-
    % N copies of the row list.
    length(Copies, N),
    maplist(=(Row), Copies),
    append(Copies, Tiled).

% tr_tile_h(+Grid, +N, -Tiled): repeat each row N times (widen the grid).
tr_tile_h(Grid, N, Tiled) :-
    % Require a positive tile count.
    N > 0,
    maplist(tr_tile_row_(N), Grid, Tiled).

% tr_tile_v(+Grid, +N, -Tiled): repeat the row list N times (heighten the grid).
tr_tile_v(Grid, N, Tiled) :-
    % Require a positive tile count.
    N > 0,
    % N copies of the grid row list.
    length(Copies, N),
    maplist(=(Grid), Copies),
    append(Copies, Tiled).

% tr_tile(+Grid, +N, -Tiled): tile in both directions N times.
tr_tile(Grid, N, Tiled) :-
    % Tile horizontally first, then vertically.
    tr_tile_h(Grid, N, H),
    tr_tile_v(H, N, Tiled).

% tr_heads_tails_(+Rows, -Heads, -Tails): split each row into head and tail.
tr_heads_tails_([], [], []).
tr_heads_tails_([[H|T]|Rows], [H|Hs], [T|Ts]) :-
    tr_heads_tails_(Rows, Hs, Ts).

% tr_transpose_(+Rows, -Transposed): recursive column-extraction transpose.
tr_transpose_([], []).
tr_transpose_([[]|_], []) :- !.
tr_transpose_(Rows, [Col|Cols]) :-
    % Split each row: Col = all first elements, Tails = all remaining rows.
    tr_heads_tails_(Rows, Col, Tails),
    tr_transpose_(Tails, Cols).

% tr_transpose(+Grid, -Transposed): swap rows and columns.
tr_transpose(Grid, Transposed) :-
    tr_transpose_(Grid, Transposed).

% tr_flip_h(+Grid, -Flipped): reverse each row (left-right mirror).
tr_flip_h(Grid, Flipped) :-
    maplist(reverse, Grid, Flipped).

% tr_flip_v(+Grid, -Flipped): reverse the row list (top-bottom mirror).
tr_flip_v(Grid, Flipped) :-
    reverse(Grid, Flipped).

% tr_rot90(+Grid, -Rotated): rotate 90 degrees clockwise.
tr_rot90(Grid, Rotated) :-
    % Clockwise 90 = transpose then flip each row left-right.
    tr_transpose(Grid, T),
    tr_flip_h(T, Rotated).

% tr_rot180(+Grid, -Rotated): rotate 180 degrees.
tr_rot180(Grid, Rotated) :-
    % 180 rotation = flip vertically then horizontally.
    tr_flip_v(Grid, V),
    tr_flip_h(V, Rotated).

% tr_shift_cell_(+Grid, +Rows, +Cols, +DR, +DC, +Fill, +R, +C, -Val):
%   value at shifted position; Fill when source is out of bounds.
tr_shift_cell_(Grid, Rows, Cols, DR, DC, Fill, R, C, Val) :-
    % Compute source coordinates.
    SR is R - DR,
    SC is C - DC,
    % Use source value if in bounds, otherwise Fill.
    ( SR >= 0, SR < Rows, SC >= 0, SC < Cols
    -> nth0(SR, Grid, SRow), nth0(SC, SRow, Val)
    ;  Val = Fill ).

% tr_shift_row_(+Grid, +Rows, +Cols, +DR, +DC, +Fill, +ColIds, +R, -Row):
%   build one shifted output row.
tr_shift_row_(Grid, Rows, Cols, DR, DC, Fill, ColIds, R, Row) :-
    maplist(tr_shift_cell_(Grid, Rows, Cols, DR, DC, Fill, R), ColIds, Row).

% tr_shift(+Grid, +DR, +DC, +Fill, -Shifted): translate content by (DR,DC) rows/cols.
tr_shift(Grid, DR, DC, Fill, Shifted) :-
    tr_grid_dims_(Grid, Rows, Cols),
    % Build index lists for output (same size as input).
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = [] ),
    maplist(tr_shift_row_(Grid, Rows, Cols, DR, DC, Fill, ColIds), RowIds, Shifted).

% tr_map_cell_(+Map, +V, -Out): look up V in From-To pair list; keep V if absent.
tr_map_cell_(Map, V, Out) :-
    ( member(V-To, Map) -> Out = To ; Out = V ).

% tr_map_row_(+Map, +Row, -MRow): apply color map to each cell in a row.
tr_map_row_(Map, Row, MRow) :-
    maplist(tr_map_cell_(Map), Row, MRow).

% tr_apply_map(+Grid, +Map, -Result): apply From-To color pairs to every cell.
tr_apply_map(Grid, Map, Result) :-
    maplist(tr_map_row_(Map), Grid, Result).

% tr_replace_color(+Grid, +From, +To, -Result): single-color substitution.
tr_replace_color(Grid, From, To, Result) :-
    % Delegate to tr_apply_map with a single-entry map.
    tr_apply_map(Grid, [From-To], Result).

% tr_mask_cell_(+Fill, +G, +M, -V): where M=0 use Fill, else keep G.
tr_mask_cell_(Fill, _G, 0, Fill) :- !.
tr_mask_cell_(_Fill, G, _M, G).

% tr_mask_row_(+Fill, +GRow, +MRow, -RRow): apply mask to one row.
tr_mask_row_(Fill, GRow, MRow, RRow) :-
    maplist(tr_mask_cell_(Fill), GRow, MRow, RRow).

% tr_mask_grid(+Grid, +Mask, +Fill, -Result): replace masked cells with Fill.
tr_mask_grid(Grid, Mask, Fill, Result) :-
    % Mask has same dimensions as Grid; 0 means "use Fill".
    maplist(tr_mask_row_(Fill), Grid, Mask, Result).
