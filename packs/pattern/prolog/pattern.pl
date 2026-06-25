% Module declaration: pattern exports all pt_* predicates.
:- module(pattern, [
    pt_list_period/2,
    pt_row_period/3,
    pt_col_period/3,
    pt_tile_grid/4,
    pt_extract_tile/4,
    pt_is_tiling/3,
    pt_scale_up/3,
    pt_scale_down/3,
    pt_repeat_h/3,
    pt_repeat_v/3,
    pt_mirror_h/2,
    pt_mirror_v/2,
    pt_checkerboard/5,
    pt_stripe_h/4,
    pt_stripe_v/4
]).

% Import list utilities needed by this module.
:- use_module(library(lists), [nth0/3, append/2, append/3, numlist/3]).
% Import higher-order utilities needed by this module.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Import grid pack for all gd_* operations.
:- use_module(library(grid)).


% LIST PERIOD DETECTION
% pt_list_period(+List, -Period): shortest positive integer P such that List[i]=List[i mod P].
pt_list_period(List, Period) :-
% Get the list length so we know the search bound.
    length(List, N),
% N must be positive for a period to be meaningful.
    N > 0,
% Try periods 1 through N in increasing order.
    between(1, N, Period),
% Check whether Period is a valid period for this list.
    list_has_period(List, Period),
% Cut to return only the shortest valid period.
    !.

% list_has_period(+List, +P): every element matches the element P positions back.
list_has_period(List, P) :-
% Build the full index range 0 to N-1.
    length(List, N),
    N1 is N - 1,
    numlist(0, N1, Indices),
% Every index must satisfy the period equality.
    maplist(check_period(List, P), Indices).

% check_period(+List, +P, +I): element at I must equal element at (I mod P).
check_period(List, P, I) :-
% Compute canonical index within one tile of the period.
    Base is I mod P,
% Extract both elements.
    nth0(I, List, ElemI),
    nth0(Base, List, ElemBase),
% Structural equality (no unification side effects).
    ElemI == ElemBase.


% ROW AND COLUMN PERIOD QUERIES
% pt_row_period(+Grid, +R, -Period): shortest horizontal period of row R.
pt_row_period(Grid, R, Period) :-
% Pull out the row as a flat list of colors.
    gd_row(Grid, R, Row),
% Delegate to the general list-period predicate.
    pt_list_period(Row, Period).

% pt_col_period(+Grid, +C, -Period): shortest vertical period of column C.
pt_col_period(Grid, C, Period) :-
% Pull out the column as a flat list of colors.
    gd_col(Grid, C, Col),
% Delegate to the general list-period predicate.
    pt_list_period(Col, Period).


% TILE-BASED GRID CONSTRUCTION
% pt_tile_grid(+Tile, +Rows, +Cols, -Grid): fill Rows x Cols grid by repeating Tile.
pt_tile_grid(Tile, Rows, Cols, Grid) :-
% Get tile dimensions for the modular index mapping.
    gd_size(Tile, TR, TC),
% Build the output row list one row at a time.
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(build_tiled_row(Tile, TR, TC, Cols), RowIndices, Grid).

% build_tiled_row(+Tile,+TR,+TC,+Cols,+R,-Row): one row of the tiled grid.
build_tiled_row(Tile, TR, TC, Cols, R, Row) :-
% Map this output row to the corresponding tile row via modulo.
    TileR is R mod TR,
% Extract that tile row.
    gd_row(Tile, TileR, TileRow),
% Build column indices for this row.
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
% Map each column index to the tiled cell color.
    maplist(tiled_cell(TileRow, TC), ColIndices, Row).

% tiled_cell(+TileRow, +TC, +C, -Color): color at column C from the tile row.
tiled_cell(TileRow, TC, C, Color) :-
% Map output column to tile column via modulo.
    TileC is C mod TC,
% Extract the color at that tile position.
    nth0(TileC, TileRow, Color).

% pt_extract_tile(+Grid, +TileRows, +TileCols, -Tile): crop the top-left sub-grid.
pt_extract_tile(Grid, TileRows, TileCols, Tile) :-
% Compute the inclusive bottom-right corner of the tile.
    R1 is TileRows - 1,
    C1 is TileCols - 1,
