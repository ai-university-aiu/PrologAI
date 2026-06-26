% proximity.pl - Layer 157: Object-Level Proximity and Distance (px_* prefix).
% Computes distances and spatial relationships between obj(Color, Cells) terms,
% where Cells is a sorted list of r(R,C) terms. Distance is always Manhattan
% (sum of absolute row and column differences). Centroid is the integer-truncated
% average row and column of an object's cells. All predicates operate on obj terms
% directly; no grid argument is required.
:- module(proximity, [
    % px_centroid/3: integer centroid (R, C) of an obj term.
    px_centroid/3,
    % px_centroid_dist/3: Manhattan distance between centroids of two obj terms.
    px_centroid_dist/3,
    % px_min_cell_dist/3: minimum Manhattan distance between any cell pair of two objs.
    px_min_cell_dist/3,
    % px_touching/2: succeed if any cell of O1 is 4-adjacent to a cell of O2.
    px_touching/2,
    % px_nearest/3: object in list with minimum centroid distance to reference.
    px_nearest/3,
    % px_farthest/3: object in list with maximum centroid distance to reference.
    px_farthest/3,
    % px_sort_by_dist/3: sort list by ascending centroid distance from reference.
    px_sort_by_dist/3,
    % px_within_dist/4: objects whose centroid is within distance D of reference centroid.
    px_within_dist/4,
    % px_beyond_dist/4: objects whose centroid is beyond distance D of reference centroid.
    px_beyond_dist/4,
    % px_closest_pair/2: O1-O2 pair from list with minimum centroid distance (O1 \== O2).
    px_closest_pair/2,
    % px_farthest_pair/2: O1-O2 pair from list with maximum centroid distance.
    px_farthest_pair/2,
    % px_touching_objs/3: objects from list that 4-touch the reference object.
    px_touching_objs/3,
    % px_non_touching_objs/3: objects from list that do not 4-touch the reference.
    px_non_touching_objs/3,
    % px_dist_rank/3: D-Obj pairs sorted ascending by centroid distance from reference.
    px_dist_rank/3
]).

% Import list utilities; msort/2, between/3, length/2, sort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, sum_list/2, nth1/3]).

% px_centroid(+Obj, -R, -C): integer-truncated centroid of an obj term.
% R is the sum of row values divided (integer) by cell count; same for C.
px_centroid(obj(_,Cells), R, C) :-
% Collect all row values and sum them.
    findall(Rr, member(r(Rr,_), Cells), Rs),
    sum_list(Rs, SumR),
% Collect all column values and sum them.
    findall(Cc, member(r(_,Cc), Cells), Cs),
    sum_list(Cs, SumC),
% Integer-truncate by dividing by cell count.
    length(Cells, N),
    R is SumR // N,
    C is SumC // N.

% px_centroid_dist(+O1, +O2, -D): Manhattan distance between centroids of O1 and O2.
px_centroid_dist(O1, O2, D) :-
% Compute centroid of each object.
    px_centroid(O1, R1, C1),
    px_centroid(O2, R2, C2),
% Manhattan distance: sum of absolute differences in row and column.
    D is abs(R1 - R2) + abs(C1 - C2).

% px_min_cell_dist(+O1, +O2, -D): minimum Manhattan distance between any cell pair.
% Considers all combinations of one cell from O1 and one cell from O2.
px_min_cell_dist(obj(_,Cells1), obj(_,Cells2), D) :-
% Compute Manhattan distance for every (cell1, cell2) pair.
    findall(Dist, (
        member(r(R1,C1), Cells1),
        member(r(R2,C2), Cells2),
        Dist is abs(R1 - R2) + abs(C1 - C2)
    ), Dists),
% Minimum of all pairwise distances.
    min_list(Dists, D).

% px_touching(+O1, +O2): succeed if any cell of O1 is 4-adjacent to any cell of O2.
% 4-adjacent means the Manhattan distance between the two cells is exactly 1.
px_touching(obj(_,Cells1), obj(_,Cells2)) :-
% Find a cell pair with Manhattan distance 1; cut stops after first success.
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    abs(R1 - R2) + abs(C1 - C2) =:= 1,
    !.

% px_nearest(+Objs, +Ref, -Nearest): object in Objs with minimum centroid distance to Ref.
% Ties broken by the object that appears first in Objs.
px_nearest(Objs, Ref, Nearest) :-
% Compute centroid distance for every candidate.
    findall(D-O, (member(O, Objs), px_centroid_dist(O, Ref, D)), Pairs),
% Find the minimum distance.
    findall(D, member(D-_, Pairs), Ds),
    min_list(Ds, MinD),
% First match at minimum distance; cut avoids choicepoint.
    member(MinD-Nearest, Pairs), !.

