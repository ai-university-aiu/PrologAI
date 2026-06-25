% PLUnit tests for the pattern pack (pt_* predicates).
:- use_module(library(plunit)).
:- use_module(library(pattern)).

% Helper grids.
% A 1x4 row with period 2: [0,1,0,1].
row_p2([0,1,0,1]).
% A 1x6 row with period 3: [1,2,3,1,2,3].
row_p3([1,2,3,1,2,3]).
% A 4x4 grid tiled horizontally with [0,1] period 2.
grid_h2([[0,1,0,1],[0,1,0,1],[0,1,0,1],[0,1,0,1]]).
% A 4x4 checkerboard; horizontal period 2, vertical period 2.
grid_checker([[0,1,0,1],[1,0,1,0],[0,1,0,1],[1,0,1,0]]).
% A 2x2 tile.
tile2([[0,1],[1,0]]).
% A 4x6 grid tiled from tile2 (2x2 tile repeated).
grid_tiled([[0,1,0,1,0,1],[1,0,1,0,1,0],[0,1,0,1,0,1],[1,0,1,0,1,0]]).
% A 3x3 uniform grid (all rows same).
grid_uniform([[1,2,3],[1,2,3],[1,2,3]]).
% A simple 3x3 test grid.
g3([[0,1,2],[3,0,1],[2,3,0]]).
% A 4x4 grid with a 2x2 pattern of 5s.
grid_stamp([[5,5,0,0],[5,5,0,0],[0,0,5,5],[0,0,5,5]]).

:- begin_tests(pattern_row_period).

test(period_2) :-
    row_p2(R), pt_row_period(R, P), P =:= 2.

test(period_3) :-
    row_p3(R), pt_row_period(R, P), P =:= 3.

test(period_1_uniform) :-
    pt_row_period([7,7,7,7], P), P =:= 1.

test(period_full) :-
    pt_row_period([1,2,3], P), P =:= 3.

:- end_tests(pattern_row_period).

:- begin_tests(pattern_col_period).

test(col_period_uniform) :-
    % All-zero grid: every column has period 1.
    grid_h2(G), pt_col_period(G, 0, P), P =:= 1.

test(col_period_checker) :-
    % Checker: column 0 is [0,1,0,1], period 2.
    grid_checker(G), pt_col_period(G, 0, P), P =:= 2.

test(col_period_single_distinct) :-
    % Column 0 of g3 is [0,3,2], no repeat -> period 3.
    g3(G), pt_col_period(G, 0, P), P =:= 3.

:- end_tests(pattern_col_period).

:- begin_tests(pattern_grid_period_h).

test(period_h_2) :-
    grid_h2(G), pt_grid_period_h(G, P), P =:= 2.

test(period_h_checker) :-
    grid_checker(G), pt_grid_period_h(G, P), P =:= 2.

test(period_h_full_width) :-
    % g3 rows are all distinct -> horizontal period = number of cols = 3.
    g3(G), pt_grid_period_h(G, P), P =:= 3.

:- end_tests(pattern_grid_period_h).

:- begin_tests(pattern_grid_period_v).

test(period_v_uniform_rows) :-
    grid_uniform(G), pt_grid_period_v(G, P), P =:= 1.

test(period_v_checker) :-
    grid_checker(G), pt_grid_period_v(G, P), P =:= 2.

test(period_v_tiled) :-
    grid_tiled(G), pt_grid_period_v(G, P), P =:= 2.

:- end_tests(pattern_grid_period_v).

:- begin_tests(pattern_tile_unit_h).

test(tile_h_period2) :-
    grid_h2(G), pt_tile_unit_h(G, Tile),
    % Tile should be first 2 columns of each row.
    Tile = [[0,1],[0,1],[0,1],[0,1]].

test(tile_h_uniform_row) :-
    grid_uniform(G), pt_tile_unit_h(G, Tile),
    % Period 3 (full width = 3); tile is the full grid.
    Tile = [[1,2,3],[1,2,3],[1,2,3]].

:- end_tests(pattern_tile_unit_h).

:- begin_tests(pattern_tile_unit_v).

test(tile_v_uniform) :-
    grid_uniform(G), pt_tile_unit_v(G, Tile),
    % Vertical period 1 -> first row.
    Tile = [[1,2,3]].

test(tile_v_checker) :-
    grid_checker(G), pt_tile_unit_v(G, Tile),
    % Vertical period 2 -> first 2 rows.
    Tile = [[0,1,0,1],[1,0,1,0]].

:- end_tests(pattern_tile_unit_v).

:- begin_tests(pattern_tile_unit).

