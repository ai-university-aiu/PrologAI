% Module measure: geometric measurement of cell regions and grids.
% Layer 51. Prefix: ms_. Requires: grid.
% A region is any list of r(R,C) cells.
:- module(measure, [
    % Cell count of a region.
    measure_area/2,
    % Tight bounding box of a region as bbox(R1,C1,R2,C2).
    measure_bbox/2,
    % Width and height of the bounding box of a region.
    measure_bbox_size/3,
    % Number of exposed 4-connected edge faces of a region.
    measure_perimeter/2,
    % Diameter: maximum Manhattan distance between any two cells in the region.
    measure_diameter/2,
    % Extent: area / bbox_area as integer fraction N/D.
    measure_extent/3,
    % Aspect ratio: max(W,H) / min(W,H) as N/D.
    measure_aspect/3,
    % Number of distinct rows occupied by the region.
    measure_row_span/2,
    % Number of distinct columns occupied by the region.
    measure_col_span/2,
    % Integer floor centroid (AvgR, AvgC) of the region.
    measure_centroid/3,
    % Maximum Chebyshev distance from centroid to any cell.
    measure_radius/2,
    % Count of cells whose 4 neighbors are all in the region.
    measure_interior_count/2,
    % Count of cells with at least one 4-neighbor outside the region.
    measure_border_count/2,
    % Number of distinct color values in a grid.
    measure_color_count/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/2,
                                max_list/2, min_list/2, sum_list/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% measure_row_(+Cell, -R)
% Extract the row index from a cell.
measure_row_(r(R,_), R).

% measure_col_(+Cell, -C)
% Extract the column index from a cell.
measure_col_(r(_,C), C).

% measure_rows_(+Region, -Rs): list of all row indices in Region.
measure_rows_(Region, Rs) :- maplist(measure_row_, Region, Rs).

% measure_cols_(+Region, -Cs): list of all column indices in Region.
measure_cols_(Region, Cs) :- maplist(measure_col_, Region, Cs).

% measure_unique_(+SortedList, -Unique)
% Remove consecutive duplicates from a sorted list.
measure_unique_([], []).
measure_unique_([H], [H]) :- !.
measure_unique_([H,H|T], U) :- !, measure_unique_([H|T], U).
measure_unique_([H|T], [H|U]) :- measure_unique_(T, U).

% measure_area(+Region, -N)
% N is the number of cells in Region.
measure_area(Region, N) :- length(Region, N).

% measure_bbox(+Region, -bbox(R1,C1,R2,C2))
% Tight bounding box of Region.
measure_bbox(Region, bbox(R1, C1, R2, C2)) :-
    Region = [_|_],
    measure_rows_(Region, Rs), measure_cols_(Region, Cs),
    min_list(Rs, R1), max_list(Rs, R2),
    min_list(Cs, C1), max_list(Cs, C2).

% measure_bbox_size(+Region, -W, -H)
% W is bounding box width (C2-C1+1), H is height (R2-R1+1).
measure_bbox_size(Region, W, H) :-
    measure_bbox(Region, bbox(R1, C1, R2, C2)),
    W is C2 - C1 + 1,
    H is R2 - R1 + 1.

% measure_neighbor4_(+Cell, ?Neighbor)
% Enumerate 4-connected neighbors of a cell.
measure_neighbor4_(r(R,C), r(N,C)) :- N is R - 1.
measure_neighbor4_(r(R,C), r(N,C)) :- N is R + 1.
measure_neighbor4_(r(R,C), r(R,N)) :- N is C - 1.
measure_neighbor4_(r(R,C), r(R,N)) :- N is C + 1.

% measure_cell_exposed_(+Region, +Cell, -N)
% N is the count of 4-connected neighbors of Cell not in Region.
measure_cell_exposed_(Region, Cell, N) :-
    findall(Nb, (measure_neighbor4_(Cell, Nb), \+ member(Nb, Region)), Exposed),
    length(Exposed, N).

% measure_perimeter(+Region, -P)
% P is the total exposed 4-edge count: sum of exposed edges across all cells.
measure_perimeter(Region, P) :-
    Region = [_|_],
    maplist(measure_cell_exposed_(Region), Region, Ns),
    sum_list(Ns, P).

% measure_diameter(+Region, -D)
% D is the maximum Manhattan distance between any two cells in Region.
measure_diameter(Region, D) :-
    Region = [_|_],
    findall(Dist,
        (member(r(R1,C1), Region), member(r(R2,C2), Region),
         Dist is abs(R1 - R2) + abs(C1 - C2)),
        Dists),
    max_list(Dists, D).

% measure_extent(+Region, -N, -D)
% N = area, D = bbox_area. Extent = N/D (as two separate integers).
measure_extent(Region, N, D) :-
    measure_area(Region, N),
    measure_bbox(Region, bbox(R1, C1, R2, C2)),
    D is (R2 - R1 + 1) * (C2 - C1 + 1),
    D > 0.

% measure_aspect(+Region, -N, -D)
% N = max(W,H), D = min(W,H) where W and H are bbox dimensions.
% Aspect ratio = N/D. Square has N=D.
measure_aspect(Region, N, D) :-
    measure_bbox_size(Region, W, H),
    N is max(W, H),
    D is min(W, H).

% measure_row_span(+Region, -S)
% S is the number of distinct row indices occupied by Region.
measure_row_span(Region, S) :-
    measure_rows_(Region, Rs),
    msort(Rs, Sorted),
    measure_unique_(Sorted, Unique),
    length(Unique, S).

% measure_col_span(+Region, -S)
% S is the number of distinct column indices occupied by Region.
measure_col_span(Region, S) :-
    measure_cols_(Region, Cs),
    msort(Cs, Sorted),
    measure_unique_(Sorted, Unique),
    length(Unique, S).

% measure_centroid(+Region, -AvgR, -AvgC)
% Integer floor centroid of Region.
measure_centroid(Region, AvgR, AvgC) :-
    Region = [_|_],
    measure_rows_(Region, Rs), measure_cols_(Region, Cs),
    sum_list(Rs, SumR), sum_list(Cs, SumC),
    length(Region, N),
    AvgR is SumR // N,
    AvgC is SumC // N.

% measure_chebyshev_(+r(R1,C1), +r(R2,C2), -D)
% Chebyshev (L-infinity) distance between two cells.
measure_chebyshev_(r(R1,C1), r(R2,C2), D) :-
    D is max(abs(R1 - R2), abs(C1 - C2)).

% measure_radius(+Region, -Rad)
% Rad is the maximum Chebyshev distance from the centroid to any cell.
measure_radius(Region, Rad) :-
    measure_centroid(Region, CR, CC),
    findall(D, (member(Cell, Region), measure_chebyshev_(r(CR,CC), Cell, D)), Ds),
    max_list(Ds, Rad).

% measure_has_all_neighbors_(+Cell, +Region)
% Succeed if all 4 neighbors of Cell are in Region.
measure_has_all_neighbors_(Cell, Region) :-
    \+ (measure_neighbor4_(Cell, Nb), \+ member(Nb, Region)).

% measure_interior_count(+Region, -N)
% N is the number of cells in Region all of whose 4 neighbors are also in Region.
measure_interior_count(Region, N) :-
    findall(Cell, (member(Cell, Region), measure_has_all_neighbors_(Cell, Region)), Interior),
    length(Interior, N).

% measure_border_count(+Region, -N)
% N is the number of cells in Region with at least one 4-neighbor outside Region.
measure_border_count(Region, N) :-
    findall(Cell, (member(Cell, Region), \+ measure_has_all_neighbors_(Cell, Region)), Border),
    length(Border, N).

% measure_grid_colors_(+Grid, -Colors)
% Flatten Grid to a sorted list of unique cell values.
measure_grid_colors_(Grid, Colors) :-
    append(Grid, Flat),
    msort(Flat, Sorted),
    measure_unique_(Sorted, Colors).

% measure_color_count(+Grid, -N)
% N is the number of distinct color values present in Grid.
measure_color_count(Grid, N) :-
    measure_grid_colors_(Grid, Colors),
    length(Colors, N).
