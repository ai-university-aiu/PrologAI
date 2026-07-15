% zoom.pl - Layer 111: Integer-Factor Grid Scaling (zm_* prefix).
% Provides predicates for upscaling and downscaling integer grids by an integer
% factor, extracting and splitting FxF tiles, inferring scale factors, testing
% scaled equivalence, computing tile dimensions, finding the dominant color of
% a tile, downsampling by mode, and tiling a small grid NR x NC times.
:- module(zoom, [
    zoom_scale_up/3,
    zoom_scale_down/3,
    zoom_scale_up_row/3,
    zoom_scale_down_row/3,
    zoom_scale_factor/3,
    zoom_is_scaled_up/3,
    zoom_dims_up/5,
    zoom_dims_down/5,
    zoom_extract_block/5,
    zoom_split_blocks/3,
    zoom_blocks_dims/4,
    zoom_block_color/5,
    zoom_scale_down_mode/3,
    zoom_tile_grid/4
]).
% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, last/2]).
% Import higher-order filtering.
:- use_module(library(apply), [include/3]).

% zoom_take_cols_: extract W columns starting at column C0 from a row.
zoom_take_cols_(Row, C0, W, SubRow) :-
% Build a skip list of length C0 to consume the first C0 elements.
    length(Skip, C0),
% Split the row into the skipped prefix and the suffix starting at C0.
    append(Skip, Suffix, Row),
% Build a result list of length W to consume exactly W elements from Suffix.
    length(SubRow, W),
% Split the suffix into the W-element sub-row and the trailing remainder.
    append(SubRow, _, Suffix).

% zoom_scale_up_row(+Row, +F, -BigRow): BigRow is Row with each element repeated
% F consecutive times. An empty row gives an empty result.
zoom_scale_up_row([], _, []) :- !.
zoom_scale_up_row([V|Rest], F, BigRow) :-
% Build F copies of the current value V.
    findall(V, between(1, F, _), Copies),
% Recursively scale the remaining elements.
    zoom_scale_up_row(Rest, F, BigRest),
% Concatenate the F copies with the scaled tail.
    append(Copies, BigRest, BigRow).

% zoom_scale_down_row(+Row, +F, -SmallRow): SmallRow contains every Fth element
% of Row starting at index 0 (the top-left corner of each F-wide block).
zoom_scale_down_row(Row, F, SmallRow) :-
    length(Row, N),
    N1 is N - 1,
% Collect elements at indices 0, F, 2F, ... (one per F-wide block).
    findall(V, (
        between(0, N1, I),
        I mod F =:= 0,
        nth0(I, Row, V)
    ), SmallRow).

% zoom_scale_up(+Grid, +F, -Big): Big is Grid scaled up by integer factor F.
% Each cell becomes an FxF block of the same color. The result has H*F rows
% and W*F columns. Each row is first scaled horizontally, then duplicated F
% times vertically before processing the next row.
zoom_scale_up([], _, []) :- !.
zoom_scale_up([Row|Rest], F, Big) :-
% Scale this row horizontally by F: each cell becomes F consecutive copies.
    zoom_scale_up_row(Row, F, ScaledRow),
% Create F identical copies of the scaled row for the vertical expansion.
    findall(ScaledRow, between(1, F, _), Copies),
% Recursively scale the remaining rows.
    zoom_scale_up(Rest, F, BigRest),
% Concatenate this block's F rows with the scaled tail.
    append(Copies, BigRest, Big).

% zoom_scale_down(+Grid, +F, -Small): Small is Grid downsampled by factor F.
% Samples row 0, F, 2F, ... and within each row column 0, F, 2F, ...
zoom_scale_down(Grid, F, Small) :-
    length(Grid, H),
    H1 is H - 1,
% Collect every Fth row and apply zoom_scale_down_row to each.
    findall(SmallRow, (
        between(0, H1, R),
        R mod F =:= 0,
        nth0(R, Grid, Row),
        zoom_scale_down_row(Row, F, SmallRow)
    ), Small).

% zoom_scale_factor(+Small, +Big, -F): F is the integer scale factor such that
% zoom_scale_up(Small, F) = Big. Uses the ratio of row widths.
zoom_scale_factor(Small, Big, F) :-
% Use the first rows of each grid to compute the column ratio.
    Small = [SmallRow|_],
    Big = [BigRow|_],
    length(SmallRow, WS),
    length(BigRow, WB),
