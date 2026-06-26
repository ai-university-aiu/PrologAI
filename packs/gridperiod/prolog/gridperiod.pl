:- module(gridperiod, [
    gper_is_row_periodic/2,
    gper_is_col_periodic/2,
    gper_row_period/2,
    gper_col_period/2,
    gper_tile_dims/3,
    gper_extract_tile/4,
    gper_tile_grid/4,
    gper_extend_rows/3,
    gper_extend_cols/3,
    gper_extend/4,
    gper_autocorr_row/3,
    gper_autocorr_col/3,
    gper_shift_wrap_rows/3,
    gper_shift_wrap_cols/3
]).
% gridperiod.pl - Layer 201: Grid Periodic Pattern Detection and Extension (gper_* prefix).
% All predicates operate on raw grid format: list of rows, each a list of
% color atoms, 0-indexed (row 0 = top, col 0 = left).
% "Row period P" means Grid[r] == Grid[r+P] for all valid r.
% "Column period P" means Grid[r][c] == Grid[r][c+P] for all valid r,c.
% "Tile" is the smallest rectangle whose repetition (with wrap-around indexing)
% reconstructs the full grid.
:- use_module(library(lists), [
    nth0/3, append/3, member/2, sum_list/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gper_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; W=0 for empty grids.
    (H > 0 -> Grid = [FirstRow|_], length(FirstRow, W) ; W = 0).

% Read cell value at (R,C).
gper_cell_(Grid, R, C, V) :-
% Index row then column.
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% Extract a single column as a list.
gper_col_(Grid, C, Col) :-
% Collect every cell in column C from top to bottom.
    gper_dims_(Grid, H, _),
    H1 is H - 1,
    findall(V, (between(0, H1, R), gper_cell_(Grid, R, C, V)), Col).

% Shift a list left by N positions (wrapping): element at index i goes to index (i-N) mod L.
gper_shift_list_(List, N, Shifted) :-
% Each position C in output holds the element at (C - N) mod L of the input.
    length(List, L),
    L1 is L - 1,
    findall(V,
        (between(0, L1, C),
         OrigC is (C - N) mod L,
         nth0(OrigC, List, V)),
        Shifted).

% Partition a number H into segments of size P (with possible short last segment).
gper_divides_(H, P) :-
% P divides H evenly.
    H mod P =:= 0.

% --- EXPORTED PREDICATES ---

% gper_is_row_periodic(+Grid, +P)
% Succeed if Grid has row period P: Grid[r] == Grid[r+P] for every row r
% where r+P is a valid row index. Vacuously true if no such pair exists.
gper_is_row_periodic(Grid, P) :-
% Check all row pairs separated by P.
    gper_dims_(Grid, H, _),
    H1 is H - 1,
    \+ (between(0, H1, R),
        R2 is R + P,
        R2 < H,
        nth0(R, Grid, Row),
        nth0(R2, Grid, Row2),
        Row \= Row2).

% gper_is_col_periodic(+Grid, +P)
% Succeed if Grid has column period P: Grid[r][c] == Grid[r][c+P] for every
% valid (r,c) where c+P is a valid column index.
gper_is_col_periodic(Grid, P) :-
% Check all column pairs separated by P.
    gper_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    \+ (between(0, H1, R),
        between(0, W1, C),
        C2 is C + P,
        C2 < W,
        gper_cell_(Grid, R, C, V),
        gper_cell_(Grid, R, C2, V2),
        V \= V2).

% gper_row_period(+Grid, -P)
% P is the smallest positive integer for which gper_is_row_periodic holds.
% For a grid of height H, P is always found within 1..H (H itself is vacuously true).
gper_row_period(Grid, P) :-
% Try periods from 1 upward, stop at first valid one.
    gper_dims_(Grid, H, _),
    between(1, H, P),
    gper_is_row_periodic(Grid, P),
    !.

% gper_col_period(+Grid, -P)
% P is the smallest positive integer for which gper_is_col_periodic holds.
% Always found within 1..W.
gper_col_period(Grid, P) :-
    gper_dims_(Grid, _, W),
    between(1, W, P),
    gper_is_col_periodic(Grid, P),
    !.

% gper_tile_dims(+Grid, -PH, -PW)
% PH x PW is the smallest tile whose tiling (with wrap-around) reconstructs Grid.
% Equivalent to: PH = gper_row_period(Grid), PW = gper_col_period(Grid),
% but only reported when PH divides H and PW divides W (true tiling).
gper_tile_dims(Grid, PH, PW) :-
% Find the smallest periods for rows and columns.
    gper_row_period(Grid, PH),
    gper_col_period(Grid, PW).

% gper_extract_tile(+Grid, +TH, +TW, -Tile)
% Tile is the top-left TH x TW sub-grid of Grid.
% TH must not exceed the grid height; TW must not exceed the grid width.
gper_extract_tile(Grid, TH, TW, Tile) :-
    TH1 is TH - 1,
    TW1 is TW - 1,
% Collect the first TH rows, each truncated to TW columns.
    findall(Row,
        (between(0, TH1, R),
         findall(V, (between(0, TW1, C), gper_cell_(Grid, R, C, V)), Row)),
        Tile).

% gper_tile_grid(+Tile, +H, +W, -Grid)
% Grid is a H x W grid formed by tiling Tile using wrap-around indexing:
% Grid[r][c] = Tile[r mod TH][c mod TW].
gper_tile_grid(Tile, H, W, Grid) :-
    gper_dims_(Tile, TH, TW),
    H1 is H - 1,
    W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         TR is R mod TH,
         findall(V,
             (between(0, W1, C),
              TC is C mod TW,
              gper_cell_(Tile, TR, TC, V)),
             Row)),
        Grid).

