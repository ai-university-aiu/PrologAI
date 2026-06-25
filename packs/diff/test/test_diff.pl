% test_diff.pl - PLUnit tests for the diff pack (Layer 89: df_* predicates).
:- use_module('../prolog/diff').

% Tests for df_cell_diff/3

:- begin_tests(df_cell_diff).

test(no_changes) :-
    df_cell_diff([[1,2],[3,4]], [[1,2],[3,4]], D),
    D = [].

test(one_change) :-
    df_cell_diff([[1,0],[0,0]], [[1,0],[0,9]], D),
    D = [diff(1,1,0,9)].

test(all_change) :-
    df_cell_diff([[0,0]], [[1,2]], D),
    D = [diff(0,0,0,1), diff(0,1,0,2)].

:- end_tests(df_cell_diff).

% Tests for df_added/4

:- begin_tests(df_added).

test(added_one) :-
    df_added([[0,0],[0,0]], [[0,0],[0,3]], 0, A),
    A = [1-1].

test(added_none) :-
    df_added([[1,0],[0,0]], [[1,0],[0,0]], 0, A),
    A = [].

test(added_multiple) :-
    df_added([[0,0],[0,0]], [[1,0],[0,2]], 0, A),
    A = [0-0, 1-1].

:- end_tests(df_added).

% Tests for df_removed/4

:- begin_tests(df_removed).

test(removed_one) :-
    df_removed([[0,5],[0,0]], [[0,0],[0,0]], 0, R),
    R = [0-1].

test(removed_none) :-
    df_removed([[0,0],[0,0]], [[1,0],[0,0]], 0, R),
    R = [].

test(removed_two) :-
    df_removed([[3,0],[0,7]], [[0,0],[0,0]], 0, R),
    R = [0-0, 1-1].

:- end_tests(df_removed).

% Tests for df_recolored/4

:- begin_tests(df_recolored).

test(recolored_one) :-
    df_recolored([[1,0]], [[2,0]], 0, T),
    T = [0-0-1-2].

test(recolored_none_bg_change) :-
    df_recolored([[0,0]], [[1,0]], 0, T),
    T = [].

test(recolored_two) :-
    df_recolored([[1,2]], [[3,4]], 0, T),
    T = [0-0-1-3, 0-1-2-4].

:- end_tests(df_recolored).

% Tests for df_stable/3

:- begin_tests(df_stable).

test(stable_all) :-
    df_stable([[1,2],[3,4]], [[1,2],[3,4]], S),
    S = [0-0, 0-1, 1-0, 1-1].

test(stable_some) :-
    df_stable([[1,0],[0,4]], [[1,9],[0,4]], S),
    S = [0-0, 1-0, 1-1].

test(stable_none) :-
    df_stable([[1]], [[2]], S),
    S = [].

:- end_tests(df_stable).

% Tests for df_palette_change/4

:- begin_tests(df_palette_change).

test(added_color) :-
    df_palette_change([[1,1]], [[1,2]], Added, Lost),
    Added = [2], Lost = [].

test(lost_color) :-
    df_palette_change([[1,2]], [[1,1]], Added, Lost),
    Added = [], Lost = [2].

test(swap_colors) :-
    df_palette_change([[1,0]], [[2,0]], Added, Lost),
    Added = [2], Lost = [1].

:- end_tests(df_palette_change).

% Tests for df_common_diffs/2

:- begin_tests(df_common_diffs).

test(common_in_all_pairs) :-
    Pairs = [[[0,0]]-[[0,1]], [[0,0]]-[[0,1]]],
    df_common_diffs(Pairs, C),
    C = [0-1].

test(no_common_changed) :-
    Pairs = [[[0,0]]-[[1,0]], [[0,0]]-[[0,1]]],
    df_common_diffs(Pairs, C),
    C = [].

test(empty_pairs) :-
    df_common_diffs([], C),
    C = [].

