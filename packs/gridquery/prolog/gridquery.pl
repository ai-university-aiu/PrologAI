% gridquery.pl - Layer 196: Grid Query and Manipulation for Raw Grid Format (gq_* prefix).
% A raw grid is a list of rows, each row a list of color atoms. Position (R,C) is
% 0-indexed (R=row from top, C=column from left). Predicates cover size queries,
% cell access, row/column extraction, color statistics, rectangular region extraction,
% grid difference, structural operations (transpose, replace, fill).
% No cross-pack dependencies.
:- module(gridquery, [
    % gridquery_size/3: height and width of a grid.
    gridquery_size/3,
    % gridquery_at/4: color at position (R,C) in the grid.
    gridquery_at/4,
    % gridquery_row/3: extract row R as a list.
    gridquery_row/3,
    % gridquery_col/3: extract column C as a list.
    gridquery_col/3,
    % gridquery_colors/2: sorted list of distinct colors appearing in the grid.
    gridquery_colors/2,
    % gridquery_n_cells/3: count of cells matching a given color.
    gridquery_n_cells/3,
    % gridquery_most_freq_color/2: color with the most cells (background color by frequency).
    gridquery_most_freq_color/2,
    % gridquery_region/6: rectangular sub-grid bounded by (R0,C0)-(R1,C1) inclusive.
    gridquery_region/6,
    % gridquery_diff/3: list of r(R,C) cells where Grid1 and Grid2 have different colors.
    gridquery_diff/3,
    % gridquery_n_diff/3: count of differing cells between two same-size grids.
    gridquery_n_diff/3,
    % gridquery_same_size/2: succeed if two grids have the same height and width.
    gridquery_same_size/2,
    % gridquery_transpose/2: transpose the grid (rows become columns).
    gridquery_transpose/2,
    % gridquery_replace/5: replace the color at one cell and return the new grid.
    gridquery_replace/5,
    % gridquery_fill_region/7: fill a rectangular region with a given color.
    gridquery_fill_region/7
]).

% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, last/2]).
% Import apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% gridquery_size(+Grid, -H, -W)
% H is the number of rows; W is the number of columns.
% W is derived from the first row; 0 for an empty grid.
gridquery_size(Grid, H, W) :-
% Measure the number of rows.
    length(Grid, H),
% Measure the number of columns from the first row; zero for empty.
    (H > 0 -> Grid = [Row|_], length(Row, W) ; W = 0).

% gridquery_at(+Grid, +R, +C, -Color)
% Color is the value at row R, column C (both 0-indexed).
gridquery_at(Grid, R, C, Color) :-
% Retrieve row R from the grid using nth0.
    nth0(R, Grid, Row),
% Retrieve column C from that row.
    nth0(C, Row, Color).

% gridquery_row(+Grid, +R, -Row)
% Row is the Rth row of Grid (0-indexed).
gridquery_row(Grid, R, Row) :-
% Use nth0 to retrieve the row.
    nth0(R, Grid, Row).

% gridquery_col(+Grid, +C, -Col)
% Col is the Cth column of Grid, as a list of values top-to-bottom.
gridquery_col(Grid, C, Col) :-
% For each row, extract the Cth element.
    maplist([Row, Cell]>>(nth0(C, Row, Cell)), Grid, Col).

% gridquery_colors(+Grid, -Colors)
% Colors is a sorted list of distinct color atoms in Grid.
gridquery_colors(Grid, Colors) :-
% Flatten all rows into a single cell list.
    findall(Cell, (member(Row, Grid), member(Cell, Row)), All),
% sort/2 removes duplicates and sorts.
    sort(All, Colors).

% gridquery_n_cells(+Grid, +Color, -N)
% N is the number of cells in Grid with value Color.
gridquery_n_cells(Grid, Color, N) :-
% Collect all cells matching Color.
    findall(_, (member(Row, Grid), member(Color, Row)), Matches),
% Length gives the count.
    length(Matches, N).

% gridquery_most_freq_color(+Grid, -Color)
% Color is the most frequent cell value in Grid. Ties broken by term order.
% Fails for an empty grid.
gridquery_most_freq_color(Grid, Color) :-
% Get all distinct colors first.
    gridquery_colors(Grid, Colors),
    Colors \= [],
% Count each color and key by negative count for msort descending.
    findall(NegN-C, (member(C, Colors), gridquery_n_cells(Grid, C, N), NegN is -N), Keyed),
    msort(Keyed, [_-Color | _]).

% gridquery_region(+Grid, +R0, +C0, +R1, +C1, -SubGrid)
% SubGrid is the sub-grid covering rows R0..R1 and columns C0..C1 (inclusive).
gridquery_region(Grid, R0, C0, R1, C1, SubGrid) :-
% Enumerate the row indices from R0 to R1.
    numlist(R0, R1, RowIdxs),
% For each row index, extract the row and slice the column range.
    maplist(gridquery_region_row_(Grid, C0, C1), RowIdxs, SubGrid).

% gridquery_region_row_(+Grid, +C0, +C1, +R, -Slice): extract row R sliced to columns C0..C1.
gridquery_region_row_(Grid, C0, C1, R, Slice) :-
% Retrieve row R.
    nth0(R, Grid, Row),
% Enumerate column indices.
    numlist(C0, C1, ColIdxs),
% Extract the cell at each column index.
    maplist([Ci, Cell]>>(nth0(Ci, Row, Cell)), ColIdxs, Slice).

% gridquery_diff(+Grid1, +Grid2, -Cells)
% Cells is a list of r(R,C) positions where Grid1 and Grid2 have different values.
% Both grids must have the same dimensions.
gridquery_diff(Grid1, Grid2, Cells) :-
    gridquery_size(Grid1, H, W),
