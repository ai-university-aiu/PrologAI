:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(grid)).
:- use_module('../prolog/pattern').

% FIXTURES
% A 2x3 tile for tiling tests.
tile_2x3([[1,2,3],[4,5,6]]).
% A 3x3 checkerboard tile.
tile_3x3([[0,1,0],[1,0,1],[0,1,0]]).
% A 2x2 tile for simple scale tests.
tile_2x2([[1,2],[3,4]]).


:- begin_tests(pattern_period).

% Period of a constant list is 1.
test(period_constant) :-
    pt_list_period([0,0,0,0], 1).

% Period of alternating list is 2.
test(period_alternating) :-
    pt_list_period([1,2,1,2,1,2], 2).

% Period of a length-1 list is 1.
test(period_single) :-
    pt_list_period([5], 1).

% Period of ABC repeated is 3.
test(period_abc) :-
    pt_list_period([1,2,3,1,2,3], 3).

% Non-repeating list has period equal to its own length.
test(period_full_length) :-
    pt_list_period([1,2,3,4], 4).

:- end_tests(pattern_period).


:- begin_tests(pattern_row_col_period).

% Row period: row 0 of a uniform grid has period 1.
test(row_period_uniform) :-
    gd_make(3, 4, 1, Grid),
    pt_row_period(Grid, 0, 1).

% Row period: row of alternating 0/1 has period 2.
test(row_period_alt) :-
    Grid = [[0,1,0,1],[0,0,0,0]],
    pt_row_period(Grid, 0, 2).

% Col period: column of alternating 0/1 has period 2.
test(col_period_alt) :-
    Grid = [[0,0],[1,0],[0,0],[1,0]],
    pt_col_period(Grid, 0, 2).

% Col period: uniform column has period 1.
test(col_period_uniform) :-
    gd_make(4, 2, 3, Grid),
    pt_col_period(Grid, 0, 1).

:- end_tests(pattern_row_col_period).


:- begin_tests(pattern_tiling).

% Tiling a 2x3 tile into a 4x6 grid then extracting gives back the tile.
test(tile_then_extract) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 4, 6, Grid),
    pt_extract_tile(Grid, 2, 3, Extracted),
    gd_equal(Extracted, Tile).

% pt_is_tiling should succeed for a properly tiled grid.
test(is_tiling_yes) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 4, 6, Grid),
    pt_is_tiling(Grid, Tile, 2).

% pt_is_tiling should fail when comparing against wrong tile.
test(is_tiling_no) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 4, 6, Grid),
    WrongTile = [[9,9],[9,9]],
    \+ pt_is_tiling(Grid, WrongTile, 2).

% Tiled grid has correct dimensions.
test(tile_grid_size) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 6, 9, Grid),
    gd_size(Grid, 6, 9).

% Cell at (0,0) of tiled grid matches tile cell (0,0).
test(tile_grid_cell_origin) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 4, 6, Grid),
    gd_cell(Tile, 0, 0, C0),
    gd_cell(Grid, 0, 0, C0).

% Cell at (2,3) maps to tile cell (0,0) for a 2x3 tile.
test(tile_grid_cell_wrapped) :-
    tile_2x3(Tile),
    pt_tile_grid(Tile, 4, 6, Grid),
    gd_cell(Tile, 0, 0, C0),
    gd_cell(Grid, 2, 3, C0).

:- end_tests(pattern_tiling).


:- begin_tests(pattern_scaling).

% Scale up 2x2 tile by factor 2 gives 4x4 grid.
test(scale_up_size) :-
    tile_2x2(Tile),
    pt_scale_up(Tile, 2, Big),
    gd_size(Big, 4, 4).

% After scale-up, cell (0,0) matches original (0,0).
test(scale_up_cell_origin) :-
    tile_2x2(Tile),
    pt_scale_up(Tile, 2, Big),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Big, 0, 0, C).

% After scale-up, cell (1,1) maps to original (0,0) (within first block).
test(scale_up_cell_block) :-
    tile_2x2(Tile),
    pt_scale_up(Tile, 2, Big),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Big, 1, 1, C).

% Scale up then scale down recovers the original grid.
test(scale_up_down_inverse) :-
    tile_2x2(Tile),
    pt_scale_up(Tile, 3, Big),
    pt_scale_down(Big, 3, Recovered),
    gd_equal(Recovered, Tile).

% Scale down 4x4 by factor 2 gives 2x2.
test(scale_down_size) :-
    gd_make(4, 4, 7, Grid),
    pt_scale_down(Grid, 2, Small),
    gd_size(Small, 2, 2).

:- end_tests(pattern_scaling).


:- begin_tests(pattern_repetition).

% Repeating 2x2 horizontally 3 times gives 2x6.
test(repeat_h_size) :-
    tile_2x2(Tile),
    pt_repeat_h(Tile, 3, Grid2),
    gd_size(Grid2, 2, 6).

% Repeating 2x2 vertically 3 times gives 6x2.
test(repeat_v_size) :-
    tile_2x2(Tile),
    pt_repeat_v(Tile, 3, Grid2),
    gd_size(Grid2, 6, 2).

% First cell of horizontal repeat matches original first cell.
test(repeat_h_cell) :-
    tile_2x2(Tile),
    pt_repeat_h(Tile, 3, Grid2),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Grid2, 0, 0, C).

