% test_difference.pl - PLUnit tests for the diff pack (Layer 89: df_* predicates).
:- use_module('../prolog/difference').

% Tests for difference_cell_diff/3

:- begin_tests(difference_cell_diff).

test(no_changes) :-
    difference_cell_diff([[1,2],[3,4]], [[1,2],[3,4]], D),
    D = [].

test(one_change) :-
    difference_cell_diff([[1,0],[0,0]], [[1,0],[0,9]], D),
    D = [diff(1,1,0,9)].

test(all_change) :-
    difference_cell_diff([[0,0]], [[1,2]], D),
    D = [diff(0,0,0,1), diff(0,1,0,2)].

:- end_tests(difference_cell_diff).

% Tests for difference_added/4

:- begin_tests(difference_added).

test(added_one) :-
    difference_added([[0,0],[0,0]], [[0,0],[0,3]], 0, A),
    A = [1-1].

test(added_none) :-
    difference_added([[1,0],[0,0]], [[1,0],[0,0]], 0, A),
    A = [].

test(added_multiple) :-
    difference_added([[0,0],[0,0]], [[1,0],[0,2]], 0, A),
    A = [0-0, 1-1].

:- end_tests(difference_added).

% Tests for difference_removed/4

:- begin_tests(difference_removed).

test(removed_one) :-
    difference_removed([[0,5],[0,0]], [[0,0],[0,0]], 0, R),
    R = [0-1].

test(removed_none) :-
    difference_removed([[0,0],[0,0]], [[1,0],[0,0]], 0, R),
    R = [].

test(removed_two) :-
    difference_removed([[3,0],[0,7]], [[0,0],[0,0]], 0, R),
    R = [0-0, 1-1].

:- end_tests(difference_removed).

% Tests for difference_recolored/4

:- begin_tests(difference_recolored).

test(recolored_one) :-
    difference_recolored([[1,0]], [[2,0]], 0, T),
    T = [0-0-1-2].

test(recolored_none_bg_change) :-
    difference_recolored([[0,0]], [[1,0]], 0, T),
    T = [].

test(recolored_two) :-
    difference_recolored([[1,2]], [[3,4]], 0, T),
    T = [0-0-1-3, 0-1-2-4].

:- end_tests(difference_recolored).

% Tests for difference_stable/3

:- begin_tests(difference_stable).

test(stable_all) :-
    difference_stable([[1,2],[3,4]], [[1,2],[3,4]], S),
    S = [0-0, 0-1, 1-0, 1-1].

test(stable_some) :-
    difference_stable([[1,0],[0,4]], [[1,9],[0,4]], S),
    S = [0-0, 1-0, 1-1].

test(stable_none) :-
    difference_stable([[1]], [[2]], S),
    S = [].

:- end_tests(difference_stable).

% Tests for difference_palette_change/4

:- begin_tests(difference_palette_change).

test(added_color) :-
    difference_palette_change([[1,1]], [[1,2]], Added, Lost),
    Added = [2], Lost = [].

test(lost_color) :-
    difference_palette_change([[1,2]], [[1,1]], Added, Lost),
    Added = [], Lost = [2].

test(swap_colors) :-
    difference_palette_change([[1,0]], [[2,0]], Added, Lost),
    Added = [2], Lost = [1].

:- end_tests(difference_palette_change).

% Tests for difference_common_diffs/2

:- begin_tests(difference_common_diffs).

test(common_in_all_pairs) :-
    Pairs = [[[0,0]]-[[0,1]], [[0,0]]-[[0,1]]],
    difference_common_diffs(Pairs, C),
    C = [0-1].

test(no_common_changed) :-
    Pairs = [[[0,0]]-[[1,0]], [[0,0]]-[[0,1]]],
    difference_common_diffs(Pairs, C),
    C = [].

test(empty_pairs) :-
    difference_common_diffs([], C),
    C = [].

:- end_tests(difference_common_diffs).

% Tests for difference_common_stable/2

:- begin_tests(difference_common_stable).

test(stable_in_all) :-
    Pairs = [[[1,0]]-[[1,2]], [[1,0]]-[[1,3]]],
    difference_common_stable(Pairs, S),
    S = [0-0].

test(no_stable) :-
    Pairs = [[[1,2]]-[[3,4]], [[5,6]]-[[5,7]]],
    difference_common_stable(Pairs, S),
    S = [].

test(empty_pairs) :-
    difference_common_stable([], S),
    S = [].

:- end_tests(difference_common_stable).

% Tests for difference_always_added/3

:- begin_tests(difference_always_added).

test(always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[0,1]]-[[3,1]]],
    difference_always_added(Pairs, 0, A),
    A = [0-0].

test(not_always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[3,1]]-[[3,1]]],
    difference_always_added(Pairs, 0, A),
    A = [].

test(empty_pairs) :-
    difference_always_added([], 0, A),
    A = [].

:- end_tests(difference_always_added).

% Tests for difference_always_removed/3

:- begin_tests(difference_always_removed).

test(always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[1,0]]-[[0,0]]],
    difference_always_removed(Pairs, 0, R),
    R = [0-0].

test(not_always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[0,0]]-[[0,0]]],
    difference_always_removed(Pairs, 0, R),
    R = [].

test(empty_pairs) :-
    difference_always_removed([], 0, R),
    R = [].

:- end_tests(difference_always_removed).

% Tests for difference_total_changes/3

:- begin_tests(difference_total_changes).

test(zero_changes) :-
    difference_total_changes([[1,2]], [[1,2]], N),
    N =:= 0.

test(one_change) :-
    difference_total_changes([[1,2]], [[1,9]], N),
    N =:= 1.

test(four_changes) :-
    difference_total_changes([[1,2],[3,4]], [[5,6],[7,8]], N),
    N =:= 4.

:- end_tests(difference_total_changes).

% Tests for difference_apply_diffs/3

:- begin_tests(difference_apply_diffs).

test(apply_one) :-
    difference_apply_diffs([[0,0],[0,0]], [diff(1,1,0,7)], G),
    G = [[0,0],[0,7]].

test(apply_empty) :-
    difference_apply_diffs([[1,2]], [], G),
    G = [[1,2]].

test(apply_two) :-
    difference_apply_diffs([[0,0]], [diff(0,0,0,3), diff(0,1,0,4)], G),
    G = [[3,4]].

:- end_tests(difference_apply_diffs).

% Tests for difference_invert_diffs/2

:- begin_tests(difference_invert_diffs).

test(invert_one) :-
    difference_invert_diffs([diff(0,0,1,2)], Inv),
    Inv = [diff(0,0,2,1)].

test(invert_empty) :-
    difference_invert_diffs([], Inv),
    Inv = [].

test(invert_two) :-
    difference_invert_diffs([diff(0,0,3,4), diff(1,1,5,6)], Inv),
    Inv = [diff(0,0,4,3), diff(1,1,6,5)].

:- end_tests(difference_invert_diffs).

% Tests for difference_filter_diffs/3

:- begin_tests(difference_filter_diffs).

test(filter_by_row) :-
    Diffs = [diff(0,0,1,2), diff(1,0,3,4)],
    difference_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2)].

test(filter_none_match) :-
    Diffs = [diff(0,0,1,2)],
    difference_filter_diffs(Diffs, [D]>>(D = diff(5,_,_,_)), F),
    F = [].

test(filter_all_match) :-
    Diffs = [diff(0,0,1,2), diff(0,1,3,4)],
    difference_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2), diff(0,1,3,4)].

:- end_tests(difference_filter_diffs).
