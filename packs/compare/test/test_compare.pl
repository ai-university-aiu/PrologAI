% PLUnit tests for the compare pack (cp_* predicates).
:- use_module(library(plunit)).
:- use_module(library(compare)).

% Helper grids.
% Two 3x3 grids differing in center.
g1([[0,0,0],[0,1,0],[0,0,0]]).
g2([[0,0,0],[0,2,0],[0,0,0]]).
% Identical grids.
ga([[1,2],[3,4]]).
gb([[1,2],[3,4]]).
% Grid where row 0 changed completely.
gc([[0,0,0],[0,0,0],[0,0,0]]).
gd([[1,1,1],[0,0,0],[0,0,0]]).
% Small 2x2 grids.
p1([[1,0],[0,1]]).
p2([[0,1],[1,0]]).

:- begin_tests(compare_diff_cells).

test(diff_one_cell) :-
    g1(A), g2(B), cp_diff_cells(A, B, Diffs),
    Diffs = [r(1,1)].

test(diff_none) :-
    ga(A), gb(B), cp_diff_cells(A, B, Diffs),
    Diffs = [].

test(diff_full_row) :-
    gc(A), gd(B), cp_diff_cells(A, B, Diffs),
    msort(Diffs, Sorted),
    Sorted = [r(0,0), r(0,1), r(0,2)].

test(diff_all_cells) :-
    p1(A), p2(B), cp_diff_cells(A, B, Diffs),
    msort(Diffs, Sorted),
    Sorted = [r(0,0), r(0,1), r(1,0), r(1,1)].

:- end_tests(compare_diff_cells).

:- begin_tests(compare_same_cells).

test(same_all) :-
    ga(A), gb(B), cp_same_cells(A, B, Sames),
    msort(Sames, Sorted),
    Sorted = [r(0,0), r(0,1), r(1,0), r(1,1)].

test(same_partial) :-
    g1(A), g2(B), cp_same_cells(A, B, Sames),
    % 8 cells are 0 in both; center differs.
    length(Sames, N), N =:= 8.

test(same_none) :-
    p1(A), p2(B), cp_same_cells(A, B, Sames),
    Sames = [].

:- end_tests(compare_same_cells).

:- begin_tests(compare_added_color).

test(added_2_in_center) :-
    g1(A), g2(B), cp_added_color(A, B, 2, Added),
    Added = [r(1,1)].

test(added_nothing) :-
    g1(A), g2(B), cp_added_color(A, B, 9, Added),
    Added = [].

test(added_row) :-
    gc(A), gd(B), cp_added_color(A, B, 1, Added),
    msort(Added, Sorted),
    Sorted = [r(0,0), r(0,1), r(0,2)].

:- end_tests(compare_added_color).

:- begin_tests(compare_removed_color).

test(removed_1_from_center) :-
    g1(A), g2(B), cp_removed_color(A, B, 1, Removed),
    Removed = [r(1,1)].

test(removed_nothing) :-
    g1(A), g2(B), cp_removed_color(A, B, 0, Removed),
    Removed = [].

test(removed_row) :-
    gd(A), gc(B), cp_removed_color(A, B, 1, Removed),
    msort(Removed, Sorted),
    Sorted = [r(0,0), r(0,1), r(0,2)].

:- end_tests(compare_removed_color).

:- begin_tests(compare_changed_to).

test(changed_to_2) :-
    g1(A), g2(B), cp_changed_to(A, B, 2, Changed),
    Changed = [r(1,1)].

test(changed_to_absent) :-
    ga(A), gb(B), cp_changed_to(A, B, 9, Changed),
    Changed = [].

:- end_tests(compare_changed_to).

:- begin_tests(compare_changed_from).

test(changed_from_1) :-
    g1(A), g2(B), cp_changed_from(A, B, 1, Changed),
    Changed = [r(1,1)].

test(changed_from_absent) :-
    ga(A), gb(B), cp_changed_from(A, B, 9, Changed),
    Changed = [].

:- end_tests(compare_changed_from).

:- begin_tests(compare_diff_map).

