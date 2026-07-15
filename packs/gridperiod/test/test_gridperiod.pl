:- use_module('../prolog/gridperiod').
:- use_module(library(plunit)).

% Grid fixtures

% 2x2: all same color (period 1 in both dimensions)
g2x2_uniform([[r,r],[r,r]]).

% 4x2: two distinct rows alternating (row period 2, col period 2 since cols differ)
g4x2_alt([[r,b],[b,r],[r,b],[b,r]]).

% 2x4: rows identical, col period 2
g2x4_alt([[r,b,r,b],[r,b,r,b]]).

% 4x4: 2x2 tile [r,b;b,r] repeated (row period 2, col period 2)
g4x4_tile([[r,b,r,b],[b,r,b,r],[r,b,r,b],[b,r,b,r]]).

% 3x3: single r (uniform, period 1 both dimensions)
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).

% 3x3: distinct rows (all cols same within each row)
g3x3_rows([[r,r,r],[b,b,b],[g,g,g]]).

% 3x3: distinct columns (all rows same within each column)
g3x3_cols([[r,b,g],[r,b,g],[r,b,g]]).

% 2x3 tile for tiling tests
tile2x3([[r,b,g],[g,r,b]]).

% 3x3 with unique rows and cols
g3x3_unique([[r,b,g],[b,g,r],[g,r,b]]).

:- begin_tests(gridperiod).

% --- gridperiod_is_row_periodic/2 ---

test(row_periodic_uniform_p1) :-
% Uniform grid: all rows identical -> row period 1.
    g2x2_uniform(G),
    gridperiod_is_row_periodic(G, 1).

test(row_periodic_alt_p2) :-
% g4x2_alt rows: [r,b],[b,r],[r,b],[b,r] -> period 2.
    g4x2_alt(G),
    gridperiod_is_row_periodic(G, 2).

test(row_periodic_alt_not_p1, [fail]) :-
% Alternating rows are NOT period 1.
    g4x2_alt(G),
    gridperiod_is_row_periodic(G, 1).

test(row_periodic_tile_p2) :-
% g4x4_tile has row period 2.
    g4x4_tile(G),
    gridperiod_is_row_periodic(G, 2).

% --- gridperiod_is_col_periodic/2 ---

test(col_periodic_uniform_p1) :-
% Uniform grid: all columns identical -> col period 1.
    g2x2_uniform(G),
    gridperiod_is_col_periodic(G, 1).

test(col_periodic_alt_p2) :-
% g2x4_alt: columns alternate r,b -> col period 2.
    g2x4_alt(G),
    gridperiod_is_col_periodic(G, 2).

test(col_periodic_rows_p1) :-
% g3x3_rows: each row is uniform color -> all columns are identical -> col period 1.
    g3x3_rows(G),
    gridperiod_is_col_periodic(G, 1).

test(col_periodic_tile_p2) :-
% g4x4_tile has col period 2.
    g4x4_tile(G),
    gridperiod_is_col_periodic(G, 2).

% --- gridperiod_row_period/2 ---

test(row_period_uniform) :-
% Uniform grid: row period = 1.
    g3x3_r(G),
    gridperiod_row_period(G, P),
    P =:= 1.

test(row_period_alt) :-
% g4x2_alt: row period = 2.
    g4x2_alt(G),
    gridperiod_row_period(G, P),
    P =:= 2.

test(row_period_unique) :-
% g3x3_unique has no smaller period than 3 (H=3, so period = 3).
    g3x3_unique(G),
    gridperiod_row_period(G, P),
    P =:= 3.

test(row_period_single_row) :-
% Single row grid: H=1, row period = 1 (vacuously).
    gridperiod_row_period([[r,b,g]], P),
    P =:= 1.

% --- gridperiod_col_period/2 ---

test(col_period_uniform) :-
% Uniform grid: col period = 1.
    g3x3_r(G),
    gridperiod_col_period(G, P),
    P =:= 1.

test(col_period_alt) :-
% g2x4_alt: col period = 2.
    g2x4_alt(G),
    gridperiod_col_period(G, P),
    P =:= 2.

test(col_period_unique) :-
% g3x3_unique: col period = 3 (W=3, no smaller period works).
    g3x3_unique(G),
    gridperiod_col_period(G, P),
    P =:= 3.

% --- gridperiod_tile_dims/3 ---

test(tile_dims_uniform) :-
% Uniform grid: tile is 1x1.
    g3x3_r(G),
    gridperiod_tile_dims(G, PH, PW),
    PH =:= 1, PW =:= 1.

test(tile_dims_4x4_tile) :-
% g4x4_tile: tile is 2x2.
    g4x4_tile(G),
    gridperiod_tile_dims(G, PH, PW),
    PH =:= 2, PW =:= 2.

