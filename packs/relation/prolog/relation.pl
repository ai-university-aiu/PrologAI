% Module relation: spatial relations between cell regions.
% Layer 47. Prefix: rl_. Depends on grid pack only.
% A region is any list of r(R,C) cells (not necessarily normalized to origin).
:- module(relation, [
    % Succeed if region A is entirely above region B.
    rl_above/2,
    % Succeed if region A is entirely below region B.
    rl_below/2,
    % Succeed if region A is entirely left of region B.
    rl_left_of/2,
    % Succeed if region A is entirely right of region B.
    rl_right_of/2,
    % Succeed if any cell of A is 4-connected adjacent to any cell of B.
    rl_adjacent/2,
    % Minimum Manhattan distance between any cell of A and any cell of B.
    rl_distance/3,
    % Succeed if the bounding box of A is contained in the bounding box of B.
    rl_contained_bbox/2,
    % Succeed if A and B share at least one cell.
    rl_overlap/2,
    % Succeed if A and B share no cells.
    rl_disjoint/2,
    % Succeed if A and B have at least one row index in common.
    rl_same_row/2,
    % Succeed if A and B have at least one column index in common.
    rl_same_col/2,
    % Integer centroid (AvgR, AvgC) of a region.
    rl_centroid/3,
    % Integer (DR, DC) offset from centroid of A to centroid of B.
    rl_offset/4,
    % Cardinal direction from region A toward region B (above/below/left/right).
    rl_direction/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, max_member/2, min_member/2,
                                max_list/2, min_list/2, sum_list/2,
                                append/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Load grid pack.
:- use_module(library(grid)).

% rl_rows_(+Region, -Rs)
% Extract all row indices from a region.
rl_rows_(Region, Rs) :-
    maplist(rl_row_, Region, Rs).

% rl_row_(+Cell, -R)
rl_row_(r(R,_), R).

% rl_cols_(+Region, -Cs)
% Extract all column indices from a region.
rl_cols_(Region, Cs) :-
    maplist(rl_col_, Region, Cs).

% rl_col_(+Cell, -C)
rl_col_(r(_,C), C).

% rl_above(+A, +B)
% Succeed if every row of A is strictly less than every row of B.
% (A is entirely above B in grid coordinates: smaller row = higher up.)
rl_above(A, B) :-
    rl_rows_(A, Rs_A),
    rl_rows_(B, Rs_B),
    max_list(Rs_A, MaxR_A),
    min_list(Rs_B, MinR_B),
    MaxR_A < MinR_B.

% rl_below(+A, +B)
% Succeed if every row of A is strictly greater than every row of B.
rl_below(A, B) :-
    rl_rows_(A, Rs_A),
    rl_rows_(B, Rs_B),
    min_list(Rs_A, MinR_A),
    max_list(Rs_B, MaxR_B),
    MinR_A > MaxR_B.

% rl_left_of(+A, +B)
% Succeed if every column of A is strictly less than every column of B.
rl_left_of(A, B) :-
    rl_cols_(A, Cs_A),
    rl_cols_(B, Cs_B),
    max_list(Cs_A, MaxC_A),
    min_list(Cs_B, MinC_B),
    MaxC_A < MinC_B.

% rl_right_of(+A, +B)
% Succeed if every column of A is strictly greater than every column of B.
rl_right_of(A, B) :-
    rl_cols_(A, Cs_A),
    rl_cols_(B, Cs_B),
    min_list(Cs_A, MinC_A),
    max_list(Cs_B, MaxC_B),
    MinC_A > MaxC_B.

% rl_adjacent(+A, +B)
% Succeed if any cell of A has a 4-connected neighbor in B.
rl_adjacent(A, B) :-
    member(r(R1,C1), A),
    member(r(R2,C2), B),
    (   R1 =:= R2, (C2 =:= C1 - 1 ; C2 =:= C1 + 1)
    ;   C1 =:= C2, (R2 =:= R1 - 1 ; R2 =:= R1 + 1)
    ),
    !.

% rl_distance(+A, +B, -D)
% D is the minimum Manhattan distance between any cell of A and any cell of B.
rl_distance(A, B, D) :-
    findall(Dist,
        (   member(r(R1,C1), A),
            member(r(R2,C2), B),
            Dist is abs(R1 - R2) + abs(C1 - C2)
        ),
        Dists),
    Dists = [_|_],
    min_list(Dists, D).

% rl_contained_bbox(+A, +B)
% Succeed if the bounding box of A is contained within the bounding box of B.
rl_contained_bbox(A, B) :-
    rl_rows_(A, Rs_A),
    rl_cols_(A, Cs_A),
    rl_rows_(B, Rs_B),
    rl_cols_(B, Cs_B),
    min_list(Rs_A, MinR_A), max_list(Rs_A, MaxR_A),
    min_list(Cs_A, MinC_A), max_list(Cs_A, MaxC_A),
    min_list(Rs_B, MinR_B), max_list(Rs_B, MaxR_B),
    min_list(Cs_B, MinC_B), max_list(Cs_B, MaxC_B),
    MinR_A >= MinR_B,
    MaxR_A =< MaxR_B,
    MinC_A >= MinC_B,
    MaxC_A =< MaxC_B.

% rl_overlap(+A, +B)
% Succeed if A and B share at least one cell.
rl_overlap(A, B) :-
    member(Cell, A),
    member(Cell, B),
    !.

% rl_disjoint(+A, +B)
% Succeed if A and B share no cells.
rl_disjoint(A, B) :-
    \+ rl_overlap(A, B).

% rl_same_row(+A, +B)
% Succeed if A and B have at least one row index in common.
rl_same_row(A, B) :-
    member(r(R,_), A),
    member(r(R,_), B),
    !.

% rl_same_col(+A, +B)
% Succeed if A and B have at least one column index in common.
rl_same_col(A, B) :-
    member(r(_,C), A),
    member(r(_,C), B),
    !.

% rl_centroid(+Region, -AvgR, -AvgC)
% AvgR and AvgC are the integer (floor) centroid of Region.
rl_centroid(Region, AvgR, AvgC) :-
    Region = [_|_],
    rl_rows_(Region, Rs),
    rl_cols_(Region, Cs),
    sum_list(Rs, SumR),
    sum_list(Cs, SumC),
    length(Region, N),
    AvgR is SumR // N,
    AvgC is SumC // N.

% rl_offset(+A, +B, -DR, -DC)
% DR and DC are the integer offset from the centroid of A to the centroid of B.
% DR = centroid_row(B) - centroid_row(A), DC = centroid_col(B) - centroid_col(A).
rl_offset(A, B, DR, DC) :-
    rl_centroid(A, RA, CA),
    rl_centroid(B, RB, CB),
    DR is RB - RA,
    DC is CB - CA.

% rl_direction(+A, +B, -Dir)
% Dir is the cardinal direction (above/below/left/right) from A toward B.
% Based on the dominant axis of the centroid offset.
% Fails if centroids are identical.
rl_direction(A, B, Dir) :-
    rl_offset(A, B, DR, DC),
    rl_dir_from_offset_(DR, DC, Dir).

% rl_dir_from_offset_(+DR, +DC, -Dir)
% Convert (DR, DC) offset to a cardinal direction.
% Vertical axis dominates on tie (abs(DR) >= abs(DC)).
rl_dir_from_offset_(DR, DC, above) :-
    DR < 0,
    abs(DR) >= abs(DC),
    !.
rl_dir_from_offset_(DR, DC, below) :-
    DR > 0,
    abs(DR) >= abs(DC),
    !.
rl_dir_from_offset_(DR, DC, left) :-
    DC < 0,
    abs(DC) > abs(DR),
    !.
rl_dir_from_offset_(_DR, DC, right) :-
    DC > 0.
