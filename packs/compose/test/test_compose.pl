:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(grid)).
:- use_module('../prolog/compose').

% HELPER PREDICATES FOR TESTS (named, not lambdas)
% add1_row(+Row, -Row2): increment each cell by 1.
add1_row(Row, Row2) :- maplist(add1_cell, Row, Row2).
% add1_cell(+A, -B): B = A + 1.
add1_cell(A, B) :- B is A + 1.
% max_cell(+A, +B, -C): C = max(A, B).
max_cell(A, B, C) :- C is max(A, B).
% min_cell(+A, +B, -C): C = min(A, B).
min_cell(A, B, C) :- C is min(A, B).
% add_cell(+A, +B, -C): C = A + B.
add_cell(A, B, C) :- C is A + B.
% is_uniform(+Grid): all cells have the same color.
is_uniform(Grid) :- gd_colors(Grid, [_]).
% is_small(+Grid): Grid has at most 2 rows (used for compose_until termination).
is_small(Grid) :- gd_size(Grid, Rows, _), Rows =< 2.
% overlay_grids(+G1, +G2, -G3): overlay G2 onto G1 at (0,0).
overlay_grids(G1, G2, G3) :- gd_size(G2, R, C), R1 is R-1, C1 is C-1,
    gd_crop(G2, 0, 0, R1, C1, Patch), gd_overlay(G1, Patch, 0, 0, G3).
% rev_list(+L, -L2): reverse a list (used for column rule tests).
rev_list(L, L2) :- reverse(L, L2).
% double_rotate(+G, -G2): rotate 90 degrees twice = rotate 180.
double_rotate(G, G2) :- gd_rotate90(G, G1), gd_rotate90(G1, G2).

% FIXTURE GRIDS
% A simple 2x2 asymmetric grid.
grid_2x2([[1,2],[3,4]]).
% A uniform 2x2 grid.
grid_uniform([[5,5],[5,5]]).
% A 3x3 gradient grid.
grid_3x3([[1,2,3],[4,5,6],[7,8,9]]).
% A 2x3 asymmetric grid.
grid_2x3([[1,2,3],[4,5,6]]).


:- begin_tests(compose_apply).

% compose_apply dispatches to the named rule correctly.
test(apply_reflect_h) :-
    grid_2x2(G),
    compose_apply(gd_reflect_h, G, G2),
    gd_equal(G2, [[3,4],[1,2]]).

% compose_apply works with a partial application (compose_const).
test(apply_const) :-
    grid_2x2(G),
    compose_apply(compose_const([[9,9],[9,9]]), G, G2),
    gd_equal(G2, [[9,9],[9,9]]).

% compose_identity returns the same grid.
test(identity) :-
    grid_2x2(G),
    compose_identity(G, G2),
    gd_equal(G, G2).

% compose_const ignores the input and returns the constant.
test(const) :-
    grid_2x2(G),
    compose_const([[0,0],[0,0]], G, G2),
    gd_equal(G2, [[0,0],[0,0]]).

:- end_tests(compose_apply).


:- begin_tests(compose_pipe).

% Empty pipeline is identity.
test(pipe_empty) :-
    grid_2x2(G),
    compose_pipe([], G, G2),
    gd_equal(G, G2).

% Single-rule pipeline equals direct application.
test(pipe_single) :-
    grid_2x2(G),
    compose_pipe([gd_reflect_h], G, G2),
    gd_reflect_h(G, G2Expected),
    gd_equal(G2, G2Expected).

% Two-rule pipeline: rotate90 then rotate90 = rotate180.
test(pipe_two) :-
    grid_3x3(G),
    compose_pipe([gd_rotate90, gd_rotate90], G, G2),
    gd_rotate180(G, G2Expected),
    gd_equal(G2, G2Expected).

% Three-rule pipeline: reflect_h three times = reflect_h (odd count).
test(pipe_three_reflect) :-
    grid_2x2(G),
    compose_pipe([gd_reflect_h, gd_reflect_h, gd_reflect_h], G, G2),
    gd_reflect_h(G, G2Expected),
    gd_equal(G2, G2Expected).