test(tile_dims_rows) :-
% g3x3_rows: each row unique but cols repeat -> PH=3, PW=1.
    g3x3_rows(G),
    gridperiod_tile_dims(G, PH, PW),
    PH =:= 3, PW =:= 1.

% --- gridperiod_extract_tile/4 ---

test(extract_tile_1x1) :-
% Extract 1x1 tile from uniform grid.
    g3x3_r(G),
    gridperiod_extract_tile(G, 1, 1, Tile),
    Tile = [[r]].

test(extract_tile_2x2) :-
% Extract 2x2 from g4x4_tile.
    g4x4_tile(G),
    gridperiod_extract_tile(G, 2, 2, Tile),
    Tile = [[r,b],[b,r]].

test(extract_tile_2x3) :-
% Extract 2x3 tile from tile2x3 (trivial: returns itself).
    tile2x3(T),
    gridperiod_extract_tile(T, 2, 3, Tile),
    Tile = [[r,b,g],[g,r,b]].

% --- gridperiod_tile_grid/4 ---

test(tile_grid_uniform) :-
% Tile [[r]] to 3x3 gives all r.
    gridperiod_tile_grid([[r]], 3, 3, G),
    G = [[r,r,r],[r,r,r],[r,r,r]].

test(tile_grid_2x2_to_4x4) :-
% Tile [[r,b],[b,r]] to 4x4 gives g4x4_tile.
    gridperiod_tile_grid([[r,b],[b,r]], 4, 4, G),
    g4x4_tile(Expected),
    G = Expected.

test(tile_grid_2x3_to_4x6) :-
% Tile 2x3 to 4x6 by repeating twice in each dimension.
    tile2x3(T),
    gridperiod_tile_grid(T, 4, 6, G),
    length(G, 4),
    G = [R0, R1, R2, R3],
    R0 = [r,b,g,r,b,g],
    R1 = [g,r,b,g,r,b],
    R2 = [r,b,g,r,b,g],
    R3 = [g,r,b,g,r,b].

% --- gridperiod_extend_rows/3 ---

test(extend_rows_no_change) :-
% Extend g3x3_r to 3 rows = no change.
    g3x3_r(G),
    gridperiod_extend_rows(G, 3, E),
    E = G.

test(extend_rows_double) :-
% Extend 2-row grid to 4 rows by wrapping.
    gridperiod_extend_rows([[r,b],[g,r]], 4, E),
    E = [[r,b],[g,r],[r,b],[g,r]].

% --- gridperiod_extend_cols/3 ---

test(extend_cols_no_change) :-
% Extend g3x3_r to 3 cols = no change.
    g3x3_r(G),
    gridperiod_extend_cols(G, 3, E),
    E = G.

test(extend_cols_double) :-
% Extend 2-col grid to 4 cols by wrapping.
    gridperiod_extend_cols([[r,b],[g,r]], 4, E),
    E = [[r,b,r,b],[g,r,g,r]].

% --- gridperiod_extend/4 ---

test(extend_1x1_to_3x3) :-
% Tile a 1x1 grid to 3x3.
    gridperiod_extend([[b]], 3, 3, E),
    E = [[b,b,b],[b,b,b],[b,b,b]].

test(extend_2x2_to_4x4) :-
% Tile [[r,b],[b,r]] to 4x4.
    gridperiod_extend([[r,b],[b,r]], 4, 4, E),
    g4x4_tile(Expected),
    E = Expected.

test(extend_2x3_to_4x6) :-
% Tile tile2x3 to 4x6.
    tile2x3(T),
    gridperiod_extend(T, 4, 6, E),
    length(E, 4),
    nth0(0, E, R0),
    R0 = [r,b,g,r,b,g].

% --- gridperiod_autocorr_row/3 ---

test(autocorr_row_perfect) :-
% Uniform grid: row autocorrelation at any lag = 1.0.
    g3x3_r(G),
    gridperiod_autocorr_row(G, 1, Score),
    Score =:= 1.0.

test(autocorr_row_alt_p2) :-
% g4x2_alt: autocorrelation at lag 2 is 1.0 (all pairs match).
    g4x2_alt(G),
    gridperiod_autocorr_row(G, 2, Score),
    Score =:= 1.0.

test(autocorr_row_alt_p1) :-
% g4x2_alt: autocorrelation at lag 1 is 0.0 (no adjacent rows match).
    g4x2_alt(G),
    gridperiod_autocorr_row(G, 1, Score),
    Score =:= 0.0.

% --- gridperiod_autocorr_col/3 ---

test(autocorr_col_perfect) :-
% Uniform grid: col autocorrelation at any lag = 1.0.
    g3x3_r(G),
    gridperiod_autocorr_col(G, 1, Score),
    Score =:= 1.0.

