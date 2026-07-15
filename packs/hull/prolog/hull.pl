% hull.pl - Layer 107: Convex Hull and Polygon Geometry (hu_* prefix).
% Provides predicates for computing the convex hull of a cell set using
% Andrew's monotone chain algorithm, testing convexity and rectangularity,
% measuring hull area and perimeter, checking point-in-hull membership,
% filling hull regions, finding concavities, computing diameter and centroid,
% and testing whether one cell set is contained within the hull of another.
:- module(hull, [
    hull_convex_hull/2,
    hull_is_convex/1,
    hull_hull_size/2,
    hull_hull_area2/2,
    hull_in_hull/3,
    hull_cells_in_hull/3,
    hull_fill_hull/4,
    hull_concavities/4,
    hull_diameter/4,
    hull_aspect/3,
    hull_is_rect/1,
    hull_hull_perim2/2,
    hull_centroid/3,
    hull_hull_contains/2
]).
% Import list utilities needed by the hull predicates.
:- use_module(library(lists), [member/2, nth0/3, append/3, reverse/2,
                                min_list/2, max_list/2, last/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3]).

% hull_sort_xy_: sort cells by (C, R) - column then row - for monotone chain.
hull_sort_xy_(Cells, Sorted) :-
% Build keyed pairs using column-row as sort key.
    maplist([R-C, (C-R)-(R-C)]>>true, Cells, Keyed),
% Sort keys: primary on C (x), secondary on R (y).
    keysort(Keyed, KSorted),
% Strip keys to recover the R-C cell terms.
    maplist([_-RC, RC]>>true, KSorted, Sorted).

% hull_cross_: signed cross product of vectors (A-to-B) and (A-to-C) in R-C coords.
% In screen coordinates (R increases downward), positive Z is a counterclockwise
% turn and negative Z is a clockwise turn.
hull_cross_(R1-C1, R2-C2, R3-C3, Z) :-
    Z is (C2 - C1) * (R3 - R1) - (R2 - R1) * (C3 - C1).

% hull_trim_: remove points from the accumulator head while the last three
% points make a counterclockwise or collinear turn (Z >= 0).
% The accumulator stores points in reverse insertion order (head = most recent).
hull_trim_([B, A | Rest], P, Trimmed) :-
    hull_cross_(A, B, P, Z),
    Z >= 0, !,
    hull_trim_([A | Rest], P, Trimmed).
hull_trim_(Acc, _, Acc).

% hull_build_half_: build one half-hull from points in monotone order.
% Returns the half-hull in reverse (most recently added point at head).
hull_build_half_([], RevHull, RevHull).
hull_build_half_([P | Ps], Acc, RevHull) :-
% Trim clockwise-turn violations then prepend the new point.
    hull_trim_(Acc, P, TrimmedAcc),
    hull_build_half_(Ps, [P | TrimmedAcc], RevHull).

% hull_convex_hull(+Cells, -Hull): convex hull of Cells using Andrew's monotone
% chain. Hull is a list of vertex R-C cells in clockwise screen order (R down).
% Collinear points are excluded from the hull.
% Degenerate cases: empty list gives [], single cell gives [that cell].
hull_convex_hull([], []) :- !.
hull_convex_hull([C], [C]) :- !.
hull_convex_hull(Cells, Hull) :-
% Remove duplicates then sort by (C, R) for the monotone chain.
    sort(Cells, Unique),
    hull_sort_xy_(Unique, Sorted),
% Build the lower half-hull left-to-right; result is reversed.
    hull_build_half_(Sorted, [], LowerR),
% Build the upper half-hull right-to-left; result is reversed.
    reverse(Sorted, RSorted),
    hull_build_half_(RSorted, [], UpperR),
% Each result includes both shared endpoints; drop the head of each to avoid
% duplication in the combined hull.
    LowerR = [_ | LBody],
    UpperR = [_ | UBody],
    reverse(LBody, Lower),
    reverse(UBody, Upper),
% Concatenate to form the complete ordered hull.
    append(Lower, Upper, Hull).