% Enumerate all (R,C) pairs and keep those where the colors differ.
    findall(r(R,C),
        (gridquery_row_(Grid1, Grid2, H, W, R, C)),
        Cells).

% gridquery_row_(+Grid1, +Grid2, +H, +W, -R, -C): enumerate all differing positions.
gridquery_row_(Grid1, Grid2, H, W, R, C) :-
    H1 is H - 1, W1 is W - 1,
    between(0, H1, R), between(0, W1, C),
    nth0(R, Grid1, Row1), nth0(C, Row1, V1),
    nth0(R, Grid2, Row2), nth0(C, Row2, V2),
    V1 \== V2.

% gridquery_n_diff(+Grid1, +Grid2, -N)
% N is the number of cells where Grid1 and Grid2 differ.
gridquery_n_diff(Grid1, Grid2, N) :-
    gridquery_diff(Grid1, Grid2, Cells),
    length(Cells, N).

% gridquery_same_size(+Grid1, +Grid2)
% Succeed if Grid1 and Grid2 have the same height and width.
gridquery_same_size(Grid1, Grid2) :-
    gridquery_size(Grid1, H, W),
    gridquery_size(Grid2, H, W).

% gridquery_transpose(+Grid, -Transposed)
% Transposed has rows and columns swapped: Transposed[C][R] = Grid[R][C].
% For an empty grid or a grid with no columns, Transposed is [].
gridquery_transpose(Grid, Transposed) :-
    gridquery_size(Grid, H, W),
% For an empty grid or zero-width grid, return empty.
    (H =:= 0 -> Transposed = []
    ; W =:= 0 -> Transposed = []
    ;
% Enumerate column indices 0..W-1; for each, extract that column.
        W1 is W - 1,
        numlist(0, W1, ColIdxs),
        maplist(gridquery_col(Grid), ColIdxs, Transposed)
    ).

% gridquery_replace(+Grid, +R, +C, +Color, -NewGrid)
% NewGrid is Grid with the cell at (R,C) replaced by Color.
gridquery_replace(Grid, R, C, Color, NewGrid) :-
% Get the height for row index range.
    length(Grid, H), H1 is H - 1,
% Rebuild the grid: rows before R unchanged, row R replaced, rows after R unchanged.
    numlist(0, H1, RowIdxs),
    maplist(gridquery_replace_row_(Grid, R, C, Color), RowIdxs, NewGrid).

% gridquery_replace_row_(+Grid, +TargetR, +TargetC, +Color, +RowIdx, -NewRow).
gridquery_replace_row_(Grid, TargetR, TargetC, Color, RowIdx, NewRow) :-
    nth0(RowIdx, Grid, OldRow),
    (RowIdx =:= TargetR ->
% This is the target row: replace cell at TargetC.
        gridquery_replace_cell_(OldRow, TargetC, Color, NewRow)
    ;
% Other rows: unchanged.
        NewRow = OldRow
    ).

% gridquery_replace_cell_(+Row, +TargetC, +Color, -NewRow): replace cell at TargetC in Row.
gridquery_replace_cell_(Row, TargetC, Color, NewRow) :-
    length(Row, W), W1 is W - 1,
    numlist(0, W1, ColIdxs),
    maplist(gridquery_pick_cell_(Row, TargetC, Color), ColIdxs, NewRow).

% gridquery_pick_cell_(+Row, +TargetC, +Color, +ColIdx, -Cell): pick original or replaced.
gridquery_pick_cell_(Row, TargetC, Color, ColIdx, Cell) :-
    (ColIdx =:= TargetC ->
        Cell = Color
    ;
        nth0(ColIdx, Row, Cell)
    ).

% gridquery_fill_region(+Grid, +R0, +C0, +R1, +C1, +Color, -NewGrid)
% NewGrid is Grid with every cell in the rectangle (R0,C0)-(R1,C1) set to Color.
gridquery_fill_region(Grid, R0, C0, R1, C1, Color, NewGrid) :-
    length(Grid, H), H1 is H - 1,
    numlist(0, H1, RowIdxs),
    maplist(gridquery_fill_row_(Grid, R0, C0, R1, C1, Color), RowIdxs, NewGrid).

% gridquery_fill_row_(+Grid, +R0, +C0, +R1, +C1, +Color, +RowIdx, -NewRow).
gridquery_fill_row_(Grid, R0, C0, R1, C1, Color, RowIdx, NewRow) :-
    nth0(RowIdx, Grid, OldRow),
    (RowIdx >= R0, RowIdx =< R1 ->
% Row is in the target range: fill cells C0..C1.
        gridquery_fill_cells_(OldRow, C0, C1, Color, NewRow)
    ;
% Row is outside the target range: unchanged.
        NewRow = OldRow
    ).

% gridquery_fill_cells_(+Row, +C0, +C1, +Color, -NewRow): fill C0..C1 with Color.
gridquery_fill_cells_(Row, C0, C1, Color, NewRow) :-
    length(Row, W), W1 is W - 1,
    numlist(0, W1, ColIdxs),
    maplist(gridquery_fill_cell_(C0, C1, Color, Row), ColIdxs, NewRow).

% gridquery_fill_cell_(+C0, +C1, +Color, +Row, +ColIdx, -Cell): return Color if in range, else original.
gridquery_fill_cell_(C0, C1, Color, Row, ColIdx, Cell) :-
    (ColIdx >= C0, ColIdx =< C1 ->
        Cell = Color
    ;
        nth0(ColIdx, Row, Cell)
    ).
