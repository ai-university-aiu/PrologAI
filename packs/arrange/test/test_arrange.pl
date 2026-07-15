:- use_module('../prolog/arrange').

:- begin_tests(arrange).

% arrange_centroid/2 tests.
test(centroid_single) :-
    arrange_centroid(obj(1, [r(4,6)]), r(4,6)).

test(centroid_hpair) :-
    arrange_centroid(obj(2, [r(0,0), r(0,2)]), r(0,1)).

test(centroid_square) :-
    arrange_centroid(obj(3, [r(0,0), r(0,1), r(1,0), r(1,1)]), r(0,0)).

% arrange_offset/3 tests.
test(offset_right) :-
    arrange_offset(obj(1, [r(0,0)]), obj(2, [r(0,3)]), r(0,3)).

test(offset_down) :-
    arrange_offset(obj(1, [r(0,2)]), obj(2, [r(4,2)]), r(4,0)).

test(offset_diagonal) :-
    arrange_offset(obj(1, [r(1,1)]), obj(2, [r(3,4)]), r(2,3)).

% arrange_row_order/2 tests.
test(row_order_above) :-
    arrange_row_order(obj(1, [r(0,0)]), obj(2, [r(3,0)])).

test(row_order_equal) :-
    arrange_row_order(obj(1, [r(2,0)]), obj(2, [r(2,5)])).

test(row_order_fail, [fail]) :-
    arrange_row_order(obj(1, [r(5,0)]), obj(2, [r(1,0)])).

% arrange_col_order/2 tests.
test(col_order_left) :-
    arrange_col_order(obj(1, [r(0,0)]), obj(2, [r(0,4)])).

test(col_order_equal) :-
    arrange_col_order(obj(1, [r(0,3)]), obj(2, [r(5,3)])).

test(col_order_fail, [fail]) :-
    arrange_col_order(obj(1, [r(0,7)]), obj(2, [r(0,2)])).

% arrange_row_aligned/2 tests.
test(row_aligned_same) :-
    arrange_row_aligned(obj(1, [r(2,0)]), obj(2, [r(2,5)])).

test(row_aligned_pair) :-
    arrange_row_aligned(obj(1, [r(0,0), r(0,1)]), obj(2, [r(0,3), r(0,4)])).

test(row_aligned_fail, [fail]) :-
    arrange_row_aligned(obj(1, [r(0,0)]), obj(2, [r(1,0)])).

% arrange_col_aligned/2 tests.
test(col_aligned_same) :-
    arrange_col_aligned(obj(1, [r(0,3)]), obj(2, [r(4,3)])).

test(col_aligned_pair) :-
    arrange_col_aligned(obj(1, [r(0,0), r(1,0)]), obj(2, [r(3,0), r(4,0)])).

test(col_aligned_fail, [fail]) :-
    arrange_col_aligned(obj(1, [r(0,0)]), obj(2, [r(0,1)])).

% arrange_sort_by_row/2 tests.
test(sorting_row_basic) :-
    Objs = [obj(1,[r(3,0)]), obj(2,[r(1,0)]), obj(3,[r(2,0)])],
    arrange_sort_by_row(Objs, Sorted),
    Sorted = [obj(2,[r(1,0)]), obj(3,[r(2,0)]), obj(1,[r(3,0)])].

test(sorting_row_equal) :-
    Objs = [obj(1,[r(0,2)]), obj(2,[r(0,0)])],
    arrange_sort_by_row(Objs, Sorted),
    Sorted = [obj(1,[r(0,2)]), obj(2,[r(0,0)])].

test(sorting_row_single) :-
    arrange_sort_by_row([obj(5,[r(1,1)])], Sorted),
    Sorted = [obj(5,[r(1,1)])].

% arrange_sort_by_col/2 tests.
test(sorting_col_basic) :-
    Objs = [obj(1,[r(0,5)]), obj(2,[r(0,1)]), obj(3,[r(0,3)])],
    arrange_sort_by_col(Objs, Sorted),
    Sorted = [obj(2,[r(0,1)]), obj(3,[r(0,3)]), obj(1,[r(0,5)])].