% Cell at (0,2) in horizontal repeat of a 2-wide grid = cell (0,0) of original.
test(repeat_h_wrap) :-
    tile_2x2(Tile),
    pt_repeat_h(Tile, 3, Grid2),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Grid2, 0, 2, C).

% Cell at (2,0) in vertical repeat of a 2-row grid = cell (0,0) of original.
test(repeat_v_wrap) :-
    tile_2x2(Tile),
    pt_repeat_v(Tile, 3, Grid2),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Grid2, 2, 0, C).

:- end_tests(pattern_repetition).


:- begin_tests(pattern_mirror).

% Mirror horizontally doubles the column count.
test(mirror_h_size) :-
    tile_2x2(Tile),
    pt_mirror_h(Tile, Grid2),
    gd_size(Grid2, 2, 4).

% Mirror vertically doubles the row count.
test(mirror_v_size) :-
    tile_2x2(Tile),
    pt_mirror_v(Tile, Grid2),
    gd_size(Grid2, 4, 2).

% Left half of mirror_h equals original.
test(mirror_h_left_half) :-
    tile_2x2(Tile),
    pt_mirror_h(Tile, Grid2),
    gd_cell(Tile, 0, 0, C0),
    gd_cell(Grid2, 0, 0, C0),
    gd_cell(Tile, 0, 1, C1),
    gd_cell(Grid2, 0, 1, C1).

% Right half of mirror_h is the reflected column order.
test(mirror_h_right_half) :-
    tile_2x2(Tile),
    pt_mirror_h(Tile, Grid2),
% Column 2 of Grid2 should equal column 1 of Tile (reflected).
    gd_cell(Tile, 0, 1, C1),
    gd_cell(Grid2, 0, 2, C1).

% Top half of mirror_v equals original.
test(mirror_v_top_half) :-
    tile_2x2(Tile),
    pt_mirror_v(Tile, Grid2),
    gd_cell(Tile, 0, 0, C),
    gd_cell(Grid2, 0, 0, C).

% Bottom half of mirror_v is reflected row order.
test(mirror_v_bottom_half) :-
    tile_2x2(Tile),
    pt_mirror_v(Tile, Grid2),
% Row 2 of Grid2 should equal row 1 of Tile (reflected vertically).
    gd_cell(Tile, 1, 0, C),
    gd_cell(Grid2, 2, 0, C).

:- end_tests(pattern_mirror).


:- begin_tests(pattern_checkerboard).

% Checkerboard has correct dimensions.
test(checker_size) :-
    pt_checkerboard(4, 6, 0, 1, Grid),
    gd_size(Grid, 4, 6).

% Even parity cell (0,0) gets color CA.
test(checker_even_parity) :-
    pt_checkerboard(3, 3, 7, 8, Grid),
    gd_cell(Grid, 0, 0, 7).

% Odd parity cell (0,1) gets color CB.
test(checker_odd_parity) :-
    pt_checkerboard(3, 3, 7, 8, Grid),
    gd_cell(Grid, 0, 1, 8).

% Cell (1,1) has even parity and gets CA.
test(checker_11_even) :-
    pt_checkerboard(3, 3, 7, 8, Grid),
    gd_cell(Grid, 1, 1, 7).

:- end_tests(pattern_checkerboard).


:- begin_tests(pattern_stripes).

% Horizontal stripes: row 0 gets first color.
test(stripe_h_row0) :-
    pt_stripe_h(4, 3, [1,2,3], Grid),
    gd_cell(Grid, 0, 0, 1).

% Horizontal stripes: row 1 gets second color.
test(stripe_h_row1) :-
    pt_stripe_h(4, 3, [1,2,3], Grid),
    gd_cell(Grid, 1, 0, 2).

% Horizontal stripes: row 3 wraps to first color with 3 colors.
test(stripe_h_wrap) :-
    pt_stripe_h(4, 3, [1,2,3], Grid),
    gd_cell(Grid, 3, 0, 1).

% Horizontal stripes: all cells in a row have the same color.
test(stripe_h_uniform_row) :-
    pt_stripe_h(4, 3, [1,2,3], Grid),
    gd_cell(Grid, 0, 0, C0),
    gd_cell(Grid, 0, 1, C0),
    gd_cell(Grid, 0, 2, C0).

% Vertical stripes: col 0 gets first color.
test(stripe_v_col0) :-
    pt_stripe_v(3, 4, [5,6], Grid),
    gd_cell(Grid, 0, 0, 5).

% Vertical stripes: col 1 gets second color.
test(stripe_v_col1) :-
    pt_stripe_v(3, 4, [5,6], Grid),
    gd_cell(Grid, 0, 1, 6).

% Vertical stripes: col 2 wraps to first color with 2 colors.
test(stripe_v_wrap) :-
    pt_stripe_v(3, 4, [5,6], Grid),
    gd_cell(Grid, 0, 2, 5).

% Vertical stripes: all cells in a column have the same color.
test(stripe_v_uniform_col) :-
    pt_stripe_v(3, 4, [5,6], Grid),
    gd_cell(Grid, 0, 0, C0),
    gd_cell(Grid, 1, 0, C0),
    gd_cell(Grid, 2, 0, C0).

:- end_tests(pattern_stripes).
