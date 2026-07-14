/*  PrologAI — Causalontology Object Relations  (WP-408, Layer 383)

    Nearly every ARC-AGI-3 mechanic is defined not on pixels but on the RELATIONS
    between objects: a key is inside a lock's region, a pusher is adjacent to a
    block, a follower sits at a fixed offset from a leader, tiles are aligned in a
    row, the largest object is the one to move. Reasoning over structured objects
    and their relations is far cheaper and far more transferable than reasoning over
    a grid of colours. This pack turns an object list into that relational picture.

    An object is obj(Id, cell(Row,Col), bbox(R0,C0,R1,C1), Size): its id, its
    centroid, its bounding box, and its cell count. The relations computed over a
    list of them are the reusable vocabulary of grid games: relative position,
    row/column alignment, adjacency, containment, the offset vector between two
    objects (the leader-follower / vector-guided primitive), ordinal size, and the
    nearest neighbour. object_relations_relations enumerates them all as rel(Type, IdA, IdB) so a
    caller can match a mechanic against the relation set.

    Predicates:
      object_relations_left_of/2 object_relations_right_of/2 object_relations_above/2 object_relations_below/2   -- +A, +B
      object_relations_aligned_row/2 object_relations_aligned_col/2                  -- +A, +B
      object_relations_adjacent/2                                      -- +A, +B
      object_relations_contains/2                                      -- +A, +B  (A encloses B)
      object_relations_vector/4                                        -- +A, +B, -DRow, -DCol
      object_relations_larger/2 object_relations_same_size/2                         -- +A, +B
      object_relations_nearest/4                                       -- +A, +Objects, -B, -Dist
      object_relations_relations/2                                     -- +Objects, -Relations
*/

% Declare this module and its object-relations interface.
:- module(object_relations, [
    % Relative position by centroid.
    object_relations_left_of/2, object_relations_right_of/2, object_relations_above/2, object_relations_below/2,
    % Row / column alignment.
    object_relations_aligned_row/2, object_relations_aligned_col/2,
    % Adjacency (touching or overlapping bounding boxes).
    object_relations_adjacent/2,
    % Containment (A's box encloses B's box).
    object_relations_contains/2,
    % The centroid offset vector between two objects.
    object_relations_vector/4,
    % Ordinal size.
    object_relations_larger/2, object_relations_same_size/2,
    % The nearest object to A among a set.
    object_relations_nearest/4,
    % Every relation over an object list.
    object_relations_relations/2
]).

% List helpers.
:- use_module(library(lists), [member/2, select/3]).

% obj(Id, cell(R,C), bbox(R0,C0,R1,C1), Size) is the object shape (from grid_perception).

% object_relations_centroid(+Obj, -R, -C): the object's centroid.
object_relations_centroid(obj(_, cell(R, C), _, _), R, C).
% object_relations_box(+Obj, -R0,-C0,-R1,-C1): the object's bounding box.
object_relations_box(obj(_, _, bbox(R0, C0, R1, C1), _), R0, C0, R1, C1).
% object_relations_id(+Obj, -Id): the object's id.
object_relations_id(obj(Id, _, _, _), Id).
% object_relations_size(+Obj, -Size): the object's cell count.
object_relations_size(obj(_, _, _, Size), Size).

% ---------------------------------------------------------------------------
% RELATIVE POSITION
% ---------------------------------------------------------------------------

% object_relations_left_of(+A, +B): A's centroid is strictly left of B's.
object_relations_left_of(A, B) :- object_relations_centroid(A, _, CA), object_relations_centroid(B, _, CB), CA < CB.
% object_relations_right_of(+A, +B): A is strictly right of B.
object_relations_right_of(A, B) :- object_relations_centroid(A, _, CA), object_relations_centroid(B, _, CB), CA > CB.
% object_relations_above(+A, +B): A is strictly above B.
object_relations_above(A, B) :- object_relations_centroid(A, RA, _), object_relations_centroid(B, RB, _), RA < RB.
% object_relations_below(+A, +B): A is strictly below B.
object_relations_below(A, B) :- object_relations_centroid(A, RA, _), object_relations_centroid(B, RB, _), RA > RB.

% object_relations_aligned_row(+A, +B): A and B share a centroid row.
object_relations_aligned_row(A, B) :- object_relations_centroid(A, R, _), object_relations_centroid(B, R, _).
% object_relations_aligned_col(+A, +B): A and B share a centroid column.
object_relations_aligned_col(A, B) :- object_relations_centroid(A, _, C), object_relations_centroid(B, _, C).

% ---------------------------------------------------------------------------
% ADJACENCY AND CONTAINMENT
% ---------------------------------------------------------------------------

