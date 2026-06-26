% edge.pl - Layer 128: Grid Edge Detection and Boundary Analysis (ed_* prefix).
% General-purpose predicates for finding boundaries between cells with
% different values in a 2D grid.
:- module(edge, [
    ed_h_edges/2, ed_v_edges/2,
    ed_h_edge/4, ed_v_edge/4,
    ed_all_edges/2, ed_boundary_cells/3,
    ed_outer_boundary/2, ed_inner_cells/3,
    ed_edge_count/2, ed_is_smooth/1,
    ed_label_edges/3, ed_has_edge/4,
    ed_corners/2, ed_corner_count/2
]).
% Import list utilities for grid traversal.
:- use_module(library(lists), [member/2, nth0/3]).

% ed_h_edges(+Grid, -Edges): collect all horizontal edges as R-C pairs.
% A horizontal edge exists between row R and row R+1 at column C if
% Grid[R][C] \= Grid[R+1][C].
ed_h_edges(Grid, Edges) :-
% Iterate over each adjacent row pair and each column.
    length(Grid, H), H2 is H - 2,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H2, R), R1 is R + 1,
        between(0, W1, C),
        nth0(R, Grid, RowA), nth0(C, RowA, VA),
        nth0(R1, Grid, RowB), nth0(C, RowB, VB),
        VA \= VB
    ), Edges).

% ed_v_edges(+Grid, -Edges): collect all vertical edges as R-C pairs.
% A vertical edge exists between column C and column C+1 at row R if
% Grid[R][C] \= Grid[R][C+1].
ed_v_edges(Grid, Edges) :-
% Iterate over each row and each adjacent column pair.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W2 is W - 2,
    findall(R-C, (
        between(0, H1, R),
        between(0, W2, C), C1 is C + 1,
        nth0(R, Grid, Row),
        nth0(C, Row, VA), nth0(C1, Row, VB),
        VA \= VB
    ), Edges).

% ed_h_edge(+Grid, +R, +C, -Bool): Bool=1 iff there is a horizontal edge
% between (R, C) and (R+1, C).
ed_h_edge(Grid, R, C, Bool) :-
% Fetch both cells and compare; return 1 or 0.
    R1 is R + 1,
    nth0(R, Grid, RowA), nth0(C, RowA, VA),
    nth0(R1, Grid, RowB), nth0(C, RowB, VB),
    (VA \= VB -> Bool = 1 ; Bool = 0).

% ed_v_edge(+Grid, +R, +C, -Bool): Bool=1 iff there is a vertical edge
% between (R, C) and (R, C+1).
ed_v_edge(Grid, R, C, Bool) :-
% Fetch both cells and compare; return 1 or 0.
    C1 is C + 1,
    nth0(R, Grid, Row),
    nth0(C, Row, VA), nth0(C1, Row, VB),
    (VA \= VB -> Bool = 1 ; Bool = 0).

% ed_all_edges(+Grid, -Edges): collect all edges (horizontal and vertical)
% as dir(h/v)-R-C terms, sorted.
ed_all_edges(Grid, Edges) :-
% Combine horizontal and vertical edge lists.
    ed_h_edges(Grid, HEdges),
    ed_v_edges(Grid, VEdges),
    findall(h-R-C, member(R-C, HEdges), HTerms),
    findall(v-R-C, member(R-C, VEdges), VTerms),
    append(HTerms, VTerms, All),
    sort(All, Edges).

% ed_boundary_cells(+Grid, +Val, -Cells): cells of value Val that have at
% least one neighbor with a different value. Returns R-C pairs sorted.
ed_boundary_cells(Grid, Val, Cells) :-
% A cell is a boundary cell if it equals Val and has at least one
% adjacent cell (4-connected) that differs from Val.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        (   (R > 0,  R2 is R-1, nth0(R2, Grid, Row2), nth0(C, Row2, V2), V2 \= Val)
        ;   (R < H1, R2 is R+1, nth0(R2, Grid, Row2), nth0(C, Row2, V2), V2 \= Val)
        ;   (C > 0,  C0 is C-1, nth0(C0, Row, V2), V2 \= Val)
        ;   (C < W1, C1 is C+1, nth0(C1, Row, V2), V2 \= Val)
        )
    ), Unsorted),
    sort(Unsorted, Cells).

