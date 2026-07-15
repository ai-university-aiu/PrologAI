% test_diff.pl - PLUnit tests for the diff pack (Layer 89: df_* predicates).
:- use_module('../prolog/diff').

% Tests for diff_cell_diff/3

:- begin_tests(diff_cell_diff).

test(no_changes) :-
    diff_cell_diff([[1,2],[3,4]], [[1,2],[3,4]], D),
    D = [].

test(one_change) :-
    diff_cell_diff([[1,0],[0,0]], [[1,0],[0,9]], D),
    D = [diff(1,1,0,9)].

test(all_change) :-
    diff_cell_diff([[0,0]], [[1,2]], D),
    D = [diff(0,0,0,1), diff(0,1,0,2)].

:- end_tests(diff_cell_diff).

% Tests for diff_added/4

:- begin_tests(diff_added).

test(added_one) :-
    diff_added([[0,0],[0,0]], [[0,0],[0,3]], 0, A),
    A = [1-1].

test(added_none) :-
    diff_added([[1,0],[0,0]], [[1,0],[0,0]], 0, A),
    A = [].

test(added_multiple) :-
    diff_added([[0,0],[0,0]], [[1,0],[0,2]], 0, A),
    A = [0-0, 1-1].

:- end_tests(diff_added).

% Tests for diff_removed/4

:- begin_tests(diff_removed).

test(removed_one) :-
    diff_removed([[0,5],[0,0]], [[0,0],[0,0]], 0, R),
    R = [0-1].

test(removed_none) :-
    diff_removed([[0,0],[0,0]], [[1,0],[0,0]], 0, R),
    R = [].

test(removed_two) :-
    diff_removed([[3,0],[0,7]], [[0,0],[0,0]], 0, R),
    R = [0-0, 1-1].

:- end_tests(diff_removed).

% Tests for diff_recolored/4

:- begin_tests(diff_recolored).

test(recolored_one) :-
    diff_recolored([[1,0]], [[2,0]], 0, T),
    T = [0-0-1-2].

test(recolored_none_bg_change) :-
    diff_recolored([[0,0]], [[1,0]], 0, T),
    T = [].

test(recolored_two) :-
    diff_recolored([[1,2]], [[3,4]], 0, T),
    T = [0-0-1-3, 0-1-2-4].

:- end_tests(diff_recolored).

% Tests for diff_stable/3

:- begin_tests(diff_stable).

test(stable_all) :-
    diff_stable([[1,2],[3,4]], [[1,2],[3,4]], S),
    S = [0-0, 0-1, 1-0, 1-1].

test(stable_some) :-
    diff_stable([[1,0],[0,4]], [[1,9],[0,4]], S),
    S = [0-0, 1-0, 1-1].

test(stable_none) :-
    diff_stable([[1]], [[2]], S),
    S = [].

:- end_tests(diff_stable).

% Tests for diff_palette_change/4

:- begin_tests(diff_palette_change).

test(added_color) :-
    diff_palette_change([[1,1]], [[1,2]], Added, Lost),
    Added = [2], Lost = [].

test(lost_color) :-
    diff_palette_change([[1,2]], [[1,1]], Added, Lost),
    Added = [], Lost = [2].

test(swap_colors) :-
    diff_palette_change([[1,0]], [[2,0]], Added, Lost),
    Added = [2], Lost = [1].

:- end_tests(diff_palette_change).

% Tests for diff_common_diffs/2

:- begin_tests(diff_common_diffs).

test(common_in_all_pairs) :-
    Pairs = [[[0,0]]-[[0,1]], [[0,0]]-[[0,1]]],
    diff_common_diffs(Pairs, C),
    C = [0-1].

test(no_common_changed) :-
    Pairs = [[[0,0]]-[[1,0]], [[0,0]]-[[0,1]]],
    diff_common_diffs(Pairs, C),
    C = [].

test(empty_pairs) :-
    diff_common_diffs([], C),
    C = [].

:- end_tests(diff_common_diffs).

% Tests for diff_common_stable/2

:- begin_tests(diff_common_stable).

test(stable_in_all) :-
    Pairs = [[[1,0]]-[[1,2]], [[1,0]]-[[1,3]]],
    diff_common_stable(Pairs, S),
    S = [0-0].

test(no_stable) :-
    Pairs = [[[1,2]]-[[3,4]], [[5,6]]-[[5,7]]],
    diff_common_stable(Pairs, S),
    S = [].

test(empty_pairs) :-
    diff_common_stable([], S),
    S = [].

:- end_tests(diff_common_stable).

% Tests for diff_always_added/3

:- begin_tests(diff_always_added).

test(always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[0,1]]-[[3,1]]],
    diff_always_added(Pairs, 0, A),
    A = [0-0].

test(not_always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[3,1]]-[[3,1]]],
    diff_always_added(Pairs, 0, A),
    A = [].

test(empty_pairs) :-
    diff_always_added([], 0, A),
    A = [].

:- end_tests(diff_always_added).

% Tests for diff_always_removed/3

:- begin_tests(diff_always_removed).

test(always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[1,0]]-[[0,0]]],
    diff_always_removed(Pairs, 0, R),
    R = [0-0].

test(not_always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[0,0]]-[[0,0]]],
    diff_always_removed(Pairs, 0, R),
    R = [].

test(empty_pairs) :-
    diff_always_removed([], 0, R),
    R = [].

:- end_tests(diff_always_removed).

% Tests for diff_total_changes/3

:- begin_tests(diff_total_changes).

test(zero_changes) :-
    diff_total_changes([[1,2]], [[1,2]], N),
    N =:= 0.

test(one_change) :-
    diff_total_changes([[1,2]], [[1,9]], N),
    N =:= 1.

test(four_changes) :-
    diff_total_changes([[1,2],[3,4]], [[5,6],[7,8]], N),
    N =:= 4.

:- end_tests(diff_total_changes).

% Tests for diff_apply_diffs/3

:- begin_tests(diff_apply_diffs).

test(apply_one) :-
    diff_apply_diffs([[0,0],[0,0]], [diff(1,1,0,7)], G),
    G = [[0,0],[0,7]].

test(apply_empty) :-
    diff_apply_diffs([[1,2]], [], G),
    G = [[1,2]].

test(apply_two) :-
    diff_apply_diffs([[0,0]], [diff(0,0,0,3), diff(0,1,0,4)], G),
    G = [[3,4]].

:- end_tests(diff_apply_diffs).

% Tests for diff_invert_diffs/2

:- begin_tests(diff_invert_diffs).

test(invert_one) :-
    diff_invert_diffs([diff(0,0,1,2)], Inv),
    Inv = [diff(0,0,2,1)].

test(invert_empty) :-
    diff_invert_diffs([], Inv),
    Inv = [].

test(invert_two) :-
    diff_invert_diffs([diff(0,0,3,4), diff(1,1,5,6)], Inv),
    Inv = [diff(0,0,4,3), diff(1,1,6,5)].

:- end_tests(diff_invert_diffs).

% Tests for diff_filter_diffs/3

:- begin_tests(diff_filter_diffs).

test(filter_by_row) :-
    Diffs = [diff(0,0,1,2), diff(1,0,3,4)],
    diff_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2)].

test(filter_none_match) :-
    Diffs = [diff(0,0,1,2)],
    diff_filter_diffs(Diffs, [D]>>(D = diff(5,_,_,_)), F),
    F = [].

test(filter_all_match) :-
    Diffs = [diff(0,0,1,2), diff(0,1,3,4)],
    diff_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2), diff(0,1,3,4)].

:- end_tests(diff_filter_diffs).
