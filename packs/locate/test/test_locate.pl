:- use_module('../prolog/locate').

:- begin_tests(locate).

% --- lc_subgrid_at ---

test(subgrid_at_center) :-
    lc_subgrid_at([[1,2,3],[4,5,6],[7,8,9]], [[5,6],[8,9]], 1, 1).

test(subgrid_at_topleft) :-
    lc_subgrid_at([[1,2],[3,4]], [[1]], 0, 0).

test(subgrid_at_fail) :-
    \+ lc_subgrid_at([[1,2],[3,4]], [[9]], 0, 0).

% --- lc_find_sub ---

test(find_sub_center) :-
    lc_find_sub([[0,0,0],[0,1,0],[0,0,0]], [[1]], R, C),
    R = 1, C = 1.

test(find_sub_full) :-
    lc_find_sub([[1,2],[3,4]], [[1,2],[3,4]], R, C),
    R = 0, C = 0.

test(find_sub_first) :-
    lc_find_sub([[0,1,0],[0,0,0]], [[1]], R, C),
    R = 0, C = 1.

% --- lc_all_sub ---

test(all_sub_corners) :-
    lc_all_sub([[1,0,1],[0,0,0],[1,0,1]], [[1]], P),
    P = [0-0, 0-2, 2-0, 2-2].

test(all_sub_none) :-
    lc_all_sub([[0,0],[0,0]], [[1]], P),
    P = [].

test(all_sub_one) :-
    lc_all_sub([[1,1],[1,0]], [[1],[1]], P),
    P = [0-0].

% --- lc_subgrid_count ---

test(subgrid_count_four) :-
    lc_subgrid_count([[1,0,1],[0,0,0],[1,0,1]], [[1]], N),
    N = 4.

test(subgrid_count_zero) :-
    lc_subgrid_count([[0,0],[0,0]], [[1]], N),
    N = 0.

test(subgrid_count_one) :-
    lc_subgrid_count([[1,1],[1,0]], [[1,1]], N),
    N = 1.

% --- lc_row_pattern ---

test(row_pattern_basic) :-
    lc_row_pattern([[0,0],[1,2],[0,0]], [1,2], R),
    R = 1.

test(row_pattern_first) :-
    lc_row_pattern([[1,1],[0,0],[1,1]], [1,1], R),
    R = 0.

test(row_pattern_fail) :-
    \+ lc_row_pattern([[0,0],[1,0]], [9,9], _).

% --- lc_all_row_pattern ---

test(all_row_pattern_two) :-
    lc_all_row_pattern([[1,1],[0,0],[1,1]], [1,1], Rs),
    Rs = [0, 2].

test(all_row_pattern_none) :-
    lc_all_row_pattern([[0,0],[0,0]], [1,1], Rs),
    Rs = [].

test(all_row_pattern_basic) :-
    lc_all_row_pattern([[1,2],[3,4],[1,2]], [1,2], Rs),
    Rs = [0, 2].

% --- lc_col_pattern ---

test(col_pattern_col0) :-
    lc_col_pattern([[1,0],[2,0],[3,0]], [1,2,3], C),
    C = 0.

test(col_pattern_col1) :-
    lc_col_pattern([[0,1],[0,2],[0,3]], [1,2,3], C),
    C = 1.

test(col_pattern_fail) :-
    \+ lc_col_pattern([[0,0],[0,0]], [9,9], _).

% --- lc_all_col_pattern ---

test(all_col_pattern_two) :-
    lc_all_col_pattern([[1,1],[2,2],[3,3]], [1,2,3], Cols),
    Cols = [0, 1].

test(all_col_pattern_both) :-
    lc_all_col_pattern([[0,0],[0,0]], [0,0], Cols),
    Cols = [0, 1].

test(all_col_pattern_one) :-
    lc_all_col_pattern([[1,0],[2,0],[3,0]], [1,2,3], Cols),
    Cols = [0].

% --- lc_row_prefix ---

test(row_prefix_basic) :-
    lc_row_prefix([[1,2,3],[4,5,6]], 0, [1,2], Rest),
    Rest = [3].

test(row_prefix_empty) :-
    lc_row_prefix([[1,2,3]], 0, [], Rest),
    Rest = [1,2,3].

test(row_prefix_full) :-
    lc_row_prefix([[1,2,3],[4,5,6]], 1, [4,5,6], Rest),
    Rest = [].

% --- lc_row_suffix ---

test(row_suffix_basic) :-
    lc_row_suffix([[1,2,3],[4,5,6]], 0, [2,3]).

test(row_suffix_empty) :-
    lc_row_suffix([[1,2,3]], 0, []).

test(row_suffix_fail) :-
    \+ lc_row_suffix([[1,2,3]], 0, [1,3]).

% --- lc_anchor ---

test(anchor_center) :-
    lc_anchor([[0,0,0],[0,9,0],[0,0,0]], 9, R, C),
    R = 1, C = 1.

test(anchor_corner) :-
    lc_anchor([[9,0],[0,0]], 9, R, C),
    R = 0, C = 0.

test(anchor_fail_two) :-
    \+ lc_anchor([[9,0],[9,0]], 9, _, _).

% --- lc_row_count ---

test(row_count_basic) :-
    lc_row_count([[1,0,1],[0,0,0],[1,1,0]], 1, Counts),
    Counts = [2, 0, 2].

test(row_count_zero) :-
    lc_row_count([[0,0],[0,0]], 1, Counts),
    Counts = [0, 0].

test(row_count_all) :-
    lc_row_count([[1,1],[1,1]], 1, Counts),
    Counts = [2, 2].

% --- lc_row_contains ---

test(row_contains_all) :-
    lc_row_contains([[0,1,0],[1,0,0],[0,0,1]], 1, Rows),
    Rows = [0, 1, 2].

test(row_contains_none) :-
    lc_row_contains([[0,0],[0,0]], 1, Rows),
    Rows = [].

test(row_contains_one) :-
    lc_row_contains([[0,0],[1,0]], 1, Rows),
    Rows = [1].

% --- lc_col_contains ---

test(col_contains_one) :-
    lc_col_contains([[0,1,0],[0,1,0]], 1, Cols),
    Cols = [1].

test(col_contains_none) :-
    lc_col_contains([[0,0],[0,0]], 1, Cols),
    Cols = [].

test(col_contains_three) :-
    lc_col_contains([[1,0,1],[0,1,0]], 1, Cols),
    Cols = [0, 1, 2].

:- end_tests(locate).
