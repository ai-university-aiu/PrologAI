% distance.pl - Layer 129: Cell Distance and Proximity Computation (dt_* prefix).
% General-purpose predicates for computing distances between grid cells,
% distance transforms, and proximity queries.
:- module(distance, [
    distance_manhattan/5, distance_chebyshev/5,
    distance_euclidean_sq/5, distance_nearest/4,
    distance_farthest/4, distance_all_at/5,
    distance_within_manhattan/5, distance_within_chebyshev/5,
    distance_map_manhattan/3, distance_map_chebyshev/3,
    distance_ring_manhattan/5, distance_centroid/3,
    distance_diameter_manhattan/3, distance_diameter_chebyshev/3
]).
% Import list utilities for grid traversal and aggregation.
:- use_module(library(lists), [member/2, nth0/3, min_list/2, max_list/2]).
:- use_module(library(apply), [maplist/3]).

% distance_manhattan(+R1, +C1, +R2, +C2, -D): Manhattan (L1) distance between
% two grid positions (R1,C1) and (R2,C2).
distance_manhattan(R1, C1, R2, C2, D) :-
% D = |R2 - R1| + |C2 - C1|.
    DR is abs(R2 - R1), DC is abs(C2 - C1), D is DR + DC.

% distance_chebyshev(+R1, +C1, +R2, +C2, -D): Chebyshev (L-inf, 8-connected)
% distance between two grid positions.
distance_chebyshev(R1, C1, R2, C2, D) :-
% D = max(|R2 - R1|, |C2 - C1|).
    DR is abs(R2 - R1), DC is abs(C2 - C1), D is max(DR, DC).

% distance_euclidean_sq(+R1, +C1, +R2, +C2, -DSq): squared Euclidean distance
% between two grid positions. Returns an integer; avoids floating point.
distance_euclidean_sq(R1, C1, R2, C2, DSq) :-
% DSq = (R2-R1)^2 + (C2-C1)^2.
    DR is R2 - R1, DC is C2 - C1, DSq is DR * DR + DC * DC.

% distance_nearest(+Grid, +Val, +R0-C0, -R-C): find the nearest cell (by
% Manhattan distance) in Grid that has value Val to the query position
% (R0,C0). On ties, the first in row-major order wins.
distance_nearest(Grid, Val, R0-C0, R-C) :-
% Collect all cells with value Val, compute distances, find minimum.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(D-R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        nth0(R2, Grid, Row2), nth0(C2, Row2, Val),
        distance_manhattan(R0, C0, R2, C2, D)
    ), Pairs),
    Pairs \= [],
    min_list_key_(Pairs, _-R-C).

% distance_farthest(+Grid, +Val, +R0-C0, -R-C): find the farthest cell (by
% Manhattan distance) in Grid that has value Val from the query position.
distance_farthest(Grid, Val, R0-C0, R-C) :-
% Collect all cells with value Val, compute distances, find maximum.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(D-R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        nth0(R2, Grid, Row2), nth0(C2, Row2, Val),
        distance_manhattan(R0, C0, R2, C2, D)
    ), Pairs),
    Pairs \= [],
    max_list_key_(Pairs, _-R-C).

% distance_all_at(+Grid, +Val, +R0-C0, +D, -Cells): find all cells of value Val
% at exactly Manhattan distance D from (R0,C0). Returns R-C pairs sorted.
distance_all_at(Grid, Val, R0-C0, D, Cells) :-
% Filter cells of Val whose Manhattan distance equals exactly D.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        nth0(R2, Grid, Row2), nth0(C2, Row2, Val),
        distance_manhattan(R0, C0, R2, C2, D)
    ), Unsorted),
    sort(Unsorted, Cells).

% distance_within_manhattan(+Grid, +R0, +C0, +D, -Cells): all grid positions
% within Manhattan distance D of (R0,C0). Returns R-C pairs sorted.
distance_within_manhattan(Grid, R0, C0, D, Cells) :-
% Collect all in-bounds positions with Manhattan distance <= D.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        distance_manhattan(R0, C0, R2, C2, Dist),
        Dist =< D
    ), Unsorted),
    sort(Unsorted, Cells).

% distance_within_chebyshev(+Grid, +R0, +C0, +D, -Cells): all grid positions
% within Chebyshev distance D of (R0,C0). Returns R-C pairs sorted.
distance_within_chebyshev(Grid, R0, C0, D, Cells) :-
% Collect all in-bounds positions with Chebyshev distance <= D.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        distance_chebyshev(R0, C0, R2, C2, Dist),
        Dist =< D
    ), Unsorted),
    sort(Unsorted, Cells).

