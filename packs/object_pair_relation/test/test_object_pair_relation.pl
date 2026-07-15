:- use_module('../prolog/object_pair_relation').

% Test objects used across multiple tests:
%   A    = obj(a, [r(0,0)])                          single cell at origin
%   B    = obj(b, [r(0,1)])                          4-adjacent to A (east)
%   C    = obj(c, [r(1,1)])                          8-adj to A (SE), 4-adj to B
%   D    = obj(d, [r(0,3)])                          not adjacent to A or B
%   N    = obj(n, [r(0,0)])                          same cell as A, different color
%   Hbar = obj(h, [r(2,0),r(2,1),r(2,2)])           horizontal bar
%   Vbar = obj(v, [r(0,2),r(1,2),r(2,2)])           vertical bar at col 2
%   Big  = obj(g, [...])                             3x3 block rows 1-3, cols 1-3
%   Tiny = obj(t, [r(2,2)])                          cell inside Big

:- begin_tests(object_pair_relation).

% object_pair_relation_overlap/2 tests
test(overlap_adj_false) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    \+ object_pair_relation_overlap(A, B).

test(overlap_same_cell_diff_color) :-
    A = obj(a, [r(0,0)]), N = obj(n, [r(0,0)]),
    object_pair_relation_overlap(A, N).

test(overlap_shared_one_cell) :-
    P = obj(p, [r(0,0), r(0,1)]),
    Q = obj(q, [r(0,1), r(0,2)]),
    object_pair_relation_overlap(P, Q).

test(overlap_disjoint_false) :-
    A = obj(a, [r(0,0)]), D = obj(d, [r(5,5)]),
    \+ object_pair_relation_overlap(A, D).

test(overlap_subset) :-
    Big = obj(g, [r(1,1),r(1,2),r(1,3),r(2,1),r(2,2),r(2,3),r(3,1),r(3,2),r(3,3)]),
    Tiny = obj(t, [r(2,2)]),
    object_pair_relation_overlap(Big, Tiny).

% object_pair_relation_shared_cells/3 tests
test(shared_cells_one) :-
    P = obj(p, [r(0,0), r(0,1)]),
    Q = obj(q, [r(0,1), r(0,2)]),
    object_pair_relation_shared_cells(P, Q, Shared),
    Shared = [r(0,1)].

test(shared_cells_empty) :-
    A = obj(a, [r(0,0)]),
    D = obj(d, [r(5,5)]),
    object_pair_relation_shared_cells(A, D, Shared),
    Shared = [].

test(shared_cells_all) :-
    P = obj(p, [r(1,1), r(1,2)]),
    Q = obj(q, [r(1,1), r(1,2)]),
    object_pair_relation_shared_cells(P, Q, Shared),
    msort(Shared, [r(1,1), r(1,2)]).

test(shared_cells_subset) :-
    Big = obj(g, [r(1,1),r(1,2),r(1,3),r(2,1),r(2,2),r(2,3),r(3,1),r(3,2),r(3,3)]),
    Tiny = obj(t, [r(2,2)]),
    object_pair_relation_shared_cells(Big, Tiny, Shared),
    Shared = [r(2,2)].

% object_pair_relation_n_shared/3 tests
test(n_shared_one) :-
    P = obj(p, [r(0,0), r(0,1)]),
    Q = obj(q, [r(0,1), r(0,2)]),
    object_pair_relation_n_shared(P, Q, N),
    N =:= 1.

test(n_shared_zero) :-
    A = obj(a, [r(0,0)]), D = obj(d, [r(5,5)]),
    object_pair_relation_n_shared(A, D, N),
    N =:= 0.

test(n_shared_two) :-
    P = obj(p, [r(0,0), r(0,1), r(0,2)]),
    Q = obj(q, [r(0,0), r(0,1)]),
    object_pair_relation_n_shared(P, Q, N),
    N =:= 2.

% object_pair_relation_touch4/2 tests
test(touch4_east) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    object_pair_relation_touch4(A, B).

test(touch4_south) :-
    A = obj(a, [r(0,0)]), S = obj(s, [r(1,0)]),
    object_pair_relation_touch4(A, S).

test(touch4_not_diagonal) :-
    A = obj(a, [r(0,0)]), C = obj(c, [r(1,1)]),
    \+ object_pair_relation_touch4(A, C).

test(touch4_not_far) :-
    A = obj(a, [r(0,0)]), D = obj(d, [r(0,2)]),
    \+ object_pair_relation_touch4(A, D).

test(touch4_not_overlapping) :-
    A = obj(a, [r(0,0)]), N = obj(n, [r(0,0)]),
    \+ object_pair_relation_touch4(A, N).

test(touch4_bar_to_point) :-
    Hbar = obj(h, [r(2,0),r(2,1),r(2,2)]),
    Above = obj(x, [r(1,0)]),
    object_pair_relation_touch4(Hbar, Above).