test(autocorr_col_alt_p2) :-
% g2x4_alt: autocorrelation at lag 2 = 1.0.
    g2x4_alt(G),
    gridperiod_autocorr_col(G, 2, Score),
    Score =:= 1.0.

test(autocorr_col_alt_p1) :-
% g2x4_alt: autocorrelation at lag 1 = 0.0 (r vs b never match).
    g2x4_alt(G),
    gridperiod_autocorr_col(G, 1, Score),
    Score =:= 0.0.

% --- gridperiod_shift_wrap_rows/3 ---

test(shift_rows_zero) :-
% Shifting by 0 returns the same grid.
    g3x3_rows(G),
    gridperiod_shift_wrap_rows(G, 0, S),
    S = G.

test(shift_rows_by_1) :-
% g3x3_rows = [[r,r,r],[b,b,b],[g,g,g]]; shift down 1:
% Row 0 of shifted = row (0-1) mod 3 = row 2 = [g,g,g]
% Row 1 of shifted = row 0 = [r,r,r]
% Row 2 of shifted = row 1 = [b,b,b]
    g3x3_rows(G),
    gridperiod_shift_wrap_rows(G, 1, S),
    S = [[g,g,g],[r,r,r],[b,b,b]].

test(shift_rows_by_h_identity) :-
% Shifting by H (height) returns the same grid.
    g3x3_rows(G),
    gridperiod_shift_wrap_rows(G, 3, S),
    S = G.

% --- gridperiod_shift_wrap_cols/3 ---

test(shift_cols_zero) :-
% Shifting cols by 0 returns same grid.
    g3x3_cols(G),
    gridperiod_shift_wrap_cols(G, 0, S),
    S = G.

test(shift_cols_by_1) :-
% g3x3_cols = [[r,b,g],[r,b,g],[r,b,g]]; shift right 1:
% Col 0 of shifted = col (0-1) mod 3 = col 2 = g
% Col 1 of shifted = col 0 = r
% Col 2 of shifted = col 1 = b
% Each row: [g,r,b]
    g3x3_cols(G),
    gridperiod_shift_wrap_cols(G, 1, S),
    S = [[g,r,b],[g,r,b],[g,r,b]].

test(shift_cols_by_w_identity) :-
% Shifting cols by W returns same grid.
    g3x3_cols(G),
    gridperiod_shift_wrap_cols(G, 3, S),
    S = G.

% Extra: combined round-trip tests

test(extract_then_tile) :-
% Extracting 2x2 tile from g4x4_tile and tiling back gives the original.
    g4x4_tile(G),
    gridperiod_extract_tile(G, 2, 2, Tile),
    gridperiod_tile_grid(Tile, 4, 4, G2),
    G = G2.

test(extend_then_period) :-
% Extending a 1x2 grid [r,b] to 1x6 gives row period 1 and col period 2.
    gridperiod_extend([[r,b]], 1, 6, E),
    gridperiod_col_period(E, P),
    P =:= 2.

test(shift_cols_twice) :-
% Shifting cols by 1 twice = shifting by 2.
    g3x3_cols(G),
    gridperiod_shift_wrap_cols(G, 1, S1),
    gridperiod_shift_wrap_cols(S1, 1, S2),
    gridperiod_shift_wrap_cols(G, 2, S3),
    S2 = S3.

test(tile_grid_1x1_to_2x2) :-
% Tile [[b]] to 2x2 gives [[b,b],[b,b]].
    gridperiod_tile_grid([[b]], 2, 2, G),
    G = [[b,b],[b,b]].

test(row_period_two_identical_rows) :-
% Two identical rows: row period 1.
    gridperiod_row_period([[r,b],[r,b]], P),
    P =:= 1.

test(autocorr_row_partial) :-
% g3x3_rows = [[r,r,r],[b,b,b],[g,g,g]]: row autocorr at lag 1.
% Pairs: (row0,row1) r!=b -> 0; (row1,row2) b!=g -> 0. Score = 0.0.
    g3x3_rows(G),
    gridperiod_autocorr_row(G, 1, Score),
    Score =:= 0.0.

test(autocorr_col_partial) :-
% g3x3_cols = [[r,b,g],[r,b,g],[r,b,g]]: col autocorr at lag 1.
% Pairs: (col0,col1) r!=b -> 0; (col1,col2) b!=g -> 0. Score = 0.0.
    g3x3_cols(G),
    gridperiod_autocorr_col(G, 1, Score),
    Score =:= 0.0.

test(extend_rows_single_to_4) :-
% Extend single-row [[r,b,g]] to 4 rows by row tiling.
    gridperiod_extend_rows([[r,b,g]], 4, E),
    length(E, 4),
    E = [[r,b,g],[r,b,g],[r,b,g],[r,b,g]].

:- end_tests(gridperiod).
