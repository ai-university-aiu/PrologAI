:- use_module('../prolog/patch').

:- begin_tests(patch).

% patch_extract/6 tests

% Extract a 2x2 patch from the top-left corner of a 3x3 grid.
test(extract_top_left) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_extract(Grid, 0, 0, 2, 2, Patch),
    Patch = [[1,2],[4,5]].

% Extract a 2x2 patch from the bottom-right corner of a 3x3 grid.
test(extract_bottom_right) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_extract(Grid, 1, 1, 2, 2, Patch),
    Patch = [[5,6],[8,9]].

% Extract a single-cell patch (1x1).
test(extract_single_cell) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_extract(Grid, 1, 1, 1, 1, Patch),
    Patch = [[5]].

% patch_dims/3 tests

% A 2x3 patch has height 2 and width 3.
test(dims_2x3) :-
    Patch = [[1,2,3],[4,5,6]],
    patch_dims(Patch, H, W),
    H = 2, W = 3.

% A single-row patch has height 1.
test(dims_single_row) :-
    Patch = [[1,2,3,4]],
    patch_dims(Patch, H, W),
    H = 1, W = 4.

% An empty patch has height 0 and width 0.
test(dims_empty) :-
    patch_dims([], H, W),
    H = 0, W = 0.

% patch_match/4 tests

% A 2x2 patch matches at position (0,0) in a 3x3 grid.
test(match_top_left) :-
    Grid = [[1,2,3],[1,2,3],[4,5,6]],
    once(patch_match(Grid, [[1,2],[1,2]], 0, 0)).

% A 2x2 patch with all-9 values fails to match in a grid without them.
test(match_fail, [fail]) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_match(Grid, [[9,9],[9,9]], _, _).

% A 1x1 patch matches at its exact position.
test(match_single_cell) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    once(patch_match(Grid, [[5]], 1, 1)).

% patch_match_all/3 tests

% A 1x1 patch matching value 1 appears at three positions.
test(match_all_three) :-
    Grid = [[1,0,1],[0,0,0],[1,0,0]],
    patch_match_all(Grid, [[1]], Positions),
    sort(Positions, S),
    S = [0-0, 0-2, 2-0].

% A 2x2 all-zero patch finds matches in an all-zero grid.
test(match_all_zeros) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    patch_match_all(Grid, [[0,0],[0,0]], Positions),
    length(Positions, 4).

% A patch not present gives an empty list.
test(match_all_none) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_match_all(Grid, [[0,0],[0,0]], Positions),
    Positions = [].

% patch_match_count/3 tests

% Counting matches of [[1,1]] in a row of three 1s gives two matches.
test(match_count_two) :-
    Grid = [[1,1,1]],
    patch_match_count(Grid, [[1,1]], N),
    N = 2.

% Counting matches of a non-existent patch gives 0.
test(match_count_zero) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_match_count(Grid, [[0,0],[0,0]], N),
    N = 0.

% Counting matches of the grid itself against itself gives 1.
test(match_count_self) :-
    Grid = [[1,2],[3,4]],
    patch_match_count(Grid, Grid, N),
    N = 1.

% patch_match_bg/4 tests

% A patch with all-background wildcards matches every position in the grid.
test(match_bg_all_positions) :-
    Grid = [[1,2],[3,4]],
    patch_match_bg(Grid, [[0,0],[0,0]], 0, Positions),
    length(Positions, 1).

% A patch with mixed bg and exact values matches only correct positions.
test(match_bg_mixed) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_match_bg(Grid, [[0,2],[0,5]], 0, Positions),
    Positions = [0-0].

% A patch with no background wildcards behaves like patch_match_all.
test(match_bg_no_wildcard) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_match_bg(Grid, [[1,2],[4,5]], 0, Positions),
    Positions = [0-0].

% patch_slides/4 tests

% A 2x2 sliding window on a 3x3 grid produces exactly 4 patches.
test(slides_count_four) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_slides(Grid, 2, 2, Patches),
    length(Patches, 4).

% The first slide in a 3x3 grid with H=2 W=2 is at position 0-0.
test(slides_first_position) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    patch_slides(Grid, 2, 2, [0-0-Patch | _]),
    Patch = [[1,2],[4,5]].

% A 1x1 sliding window on a 2x3 grid produces 6 patches.
test(slides_1x1) :-
    Grid = [[1,2,3],[4,5,6]],
    patch_slides(Grid, 1, 1, Patches),
    length(Patches, 6).

% patch_unique_patches/4 tests