% object_pair_relation_touch8/2 tests
test(touch8_diagonal) :-
    A = obj(a, [r(0,0)]), C = obj(c, [r(1,1)]),
    object_pair_relation_touch8(A, C).

test(touch8_also_touch4) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    object_pair_relation_touch8(A, B).

test(touch8_not_far) :-
    A = obj(a, [r(0,0)]), D = obj(d, [r(0,2)]),
    \+ object_pair_relation_touch8(A, D).

test(touch8_not_overlapping) :-
    A = obj(a, [r(0,0)]), N = obj(n, [r(0,0)]),
    \+ object_pair_relation_touch8(A, N).

test(touch8_sw_diagonal) :-
    A = obj(a, [r(1,1)]), SW = obj(s, [r(2,0)]),
    object_pair_relation_touch8(A, SW).

% object_pair_relation_contains/2 tests
test(contains_tiny_in_big) :-
    Big = obj(g, [r(1,1),r(1,2),r(1,3),r(2,1),r(2,2),r(2,3),r(3,1),r(3,2),r(3,3)]),
    Tiny = obj(t, [r(2,2)]),
    object_pair_relation_contains(Big, Tiny).

test(contains_not_big_in_tiny) :-
    Big = obj(g, [r(1,1),r(1,2),r(1,3),r(2,1),r(2,2),r(2,3),r(3,1),r(3,2),r(3,3)]),
    Tiny = obj(t, [r(2,2)]),
    \+ object_pair_relation_contains(Tiny, Big).

test(contains_self) :-
    Hbar = obj(h, [r(0,0),r(0,1),r(0,2)]),
    object_pair_relation_contains(Hbar, Hbar).

test(contains_partial_false) :-
    P = obj(p, [r(0,0), r(0,1)]),
    Q = obj(q, [r(0,1), r(0,2)]),
    \+ object_pair_relation_contains(P, Q).

test(contains_empty_true) :-
    A = obj(a, [r(0,0)]),
    Empty = obj(e, []),
    object_pair_relation_contains(A, Empty).

% object_pair_relation_union_cells/3 tests
test(union_disjoint) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    object_pair_relation_union_cells(A, B, Union),
    msort(Union, [r(0,0), r(0,1)]).

test(union_overlapping) :-
    P = obj(p, [r(0,0), r(0,1)]),
    Q = obj(q, [r(0,1), r(0,2)]),
    object_pair_relation_union_cells(P, Q, Union),
    Union = [r(0,0), r(0,1), r(0,2)].

test(union_size) :-
    Hbar = obj(h, [r(0,0),r(0,1),r(0,2)]),
    Vbar = obj(v, [r(0,0),r(1,0),r(2,0)]),
    object_pair_relation_union_cells(Hbar, Vbar, Union),
    length(Union, L), L =:= 5.

% object_pair_relation_dist/3 tests
test(dist_adjacent_east) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    object_pair_relation_dist(A, B, D),
    D =:= 1.0.

test(dist_zero_same) :-
    A = obj(a, [r(2,3)]), N = obj(n, [r(2,3)]),
    object_pair_relation_dist(A, N, D),
    D =:= 0.0.

test(dist_diagonal) :-
    A = obj(a, [r(0,0)]), C = obj(c, [r(1,1)]),
    object_pair_relation_dist(A, C, D),
    abs(D - sqrt(2.0)) < 0.0001.

test(dist_bar_centroid) :-
    Hbar = obj(h, [r(0,0),r(0,2),r(0,4)]),
    Vbar = obj(v, [r(0,2),r(2,2),r(4,2)]),
    object_pair_relation_dist(Hbar, Vbar, D),
    % centroids: (0.0, 2.0) and (2.0, 2.0); dist = 2.0
    D =:= 2.0.

% object_pair_relation_manhattan/3 tests
test(manhattan_adjacent) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    object_pair_relation_manhattan(A, B, D),
    D =:= 1.0.

test(manhattan_diagonal) :-
    A = obj(a, [r(0,0)]), C = obj(c, [r(3,4)]),
    object_pair_relation_manhattan(A, C, D),
    D =:= 7.0.

test(manhattan_same) :-
    A = obj(a, [r(2,2)]), N = obj(n, [r(2,2)]),
    object_pair_relation_manhattan(A, N, D),
    D =:= 0.0.

% object_pair_relation_direction/3 tests
test(direction_east) :-
    A = obj(a, [r(2,0)]), E = obj(e, [r(2,5)]),
    object_pair_relation_direction(A, E, Dir), Dir = e.

test(direction_west) :-
    A = obj(a, [r(2,5)]), W = obj(w, [r(2,0)]),
    object_pair_relation_direction(A, W, Dir), Dir = w.

test(direction_south) :-
    A = obj(a, [r(0,2)]), S = obj(s, [r(4,2)]),
    object_pair_relation_direction(A, S, Dir), Dir = s.

