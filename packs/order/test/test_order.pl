% test_order.pl - PLUnit tests for the order pack (Layer 90: od_* predicates).
:- use_module('../prolog/order').

% Helper: build obj(Color, Cells) from color and list of R-C pairs.
make_obj(Color, RCList, obj(Color, Cells)) :-
    maplist([R-C, r(R,C)]>>true, RCList, Cells).

% Tests for order_centroid/3

:- begin_tests(order_centroid).

test(single_cell) :-
    make_obj(1, [2-3], Obj),
    order_centroid(Obj, CR, CC),
    CR =:= 2, CC =:= 3.

test(two_cells_floor) :-
    make_obj(2, [0-0, 3-3], Obj),
    order_centroid(Obj, CR, CC),
    CR =:= 1, CC =:= 1.

test(four_cells) :-
    make_obj(3, [0-0, 0-2, 2-0, 2-2], Obj),
    order_centroid(Obj, CR, CC),
    CR =:= 1, CC =:= 1.

:- end_tests(order_centroid).

% Tests for order_sort_row/2

:- begin_tests(order_sort_row).

test(already_sorted) :-
    make_obj(1, [0-0], O1), make_obj(2, [2-0], O2), make_obj(3, [4-0], O3),
    order_sort_row([O1, O2, O3], [O1, O2, O3]).

test(reverse_order) :-
    make_obj(1, [4-0], O1), make_obj(2, [2-0], O2), make_obj(3, [0-0], O3),
    order_sort_row([O1, O2, O3], [O3, O2, O1]).

test(single_object) :-
    make_obj(1, [1-1], O),
    order_sort_row([O], [O]).

:- end_tests(order_sort_row).

% Tests for order_sort_col/2

:- begin_tests(order_sort_col).

test(already_sorted) :-
    make_obj(1, [0-0], O1), make_obj(2, [0-2], O2), make_obj(3, [0-4], O3),
    order_sort_col([O1, O2, O3], [O1, O2, O3]).

test(reverse_order) :-
    make_obj(1, [0-4], O1), make_obj(2, [0-2], O2), make_obj(3, [0-0], O3),
    order_sort_col([O1, O2, O3], [O3, O2, O1]).

test(single_object) :-
    make_obj(1, [0-5], O),
    order_sort_col([O], [O]).

:- end_tests(order_sort_col).

% Tests for order_reading_order/2

:- begin_tests(order_reading_order).

test(reading_order_rows_then_cols) :-
    make_obj(1, [0-2], O1), make_obj(2, [0-0], O2), make_obj(3, [1-1], O3),
    order_reading_order([O1, O2, O3], [O2, O1, O3]).

test(single_row) :-
    make_obj(1, [0-3], O1), make_obj(2, [0-1], O2),
    order_reading_order([O1, O2], [O2, O1]).

test(single_object) :-
    make_obj(1, [2-3], O),
    order_reading_order([O], [O]).

:- end_tests(order_reading_order).

% Tests for order_sort_color/2

:- begin_tests(order_sort_color).

test(sorting_colors_asc) :-
    make_obj(3, [0-0], O3), make_obj(1, [1-0], O1), make_obj(2, [2-0], O2),
    order_sort_color([O3, O1, O2], [O1, O2, O3]).

test(already_sorted_color) :-
    make_obj(1, [0-0], O1), make_obj(2, [1-0], O2),
    order_sort_color([O1, O2], [O1, O2]).

test(single_object_color) :-
    make_obj(5, [0-0], O),
    order_sort_color([O], [O]).

:- end_tests(order_sort_color).

% Tests for order_topmost/2

:- begin_tests(order_topmost).

test(topmost_first) :-
    make_obj(1, [0-0], O1), make_obj(2, [3-0], O2),
    order_topmost([O1, O2], O1).

test(topmost_last) :-
    make_obj(1, [5-0], O1), make_obj(2, [1-0], O2),
    order_topmost([O1, O2], O2).

test(topmost_single) :-
    make_obj(1, [2-2], O),
    order_topmost([O], O).

:- end_tests(order_topmost).

% Tests for order_bottommost/2

:- begin_tests(order_bottommost).

test(bottommost_last) :-
    make_obj(1, [0-0], O1), make_obj(2, [4-0], O2),
    order_bottommost([O1, O2], O2).

test(bottommost_first) :-
    make_obj(1, [6-0], O1), make_obj(2, [1-0], O2),
    order_bottommost([O1, O2], O1).

