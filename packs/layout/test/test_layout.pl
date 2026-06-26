:- use_module('../prolog/layout.pl').
:- use_module(library(plunit)).

% Helpers: a row of 3 single-cell objects.
row3([obj(red,[r(0,0)]), obj(blue,[r(0,2)]), obj(green,[r(0,4)])]).
% Three objects in the same column.
col3([obj(red,[r(0,0)]), obj(blue,[r(2,0)]), obj(green,[r(4,0)])]).
% 2x2 grid of single cells.
grid22([obj(a,[r(0,0)]), obj(b,[r(0,2)]), obj(c,[r(2,0)]), obj(d,[r(2,2)])]).
% Downward-right diagonal: (0,0),(1,1),(2,2) -> R-C = 0 for all.
diag_dr([obj(a,[r(0,0)]), obj(b,[r(1,1)]), obj(c,[r(2,2)])]).
% Downward-left diagonal: (0,2),(1,1),(2,0) -> R+C = 2 for all.
diag_dl([obj(a,[r(0,2)]), obj(b,[r(1,1)]), obj(c,[r(2,0)])]).
% Multi-cell objects for bbox tests.
biobj(obj(red,[r(0,0),r(0,1),r(1,0),r(1,1)])).

:- begin_tests(lt_global_bbox).

test(single_cell) :-
    lt_global_bbox([obj(red,[r(3,5)])], 3, 5, 3, 5).

test(multi_obj_row) :-
    row3(Objs),
    lt_global_bbox(Objs, R1, C1, R2, C2),
    R1 =:= 0, C1 =:= 0, R2 =:= 0, C2 =:= 4.

test(multi_cell_obj) :-
    biobj(O),
    lt_global_bbox([O], 0, 0, 1, 1).

test(mixed_objs) :-
    % Obj1 at (0,0), Obj2 at (3,5): bbox is (0,0)-(3,5).
    lt_global_bbox(
        [obj(a,[r(0,0)]), obj(b,[r(3,5)])],
        0, 0, 3, 5).

:- end_tests(lt_global_bbox).

:- begin_tests(lt_bbox_area).

test(single_cell) :-
    lt_bbox_area([obj(red,[r(0,0)])], 1).

test(row_of_three) :-
    % Bbox spans rows 0-0, cols 0-4: area = 1 * 5 = 5.
    row3(Objs), lt_bbox_area(Objs, 5).

test(grid22) :-
    % Bbox spans rows 0-2, cols 0-2: area = 3 * 3 = 9.
    grid22(Objs), lt_bbox_area(Objs, 9).

:- end_tests(lt_bbox_area).

:- begin_tests(lt_row_range).

test(single_obj) :-
    lt_row_range([obj(red,[r(2,0)])], 2, 2).

test(row3_all_same) :-
    row3(Objs), lt_row_range(Objs, 0, 0).

test(col3_diff_rows) :-
    col3(Objs), lt_row_range(Objs, 0, 4).

test(mixed) :-
    lt_row_range([obj(a,[r(1,0)]), obj(b,[r(3,0)]), obj(c,[r(2,0)])], 1, 3).

:- end_tests(lt_row_range).

:- begin_tests(lt_col_range).

test(single_obj) :-
    lt_col_range([obj(red,[r(0,3)])], 3, 3).

test(col3_all_same) :-
    col3(Objs), lt_col_range(Objs, 0, 0).

test(row3_diff_cols) :-
    row3(Objs), lt_col_range(Objs, 0, 4).

:- end_tests(lt_col_range).

:- begin_tests(lt_all_same_row).

test(empty) :-
    lt_all_same_row([]).

test(single) :-
    lt_all_same_row([obj(red,[r(0,0)])]).

test(row3_true) :-
    row3(Objs), lt_all_same_row(Objs).

test(col3_false) :-
    col3(Objs), \+ lt_all_same_row(Objs).

test(mixed_true) :-
    % Objects at (0,0), (0,3), (0,7): same row 0.
    lt_all_same_row([obj(a,[r(0,0)]), obj(b,[r(0,3)]), obj(c,[r(0,7)])]).

:- end_tests(lt_all_same_row).

:- begin_tests(lt_all_same_col).

test(empty) :-
    lt_all_same_col([]).

test(single) :-
    lt_all_same_col([obj(red,[r(0,0)])]).

test(col3_true) :-
    col3(Objs), lt_all_same_col(Objs).

test(row3_false) :-
    row3(Objs), \+ lt_all_same_col(Objs).

:- end_tests(lt_all_same_col).

:- begin_tests(lt_centroid_of_all).

test(single_cell) :-
    lt_centroid_of_all([obj(a,[r(2,4)])], 2, 4).

test(two_objs) :-
    % Centroids (0,0) and (4,4): average = (2,2).
    lt_centroid_of_all([obj(a,[r(0,0)]), obj(b,[r(4,4)])], 2, 2).

test(three_objs_truncate) :-
    % Centroids (0,0),(0,1),(0,2): avg col = 1.
    lt_centroid_of_all([obj(a,[r(0,0)]), obj(b,[r(0,1)]), obj(c,[r(0,2)])], 0, 1).