test(direction_north) :-
    A = obj(a, [r(4,2)]), N = obj(n, [r(0,2)]),
    object_pair_relation_direction(A, N, Dir), Dir = n.

test(direction_se) :-
    A = obj(a, [r(0,0)]), SE = obj(x, [r(2,2)]),
    object_pair_relation_direction(A, SE, Dir), Dir = se.

test(direction_sw) :-
    A = obj(a, [r(0,2)]), SW = obj(x, [r(2,0)]),
    object_pair_relation_direction(A, SW, Dir), Dir = sw.

test(direction_ne) :-
    A = obj(a, [r(2,0)]), NE = obj(x, [r(0,2)]),
    object_pair_relation_direction(A, NE, Dir), Dir = ne.

test(direction_nw) :-
    A = obj(a, [r(2,2)]), NW = obj(x, [r(0,0)]),
    object_pair_relation_direction(A, NW, Dir), Dir = nw.

test(direction_same) :-
    A = obj(a, [r(2,2)]), B = obj(b, [r(2,2)]),
    object_pair_relation_direction(A, B, Dir), Dir = same.

% object_pair_relation_aligned_h/2 tests
test(aligned_h_same_row) :-
    A = obj(a, [r(3,0)]), B = obj(b, [r(3,5)]),
    object_pair_relation_aligned_h(A, B).

test(aligned_h_bar_centroid) :-
    Hbar = obj(h, [r(2,0),r(2,1),r(2,2)]),
    Dot  = obj(d, [r(2,9)]),
    object_pair_relation_aligned_h(Hbar, Dot).

test(aligned_h_false) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(1,0)]),
    \+ object_pair_relation_aligned_h(A, B).

% object_pair_relation_aligned_v/2 tests
test(aligned_v_same_col) :-
    A = obj(a, [r(0,4)]), B = obj(b, [r(7,4)]),
    object_pair_relation_aligned_v(A, B).

test(aligned_v_bar_centroid) :-
    Vbar = obj(v, [r(0,3),r(1,3),r(2,3)]),
    Dot  = obj(d, [r(8,3)]),
    object_pair_relation_aligned_v(Vbar, Dot).

test(aligned_v_false) :-
    A = obj(a, [r(0,0)]), B = obj(b, [r(0,1)]),
    \+ object_pair_relation_aligned_v(A, B).

% object_pair_relation_gap_rows/3 tests
test(gap_rows_two_rows) :-
    Top = obj(t, [r(0,0)]), Bot = obj(b, [r(3,0)]),
    object_pair_relation_gap_rows(Top, Bot, G),
    % bbox top: rows 0-0; bbox bot: rows 3-3; gap = 3-0-1 = 2
    G =:= 2.

test(gap_rows_touching) :-
    Top = obj(t, [r(0,0)]), Bot = obj(b, [r(1,0)]),
    object_pair_relation_gap_rows(Top, Bot, G),
    % bboxes at 0-0 and 1-1; gap = max(0, max(0,1)-min(0,1)-1) = max(0,1-0-1)=0
    G =:= 0.

test(gap_rows_overlap) :-
    P = obj(p, [r(1,0),r(2,0)]), Q = obj(q, [r(2,0),r(3,0)]),
    object_pair_relation_gap_rows(P, Q, G),
    G =:= 0.

test(gap_rows_bars) :-
    Top = obj(t, [r(0,0),r(0,1),r(0,2)]),
    Bot = obj(b, [r(4,0),r(4,1),r(4,2)]),
    object_pair_relation_gap_rows(Top, Bot, G),
    % bboxes: top rows 0-0, bot rows 4-4; gap = max(0, 4-0-1) = 3
    G =:= 3.

% object_pair_relation_gap_cols/3 tests
test(gap_cols_three_cols) :-
    Left  = obj(l, [r(0,0)]), Right = obj(r, [r(0,4)]),
    object_pair_relation_gap_cols(Left, Right, G),
    % bboxes: left cols 0-0, right cols 4-4; gap = 4-0-1 = 3
    G =:= 3.

test(gap_cols_touching) :-
    Left  = obj(l, [r(0,0)]), Right = obj(r, [r(0,1)]),
    object_pair_relation_gap_cols(Left, Right, G),
    G =:= 0.

test(gap_cols_overlap) :-
    P = obj(p, [r(0,1),r(0,2)]), Q = obj(q, [r(0,2),r(0,3)]),
    object_pair_relation_gap_cols(P, Q, G),
    G =:= 0.

test(gap_cols_bars) :-
    Left  = obj(l, [r(0,0),r(1,0),r(2,0)]),
    Right = obj(r, [r(0,5),r(1,5),r(2,5)]),
    object_pair_relation_gap_cols(Left, Right, G),
    % bboxes: left cols 0-0, right cols 5-5; gap = 5-0-1 = 4
    G =:= 4.

:- end_tests(object_pair_relation).