% px_farthest(+Objs, +Ref, -Farthest): object in Objs with maximum centroid distance to Ref.
% Ties broken by the object that appears first in Objs.
px_farthest(Objs, Ref, Farthest) :-
% Compute centroid distance for every candidate.
    findall(D-O, (member(O, Objs), px_centroid_dist(O, Ref, D)), Pairs),
% Find the maximum distance.
    findall(D, member(D-_, Pairs), Ds),
    max_list(Ds, MaxD),
% First match at maximum distance; cut avoids choicepoint.
    member(MaxD-Farthest, Pairs), !.

% px_sort_by_dist(+Objs, +Ref, -Sorted): Sorted is Objs ordered by ascending centroid distance.
% Equal-distance objects preserve their relative order from Objs (msort is stable).
px_sort_by_dist(Objs, Ref, Sorted) :-
% Pair each object with its centroid distance.
    findall(D-O, (member(O, Objs), px_centroid_dist(O, Ref, D)), Pairs),
% Stable sort by distance ascending (msort preserves order of equal keys).
    msort(Pairs, SortedPairs),
% Extract objects in sorted order.
    findall(O, member(_-O, SortedPairs), Sorted).

% px_within_dist(+Objs, +Ref, +D, -Near): objects whose centroid distance <= D from Ref.
px_within_dist(Objs, Ref, D, Near) :-
% Centroid distance at most D.
    findall(O, (member(O, Objs), px_centroid_dist(O, Ref, Dist), Dist =< D), Near).

% px_beyond_dist(+Objs, +Ref, +D, -Far): objects whose centroid distance > D from Ref.
px_beyond_dist(Objs, Ref, D, Far) :-
% Centroid distance strictly greater than D.
    findall(O, (member(O, Objs), px_centroid_dist(O, Ref, Dist), Dist > D), Far).

% px_closest_pair(+Objs, -O1-O2): unordered pair with minimum centroid distance.
% Only considers pairs where I < J (avoids duplicates and self-pairs).
% Ties broken by the first such pair in index order.
px_closest_pair(Objs, O1-O2) :-
% Require at least two objects.
    length(Objs, N), N >= 2,
% Generate all index-ordered distinct pairs (I < J) and their distances.
    findall(D-I-J, (
        between(1, N, I),
        I1 is I + 1,
        between(I1, N, J),
        nth1(I, Objs, A),
        nth1(J, Objs, B),
        px_centroid_dist(A, B, D)
    ), Triples),
% Find the minimum distance.
    findall(D, member(D-_-_, Triples), Ds),
    min_list(Ds, MinD),
% First triple at minimum distance; cut avoids choicepoint.
    member(MinD-Pi-Pj, Triples), !,
    nth1(Pi, Objs, O1),
    nth1(Pj, Objs, O2).

% px_farthest_pair(+Objs, -O1-O2): unordered pair with maximum centroid distance.
px_farthest_pair(Objs, O1-O2) :-
% Require at least two objects.
    length(Objs, N), N >= 2,
% Generate all index-ordered distinct pairs (I < J) and their distances.
    findall(D-I-J, (
        between(1, N, I),
        I1 is I + 1,
        between(I1, N, J),
        nth1(I, Objs, A),
        nth1(J, Objs, B),
        px_centroid_dist(A, B, D)
    ), Triples),
% Find the maximum distance.
    findall(D, member(D-_-_, Triples), Ds),
    max_list(Ds, MaxD),
% First triple at maximum distance; cut avoids choicepoint.
    member(MaxD-Pi-Pj, Triples), !,
    nth1(Pi, Objs, O1),
    nth1(Pj, Objs, O2).

% px_touching_objs(+Objs, +Ref, -Touching): objects from Objs that 4-touch Ref.
px_touching_objs(Objs, Ref, Touching) :-
% Keep objects for which px_touching/2 succeeds.
    findall(O, (member(O, Objs), px_touching(O, Ref)), Touching).

% px_non_touching_objs(+Objs, +Ref, -NonTouching): objects from Objs not touching Ref.
px_non_touching_objs(Objs, Ref, NonTouching) :-
% Keep objects for which px_touching/2 fails (negation as failure).
    findall(O, (member(O, Objs), \+ px_touching(O, Ref)), NonTouching).

% px_dist_rank(+Objs, +Ref, -Ranked): D-Obj pairs sorted ascending by centroid distance.
% Ranked[1] is nearest; last element is farthest. Equal distances ordered as in Objs.
px_dist_rank(Objs, Ref, Ranked) :-
% Compute D-Obj pairs for every object.
    findall(D-O, (member(O, Objs), px_centroid_dist(O, Ref, D)), Pairs),
% Stable sort ascending by distance.
    msort(Pairs, Ranked).
