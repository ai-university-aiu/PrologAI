% cluster.pl - Layer 102: Spatial Proximity and Grouping Operations (cl_* prefix).
% Provides distance metrics, proximity filtering, centroid and spread computation,
% color-based grouping, sorted proximity ordering, and closest/farthest pair detection
% for sets of R-C cells in 2D integer-coordinate grids.
:- module(cluster, [
    cluster_chebyshev/5,
    cluster_manhattan/5,
    cluster_euclidean_sq/5,
    cluster_within/5,
    cluster_nearest/4,
    cluster_farthest/4,
    cluster_center/3,
    cluster_diameter/2,
    cluster_spread/3,
    cluster_group_by_color/4,
    cluster_sort_by_dist/4,
    cluster_nearest_pair/3,
    cluster_farthest_pair/3,
    cluster_cells_in_band/6
]).
% Import list utilities for aggregation, lookup, and pair manipulation.
:- use_module(library(lists), [nth0/3, member/2, max_list/2, min_list/2, sum_list/2, append/2, append/3]).
% Import higher-order utilities for mapping and filtering.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% cluster_chebyshev(+R1, +C1, +R2, +C2, -D): Chebyshev (L-inf) distance between two cells.
% D = max(|R2 - R1|, |C2 - C1|). This is the number of king moves between the cells.
cluster_chebyshev(R1, C1, R2, C2, D) :-
% Absolute row difference.
    DR is abs(R2 - R1),
% Absolute column difference.
    DC is abs(C2 - C1),
% Chebyshev distance is the larger of the two.
    D is max(DR, DC).

% cluster_manhattan(+R1, +C1, +R2, +C2, -D): Manhattan (L-1) distance between two cells.
% D = |R2 - R1| + |C2 - C1|. This is the minimum number of 4-connected steps.
cluster_manhattan(R1, C1, R2, C2, D) :-
% Sum of absolute differences.
    D is abs(R2 - R1) + abs(C2 - C1).

% cluster_euclidean_sq(+R1, +C1, +R2, +C2, -DSq): squared Euclidean distance.
% DSq = (R2-R1)^2 + (C2-C1)^2. Integer arithmetic; no square root needed for comparisons.
cluster_euclidean_sq(R1, C1, R2, C2, DSq) :-
% Sum of squared differences.
    DSq is (R2 - R1) * (R2 - R1) + (C2 - C1) * (C2 - C1).

% cluster_within(+R, +C, +D, +Cells, -Near): cells from Cells within Chebyshev D of (R,C).
% Near is the sublist of Cells whose Chebyshev distance to (R,C) is at most D.
cluster_within(R, C, D, Cells, Near) :-
% Keep each cell whose Chebyshev distance is within the radius.
    include([Cell]>>(Cell = CR-CC, Dist is max(abs(CR-R), abs(CC-C)), Dist =< D), Cells, Near).

% cluster_nearest_helper_: fold helper for finding the nearest cell. If-then-else for determinism.
cluster_nearest_helper_(_, _, [], _, BestCell, BestCell) :- !.
cluster_nearest_helper_(R, C, [Cell|Rest], BestD, BestCell, Result) :-
    Cell = CR-CC,
% Chebyshev distance from query point to this cell.
    D is max(abs(CR - R), abs(CC - C)),
    (D < BestD ->
% This cell is closer; update best.
        cluster_nearest_helper_(R, C, Rest, D, Cell, Result)
    ;
% Keep current best.
        cluster_nearest_helper_(R, C, Rest, BestD, BestCell, Result)
    ).

% cluster_nearest(+R, +C, +Cells, -Nearest): cell in Cells closest to (R,C) by Chebyshev.
% Cells must be non-empty. Ties resolved by first occurrence in Cells.
cluster_nearest(R, C, [First|Rest], Nearest) :-
% Initialize with the first cell.
    First = FR-FC,
    D0 is max(abs(FR - R), abs(FC - C)),
    cluster_nearest_helper_(R, C, Rest, D0, First, Nearest).

% cluster_farthest_helper_: fold helper for finding the farthest cell.
cluster_farthest_helper_(_, _, [], _, BestCell, BestCell) :- !.
cluster_farthest_helper_(R, C, [Cell|Rest], BestD, BestCell, Result) :-
    Cell = CR-CC,
    D is max(abs(CR - R), abs(CC - C)),
    (D > BestD ->
        cluster_farthest_helper_(R, C, Rest, D, Cell, Result)
    ;
        cluster_farthest_helper_(R, C, Rest, BestD, BestCell, Result)
    ).

% cluster_farthest(+R, +C, +Cells, -Farthest): cell in Cells most distant from (R,C).
% Cells must be non-empty. Ties resolved by first occurrence.
cluster_farthest(R, C, [First|Rest], Farthest) :-
    First = FR-FC,
    D0 is max(abs(FR - R), abs(FC - C)),
    cluster_farthest_helper_(R, C, Rest, D0, First, Farthest).

% cluster_center(+Cells, -CR, -CC): integer centroid of a non-empty cell set.
% CR = round(mean row), CC = round(mean column).
cluster_center(Cells, CR, CC) :-
% Extract row indices.
    maplist([Cell, R]>>(Cell = R-_), Cells, Rows),
% Extract column indices.
    maplist([Cell, C]>>(Cell = _-C), Cells, Cols),
% Sum rows and columns.
    sum_list(Rows, SumR), sum_list(Cols, SumC),
% Count cells.
    length(Cells, N),
% Round the averages to the nearest integer.
    CR is round(SumR / N),
    CC is round(SumC / N).

