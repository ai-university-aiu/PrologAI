% gridquery.pl - Layer 196: Grid Query and Manipulation for Raw Grid Format (gq_* prefix).
% A raw grid is a list of rows, each row a list of color atoms. Position (R,C) is
% 0-indexed (R=row from top, C=column from left). Predicates cover size queries,
% cell access, row/column extraction, color statistics, rectangular region extraction,
% grid difference, structural operations (transpose, replace, fill).
% No cross-pack dependencies.
:- module(gridquery, [
    % gq_size/3: height and width of a grid.
    gq_size/3,
    % gq_at/4: color at position (R,C) in the grid.
    gq_at/4,
    % gq_row/3: extract row R as a list.
    gq_row/3,
    % gq_col/3: extract column C as a list.
    gq_col/3,
    % gq_colors/2: sorted list of distinct colors appearing in the grid.
    gq_colors/2,
    % gq_n_cells/3: count of cells matching a given color.
    gq_n_cells/3,
    % gq_most_freq_color/2: color with the most cells (background color by frequency).
    gq_most_freq_color/2,
    % gq_region/6: rectangular sub-grid bounded by (R0,C0)-(R1,C1) inclusive.
    gq_region/6,
    % gq_diff/3: list of r(R,C) cells where Grid1 and Grid2 have different colors.
    gq_diff/3,
    % gq_n_diff/3: count of differing cells between two same-size grids.
    gq_n_diff/3,
    % gq_same_size/2: succeed if two grids have the same height and width.
    gq_same_size/2,
    % gq_transpose/2: transpose the grid (rows become columns).
    gq_transpose/2,
    % gq_replace/5: replace the color at one cell and return the new grid.
    gq_replace/5,
    % gq_fill_region/7: fill a rectangular region with a given color.
    gq_fill_region/7
]).

% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, last/2]).
% Import apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% gq_size(+Grid, -H, -W)
% H is the number of rows; W is the number of columns.
% W is derived from the first row; 0 for an empty grid.
gq_size(Grid, H, W) :-
% Measure the number of rows.
    length(Grid, H),
% Measure the number of columns from the first row; zero for empty.
    (H > 0 -> Grid = [Row|_], length(Row, W) ; W = 0).

% gq_at(+Grid, +R, +C, -Color)
% Color is the value at row R, column C (both 0-indexed).
gq_at(Grid, R, C, Color) :-
% Retrieve row R from the grid using nth0.
    nth0(R, Grid, Row),
% Retrieve column C from that row.
    nth0(C, Row, Color).

% gq_row(+Grid, +R, -Row)
% Row is the Rth row of Grid (0-indexed).
gq_row(Grid, R, Row) :-
% Use nth0 to retrieve the row.
    nth0(R, Grid, Row).

% gq_col(+Grid, +C, -Col)
% Col is the Cth column of Grid, as a list of values top-to-bottom.
gq_col(Grid, C, Col) :-
% For each row, extract the Cth element.
    maplist([Row, Cell]>>(nth0(C, Row, Cell)), Grid, Col).

% gq_colors(+Grid, -Colors)
% Colors is a sorted list of distinct color atoms in Grid.
gq_colors(Grid, Colors) :-
% Flatten all rows into a single cell list.
    findall(Cell, (member(Row, Grid), member(Cell, Row)), All),
% sort/2 removes duplicates and sorts.
    sort(All, Colors).

% gq_n_cells(+Grid, +Color, -N)
% N is the number of cells in Grid with value Color.
gq_n_cells(Grid, Color, N) :-
% Collect all cells matching Color.
    findall(_, (member(Row, Grid), member(Color, Row)), Matches),
% Length gives the count.
    length(Matches, N).

% gq_most_freq_color(+Grid, -Color)
% Color is the most frequent cell value in Grid. Ties broken by term order.
% Fails for an empty grid.
gq_most_freq_color(Grid, Color) :-
% Get all distinct colors first.
    gq_colors(Grid, Colors),
    Colors \= [],
% Count each color and key by negative count for msort descending.
    findall(NegN-C, (member(C, Colors), gq_n_cells(Grid, C, N), NegN is -N), Keyed),
    msort(Keyed, [_-Color | _]).

% gq_region(+Grid, +R0, +C0, +R1, +C1, -SubGrid)
% SubGrid is the sub-grid covering rows R0..R1 and columns C0..C1 (inclusive).
gq_region(Grid, R0, C0, R1, C1, SubGrid) :-
% Enumerate the row indices from R0 to R1.
    numlist(R0, R1, RowIdxs),
% For each row index, extract the row and slice the column range.
    maplist(gq_region_row_(Grid, C0, C1), RowIdxs, SubGrid).

% gq_region_row_(+Grid, +C0, +C1, +R, -Slice): extract row R sliced to columns C0..C1.
gq_region_row_(Grid, C0, C1, R, Slice) :-
% Retrieve row R.
    nth0(R, Grid, Row),
% Enumerate column indices.
    numlist(C0, C1, ColIdxs),
% Extract the cell at each column index.
    maplist([Ci, Cell]>>(nth0(Ci, Row, Cell)), ColIdxs, Slice).

% gq_diff(+Grid1, +Grid2, -Cells)
% Cells is a list of r(R,C) positions where Grid1 and Grid2 have different values.
% Both grids must have the same dimensions.
gq_diff(Grid1, Grid2, Cells) :-
    gq_size(Grid1, H, W),