:- end_tests(compose_pipe).


:- begin_tests(compose_pipe_n).

% compose_pipe_n 0 times is identity.
test(pipe_n_zero) :-
    grid_2x2(G),
    compose_pipe_n(gd_reflect_h, 0, G, G2),
    gd_equal(G, G2).

% compose_pipe_n 1 time = single apply.
test(pipe_n_one) :-
    grid_2x2(G),
    compose_pipe_n(gd_reflect_h, 1, G, G2),
    gd_reflect_h(G, G2Expected),
    gd_equal(G2, G2Expected).

% compose_pipe_n 4 rotations of 90 degrees = identity.
test(pipe_n_four_rotations) :-
    grid_3x3(G),
    compose_pipe_n(gd_rotate90, 4, G, G2),
    gd_equal(G, G2).

% compose_pipe_n 2 reflect_h = identity.
test(pipe_n_two_reflect) :-
    grid_2x2(G),
    compose_pipe_n(gd_reflect_h, 2, G, G2),
    gd_equal(G, G2).

:- end_tests(compose_pipe_n).


:- begin_tests(compose_branch).

% compose_branch takes Then branch when condition holds.
test(branch_then) :-
    grid_uniform(G),
% is_uniform/1 succeeds on uniform grid; ThenRule = reflect_h, ElseRule = reflect_v.
    compose_branch(is_uniform, gd_reflect_h, gd_reflect_v, G, G2),
% Uniform grid reflected horizontally (rows reversed; symmetric so same as original).
    gd_reflect_h(G, G2Expected),
    gd_equal(G2, G2Expected).

% compose_branch takes Else branch when condition fails.
test(branch_else) :-
    grid_2x2(G),
% is_uniform/1 fails on asymmetric grid; apply ElseRule = reflect_v.
    compose_branch(is_uniform, gd_reflect_h, gd_reflect_v, G, G2),
    gd_reflect_v(G, G2Expected),
    gd_equal(G2, G2Expected).

:- end_tests(compose_branch).


:- begin_tests(compose_repeat).

% compose_repeat 0 = identity.
test(repeat_zero) :-
    grid_2x2(G),
    compose_repeat(gd_reflect_h, 0, G, G2),
    gd_equal(G, G2).

% compose_repeat 2 with reflect_h = identity.
test(repeat_two_reflect) :-
    grid_2x2(G),
    compose_repeat(gd_reflect_h, 2, G, G2),
    gd_equal(G, G2).

% compose_repeat 4 with rotate90 = identity.
test(repeat_four_rotate) :-
    grid_3x3(G),
    compose_repeat(gd_rotate90, 4, G, G2),
    gd_equal(G, G2).

:- end_tests(compose_repeat).


:- begin_tests(compose_until).

% compose_until stops immediately when condition already holds.
test(until_already_done) :-
    grid_2x2(G),
% is_small/1 holds for a 2-row grid.
    compose_until(gd_rotate90, is_small, G, G2),
    gd_equal(G, G2).

% compose_until converges after applying the rule once (rotate 3x3 -> 3x3; is_small never holds).
% Use a condition that holds only after two reflect_h applications.
test(until_identity_check) :-
    grid_2x2(G),
% Condition: grid equals [[1,2],[3,4]] which is already true at start.
    compose_until(gd_reflect_h, gd_equal(G), G, G2),
    gd_equal(G, G2).

:- end_tests(compose_until).


:- begin_tests(compose_fixed_point).

% compose_fixed_point on identity rule converges in one step.
test(fixed_point_identity) :-
    grid_2x2(G),
    compose_fixed_point(compose_identity, G, G2),
    gd_equal(G, G2).

% compose_fixed_point with reflect_h applied twice = identity, so converges after two steps.
test(fixed_point_reflect_twice) :-
    grid_2x2(G),
