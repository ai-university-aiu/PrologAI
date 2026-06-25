% Module measure: geometric measurement of cell regions and grids.
% Layer 51. Prefix: ms_. Requires: grid.
% A region is any list of r(R,C) cells.
:- module(measure, [
    % Cell count of a region.
    ms_area/2,
    % Tight bounding box of a region as bbox(R1,C1,R2,C2).
    ms_bbox/2,
    % Width and height of the bounding box of a region.
    ms_bbox_size/3,
    % Number of exposed 4-connected edge faces of a region.
    ms_perimeter/2,
    % Diameter: maximum Manhattan distance between any two cells in the region.
    ms_diameter/2,
    % Extent: area / bbox_area as integer fraction N/D.
    ms_extent/3,
    % Aspect ratio: max(W,H) / min(W,H) as N/D.
    ms_aspect/3,
    % Number of distinct rows occupied by the region.
    ms_row_span/2,
    % Number of distinct columns occupied by the region.
    ms_col_span/2,
    % Integer floor centroid (AvgR, AvgC) of the region.
    ms_centroid/3,
    % Maximum Chebyshev distance from centroid to any cell.
    ms_radius/2,
    % Count of cells whose 4 neighbors are all in the region.
    ms_interior_count/2,
    % Count of cells with at least one 4-neighbor outside the region.
    ms_border_count/2,
    % Number of distinct color values in a grid.
    ms_color_count/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/2,
                                max_list/2, min_list/2, sum_list/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% ms_row_(+Cell, -R)
% Extract the row index from a cell.
ms_row_(r(R,_), R).

% ms_col_(+Cell, -C)
% Extract the column index from a cell.
ms_col_(r(_,C), C).

% ms_rows_(+Region, -Rs): list of all row indices in Region.
ms_rows_(Region, Rs) :- maplist(ms_row_, Region, Rs).

% ms_cols_(+Region, -Cs): list of all column indices in Region.
ms_cols_(Region, Cs) :- maplist(ms_col_, Region, Cs).

% ms_unique_(+SortedList, -Unique)
% Remove consecutive duplicates from a sorted list.
ms_unique_([], []).
ms_unique_([H], [H]) :- !.
ms_unique_([H,H|T], U) :- !, ms_unique_([H|T], U).
ms_unique_([H|T], [H|U]) :- ms_unique_(T, U).

% ms_area(+Region, -N)
% N is the number of cells in Region.
ms_area(Region, N) :- length(Region, N).

% ms_bbox(+Region, -bbox(R1,C1,R2,C2))
% Tight bounding box of Region.
ms_bbox(Region, bbox(R1, C1, R2, C2)) :-
    Region = [_|_],
    ms_rows_(Region, Rs), ms_cols_(Region, Cs),
    min_list(Rs, R1), max_list(Rs, R2),
    min_list(Cs, C1), max_list(Cs, C2).

% ms_bbox_size(+Region, -W, -H)
% W is bounding box width (C2-C1+1), H is height (R2-R1+1).
ms_bbox_size(Region, W, H) :-
    ms_bbox(Region, bbox(R1, C1, R2, C2)),
    W is C2 - C1 + 1,
    H is R2 - R1 + 1.

% ms_neighbor4_(+Cell, ?Neighbor)
% Enumerate 4-connected neighbors of a cell.
ms_neighbor4_(r(R,C), r(N,C)) :- N is R - 1.
ms_neighbor4_(r(R,C), r(N,C)) :- N is R + 1.
ms_neighbor4_(r(R,C), r(R,N)) :- N is C - 1.
ms_neighbor4_(r(R,C), r(R,N)) :- N is C + 1.

% ms_cell_exposed_(+Region, +Cell, -N)
% N is the count of 4-connected neighbors of Cell not in Region.
ms_cell_exposed_(Region, Cell, N) :-
    findall(Nb, (ms_neighbor4_(Cell, Nb), \+ member(Nb, Region)), Exposed),
    length(Exposed, N).

% ms_perimeter(+Region, -P)
% P is the total exposed 4-edge count: sum of exposed edges across all cells.
ms_perimeter(Region, P) :-
    Region = [_|_],
    maplist(ms_cell_exposed_(Region), Region, Ns),
    sum_list(Ns, P).

% ms_diameter(+Region, -D)
% D is the maximum Manhattan distance between any two cells in Region.
ms_diameter(Region, D) :-
    Region = [_|_],
    findall(Dist,
        (member(r(R1,C1), Region), member(r(R2,C2), Region),
         Dist is abs(R1 - R2) + abs(C1 - C2)),
        Dists),
    max_list(Dists, D).

% ms_extent(+Region, -N, -D)
% N = area, D = bbox_area. Extent = N/D (as two separate integers).
ms_extent(Region, N, D) :-
    ms_area(Region, N),
    ms_bbox(Region, bbox(R1, C1, R2, C2)),
    D is (R2 - R1 + 1) * (C2 - C1 + 1),
    D > 0.

% ms_aspect(+Region, -N, -D)
% N = max(W,H), D = min(W,H) where W and H are bbox dimensions.
% Aspect ratio = N/D. Square has N=D.
ms_aspect(Region, N, D) :-
    ms_bbox_size(Region, W, H),
    N is max(W, H),
    D is min(W, H).

% ms_row_span(+Region, -S)
% S is the number of distinct row indices occupied by Region.
ms_row_span(Region, S) :-
    ms_rows_(Region, Rs),
    msort(Rs, Sorted),
    ms_unique_(Sorted, Unique),
    length(Unique, S).

% ms_col_span(+Region, -S)
% S is the number of distinct column indices occupied by Region.
ms_col_span(Region, S) :-
    ms_cols_(Region, Cs),
    msort(Cs, Sorted),
    ms_unique_(Sorted, Unique),
    length(Unique, S).

% ms_centroid(+Region, -AvgR, -AvgC)
% Integer floor centroid of Region.
ms_centroid(Region, AvgR, AvgC) :-
    Region = [_|_],
    ms_rows_(Region, Rs), ms_cols_(Region, Cs),
    sum_list(Rs, SumR), sum_list(Cs, SumC),
    length(Region, N),
    AvgR is SumR // N,
    AvgC is SumC // N.

% ms_chebyshev_(+r(R1,C1), +r(R2,C2), -D)
% Chebyshev (L-infinity) distance between two cells.
ms_chebyshev_(r(R1,C1), r(R2,C2), D) :-
    D is max(abs(R1 - R2), abs(C1 - C2)).

% ms_radius(+Region, -Rad)
% Rad is the maximum Chebyshev distance from the centroid to any cell.
ms_radius(Region, Rad) :-
    ms_centroid(Region, CR, CC),
    findall(D, (member(Cell, Region), ms_chebyshev_(r(CR,CC), Cell, D)), Ds),
    max_list(Ds, Rad).

% ms_has_all_neighbors_(+Cell, +Region)
% Succeed if all 4 neighbors of Cell are in Region.
ms_has_all_neighbors_(Cell, Region) :-
    \+ (ms_neighbor4_(Cell, Nb), \+ member(Nb, Region)).

% ms_interior_count(+Region, -N)
% N is the number of cells in Region all of whose 4 neighbors are also in Region.
ms_interior_count(Region, N) :-
    findall(Cell, (member(Cell, Region), ms_has_all_neighbors_(Cell, Region)), Interior),
    length(Interior, N).

% ms_border_count(+Region, -N)
% N is the number of cells in Region with at least one 4-neighbor outside Region.
ms_border_count(Region, N) :-
    findall(Cell, (member(Cell, Region), \+ ms_has_all_neighbors_(Cell, Region)), Border),
    length(Border, N).

% ms_grid_colors_(+Grid, -Colors)
% Flatten Grid to a sorted list of unique cell values.
ms_grid_colors_(Grid, Colors) :-
    append(Grid, Flat),
    msort(Flat, Sorted),
    ms_unique_(Sorted, Colors).

% ms_color_count(+Grid, -N)
% N is the number of distinct color values present in Grid.
ms_color_count(Grid, N) :-
    ms_grid_colors_(Grid, Colors),
    length(Colors, N).