test(sorting_col_equal) :-
    Objs = [obj(1,[r(2,3)]), obj(2,[r(0,3)])],
    arrange_sort_by_col(Objs, Sorted),
    Sorted = [obj(1,[r(2,3)]), obj(2,[r(0,3)])].

test(sorting_col_single) :-
    arrange_sort_by_col([obj(7,[r(3,2)])], Sorted),
    Sorted = [obj(7,[r(3,2)])].

% arrange_row_gaps/2 tests.
test(row_gaps_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(3,0)]), obj(3,[r(7,0)])],
    arrange_row_gaps(Objs, Gaps),
    Gaps = [3,4].

test(row_gaps_equal) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(2,0)]), obj(3,[r(4,0)])],
    arrange_row_gaps(Objs, Gaps),
    Gaps = [2,2].

test(row_gaps_two) :-
    Objs = [obj(1,[r(1,0)]), obj(2,[r(4,0)])],
    arrange_row_gaps(Objs, Gaps),
    Gaps = [3].

% arrange_col_gaps/2 tests.
test(col_gaps_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,5)]), obj(3,[r(0,9)])],
    arrange_col_gaps(Objs, Gaps),
    Gaps = [5,4].

test(col_gaps_equal) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,3)]), obj(3,[r(0,6)])],
    arrange_col_gaps(Objs, Gaps),
    Gaps = [3,3].

test(col_gaps_two) :-
    Objs = [obj(1,[r(0,2)]), obj(2,[r(0,7)])],
    arrange_col_gaps(Objs, Gaps),
    Gaps = [5].

% arrange_equal_row_gaps/1 tests.
test(equal_row_gaps_yes) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(3,0)]), obj(3,[r(6,0)])],
    arrange_equal_row_gaps(Objs).

test(equal_row_gaps_no, [fail]) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(2,0)]), obj(3,[r(5,0)])],
    arrange_equal_row_gaps(Objs).

test(equal_row_gaps_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(4,0)])],
    arrange_equal_row_gaps(Objs).

% arrange_equal_col_gaps/1 tests.
test(equal_col_gaps_yes) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,4)]), obj(3,[r(0,8)])],
    arrange_equal_col_gaps(Objs).

test(equal_col_gaps_no, [fail]) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,3)]), obj(3,[r(0,8)])],
    arrange_equal_col_gaps(Objs).

test(equal_col_gaps_two) :-
    Objs = [obj(1,[r(0,1)]), obj(2,[r(0,6)])],
    arrange_equal_col_gaps(Objs).

% arrange_group_bbox/5 tests.
test(group_bbox_two) :-
    Objs = [obj(1,[r(0,0), r(0,1)]), obj(2,[r(3,2), r(3,3)])],
    arrange_group_bbox(Objs, 0, 0, 3, 3).

test(group_bbox_single) :-
    arrange_group_bbox([obj(1,[r(2,3)])], 2, 3, 2, 3).

test(group_bbox_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(5,0)]), obj(3,[r(0,8)])],
    arrange_group_bbox(Objs, 0, 0, 5, 8).

% arrange_nearest/3 tests.
test(nearest_closer) :-
    Ref = obj(1, [r(0,0)]),
    Candidates = [obj(2,[r(0,5)]), obj(3,[r(0,2)])],
    arrange_nearest(Ref, Candidates, Nearest),
    Nearest = obj(3,[r(0,2)]).

test(nearest_three) :-
    Ref = obj(1, [r(5,5)]),
    Candidates = [obj(2,[r(0,0)]), obj(3,[r(4,4)]), obj(4,[r(9,9)])],
    arrange_nearest(Ref, Candidates, Nearest),
    Nearest = obj(3,[r(4,4)]).

test(nearest_single) :-
    Ref = obj(1, [r(3,3)]),
    arrange_nearest(Ref, [obj(2,[r(1,1)])], Nearest),
    Nearest = obj(2,[r(1,1)]).

:- end_tests(arrange).
