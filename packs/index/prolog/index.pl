% index.pl - Layer 142: Coordinate-Valued Grid Generation and Index Masking (ix_* prefix).
% Provides predicates that create special 2D grids whose cell values are derived
% from the cell coordinates: row index, column index, diagonal sum, anti-diagonal
% difference, product, Manhattan distance, Chebyshev distance, modular stripe
% patterns, and linear offsets from a reference point. Also provides index-based
% row and column masking, and elementwise binary operations between an index grid
% and a value grid. All coordinate grids are row-major, 0-indexed.
:- module(index, [
    % index_row_grid/3: cell(R,C) = R for all R,C.
    index_row_grid/3,
    % index_col_grid/3: cell(R,C) = C for all R,C.
    index_col_grid/3,
    % index_sum_grid/3: cell(R,C) = R+C (diagonal band index).
    index_sum_grid/3,
    % index_diff_grid/3: cell(R,C) = R-C (anti-diagonal index, may be negative).
    index_diff_grid/3,
    % index_prod_grid/3: cell(R,C) = R*C (product index).
    index_prod_grid/3,
    % index_manhattan_grid/5: cell(R,C) = |R-R0|+|C-C0| (Manhattan distance from R0,C0).
    index_manhattan_grid/5,
    % index_chebyshev_grid/5: cell(R,C) = max(|R-R0|,|C-C0|) (ring/shell index from R0,C0).
    index_chebyshev_grid/5,
    % index_mod_grid/4: cell(R,C) = (R+C) mod N (diagonal modular stripes).
    index_mod_grid/4,
    % index_row_mod_grid/4: cell(R,C) = R mod N (horizontal stripe index).
    index_row_mod_grid/4,
    % index_col_mod_grid/4: cell(R,C) = C mod N (vertical stripe index).
    index_col_mod_grid/4,
    % index_mask_rows/4: replace rows not in the given index list with background.
    index_mask_rows/4,
    % index_mask_cols/4: replace columns not in the given index list with background.
    index_mask_cols/4,
    % index_apply/4: Out[R][C] = Grid[R][C] Op IxGrid[R][C] for Op in {add,sub,mul,max_op,min_op}.
    index_apply/4,
    % index_from/5: cell(R,C) = (R-R0)*W + (C-C0) (linear offset from reference point).
    index_from/5
]).

% Import list utilities for indexing and membership testing.
:- use_module(library(lists), [member/2, nth0/3]).

% index_row_grid(+H, +W, -Grid): Grid is H rows by W cols; every cell in row R has
% value R. Row 0 is all zeros; row 1 is all ones; row H-1 is all H-1.
% Useful as a mask to select or weight cells by their row position.
index_row_grid(H, W, Grid) :-
    % Compute the maximum row index.
    H1 is H - 1,
    % Collect one row per R; inner findall repeats R once per column.
    findall(Row, (
        between(0, H1, R),
        findall(R, between(1, W, _), Row)
    ), Grid).

% index_col_grid(+H, +W, -Grid): Grid is H rows by W cols; cell(R,C) = C.
% Every row is identical: [0, 1, 2, ..., W-1].
% Useful as a mask to select or weight cells by their column position.
index_col_grid(H, W, Grid) :-
    % Compute the maximum column index.
    W1 is W - 1,
    % Repeat the same column-index row H times.
    findall(Row, (
        between(1, H, _),
        findall(C, between(0, W1, C), Row)
    ), Grid).

% index_sum_grid(+H, +W, -Grid): Grid is H rows by W cols; cell(R,C) = R+C.
% Cells sharing the same R+C value lie on the same top-left/bottom-right diagonal.
% The minimum value 0 appears at (0,0); the maximum H+W-2 appears at (H-1,W-1).
index_sum_grid(H, W, Grid) :-
    % Compute upper bounds for both dimensions.
    H1 is H - 1,
    % Compute the max column index.
    W1 is W - 1,
    % Build each row: cell value is row index plus column index.
    findall(Row, (
        between(0, H1, R),
        findall(S, (between(0, W1, C), S is R + C), Row)
    ), Grid).

