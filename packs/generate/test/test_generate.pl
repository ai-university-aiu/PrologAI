% PLUnit tests for the generate pack (ge_* predicates).
:- use_module(library(plunit)).
:- use_module(library(generate)).

:- begin_tests(generate_ge_uniform).

test(uniform_2x3) :-
    generate_uniform(2, 3, 5, G),
    G = [[5,5,5],[5,5,5]].

test(uniform_1x1) :-
    generate_uniform(1, 1, 0, G),
    G = [[0]].

test(uniform_zero_color) :-
    generate_uniform(2, 2, 0, G),
    G = [[0,0],[0,0]].

:- end_tests(generate_ge_uniform).

:- begin_tests(generate_ge_gradient_h).

test(gradient_h_basic) :-
    % 2 rows, 3 cols, 3 colors: col 0->0, col 1->1, col 2->2.
    generate_gradient_h(2, 3, 3, G),
    G = [[0,1,2],[0,1,2]].

test(gradient_h_wrap) :-
    % 1 row, 4 cols, 2 colors: col 0->0, 1->1, 2->0, 3->1.
    generate_gradient_h(1, 4, 2, G),
    G = [[0,1,0,1]].

:- end_tests(generate_ge_gradient_h).

:- begin_tests(generate_ge_gradient_v).

test(gradient_v_basic) :-
    % 3 rows, 2 cols, 3 colors: row 0->0, row 1->1, row 2->2.
    generate_gradient_v(3, 2, 3, G),
    G = [[0,0],[1,1],[2,2]].

test(gradient_v_wrap) :-
    % 4 rows, 1 col, 2 colors: row 0->0, 1->1, 2->0, 3->1.
    generate_gradient_v(4, 1, 2, G),
    G = [[0],[1],[0],[1]].

:- end_tests(generate_ge_gradient_v).

:- begin_tests(generate_ge_checkerboard).

test(checker_2x2) :-
    generate_checkerboard(2, 2, 0, 1, G),
    G = [[0,1],[1,0]].

test(checker_3x3) :-
    generate_checkerboard(3, 3, 0, 1, G),
    G = [[0,1,0],[1,0,1],[0,1,0]].

test(checker_colors) :-
    generate_checkerboard(2, 2, 3, 7, G),
    G = [[3,7],[7,3]].

:- end_tests(generate_ge_checkerboard).

:- begin_tests(generate_ge_stripes_h).

test(stripes_h_basic) :-
    generate_stripes_h(3, 2, [1,2,3], G),
    G = [[1,1],[2,2],[3,3]].

test(stripes_h_wrap) :-
    generate_stripes_h(4, 2, [1,2], G),
    G = [[1,1],[2,2],[1,1],[2,2]].

:- end_tests(generate_ge_stripes_h).

:- begin_tests(generate_ge_stripes_v).

test(stripes_v_basic) :-
    generate_stripes_v(2, 3, [1,2,3], G),
    G = [[1,2,3],[1,2,3]].

test(stripes_v_wrap) :-
    generate_stripes_v(2, 4, [1,2], G),
    G = [[1,2,1,2],[1,2,1,2]].

:- end_tests(generate_ge_stripes_v).

:- begin_tests(generate_ge_border_rect).

test(border_3x3) :-
    generate_border_rect(3, 3, 1, 0, G),
    G = [[1,1,1],[1,0,1],[1,1,1]].

test(border_4x4) :-
    generate_border_rect(4, 4, 5, 0, G),
    G = [[5,5,5,5],[5,0,0,5],[5,0,0,5],[5,5,5,5]].

:- end_tests(generate_ge_border_rect).

:- begin_tests(generate_ge_diagonal).

test(diag_3x3) :-
    generate_diagonal(3, 3, 1, G),
    G = [[1,0,0],[0,1,0],[0,0,1]].

test(diag_2x3) :-
    generate_diagonal(2, 3, 5, G),
    G = [[5,0,0],[0,5,0]].

:- end_tests(generate_ge_diagonal).

:- begin_tests(generate_ge_antidiagonal).

test(antidiag_3x3) :-
    generate_antidiagonal(3, 3, 1, G),
    G = [[0,0,1],[0,1,0],[1,0,0]].

:- end_tests(generate_ge_antidiagonal).

:- begin_tests(generate_ge_frame).

test(frame_3x3) :-
    generate_frame(3, 3, 1, 0, G),
    G = [[1,1,1],[1,0,1],[1,1,1]].

test(frame_4x4) :-
    generate_frame(4, 4, 2, 0, G),
    G = [[2,2,2,2],[2,0,0,2],[2,0,0,2],[2,2,2,2]].

:- end_tests(generate_ge_frame).

:- begin_tests(generate_ge_cross).

test(cross_3x3) :-
    generate_cross(3, 3, 1, 0, G),
    G = [[0,1,0],[1,1,1],[0,1,0]].

test(cross_5x5) :-
    generate_cross(5, 5, 1, 0, G),
    nth0(2, G, MidRow), MidRow = [1,1,1,1,1],
    nth0(0, G, TopRow), nth0(2, TopRow, 1),
    nth0(0, TopRow, 0).

:- end_tests(generate_ge_cross).

:- begin_tests(generate_ge_identity_grid).

test(identity_3x3) :-
    generate_identity_grid(3, 1, G),
    G = [[1,0,0],[0,1,0],[0,0,1]].

test(identity_2x2) :-
    generate_identity_grid(2, 5, G),
    G = [[5,0],[0,5]].

:- end_tests(generate_ge_identity_grid).

:- begin_tests(generate_ge_from_map).

test(from_map_basic) :-
    Map = [r(0,0)-1, r(1,1)-2, r(2,2)-3],
    generate_from_map(3-3, Map, G),
    G = [[1,0,0],[0,2,0],[0,0,3]].

test(from_map_empty) :-
    generate_from_map(2-2, [], G),
    G = [[0,0],[0,0]].

:- end_tests(generate_ge_from_map).

:- begin_tests(generate_ge_repeat_pattern).

test(repeat_pattern_basic) :-
    P = [[1,2],[3,4]],
    generate_repeat_pattern(P, 4, 4, G),
    G = [[1,2,1,2],[3,4,3,4],[1,2,1,2],[3,4,3,4]].

test(repeat_pattern_partial) :-
    P = [[1,2,3]],
    generate_repeat_pattern(P, 2, 5, G),
    G = [[1,2,3,1,2],[1,2,3,1,2]].

:- end_tests(generate_ge_repeat_pattern).
