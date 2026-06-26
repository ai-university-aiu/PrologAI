:- use_module('../prolog/gridscale').
:- use_module(library(plunit)).

% Grid fixtures

% 1x1 single-cell grid
g1x1([[r]]).

% 2x2 uniform red
g2x2_r([[r,r],[r,r]]).

% 2x2 checkerboard
g2x2_check([[r,b],[b,r]]).

% 2x2 two-color top/bottom
g2x2_tb([[r,r],[b,b]]).

% 4x4: each 2x2 block is uniform r or b (upsampled from g2x2_check)
g4x4_up2([[r,r,b,b],[r,r,b,b],[b,b,r,r],[b,b,r,r]]).

% 4x4 uniform r
g4x4_r([[r,r,r,r],[r,r,r,r],[r,r,r,r],[r,r,r,r]]).

% 4x4 non-uniform blocks (top-left block is r,b,b,r — not uniform)
g4x4_nonunif([[r,b,r,r],[b,r,r,r],[r,r,b,b],[r,r,b,b]]).

% 3x3: all r
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).

% 3x3: rgb rows
g3x3_rows([[r,r,r],[b,b,b],[g,g,g]]).

% 4x6: upsampling of g2x3 = [[r,b,g],[b,r,g]] by factor 2
g2x3([[r,b,g],[b,r,g]]).
g4x6_up2([[r,r,b,b,g,g],[r,r,b,b,g,g],[b,b,r,r,g,g],[b,b,r,r,g,g]]).

% 6x6: upsampling of g2x2_check by factor 3
g6x6_up3([[r,r,r,b,b,b],[r,r,r,b,b,b],[r,r,r,b,b,b],[b,b,b,r,r,r],[b,b,b,r,r,r],[b,b,b,r,r,r]]).

:- begin_tests(gridscale).

% --- gsc_upsample/3 ---

test(upsample_1x1_by_2) :-
% 1x1 [[r]] upsampled by 2 gives 2x2 [[r,r],[r,r]].
    g1x1(G),
    gsc_upsample(G, 2, S),
    S = [[r,r],[r,r]].

test(upsample_2x2_check_by_2) :-
% 2x2 checkerboard upsampled by 2 gives g4x4_up2.
    g2x2_check(G),
    gsc_upsample(G, 2, S),
    g4x4_up2(Expected),
    S = Expected.

test(upsample_2x2_check_by_3) :-
% 2x2 checkerboard upsampled by 3 gives g6x6_up3.
    g2x2_check(G),
    gsc_upsample(G, 3, S),
    g6x6_up3(Expected),
    S = Expected.

test(upsample_by_1_identity) :-
% Upsampling by 1 is a no-op.
    g3x3_rows(G),
    gsc_upsample(G, 1, S),
    S = G.

test(upsample_2x3_by_2) :-
% 2x3 grid upsampled by 2 gives g4x6_up2.
    g2x3(G),
    gsc_upsample(G, 2, S),
    g4x6_up2(Expected),
    S = Expected.

% --- gsc_downsample/3 ---

test(downsample_4x4_by_2) :-
% g4x4_up2 downsampled by 2 recovers g2x2_check.
    g4x4_up2(G),
    gsc_downsample(G, 2, S),
    g2x2_check(Expected),
    S = Expected.

test(downsample_4x4_uniform_by_4) :-
% 4x4 all-r downsampled by 4 gives 1x1 [[r]].
    g4x4_r(G),
    gsc_downsample(G, 4, S),
    S = [[r]].

test(downsample_nonuniform_fails, [fail]) :-
% g4x4_nonunif cannot be downsampled by 2 (top-left block not uniform).
    g4x4_nonunif(G),
    gsc_downsample(G, 2, _).

test(downsample_6x6_by_3) :-
% g6x6_up3 downsampled by 3 recovers g2x2_check.
    g6x6_up3(G),
    gsc_downsample(G, 3, S),
    g2x2_check(Expected),
    S = Expected.

test(downsample_by_1_identity) :-
% Downsampling by 1 is a no-op.
    g2x2_check(G),
    gsc_downsample(G, 1, S),
    S = G.

% --- gsc_block_majority/3 ---