% Delegate to gd_crop for the actual extraction.
    gd_crop(Grid, 0, 0, R1, C1, Tile).

% pt_is_tiling(+Grid, +Tile, +RowPeriod): verify Grid is a proper tiling of Tile.
pt_is_tiling(Grid, Tile, RowPeriod) :-
% Get overall grid dimensions.
    gd_size(Grid, Rows, Cols),
% Get tile dimensions.
    gd_size(Tile, TR, TC),
% The row period must match the tile height.
    RowPeriod =:= TR,
% The tile width must evenly divide the grid width.
    0 is Cols mod TC,
% Reconstruct the expected tiling and compare cell by cell.
    pt_tile_grid(Tile, Rows, Cols, Expected),
    gd_equal(Grid, Expected).


% SCALING OPERATIONS
% pt_scale_up(+Grid, +Factor, -Grid2): expand each cell to a Factor x Factor block.
pt_scale_up(Grid, Factor, Grid2) :-
% Compute new grid dimensions.
    gd_size(Grid, Rows, Cols),
    NewRows is Rows * Factor,
% Build each row of the enlarged grid.
    NewR1 is NewRows - 1,
    numlist(0, NewR1, RowIndices),
    maplist(scale_up_row(Grid, Factor, Cols), RowIndices, Grid2).

% scale_up_row(+Grid,+Factor,+Cols,+R2,-Row2): one enlarged row.
scale_up_row(Grid, Factor, Cols, R2, Row2) :-
% Map enlarged row index back to original row.
    OrigR is R2 // Factor,
% Compute number of enlarged columns.
    NewCols is Cols * Factor,
    NewC1 is NewCols - 1,
    numlist(0, NewC1, ColIndices),
% Map each enlarged column index to its color.
    maplist(scale_up_cell(Grid, Factor, OrigR), ColIndices, Row2).

% scale_up_cell(+Grid,+Factor,+OrigR,+C2,-Color): color at enlarged cell (OrigR,C2).
scale_up_cell(Grid, Factor, OrigR, C2, Color) :-
% Map enlarged column index back to original column.
    OrigC is C2 // Factor,
% Fetch the color from the original grid.
    gd_cell(Grid, OrigR, OrigC, Color).

% pt_scale_down(+Grid, +Factor, -Grid2): collapse each Factor x Factor block to one cell.
pt_scale_down(Grid, Factor, Grid2) :-
% Compute reduced dimensions via integer division.
    gd_size(Grid, Rows, Cols),
    NewRows is Rows // Factor,
    NewCols is Cols // Factor,
% Build each row of the reduced grid.
    NewR1 is NewRows - 1,
    numlist(0, NewR1, RowIndices),
    maplist(scale_down_row(Grid, Factor, NewCols), RowIndices, Grid2).

% scale_down_row(+Grid,+Factor,+NewCols,+R,-Row): one reduced row.
scale_down_row(Grid, Factor, NewCols, R, Row) :-
% Map reduced row to top-left row of its source block.
    OrigR is R * Factor,
    NewC1 is NewCols - 1,
    numlist(0, NewC1, ColIndices),
    maplist(scale_down_cell(Grid, Factor, OrigR), ColIndices, Row).

% scale_down_cell(+Grid,+Factor,+OrigR,+C,-Color): sample top-left of source block.
scale_down_cell(Grid, Factor, OrigR, C, Color) :-
% Map reduced column to top-left column of its source block.
    OrigC is C * Factor,
% Use the top-left representative cell.
    gd_cell(Grid, OrigR, OrigC, Color).


% REPETITION OPERATIONS
% pt_repeat_h(+Grid, +N, -Grid2): concatenate N copies of Grid horizontally.
pt_repeat_h(Grid, N, Grid2) :-
% Get the number of rows to iterate over.
    gd_size(Grid, Rows, _),
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
% Build each output row by repeating the source row N times.
    maplist(repeat_row_h(Grid, N), RowIndices, Grid2).

% repeat_row_h(+Grid,+N,+R,-Row2): row R repeated N times side by side.
repeat_row_h(Grid, N, R, Row2) :-
% Extract the source row.
    gd_row(Grid, R, Row),
