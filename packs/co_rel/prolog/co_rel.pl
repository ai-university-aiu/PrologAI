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
    nearest neighbour. cr_relations enumerates them all as rel(Type, IdA, IdB) so a
    caller can match a mechanic against the relation set.

    Predicates:
      cr_left_of/2 cr_right_of/2 cr_above/2 cr_below/2   -- +A, +B
      cr_aligned_row/2 cr_aligned_col/2                  -- +A, +B
      cr_adjacent/2                                      -- +A, +B
      cr_contains/2                                      -- +A, +B  (A encloses B)
      cr_vector/4                                        -- +A, +B, -DRow, -DCol
      cr_larger/2 cr_same_size/2                         -- +A, +B
      cr_nearest/4                                       -- +A, +Objects, -B, -Dist
      cr_relations/2                                     -- +Objects, -Relations
*/

% Declare this module and its object-relations interface.
:- module(co_rel, [
    % Relative position by centroid.
    cr_left_of/2, cr_right_of/2, cr_above/2, cr_below/2,
    % Row / column alignment.
    cr_aligned_row/2, cr_aligned_col/2,
    % Adjacency (touching or overlapping bounding boxes).
    cr_adjacent/2,
    % Containment (A's box encloses B's box).
    cr_contains/2,
    % The centroid offset vector between two objects.
    cr_vector/4,
    % Ordinal size.
    cr_larger/2, cr_same_size/2,
    % The nearest object to A among a set.
    cr_nearest/4,
    % Every relation over an object list.
    cr_relations/2
]).

% List helpers.
:- use_module(library(lists), [member/2, select/3]).

% obj(Id, cell(R,C), bbox(R0,C0,R1,C1), Size) is the object shape (from co_see).

% cr_centroid(+Obj, -R, -C): the object's centroid.
cr_centroid(obj(_, cell(R, C), _, _), R, C).
% cr_box(+Obj, -R0,-C0,-R1,-C1): the object's bounding box.
cr_box(obj(_, _, bbox(R0, C0, R1, C1), _), R0, C0, R1, C1).
% cr_id(+Obj, -Id): the object's id.
cr_id(obj(Id, _, _, _), Id).
% cr_size(+Obj, -Size): the object's cell count.
cr_size(obj(_, _, _, Size), Size).

% ---------------------------------------------------------------------------
% RELATIVE POSITION
% ---------------------------------------------------------------------------

% cr_left_of(+A, +B): A's centroid is strictly left of B's.
cr_left_of(A, B) :- cr_centroid(A, _, CA), cr_centroid(B, _, CB), CA < CB.
% cr_right_of(+A, +B): A is strictly right of B.
cr_right_of(A, B) :- cr_centroid(A, _, CA), cr_centroid(B, _, CB), CA > CB.
% cr_above(+A, +B): A is strictly above B.
cr_above(A, B) :- cr_centroid(A, RA, _), cr_centroid(B, RB, _), RA < RB.
% cr_below(+A, +B): A is strictly below B.
cr_below(A, B) :- cr_centroid(A, RA, _), cr_centroid(B, RB, _), RA > RB.

% cr_aligned_row(+A, +B): A and B share a centroid row.
cr_aligned_row(A, B) :- cr_centroid(A, R, _), cr_centroid(B, R, _).
% cr_aligned_col(+A, +B): A and B share a centroid column.
cr_aligned_col(A, B) :- cr_centroid(A, _, C), cr_centroid(B, _, C).

% ---------------------------------------------------------------------------
% ADJACENCY AND CONTAINMENT
% ---------------------------------------------------------------------------

% cr_adjacent(+A, +B): A's and B's bounding boxes touch or overlap (their boxes,
% expanded by one cell, intersect) — the pusher-next-to-block relation.
cr_adjacent(A, B) :-
    % A's bounding box.
    cr_box(A, AR0, AC0, AR1, AC1),
    % B's bounding box.
    cr_box(B, BR0, BC0, BR1, BC1),
    % Expand A by one cell and test for box intersection with B.
    AR0e is AR0 - 1, AC0e is AC0 - 1, AR1e is AR1 + 1, AC1e is AC1 + 1,
    % The expanded rows of A overlap B's rows.
    AR0e =< BR1, BR0 =< AR1e,
    % The expanded columns of A overlap B's columns.
    AC0e =< BC1, BC0 =< AC1e.

