:- use_module('../prolog/zoom').

:- begin_tests(zoom).

% zoom_scale_up_row/3 tests

% Each element repeated twice in a 3-element row.
test(scale_up_row_f2) :-
    zoom_scale_up_row([1,2,3], 2, BigRow),
    BigRow = [1,1,2,2,3,3].

% Each element repeated once is the identity.
test(scale_up_row_f1) :-
    zoom_scale_up_row([4,5], 1, BigRow),
    BigRow = [4,5].

% Empty row scaled up is empty.
test(scale_up_row_empty) :-
    zoom_scale_up_row([], 3, BigRow),
    BigRow = [].

% zoom_scale_down_row/3 tests

% Sampling every 2nd element of a 4-element row.
test(scale_down_row_f2) :-
    zoom_scale_down_row([1,1,2,2], 2, SmallRow),
    SmallRow = [1,2].

% Sampling every element (F=1) is the identity.
test(scale_down_row_f1) :-
    zoom_scale_down_row([3,4,5], 1, SmallRow),
    SmallRow = [3,4,5].

% Sampling every 3rd element of a 6-element row.
test(scale_down_row_f3) :-
    zoom_scale_down_row([1,1,1,2,2,2], 3, SmallRow),
    SmallRow = [1,2].

% zoom_scale_up/3 tests

% 2x2 grid scaled up by 2 gives 4x4 grid with 2x2 blocks.
test(scale_up_2x2_f2) :-
    zoom_scale_up([[1,2],[3,4]], 2, Big),
    Big = [[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]].

% Scale up by 1 is the identity.
test(scale_up_f1) :-
    zoom_scale_up([[5,6],[7,8]], 1, Big),
    Big = [[5,6],[7,8]].

% 1x1 grid scaled up by 3 gives 3x3 uniform grid.
test(scale_up_1x1_f3) :-
    zoom_scale_up([[9]], 3, Big),
    Big = [[9,9,9],[9,9,9],[9,9,9]].

% zoom_scale_down/3 tests