% A uniform grid has only one distinct 2x2 patch.
test(unique_one_patch) :-
    Grid = [[1,1,1],[1,1,1],[1,1,1]],
    patch_unique_patches(Grid, 2, 2, Unique),
    length(Unique, 1),
    Unique = [[[1,1],[1,1]]].

% A grid where each 1x1 patch is different has 4 unique patches.
test(unique_four_patches) :-
    Grid = [[1,2],[3,4]],
    patch_unique_patches(Grid, 1, 1, Unique),
    length(Unique, 4).

% A 3x3 grid of alternating 0 and 1 has two distinct 1x1 patches.
test(unique_two_patches) :-
    Grid = [[0,1,0],[1,0,1],[0,1,0]],
    patch_unique_patches(Grid, 1, 1, Unique),
    length(Unique, 2).

% patch_most_common_patch/5 tests

% In a uniform grid the only patch is most common.
test(most_common_uniform) :-
    Grid = [[1,1,1],[1,1,1],[1,1,1]],
    patch_most_common_patch(Grid, 2, 2, Patch, Count),
    Patch = [[1,1],[1,1]],
    Count = 4.

% In a 3x1 grid, [[1]] appears twice and [[2]] once.
test(most_common_two_one) :-
    Grid = [[1],[1],[2]],
    patch_most_common_patch(Grid, 1, 1, Patch, Count),
    Patch = [[1]],
    Count = 2.

% A 2x2 grid has exactly one patch equal to itself; count is 1.
test(most_common_single) :-
    Grid = [[1,2],[3,4]],
    patch_most_common_patch(Grid, 2, 2, Patch, Count),
    Patch = [[1,2],[3,4]],
    Count = 1.

% patch_diff/3 tests

% Two identical patches give an empty diff list.
test(difference_identical) :-
    patch_diff([[1,2],[3,4]], [[1,2],[3,4]], Cells),
    Cells = [].

% Patches differing in one cell give a one-element diff list.
test(difference_one_cell) :-
    patch_diff([[1,2],[3,4]], [[1,2],[3,9]], Cells),
    Cells = [1-1].

% Patches differing in all cells give a full diff list.
test(difference_all_cells) :-
    patch_diff([[1,1],[1,1]], [[2,2],[2,2]], Cells),
    sort(Cells, S),
    S = [0-0, 0-1, 1-0, 1-1].

% patch_is_uniform/2 tests

% A 2x2 patch of all-1 cells is uniform with color 1.
test(is_uniform_all_same) :-
    patch_is_uniform([[1,1],[1,1]], Color),
    Color = 1.

% A 2x2 patch with mixed values is not uniform.
test(is_uniform_mixed, [fail]) :-
    patch_is_uniform([[1,2],[3,4]], _).

% A 1x1 patch is trivially uniform.
test(is_uniform_single) :-
    patch_is_uniform([[7]], Color),
    Color = 7.

% patch_flip_h/2 tests

% Flipping [[1,2,3]] horizontally gives [[3,2,1]].
test(flip_h_single_row) :-
    patch_flip_h([[1,2,3]], F),
    F = [[3,2,1]].

% Flipping a 2x2 patch horizontally reverses each row.
test(flip_h_2x2) :-
    patch_flip_h([[1,2],[3,4]], F),
    F = [[2,1],[4,3]].

% Flipping a symmetric row leaves it unchanged.
test(flip_h_symmetric) :-
    patch_flip_h([[1,2,1]], F),
    F = [[1,2,1]].

% patch_flip_v/2 tests

% Flipping a two-row patch vertically reverses the row order.
test(flip_v_two_rows) :-
    patch_flip_v([[1,2],[3,4]], F),
    F = [[3,4],[1,2]].

% Flipping a three-row patch vertically reverses the rows.
test(flip_v_three_rows) :-
    patch_flip_v([[1,2],[3,4],[5,6]], F),
    F = [[5,6],[3,4],[1,2]].

% A single-row patch is unchanged by vertical flip.
test(flip_v_single_row) :-
    patch_flip_v([[1,2,3]], F),
    F = [[1,2,3]].

% patch_rot90/2 tests

% Rotating a 2x3 patch 90 degrees clockwise produces a 3x2 patch.
test(rot90_2x3) :-
    patch_rot90([[1,2,3],[4,5,6]], Rotated),
    Rotated = [[4,1],[5,2],[6,3]].

% Rotating a 1x1 patch produces the same 1x1 patch.
test(rot90_1x1) :-
    patch_rot90([[5]], Rotated),
    Rotated = [[5]].

% Rotating a 2x2 patch 90 degrees clockwise.
test(rot90_2x2) :-
    patch_rot90([[1,2],[3,4]], Rotated),
    Rotated = [[3,1],[4,2]].

:- end_tests(patch).