test(tile_2d_checker) :-
    grid_checker(G), pt_tile_unit(G, Tile),
    % Period h=2, v=2 -> 2x2 tile.
    Tile = [[0,1],[1,0]].

test(tile_2d_tiled) :-
    grid_tiled(G), pt_tile_unit(G, Tile),
    % grid_tiled is tiled from [[0,1],[1,0]] -> same tile.
    Tile = [[0,1],[1,0]].

:- end_tests(pattern_tile_unit).

:- begin_tests(pattern_is_tiling).

test(is_tiling_checker) :-
    grid_checker(G), tile2(T), pt_is_tiling(G, T).

test(is_tiling_tiled) :-
    grid_tiled(G), tile2(T), pt_is_tiling(G, T).

test(not_tiling) :-
    g3(G), tile2(T),
    % g3 is not a tiling of tile2.
    \+ pt_is_tiling(G, T).

test(is_tiling_1x1) :-
    % Uniform grid is a tiling of its single element.
    G = [[7,7],[7,7]], pt_is_tiling(G, [[7]]).

:- end_tests(pattern_is_tiling).

:- begin_tests(pattern_find_tile).

test(find_tile_2x2_in_4x4) :-
    grid_checker(G),
    % [[0,1],[1,0]] appears at (0,0),(0,2),(1,1),(2,0),(2,2).
    pt_find_tile(G, [[0,1],[1,0]], Positions),
    msort(Positions, Sorted),
    Sorted = [r(0,0), r(0,2), r(1,1), r(2,0), r(2,2)].

test(find_tile_single_cell) :-
    g3(G),
    pt_find_tile(G, [[0]], Positions),
    % Color 0 appears at (0,0), (1,1), (2,2).
    msort(Positions, Sorted),
    Sorted = [r(0,0), r(1,1), r(2,2)].

test(find_tile_not_found) :-
    g3(G),
    pt_find_tile(G, [[9]], Positions),
    Positions = [].

:- end_tests(pattern_find_tile).

:- begin_tests(pattern_count_tile).

test(count_0_in_checker) :-
    grid_checker(G), pt_count_tile(G, [[0]], N), N =:= 8.

test(count_tile2x2) :-
    % 5 overlapping positions in 4x4 checker for the 2x2 tile.
    grid_checker(G), tile2(T), pt_count_tile(G, T, N),
    N =:= 5.

test(count_not_present) :-
    g3(G), pt_count_tile(G, [[9]], N), N =:= 0.

:- end_tests(pattern_count_tile).

:- begin_tests(pattern_extract_tile).

test(extract_top_left_2x2) :-
    g3(G), pt_extract_tile(G, r(0,0), 2, 2, Tile),
    Tile = [[0,1],[3,0]].

test(extract_bottom_right_2x2) :-
    g3(G), pt_extract_tile(G, r(1,1), 2, 2, Tile),
    Tile = [[0,1],[3,0]].

test(extract_1x1) :-
    g3(G), pt_extract_tile(G, r(1,1), 1, 1, Tile),
    Tile = [[0]].

test(extract_full_row) :-
    g3(G), pt_extract_tile(G, r(0,0), 1, 3, Tile),
    Tile = [[0,1,2]].

:- end_tests(pattern_extract_tile).

:- begin_tests(pattern_unique_rows).

test(unique_rows_g3) :-
    g3(G), pt_unique_rows(G, N), N =:= 3.

test(unique_rows_uniform) :-
    grid_uniform(G), pt_unique_rows(G, N), N =:= 1.

test(unique_rows_two) :-
    G = [[1,2],[1,2],[3,4]], pt_unique_rows(G, N), N =:= 2.

:- end_tests(pattern_unique_rows).

:- begin_tests(pattern_unique_cols).

test(unique_cols_g3) :-
    g3(G), pt_unique_cols(G, N), N =:= 3.

test(unique_cols_uniform) :-
    % grid_uniform rows all same, but columns are different.
    grid_uniform(G), pt_unique_cols(G, N), N =:= 3.

test(unique_cols_one) :-
    % All columns identical.
    G = [[5,5,5],[5,5,5]], pt_unique_cols(G, N), N =:= 1.

:- end_tests(pattern_unique_cols).

:- begin_tests(pattern_has_uniform_rows).

test(uniform_true) :-
    grid_uniform(G), pt_has_uniform_rows(G).

test(uniform_h2_true) :-
    grid_h2(G), pt_has_uniform_rows(G).

test(uniform_checker_false) :-
    grid_checker(G), \+ pt_has_uniform_rows(G).

test(uniform_g3_false) :-
    g3(G), \+ pt_has_uniform_rows(G).

:- end_tests(pattern_has_uniform_rows).
