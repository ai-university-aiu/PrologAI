:- use_module('../prolog/locate').

:- begin_tests(locate).

% --- locate_subgrid_at ---

test(subgrid_at_center) :-
    locate_subgrid_at([[1,2,3],[4,5,6],[7,8,9]], [[5,6],[8,9]], 1, 1).

test(subgrid_at_topleft) :-
    locate_subgrid_at([[1,2],[3,4]], [[1]], 0, 0).

test(subgrid_at_fail) :-
    \+ locate_subgrid_at([[1,2],[3,4]], [[9]], 0, 0).

% --- locate_find_sub ---

test(find_sub_center) :-
    locate_find_sub([[0,0,0],[0,1,0],[0,0,0]], [[1]], R, C),
    R = 1, C = 1.

test(find_sub_full) :-
    locate_find_sub([[1,2],[3,4]], [[1,2],[3,4]], R, C),
    R = 0, C = 0.

test(find_sub_first) :-
    locate_find_sub([[0,1,0],[0,0,0]], [[1]], R, C),
    R = 0, C = 1.

% --- locate_all_sub ---

test(all_sub_corners) :-
    locate_all_sub([[1,0,1],[0,0,0],[1,0,1]], [[1]], P),
    P = [0-0, 0-2, 2-0, 2-2].

test(all_sub_none) :-
    locate_all_sub([[0,0],[0,0]], [[1]], P),
    P = [].

test(all_sub_one) :-
    locate_all_sub([[1,1],[1,0]], [[1],[1]], P),
    P = [0-0].

% --- locate_subgrid_count ---

test(subgrid_count_four) :-
    locate_subgrid_count([[1,0,1],[0,0,0],[1,0,1]], [[1]], N),
    N = 4.

test(subgrid_count_zero) :-
    locate_subgrid_count([[0,0],[0,0]], [[1]], N),
    N = 0.

test(subgrid_count_one) :-
    locate_subgrid_count([[1,1],[1,0]], [[1,1]], N),
    N = 1.

% --- locate_row_pattern ---

test(row_pattern_basic) :-
    locate_row_pattern([[0,0],[1,2],[0,0]], [1,2], R),
    R = 1.

test(row_pattern_first) :-
    locate_row_pattern([[1,1],[0,0],[1,1]], [1,1], R),
    R = 0.

test(row_pattern_fail) :-
    \+ locate_row_pattern([[0,0],[1,0]], [9,9], _).

% --- locate_all_row_pattern ---

test(all_row_pattern_two) :-
    locate_all_row_pattern([[1,1],[0,0],[1,1]], [1,1], Rs),
    Rs = [0, 2].

test(all_row_pattern_none) :-
    locate_all_row_pattern([[0,0],[0,0]], [1,1], Rs),
    Rs = [].

test(all_row_pattern_basic) :-
    locate_all_row_pattern([[1,2],[3,4],[1,2]], [1,2], Rs),
    Rs = [0, 2].

% --- locate_col_pattern ---

test(col_pattern_col0) :-
    locate_col_pattern([[1,0],[2,0],[3,0]], [1,2,3], C),
    C = 0.

test(col_pattern_col1) :-
    locate_col_pattern([[0,1],[0,2],[0,3]], [1,2,3], C),
    C = 1.

test(col_pattern_fail) :-
    \+ locate_col_pattern([[0,0],[0,0]], [9,9], _).

% --- locate_all_col_pattern ---

test(all_col_pattern_two) :-
    locate_all_col_pattern([[1,1],[2,2],[3,3]], [1,2,3], Cols),
    Cols = [0, 1].

test(all_col_pattern_both) :-
    locate_all_col_pattern([[0,0],[0,0]], [0,0], Cols),
    Cols = [0, 1].

test(all_col_pattern_one) :-
    locate_all_col_pattern([[1,0],[2,0],[3,0]], [1,2,3], Cols),
    Cols = [0].

% --- locate_row_prefix ---

test(row_prefix_basic) :-
    locate_row_prefix([[1,2,3],[4,5,6]], 0, [1,2], Rest),
    Rest = [3].

test(row_prefix_empty) :-
    locate_row_prefix([[1,2,3]], 0, [], Rest),
    Rest = [1,2,3].

test(row_prefix_full) :-
    locate_row_prefix([[1,2,3],[4,5,6]], 1, [4,5,6], Rest),
    Rest = [].

% --- locate_row_suffix ---

test(row_suffix_basic) :-
    locate_row_suffix([[1,2,3],[4,5,6]], 0, [2,3]).

test(row_suffix_empty) :-
    locate_row_suffix([[1,2,3]], 0, []).

test(row_suffix_fail) :-
    \+ locate_row_suffix([[1,2,3]], 0, [1,3]).

% --- locate_anchor ---

test(anchor_center) :-
    locate_anchor([[0,0,0],[0,9,0],[0,0,0]], 9, R, C),
    R = 1, C = 1.

test(anchor_corner) :-
    locate_anchor([[9,0],[0,0]], 9, R, C),
    R = 0, C = 0.

test(anchor_fail_two) :-
    \+ locate_anchor([[9,0],[9,0]], 9, _, _).

% --- locate_row_count ---

test(row_count_basic) :-
    locate_row_count([[1,0,1],[0,0,0],[1,1,0]], 1, Counts),
    Counts = [2, 0, 2].

test(row_count_zero) :-
    locate_row_count([[0,0],[0,0]], 1, Counts),
    Counts = [0, 0].

test(row_count_all) :-
    locate_row_count([[1,1],[1,1]], 1, Counts),
    Counts = [2, 2].

% --- locate_row_contains ---

test(row_contains_all) :-
    locate_row_contains([[0,1,0],[1,0,0],[0,0,1]], 1, Rows),
    Rows = [0, 1, 2].

test(row_contains_none) :-
    locate_row_contains([[0,0],[0,0]], 1, Rows),
    Rows = [].

test(row_contains_one) :-
    locate_row_contains([[0,0],[1,0]], 1, Rows),
    Rows = [1].

% --- locate_col_contains ---

test(col_contains_one) :-
    locate_col_contains([[0,1,0],[0,1,0]], 1, Cols),
    Cols = [1].

test(col_contains_none) :-
    locate_col_contains([[0,0],[0,0]], 1, Cols),
    Cols = [].

test(col_contains_three) :-
    locate_col_contains([[1,0,1],[0,1,0]], 1, Cols),
    Cols = [0, 1, 2].

:- end_tests(locate).
