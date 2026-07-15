% test_diagonal.pl - PLUnit tests for the diagonal pack (Layer 98: dg_* predicates).
:- use_module('../prolog/diagonal').

% Tests for diagonal_main_diag/2

:- begin_tests(diagonal_main_diag).

test(square_main_diag) :-
    diagonal_main_diag([[1,2,3],[4,5,6],[7,8,9]], D),
    D = [1,5,9].

test(wider_grid) :-
    diagonal_main_diag([[1,2,3],[4,5,6]], D),
    D = [1,5].

test(taller_grid) :-
    diagonal_main_diag([[1,2],[3,4],[5,6]], D),
    D = [1,4].

:- end_tests(diagonal_main_diag).

% Tests for diagonal_anti_diag/2

:- begin_tests(diagonal_anti_diag).

test(square_anti_diag) :-
    diagonal_anti_diag([[1,2,3],[4,5,6],[7,8,9]], D),
    D = [3,5,7].

test(wider_anti_diag) :-
    diagonal_anti_diag([[1,2,3],[4,5,6]], D),
    D = [3,5].

test(single_row) :-
    diagonal_anti_diag([[1,2,3]], D),
    D = [3].

:- end_tests(diagonal_anti_diag).

% Tests for diagonal_nth_diag/3

:- begin_tests(diagonal_nth_diag).

test(main_diagonal_is_zero) :-
    diagonal_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 0, D),
    D = [1,5,9].

test(superdiagonal_n1) :-
    diagonal_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 1, D),
    D = [2,6].

test(subdiagonal_neg1) :-
    diagonal_nth_diag([[1,2,3],[4,5,6],[7,8,9]], -1, D),
    D = [4,8].

:- end_tests(diagonal_nth_diag).

% Tests for diagonal_nth_anti_diag/3

:- begin_tests(diagonal_nth_anti_diag).

test(top_left_corner) :-
    diagonal_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 0, D),
    D = [1].

test(middle_anti_diag) :-
    diagonal_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, D),
    D = [3,5,7].

test(near_bottom_right) :-
    diagonal_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 3, D),
    D = [6,8].

:- end_tests(diagonal_nth_anti_diag).

% Tests for diagonal_all_diags/2

:- begin_tests(diagonal_all_diags).

test(two_by_two_count) :-
    diagonal_all_diags([[1,2],[3,4]], Diags),
    length(Diags, 3).

test(two_by_two_main) :-
    diagonal_all_diags([[1,2],[3,4]], Diags),
    nth0(1, Diags, Main),
    Main = [1,4].

test(three_by_three_count) :-
    diagonal_all_diags([[1,2,3],[4,5,6],[7,8,9]], Diags),
    length(Diags, 5).

:- end_tests(diagonal_all_diags).

% Tests for diagonal_all_anti_diags/2

:- begin_tests(diagonal_all_anti_diags).

test(two_by_two_count) :-
    diagonal_all_anti_diags([[1,2],[3,4]], ADiags),
    length(ADiags, 3).

test(two_by_two_middle) :-
    diagonal_all_anti_diags([[1,2],[3,4]], ADiags),
    nth0(1, ADiags, Mid),
    Mid = [2,3].

test(three_by_three_count) :-
    diagonal_all_anti_diags([[1,2,3],[4,5,6],[7,8,9]], ADiags),
    length(ADiags, 5).

:- end_tests(diagonal_all_anti_diags).

% Tests for diagonal_fill_main/3

:- begin_tests(diagonal_fill_main).

test(fill_main_square) :-
    diagonal_fill_main([[1,2,3],[4,5,6],[7,8,9]], 0, R),
    R = [[0,2,3],[4,0,6],[7,8,0]].

test(fill_main_wider) :-
    diagonal_fill_main([[1,2,3],[4,5,6]], 0, R),
    R = [[0,2,3],[4,0,6]].

test(fill_main_already_filled) :-
    diagonal_fill_main([[0,1],[2,0]], 9, R),
    R = [[9,1],[2,9]].

:- end_tests(diagonal_fill_main).