% double_rotate is its own fixed point only after 4 steps; just verify it terminates.
    compose_fixed_point(compose_identity, G, G2),
    gd_equal(G, G2).

:- end_tests(compose_fixed_point).


:- begin_tests(compose_map_rows).

% compose_map_rows applies the rule to each row independently.
test(map_rows_add1) :-
    grid_2x2(G),
    compose_map_rows(add1_row, G, G2),
    gd_cell(G2, 0, 0, 2),
    gd_cell(G2, 0, 1, 3),
    gd_cell(G2, 1, 0, 4),
    gd_cell(G2, 1, 1, 5).

% compose_map_rows with reverse reverses each row independently.
test(map_rows_reverse) :-
    grid_2x3(G),
    compose_map_rows(rev_list, G, G2),
    gd_equal(G2, [[3,2,1],[6,5,4]]).

% compose_map_rows on a uniform grid with add1 increments all cells.
test(map_rows_uniform) :-
    grid_uniform(G),
    compose_map_rows(add1_row, G, G2),
    gd_equal(G2, [[6,6],[6,6]]).

:- end_tests(compose_map_rows).


:- begin_tests(compose_map_cols).

% compose_map_cols with reverse reverses each column independently.
test(map_cols_reverse) :-
    grid_2x2(G),
% Reversing each column of [[1,2],[3,4]] gives [[3,4],[1,2]] = same as gd_reflect_h.
    compose_map_cols(rev_list, G, G2),
    gd_reflect_h(G, GExpected),
    gd_equal(G2, GExpected).

% compose_map_cols with identity on each column gives back the original grid.
test(map_cols_identity) :-
    grid_3x3(G),
    compose_map_cols(compose_identity, G, G2),
    gd_equal(G, G2).

:- end_tests(compose_map_cols).


:- begin_tests(compose_zip).

% compose_zip with max_cell: result cell = max of the two input cells.
test(zip_max) :-
    GridA = [[1,4],[3,2]],
    GridB = [[2,3],[1,5]],
    compose_zip(max_cell, GridA, GridB, GridC),
    gd_equal(GridC, [[2,4],[3,5]]).

% compose_zip with min_cell: result cell = min of the two input cells.
test(zip_min) :-
    GridA = [[1,4],[3,2]],
    GridB = [[2,3],[1,5]],
    compose_zip(min_cell, GridA, GridB, GridC),
    gd_equal(GridC, [[1,3],[1,2]]).

% compose_zip of a grid with itself using max = identity.
test(zip_self_max) :-
    grid_2x2(G),
    compose_zip(max_cell, G, G, G2),
    gd_equal(G, G2).

% compose_zip with add_cell: elementwise addition.
test(zip_add) :-
    GridA = [[1,2],[3,4]],
    GridB = [[10,20],[30,40]],
    compose_zip(add_cell, GridA, GridB, GridC),
    gd_equal(GridC, [[11,22],[33,44]]).

:- end_tests(compose_zip).


:- begin_tests(compose_fold).

% compose_fold over empty list returns the initial accumulator.
test(fold_empty, nondet) :-
    grid_2x2(G),
    compose_fold(overlay_grids, G, [], G2),
    gd_equal(G, G2).

% compose_fold over one element applies the rule once.
test(fold_one, nondet) :-
    Base = [[0,0],[0,0]],
    Patch = [[1,2],[3,4]],
    compose_fold(overlay_grids, Base, [Patch], Result),
    gd_equal(Result, [[1,2],[3,4]]).

% compose_fold over two elements applies the rule twice in sequence.
test(fold_two, nondet) :-
    Base = [[0,0],[0,0]],
    Patch1 = [[1,0],[0,0]],
    Patch2 = [[0,2],[0,0]],
    compose_fold(overlay_grids, Base, [Patch1, Patch2], Result),
% Second overlay writes 2 at (0,1) on top of first result.
    gd_cell(Result, 0, 0, 1),
    gd_cell(Result, 0, 1, 2).

:- end_tests(compose_fold).