test(block_majority_uniform_blocks) :-
% When all blocks are uniform, block_majority = downsample.
    g4x4_up2(G),
    gsc_block_majority(G, 2, S),
    g2x2_check(Expected),
    S = Expected.

test(block_majority_mixed_block) :-
% Top-left 2x2 block of g4x4_nonunif = [r,b;b,r]: 2 r and 2 b; msort picks b (b < r).
    g4x4_nonunif(G),
    gsc_block_majority(G, 2, S),
    S = [[b,r],[r,b]].

test(block_majority_by_1) :-
% Block size 1: majority is just the cell itself.
    g2x2_check(G),
    gsc_block_majority(G, 1, S),
    S = G.

% --- gsc_scale_factor/3 ---

test(scale_factor_2x2_to_4x4) :-
% g2x2_check -> g4x4_up2 has scale factor 2.
    g2x2_check(A),
    g4x4_up2(B),
    gsc_scale_factor(A, B, N),
    N =:= 2.

test(scale_factor_2x2_to_6x6) :-
% g2x2_check -> g6x6_up3 has scale factor 3.
    g2x2_check(A),
    g6x6_up3(B),
    gsc_scale_factor(A, B, N),
    N =:= 3.

test(scale_factor_identity) :-
% Same grid: scale factor 1.
    g2x2_check(G),
    gsc_scale_factor(G, G, N),
    N =:= 1.

test(scale_factor_fails_nonscale, [fail]) :-
% g3x3_rows -> g4x4_r: dimensions don't match a uniform scale.
    g3x3_rows(A),
    g4x4_r(B),
    gsc_scale_factor(A, B, _).

% --- gsc_is_scale_of/3 ---

test(is_scale_of_n2_succeeds) :-
% g4x4_up2 is g2x2_check upsampled by 2.
    g2x2_check(A),
    g4x4_up2(B),
    gsc_is_scale_of(A, B, 2).

test(is_scale_of_n3_succeeds) :-
% g6x6_up3 is g2x2_check upsampled by 3.
    g2x2_check(A),
    g6x6_up3(B),
    gsc_is_scale_of(A, B, 3).

test(is_scale_of_fails, [fail]) :-
% g4x4_nonunif is NOT an upsampling of g2x2_check by 2.
    g2x2_check(A),
    g4x4_nonunif(B),
    gsc_is_scale_of(A, B, 2).

% --- gsc_block_at/5 ---

test(block_at_0_0) :-
% Top-left 2x2 block of g4x4_up2 is [[r,r],[r,r]].
    g4x4_up2(G),
    gsc_block_at(G, 2, 0, 0, Block),
    Block = [[r,r],[r,r]].

test(block_at_0_1) :-
% Top-right 2x2 block of g4x4_up2 is [[b,b],[b,b]].
    g4x4_up2(G),
    gsc_block_at(G, 2, 0, 1, Block),
    Block = [[b,b],[b,b]].

test(block_at_1_0) :-
% Bottom-left 2x2 block of g4x4_up2 is [[b,b],[b,b]].
    g4x4_up2(G),
    gsc_block_at(G, 2, 1, 0, Block),
    Block = [[b,b],[b,b]].

test(block_at_1x1_block) :-
% With block size 1, block (1,2) is just [[V]] at row 1, col 2.
    g3x3_rows(G),
    gsc_block_at(G, 1, 1, 2, Block),
    Block = [[b]].

% --- gsc_block_uniform/5 ---

test(block_uniform_top_left) :-
% Top-left 2x2 block of g4x4_up2 is uniform r.
    g4x4_up2(G),
    gsc_block_uniform(G, 2, 0, 0, Color),
    Color = r.

test(block_uniform_top_right) :-
% Top-right 2x2 block of g4x4_up2 is uniform b.
    g4x4_up2(G),
    gsc_block_uniform(G, 2, 0, 1, Color),
    Color = b.

test(block_uniform_nonunif_fails, [fail]) :-
% Top-left 2x2 block of g4x4_nonunif is [r,b;b,r] — not uniform.
    g4x4_nonunif(G),
    gsc_block_uniform(G, 2, 0, 0, _).