% gper_extend_rows(+Grid, +TargetH, -Extended)
% Extended is Grid extended to TargetH rows by repeating existing rows from
% the top (row R of Extended = row (R mod H) of Grid).
gper_extend_rows(Grid, TargetH, Extended) :-
    gper_dims_(Grid, H, _),
    T1 is TargetH - 1,
    findall(Row,
        (between(0, T1, R),
         OrigR is R mod H,
         nth0(OrigR, Grid, Row)),
        Extended).

% gper_extend_cols(+Grid, +TargetW, -Extended)
% Extended is Grid extended to TargetW columns per row by repeating existing
% columns (column C of Extended = column (C mod W) of Grid).
gper_extend_cols(Grid, TargetW, Extended) :-
    gper_dims_(Grid, H, W),
    H1 is H - 1,
    T1 is TargetW - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, Row),
         findall(V,
             (between(0, T1, C),
              OrigC is C mod W,
              nth0(OrigC, Row, V)),
             NewRow)),
        Extended).

% gper_extend(+Grid, +TargetH, +TargetW, -Extended)
% Extended is Grid tiled to fill a TargetH x TargetW area.
% Combines gper_extend_rows and gper_extend_cols in one pass.
gper_extend(Grid, TargetH, TargetW, Extended) :-
    gper_dims_(Grid, H, W),
    T1H is TargetH - 1,
    T1W is TargetW - 1,
    findall(NewRow,
        (between(0, T1H, R),
         OrigR is R mod H,
         nth0(OrigR, Grid, Row),
         findall(V,
             (between(0, T1W, C),
              OrigC is C mod W,
              nth0(OrigC, Row, V)),
             NewRow)),
        Extended).

% gper_autocorr_row(+Grid, +P, -Score)
% Score (0.0 to 1.0) is the fraction of row pairs (r, r+P) where Grid[r] == Grid[r+P].
% Score = 1.0 if no such pairs exist (vacuously perfect) or all rows match.
gper_autocorr_row(Grid, P, Score) :-
    gper_dims_(Grid, H, _),
    H1 is H - 1,
    findall(Match,
        (between(0, H1, R),
         R2 is R + P,
         R2 < H,
         nth0(R, Grid, Row),
         nth0(R2, Grid, Row2),
         (Row = Row2 -> Match = 1 ; Match = 0)),
        Matches),
% Vacuously perfect autocorrelation when no row pairs exist.
    (Matches = [] ->
        Score = 1.0
    ;
        sum_list(Matches, Sum),
        length(Matches, N),
        Score is Sum / N).

% gper_autocorr_col(+Grid, +P, -Score)
% Score (0.0 to 1.0) is the fraction of column pairs (c, c+P) that are identical lists.
gper_autocorr_col(Grid, P, Score) :-
    gper_dims_(Grid, _, W),
    W1 is W - 1,
    findall(Match,
        (between(0, W1, C),
         C2 is C + P,
         C2 < W,
         gper_col_(Grid, C, Col),
         gper_col_(Grid, C2, Col2),
         (Col = Col2 -> Match = 1 ; Match = 0)),
        Matches),
    (Matches = [] ->
        Score = 1.0
    ;
        sum_list(Matches, Sum),
        length(Matches, N),
        Score is Sum / N).

% gper_shift_wrap_rows(+Grid, +N, -Shifted)
% Shifted is Grid with rows shifted down by N positions (wrapping).
% Row R of Shifted = row (R - N) mod H of Grid.
gper_shift_wrap_rows(Grid, N, Shifted) :-
    gper_dims_(Grid, H, _),
    H1 is H - 1,
    findall(Row,
        (between(0, H1, R),
         OrigR is (R - N) mod H,
         nth0(OrigR, Grid, Row)),
        Shifted).

% gper_shift_wrap_cols(+Grid, +N, -Shifted)
% Shifted is Grid with all columns shifted right by N positions (wrapping).
% Cell (R,C) of Shifted = cell (R, (C-N) mod W) of Grid.
gper_shift_wrap_cols(Grid, N, Shifted) :-
    gper_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(ShiftedRow,
        (between(0, H1, R),
         nth0(R, Grid, Row),
         findall(V,
             (between(0, W1, C),
              OrigC is (C - N) mod W,
              nth0(OrigC, Row, V)),
             ShiftedRow)),
        Shifted).
