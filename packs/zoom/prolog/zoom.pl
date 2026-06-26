% zoom.pl - Layer 111: Integer-Factor Grid Scaling (zm_* prefix).
% Provides predicates for upscaling and downscaling integer grids by an integer
% factor, extracting and splitting FxF tiles, inferring scale factors, testing
% scaled equivalence, computing tile dimensions, finding the dominant color of
% a tile, downsampling by mode, and tiling a small grid NR x NC times.
:- module(zoom, [
    zm_scale_up/3,
    zm_scale_down/3,
    zm_scale_up_row/3,
    zm_scale_down_row/3,
    zm_scale_factor/3,
    zm_is_scaled_up/3,
    zm_dims_up/5,
    zm_dims_down/5,
    zm_extract_block/5,
    zm_split_blocks/3,
    zm_blocks_dims/4,
    zm_block_color/5,
    zm_scale_down_mode/3,
    zm_tile_grid/4
]).
% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, last/2]).
% Import higher-order filtering.
:- use_module(library(apply), [include/3]).

% zm_take_cols_: extract W columns starting at column C0 from a row.
zm_take_cols_(Row, C0, W, SubRow) :-
% Build a skip list of length C0 to consume the first C0 elements.
    length(Skip, C0),
% Split the row into the skipped prefix and the suffix starting at C0.
    append(Skip, Suffix, Row),
% Build a result list of length W to consume exactly W elements from Suffix.
    length(SubRow, W),
% Split the suffix into the W-element sub-row and the trailing remainder.
    append(SubRow, _, Suffix).

% zm_scale_up_row(+Row, +F, -BigRow): BigRow is Row with each element repeated
% F consecutive times. An empty row gives an empty result.
zm_scale_up_row([], _, []) :- !.
zm_scale_up_row([V|Rest], F, BigRow) :-
% Build F copies of the current value V.
    findall(V, between(1, F, _), Copies),
% Recursively scale the remaining elements.
    zm_scale_up_row(Rest, F, BigRest),
% Concatenate the F copies with the scaled tail.
    append(Copies, BigRest, BigRow).

% zm_scale_down_row(+Row, +F, -SmallRow): SmallRow contains every Fth element
% of Row starting at index 0 (the top-left corner of each F-wide block).
zm_scale_down_row(Row, F, SmallRow) :-
    length(Row, N),
    N1 is N - 1,
% Collect elements at indices 0, F, 2F, ... (one per F-wide block).
    findall(V, (
        between(0, N1, I),
        I mod F =:= 0,
        nth0(I, Row, V)
    ), SmallRow).

% zm_scale_up(+Grid, +F, -Big): Big is Grid scaled up by integer factor F.
% Each cell becomes an FxF block of the same color. The result has H*F rows
% and W*F columns. Each row is first scaled horizontally, then duplicated F
% times vertically before processing the next row.
zm_scale_up([], _, []) :- !.
zm_scale_up([Row|Rest], F, Big) :-
% Scale this row horizontally by F: each cell becomes F consecutive copies.
    zm_scale_up_row(Row, F, ScaledRow),
% Create F identical copies of the scaled row for the vertical expansion.
    findall(ScaledRow, between(1, F, _), Copies),
% Recursively scale the remaining rows.
    zm_scale_up(Rest, F, BigRest),
% Concatenate this block's F rows with the scaled tail.
    append(Copies, BigRest, Big).

% zm_scale_down(+Grid, +F, -Small): Small is Grid downsampled by factor F.
% Samples row 0, F, 2F, ... and within each row column 0, F, 2F, ...
zm_scale_down(Grid, F, Small) :-
    length(Grid, H),
    H1 is H - 1,
% Collect every Fth row and apply zm_scale_down_row to each.
    findall(SmallRow, (
        between(0, H1, R),
        R mod F =:= 0,
        nth0(R, Grid, Row),
        zm_scale_down_row(Row, F, SmallRow)
    ), Small).

% zm_scale_factor(+Small, +Big, -F): F is the integer scale factor such that
% zm_scale_up(Small, F) = Big. Uses the ratio of row widths.
zm_scale_factor(Small, Big, F) :-
% Use the first rows of each grid to compute the column ratio.
    Small = [SmallRow|_],
    Big = [BigRow|_],
    length(SmallRow, WS),
    length(BigRow, WB),
% The width ratio must be exact.
    WB mod WS =:= 0,
    F is WB // WS.

% zm_is_scaled_up(+Small, +Big, +F): succeed if Big is the F-factor upscaling
% of Small. Verifies by computing zm_scale_up and unifying.
zm_is_scaled_up(Small, Big, F) :-
    zm_scale_up(Small, F, Big).

