% Module declaration: spatial pack, Layer 58.
:- module(spatial, [
    % spatial_direction/3: cardinal direction from Cell1 to Cell2.
    spatial_direction/3,
    % spatial_distance_manhattan/3: Manhattan (L1) distance between two cells.
    spatial_distance_manhattan/3,
    % spatial_distance_chebyshev/3: Chebyshev (L-inf) distance between two cells.
    spatial_distance_chebyshev/3,
    % spatial_neighbors4/3: all 4-connected neighbors of a cell within grid bounds.
    spatial_neighbors4/3,
    % spatial_neighbors8/3: all 8-connected neighbors of a cell within grid bounds.
    spatial_neighbors8/3,
    % spatial_adjacent4/2: true when two cells are 4-connected neighbors.
    spatial_adjacent4/2,
    % spatial_adjacent8/2: true when two cells are 8-connected neighbors.
    spatial_adjacent8/2,
    % spatial_bbox_contains/2: true when a cell is inside a bounding box.
    spatial_bbox_contains/2,
    % spatial_in_region/2: true when a cell is a member of a region list.
    spatial_in_region/2,
    % spatial_row_between/3: cells in Region between two row indices (inclusive).
    spatial_row_between/4,
    % spatial_col_between/4: cells in Region between two column indices (inclusive).
    spatial_col_between/4,
    % spatial_closest/3: cell in Region closest (Manhattan) to a reference cell.
    spatial_closest/3,
    % spatial_farthest/3: cell in Region farthest (Manhattan) from a reference cell.
    spatial_farthest/3,
    % spatial_centroid/3: integer centroid of a region (rounded down).
    spatial_centroid/3
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% spatial_direction(+r(R1,C1), +r(R2,C2), -Dir): cardinal direction from Cell1 to Cell2.
spatial_direction(r(R1,C1), r(R2,C2), Dir) :-
    % Compute row and column offsets.
    DR is R2 - R1, DC is C2 - C1,
    % Map to a cardinal name.
    spatial_dir_name_(DR, DC, Dir).

% spatial_dir_name_(+DR, +DC, -Dir): name the direction from offset signs.
spatial_dir_name_(DR, 0, north) :- DR < 0, !.
spatial_dir_name_(DR, 0, south) :- DR > 0, !.
spatial_dir_name_(0, DC, west)  :- DC < 0, !.
spatial_dir_name_(0, DC, east)  :- DC > 0, !.
spatial_dir_name_(DR, DC, northeast) :- DR < 0, DC > 0, !.
spatial_dir_name_(DR, DC, northwest) :- DR < 0, DC < 0, !.
spatial_dir_name_(DR, DC, southeast) :- DR > 0, DC > 0, !.
spatial_dir_name_(DR, DC, southwest) :- DR > 0, DC < 0, !.
spatial_dir_name_(0, 0, same).

% spatial_distance_manhattan(+r(R1,C1), +r(R2,C2), -D): |R2-R1| + |C2-C1|.
spatial_distance_manhattan(r(R1,C1), r(R2,C2), D) :-
    % Compute absolute row and column differences.
    DR is abs(R2 - R1), DC is abs(C2 - C1),
    D is DR + DC.

% spatial_distance_chebyshev(+r(R1,C1), +r(R2,C2), -D): max(|R2-R1|, |C2-C1|).
spatial_distance_chebyshev(r(R1,C1), r(R2,C2), D) :-
    % Compute absolute differences then take max.
    DR is abs(R2 - R1), DC is abs(C2 - C1),
    D is max(DR, DC).

% spatial_in_bounds_(+Rows, +Cols, +r(R,C)): cell is within grid boundaries.
spatial_in_bounds_(Rows, Cols, r(R,C)) :-
    R >= 0, R < Rows, C >= 0, C < Cols.

% spatial_neighbors4(+r(R,C), +Rows-Cols, -Neighbors): 4-connected in-bounds neighbors.
spatial_neighbors4(r(R,C), Rows-Cols, Neighbors) :-
    % Generate all four candidate neighbors.
    R1 is R - 1, R2 is R + 1, C1 is C - 1, C2 is C + 1,
    Candidates = [r(R1,C), r(R2,C), r(R,C1), r(R,C2)],
    % Keep only in-bounds ones.
    include(spatial_in_bounds_(Rows, Cols), Candidates, Neighbors).

% spatial_neighbors8(+r(R,C), +Rows-Cols, -Neighbors): 8-connected in-bounds neighbors.
spatial_neighbors8(r(R,C), Rows-Cols, Neighbors) :-
    % Generate all eight candidate neighbors.
    R1 is R - 1, R2 is R + 1, C1 is C - 1, C2 is C + 1,
    Candidates = [r(R1,C1), r(R1,C), r(R1,C2),
                  r(R,C1),            r(R,C2),
                  r(R2,C1), r(R2,C), r(R2,C2)],
    % Keep only in-bounds ones.
    include(spatial_in_bounds_(Rows, Cols), Candidates, Neighbors).

% spatial_adjacent4(+Cell1, +Cell2): cells are 4-connected (differ by exactly 1 in one axis).
spatial_adjacent4(r(R1,C1), r(R2,C2)) :-
    % Manhattan distance exactly 1.
    D is abs(R2-R1) + abs(C2-C1),
    D =:= 1.

% spatial_adjacent8(+Cell1, +Cell2): cells are 8-connected (Chebyshev distance 1).
spatial_adjacent8(r(R1,C1), r(R2,C2)) :-
    % Chebyshev distance exactly 1 (and not same cell).
    DR is abs(R2-R1), DC is abs(C2-C1),
    max(DR, DC) =:= 1.

% spatial_bbox_contains(+bbox(R1,C1,R2,C2), +r(R,C)): cell is inside the bounding box.
spatial_bbox_contains(bbox(R1,C1,R2,C2), r(R,C)) :-
    % Row and column both within the bbox range.
    R >= R1, R =< R2, C >= C1, C =< C2.

% spatial_in_region(+Cell, +Region): cell membership in a region list.
spatial_in_region(Cell, Region) :-
    % Cut after first match to suppress choicepoint.
    member(Cell, Region), !.

% spatial_row_between(+Region, +MinR, +MaxR, -Filtered): cells with MinR =< R =< MaxR.
spatial_row_between(Region, MinR, MaxR, Filtered) :-
    % Keep cells whose row index falls in the range.
    include(spatial_row_in_range_(MinR, MaxR), Region, Filtered).

% spatial_row_in_range_(+MinR, +MaxR, +r(R,_)): row R in [MinR, MaxR].
spatial_row_in_range_(MinR, MaxR, r(R,_)) :-
    R >= MinR, R =< MaxR.

% spatial_col_between(+Region, +MinC, +MaxC, -Filtered): cells with MinC =< C =< MaxC.
spatial_col_between(Region, MinC, MaxC, Filtered) :-
    % Keep cells whose column index falls in the range.
    include(spatial_col_in_range_(MinC, MaxC), Region, Filtered).

% spatial_col_in_range_(+MinC, +MaxC, +r(_,C)): column C in [MinC, MaxC].
spatial_col_in_range_(MinC, MaxC, r(_,C)) :-
    C >= MinC, C =< MaxC.

% spatial_manhattan_dist_(+Ref, +Cell, -D): Manhattan distance from Ref to Cell.
spatial_manhattan_dist_(Ref, Cell, D) :-
    spatial_distance_manhattan(Ref, Cell, D).

% spatial_closest(+Ref, +Region, -Closest): cell in Region with minimum Manhattan distance.
spatial_closest(Ref, Region, Closest) :-
    % Compute distances to all region cells.
    Region = [_|_],
    maplist(spatial_manhattan_dist_(Ref), Region, Dists),
    % Find the minimum distance.
    min_list(Dists, MinD),
    % Return the first cell at that distance.
    nth0(Idx, Dists, MinD), !,
    nth0(Idx, Region, Closest).

% spatial_farthest(+Ref, +Region, -Farthest): cell in Region with maximum Manhattan distance.
spatial_farthest(Ref, Region, Farthest) :-
    % Compute distances to all region cells.
    Region = [_|_],
    maplist(spatial_manhattan_dist_(Ref), Region, Dists),
    % Find the maximum distance.
    max_list(Dists, MaxD),
    % Return the first cell at that distance.
    nth0(Idx, Dists, MaxD), !,
    nth0(Idx, Region, Farthest).

% spatial_centroid(+Region, -Row, -Col): integer centroid (average, truncated).
spatial_centroid(Region, Row, Col) :-
    % Sum all row and column indices.
    length(Region, N), N > 0,
    maplist([r(R,_), R]>>(true), Region, Rows),
    maplist([r(_,C), C]>>(true), Region, Cols),
    sum_list(Rows, SumR), sum_list(Cols, SumC),
    % Truncate division to integer.
    Row is SumR // N,
    Col is SumC // N.