test(block_uniform_size1) :-
% Block size 1 at (0,0) of g3x3_rows is uniform r.
    g3x3_rows(G),
    gsc_block_uniform(G, 1, 0, 0, Color),
    Color = r.

% --- gsc_all_uniform/2 ---

test(all_uniform_g4x4_up2_n2) :-
% g4x4_up2 with block size 2: all 4 blocks are uniform.
    g4x4_up2(G),
    gsc_all_uniform(G, 2).

test(all_uniform_any_grid_n1) :-
% Block size 1 is always trivially uniform for any grid.
    g4x4_nonunif(G),
    gsc_all_uniform(G, 1).

test(all_uniform_nonunif_fails, [fail]) :-
% g4x4_nonunif with block size 2: top-left block is not uniform.
    g4x4_nonunif(G),
    gsc_all_uniform(G, 2).

test(all_uniform_uniform_grid) :-
% g4x4_r with block size 4: the single block is all r.
    g4x4_r(G),
    gsc_all_uniform(G, 4).

% --- gsc_infer_tile/2 ---

test(infer_tile_from_4x4_up2) :-
% Largest valid block size for g4x4_up2 is 2; tile = g2x2_check.
    g4x4_up2(G),
    gsc_infer_tile(G, Tile),
    g2x2_check(Expected),
    Tile = Expected.

test(infer_tile_from_6x6_up3) :-
% g6x6_up3: block size 3 is valid (2 also is, but 3 is larger); tile = g2x2_check.
    g6x6_up3(G),
    gsc_infer_tile(G, Tile),
    g2x2_check(Expected),
    Tile = Expected.

test(infer_tile_from_4x4_r) :-
% g4x4_r: all cells are r; block size 4 works; tile = [[r]].
    g4x4_r(G),
    gsc_infer_tile(G, Tile),
    Tile = [[r]].

test(infer_tile_fails_prime_sized, [fail]) :-
% g3x3_rows: H=3, W=3; only divisor >= 2 is 3;
% rows differ so block size 3 is NOT uniform (block 0,0 = full grid, not uniform).
    g3x3_rows(G),
    gsc_infer_tile(G, _).

% --- gsc_factors/2 ---

test(factors_4x4) :-
% 4x4: divisors of 4 = [1,2,4].
    g4x4_r(G),
    gsc_factors(G, F),
    F = [1,2,4].

test(factors_3x3) :-
% 3x3: divisors of 3 = [1,3].
    g3x3_r(G),
    gsc_factors(G, F),
    F = [1,3].

test(factors_2x3) :-
% 2x3: divisors common to 2 and 3 = [1].
    g2x3(G),
    gsc_factors(G, F),
    F = [1].

test(factors_6x6) :-
% 6x6: divisors of 6 = [1,2,3,6].
    g6x6_up3(G),
    gsc_factors(G, F),
    F = [1,2,3,6].

% --- gsc_resize/4 ---

test(resize_2x2_to_4x4) :-
% Resize g2x2_check to 4x4 gives g4x4_up2 (nearest neighbor).
    g2x2_check(G),
    gsc_resize(G, 4, 4, R),
    g4x4_up2(Expected),
    R = Expected.

test(resize_4x4_to_2x2) :-
% Resize g4x4_up2 to 2x2 via nearest neighbor: each cell maps to top-left of block.
% Cell (0,0): SR=0, SC=0 -> r. Cell (0,1): SR=0, SC=2 -> b.
% Cell (1,0): SR=2, SC=0 -> b. Cell (1,1): SR=2, SC=2 -> r.
    g4x4_up2(G),
    gsc_resize(G, 2, 2, R),
    g2x2_check(Expected),
    R = Expected.

test(resize_identity) :-
% Resize to same dimensions is identity.
    g3x3_rows(G),
    gsc_resize(G, 3, 3, R),
    R = G.

test(resize_1x1_to_3x3) :-
% 1x1 [[r]] resized to 3x3 gives all r.
    g1x1(G),
    gsc_resize(G, 3, 3, R),
    R = [[r,r,r],[r,r,r],[r,r,r]].

% --- gsc_subsample/3 ---