:- end_tests(df_common_diffs).

% Tests for df_common_stable/2

:- begin_tests(df_common_stable).

test(stable_in_all) :-
    Pairs = [[[1,0]]-[[1,2]], [[1,0]]-[[1,3]]],
    df_common_stable(Pairs, S),
    S = [0-0].

test(no_stable) :-
    Pairs = [[[1,2]]-[[3,4]], [[5,6]]-[[5,7]]],
    df_common_stable(Pairs, S),
    S = [].

test(empty_pairs) :-
    df_common_stable([], S),
    S = [].

:- end_tests(df_common_stable).

% Tests for df_always_added/3

:- begin_tests(df_always_added).

test(always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[0,1]]-[[3,1]]],
    df_always_added(Pairs, 0, A),
    A = [0-0].

test(not_always_added) :-
    Pairs = [[[0,1]]-[[2,1]], [[3,1]]-[[3,1]]],
    df_always_added(Pairs, 0, A),
    A = [].

test(empty_pairs) :-
    df_always_added([], 0, A),
    A = [].

:- end_tests(df_always_added).

% Tests for df_always_removed/3

:- begin_tests(df_always_removed).

test(always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[1,0]]-[[0,0]]],
    df_always_removed(Pairs, 0, R),
    R = [0-0].

test(not_always_removed) :-
    Pairs = [[[1,0]]-[[0,0]], [[0,0]]-[[0,0]]],
    df_always_removed(Pairs, 0, R),
    R = [].

test(empty_pairs) :-
    df_always_removed([], 0, R),
    R = [].

:- end_tests(df_always_removed).

% Tests for df_total_changes/3

:- begin_tests(df_total_changes).

test(zero_changes) :-
    df_total_changes([[1,2]], [[1,2]], N),
    N =:= 0.

test(one_change) :-
    df_total_changes([[1,2]], [[1,9]], N),
    N =:= 1.

test(four_changes) :-
    df_total_changes([[1,2],[3,4]], [[5,6],[7,8]], N),
    N =:= 4.

:- end_tests(df_total_changes).

% Tests for df_apply_diffs/3

:- begin_tests(df_apply_diffs).

test(apply_one) :-
    df_apply_diffs([[0,0],[0,0]], [diff(1,1,0,7)], G),
    G = [[0,0],[0,7]].

test(apply_empty) :-
    df_apply_diffs([[1,2]], [], G),
    G = [[1,2]].

test(apply_two) :-
    df_apply_diffs([[0,0]], [diff(0,0,0,3), diff(0,1,0,4)], G),
    G = [[3,4]].

:- end_tests(df_apply_diffs).

% Tests for df_invert_diffs/2

:- begin_tests(df_invert_diffs).

test(invert_one) :-
    df_invert_diffs([diff(0,0,1,2)], Inv),
    Inv = [diff(0,0,2,1)].

test(invert_empty) :-
    df_invert_diffs([], Inv),
    Inv = [].

test(invert_two) :-
    df_invert_diffs([diff(0,0,3,4), diff(1,1,5,6)], Inv),
    Inv = [diff(0,0,4,3), diff(1,1,6,5)].

:- end_tests(df_invert_diffs).

% Tests for df_filter_diffs/3

:- begin_tests(df_filter_diffs).

test(filter_by_row) :-
    Diffs = [diff(0,0,1,2), diff(1,0,3,4)],
    df_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2)].

test(filter_none_match) :-
    Diffs = [diff(0,0,1,2)],
    df_filter_diffs(Diffs, [D]>>(D = diff(5,_,_,_)), F),
    F = [].

test(filter_all_match) :-
    Diffs = [diff(0,0,1,2), diff(0,1,3,4)],
    df_filter_diffs(Diffs, [D]>>(D = diff(0,_,_,_)), F),
    F = [diff(0,0,1,2), diff(0,1,3,4)].

:- end_tests(df_filter_diffs).