% 4x4 grid downsampled by 2: take rows 0,2 and cols 0,2.
test(scale_down_4x4_f2) :-
    zoom_scale_down([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, Small),
    Small = [[1,2],[3,4]].

% Scale down by 1 is the identity.
test(scale_down_f1) :-
    zoom_scale_down([[5,6],[7,8]], 1, Small),
    Small = [[5,6],[7,8]].

% 3x3 grid downsampled by 3 gives a 1x1 grid.
test(scale_down_3x3_f3) :-
    zoom_scale_down([[1,1,1],[1,1,1],[1,1,1]], 3, Small),
    Small = [[1]].

% zoom_scale_factor/3 tests

% Factor inferred from a 1x1 small and 2x2 big grid.
test(scale_factor_f2) :-
    zoom_scale_factor([[1]], [[1,1],[1,1]], F),
    F = 2.

% Factor 1 when grids are the same size.
test(scale_factor_f1) :-
    zoom_scale_factor([[1,2],[3,4]], [[1,2],[3,4]], F),
    F = 1.

% Factor 3 from a 1x2 small to a 1x6 big grid.
test(scale_factor_f3) :-
    zoom_scale_factor([[1,2]], [[1,1,1,2,2,2]], F),
    F = 3.

% zoom_is_scaled_up/3 tests

% Verify that a 4x4 grid is the 2x upscaling of a 2x2.
test(is_scaled_up_yes) :-
    zoom_is_scaled_up([[1,2],[3,4]], [[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2).

% A non-upscaling fails.
test(is_scaled_up_no, [fail]) :-
    zoom_is_scaled_up([[1,2],[3,4]], [[1,2],[3,4],[5,6],[7,8]], 2).

% Verify 1-factor upscaling of itself.
test(is_scaled_up_f1) :-
    zoom_is_scaled_up([[5,6],[7,8]], [[5,6],[7,8]], 1).

% zoom_dims_up/5 tests

% 2x3 grid upscaled by 2 gives 4x6.
test(dims_up_f2) :-
    zoom_dims_up(2, 3, 2, BH, BW),
    BH = 4, BW = 6.

% Scale factor 1 preserves dimensions.
test(dims_up_f1) :-
    zoom_dims_up(5, 5, 1, BH, BW),
    BH = 5, BW = 5.

% 1x1 upscaled by 3 gives 3x3.
test(dims_up_1x1) :-
    zoom_dims_up(1, 1, 3, BH, BW),
    BH = 3, BW = 3.

% zoom_dims_down/5 tests

% 4x6 grid downsampled by 2 gives 2x3.
test(dims_down_f2) :-
    zoom_dims_down(4, 6, 2, SH, SW),
    SH = 2, SW = 3.

% Scale factor 1 preserves dimensions.
test(dims_down_f1) :-
    zoom_dims_down(5, 5, 1, SH, SW),
    SH = 5, SW = 5.

% 9x9 downsampled by 3 gives 3x3.
test(dims_down_9x9) :-
    zoom_dims_down(9, 9, 3, SH, SW),
    SH = 3, SW = 3.

% zoom_extract_block/5 tests

% Extract the top-left 2x2 block (BR=0, BC=0) from a 4x4 grid.
test(extract_block_topleft) :-
    zoom_extract_block([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, 0, 0, Block),
    Block = [[1,1],[1,1]].

% Extract the bottom-right 2x2 block (BR=1, BC=1).
test(extract_block_bottomright) :-
    zoom_extract_block([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, 1, 1, Block),
    Block = [[4,4],[4,4]].

% Extract a 3x3 block from a 3x3 grid (one block total).
test(extract_block_3x3) :-
    zoom_extract_block([[7,7,7],[7,7,7],[7,7,7]], 3, 0, 0, Block),
    Block = [[7,7,7],[7,7,7],[7,7,7]].

% zoom_blocks_dims/4 tests

% 4x4 grid with F=2 has 2x2 block layout.
test(blocks_dims_4x4_f2) :-
    zoom_blocks_dims([[1,2,3,4],[1,2,3,4],[1,2,3,4],[1,2,3,4]], 2, NR, NC),
    NR = 2, NC = 2.

% 3x6 grid with F=3 has 1x2 block layout.
test(blocks_dims_3x6_f3) :-
    zoom_blocks_dims([[1,1,1,2,2,2],[1,1,1,2,2,2],[1,1,1,2,2,2]], 3, NR, NC),
    NR = 1, NC = 2.

% 2x2 grid with F=1 has 2x2 block layout.
test(blocks_dims_f1) :-
    zoom_blocks_dims([[1,2],[3,4]], 1, NR, NC),
    NR = 2, NC = 2.

% zoom_split_blocks/3 tests

% 4x4 grid with F=2 splits into 4 blocks in row-major order.
test(split_blocks_4x4_f2) :-
    zoom_split_blocks([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, Blocks),
    length(Blocks, 4).

% Each block from a uniform 4x4 grid is all the same color.
test(split_blocks_uniform) :-
    zoom_split_blocks([[5,5,5,5],[5,5,5,5],[5,5,5,5],[5,5,5,5]], 2, Blocks),
    Blocks = [[[5,5],[5,5]],[[5,5],[5,5]],[[5,5],[5,5]],[[5,5],[5,5]]].

% A 2x2 grid with F=1 splits into 4 1x1 blocks.
test(split_blocks_f1) :-
    zoom_split_blocks([[1,2],[3,4]], 1, Blocks),
    Blocks = [[[1]],[[2]],[[3]],[[4]]].

% zoom_block_color/5 tests

% A uniform block returns its single color.
test(block_color_uniform) :-
    zoom_block_color([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, 0, 0, Color),
    Color = 1.

% The bottom-right uniform block returns its color.
test(block_color_bottomright) :-
    zoom_block_color([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, 1, 1, Color),
    Color = 4.

% A non-uniform block fails.
test(block_color_nonuniform, [fail]) :-
    zoom_block_color([[1,2],[3,4]], 2, 0, 0, _).

% zoom_scale_down_mode/3 tests

% Mode downsampling of a 4x4 grid with uniform 2x2 blocks recovers the small.
test(scale_down_mode_uniform) :-
    zoom_scale_down_mode([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, Small),
    Small = [[1,2],[3,4]].

% Mode downsampling: majority value wins within each block.
test(scale_down_mode_majority) :-
    zoom_scale_down_mode([[1,1,1,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, Small),
    Small = [[1,2],[3,4]].

% Single-cell result from a 2x2 uniform grid with F=2.
test(scale_down_mode_single) :-
    zoom_scale_down_mode([[7,7],[7,7]], 2, Small),
    Small = [[7]].

% zoom_tile_grid/4 tests

% Tiling a 1x1 grid 2x2 times gives a 2x2 grid.
test(tile_grid_1x1) :-
    zoom_tile_grid([[5]], 2, 2, Grid),
    Grid = [[5,5],[5,5]].

% Tiling a 1x2 grid 1x2 times gives a 1x4 grid.
test(tile_grid_1x2) :-
    zoom_tile_grid([[1,2]], 1, 2, Grid),
    Grid = [[1,2,1,2]].

% Tiling a 2x1 grid 2x1 times gives a 4x1 grid.
test(tile_grid_2x1) :-
    zoom_tile_grid([[1],[2]], 2, 1, Grid),
    Grid = [[1],[2],[1],[2]].

:- end_tests(zoom).