% zm_dims_up(+H, +W, +F, -BH, -BW): BH and BW are the dimensions of a grid
% of size H x W after upscaling by factor F.
zm_dims_up(H, W, F, BH, BW) :-
    BH is H * F,
    BW is W * F.

% zm_dims_down(+H, +W, +F, -SH, -SW): SH and SW are the dimensions of a grid
% of size H x W after integer downsampling by factor F.
zm_dims_down(H, W, F, SH, SW) :-
    SH is H // F,
    SW is W // F.

% zm_extract_block(+Grid, +F, +BR, +BC, -Block): Block is the FxF sub-grid at
% tile position (BR, BC) where tiles are indexed 0-based from the top-left.
zm_extract_block(Grid, F, BR, BC, Block) :-
% Compute the top-left row and column of this block.
    R0 is BR * F,
    C0 is BC * F,
    R1 is R0 + F - 1,
% Collect F consecutive rows, each cropped to F columns starting at C0.
    findall(SubRow, (
        between(R0, R1, R),
        nth0(R, Grid, FullRow),
        zm_take_cols_(FullRow, C0, F, SubRow)
    ), Block).

% zm_blocks_dims(+Grid, +F, -NR, -NC): NR and NC are the number of F-sized
% tile blocks along the row and column dimensions.
zm_blocks_dims(Grid, F, NR, NC) :-
    length(Grid, H),
    Grid = [Row|_],
    length(Row, W),
    NR is H // F,
    NC is W // F.

% zm_split_blocks(+Grid, +F, -Blocks): Blocks is the flat list of all FxF
% tile blocks from Grid in row-major order: (0,0), (0,1), ..., (NR-1,NC-1).
zm_split_blocks(Grid, F, Blocks) :-
    zm_blocks_dims(Grid, F, NR, NC),
    NR1 is NR - 1,
    NC1 is NC - 1,
% Enumerate all block positions in row-major order.
    findall(Block, (
        between(0, NR1, BR),
        between(0, NC1, BC),
        zm_extract_block(Grid, F, BR, BC, Block)
    ), Blocks).

% zm_block_color(+Grid, +F, +BR, +BC, -Color): Color is the single color value
% of the uniform FxF block at tile position (BR, BC). Fails if the block is not
% uniform (contains more than one distinct color value).
zm_block_color(Grid, F, BR, BC, Color) :-
% Extract the FxF block.
    zm_extract_block(Grid, F, BR, BC, Block),
% Flatten the block rows into a single cell list.
    append(Block, Flat),
% Bind Color to the first cell and verify all cells match.
    Flat = [Color|_],
    forall(member(V, Flat), V =:= Color).

% zm_mode_: find the most common value in a non-empty list.
% On ties, the largest value wins (msort + last ordering).
zm_mode_(List, Mode) :-
% Get the sorted list of distinct values.
    sort(List, Unique),
% For each distinct value, count its occurrences.
    findall(N-V, (
        member(V, Unique),
        include(==(V), List, Matches),
        length(Matches, N)
    ), Pairs),
% Sort N-V pairs ascending; last element has the highest count.
    msort(Pairs, Sorted),
    last(Sorted, _-Mode).

% zm_scale_down_mode(+Grid, +F, -Small): Small is a downsampled grid where each
% cell is the most common (mode) value among the F x F source block. On ties in
% count, the largest value in the block wins.
zm_scale_down_mode(Grid, F, Small) :-
    zm_blocks_dims(Grid, F, NR, NC),
    NR1 is NR - 1,
    NC1 is NC - 1,
% Build one output row per block row.
    findall(SmallRow, (
        between(0, NR1, BR),
% Within that row, one output cell per block column.
        findall(Mode, (
            between(0, NC1, BC),
            zm_extract_block(Grid, F, BR, BC, Block),
            append(Block, Flat),
            zm_mode_(Flat, Mode)
        ), SmallRow)
    ), Small).

% zm_tile_grid(+Tile, +NR, +NC, -Grid): Grid is Tile repeated NR times
% vertically and NC times horizontally. Tile dimensions multiply by (NR, NC).
zm_tile_grid(Tile, NR, NC, Grid) :-
% Expand each Tile row horizontally NC times.
    findall(TiledRow, (
        member(Row, Tile),
        findall(V, (
            between(1, NC, _),
            member(V, Row)
        ), TiledRow)
    ), TileBlockRow),
% Repeat the entire TileBlockRow NR times.
    findall(Row, (
        between(1, NR, _),
        member(Row, TileBlockRow)
    ), Grid).
