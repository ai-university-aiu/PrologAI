% PLUnit tests for the tile pack (ti_* predicates, Layer 81).
:- use_module(library(plunit)).
:- use_module('../prolog/tile.pl').

:- begin_tests(tile_tile_h).

% Repeat a 2x2 tile twice horizontally.
test(tile_h_basic) :-
    tile_tile_h([[1,2],[3,4]], 2, G),
    G = [[1,2,1,2],[3,4,3,4]].

% Tiling once returns the original tile.
test(tile_h_once) :-
    tile_tile_h([[1,0]], 1, G),
    G = [[1,0]].

% Repeat a single-cell tile three times.
test(tile_h_three) :-
    tile_tile_h([[1]], 3, G),
    G = [[1,1,1]].

:- end_tests(tile_tile_h).

:- begin_tests(tile_tile_v).

% Repeat a 2x2 tile twice vertically.
test(tile_v_basic) :-
    tile_tile_v([[1,2],[3,4]], 2, G),
    G = [[1,2],[3,4],[1,2],[3,4]].

% Tiling once returns the original tile.
test(tile_v_once) :-
    tile_tile_v([[1,0]], 1, G),
    G = [[1,0]].

% Repeat a single-row tile three times.
test(tile_v_single_row) :-
    tile_tile_v([[1,2]], 3, G),
    G = [[1,2],[1,2],[1,2]].

:- end_tests(tile_tile_v).

:- begin_tests(tile_tile).

% Tile a 2x2 block into a 4x4 grid (2 rows, 2 cols of copies).
test(tile_basic) :-
    tile_tile([[1,0],[0,1]], 2, 2, G),
    G = [[1,0,1,0],[0,1,0,1],[1,0,1,0],[0,1,0,1]].

% Tile a 1x2 block into a 1x6 grid (1 row, 3 cols of copies).
test(tile_1x3) :-
    tile_tile([[1,2]], 1, 3, G),
    G = [[1,2,1,2,1,2]].

% Tile a 2x1 block into a 6x1 grid (3 rows, 1 col of copies).
test(tile_3x1) :-
    tile_tile([[1],[2]], 3, 1, G),
    G = [[1],[2],[1],[2],[1],[2]].

:- end_tests(tile_tile).

:- begin_tests(tile_split_rows).

% Split a 4-row grid into two 2-row bands.
test(split_rows_basic) :-
    tile_split_rows([[1,2],[3,4],[5,6],[7,8]], 2, B),
    B = [[[1,2],[3,4]],[[5,6],[7,8]]].

% When TH equals total rows, one band is returned.
test(split_rows_single_band) :-
    tile_split_rows([[1,2],[3,4]], 2, B),
    B = [[[1,2],[3,4]]].

% When TH = 1, each row is its own band.
test(split_rows_one_each) :-
    tile_split_rows([[1,2],[3,4]], 1, B),
    B = [[[1,2]],[[3,4]]].

:- end_tests(tile_split_rows).

:- begin_tests(tile_split_cols).

% Split a 2x4 grid into two 2x2 stripes.
test(split_cols_basic) :-
    tile_split_cols([[1,2,3,4],[5,6,7,8]], 2, S),
    S = [[[1,2],[5,6]],[[3,4],[7,8]]].

% When TW equals total cols, one stripe is returned.
test(split_cols_single) :-
    tile_split_cols([[1,2],[3,4]], 2, S),
    S = [[[1,2],[3,4]]].

% When TW = 1, each column is its own stripe.
test(split_cols_one_each) :-
    tile_split_cols([[1,2],[3,4]], 1, S),
    S = [[[1],[3]],[[2],[4]]].

:- end_tests(tile_split_cols).

:- begin_tests(tile_split).

% Split a 2x4 grid into one row of two 2x2 tiles.
test(split_basic) :-
    tile_split([[1,2,3,4],[5,6,7,8]], 2, 2, TG),
    TG = [[[[1,2],[5,6]],[[3,4],[7,8]]]].

% When TH and TW equal grid dimensions, one tile is returned.
test(split_whole) :-
    tile_split([[1,2],[3,4]], 2, 2, TG),
    TG = [[[[1,2],[3,4]]]].

% When TH = TW = 1, each cell becomes its own 1x1 tile.
test(split_unit) :-
    tile_split([[1,2],[3,4]], 1, 1, TG),
    TG = [[[[1]],[[2]]],[[[3]],[[4]]]].

:- end_tests(tile_split).

:- begin_tests(tile_flatten_tiles).

% Flatten a single tile-row of two 2x2 tiles back to a 2x4 grid.
test(flatten_basic) :-
    tile_flatten_tiles([[[[1,2],[5,6]],[[3,4],[7,8]]]], G),
    G = [[1,2,3,4],[5,6,7,8]].

% Flatten a single-tile tile-grid.
test(flatten_whole) :-
    tile_flatten_tiles([[[[1,2],[3,4]]]], G),
    G = [[1,2],[3,4]].

% Flatten two tile-rows of one 1x2 tile each.
test(flatten_stacked) :-
    tile_flatten_tiles([[[[1,2]]],[[[3,4]]]], G),
    G = [[1,2],[3,4]].

