% Object Pair Relation Analysis (or_*, Layer 172)
% Predicates that take two obj(Color, Cells) terms and compute
% their pairwise geometric and spatial relationships.
% Cell positions are r(Row, Col) terms; colors are ignored in all predicates.
:- module(object_pair_relation, [
    object_pair_relation_overlap/2,
    object_pair_relation_shared_cells/3,
    object_pair_relation_n_shared/3,
    object_pair_relation_touch4/2,
    object_pair_relation_touch8/2,
    object_pair_relation_contains/2,
    object_pair_relation_union_cells/3,
    object_pair_relation_dist/3,
    object_pair_relation_manhattan/3,
    object_pair_relation_direction/3,
    object_pair_relation_aligned_h/2,
    object_pair_relation_aligned_v/2,
    object_pair_relation_gap_rows/3,
    object_pair_relation_gap_cols/3
]).

:- use_module(library(lists), [member/2, memberchk/2, append/3]).
:- use_module(library(aggregate), []).

% object_pair_relation_centroid_(+Obj, -CR, -CC): private; centroid = (sum_rows/N, sum_cols/N)
object_pair_relation_centroid_(obj(_, Cells), CR, CC) :-
    % collect all row indices from the cell list
    findall(R, member(r(R,_), Cells), Rs),
    % collect all column indices from the cell list
    findall(C, member(r(_,C), Cells), Cs),
    % cell count must be positive
    length(Rs, N), N > 0,
    % sum rows and cols then divide by count
    sumlist(Rs, SR), sumlist(Cs, SC),
    % compute floating-point centroid coordinates
    CR is SR / N, CC is SC / N.

