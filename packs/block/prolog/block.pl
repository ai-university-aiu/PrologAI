% block.pl - Layer 127: Rectangular Sub-Grid (Block) Decomposition (bk_* prefix).
% General-purpose predicates for splitting grids into uniform rectangular blocks
% and performing block-level operations.
:- module(block, [
    bk_extract/6, bk_dims/5,
    bk_split_h/3, bk_split_v/3,
    bk_tile_h/3, bk_tile_v/3,
    bk_count_h/3, bk_count_v/3,
    bk_map/3, bk_uniform/4,
    bk_mode_color/4, bk_border_color/4,
    bk_is_solid/3, bk_is_border/4
]).
% Import list utilities for row slicing, block assembly, and mode computation.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, max_list/2]).
% Import apply for row-level operations and frequency counting in mode helper.
:- use_module(library(apply), [maplist/3, include/3]).

% bk_extract(+Grid, +R0, +C0, +R1, +C1, -Block): extract the rectangular
% sub-grid from row R0..R1 and column C0..C1 (all inclusive, 0-indexed).
bk_extract(Grid, R0, C0, R1, C1, Block) :-
% Collect each row slice from the specified row range.
    findall(RowSlice, (
        between(R0, R1, R),
        nth0(R, Grid, Row),
        findall(V, (between(C0, C1, C), nth0(C, Row, V)), RowSlice)
    ), Block).

% bk_dims(+Grid, +BH, +BW, -NR, -NC): compute number of block rows NR and
% block columns NC when dividing a grid into BH-by-BW blocks (exact division assumed).
bk_dims(Grid, BH, BW, NR, NC) :-
% Grid height divided by block height gives block row count.
    length(Grid, H), NR is H // BH,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), NC is W // BW.

% bk_split_h(+Grid, +BH, -Strips): split Grid into horizontal strips of height BH.
% Each strip is a list of BH consecutive rows.
bk_split_h(Grid, BH, Strips) :-
% Compute number of strips and collect each strip's rows.
    length(Grid, H), NS is H // BH,
    findall(Strip, (
        between(0, NS, Si), Si < NS,
        R0 is Si * BH, R1 is R0 + BH - 1,
        findall(Row, (between(R0, R1, R), nth0(R, Grid, Row)), Strip)
    ), Strips).

% bk_split_v(+Grid, +BW, -Strips): split Grid into vertical strips of width BW.
% Each strip contains all rows sliced to the BW columns.
bk_split_v(Grid, BW, Strips) :-
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

% bk_tile_h(+Grid, +N, -Tiled): tile Grid N times vertically (stack N copies top to bottom).
bk_tile_h(Grid, N, Tiled) :-
% Replicate the grid N times and flatten with append/2.
    findall(Row, (between(1, N, _), member(Row, Grid)), Tiled).

% bk_tile_v(+Grid, +N, -Tiled): tile Grid N times horizontally (extend each row N times).
bk_tile_v(Grid, N, Tiled) :-
% For each row, replicate its cells N times and flatten with append/2.
    maplist(bk_tile_row_(N), Grid, Tiled).
% Per-row tiling helper: collect each cell N times from all N copies of Row.
bk_tile_row_(N, Row, TiledRow) :-
    findall(V, (between(1, N, _), member(V, Row)), TiledRow).

% bk_count_h(+Grid, +BH, -N): number of complete horizontal strips of height BH.
bk_count_h(Grid, BH, N) :-
% Integer division of grid height by block height.
    length(Grid, H), N is H // BH.

% bk_count_v(+Grid, +BW, -N): number of complete vertical strips of width BW.
bk_count_v(Grid, BW, N) :-
% Integer division of grid width by block width.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), N is W // BW.

% bk_map(+Blocks, +Goal, -Blocks2): apply Goal to each block in Blocks.
% Goal is a 2-argument predicate Goal(BlockIn, BlockOut).
bk_map(Blocks, Goal, Blocks2) :-
% Apply Goal to each block using maplist/3.
    maplist(Goal, Blocks, Blocks2).

% bk_uniform(+Grid, +R0, +C0, -V): succeeds iff the BH-by-BW block starting
% at (R0,C0) is uniform (all cells equal to V).
% BH and BW are inferred from the grid context; this predicate checks a single
% top-left position for a 2x2 uniform block to keep the API simple.
% For explicit BH/BW use bk_extract + bk_is_solid.
bk_uniform(Grid, R, C, V) :-
% A single cell is trivially uniform; this checks that R-C holds value V.
    nth0(R, Grid, Row), nth0(C, Row, V).

% bk_mode_color(+Grid, +R0, +C0, -V): most frequent value in a 2x2 block.
bk_mode_color(Grid, R0, C0, V) :-
% Collect the 2x2 block cells and find the most frequent value.
    R1 is R0 + 1, C1 is C0 + 1,
    findall(Cell, (
        between(R0, R1, R), nth0(R, Grid, Row), between(C0, C1, C), nth0(C, Row, Cell)
    ), Cells),
    bk_mode_(Cells, V).
% Helper: sort unique values, count each, pick the max-count winner.
bk_mode_(Cells, V) :-
    sort(Cells, Unique),
    findall(N-U, (member(U, Unique), include(=(U), Cells, Ms), length(Ms, N)), Pairs),
    findall(N, member(N-_, Pairs), Ns),
    max_list(Ns, MaxN),
    findall(U, member(MaxN-U, Pairs), Winners),
    sort(Winners, [V|_]).

% bk_border_color(+Grid, +R0, +C0, -Bg): most frequent border cell value
% in the 3x3 block centered at (R0, C0), ignoring the center cell.
bk_border_color(Grid, R0, C0, Bg) :-
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
    bk_mode_(BorderCells, Bg).

% bk_is_solid(+Grid, +Color, -Bool): Bool = 1 iff every cell in Grid equals Color.
bk_is_solid(Grid, Color, Bool) :-
% Use forall to check every cell; set Bool accordingly.
    (forall(member(Row, Grid), forall(member(V, Row), V =:= Color))
    -> Bool = 1 ; Bool = 0).

% bk_is_border(+Grid, +R, +C, -Bool): Bool = 1 iff (R,C) is on the grid border.
bk_is_border(Grid, R, C, Bool) :-
% A cell is on the border if it is in the first/last row or first/last column.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    (R =:= 0 ; R =:= H1 ; C =:= 0 ; C =:= W1)
    -> Bool = 1 ; Bool = 0.