test(diff_map_one_cell) :-
    g1(A), g2(B), cp_diff_map(A, B, Map),
    Map = [[0,0,0],[0,1,0],[0,0,0]].

test(diff_map_none) :-
    ga(A), gb(B), cp_diff_map(A, B, Map),
    Map = [[0,0],[0,0]].

test(diff_map_all) :-
    p1(A), p2(B), cp_diff_map(A, B, Map),
    Map = [[1,1],[1,1]].

:- end_tests(compare_diff_map).

:- begin_tests(compare_similarity).

test(similarity_identical) :-
    ga(A), gb(B), cp_similarity(A, B, EqCount-Total),
    EqCount =:= 4, Total =:= 4.

test(similarity_one_diff) :-
    g1(A), g2(B), cp_similarity(A, B, EqCount-Total),
    EqCount =:= 8, Total =:= 9.

test(similarity_all_diff) :-
    p1(A), p2(B), cp_similarity(A, B, EqCount-Total),
    EqCount =:= 0, Total =:= 4.

:- end_tests(compare_similarity).

:- begin_tests(compare_region_diff).

test(region_diff_basic) :-
    cp_region_diff([r(0,0), r(0,1), r(1,0)], [r(0,0)], Diff),
    msort(Diff, Sorted),
    Sorted = [r(0,1), r(1,0)].

test(region_diff_empty_result) :-
    cp_region_diff([r(0,0)], [r(0,0), r(1,1)], Diff),
    Diff = [].

test(region_diff_no_overlap) :-
    cp_region_diff([r(0,0)], [r(1,1)], Diff),
    Diff = [r(0,0)].

:- end_tests(compare_region_diff).

:- begin_tests(compare_region_intersect).

test(region_intersect_one) :-
    cp_region_intersect([r(0,0), r(0,1)], [r(0,0), r(1,1)], Inter),
    Inter = [r(0,0)].

test(region_intersect_empty) :-
    cp_region_intersect([r(0,0)], [r(1,1)], Inter),
    Inter = [].

test(region_intersect_all) :-
    cp_region_intersect([r(0,0), r(1,1)], [r(0,0), r(1,1)], Inter),
    msort(Inter, Sorted),
    Sorted = [r(0,0), r(1,1)].

:- end_tests(compare_region_intersect).

:- begin_tests(compare_region_union).

test(region_union_combined) :-
    cp_region_union([r(0,0)], [r(1,1)], Union),
    msort(Union, Sorted),
    Sorted = [r(0,0), r(1,1)].

test(region_union_no_dup) :-
    cp_region_union([r(0,0), r(1,1)], [r(1,1), r(2,2)], Union),
    msort(Union, Sorted),
    Sorted = [r(0,0), r(1,1), r(2,2)].

test(region_union_identical) :-
    cp_region_union([r(0,0)], [r(0,0)], Union),
    Union = [r(0,0)].

:- end_tests(compare_region_union).

:- begin_tests(compare_region_equal).

test(equal_same_order) :-
    cp_region_equal([r(0,0), r(1,1)], [r(0,0), r(1,1)]).

test(equal_diff_order) :-
    cp_region_equal([r(1,1), r(0,0)], [r(0,0), r(1,1)]).

test(not_equal) :-
    \+ cp_region_equal([r(0,0)], [r(1,1)]).

:- end_tests(compare_region_equal).

:- begin_tests(compare_grids_equal).

test(equal_grids) :-
    ga(A), gb(B), cp_grids_equal(A, B).

test(not_equal_grids) :-
    g1(A), g2(B), \+ cp_grids_equal(A, B).

:- end_tests(compare_grids_equal).

:- begin_tests(compare_color_shift).

test(shift_one_cell) :-
    g1(A), g2(B), cp_color_shift(A, B, Pairs),
    Pairs = [1-2].

test(shift_none) :-
    ga(A), gb(B), cp_color_shift(A, B, Pairs),
    Pairs = [].

test(shift_all_cells) :-
    p1(A), p2(B), cp_color_shift(A, B, Pairs),
    msort(Pairs, Sorted),
    Sorted = [0-1, 0-1, 1-0, 1-0].

:- end_tests(compare_color_shift).