test(bottommost_single) :-
    make_obj(1, [3-3], O),
    order_bottommost([O], O).

:- end_tests(order_bottommost).

% Tests for order_leftmost/2

:- begin_tests(order_leftmost).

test(leftmost_first) :-
    make_obj(1, [0-0], O1), make_obj(2, [0-5], O2),
    order_leftmost([O1, O2], O1).

test(leftmost_second) :-
    make_obj(1, [0-7], O1), make_obj(2, [0-2], O2),
    order_leftmost([O1, O2], O2).

test(leftmost_single) :-
    make_obj(1, [0-4], O),
    order_leftmost([O], O).

:- end_tests(order_leftmost).

% Tests for order_rightmost/2

:- begin_tests(order_rightmost).

test(rightmost_second) :-
    make_obj(1, [0-1], O1), make_obj(2, [0-8], O2),
    order_rightmost([O1, O2], O2).

test(rightmost_first) :-
    make_obj(1, [0-9], O1), make_obj(2, [0-3], O2),
    order_rightmost([O1, O2], O1).

test(rightmost_single) :-
    make_obj(1, [0-6], O),
    order_rightmost([O], O).

:- end_tests(order_rightmost).

% Tests for order_nth_row/3

:- begin_tests(order_nth_row).

test(first_in_row_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [3-0], O2), make_obj(3, [6-0], O3),
    order_nth_row([O3, O1, O2], 1, O1).

test(second_in_row_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [3-0], O2), make_obj(3, [6-0], O3),
    order_nth_row([O3, O1, O2], 2, O2).

test(last_in_row_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [3-0], O2), make_obj(3, [6-0], O3),
    order_nth_row([O3, O1, O2], 3, O3).

:- end_tests(order_nth_row).

% Tests for order_nth_col/3

:- begin_tests(order_nth_col).

test(first_in_col_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [0-3], O2), make_obj(3, [0-6], O3),
    order_nth_col([O3, O1, O2], 1, O1).

test(second_in_col_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [0-3], O2), make_obj(3, [0-6], O3),
    order_nth_col([O3, O1, O2], 2, O2).

test(last_in_col_order) :-
    make_obj(1, [0-0], O1), make_obj(2, [0-3], O2), make_obj(3, [0-6], O3),
    order_nth_col([O3, O1, O2], 3, O3).

:- end_tests(order_nth_col).

% Tests for order_nearest/4

:- begin_tests(order_nearest).

test(nearest_to_origin) :-
    make_obj(1, [0-0], O1), make_obj(2, [5-5], O2),
    order_nearest([O1, O2], 0, 0, O1).

test(nearest_to_far_point) :-
    make_obj(1, [0-0], O1), make_obj(2, [9-9], O2),
    order_nearest([O1, O2], 8, 8, O2).

test(nearest_single) :-
    make_obj(1, [3-3], O),
    order_nearest([O], 0, 0, O).

:- end_tests(order_nearest).

% Tests for order_farthest/4

:- begin_tests(order_farthest).

test(farthest_from_origin) :-
    make_obj(1, [0-0], O1), make_obj(2, [8-8], O2),
    order_farthest([O1, O2], 0, 0, O2).

test(farthest_from_far_point) :-
    make_obj(1, [0-0], O1), make_obj(2, [9-9], O2),
    order_farthest([O1, O2], 9, 9, O1).

test(farthest_single) :-
    make_obj(1, [5-5], O),
    order_farthest([O], 0, 0, O).

:- end_tests(order_farthest).

% Tests for order_rank_row/3

:- begin_tests(order_rank_row).

test(rank_1_is_topmost) :-
    make_obj(1, [0-0], O1), make_obj(2, [5-0], O2), make_obj(3, [9-0], O3),
    order_rank_row([O3, O1, O2], O1, R),
    R =:= 1.

test(rank_2_is_middle) :-
    make_obj(1, [0-0], O1), make_obj(2, [5-0], O2), make_obj(3, [9-0], O3),
    order_rank_row([O3, O1, O2], O2, R),
    R =:= 2.

test(rank_3_is_bottommost) :-
    make_obj(1, [0-0], O1), make_obj(2, [5-0], O2), make_obj(3, [9-0], O3),
    order_rank_row([O3, O1, O2], O3, R),
    R =:= 3.

:- end_tests(order_rank_row).
