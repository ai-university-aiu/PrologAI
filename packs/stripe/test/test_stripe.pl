% test_stripe.pl - PLUnit tests for the stripe pack (Layer 97: sr_* predicates).
:- use_module('../prolog/stripe').

% Tests for stripe_uniform_row/3

:- begin_tests(stripe_uniform_row).

test(uniform_row) :-
    stripe_uniform_row([[5,5,5],[1,2,3]], 0, C), C =:= 5.

test(non_uniform_row_fails, [fail]) :-
    stripe_uniform_row([[1,2,3]], 0, _).

test(single_cell_row) :-
    stripe_uniform_row([[7]], 0, C), C =:= 7.

:- end_tests(stripe_uniform_row).

% Tests for stripe_uniform_col/3

:- begin_tests(stripe_uniform_col).

test(uniform_col) :-
    stripe_uniform_col([[5,0],[5,1],[5,2]], 0, C), C =:= 5.

test(non_uniform_col_fails, [fail]) :-
    stripe_uniform_col([[1,0],[2,0]], 0, _).

test(single_cell_col) :-
    stripe_uniform_col([[3]], 0, C), C =:= 3.

:- end_tests(stripe_uniform_col).

% Tests for stripe_uniform_rows/3

:- begin_tests(stripe_uniform_rows).

test(all_matching) :-
    stripe_uniform_rows([[0,0],[0,0]], 0, Rs), Rs = [0,1].

test(none_matching) :-
    stripe_uniform_rows([[0,1],[1,0]], 0, Rs), Rs = [].

test(one_matching) :-
    stripe_uniform_rows([[0,0],[1,2]], 0, Rs), Rs = [0].

:- end_tests(stripe_uniform_rows).

% Tests for stripe_uniform_cols/3

:- begin_tests(stripe_uniform_cols).

test(all_cols_match) :-
    stripe_uniform_cols([[0,0],[0,0]], 0, Cs), Cs = [0,1].

test(no_cols_match) :-
    stripe_uniform_cols([[0,1],[1,0]], 0, Cs), Cs = [].

test(one_col_matches) :-
    stripe_uniform_cols([[0,1],[0,2]], 0, Cs), Cs = [0].

:- end_tests(stripe_uniform_cols).

% Tests for stripe_all_stripe_rows/2

:- begin_tests(stripe_all_stripe_rows).

test(two_uniform_rows) :-
    stripe_all_stripe_rows([[5,5],[1,2],[3,3]], Pairs),
    Pairs = [0-5, 2-3].

test(no_uniform_rows) :-
    stripe_all_stripe_rows([[1,2],[3,4]], Pairs), Pairs = [].

test(all_uniform_rows) :-
    stripe_all_stripe_rows([[0,0],[1,1]], Pairs),
    Pairs = [0-0, 1-1].

:- end_tests(stripe_all_stripe_rows).

% Tests for stripe_all_stripe_cols/2

:- begin_tests(stripe_all_stripe_cols).

test(one_uniform_col) :-
    stripe_all_stripe_cols([[0,1],[0,2]], Pairs),
    Pairs = [0-0].

test(no_uniform_cols) :-
    stripe_all_stripe_cols([[1,2],[3,4]], Pairs), Pairs = [].

test(all_uniform_cols) :-
    stripe_all_stripe_cols([[0,1],[0,1]], Pairs),
    Pairs = [0-0, 1-1].

:- end_tests(stripe_all_stripe_cols).

% Tests for stripe_mixed_rows/2

:- begin_tests(stripe_mixed_rows).

test(all_rows_mixed) :-
    stripe_mixed_rows([[1,2],[3,4]], Rs), Rs = [0,1].

test(no_rows_mixed) :-
    stripe_mixed_rows([[0,0],[1,1]], Rs), Rs = [].

test(one_row_mixed) :-
    stripe_mixed_rows([[0,0],[1,2]], Rs), Rs = [1].

:- end_tests(stripe_mixed_rows).