% hull_bbox_: compute the bounding box of a non-empty cell list.
hull_bbox_(Cells, MinR, MinC, MaxR, MaxC) :-
    maplist([R-_, R]>>true, Cells, Rs),
    maplist([_-C, C]>>true, Cells, Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% hull_is_convex(+Cells): succeed if Cells is a convex discrete shape.
% A cell set is convex if it equals the set of all grid cells inside its
% convex hull (within the bounding box).
hull_is_convex(Cells) :-
    sort(Cells, CellSet),
    CellSet \= [],
    hull_bbox_(CellSet, MinR, MinC, MaxR, MaxC),
    hull_convex_hull(CellSet, Hull),
    findall(R-C, (
        between(MinR, MaxR, R),
        between(MinC, MaxC, C),
        hull_in_hull(R, C, Hull)
    ), InHullRaw),
    sort(InHullRaw, InHull),
    InHull = CellSet.

% hull_hull_size(+Cells, -N): number of vertices in the convex hull of Cells.
hull_hull_size(Cells, N) :-
    hull_convex_hull(Cells, Hull),
    length(Hull, N).

% hull_shoelace_: compute the signed twice-area of a closed polygon via the
% shoelace formula: sum of (C_i * R_{i+1} - C_{i+1} * R_i) over all edges.
hull_shoelace_(Hull, A2) :-
    Hull = [First | _],
    append(Hull, [First], Closed),
    hull_shoelace_sum_(Closed, 0, A2).

% hull_shoelace_sum_: accumulate shoelace terms over consecutive vertex pairs.
hull_shoelace_sum_([_], Acc, Acc) :- !.
hull_shoelace_sum_([R1-C1, R2-C2 | Rest], Acc, A2) :-
    Term is C1 * R2 - C2 * R1,
    Acc1 is Acc + Term,
    hull_shoelace_sum_([R2-C2 | Rest], Acc1, A2).

% hull_hull_area2(+Cells, -A2): twice the area of the convex hull (integer >= 0).
% Returns 0 for degenerate hulls with fewer than 3 vertices.
hull_hull_area2(Cells, A2) :-
    hull_convex_hull(Cells, Hull),
    length(Hull, N),
    (N < 3 ->
        A2 = 0
    ;
        hull_shoelace_(Hull, SA),
        A2 is abs(SA)
    ).

% hull_edge_test_: test if point P is on the inside (or boundary) of directed
% edge A-to-B in a clockwise hull. For CW hull, inside means Z =< 0.
hull_edge_test_(RA-CA, RB-CB, RP-CP) :-
    Z is (CB - CA) * (RP - RA) - (RB - RA) * (CP - CA),
    Z =< 0.

% hull_all_edges_: check all consecutive edges in a closed polygon list.
% Succeeds if point P passes the edge test for every edge.
hull_all_edges_([_], _) :- !.
hull_all_edges_([A, B | Rest], P) :-
    hull_edge_test_(A, B, P),
    hull_all_edges_([B | Rest], P).

% hull_in_hull(+R, +C, +Hull): succeed if (R,C) is inside or on the convex hull.
% Handles degenerate hulls with 0, 1, or 2 vertices separately.
hull_in_hull(_, _, []) :- !, fail.
hull_in_hull(R, C, [R1-C1]) :- !, R =:= R1, C =:= C1.
hull_in_hull(R, C, [R1-C1, R2-C2]) :- !,
% For a 2-vertex hull (line segment): point must be collinear and within range.
    Z is (C2 - C1) * (R - R1) - (R2 - R1) * (C - C1),
    Z =:= 0,
    R >= min(R1, R2), R =< max(R1, R2),
    C >= min(C1, C2), C =< max(C1, C2).
hull_in_hull(R, C, Hull) :-
% For a proper polygon (3+ vertices): all edge cross products must be =< 0.
    Hull = [First | _],
    append(Hull, [First], Closed),
    hull_all_edges_(Closed, R-C).

% hull_dims_: extract row count and column count from a grid.
hull_dims_(Grid, NR, NC) :-
    length(Grid, NR),
    (NR > 0 -> Grid = [FR | _], length(FR, NC) ; NC = 0).

% hull_cells_in_hull(+Grid, +Cells, -InHull): sorted list of all R-C cells in
% Grid that lie inside or on the convex hull of Cells.
hull_cells_in_hull(Grid, Cells, InHull) :-
    hull_convex_hull(Cells, Hull),
    hull_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        hull_in_hull(R, C, Hull)
    ), Raw),
    sort(Raw, InHull).

% hull_set_cell_: replace the value at (R,C) in a grid.
hull_set_cell_(Grid, R, C, Val, NewGrid) :-
    nth0(R, Grid, OldRow, RestRows),
    nth0(C, OldRow, _, RestCols),
    nth0(C, NewRow, Val, RestCols),
    nth0(R, NewGrid, NewRow, RestRows).

% hull_set_cells_: apply a list of cell replacements to a grid.
hull_set_cells_(Grid, [], _, Grid) :- !.
hull_set_cells_(Grid0, [R-C | Rest], Val, Out) :-
    hull_set_cell_(Grid0, R, C, Val, Grid1),
    hull_set_cells_(Grid1, Rest, Val, Out).

% hull_fill_hull(+Grid, +Cells, +Color, -Out): paint all cells inside the convex
% hull of Cells with Color. Cells outside the hull are unchanged.
hull_fill_hull(Grid, Cells, Color, Out) :-
    hull_cells_in_hull(Grid, Cells, InHull),
    hull_set_cells_(Grid, InHull, Color, Out).