:- end_tests(lt_centroid_of_all).

:- begin_tests(lt_row_count).

test(single_obj) :-
    lt_row_count([obj(a,[r(0,0)])], 1).

test(row3_one_row) :-
    row3(Objs), lt_row_count(Objs, 1).

test(col3_three_rows) :-
    col3(Objs), lt_row_count(Objs, 3).

test(grid22_two_rows) :-
    grid22(Objs), lt_row_count(Objs, 2).

:- end_tests(lt_row_count).

:- begin_tests(lt_col_count).

test(single_obj) :-
    lt_col_count([obj(a,[r(0,0)])], 1).

test(col3_one_col) :-
    col3(Objs), lt_col_count(Objs, 1).

test(row3_three_cols) :-
    row3(Objs), lt_col_count(Objs, 3).

test(grid22_two_cols) :-
    grid22(Objs), lt_col_count(Objs, 2).

:- end_tests(lt_col_count).

:- begin_tests(lt_is_grid).

test(grid22_basic) :-
    grid22(Objs), lt_is_grid(Objs, 2, 2).

test(row3_is_1x3) :-
    % All same row: 1 distinct centroid row, 3 distinct centroid cols -> 1x3 grid.
    row3(Objs), lt_is_grid(Objs, 1, 3).

test(col3_is_3x1) :-
    % All same col: 3 distinct centroid rows, 1 col -> 3x1 grid.
    col3(Objs), lt_is_grid(Objs, 3, 1).

test(non_grid_missing_cell) :-
    % 3 objs at (0,0),(0,2),(2,0): missing (2,2), so NOT a 2x2 grid.
    \+ lt_is_grid(
        [obj(a,[r(0,0)]), obj(b,[r(0,2)]), obj(c,[r(2,0)])],
        2, 2).

test(single_obj_is_1x1) :-
    lt_is_grid([obj(a,[r(0,0)])], 1, 1).

:- end_tests(lt_is_grid).

:- begin_tests(lt_is_diagonal_dr).

test(empty) :-
    lt_is_diagonal_dr([]).

test(single) :-
    lt_is_diagonal_dr([obj(a,[r(2,3)])]).

test(diagonal_true) :-
    % (0,0),(1,1),(2,2): R-C = 0 for all.
    diag_dr(Objs), lt_is_diagonal_dr(Objs).

test(diagonal_false) :-
    % (0,0),(1,2),(2,4): R-C = 0,-1,-2: not equal.
    \+ lt_is_diagonal_dr(
        [obj(a,[r(0,0)]), obj(b,[r(1,2)]), obj(c,[r(2,4)])]).

test(offset_diagonal) :-
    % (0,2),(1,3),(2,4): R-C = -2 for all.
    lt_is_diagonal_dr([obj(a,[r(0,2)]), obj(b,[r(1,3)]), obj(c,[r(2,4)])]).

:- end_tests(lt_is_diagonal_dr).

:- begin_tests(lt_is_diagonal_dl).

test(empty) :-
    lt_is_diagonal_dl([]).

test(single) :-
    lt_is_diagonal_dl([obj(a,[r(2,3)])]).

test(diagonal_true) :-
    % (0,2),(1,1),(2,0): R+C = 2 for all.
    diag_dl(Objs), lt_is_diagonal_dl(Objs).

test(diagonal_false) :-
    % Row3 objs at (0,0),(0,2),(0,4): R+C = 0,2,4: not equal.
    row3(Objs), \+ lt_is_diagonal_dl(Objs).

:- end_tests(lt_is_diagonal_dl).

:- begin_tests(lt_gap_h).

test(uniform_gap) :-
    % Row3: cols 0,2,4 -> gaps 2,2 -> uniform gap 2.
    row3(Objs), lt_gap_h(Objs, 2).

test(gap_1) :-
    lt_gap_h([obj(a,[r(0,0)]), obj(b,[r(0,1)]), obj(c,[r(0,2)])], 1).

test(non_uniform_fails) :-
    \+ lt_gap_h(
        [obj(a,[r(0,0)]), obj(b,[r(0,1)]), obj(c,[r(0,3)])],
        _).

test(single_pair_gap) :-
    lt_gap_h([obj(a,[r(0,0)]), obj(b,[r(0,3)])], 3).

:- end_tests(lt_gap_h).

:- begin_tests(lt_gap_v).

test(uniform_gap) :-
    % Col3: rows 0,2,4 -> gaps 2,2 -> uniform gap 2.
    col3(Objs), lt_gap_v(Objs, 2).

test(gap_1) :-
    lt_gap_v([obj(a,[r(0,0)]), obj(b,[r(1,0)]), obj(c,[r(2,0)])], 1).

test(non_uniform_fails) :-
    \+ lt_gap_v(
        [obj(a,[r(0,0)]), obj(b,[r(1,0)]), obj(c,[r(3,0)])],
        _).

test(single_pair_gap) :-
    lt_gap_v([obj(a,[r(0,0)]), obj(b,[r(4,0)])], 4).

:- end_tests(lt_gap_v).