% Tests for diagonal_fill_anti/3

:- begin_tests(diagonal_fill_anti).

test(fill_anti_square) :-
    diagonal_fill_anti([[1,2,3],[4,5,6],[7,8,9]], 0, R),
    R = [[1,2,0],[4,0,6],[0,8,9]].

test(fill_anti_wider) :-
    diagonal_fill_anti([[1,2,3],[4,5,6]], 0, R),
    R = [[1,2,0],[4,0,6]].

test(fill_anti_different_color) :-
    diagonal_fill_anti([[1,2],[3,4]], 9, R),
    R = [[1,9],[9,4]].

:- end_tests(diagonal_fill_anti).

% Tests for diagonal_fill_nth_diag/4

:- begin_tests(diagonal_fill_nth_diag).

test(fill_main_diag) :-
    diagonal_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 0, 0, R),
    R = [[0,2,3],[4,0,6],[7,8,0]].

test(fill_superdiag) :-
    diagonal_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], 1, 0, R),
    R = [[1,0,3],[4,5,0],[7,8,9]].

test(fill_subdiag) :-
    diagonal_fill_nth_diag([[1,2,3],[4,5,6],[7,8,9]], -1, 0, R),
    R = [[1,2,3],[0,5,6],[7,0,9]].

:- end_tests(diagonal_fill_nth_diag).

% Tests for diagonal_fill_nth_anti_diag/4

:- begin_tests(diagonal_fill_nth_anti_diag).

test(fill_corner_anti_diag) :-
    diagonal_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 0, 0, R),
    R = [[0,2,3],[4,5,6],[7,8,9]].

test(fill_main_anti_diag) :-
    diagonal_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, 0, R),
    R = [[1,2,0],[4,0,6],[0,8,9]].

test(fill_near_last_anti_diag) :-
    diagonal_fill_nth_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 3, 0, R),
    R = [[1,2,3],[4,5,0],[7,0,9]].

:- end_tests(diagonal_fill_nth_anti_diag).

% Tests for diagonal_cell_diag/3

:- begin_tests(diagonal_cell_diag).

test(main_diag_cell) :-
    diagonal_cell_diag(2, 2, N), N =:= 0.

test(above_main) :-
    diagonal_cell_diag(0, 2, N), N =:= 2.

test(below_main) :-
    diagonal_cell_diag(2, 0, N), N =:= -2.

:- end_tests(diagonal_cell_diag).

% Tests for diagonal_cell_anti_diag/3

:- begin_tests(diagonal_cell_anti_diag).

test(top_left) :-
    diagonal_cell_anti_diag(0, 0, N), N =:= 0.

test(top_right) :-
    diagonal_cell_anti_diag(0, 2, N), N =:= 2.

test(bottom_right) :-
    diagonal_cell_anti_diag(2, 2, N), N =:= 4.

:- end_tests(diagonal_cell_anti_diag).

% Tests for diagonal_uniform_diag/3

:- begin_tests(diagonal_uniform_diag).

test(uniform_main_diag) :-
    diagonal_uniform_diag([[5,1],[2,5]], 0, C), C =:= 5.

test(non_uniform_fails, [fail]) :-
    diagonal_uniform_diag([[1,2,3],[4,5,6],[7,8,9]], 0, _).

test(uniform_subdiag) :-
    diagonal_uniform_diag([[0,0,0],[0,0,0]], -1, C), C =:= 0.

:- end_tests(diagonal_uniform_diag).

% Tests for diagonal_uniform_anti_diag/3

:- begin_tests(diagonal_uniform_anti_diag).

test(uniform_anti_diag) :-
    diagonal_uniform_anti_diag([[1,5],[5,2]], 1, C), C =:= 5.

test(non_uniform_fails, [fail]) :-
    diagonal_uniform_anti_diag([[1,2,3],[4,5,6],[7,8,9]], 2, _).

test(single_cell_anti_diag) :-
    diagonal_uniform_anti_diag([[1,2],[3,4]], 0, C), C =:= 1.

:- end_tests(diagonal_uniform_anti_diag).