% object_pair_relation_bbox_(+Obj, -MinR, -MinC, -MaxR, -MaxC): private; bounding box of Obj
object_pair_relation_bbox_(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
    % collect row and column indices separately
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    % bounding box extremes
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% object_pair_relation_dir_(+DR, +DC, -Dir): private; direction atom from centroid delta (DR, DC)
% DR = row delta (positive = south), DC = col delta (positive = east)
object_pair_relation_dir_(DR, DC, Dir) :-
    (   DR =:= 0, DC > 0  -> Dir = e
    ;   DR =:= 0, DC < 0  -> Dir = w
    ;   DR > 0,  DC =:= 0 -> Dir = s
    ;   DR < 0,  DC =:= 0 -> Dir = n
    ;   DR > 0,  DC > 0   -> Dir = se
    ;   DR > 0,  DC < 0   -> Dir = sw
    ;   DR < 0,  DC > 0   -> Dir = ne
    ;   DR < 0,  DC < 0   -> Dir = nw
    ;                         Dir = same
    ).

% object_pair_relation_overlap(+Obj1, +Obj2): true if Obj1 and Obj2 share at least one cell
% colors are ignored; cell positions alone determine overlap
object_pair_relation_overlap(obj(_, Cells1), obj(_, Cells2)) :-
    % find any cell that appears in both lists; cut on first match
    member(Cell, Cells1), memberchk(Cell, Cells2), !.

% object_pair_relation_shared_cells(+Obj1, +Obj2, -Shared): cells present in both objects
% result order matches Obj1's cell ordering; colors are ignored
object_pair_relation_shared_cells(obj(_, Cells1), obj(_, Cells2), Shared) :-
    % keep cells from Obj1 that also appear in Obj2
    findall(C, (member(C, Cells1), memberchk(C, Cells2)), Shared).

% object_pair_relation_n_shared(+Obj1, +Obj2, -N): count of shared cells between Obj1 and Obj2
object_pair_relation_n_shared(Obj1, Obj2, N) :-
    % delegate to object_pair_relation_shared_cells then measure length
    object_pair_relation_shared_cells(Obj1, Obj2, Shared), length(Shared, N).

% object_pair_relation_touch4(+Obj1, +Obj2): true if objects are 4-adjacent but do not overlap
% 4-adjacent means there exist cells at Manhattan distance exactly 1
object_pair_relation_touch4(Obj1, Obj2) :-
    % overlapping objects do not qualify as touching
    \+ object_pair_relation_overlap(Obj1, Obj2),
    % destructure to access cell lists
    Obj1 = obj(_, Cells1), Obj2 = obj(_, Cells2),
    % find a cell pair at Manhattan distance 1; cut on first match
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    D is abs(R1-R2) + abs(C1-C2),
    D =:= 1, !.

% object_pair_relation_touch8(+Obj1, +Obj2): true if objects are 8-adjacent (Chebyshev 1) but do not overlap
% 8-adjacent includes diagonal neighbors (Chebyshev distance = 1)
object_pair_relation_touch8(Obj1, Obj2) :-
    % overlapping objects do not qualify
    \+ object_pair_relation_overlap(Obj1, Obj2),
    % destructure to access cell lists
    Obj1 = obj(_, Cells1), Obj2 = obj(_, Cells2),
    % find a cell pair at Chebyshev distance 1; cut on first match
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    DR is abs(R1-R2), DC is abs(C1-C2),
    max(DR, DC) =:= 1, !.

% object_pair_relation_contains(+Obj1, +Obj2): true if every cell of Obj2 is also a cell of Obj1
% colors are ignored; containment is purely by cell set inclusion
object_pair_relation_contains(Obj1, Obj2) :-
    % destructure both objects
    Obj1 = obj(_, Cells1), Obj2 = obj(_, Cells2),
    % every cell of Obj2 must appear in Obj1
    forall(member(C, Cells2), memberchk(C, Cells1)).

% object_pair_relation_union_cells(+Obj1, +Obj2, -Union): sorted union of both cell sets
% Union contains every cell that appears in either Obj1 or Obj2; no duplicates
object_pair_relation_union_cells(Obj1, Obj2, Union) :-
    % destructure both objects
    Obj1 = obj(_, Cells1), Obj2 = obj(_, Cells2),
    % concatenate then sort to remove duplicates and canonicalize order
    append(Cells1, Cells2, Both), sort(Both, Union).

% object_pair_relation_dist(+Obj1, +Obj2, -D): Euclidean distance between centroids as a float
object_pair_relation_dist(Obj1, Obj2, D) :-
    % compute centroids of both objects
    object_pair_relation_centroid_(Obj1, R1, C1),
    object_pair_relation_centroid_(Obj2, R2, C2),
    % Euclidean distance formula
    D is sqrt((R2-R1)**2 + (C2-C1)**2).

% object_pair_relation_manhattan(+Obj1, +Obj2, -D): Manhattan distance between centroids
% result is a number (float when centroids have fractional coordinates)
object_pair_relation_manhattan(Obj1, Obj2, D) :-
    % compute centroids of both objects
    object_pair_relation_centroid_(Obj1, R1, C1),
    object_pair_relation_centroid_(Obj2, R2, C2),
    % sum of absolute coordinate differences
    D is abs(R2-R1) + abs(C2-C1).

% object_pair_relation_direction(+Obj1, +Obj2, -Dir): direction from Obj1 centroid to Obj2 centroid
% Dir is one of: n, s, e, w, ne, nw, se, sw, same
% rows increase southward; columns increase eastward
object_pair_relation_direction(Obj1, Obj2, Dir) :-
    % compute both centroids
    object_pair_relation_centroid_(Obj1, R1, C1),
    object_pair_relation_centroid_(Obj2, R2, C2),
    % centroid deltas: positive DR = south, positive DC = east
    DR is R2-R1, DC is C2-C1,
    % map delta pair to direction atom
    object_pair_relation_dir_(DR, DC, Dir).

% object_pair_relation_aligned_h(+Obj1, +Obj2): true if both objects have the same centroid row
% "horizontally aligned" means they share the same row center
object_pair_relation_aligned_h(Obj1, Obj2) :-
    % compute centroid row for each object
    object_pair_relation_centroid_(Obj1, R1, _),
    object_pair_relation_centroid_(Obj2, R2, _),
    % compare centroid rows arithmetically
    R1 =:= R2.

% object_pair_relation_aligned_v(+Obj1, +Obj2): true if both objects have the same centroid column
% "vertically aligned" means they share the same column center
object_pair_relation_aligned_v(Obj1, Obj2) :-
    % compute centroid column for each object
    object_pair_relation_centroid_(Obj1, _, C1),
    object_pair_relation_centroid_(Obj2, _, C2),
    % compare centroid columns arithmetically
    C1 =:= C2.

% object_pair_relation_gap_rows(+Obj1, +Obj2, -G): number of row gaps between bounding boxes
% G = 0 when bboxes touch or overlap; G > 0 is the number of empty rows between them
object_pair_relation_gap_rows(Obj1, Obj2, G) :-
    % bounding boxes of both objects
    object_pair_relation_bbox_(Obj1, MinR1, _, MaxR1, _),
    object_pair_relation_bbox_(Obj2, MinR2, _, MaxR2, _),
    % gap = distance between the closer edges minus one; floored at 0
    G is max(0, max(MinR1, MinR2) - min(MaxR1, MaxR2) - 1).

% object_pair_relation_gap_cols(+Obj1, +Obj2, -G): number of column gaps between bounding boxes
% G = 0 when bboxes touch or overlap in the column dimension
object_pair_relation_gap_cols(Obj1, Obj2, G) :-
    % bounding boxes of both objects (column extremes)
    object_pair_relation_bbox_(Obj1, _, MinC1, _, MaxC1),
    object_pair_relation_bbox_(Obj2, _, MinC2, _, MaxC2),
    % gap = distance between the closer column edges minus one; floored at 0
    G is max(0, max(MinC1, MinC2) - min(MaxC1, MaxC2) - 1).
