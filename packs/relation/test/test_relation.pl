% PLUnit tests for the relation pack (rl_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(relation)).

% Region fixtures.

% A 3-cell vertical bar at column 2, rows 0-2.
bar_v(R) :- R = [r(0,2), r(1,2), r(2,2)].

% A 3-cell horizontal bar at row 5, cols 1-3.
bar_h(R) :- R = [r(5,1), r(5,2), r(5,3)].

% A small 2x2 block at rows 0-1, cols 0-1.
block_a(R) :- R = [r(0,0), r(0,1), r(1,0), r(1,1)].

% A small 2x2 block at rows 3-4, cols 0-1.
block_b(R) :- R = [r(3,0), r(3,1), r(4,0), r(4,1)].

% A small 2x2 block at rows 0-1, cols 3-4.
block_c(R) :- R = [r(0,3), r(0,4), r(1,3), r(1,4)].

% A block adjacent to block_a (shares border at row 1/2, col 0-1).
block_adj(R) :- R = [r(2,0), r(2,1)].

% A single cell.
dot(R) :- R = [r(4,4)].

% A large outer region surrounding a small inner region.
outer(R) :- R = [r(0,0),r(0,1),r(0,2),r(1,0),r(1,2),r(2,0),r(2,1),r(2,2)].
inner(R) :- R = [r(1,1)].

:- begin_tests(relation_above).

test(above_yes) :-
    block_a(A),
    block_b(B),
    rl_above(A, B).

test(above_no, [fail]) :-
    block_a(A),
    block_b(B),
    rl_above(B, A).

test(above_adjacent_fails, [fail]) :-
    % Block at rows 0-1 and block at rows 1-2 overlap in row 1; not "above".
    A = [r(0,0), r(1,0)],
    B = [r(1,0), r(2,0)],
    rl_above(A, B).

:- end_tests(relation_above).

:- begin_tests(relation_below).

test(below_yes) :-
    block_a(A),
    block_b(B),
    rl_below(B, A).

test(below_no, [fail]) :-
    block_a(A),
    block_b(B),
    rl_below(A, B).

:- end_tests(relation_below).

:- begin_tests(relation_left_of).

test(left_yes) :-
    block_a(A),
    block_c(C),
    rl_left_of(A, C).

test(left_no, [fail]) :-
    block_a(A),
    block_c(C),
    rl_left_of(C, A).

:- end_tests(relation_left_of).

:- begin_tests(relation_right_of).

test(right_yes) :-
    block_a(A),
    block_c(C),
    rl_right_of(C, A).

test(right_no, [fail]) :-
    block_a(A),
    block_c(C),
    rl_right_of(A, C).

:- end_tests(relation_right_of).

:- begin_tests(relation_adjacent).

test(adjacent_yes) :-
    block_a(A),
    block_adj(Adj),
    rl_adjacent(A, Adj).

test(adjacent_symmetric) :-
    block_a(A),
    block_adj(Adj),
    rl_adjacent(Adj, A).

test(adjacent_no, [fail]) :-
    block_a(A),
    block_b(B),
    % block_a rows 0-1, block_b rows 3-4; gap at row 2; not adjacent.
    rl_adjacent(A, B).

test(adjacent_horizontal) :-
    A = [r(0,0), r(0,1)],
    B = [r(0,2)],
    rl_adjacent(A, B).

:- end_tests(relation_adjacent).

:- begin_tests(relation_distance).

test(distance_adjacent) :-
    A = [r(0,0)],
    B = [r(0,1)],
    rl_distance(A, B, D),
    D =:= 1.

test(distance_diagonal) :-
    A = [r(0,0)],
    B = [r(3,4)],
    rl_distance(A, B, D),
    D =:= 7.

test(distance_overlap) :-
    A = [r(1,1), r(1,2)],
    B = [r(1,2), r(1,3)],
    rl_distance(A, B, D),
    D =:= 0.

test(distance_two_regions) :-
    block_a(A),
    block_b(B),
    % block_a max row 1, block_b min row 3; gap = 2 rows (3 - 1 = 2), 0 in col.
    rl_distance(A, B, D),
    D =:= 2.

:- end_tests(relation_distance).

:- begin_tests(relation_contained_bbox).

