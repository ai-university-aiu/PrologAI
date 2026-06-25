% PLUnit tests for the noise pack (ns_* predicates).
:- use_module(library(plunit)).
:- use_module(library(noise)).

% Helper grids.
% Mostly-zero grid with a few non-zero cells (noisy).
noisy_grid([[0,0,0],[0,1,0],[0,0,0]]).
% Grid with majority color 5, one noise cell (3).
majority_grid([[5,5,5],[5,3,5],[5,5,5]]).
% 3x3 binary mask.
mask_3x3([[1,0,1],[0,1,0],[1,0,1]]).
% 3x3 complementary mask.
mask_comp([[0,1,0],[1,0,1],[0,1,0]]).
% Grid to apply mask to.
base_grid([[1,2,3],[4,5,6],[7,8,9]]).
% Color grid with color 2 in specific positions.
color_grid([[1,2,1],[2,1,2],[1,2,1]]).
% 2x3 grid.
g_2x3([[0,0,0],[0,0,0]]).

:- begin_tests(noise_ns_mask_apply).

test(mask_apply_basic) :-
    base_grid(G),
    mask_3x3(M),
    % Cells where mask=1 become 0; others keep value.
    ns_mask_apply(G, M, 0, R),
    R = [[0,2,0],[4,0,6],[0,8,0]].

test(mask_apply_all_zeros) :-
    % Mask of all zeros: grid unchanged.
    G = [[1,2],[3,4]],
    M = [[0,0],[0,0]],
    ns_mask_apply(G, M, 9, R),
    R = G.

test(mask_apply_all_ones) :-
    % Mask of all ones: grid becomes fill color.
    G = [[1,2],[3,4]],
    M = [[1,1],[1,1]],
    ns_mask_apply(G, M, 7, R),
    R = [[7,7],[7,7]].

:- end_tests(noise_ns_mask_apply).

:- begin_tests(noise_ns_mask_invert).

test(invert_basic) :-
    mask_3x3(M),
    ns_mask_invert(M, 3, Inv),
    Inv = [[0,1,0],[1,0,1],[0,1,0]].

test(invert_all_zeros) :-
    M = [[0,0],[0,0]],
    ns_mask_invert(M, 2, Inv),
    Inv = [[1,1],[1,1]].

test(invert_inverts_complement) :-
    % Inverting twice gives back the original.
    mask_3x3(M),
    ns_mask_invert(M, 3, Inv),
    ns_mask_invert(Inv, 3, M2),
    M2 = M.

:- end_tests(noise_ns_mask_invert).

:- begin_tests(noise_ns_mask_and).

