% PLUnit tests for the select pack (sl_* predicates).
:- use_module(library(plunit)).
:- use_module(library(select)).

% Helper regions.
% Small region: 1 cell.
r1([r(0,0)]).
% Medium region: 3 cells.
r3([r(1,0), r(1,1), r(1,2)]).
% Large region: 5 cells.
r5([r(0,0), r(0,1), r(0,2), r(1,0), r(1,1)]).
% Another 3-cell region.
r3b([r(3,0), r(3,1), r(3,2)]).
% 4-cell region.
r4([r(2,0), r(2,1), r(2,2), r(2,3)]).

% Border-touching region (touches row 0 of a 5x5 grid).
border_r([r(0,2), r(1,2)]).
% Interior region (no cell on border of a 5x5 grid).
interior_r([r(2,2), r(2,3), r(3,2)]).
% Corner-touching region.
corner_r([r(4,4)]).

:- begin_tests(select_largest).

test(largest_single) :-
    r1(A), sl_largest([A], L), L = [r(0,0)].

test(largest_two) :-
    r1(A), r3(B), sl_largest([A, B], L), length(L, 3).

test(largest_three) :-
    r1(A), r3(B), r5(C), sl_largest([A, B, C], L), length(L, 5).

test(largest_first) :-
    % When largest is first, still returns correctly.
    r5(A), r3(B), sl_largest([A, B], L), length(L, 5).

:- end_tests(select_largest).

:- begin_tests(select_smallest).

test(smallest_single) :-
    r1(A), sl_smallest([A], S), length(S, 1).

test(smallest_two) :-
    r1(A), r3(B), sl_smallest([A, B], S), length(S, 1).

test(smallest_three) :-
    r1(A), r3(B), r5(C), sl_smallest([A, B, C], S), length(S, 1).

test(smallest_last) :-
    r5(A), r3(B), r1(C), sl_smallest([A, B, C], S), length(S, 1).

:- end_tests(select_smallest).

:- begin_tests(select_sort_by_area).

test(sort_empty) :-
    sl_sort_by_area([], []).

test(sort_single) :-
    r3(A), sl_sort_by_area([A], [A]).

test(sort_ascending) :-
    r1(A), r3(B), r5(C),
    sl_sort_by_area([C, A, B], Sorted),
    Sorted = [A, B, C].

test(sort_equal_areas_stable) :-
    r3(A), r3b(B),
    sl_sort_by_area([A, B], Sorted),
    length(Sorted, 2),
    Sorted = [First, _], length(First, 3).

:- end_tests(select_sort_by_area).

:- begin_tests(select_filter_area).

test(filter_area_none) :-
    r1(A), r3(B), sl_filter_area([A, B], 9, F), F = [].

test(filter_area_one) :-
    r1(A), r3(B), r5(C), sl_filter_area([A, B, C], 3, F), F = [B].

test(filter_area_all) :-
    r3(A), r3b(B), sl_filter_area([A, B], 3, F), length(F, 2).

test(filter_area_single_cell) :-
    r1(A), r3(B), sl_filter_area([A, B], 1, F), F = [A].

:- end_tests(select_filter_area).

:- begin_tests(select_filter_area_min).

test(min_keep_all) :-
    r1(A), r3(B), r5(C), sl_filter_area_min([A, B, C], 1, F), length(F, 3).

test(min_keep_two) :-
    r1(A), r3(B), r5(C), sl_filter_area_min([A, B, C], 3, F), length(F, 2).

test(min_keep_one) :-
    r1(A), r3(B), r5(C), sl_filter_area_min([A, B, C], 5, F), length(F, 1).

test(min_keep_none) :-
    r1(A), r3(B), sl_filter_area_min([A, B], 10, F), F = [].

:- end_tests(select_filter_area_min).

:- begin_tests(select_filter_area_max).

test(max_keep_all) :-
    r1(A), r3(B), r5(C), sl_filter_area_max([A, B, C], 5, F), length(F, 3).

test(max_keep_two) :-
    r1(A), r3(B), r5(C), sl_filter_area_max([A, B, C], 3, F), length(F, 2).

test(max_keep_one) :-
    r1(A), r3(B), r5(C), sl_filter_area_max([A, B, C], 1, F), length(F, 1).

test(max_keep_none) :-
    r3(A), r5(B), sl_filter_area_max([A, B], 0, F), F = [].

:- end_tests(select_filter_area_max).

:- begin_tests(select_touches_border).

test(touches_top_row) :-
    border_r(R), sl_touches_border(R, 5, 5).

test(touches_corner) :-
    corner_r(R), sl_touches_border(R, 5, 5).