% cr_contains(+A, +B): A's bounding box strictly encloses B's — key-inside-lock.
cr_contains(A, B) :-
    % A and B are two distinct objects.
    cr_id(A, IdA), cr_id(B, IdB), IdA \== IdB,
    % A's bounding box.
    cr_box(A, AR0, AC0, AR1, AC1),
    % B's bounding box.
    cr_box(B, BR0, BC0, BR1, BC1),
    % A's box covers B's box on every side.
    AR0 =< BR0, AC0 =< BC0, BR1 =< AR1, BC1 =< AC1,
    % Strictly larger on at least one side (not the same box).
    ( AR0 < BR0 ; AC0 < BC0 ; BR1 < AR1 ; BC1 < AC1 ).

% ---------------------------------------------------------------------------
% OFFSET VECTOR AND ORDINAL SIZE
% ---------------------------------------------------------------------------

% cr_vector(+A, +B, -DRow, -DCol): the centroid offset from A to B — the primitive
% for leader-follower and vector-guided movement.
cr_vector(A, B, DRow, DCol) :-
    % The two centroids.
    cr_centroid(A, RA, CA), cr_centroid(B, RB, CB),
    % The offset from A to B in rows and columns.
    DRow is RB - RA, DCol is CB - CA.

% cr_larger(+A, +B): A has strictly more cells than B.
cr_larger(A, B) :- cr_size(A, SA), cr_size(B, SB), SA > SB.
% cr_same_size(+A, +B): A and B have the same cell count.
cr_same_size(A, B) :- cr_size(A, S), cr_size(B, S).

% ---------------------------------------------------------------------------
% NEAREST NEIGHBOUR
% ---------------------------------------------------------------------------

% cr_nearest(+A, +Objects, -B, -Dist): the object in Objects nearest to A by
% Manhattan distance between centroids (A itself is excluded).
cr_nearest(A, Objects, B, Dist) :-
    % A's own id, so it can be excluded from the search.
    cr_id(A, IdA),
    % Pair every other object with its Manhattan distance from A.
    findall(D - Obj,
        ( member(Obj, Objects), cr_id(Obj, IdO), IdO \== IdA,
          cr_centroid(A, RA, CA), cr_centroid(Obj, RO, CO),
          D is abs(RA - RO) + abs(CA - CO) ),
        Pairs),
    % There is at least one other object.
    Pairs \== [],
    % Sort by distance and take the nearest as B.
    keysort(Pairs, [Dist - B | _]).

% ---------------------------------------------------------------------------
% THE FULL RELATION SET
% ---------------------------------------------------------------------------

% cr_relations(+Objects, -Relations): every relation over the object list as
% rel(Type, IdA, IdB) (or rel(vector, IdA, IdB, DRow, DCol) for offsets). This is
% the structured description a mechanic is matched against.
cr_relations(Objects, Relations) :-
    % Collect every relation that holds over the object list.
    findall(Rel, cr_one_relation(Objects, Rel), Relations).

% cr_one_relation(+Objects, -Rel): one relation between a distinct ordered pair.
cr_one_relation(Objects, Rel) :-
    % A distinct ordered pair of objects.
    member(A, Objects), member(B, Objects),
    % The two objects are different.
    cr_id(A, IdA), cr_id(B, IdB), IdA \== IdB,
    % Enumerate the relation types that hold for (A, B).
    ( cr_left_of(A, B),      Rel = rel(left_of, IdA, IdB)
    % A is above B.
    ; cr_above(A, B),        Rel = rel(above, IdA, IdB)
    % A and B share a centroid row.
    ; cr_aligned_row(A, B),  Rel = rel(aligned_row, IdA, IdB)
    % A and B share a centroid column.
    ; cr_aligned_col(A, B),  Rel = rel(aligned_col, IdA, IdB)
    % A is adjacent to B.
    ; cr_adjacent(A, B),     Rel = rel(adjacent, IdA, IdB)
    % A contains B.
    ; cr_contains(A, B),     Rel = rel(contains, IdA, IdB)
    % A is larger than B.
    ; cr_larger(A, B),       Rel = rel(larger, IdA, IdB)
    % The offset vector from A to B.
    ; cr_vector(A, B, DR, DC), Rel = rel(vector, IdA, IdB, DR, DC)
    ).