% cluster_all_pairs_: generate all unordered pairs from a list. Cut on base cases.
cluster_all_pairs_([], []) :- !.
cluster_all_pairs_([_], []) :- !.
cluster_all_pairs_([H|T], Pairs) :-
% Pair H with each element of T.
    maplist([X, P]>>(P = H-X), T, HPs),
% Recurse for remaining pairs.
    cluster_all_pairs_(T, RestPs),
    append(HPs, RestPs, Pairs).

% cluster_diameter(+Cells, -D): maximum pairwise Chebyshev distance within a cell set.
% For a single cell, D = 0.
cluster_diameter([_], 0) :- !.
cluster_diameter(Cells, D) :-
% Generate all unordered pairs.
    cluster_all_pairs_(Cells, Pairs),
% Compute Chebyshev distance for each pair.
    maplist([Pair, Dist]>>(Pair = (PR1-PC1)-(PR2-PC2), Dist is max(abs(PR2-PR1), abs(PC2-PC1))), Pairs, Dists),
% Maximum distance is the diameter.
    max_list(Dists, D).

% cluster_spread(+Cells, -DR, -DC): bounding box dimensions of a non-empty cell set.
% DR = max_row - min_row; DC = max_col - min_col.
cluster_spread(Cells, DR, DC) :-
% Extract row and column indices.
    maplist([Cell, R]>>(Cell = R-_), Cells, Rows),
    maplist([Cell, C]>>(Cell = _-C), Cells, Cols),
% Compute extents.
    min_list(Rows, MinR), max_list(Rows, MaxR),
    min_list(Cols, MinC), max_list(Cols, MaxC),
    DR is MaxR - MinR,
    DC is MaxC - MinC.

% cluster_group_by_color(+Grid, +Cells, -Colors, -Groups): group R-C cells by their value in Grid.
% Colors is a sorted list of distinct values; Groups[i] is the sublist of Cells with Colors[i].
cluster_group_by_color(Grid, Cells, Colors, Groups) :-
% Get the grid color for each cell.
    maplist([Cell, Color]>>(Cell = CR-CC, nth0(CR, Grid, Row), nth0(CC, Row, Color)), Cells, CellColors),
% Distinct colors in sorted order.
    sort(CellColors, Colors),
% For each color, collect matching cells.
    maplist([Clr, Grp]>>(
        include([Cell]>>(Cell = CR2-CC2, nth0(CR2, Grid, Row2), nth0(CC2, Row2, Clr)), Cells, Grp)
    ), Colors, Groups).

% cluster_sort_by_dist(+R, +C, +Cells, -Sorted): sort Cells by Chebyshev distance to (R,C).
% Ties preserve the original relative order (keysort is stable).
cluster_sort_by_dist(R, C, Cells, Sorted) :-
% Pair each cell with its Chebyshev distance.
    maplist([Cell, Dist-Cell]>>(Cell = CR-CC, Dist is max(abs(CR-R), abs(CC-C))), Cells, Pairs),
% Sort by distance key (stable).
    keysort(Pairs, SortedPairs),
% Extract cells from sorted pairs.
    maplist([Pair, Cell]>>(Pair = _-Cell), SortedPairs, Sorted).

% cluster_min_pair_: fold helper for nearest pair (minimum Chebyshev).
cluster_min_pair_([], _, Best, Best) :- !.
cluster_min_pair_([H|T], BestD, Best0, Result) :-
    H = (PR1-PC1)-(PR2-PC2),
    D is max(abs(PR2-PR1), abs(PC2-PC1)),
    (D < BestD ->
        cluster_min_pair_(T, D, H, Result)
    ;
        cluster_min_pair_(T, BestD, Best0, Result)
    ).

% cluster_nearest_pair(+Cells, -Cell1, -Cell2): pair of cells with minimum Chebyshev distance.
% Cells must have at least 2 elements. Ties resolved by first occurrence.
cluster_nearest_pair(Cells, Cell1, Cell2) :-
% Generate all unordered pairs.
    cluster_all_pairs_(Cells, [First|RestPairs]),
% Initialize with the first pair's distance.
    First = (PR1-PC1)-(PR2-PC2),
    D0 is max(abs(PR2-PR1), abs(PC2-PC1)),
% Find the pair with minimum distance.
    cluster_min_pair_(RestPairs, D0, First, BestPair),
    BestPair = Cell1-Cell2.

% cluster_max_pair_: fold helper for farthest pair (maximum Chebyshev).
cluster_max_pair_([], _, Best, Best) :- !.
cluster_max_pair_([H|T], BestD, Best0, Result) :-
    H = (PR1-PC1)-(PR2-PC2),
    D is max(abs(PR2-PR1), abs(PC2-PC1)),
    (D > BestD ->
        cluster_max_pair_(T, D, H, Result)
    ;
        cluster_max_pair_(T, BestD, Best0, Result)
    ).

% cluster_farthest_pair(+Cells, -Cell1, -Cell2): pair of cells with maximum Chebyshev distance.
% Cells must have at least 2 elements. Ties resolved by first occurrence.
cluster_farthest_pair(Cells, Cell1, Cell2) :-
    cluster_all_pairs_(Cells, [First|RestPairs]),
    First = (PR1-PC1)-(PR2-PC2),
    D0 is max(abs(PR2-PR1), abs(PC2-PC1)),
    cluster_max_pair_(RestPairs, D0, First, BestPair),
    BestPair = Cell1-Cell2.

% cluster_cells_in_band(+R1, +R2, +C1, +C2, +Cells, -Band): filter Cells to those
% whose row is in [R1,R2] and column is in [C1,C2]. Inclusive on all sides.
cluster_cells_in_band(R1, R2, C1, C2, Cells, Band) :-
    include([Cell]>>(Cell = CR-CC, R1 =< CR, CR =< R2, C1 =< CC, CC =< C2), Cells, Band).