:- end_tests(tile_flatten_tiles).

:- begin_tests(tile_stamp).

% Stamp a 2x2 motif at the top-left of a 3x3 zero grid.
test(stamp_basic) :-
    tile_stamp([[0,0,0],[0,0,0],[0,0,0]], [[1,1],[1,1]], 0, 0, R),
    R = [[1,1,0],[1,1,0],[0,0,0]].

% Stamp a single cell at an interior position.
test(stamp_offset) :-
    tile_stamp([[0,0,0],[0,0,0],[0,0,0]], [[5]], 1, 1, R),
    R = [[0,0,0],[0,5,0],[0,0,0]].

% Stamp a motif that partially extends beyond the grid boundary.
test(stamp_partial) :-
    tile_stamp([[0,0,0],[0,0,0]], [[1,1,1]], 0, 1, R),
    R = [[0,1,1],[0,0,0]].

:- end_tests(tile_stamp).

:- begin_tests(tile_stamp_all).

% Stamp a 1x1 motif at three positions.
test(stamp_all_basic) :-
    tile_stamp_all([[0,0,0],[0,0,0]], [[1]], [0-0, 0-2, 1-1], R),
    R = [[1,0,1],[0,1,0]].

% Stamping at an empty position list returns the base unchanged.
test(stamp_all_empty) :-
    tile_stamp_all([[0,0],[0,0]], [[1,1]], [], R),
    R = [[0,0],[0,0]].

% Overlapping stamps: later stamp overwrites earlier in the overlap zone.
test(stamp_all_overlap) :-
    tile_stamp_all([[0,0,0]], [[1,1]], [0-0, 0-1], R),
    R = [[1,1,1]].

:- end_tests(tile_stamp_all).

:- begin_tests(tile_extract_tile).

% Extract the first 2x2 tile from a 2x4 grid.
test(extract_basic) :-
    tile_extract_tile([[1,2,3,4],[5,6,7,8]], 2, 2, 0, 0, T),
    T = [[1,2],[5,6]].

% Extract the second 2x2 tile (tile column 1).
test(extract_second) :-
    tile_extract_tile([[1,2,3,4],[5,6,7,8]], 2, 2, 0, 1, T),
    T = [[3,4],[7,8]].

% Extract a tile from a 4x4 grid at tile position (1,1).
test(extract_interior) :-
    tile_extract_tile([[1,0,1,0],[0,1,0,1],[1,0,1,0],[0,1,0,1]], 2, 2, 1, 1, T),
    T = [[1,0],[0,1]].

:- end_tests(tile_extract_tile).

:- begin_tests(tile_is_tiling).

% A 4x4 grid that is a 2x2-tiled copy of [[1,0],[0,1]] succeeds.
test(is_tiling_yes) :-
    tile_is_tiling([[1,0,1,0],[0,1,0,1],[1,0,1,0],[0,1,0,1]], 2, 2).

% Fails when grid dimensions are not exact multiples of tile size.
test(is_tiling_no_dims, [fail]) :-
    tile_is_tiling([[1,0,0],[0,1,0]], 1, 2).

% Fails when tile content does not match the reference tile.
test(is_tiling_content_mismatch, [fail]) :-
    tile_is_tiling([[1,0,1,1],[0,1,0,1]], 2, 2).

:- end_tests(tile_is_tiling).

:- begin_tests(tile_find_period_h).

% Find horizontal period 2 in an alternating grid.
test(period_h_basic) :-
    tile_find_period_h([[1,0,1,0],[0,1,0,1]], P),
    P = 2.

% All-same rows have period 1.
test(period_h_all_same) :-
    tile_find_period_h([[1,1,1],[1,1,1]], P),
    P = 1.

% When no shorter period exists, the period equals the width.
test(period_h_full) :-
    tile_find_period_h([[1,0,0],[1,0,0]], P),
    P = 3.

:- end_tests(tile_find_period_h).

:- begin_tests(tile_find_period_v).

% Find vertical period 2 in a 4-row alternating grid.
test(period_v_basic) :-
    tile_find_period_v([[1,0],[0,1],[1,0],[0,1]], P),
    P = 2.

% All-same rows have vertical period 1.
test(period_v_all_same) :-
    tile_find_period_v([[1,0],[1,0],[1,0]], P),
    P = 1.

% When no shorter period exists, the period equals the height.
test(period_v_full) :-
    tile_find_period_v([[1,0],[0,1],[0,0]], P),
    P = 3.

:- end_tests(tile_find_period_v).

:- begin_tests(tile_checkerboard).

% 2x2 checkerboard with values 1 and 0.
test(checkerboard_basic) :-
    tile_checkerboard(2, 2, 1, 0, G),
    G = [[1,0],[0,1]].

% 2x3 checkerboard with values 5 and 9.
test(checkerboard_large) :-
    tile_checkerboard(2, 3, 5, 9, G),
    G = [[5,9,5],[9,5,9]].

% 1x1 checkerboard returns a single V1 cell.
test(checkerboard_1x1) :-
    tile_checkerboard(1, 1, 3, 7, G),
    G = [[3]].

:- end_tests(tile_checkerboard).