test(subsample_4x4_by_2) :-
% Stride-2 sampling of g4x4_up2: take rows 0,2 and cols 0,2.
% g4x4_up2 = [[r,r,b,b],[r,r,b,b],[b,b,r,r],[b,b,r,r]]
% Row 0, col 0 = r; row 0, col 2 = b.
% Row 2, col 0 = b; row 2, col 2 = r.
    g4x4_up2(G),
    gsc_subsample(G, 2, S),
    S = [[r,b],[b,r]].

test(subsample_by_1_identity) :-
% Stride 1 returns the grid unchanged.
    g3x3_rows(G),
    gsc_subsample(G, 1, S),
    S = G.

test(subsample_4x4_by_4) :-
% Stride 4 from 4x4 gives 1x1 with top-left cell.
    g4x4_up2(G),
    gsc_subsample(G, 4, S),
    S = [[r]].

% --- gsc_pad/4 ---

test(pad_2x2_n1_color_g) :-
% Padding g2x2_check by 1 with g gives 4x4 border.
    g2x2_check(G),
    gsc_pad(G, 1, gr, P),
    P = [[gr,gr,gr,gr],[gr,r,b,gr],[gr,b,r,gr],[gr,gr,gr,gr]].

test(pad_1x1_n2) :-
% Padding [[r]] by 2 with b gives 5x5.
    g1x1(G),
    gsc_pad(G, 2, b, P),
    length(P, 5),
    nth0(2, P, Row),
    nth0(2, Row, V),
    V = r.

test(pad_by_zero_identity) :-
% Padding by 0 returns the grid unchanged.
    g2x2_tb(G),
    gsc_pad(G, 0, x, P),
    P = G.

test(pad_dimensions) :-
% Padding 3x3 by 1 gives 5x5.
    g3x3_r(G),
    gsc_pad(G, 1, b, P),
    length(P, 5),
    P = [PR|_], length(PR, 5).

% --- gsc_crop_to_factor/3 ---

test(crop_to_factor_no_crop) :-
% 4x4 cropped to factor 2: already divisible, returns full grid.
    g4x4_up2(G),
    gsc_crop_to_factor(G, 2, C),
    C = G.

test(crop_to_factor_3x3_by_2) :-
% 3x3 cropped to factor 2: CH = (3//2)*2 = 2, CW = 2.
    g3x3_rows(G),
    gsc_crop_to_factor(G, 2, C),
    length(C, 2),
    C = [R0, R1],
    length(R0, 2), length(R1, 2).

test(crop_to_factor_4x6_by_3) :-
% g4x6_up2 (4 rows, 6 cols) cropped to factor 3: CH=(4//3)*3=3, CW=6.
    g4x6_up2(G),
    gsc_crop_to_factor(G, 3, C),
    length(C, 3),
    C = [R0|_], length(R0, 6).

test(crop_to_factor_1_identity) :-
% Factor 1 never crops.
    g3x3_r(G),
    gsc_crop_to_factor(G, 1, C),
    C = G.

% Extra round-trip and combined tests

test(upsample_then_downsample) :-
% Round-trip: upsample then downsample recovers original.
    g2x2_check(G),
    gsc_upsample(G, 2, S),
    gsc_downsample(S, 2, D),
    D = G.

test(infer_then_upsample) :-
% infer_tile then scale_factor recovers factor 2.
    g4x4_up2(G),
    gsc_infer_tile(G, Tile),
    length(G, H), H =:= 4,
    G = [GRow|_], length(GRow, W), W =:= 4,
    gsc_scale_factor(Tile, G, N),
    N =:= 2.

test(scale_factor_then_is_scale) :-
% scale_factor implies is_scale_of.
    g2x2_check(A),
    g6x6_up3(B),
    gsc_scale_factor(A, B, N),
    gsc_is_scale_of(A, B, N).

test(resize_to_1x1) :-
% Any grid resized to 1x1 gives the top-left cell.
    g4x4_up2(G),
    gsc_resize(G, 1, 1, R),
    R = [[r]].

test(pad_then_crop) :-
% Pad by 2 then crop to factor 4 and back.
    g4x4_r(G),
    gsc_pad(G, 2, b, Padded),
    length(Padded, 8),
    Padded = [PR|_], length(PR, 8).

:- end_tests(gridscale).