test(contained_yes) :-
    inner(I),
    outer(O),
    rl_contained_bbox(I, O).

test(contained_self) :-
    block_a(A),
    rl_contained_bbox(A, A).

test(contained_no, [fail]) :-
    block_a(A),
    block_c(C),
    rl_contained_bbox(A, C).

:- end_tests(relation_contained_bbox).

:- begin_tests(relation_overlap).

test(overlap_yes) :-
    A = [r(0,0), r(0,1), r(1,0)],
    B = [r(0,1), r(1,1)],
    rl_overlap(A, B).

test(overlap_no, [fail]) :-
    block_a(A),
    block_b(B),
    rl_overlap(A, B).

test(overlap_self) :-
    block_a(A),
    rl_overlap(A, A).

:- end_tests(relation_overlap).

:- begin_tests(relation_disjoint).

test(disjoint_yes) :-
    block_a(A),
    block_b(B),
    rl_disjoint(A, B).

test(disjoint_no, [fail]) :-
    A = [r(0,0), r(0,1)],
    B = [r(0,1), r(0,2)],
    rl_disjoint(A, B).

:- end_tests(relation_disjoint).

:- begin_tests(relation_same_row).

test(same_row_yes) :-
    A = [r(2,0), r(2,1)],
    B = [r(2,5), r(3,5)],
    rl_same_row(A, B).

test(same_row_no, [fail]) :-
    block_a(A),
    block_b(B),
    rl_same_row(A, B).

:- end_tests(relation_same_row).

:- begin_tests(relation_same_col).

test(same_col_yes) :-
    bar_v(V),
    A = [r(5,2)],
    rl_same_col(V, A).

test(same_col_no, [fail]) :-
    block_a(A),
    block_c(C),
    rl_same_col(A, C).

:- end_tests(relation_same_col).

:- begin_tests(relation_centroid).

test(centroid_single) :-
    rl_centroid([r(4,6)], R, C),
    R =:= 4,
    C =:= 6.

test(centroid_bar_v) :-
    bar_v(B),
    % Rows [0,1,2] avg = 1; Cols [2,2,2] avg = 2.
    rl_centroid(B, R, C),
    R =:= 1,
    C =:= 2.

test(centroid_block_a) :-
    block_a(A),
    % Rows [0,0,1,1] avg = 0; Cols [0,1,0,1] avg = 0.
    rl_centroid(A, R, C),
    R =:= 0,
    C =:= 0.

:- end_tests(relation_centroid).

:- begin_tests(relation_offset).

test(offset_basic) :-
    A = [r(0,0)],
    B = [r(3,4)],
    rl_offset(A, B, DR, DC),
    DR =:= 3,
    DC =:= 4.

test(offset_negative) :-
    A = [r(5,5)],
    B = [r(2,1)],
    rl_offset(A, B, DR, DC),
    DR =:= -3,
    DC =:= -4.

test(offset_zero) :-
    A = [r(2,2)],
    rl_offset(A, A, DR, DC),
    DR =:= 0,
    DC =:= 0.

:- end_tests(relation_offset).

:- begin_tests(relation_direction).

test(direction_above) :-
    A = [r(5,5)],
    B = [r(2,5)],
    rl_direction(A, B, Dir),
    Dir = above.

test(direction_below) :-
    A = [r(2,5)],
    B = [r(5,5)],
    rl_direction(A, B, Dir),
    Dir = below.

test(direction_left) :-
    A = [r(2,5)],
    B = [r(2,1)],
    rl_direction(A, B, Dir),
    Dir = left.

test(direction_right) :-
    A = [r(2,1)],
    B = [r(2,5)],
    rl_direction(A, B, Dir),
    Dir = right.

test(direction_diagonal_above) :-
    % DR = -3, DC = 1 -> abs(DR) > abs(DC) -> above
    A = [r(5,0)],
    B = [r(2,1)],
    rl_direction(A, B, Dir),
    Dir = above.

test(direction_diagonal_right) :-
    % DR = 1, DC = 3 -> abs(DC) > abs(DR) -> right
    A = [r(0,0)],
    B = [r(1,3)],
    rl_direction(A, B, Dir),
    Dir = right.

:- end_tests(relation_direction).
