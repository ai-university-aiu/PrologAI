% block.pl - Layer 127: Rectangular Sub-Grid (Block) Decomposition (bk_* prefix).
% General-purpose predicates for splitting grids into uniform rectangular blocks
% and performing block-level operations.
:- module(block, [
    block_extract/6, block_dims/5,
    block_split_h/3, block_split_v/3,
    block_tile_h/3, block_tile_v/3,
    block_count_h/3, block_count_v/3,
    block_map/3, block_uniform/4,
    block_mode_color/4, block_border_color/4,
    block_is_solid/3, block_is_border/4
]).
% Import list utilities for row slicing, block assembly, and mode computation.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, max_list/2]).
% Import apply for row-level operations and frequency counting in mode helper.
:- use_module(library(apply), [maplist/3, include/3]).

% block_extract(+Grid, +R0, +C0, +R1, +C1, -Block): extract the rectangular
% sub-grid from row R0..R1 and column C0..C1 (all inclusive, 0-indexed).
block_extract(Grid, R0, C0, R1, C1, Block) :-
% Collect each row slice from the specified row range.
    findall(RowSlice, (
        between(R0, R1, R),
        nth0(R, Grid, Row),
        findall(V, (between(C0, C1, C), nth0(C, Row, V)), RowSlice)
    ), Block).

% block_dims(+Grid, +BH, +BW, -NR, -NC): compute number of block rows NR and
% block columns NC when dividing a grid into BH-by-BW blocks (exact division assumed).
block_dims(Grid, BH, BW, NR, NC) :-
% Grid height divided by block height gives block row count.
    length(Grid, H), NR is H // BH,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), NC is W // BW.

% block_split_h(+Grid, +BH, -Strips): split Grid into horizontal strips of height BH.
% Each strip is a list of BH consecutive rows.
block_split_h(Grid, BH, Strips) :-
% Compute number of strips and collect each strip's rows.
    length(Grid, H), NS is H // BH,
    findall(Strip, (
        between(0, NS, Si), Si < NS,
        R0 is Si * BH, R1 is R0 + BH - 1,
        findall(Row, (between(R0, R1, R), nth0(R, Grid, Row)), Strip)
    ), Strips).

% block_split_v(+Grid, +BW, -Strips): split Grid into vertical strips of width BW.
% Each strip contains all rows sliced to the BW columns.
block_split_v(Grid, BW, Strips) :-
% Compute number of vertical strips and collect each strip.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), NS is W // BW,
    findall(Strip, (
        between(0, NS, Si), Si < NS,
        C0 is Si * BW, C1 is C0 + BW - 1,
        findall(RowSlice, (
            member(Row, Grid),
            findall(V, (between(C0, C1, C), nth0(C, Row, V)), RowSlice)
        ), Strip)
    ), Strips).

% block_tile_h(+Grid, +N, -Tiled): tile Grid N times vertically (stack N copies top to bottom).
block_tile_h(Grid, N, Tiled) :-
% Replicate the grid N times and flatten with append/2.
    findall(Row, (between(1, N, _), member(Row, Grid)), Tiled).

% block_tile_v(+Grid, +N, -Tiled): tile Grid N times horizontally (extend each row N times).
block_tile_v(Grid, N, Tiled) :-
% For each row, replicate its cells N times and flatten with append/2.
    maplist(block_tile_row_(N), Grid, Tiled).
% Per-row tiling helper: collect each cell N times from all N copies of Row.
block_tile_row_(N, Row, TiledRow) :-
    findall(V, (between(1, N, _), member(V, Row)), TiledRow).

% block_count_h(+Grid, +BH, -N): number of complete horizontal strips of height BH.
block_count_h(Grid, BH, N) :-
% Integer division of grid height by block height.
    length(Grid, H), N is H // BH.

% block_count_v(+Grid, +BW, -N): number of complete vertical strips of width BW.
block_count_v(Grid, BW, N) :-
% Integer division of grid width by block width.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), N is W // BW.

% block_map(+Blocks, +Goal, -Blocks2): apply Goal to each block in Blocks.
% Goal is a 2-argument predicate Goal(BlockIn, BlockOut).
block_map(Blocks, Goal, Blocks2) :-
% Apply Goal to each block using maplist/3.
    maplist(Goal, Blocks, Blocks2).

% block_uniform(+Grid, +R0, +C0, -V): succeeds iff the BH-by-BW block starting
% at (R0,C0) is uniform (all cells equal to V).
% BH and BW are inferred from the grid context; this predicate checks a single
% top-left position for a 2x2 uniform block to keep the API simple.
% For explicit BH/BW use block_extract + block_is_solid.
block_uniform(Grid, R, C, V) :-
% A single cell is trivially uniform; this checks that R-C holds value V.
    nth0(R, Grid, Row), nth0(C, Row, V).

% block_mode_color(+Grid, +R0, +C0, -V): most frequent value in a 2x2 block.
block_mode_color(Grid, R0, C0, V) :-
% Collect the 2x2 block cells and find the most frequent value.
    R1 is R0 + 1, C1 is C0 + 1,
    findall(Cell, (
        between(R0, R1, R), nth0(R, Grid, Row), between(C0, C1, C), nth0(C, Row, Cell)
    ), Cells),
    block_mode_(Cells, V).
% Helper: sort unique values, count each, pick the max-count winner.
block_mode_(Cells, V) :-
    sort(Cells, Unique),
    findall(N-U, (member(U, Unique), include(=(U), Cells, Ms), length(Ms, N)), Pairs),
    findall(N, member(N-_, Pairs), Ns),
    max_list(Ns, MaxN),
    findall(U, member(MaxN-U, Pairs), Winners),
    sort(Winners, [V|_]).

% block_border_color(+Grid, +R0, +C0, -Bg): most frequent border cell value
% in the 3x3 block centered at (R0, C0), ignoring the center cell.
block_border_color(Grid, R0, C0, Bg) :-
% Collect all 8 border cells of the 3x3 neighborhood, skip center.
    R_min is R0 - 1, R_max is R0 + 1,
    C_min is C0 - 1, C_max is C0 + 1,
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(V, (
        between(R_min, R_max, R), R >= 0, R =< H1,
        between(C_min, C_max, C), C >= 0, C =< W1,
        \+ (R =:= R0, C =:= C0),
        nth0(R, Grid, Row), nth0(C, Row, V)
    ), BorderCells),
    block_mode_(BorderCells, Bg).

% block_is_solid(+Grid, +Color, -Bool): Bool = 1 iff every cell in Grid equals Color.
block_is_solid(Grid, Color, Bool) :-
% Use forall to check every cell; set Bool accordingly.
    (forall(member(Row, Grid), forall(member(V, Row), V =:= Color))
    -> Bool = 1 ; Bool = 0).

% block_is_border(+Grid, +R, +C, -Bool): Bool = 1 iff (R,C) is on the grid border.
block_is_border(Grid, R, C, Bool) :-
% A cell is on the border if it is in the first/last row or first/last column.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    (R =:= 0 ; R =:= H1 ; C =:= 0 ; C =:= W1)
    -> Bool = 1 ; Bool = 0.