test(and_basic) :-
    mask_3x3(M1), mask_comp(M2),
    % AND of complementary masks should be all zeros.
    ns_mask_and(M1, M2, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

test(and_with_self) :-
    % AND with self = self.
    mask_3x3(M),
    ns_mask_and(M, M, R),
    R = M.

:- end_tests(noise_ns_mask_and).

:- begin_tests(noise_ns_mask_or).

test(or_basic) :-
    mask_3x3(M1), mask_comp(M2),
    % OR of complementary masks should be all ones.
    ns_mask_or(M1, M2, R),
    R = [[1,1,1],[1,1,1],[1,1,1]].

test(or_with_zeros) :-
    % OR with all-zeros = self.
    mask_3x3(M),
    Zero = [[0,0,0],[0,0,0],[0,0,0]],
    ns_mask_or(M, Zero, R),
    R = M.

:- end_tests(noise_ns_mask_or).

:- begin_tests(noise_ns_mask_from_color).

test(mask_from_color_basic) :-
    color_grid(G),
    % Color 2 appears at (0,1), (1,0), (1,2), (2,1).
    ns_mask_from_color(G, 2, M),
    M = [[0,1,0],[1,0,1],[0,1,0]].

test(mask_from_color_absent) :-
    % Color not present: all-zero mask.
    G = [[1,1],[1,1]],
    ns_mask_from_color(G, 9, M),
    M = [[0,0],[0,0]].

test(mask_from_color_all) :-
    % Uniform grid: all ones.
    G = [[3,3],[3,3]],
    ns_mask_from_color(G, 3, M),
    M = [[1,1],[1,1]].

:- end_tests(noise_ns_mask_from_color).

:- begin_tests(noise_ns_mask_to_region).

test(to_region_basic) :-
    mask_3x3(M),
    ns_mask_to_region(M, Region),
    msort(Region, S),
    S = [r(0,0), r(0,2), r(1,1), r(2,0), r(2,2)].

test(to_region_empty) :-
    % All-zero mask: empty region.
    ns_mask_to_region([[0,0],[0,0]], R),
    R = [].

:- end_tests(noise_ns_mask_to_region).

:- begin_tests(noise_ns_region_to_mask).

test(region_to_mask_basic) :-
    % Build mask from region of corner cells.
    Region = [r(0,0), r(0,2), r(2,0), r(2,2)],
    ns_region_to_mask(Region, 3, 3, M),
    M = [[1,0,1],[0,0,0],[1,0,1]].

test(region_to_mask_empty) :-
    ns_region_to_mask([], 2, 2, M),
    M = [[0,0],[0,0]].

:- end_tests(noise_ns_region_to_mask).

:- begin_tests(noise_ns_color_count).

test(color_count_basic) :-
    color_grid(G),
    ns_color_count(G, 2, N),
    N =:= 4.

test(color_count_absent) :-
    G = [[1,1],[1,1]],
    ns_color_count(G, 9, N),
    N =:= 0.

test(color_count_all) :-
    G = [[3,3],[3,3]],
    ns_color_count(G, 3, N),
    N =:= 4.

:- end_tests(noise_ns_color_count).

:- begin_tests(noise_ns_majority_color).

test(majority_basic) :-
    majority_grid(G),
    ns_majority_color(G, C),
    C =:= 5.

test(majority_uniform) :-
    G = [[7,7],[7,7]],
    ns_majority_color(G, C),
    C =:= 7.

:- end_tests(noise_ns_majority_color).

:- begin_tests(noise_ns_noise_cells).

test(noise_cells_basic) :-
    majority_grid(G),
    ns_noise_cells(G, 0, Cells),
    % Only the cell with color 3 at (1,1) is noise.
    Cells = [r(1,1)].

test(noise_cells_none) :-
    % Uniform grid: no noise.
    G = [[5,5],[5,5]],
    ns_noise_cells(G, 0, Cells),
    Cells = [].

:- end_tests(noise_ns_noise_cells).

:- begin_tests(noise_ns_denoise).

test(denoise_basic) :-
    majority_grid(G),
    ns_denoise(G, 0, R),
    % All cells become 5 (the majority).
    R = [[5,5,5],[5,5,5],[5,5,5]].

test(denoise_uniform) :-
    G = [[5,5],[5,5]],
    ns_denoise(G, 0, R),
    R = G.

:- end_tests(noise_ns_denoise).

:- begin_tests(noise_ns_sparse_cells).

test(sparse_basic) :-
    % color 3 appears once; sparse threshold N=2 -> color 3 cells are sparse.
    majority_grid(G),
    ns_sparse_cells(G, 2, Sparse),
    Sparse = [r(1,1)].

test(sparse_none) :-
    % Uniform grid: every color appears 4 times; no sparse cells for N=2.
    G = [[5,5],[5,5]],
    ns_sparse_cells(G, 2, Sparse),
    Sparse = [].

:- end_tests(noise_ns_sparse_cells).

:- begin_tests(noise_ns_dense_cells).

test(dense_basic) :-
    % color 5 appears 8 times; dense threshold N=5.
    majority_grid(G),
    ns_dense_cells(G, 5, Dense),
    % All 8 cells of color 5 are dense.
    length(Dense, L), L =:= 8.

test(dense_none) :-
    % No color appears 10+ times in a 9-cell grid.
    majority_grid(G),
    ns_dense_cells(G, 10, Dense),
    Dense = [].

:- end_tests(noise_ns_dense_cells).

:- begin_tests(noise_ns_isolate_color).

test(isolate_basic) :-
    color_grid(G),
    ns_isolate_color(G, 2, R),
    % Color 2 cells keep value; others become 0.
    R = [[0,2,0],[2,0,2],[0,2,0]].

test(isolate_absent) :-
    % Color not present: all become 0.
    G = [[1,1],[1,1]],
    ns_isolate_color(G, 9, R),
    R = [[0,0],[0,0]].

test(isolate_all) :-
    % Uniform grid with the color: unchanged.
    G = [[2,2],[2,2]],
    ns_isolate_color(G, 2, R),
    R = G.

:- end_tests(noise_ns_isolate_color).
