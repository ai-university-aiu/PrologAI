:- module(grid_scale, [
    grid_scale_upsample/3,
    grid_scale_downsample/3,
    grid_scale_block_majority/3,
    grid_scale_scale_factor/3,
    grid_scale_is_scale_of/3,
    grid_scale_block_at/5,
    grid_scale_block_uniform/5,
    grid_scale_all_uniform/2,
    grid_scale_infer_tile/2,
    grid_scale_factors/2,
    grid_scale_resize/4,
    grid_scale_subsample/3,
    grid_scale_pad/4,
    grid_scale_crop_to_factor/3
]).
% gridscale.pl - Layer 202: Grid Block-Pixel Scaling (gsc_* prefix).
% All predicates operate on raw grid format: list of rows, each row a list
% of color atoms, 0-indexed (row 0 = top, col 0 = left).
% "Block size N" means the grid is partitioned into NxN pixel blocks;
% block (BR, BC) covers raw cells (BR*N .. BR*N+N-1) x (BC*N .. BC*N+N-1).
:- use_module(library(lists), [
    nth0/3, member/2, append/2, append/3, reverse/2, last/2
]).
:- use_module(library(apply), [maplist/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_scale_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; 0 for an empty grid.
    (H > 0 -> Grid = [First|_], length(First, W) ; W = 0).

% Read cell value at (R, C).
grid_scale_cell_(Grid, R, C, V) :-
% Index into row R then column C.
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% Extract SH x SW sub-grid starting at raw cell (SR, SC).
grid_scale_subgrid_(Grid, SR, SC, SH, SW, Sub) :-
    SH1 is SH - 1,
    SW1 is SW - 1,
% Collect rows SR .. SR+SH-1, each trimmed to columns SC .. SC+SW-1.
    findall(Row,
        (between(0, SH1, DR),
         R is SR + DR,
         findall(V,
             (between(0, SW1, DC),
              C is SC + DC,
              grid_scale_cell_(Grid, R, C, V)),
             Row)),
        Sub).

% Most frequent element of a non-empty flat list; ties broken by term order.
grid_scale_majority_(List, V) :-
    list_to_set(List, Colors),
% Build (-Count, Color) pairs for msort to pick the largest count.
    findall(NegN-C,
        (member(C, Colors),
         include(=(C), List, Cs),
         length(Cs, N),
         NegN is -N),
        Keyed),
    msort(Keyed, [_-V|_]).

% --- EXPORTED PREDICATES ---

% grid_scale_upsample(+Grid, +N, -Scaled)
% Scaled is Grid upsampled by integer factor N: each source cell becomes
% an NxN block of the same color. Scaled has dimensions (H*N) x (W*N).
% N=1 is a no-op (returns a copy). Fails for N < 1.
grid_scale_upsample(Grid, N, Scaled) :-
% Compute scaled dimensions.
    grid_scale_dims_(Grid, H, W),
    SH is H * N,
    SW is W * N,
    SH1 is SH - 1,
    SW1 is SW - 1,
% Row R of Scaled reads from block row R//N; col C reads from block col C//N.
    findall(Row,
        (between(0, SH1, R),
         BR is R // N,
         findall(V,
             (between(0, SW1, C),
              BC is C // N,
              grid_scale_cell_(Grid, BR, BC, V)),
             Row)),
        Scaled).

% grid_scale_downsample(+Grid, +N, -Small)
% Small is Grid downsampled by integer factor N: each NxN block must be
% uniform (all cells the same color); that color becomes one cell in Small.
% Small has dimensions (H//N) x (W//N). Fails if any block is not uniform.
grid_scale_downsample(Grid, N, Small) :-
% Uniformity check first so findall below never silences a block failure.
    grid_scale_all_uniform(Grid, N),
    grid_scale_dims_(Grid, H, W),
    BH is H // N,
    BW is W // N,
    BH1 is BH - 1,
    BW1 is BW - 1,
% All blocks are confirmed uniform; collect each block's color.
    findall(Row,
        (between(0, BH1, BR),
         findall(V, (between(0, BW1, BC), grid_scale_block_uniform(Grid, N, BR, BC, V)), Row)),
        Small).

% grid_scale_block_majority(+Grid, +N, -Small)
% Small is Grid downsampled by integer factor N using majority vote: each
% NxN block is reduced to the most frequent color in that block. Never fails
% (works even when blocks are not uniform). Small has (H//N) x (W//N) cells.
grid_scale_block_majority(Grid, N, Small) :-
    grid_scale_dims_(Grid, H, W),
    BH is H // N,
    BW is W // N,
    BH1 is BH - 1,
    BW1 is BW - 1,
% For each block, flatten cells and pick the majority color.
    findall(Row,
        (between(0, BH1, BR),
         findall(MajV,
             (between(0, BW1, BC),
              grid_scale_block_at(Grid, N, BR, BC, Block),
              append(Block, Cells),
              grid_scale_majority_(Cells, MajV)),
             Row)),
        Small).

% grid_scale_scale_factor(+GridA, +GridB, -N)
% N is the integer scale factor such that GridB = grid_scale_upsample(GridA, N).
% Requires H_B = H_A * N and W_B = W_A * N for the same N. Fails if no
% exact integer upscaling relationship exists between the two grids.
grid_scale_scale_factor(GridA, GridB, N) :-
    grid_scale_dims_(GridA, HA, WA),
    grid_scale_dims_(GridB, HB, WB),
    HA > 0,
    WA > 0,
% N must divide both dimensions consistently.
    HB mod HA =:= 0,
    WB mod WA =:= 0,
    N is HB // HA,
    N =:= WB // WA,
% Verify pixel content matches.
    grid_scale_is_scale_of(GridA, GridB, N).

% grid_scale_is_scale_of(+GridA, +GridB, +N)
% Succeed if GridB is exactly GridA upsampled by integer factor N:
% GridB[r][c] = GridA[r // N][c // N] for all valid (r, c). Uses
% negation-as-failure for efficiency.
grid_scale_is_scale_of(GridA, GridB, N) :-
    grid_scale_dims_(GridB, HB, WB),
    HB1 is HB - 1,
    WB1 is WB - 1,
% Fail if any cell in GridB disagrees with the upsampled value from GridA.
    \+ (between(0, HB1, R),
        between(0, WB1, C),
        BR is R // N,
        BC is C // N,
        grid_scale_cell_(GridA, BR, BC, VA),
        grid_scale_cell_(GridB, R, C, VB),
        VA \= VB).

% grid_scale_block_at(+Grid, +N, +BR, +BC, -Block)
% Block is the NxN sub-grid at block position (BR, BC): raw rows
% BR*N .. BR*N+N-1 and columns BC*N .. BC*N+N-1. Block is a list of N rows,
% each a list of N color atoms.
grid_scale_block_at(Grid, N, BR, BC, Block) :-
    SR is BR * N,
    SC is BC * N,
    grid_scale_subgrid_(Grid, SR, SC, N, N, Block).

% grid_scale_block_uniform(+Grid, +N, +BR, +BC, -Color)
% Succeed if the NxN block at block position (BR, BC) is all one Color.
% Fails if any cell in the block differs from the first cell.
grid_scale_block_uniform(Grid, N, BR, BC, Color) :-
    grid_scale_block_at(Grid, N, BR, BC, Block),
% Flatten rows into a single list.
    append(Block, [Color|Rest]),
% All remaining cells must equal Color.
    maplist(=(Color), Rest).

% grid_scale_all_uniform(+Grid, +N)
% Succeed if every NxN block in Grid is uniform (all cells same color).
% This is the necessary condition for Grid being an exact N-upsampling of
% a smaller grid.
grid_scale_all_uniform(Grid, N) :-
    grid_scale_dims_(Grid, H, W),
    BH is H // N,
    BW is W // N,
    BH1 is BH - 1,
    BW1 is BW - 1,
% Fail if any block is not uniform.
    \+ (between(0, BH1, BR),
        between(0, BW1, BC),
        \+ grid_scale_block_uniform(Grid, N, BR, BC, _)).

% grid_scale_infer_tile(+Grid, -Tile)
% Tile is the smallest grid whose N-upsampling equals Grid, where N is the
% largest valid block size (all NxN blocks are uniform). Searches from the
% largest possible divisor down. Fails if no N > 1 satisfies grid_scale_all_uniform.
grid_scale_infer_tile(Grid, Tile) :-
    grid_scale_dims_(Grid, H, W),
    MinHW is min(H, W),
% Collect all divisors of both H and W that are >= 2.
    findall(N,
        (between(2, MinHW, N),
         H mod N =:= 0,
         W mod N =:= 0),
        Divs),
% Reverse to try largest first.
    reverse(Divs, Desc),
    member(N, Desc),
    grid_scale_all_uniform(Grid, N), !,
    grid_scale_downsample(Grid, N, Tile).

% grid_scale_factors(+Grid, -Factors)
% Factors is the ascending list of all positive integers N that divide both
% the height and the width of Grid. Always includes 1 and includes H and W
% when H = W. Useful for finding legal block sizes.
grid_scale_factors(Grid, Factors) :-
    grid_scale_dims_(Grid, H, W),
    MinHW is min(H, W),
% N must divide both H and W exactly.
    findall(N, (between(1, MinHW, N), H mod N =:= 0, W mod N =:= 0), Factors).

% grid_scale_resize(+Grid, +TargetH, +TargetW, -Resized)
% Resized is Grid resized to TargetH x TargetW using nearest-neighbor
% interpolation: Resized[r][c] = Grid[(r * H) // TargetH][(c * W) // TargetW].
% Works for both upsampling and downsampling. Grid must be non-empty.
grid_scale_resize(Grid, TargetH, TargetW, Resized) :-
    grid_scale_dims_(Grid, H, W),
    TH1 is TargetH - 1,
    TW1 is TargetW - 1,
% Map each target cell back to the nearest source cell.
    findall(Row,
        (between(0, TH1, R),
         SR is (R * H) // TargetH,
         findall(V,
             (between(0, TW1, C),
              SC is (C * W) // TargetW,
              grid_scale_cell_(Grid, SR, SC, V)),
             Row)),
        Resized).

% grid_scale_subsample(+Grid, +N, -Sub)
% Sub is formed by taking every N-th row and every N-th column of Grid
% (stride-N sampling): Sub[BR][BC] = Grid[BR*N][BC*N].
% Sub has dimensions (H//N) x (W//N). N must be >= 1.
grid_scale_subsample(Grid, N, Sub) :-
    grid_scale_dims_(Grid, H, W),
    BH is H // N,
    BW is W // N,
    BH1 is BH - 1,
    BW1 is BW - 1,
% Row BR of Sub = row BR*N of Grid; col BC = col BC*N.
    findall(Row,
        (between(0, BH1, BR),
         R is BR * N,
         findall(V,
             (between(0, BW1, BC),
              C is BC * N,
              grid_scale_cell_(Grid, R, C, V)),
             Row)),
        Sub).

% grid_scale_pad(+Grid, +N, +Color, -Padded)
% Padded is Grid surrounded by an N-cell wide border of Color. Padded has
% dimensions (H + 2*N) x (W + 2*N). The original grid occupies rows N..N+H-1
% and columns N..N+W-1 in Padded.
grid_scale_pad(Grid, N, Color, Padded) :-
    grid_scale_dims_(Grid, H, W),
    NewH is H + 2 * N,
    NewW is W + 2 * N,
    NewH1 is NewH - 1,
    NewW1 is NewW - 1,
% Each Padded cell: use Grid if inside original bounds, else Color.
    findall(Row,
        (between(0, NewH1, R),
         findall(V,
             (between(0, NewW1, C),
              GR is R - N,
              GC is C - N,
              (GR >= 0, GR < H, GC >= 0, GC < W ->
                  grid_scale_cell_(Grid, GR, GC, V)
              ;
                  V = Color)),
             Row)),
        Padded).

% grid_scale_crop_to_factor(+Grid, +N, -Cropped)
% Cropped is Grid cropped to the largest dimensions divisible by N:
% CH = (H // N) * N rows, CW = (W // N) * N columns, taking the top-left
% region. If H and W are already divisible by N, Cropped = Grid.
grid_scale_crop_to_factor(Grid, N, Cropped) :-
    grid_scale_dims_(Grid, H, W),
    CH is (H // N) * N,
    CW is (W // N) * N,
    grid_scale_subgrid_(Grid, 0, 0, CH, CW, Cropped).