% hull_concavities(+Grid, +Cells, +Bg, -Missing): sorted list of Bg-valued grid
% cells that lie inside the convex hull of Cells but are absent from Cells.
% These represent the concavities (dents) in the shape.
hull_concavities(Grid, Cells, Bg, Missing) :-
    hull_convex_hull(Cells, Hull),
    hull_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    sort(Cells, CellSet),
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Bg,
        hull_in_hull(R, C, Hull),
        \+ member(R-C, CellSet)
    ), Raw),
    sort(Raw, Missing).

% hull_dist2_: squared Euclidean distance between two R-C cells.
hull_dist2_(R1-C1, R2-C2, D2) :-
    D2 is (R2 - R1) * (R2 - R1) + (C2 - C1) * (C2 - C1).

% hull_diameter(+Cells, -P1, -P2, -D2): the pair of cells with maximum squared
% Euclidean distance. P1 and P2 are the two farthest cells; D2 is their
% squared distance. Fails if Cells has fewer than two elements.
hull_diameter(Cells, P1, P2, D2) :-
    findall(D-A-B, (
        nth0(I, Cells, A),
        nth0(J, Cells, B),
        I < J,
        hull_dist2_(A, B, D)
    ), Pairs),
    Pairs = [_ | _],
    msort(Pairs, Sorted),
    last(Sorted, D2-P1-P2).

% hull_aspect(+Cells, -H, -W): height (row-span) and width (col-span) of the
% convex hull bounding box. H = MaxR - MinR, W = MaxC - MinC.
hull_aspect(Cells, H, W) :-
    hull_convex_hull(Cells, Hull),
    (Hull = [] ->
        H = 0, W = 0
    ;
        hull_bbox_(Hull, MinR, MinC, MaxR, MaxC),
        H is MaxR - MinR,
        W is MaxC - MinC
    ).

% hull_dot_: dot product of edge vectors (A-to-B) and (B-to-C).
% Zero dot product means a 90-degree angle at B.
hull_dot_(R1-C1, R2-C2, R3-C3, D) :-
    D is (R2 - R1) * (R3 - R2) + (C2 - C1) * (C3 - C2).

% hull_is_rect(+Cells): succeed if the convex hull of Cells has exactly 4
% vertices and all four interior angles are exactly 90 degrees.
hull_is_rect(Cells) :-
    hull_convex_hull(Cells, Hull),
    length(Hull, 4),
    Hull = [A, B, C, D],
    hull_dot_(A, B, C, D1), D1 =:= 0,
    hull_dot_(B, C, D, D2), D2 =:= 0,
    hull_dot_(C, D, A, D3), D3 =:= 0,
    hull_dot_(D, A, B, D4), D4 =:= 0.

% hull_edge_len2_: squared length of edge from A to B.
hull_edge_len2_(R1-C1, R2-C2, L2) :-
    L2 is (R2 - R1) * (R2 - R1) + (C2 - C1) * (C2 - C1).

% hull_perim2_sum_: sum squared edge lengths over a closed vertex list.
hull_perim2_sum_([_], Acc, Acc) :- !.
hull_perim2_sum_([A, B | Rest], Acc, P2) :-
    hull_edge_len2_(A, B, L2),
    Acc1 is Acc + L2,
    hull_perim2_sum_([B | Rest], Acc1, P2).

% hull_hull_perim2(+Cells, -P2): sum of squared edge lengths of the convex hull
% (including the closing edge). Approximates the perimeter without floats.
% Returns 0 for hulls with fewer than 2 vertices.
hull_hull_perim2(Cells, P2) :-
    hull_convex_hull(Cells, Hull),
    length(Hull, N),
    (N < 2 ->
        P2 = 0
    ;
        Hull = [First | _],
        append(Hull, [First], Closed),
        hull_perim2_sum_(Closed, 0, P2)
    ).

% hull_sum_list_: sum a list of integers recursively.
hull_sum_list_([], 0).
hull_sum_list_([H | T], S) :-
    hull_sum_list_(T, S1),
    S is S1 + H.

% hull_centroid(+Cells, -AvgR, -AvgC): centroid of the convex hull vertices.
% AvgR and AvgC are the integer floor of the average row and column of the
% hull vertices (not of all cells in Cells). Fails if hull is empty.
hull_centroid(Cells, AvgR, AvgC) :-
    hull_convex_hull(Cells, Hull),
    Hull \= [],
    length(Hull, N),
    maplist([R-_, R]>>true, Hull, Rs),
    maplist([_-C, C]>>true, Hull, Cs),
    hull_sum_list_(Rs, SumR),
    hull_sum_list_(Cs, SumC),
    AvgR is SumR // N,
    AvgC is SumC // N.

% hull_hull_contains(+Cells, +SubCells): succeed if every cell in SubCells lies
% inside or on the convex hull of Cells.
hull_hull_contains(Cells, SubCells) :-
    hull_convex_hull(Cells, Hull),
    forall(member(R-C, SubCells), hull_in_hull(R, C, Hull)).