% index_diff_grid(+H, +W, -Grid): Grid is H rows by W cols; cell(R,C) = R-C.
% Cells sharing the same R-C value lie on the same bottom-left/top-right diagonal.
% Values range from -(W-1) (top-right corner) to H-1 (bottom-left corner).
index_diff_grid(H, W, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Cell value is row index minus column index; negative when C > R.
    findall(Row, (
        between(0, H1, R),
        findall(D, (between(0, W1, C), D is R - C), Row)
    ), Grid).

% index_prod_grid(+H, +W, -Grid): Grid is H rows by W cols; cell(R,C) = R*C.
% Row 0 and column 0 are all zeros. Grows quadratically toward the bottom-right.
index_prod_grid(H, W, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Cell value is the product of row and column indices.
    findall(Row, (
        between(0, H1, R),
        findall(P, (between(0, W1, C), P is R * C), Row)
    ), Grid).

% index_manhattan_grid(+H, +W, +R0, +C0, -Grid): Grid is H rows by W cols;
% cell(R,C) = |R-R0| + |C-C0| (Manhattan / taxi-cab distance from R0,C0).
% The minimum value 0 is at (R0,C0); values increase by 1 per step away.
% Useful for finding cells within a given radius of a reference point.
index_manhattan_grid(H, W, R0, C0, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Each cell holds the sum of absolute offsets from the reference point.
    findall(Row, (
        between(0, H1, R),
        findall(D, (between(0, W1, C), D is abs(R - R0) + abs(C - C0)), Row)
    ), Grid).

% index_chebyshev_grid(+H, +W, +R0, +C0, -Grid): Grid is H rows by W cols;
% cell(R,C) = max(|R-R0|, |C-C0|) (Chebyshev / king-move distance from R0,C0).
% Cells at Chebyshev distance K form a hollow square ring (shell) around (R0,C0).
% Useful for concentric ring analysis and shell-based iteration.
index_chebyshev_grid(H, W, R0, C0, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Each cell holds the maximum of its absolute row and column offsets.
    findall(Row, (
        between(0, H1, R),
        findall(D, (between(0, W1, C), D is max(abs(R - R0), abs(C - C0))), Row)
    ), Grid).

% index_mod_grid(+H, +W, +N, -Grid): Grid is H rows by W cols; cell(R,C) = (R+C) mod N.
% This creates a diagonal stripe pattern: cells on the same diagonal (R+C constant)
% share the same value. The pattern repeats with period N along diagonals.
index_mod_grid(H, W, N, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Each cell value is the diagonal index (R+C) taken modulo N.
    findall(Row, (
        between(0, H1, R),
        findall(M, (between(0, W1, C), M is (R + C) mod N), Row)
    ), Grid).

% index_row_mod_grid(+H, +W, +N, -Grid): Grid is H rows by W cols; cell(R,C) = R mod N.
% All cells in the same row share the same value. Creates horizontal stripe patterns
% that repeat every N rows. With N=2: rows alternate 0, 1, 0, 1, ...
index_row_mod_grid(H, W, N, Grid) :-
    % Compute the maximum row index.
    H1 is H - 1,
    % Build each row: compute R mod N once, then repeat it W times.
    findall(Row, (
        between(0, H1, R),
        M is R mod N,
        findall(M, between(1, W, _), Row)
    ), Grid).

% index_col_mod_grid(+H, +W, +N, -Grid): Grid is H rows by W cols; cell(R,C) = C mod N.
% All cells in the same column share the same value. Creates vertical stripe patterns
% that repeat every N columns. With N=2: columns alternate 0, 1, 0, 1, ...
index_col_mod_grid(H, W, N, Grid) :-
    % Compute the maximum column index.
    W1 is W - 1,
    % Repeat the same row pattern (C mod N for each C) H times.
    findall(Row, (
        between(1, H, _),
        findall(M, (between(0, W1, C), M is C mod N), Row)
    ), Grid).

% index_mask_rows(+Grid, +Is, +Bg, -Grid2): Grid2 is Grid with rows whose 0-based
% index is NOT in Is replaced by rows of all Bg values. Rows in Is are unchanged.
% Example: index_mask_rows([[a,b],[c,d],[e,f]], [0,2], 9, [[a,b],[9,9],[e,f]]).
index_mask_rows(Grid, Is, Bg, Grid2) :-
    % Get the total number of rows.
    length(Grid, H),
    % Compute the maximum row index.
    H1 is H - 1,
    % Build output: keep row if its index is in Is; else fill with Bg.
    findall(Row, (
        between(0, H1, R),
        nth0(R, Grid, OrigRow),
        ( member(R, Is) ->
            Row = OrigRow
        ;
            findall(Bg, member(_, OrigRow), Row)
        )
    ), Grid2).

% index_mask_cols(+Grid, +Js, +Bg, -Grid2): Grid2 is Grid with columns whose 0-based
% index is NOT in Js replaced by Bg. Columns in Js are kept unchanged.
% Example: index_mask_cols([[a,b,c],[d,e,f]], [1], 0, [[0,b,0],[0,e,0]]).
index_mask_cols(Grid, Js, Bg, Grid2) :-
    % Get grid dimensions.
    length(Grid, H),
    % Compute maximum row index.
    H1 is H - 1,
    % Get column count from the first row.
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Compute maximum column index.
    W1 is W - 1,
    % Build output: for each row, mask out columns not in Js.
    findall(MRow, (
        between(0, H1, R),
        nth0(R, Grid, GRow),
        findall(V, (
            between(0, W1, C),
            nth0(C, GRow, GV),
            ( member(C, Js) -> V = GV ; V = Bg )
        ), MRow)
    ), Grid2).

% index_apply(+IxGrid, +Op, +Grid, -Out): Out[R][C] = Grid[R][C] Op IxGrid[R][C].
% Op is one of: add (Grid+Ix), sub (Grid-Ix), mul (Grid*Ix),
%               max_op (max(Grid,Ix)), min_op (min(Grid,Ix)).
% IxGrid and Grid must have the same dimensions.
% Useful for adding a row-index offset to each row, scaling by column index, etc.
index_apply(IxGrid, Op, Grid, Out) :-
    % Get grid dimensions from IxGrid.
    length(IxGrid, H),
    % Compute maximum row index.
    H1 is H - 1,
    % Get column count from first row of IxGrid.
    ( IxGrid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Compute maximum column index.
    W1 is W - 1,
    % Build output by applying Op to each matching cell pair.
    findall(OutRow, (
        between(0, H1, R),
        nth0(R, IxGrid, IxRow),
        nth0(R, Grid, GRow),
        findall(V, (
            between(0, W1, C),
            nth0(C, IxRow, IX),
            nth0(C, GRow, GV),
            index_apply_op_(Op, IX, GV, V)
        ), OutRow)
    ), Out).

% index_apply_op_(+Op, +Ix, +GV, -V): compute V from index value Ix and grid value GV.
% add: V = GV + Ix (add the index to the grid value).
index_apply_op_(add,    IX, GV, V) :- V is GV + IX.
% sub: V = GV - Ix (subtract the index from the grid value).
index_apply_op_(sub,    IX, GV, V) :- V is GV - IX.
% mul: V = GV * Ix (multiply the grid value by the index).
index_apply_op_(mul,    IX, GV, V) :- V is GV * IX.
% max_op: V = max(GV, Ix).
index_apply_op_(max_op, IX, GV, V) :- V is max(GV, IX).
% min_op: V = min(GV, Ix).
index_apply_op_(min_op, IX, GV, V) :- V is min(GV, IX).

% index_from(+H, +W, +R0, +C0, -Grid): Grid is H rows by W cols;
% cell(R,C) = (R-R0)*W + (C-C0). This assigns each cell a unique signed
% linear offset from the reference point (R0,C0), using row-major ordering
% with stride W. index_from(H, W, 0, 0, G) produces [0,1,...,W-1] in row 0,
% [W,...,2W-1] in row 1, etc. Values are negative when R < R0 or C < C0.
index_from(H, W, R0, C0, Grid) :-
    % Compute upper bounds.
    H1 is H - 1,
    % Compute max column index.
    W1 is W - 1,
    % Each cell's offset uses W as the row stride.
    findall(Row, (
        between(0, H1, R),
        findall(Off, (
            between(0, W1, C),
            Off is (R - R0) * W + (C - C0)
        ), Row)
    ), Grid).