% object_relations_adjacent(+A, +B): A's and B's bounding boxes touch or overlap (their boxes,
% expanded by one cell, intersect) — the pusher-next-to-block relation.
object_relations_adjacent(A, B) :-
    % A's bounding box.
    object_relations_box(A, AR0, AC0, AR1, AC1),
    % B's bounding box.
    object_relations_box(B, BR0, BC0, BR1, BC1),
    % Expand A by one cell and test for box intersection with B.
    AR0e is AR0 - 1, AC0e is AC0 - 1, AR1e is AR1 + 1, AC1e is AC1 + 1,
    % The expanded rows of A overlap B's rows.
    AR0e =< BR1, BR0 =< AR1e,
    % The expanded columns of A overlap B's columns.
    AC0e =< BC1, BC0 =< AC1e.

% object_relations_contains(+A, +B): A's bounding box strictly encloses B's — key-inside-lock.
object_relations_contains(A, B) :-
    % A and B are two distinct objects.
    object_relations_id(A, IdA), object_relations_id(B, IdB), IdA \== IdB,
    % A's bounding box.
    object_relations_box(A, AR0, AC0, AR1, AC1),
    % B's bounding box.
    object_relations_box(B, BR0, BC0, BR1, BC1),
    % A's box covers B's box on every side.
    AR0 =< BR0, AC0 =< BC0, BR1 =< AR1, BC1 =< AC1,
    % Strictly larger on at least one side (not the same box).
    ( AR0 < BR0 ; AC0 < BC0 ; BR1 < AR1 ; BC1 < AC1 ).

% ---------------------------------------------------------------------------
% OFFSET VECTOR AND ORDINAL SIZE
% ---------------------------------------------------------------------------

% object_relations_vector(+A, +B, -DRow, -DCol): the centroid offset from A to B — the primitive
% for leader-follower and vector-guided movement.
object_relations_vector(A, B, DRow, DCol) :-
    % The two centroids.
    object_relations_centroid(A, RA, CA), object_relations_centroid(B, RB, CB),
    % The offset from A to B in rows and columns.
    DRow is RB - RA, DCol is CB - CA.

% object_relations_larger(+A, +B): A has strictly more cells than B.
object_relations_larger(A, B) :- object_relations_size(A, SA), object_relations_size(B, SB), SA > SB.
% object_relations_same_size(+A, +B): A and B have the same cell count.
object_relations_same_size(A, B) :- object_relations_size(A, S), object_relations_size(B, S).

% ---------------------------------------------------------------------------
% NEAREST NEIGHBOUR
% ---------------------------------------------------------------------------

% object_relations_nearest(+A, +Objects, -B, -Dist): the object in Objects nearest to A by
% Manhattan distance between centroids (A itself is excluded).
object_relations_nearest(A, Objects, B, Dist) :-
    % A's own id, so it can be excluded from the search.
    object_relations_id(A, IdA),
    % Pair every other object with its Manhattan distance from A.
    findall(D - Obj,
        ( member(Obj, Objects), object_relations_id(Obj, IdO), IdO \== IdA,
          object_relations_centroid(A, RA, CA), object_relations_centroid(Obj, RO, CO),
          D is abs(RA - RO) + abs(CA - CO) ),
        Pairs),
    % There is at least one other object.
    Pairs \== [],
    % Sort by distance and take the nearest as B.
    keysort(Pairs, [Dist - B | _]).

% ---------------------------------------------------------------------------
% THE FULL RELATION SET
% ---------------------------------------------------------------------------

% object_relations_relations(+Objects, -Relations): every relation over the object list as
% rel(Type, IdA, IdB) (or rel(vector, IdA, IdB, DRow, DCol) for offsets). This is
% the structured description a mechanic is matched against.
object_relations_relations(Objects, Relations) :-
    % Collect every relation that holds over the object list.
    findall(Rel, object_relations_one_relation(Objects, Rel), Relations).

% object_relations_one_relation(+Objects, -Rel): one relation between a distinct ordered pair.
object_relations_one_relation(Objects, Rel) :-
    % A distinct ordered pair of objects.
    member(A, Objects), member(B, Objects),
    % The two objects are different.
    object_relations_id(A, IdA), object_relations_id(B, IdB), IdA \== IdB,
    % Enumerate the relation types that hold for (A, B).
    ( object_relations_left_of(A, B),      Rel = rel(left_of, IdA, IdB)
    % A is above B.
    ; object_relations_above(A, B),        Rel = rel(above, IdA, IdB)
    % A and B share a centroid row.
    ; object_relations_aligned_row(A, B),  Rel = rel(aligned_row, IdA, IdB)
    % A and B share a centroid column.
    ; object_relations_aligned_col(A, B),  Rel = rel(aligned_col, IdA, IdB)
    % A is adjacent to B.
    ; object_relations_adjacent(A, B),     Rel = rel(adjacent, IdA, IdB)
    % A contains B.
    ; object_relations_contains(A, B),     Rel = rel(contains, IdA, IdB)
    % A is larger than B.
    ; object_relations_larger(A, B),       Rel = rel(larger, IdA, IdB)
    % The offset vector from A to B.
    ; object_relations_vector(A, B, DR, DC), Rel = rel(vector, IdA, IdB, DR, DC)
    ).