% Enumerate all (R,C) pairs and keep those where the colors differ.
    findall(r(R,C),
        (gq_row_(Grid1, Grid2, H, W, R, C)),
        Cells).

% gq_row_(+Grid1, +Grid2, +H, +W, -R, -C): enumerate all differing positions.
gq_row_(Grid1, Grid2, H, W, R, C) :-
    H1 is H - 1, W1 is W - 1,
    between(0, H1, R), between(0, W1, C),
    nth0(R, Grid1, Row1), nth0(C, Row1, V1),
    nth0(R, Grid2, Row2), nth0(C, Row2, V2),
    V1 \== V2.

% gq_n_diff(+Grid1, +Grid2, -N)
% N is the number of cells where Grid1 and Grid2 differ.
gq_n_diff(Grid1, Grid2, N) :-
    gq_diff(Grid1, Grid2, Cells),
    length(Cells, N).

% gq_same_size(+Grid1, +Grid2)
% Succeed if Grid1 and Grid2 have the same height and width.
gq_same_size(Grid1, Grid2) :-
    gq_size(Grid1, H, W),
    gq_size(Grid2, H, W).

% gq_transpose(+Grid, -Transposed)
% Transposed has rows and columns swapped: Transposed[C][R] = Grid[R][C].
% For an empty grid or a grid with no columns, Transposed is [].
gq_transpose(Grid, Transposed) :-
    gq_size(Grid, H, W),
% For an empty grid or zero-width grid, return empty.
    (H =:= 0 -> Transposed = []
    ; W =:= 0 -> Transposed = []
    ;
% Enumerate column indices 0..W-1; for each, extract that column.
        W1 is W - 1,
        numlist(0, W1, ColIdxs),
        maplist(gq_col(Grid), ColIdxs, Transposed)
    ).

% gq_replace(+Grid, +R, +C, +Color, -NewGrid)
% NewGrid is Grid with the cell at (R,C) replaced by Color.
gq_replace(Grid, R, C, Color, NewGrid) :-
% Get the height for row index range.
    length(Grid, H), H1 is H - 1,
% Rebuild the grid: rows before R unchanged, row R replaced, rows after R unchanged.
    numlist(0, H1, RowIdxs),
    maplist(gq_replace_row_(Grid, R, C, Color), RowIdxs, NewGrid).

% gq_replace_row_(+Grid, +TargetR, +TargetC, +Color, +RowIdx, -NewRow).
gq_replace_row_(Grid, TargetR, TargetC, Color, RowIdx, NewRow) :-
    nth0(RowIdx, Grid, OldRow),
    (RowIdx =:= TargetR ->
% This is the target row: replace cell at TargetC.
        gq_replace_cell_(OldRow, TargetC, Color, NewRow)
    ;
% Other rows: unchanged.
        NewRow = OldRow
    ).

% gq_replace_cell_(+Row, +TargetC, +Color, -NewRow): replace cell at TargetC in Row.
gq_replace_cell_(Row, TargetC, Color, NewRow) :-
    length(Row, W), W1 is W - 1,
    numlist(0, W1, ColIdxs),
    maplist(gq_pick_cell_(Row, TargetC, Color), ColIdxs, NewRow).

% gq_pick_cell_(+Row, +TargetC, +Color, +ColIdx, -Cell): pick original or replaced.
gq_pick_cell_(Row, TargetC, Color, ColIdx, Cell) :-
    (ColIdx =:= TargetC ->
        Cell = Color
    ;
        nth0(ColIdx, Row, Cell)
    ).

% gq_fill_region(+Grid, +R0, +C0, +R1, +C1, +Color, -NewGrid)
% NewGrid is Grid with every cell in the rectangle (R0,C0)-(R1,C1) set to Color.
gq_fill_region(Grid, R0, C0, R1, C1, Color, NewGrid) :-
    length(Grid, H), H1 is H - 1,
    numlist(0, H1, RowIdxs),
    maplist(gq_fill_row_(Grid, R0, C0, R1, C1, Color), RowIdxs, NewGrid).

% gq_fill_row_(+Grid, +R0, +C0, +R1, +C1, +Color, +RowIdx, -NewRow).
gq_fill_row_(Grid, R0, C0, R1, C1, Color, RowIdx, NewRow) :-
    nth0(RowIdx, Grid, OldRow),
    (RowIdx >= R0, RowIdx =< R1 ->
% Row is in the target range: fill cells C0..C1.
        gq_fill_cells_(OldRow, C0, C1, Color, NewRow)
    ;
% Row is outside the target range: unchanged.
        NewRow = OldRow
    ).

% gq_fill_cells_(+Row, +C0, +C1, +Color, -NewRow): fill C0..C1 with Color.
gq_fill_cells_(Row, C0, C1, Color, NewRow) :-
    length(Row, W), W1 is W - 1,
    numlist(0, W1, ColIdxs),
    maplist(gq_fill_cell_(C0, C1, Color, Row), ColIdxs, NewRow).

% gq_fill_cell_(+C0, +C1, +Color, +Row, +ColIdx, -Cell): return Color if in range, else original.
gq_fill_cell_(C0, C1, Color, Row, ColIdx, Cell) :-
    (ColIdx >= C0, ColIdx =< C1 ->
        Cell = Color
    ;
        nth0(ColIdx, Row, Cell)
    ).