test(does_not_touch) :-
    interior_r(R), \+ sl_touches_border(R, 5, 5).

test(single_cell_interior) :-
    \+ sl_touches_border([r(2,2)], 5, 5).

test(single_cell_border_r0) :-
    sl_touches_border([r(0,2)], 5, 5).

test(single_cell_border_c0) :-
    sl_touches_border([r(2,0)], 5, 5).

:- end_tests(select_touches_border).

:- begin_tests(select_filter_border).

test(filter_border_empty) :-
    sl_filter_border([], 5, 5, F), F = [].

test(filter_border_one) :-
    border_r(A), interior_r(B),
    sl_filter_border([A, B], 5, 5, F), F = [A].

test(filter_border_none_touch) :-
    interior_r(A), sl_filter_border([A], 5, 5, F), F = [].

test(filter_border_all_touch) :-
    border_r(A), corner_r(B),
    sl_filter_border([A, B], 5, 5, F), length(F, 2).

:- end_tests(select_filter_border).

:- begin_tests(select_filter_interior).

test(filter_interior_empty) :-
    sl_filter_interior([], 5, 5, F), F = [].

test(filter_interior_one) :-
    border_r(A), interior_r(B),
    sl_filter_interior([A, B], 5, 5, F), F = [B].

test(filter_interior_none) :-
    border_r(A), corner_r(B),
    sl_filter_interior([A, B], 5, 5, F), F = [].

test(filter_interior_all) :-
    interior_r(A), sl_filter_interior([A], 5, 5, F), F = [A].

:- end_tests(select_filter_interior).

:- begin_tests(select_above_row).

test(above_empty) :-
    sl_above_row([], 3, F), F = [].

test(above_keeps_r0) :-
    % Region with cells at row 0,1 — all strictly above row 2? No: r(1,_) < 2 yes.
    sl_above_row([[r(0,0), r(1,0)]], 2, F), length(F, 1).

test(above_excludes_at_row) :-
    % Region has r(2,0) which is not strictly above row 2.
    sl_above_row([[r(2,0)]], 2, F), F = [].

test(above_mixed) :-
    A = [r(0,0)], B = [r(3,0)],
    sl_above_row([A, B], 2, F), F = [A].

:- end_tests(select_above_row).

:- begin_tests(select_below_row).

test(below_empty) :-
    sl_below_row([], 2, F), F = [].

test(below_keeps_at_row) :-
    % Cell at row 2, below_row(2) means all cells >= 2.
    sl_below_row([[r(2,0)]], 2, F), length(F, 1).

test(below_excludes_above) :-
    sl_below_row([[r(1,0)]], 2, F), F = [].

test(below_mixed) :-
    A = [r(0,0)], B = [r(3,0)],
    sl_below_row([A, B], 2, F), F = [B].

:- end_tests(select_below_row).

:- begin_tests(select_left_of_col).

test(left_empty) :-
    sl_left_of_col([], 3, F), F = [].

test(left_keeps_col0) :-
    sl_left_of_col([[r(0,0), r(1,0)]], 2, F), length(F, 1).

test(left_excludes_at_col) :-
    sl_left_of_col([[r(0,2)]], 2, F), F = [].

test(left_mixed) :-
    A = [r(0,0)], B = [r(0,3)],
    sl_left_of_col([A, B], 2, F), F = [A].

:- end_tests(select_left_of_col).

:- begin_tests(select_right_of_col).

test(right_empty) :-
    sl_right_of_col([], 2, F), F = [].

test(right_keeps_at_col) :-
    sl_right_of_col([[r(0,2)]], 2, F), length(F, 1).

test(right_excludes_left) :-
    sl_right_of_col([[r(0,1)]], 2, F), F = [].

test(right_mixed) :-
    A = [r(0,0)], B = [r(0,3)],
    sl_right_of_col([A, B], 2, F), F = [B].

:- end_tests(select_right_of_col).

:- begin_tests(select_unique_area).

test(unique_empty) :-
    sl_unique_area([], U), U = [].

test(unique_all_same) :-
    r3(A), r3b(B), sl_unique_area([A, B], U), U = [].

test(unique_one) :-
    r1(A), r3(B), r3b(C),
    sl_unique_area([A, B, C], U), U = [A].

test(unique_all_different) :-
    r1(A), r3(B), r5(C),
    sl_unique_area([A, B, C], U), length(U, 3).

test(unique_two_of_three) :-
    r1(A), r3(B), r4(C),
    sl_unique_area([A, B, C], U), length(U, 3).

:- end_tests(select_unique_area).