% distance_map_manhattan(+Grid, +Val, -MapGrid): produce a same-size grid where
% each cell holds the Manhattan distance to the nearest cell with value Val.
% Cells that already have value Val get distance 0.
distance_map_manhattan(Grid, Val, MapGrid) :-
% For each cell compute the minimum Manhattan distance to any Val-cell.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(ValR-ValC, (
        between(0, H1, ValR), between(0, W1, ValC),
        nth0(ValR, Grid, VRow), nth0(ValC, VRow, Val)
    ), ValCells),
    findall(RowD, (
        between(0, H1, R),
        findall(DMin, (
            between(0, W1, C),
            findall(D, (member(ValR-ValC, ValCells),
                        distance_manhattan(R, C, ValR, ValC, D)), Ds),
            (Ds = [] -> DMin = -1 ; min_list(Ds, DMin))
        ), RowD)
    ), MapGrid).

% distance_map_chebyshev(+Grid, +Val, -MapGrid): same-size grid where each cell
% holds the Chebyshev distance to the nearest cell with value Val.
distance_map_chebyshev(Grid, Val, MapGrid) :-
% For each cell compute the minimum Chebyshev distance to any Val-cell.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(ValR-ValC, (
        between(0, H1, ValR), between(0, W1, ValC),
        nth0(ValR, Grid, VRow), nth0(ValC, VRow, Val)
    ), ValCells),
    findall(RowD, (
        between(0, H1, R),
        findall(DMin, (
            between(0, W1, C),
            findall(D, (member(ValR-ValC, ValCells),
                        distance_chebyshev(R, C, ValR, ValC, D)), Ds),
            (Ds = [] -> DMin = -1 ; min_list(Ds, DMin))
        ), RowD)
    ), MapGrid).

% distance_ring_manhattan(+Grid, +R0, +C0, +D, -Cells): all in-bounds positions
% at exactly Manhattan distance D from (R0,C0). Returns R-C pairs sorted.
distance_ring_manhattan(Grid, R0, C0, D, Cells) :-
% Collect in-bounds positions with Manhattan distance exactly D.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        distance_manhattan(R0, C0, R2, C2, D)
    ), Unsorted),
    sort(Unsorted, Cells).

% distance_centroid(+Grid, +Val, -R-C): integer centroid (center of mass) of all
% cells with value Val in Grid. Fails if no such cells exist.
distance_centroid(Grid, Val, RC) :-
% Collect all cell positions of Val; compute mean row and column.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R2-C2, (
        between(0, H1, R2), between(0, W1, C2),
        nth0(R2, Grid, Row2), nth0(C2, Row2, Val)
    ), Cells),
    Cells \= [],
    findall(R2, member(R2-_, Cells), Rs),
    findall(C2, member(_-C2, Cells), Cs),
    length(Cells, N),
    sumlist_(Rs, SR), sumlist_(Cs, SC),
    CR is SR // N, CC is SC // N,
    RC = CR-CC.

% distance_diameter_manhattan(+Cells, -D1-D2, -Diam): given a list of R-C pairs,
% compute the diameter under Manhattan distance (the maximum pairwise distance)
% and return the two farthest cells D1 and D2.
distance_diameter_manhattan(Cells, D1-D2, Diam) :-
% Enumerate all ordered pairs; collect max distance.
    findall(Dist-A-B, (
        member(A, Cells), member(B, Cells), A @< B,
        A = RA-CA, B = RB-CB,
        distance_manhattan(RA, CA, RB, CB, Dist)
    ), Triples),
    Triples \= [],
    max_list_key_(Triples, Diam-D1-D2).

% distance_diameter_chebyshev(+Cells, -D1-D2, -Diam): diameter under Chebyshev
% distance for a list of R-C pairs.
distance_diameter_chebyshev(Cells, D1-D2, Diam) :-
% Enumerate all ordered pairs; collect max Chebyshev distance.
    findall(Dist-A-B, (
        member(A, Cells), member(B, Cells), A @< B,
        A = RA-CA, B = RB-CB,
        distance_chebyshev(RA, CA, RB, CB, Dist)
    ), Triples),
    Triples \= [],
    max_list_key_(Triples, Diam-D1-D2).

% Private helper: find the element with the minimum key in a D-... list.
min_list_key_([H|T], Min) :- min_list_key_acc_(T, H, Min).
min_list_key_acc_([], Min, Min).
min_list_key_acc_([H|T], Best, Min) :-
    (H @< Best -> Next = H ; Next = Best),
    min_list_key_acc_(T, Next, Min).

% Private helper: find the element with the maximum key in a D-... list.
max_list_key_([H|T], Max) :- max_list_key_acc_(T, H, Max).
max_list_key_acc_([], Max, Max).
max_list_key_acc_([H|T], Best, Max) :-
    (H @> Best -> Next = H ; Next = Best),
    max_list_key_acc_(T, Next, Max).

% Private helper: sum a list of integers with accumulator.
sumlist_([], 0).
sumlist_([H|T], S) :- sumlist_(T, S1), S is S1 + H.
