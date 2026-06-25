% test_diagonal.pl - PLUnit tests for the diagonal pack (Layer 98: dg_* predicates).
:- use_module('../prolog/diagonal').

% Tests for dg_main_diag/2

:- begin_tests(dg_main_diag).

test(square_main_diag) :-
    dg_main_diag([[1,2,3],[4,5,6],[7,8,9]], D),
    D = [1,5,9].

test(wider_grid) :-
    dg_main_diag([[1,2,3],[4,5,6]], D),
    D = [1,5].

test(taller_grid) :-
    dg_main_diag([[1,2],[3,4],[5,6]], D),
    D = [1,4].

:- end_tests(dg_main_diag).

% Tests for dg_anti_diag/2

:- begin_tests(dg_anti_diag).

test(square_anti_diag) :-
    dg_anti_diag([[1,2,3],[4,5,6],[7,8,9]], D),
    D = [3,5,7].

test(wider_anti_diag) :-
    dg_anti_diag([[1,2,3],[4,5,6]], D),
    D = [3,5].

test(single_row) :-
    dg_anti_diag([[1,2,3]], D),
    D = [3].

:- end_tests(dg_anti_diag).

% Tests for dg_nth_diag/3

:- begin_tests(dg_nth_diag).

test(main_diagonal_is_zero) :-
    dg_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 0, D),
    D = [1,5,9].

test(superdiagonal_n1) :-
    dg_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 1, D),
    D = [2,6].

test(subdiagonal_neg1) :-
    dg_nth_diag([[1,2,3],[4,5,6],[7,8,9]], -1, D),
    D = [4,8].

:- end_tests(dg_nth_diag).

% Tests for dg_nth_anti_diag/3

:- begin_tests(dg_nth_anti_diag).

test(top_left_corner) :-
    dg_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 0, D),
    D = [1].

test(middle_anti_diag) :-
    dg_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, D),
    D = [3,5,7].

test(near_bottom_right) :-
    dg_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 3, D),
    D = [6,8].

:- end_tests(dg_nth_anti_diag).

% Tests for dg_all_diags/2

:- begin_tests(dg_all_diags).

test(two_by_two_count) :-
    dg_all_diags([[1,2],[3,4]], Diags),
    length(Diags, 3).

test(two_by_two_main) :-
    dg_all_diags([[1,2],[3,4]], Diags),
    nth0(1, Diags, Main),
    Main = [1,4].

test(three_by_three_count) :-
    dg_all_diags([[1,2,3],[4,5,6],[7,8,9]], Diags),
    length(Diags, 5).

:- end_tests(dg_all_diags).

% Tests for dg_all_anti_diags/2

:- begin_tests(dg_all_anti_diags).

test(two_by_two_count) :-
    dg_all_anti_diags([[1,2],[3,4]], ADiags),
    length(ADiags, 3).

test(two_by_two_middle) :-
    dg_all_anti_diags([[1,2],[3,4]], ADiags),
    nth0(1, ADiags, Mid),
    Mid = [2,3].

test(three_by_three_count) :-
    dg_all_anti_diags([[1,2,3],[4,5,6],[7,8,9]], ADiags),
    length(ADiags, 5).

:- end_tests(dg_all_anti_diags).

% Tests for dg_fill_main/3

:- begin_tests(dg_fill_main).

test(fill_main_square) :-
    dg_fill_main([[1,2,3],[4,5,6],[7,8,9]], 0, R),
    R = [[0,2,3],[4,0,6],[7,8,0]].

test(fill_main_wider) :-
    dg_fill_main([[1,2,3],[4,5,6]], 0, R),
    R = [[0,2,3],[4,0,6]].

test(fill_main_already_filled) :-
    dg_fill_main([[0,1],[2,0]], 9, R),
    R = [[9,1],[2,9]].

:- end_tests(dg_fill_main).

% Tests for dg_fill_anti/3

:- begin_tests(dg_fill_anti).

test(fill_anti_square) :-
    dg_fill_anti([[1,2,3],[4,5,6],[7,8,9]], 0, R),
    R = [[1,2,0],[4,0,6],[0,8,9]].

test(fill_anti_wider) :-
    dg_fill_anti([[1,2,3],[4,5,6]], 0, R),
    R = [[1,2,0],[4,0,6]].

test(fill_anti_different_color) :-
    dg_fill_anti([[1,2],[3,4]], 9, R),
    R = [[1,9],[9,4]].

:- end_tests(dg_fill_anti).

% Tests for dg_fill_nth_diag/4

:- begin_tests(dg_fill_nth_diag).

test(fill_main_diag) :-
    dg_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 0, 0, R),
    R = [[0,2,3],[4,0,6],[7,8,0]].

test(fill_superdiag) :-
    dg_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 1, 0, R),
    R = [[1,0,3],[4,5,0],[7,8,9]].

test(fill_subdiag) :-
    dg_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], -1, 0, R),
    R = [[1,2,3],[0,5,6],[7,0,9]].

:- end_tests(dg_fill_nth_diag).

% Tests for dg_fill_nth_anti_diag/4

:- begin_tests(dg_fill_nth_anti_diag).

test(fill_corner_anti_diag) :-
    dg_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 0, 0, R),
    R = [[0,2,3],[4,5,6],[7,8,9]].

test(fill_main_anti_diag) :-
    dg_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, 0, R),
    R = [[1,2,0],[4,0,6],[0,8,9]].

test(fill_near_last_anti_diag) :-
    dg_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 3, 0, R),
    R = [[1,2,3],[4,5,0],[7,0,9]].

:- end_tests(dg_fill_nth_anti_diag).

% Tests for dg_cell_diag/3

:- begin_tests(dg_cell_diag).

test(main_diag_cell) :-
    dg_cell_diag(2, 2, N), N =:= 0.

test(above_main) :-
    dg_cell_diag(0, 2, N), N =:= 2.

test(below_main) :-
    dg_cell_diag(2, 0, N), N =:= -2.

:- end_tests(dg_cell_diag).

% Tests for dg_cell_anti_diag/3

:- begin_tests(dg_cell_anti_diag).

test(top_left) :-
    dg_cell_anti_diag(0, 0, N), N =:= 0.

test(top_right) :-
    dg_cell_anti_diag(0, 2, N), N =:= 2.

test(bottom_right) :-
    dg_cell_anti_diag(2, 2, N), N =:= 4.

:- end_tests(dg_cell_anti_diag).

% Tests for dg_uniform_diag/3

:- begin_tests(dg_uniform_diag).

test(uniform_main_diag) :-
    dg_uniform_diag([[5,1],[2,5]], 0, C), C =:= 5.

test(non_uniform_fails, [fail]) :-
    dg_uniform_diag([[1,2,3],[4,5,6],[7,8,9]], 0, _).

test(uniform_subdiag) :-
    dg_uniform_diag([[0,0,0],[0,0,0]], -1, C), C =:= 0.

:- end_tests(dg_uniform_diag).

% Tests for dg_uniform_anti_diag/3

:- begin_tests(dg_uniform_anti_diag).

test(uniform_anti_diag) :-
    dg_uniform_anti_diag([[1,5],[5,2]], 1, C), C =:= 5.

test(non_uniform_fails, [fail]) :-
    dg_uniform_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, _).

test(single_cell_anti_diag) :-
    dg_uniform_anti_diag([[1,2],[3,4]], 0, C), C =:= 1.

:- end_tests(dg_uniform_anti_diag).