% Tests for stripe_mixed_cols/2

:- begin_tests(stripe_mixed_cols).

test(all_cols_mixed) :-
    stripe_mixed_cols([[1,3],[2,4]], Cs), Cs = [0,1].

test(no_cols_mixed) :-
    stripe_mixed_cols([[0,1],[0,1]], Cs), Cs = [].

test(one_col_mixed) :-
    stripe_mixed_cols([[0,1],[0,2]], Cs), Cs = [1].

:- end_tests(stripe_mixed_cols).

% Tests for stripe_fill_row/4

:- begin_tests(stripe_fill_row).

test(fill_first_row) :-
    stripe_fill_row([[1,2],[3,4]], 0, 9, R),
    R = [[9,9],[3,4]].

test(fill_last_row) :-
    stripe_fill_row([[1,2],[3,4]], 1, 0, R),
    R = [[1,2],[0,0]].

test(fill_already_uniform_row) :-
    stripe_fill_row([[5,5],[1,2]], 0, 7, R),
    R = [[7,7],[1,2]].

:- end_tests(stripe_fill_row).

% Tests for stripe_fill_col/4

:- begin_tests(stripe_fill_col).

test(fill_first_col) :-
    stripe_fill_col([[1,2],[3,4]], 0, 9, R),
    R = [[9,2],[9,4]].

test(fill_last_col) :-
    stripe_fill_col([[1,2],[3,4]], 1, 0, R),
    R = [[1,0],[3,0]].

test(fill_already_uniform_col) :-
    stripe_fill_col([[5,1],[5,2]], 0, 7, R),
    R = [[7,1],[7,2]].

:- end_tests(stripe_fill_col).

% Tests for stripe_fill_rows/4

:- begin_tests(stripe_fill_rows).

test(fill_no_rows) :-
    stripe_fill_rows([[1,2],[3,4]], [], 9, R),
    R = [[1,2],[3,4]].

test(fill_one_row) :-
    stripe_fill_rows([[1,2],[3,4]], [0], 9, R),
    R = [[9,9],[3,4]].

test(fill_both_rows) :-
    stripe_fill_rows([[1,2],[3,4]], [0,1], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(stripe_fill_rows).

% Tests for stripe_fill_cols/4

:- begin_tests(stripe_fill_cols).

test(fill_no_cols) :-
    stripe_fill_cols([[1,2],[3,4]], [], 9, R),
    R = [[1,2],[3,4]].

test(fill_one_col) :-
    stripe_fill_cols([[1,2],[3,4]], [0], 9, R),
    R = [[9,2],[9,4]].

test(fill_both_cols) :-
    stripe_fill_cols([[1,2],[3,4]], [0,1], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(stripe_fill_cols).

% Tests for stripe_cross_cells/4

:- begin_tests(stripe_cross_cells).

test(one_intersection) :-
    stripe_cross_cells([[1,2],[3,4]], [0], [1], Cells),
    Cells = [r(0,1)].

test(four_intersections) :-
    stripe_cross_cells([[1,2],[3,4]], [0,1], [0,1], Cells),
    length(Cells, 4).

test(empty_rows) :-
    stripe_cross_cells([[1,2],[3,4]], [], [0,1], Cells),
    Cells = [].

:- end_tests(stripe_cross_cells).

% Tests for stripe_cross_fill/5

:- begin_tests(stripe_cross_fill).

test(fill_cross_single) :-
    stripe_cross_fill([[1,2,3],[4,5,6],[7,8,9]], [1], [1], 0, R),
    nth0(1, R, Row), nth0(1, Row, V), V =:= 0.

test(fill_entire_cross) :-
    stripe_cross_fill([[1,2,3],[4,5,6],[7,8,9]], [0,1,2], [0,1,2], 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

test(fill_one_row_one_col) :-
    stripe_cross_fill([[1,2],[3,4]], [0], [0], 9, R),
    R = [[9,9],[9,4]].

:- end_tests(stripe_cross_fill).