% ed_outer_boundary(+Grid, -Cells): all outer-border cells (on the grid edge).
% Returns R-C pairs sorted.
ed_outer_boundary(Grid, Cells) :-
% A cell is on the outer boundary if it is in row 0, last row,
% column 0, or last column.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        (R =:= 0 ; R =:= H1 ; C =:= 0 ; C =:= W1)
    ), Unsorted),
    sort(Unsorted, Cells).

% ed_inner_cells(+Grid, +Val, -Cells): cells of value Val that have NO
% neighbor with a different value (strictly interior to a uniform region).
ed_inner_cells(Grid, Val, Cells) :-
% An interior cell has Val and all 4-connected neighbors also have Val
% (or it is on the grid border - handled by excluding boundary cells).
    ed_boundary_cells(Grid, Val, Boundary),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        \+ member(R-C, Boundary)
    ), Unsorted),
    sort(Unsorted, Cells).

% ed_edge_count(+Grid, -N): total number of edges (horizontal + vertical).
ed_edge_count(Grid, N) :-
% Count edges by collecting both lists and computing total length.
    ed_h_edges(Grid, HEdges),
    ed_v_edges(Grid, VEdges),
    length(HEdges, NH), length(VEdges, NV),
    N is NH + NV.

% ed_is_smooth(+Grid): succeeds iff Grid has no edges (every cell is the same value).
ed_is_smooth(Grid) :-
% A grid is smooth (uniform) if it has zero edges.
    ed_edge_count(Grid, 0).

% ed_label_edges(+Grid, +Bg, -Grid2): replace each cell with 1 if it is a
% boundary cell (at least one 4-neighbor differs) and Bg otherwise.
% Produces a 1/0 edge-label grid.
ed_label_edges(Grid, Bg, Grid2) :-
% For each cell, check if any adjacent cell has a different value.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row2, (
        between(0, H1, R),
        findall(Label, (
            between(0, W1, C),
            nth0(R, Grid, Row), nth0(C, Row, V),
            (ed_has_diff_nbr_(Grid, R, C, V, H1, W1) -> Label = 1 ; Label = Bg)
        ), Row2)
    ), Grid2).
% Helper: succeeds iff cell (R,C) with value V has at least one 4-neighbor with a different value.
ed_has_diff_nbr_(Grid, R, C, V, H1, W1) :-
    (   (R > 0,  R2 is R-1, nth0(R2, Grid, Row2), nth0(C, Row2, V2), V2 \= V) -> true
    ;   (R < H1, R2 is R+1, nth0(R2, Grid, Row2), nth0(C, Row2, V2), V2 \= V) -> true
    ;   (C > 0,  C1 is C-1, nth0(R, Grid, Row), nth0(C1, Row, V2), V2 \= V)  -> true
    ;   (C < W1, C1 is C+1, nth0(R, Grid, Row), nth0(C1, Row, V2), V2 \= V)
    ).

% ed_has_edge(+Grid, +R, +C, -Bool): Bool=1 iff cell (R,C) is a boundary
% cell (has at least one 4-neighbor with a different value).
ed_has_edge(Grid, R, C, Bool) :-
% Use the helper with the same diff-neighbor check.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    nth0(R, Grid, Row), nth0(C, Row, V),
    (ed_has_diff_nbr_(Grid, R, C, V, H1, W1) -> Bool = 1 ; Bool = 0).

% ed_corners(+Grid, -Corners): positions where both a horizontal and a
% vertical edge meet. Returns R-C pairs.
% A corner is a cell position (R,C) (0-indexed, referring to the top-left cell
% of a 2x2 block) where Grid[R][C], Grid[R][C+1], Grid[R+1][C], Grid[R+1][C+1]
% are not all the same value.
ed_corners(Grid, Corners) :-
% Collect 2x2 positions where not all four cells are equal.
    length(Grid, H), H2 is H - 2,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W2 is W - 2,
    findall(R-C, (
        between(0, H2, R), R1 is R + 1,
        between(0, W2, C), C1 is C + 1,
        nth0(R,  Grid, RowA), nth0(C,  RowA, V00), nth0(C1, RowA, V01),
        nth0(R1, Grid, RowB), nth0(C,  RowB, V10), nth0(C1, RowB, V11),
        \+ (V00 == V01, V01 == V10, V10 == V11)
    ), Unsorted),
    sort(Unsorted, Corners).

% ed_corner_count(+Grid, -N): number of corner positions in Grid.
ed_corner_count(Grid, N) :-
% Count corner positions from ed_corners.
    ed_corners(Grid, Corners),
    length(Corners, N).