% Build N identical copies.
    length(Copies, N),
    maplist(=(Row), Copies),
% Concatenate the list of copies (each is a flat row list).
    append(Copies, Row2).

% pt_repeat_v(+Grid, +N, -Grid2): stack N copies of Grid vertically.
pt_repeat_v(Grid, N, Grid2) :-
% Build N identical copies of the full row list.
    length(Copies, N),
    maplist(=(Grid), Copies),
% Concatenate the copies (each is a list of rows).
    append(Copies, Grid2).


% MIRRORING OPERATIONS
% pt_mirror_h(+Grid, -Grid2): append the left-right reflection to the right.
pt_mirror_h(Grid, Grid2) :-
% Reflect the grid horizontally (flip left to right).
    gd_reflect_v(Grid, Reflected),
% Get row count.
    gd_size(Grid, Rows, _),
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
% Concatenate original and reflected rows pairwise.
    maplist(concat_rows(Grid, Reflected), RowIndices, Grid2).

% concat_rows(+GridA, +GridB, +R, -Row): row R of GridA followed by row R of GridB.
concat_rows(GridA, GridB, R, Row) :-
% Extract both rows.
    gd_row(GridA, R, RowA),
    gd_row(GridB, R, RowB),
% Concatenate them into one longer row.
    append(RowA, RowB, Row).

% pt_mirror_v(+Grid, -Grid2): append the upside-down reflection below.
pt_mirror_v(Grid, Grid2) :-
% Reflect the grid vertically (flip top to bottom).
    gd_reflect_h(Grid, Reflected),
% Stack original rows above reflected rows.
    append(Grid, Reflected, Grid2).


% CONSTRUCTED PATTERN GENERATORS
% pt_checkerboard(+Rows, +Cols, +CA, +CB, -Grid): two-color checkerboard.
pt_checkerboard(Rows, Cols, CA, CB, Grid) :-
% Build each row of the checkerboard.
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(checker_row(Cols, CA, CB), RowIndices, Grid).

% checker_row(+Cols, +CA, +CB, +R, -Row): one checkerboard row.
checker_row(Cols, CA, CB, R, Row) :-
% Build each cell in the row.
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
    maplist(checker_cell(CA, CB, R), ColIndices, Row).

% checker_cell(+CA, +CB, +R, +C, -Color): even parity -> CA, odd parity -> CB.
checker_cell(CA, CB, R, C, Color) :-
% Parity of (R+C) determines which color this cell takes.
    ( (R + C) mod 2 =:= 0 -> Color = CA ; Color = CB ).

% pt_stripe_h(+Rows, +Cols, +Colors, -Grid): horizontal stripes cycling through Colors.
pt_stripe_h(Rows, Cols, Colors, Grid) :-
% Each row has a uniform color selected by (R mod NumColors).
    length(Colors, NC),
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(stripe_h_row(Colors, NC, Cols), RowIndices, Grid).

% stripe_h_row(+Colors, +NC, +Cols, +R, -Row): one uniform-color row.
stripe_h_row(Colors, NC, Cols, R, Row) :-
% Select the color for this stripe row.
    ColorIdx is R mod NC,
    nth0(ColorIdx, Colors, Color),
% Fill all columns with the selected color.
    length(Row, Cols),
    maplist(=(Color), Row).

% pt_stripe_v(+Rows, +Cols, +Colors, -Grid): vertical stripes cycling through Colors.
pt_stripe_v(Rows, Cols, Colors, Grid) :-
% Each column has a uniform color selected by (C mod NumColors).
    length(Colors, NC),
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(stripe_v_row(Colors, NC, Cols), RowIndices, Grid).

% stripe_v_row(+Colors, +NC, +Cols, +_R, -Row): row where each cell uses its column color.
stripe_v_row(Colors, NC, Cols, _R, Row) :-
% Build column indices.
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
% Map each column index to its stripe color.
    maplist(stripe_v_cell(Colors, NC), ColIndices, Row).

% stripe_v_cell(+Colors, +NC, +C, -Color): color for column C's stripe.
stripe_v_cell(Colors, NC, C, Color) :-
% Select color based on column position modulo stripe count.
    ColorIdx is C mod NC,
    nth0(ColorIdx, Colors, Color).