% The width ratio must be exact.
    WB mod WS =:= 0,
    F is WB // WS.

% zoom_is_scaled_up(+Small, +Big, +F): succeed if Big is the F-factor upscaling
% of Small. Verifies by computing zoom_scale_up and unifying.
zoom_is_scaled_up(Small, Big, F) :-
    zoom_scale_up(Small, F, Big).

% zoom_dims_up(+H, +W, +F, -BH, -BW): BH and BW are the dimensions of a grid
% of size H x W after upscaling by factor F.
zoom_dims_up(H, W, F, BH, BW) :-
    BH is H * F,
    BW is W * F.

% zoom_dims_down(+H, +W, +F, -SH, -SW): SH and SW are the dimensions of a grid
% of size H x W after integer downsampling by factor F.
zoom_dims_down(H, W, F, SH, SW) :-
    SH is H // F,
    SW is W // F.

% zoom_extract_block(+Grid, +F, +BR, +BC, -Block): Block is the FxF sub-grid at
% tile position (BR, BC) where tiles are indexed 0-based from the top-left.
zoom_extract_block(Grid, F, BR, BC, Block) :-
% Compute the top-left row and column of this block.
    R0 is BR * F,
    C0 is BC * F,
    R1 is R0 + F - 1,
% Collect F consecutive rows, each cropped to F columns starting at C0.
    findall(SubRow, (
        between(R0, R1, R),
        nth0(R, Grid, FullRow),
        zoom_take_cols_(FullRow, C0, F, SubRow)
    ), Block).

% zoom_blocks_dims(+Grid, +F, -NR, -NC): NR and NC are the number of F-sized
% tile blocks along the row and column dimensions.
zoom_blocks_dims(Grid, F, NR, NC) :-
    length(Grid, H),
    Grid = [Row|_],
    length(Row, W),
    NR is H // F,
    NC is W // F.

% zoom_split_blocks(+Grid, +F, -Blocks): Blocks is the flat list of all FxF
% tile blocks from Grid in row-major order: (0,0), (0,1), ..., (NR-1,NC-1).
zoom_split_blocks(Grid, F, Blocks) :-
    zoom_blocks_dims(Grid, F, NR, NC),
    NR1 is NR - 1,
    NC1 is NC - 1,
% Enumerate all block positions in row-major order.
    findall(Block, (
        between(0, NR1, BR),
        between(0, NC1, BC),
        zoom_extract_block(Grid, F, BR, BC, Block)
    ), Blocks).

% zoom_block_color(+Grid, +F, +BR, +BC, -Color): Color is the single color value
% of the uniform FxF block at tile position (BR, BC). Fails if the block is not
% uniform (contains more than one distinct color value).
zoom_block_color(Grid, F, BR, BC, Color) :-
% Extract the FxF block.
    zoom_extract_block(Grid, F, BR, BC, Block),
% Flatten the block rows into a single cell list.
    append(Block, Flat),
% Bind Color to the first cell and verify all cells match.
    Flat = [Color|_],
    forall(member(V, Flat), V =:= Color).

% zoom_mode_: find the most common value in a non-empty list.
% On ties, the largest value wins (msort + last ordering).
zoom_mode_(List, Mode) :-
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

% zoom_scale_down_mode(+Grid, +F, -Small): Small is a downsampled grid where each
% cell is the most common (mode) value among the F x F source block. On ties in
% count, the largest value in the block wins.
zoom_scale_down_mode(Grid, F, Small) :-
    zoom_blocks_dims(Grid, F, NR, NC),
    NR1 is NR - 1,
    NC1 is NC - 1,
% Build one output row per block row.
    findall(SmallRow, (
        between(0, NR1, BR),
% Within that row, one output cell per block column.
        findall(Mode, (
            between(0, NC1, BC),
            zoom_extract_block(Grid, F, BR, BC, Block),
            append(Block, Flat),
            zoom_mode_(Flat, Mode)
        ), SmallRow)
    ), Small).

% zoom_tile_grid(+Tile, +NR, +NC, -Grid): Grid is Tile repeated NR times
% vertically and NC times horizontally. Tile dimensions multiply by (NR, NC).
zoom_tile_grid(Tile, NR, NC, Grid) :-
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
