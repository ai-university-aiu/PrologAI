:- use_module('../prolog/objseq').
:- use_module(library(plunit)).

:- begin_tests(objseq).

% --- Test fixtures ---
% dot1: single-cell obj at r(0,0), color r, size 1.
dot1(obj(r, [r(0,0)])).
% dot2: single-cell obj at r(0,2), color b, size 1.
dot2(obj(b, [r(0,2)])).
% dot3: single-cell obj at r(0,4), color g, size 1.
dot3(obj(g, [r(0,4)])).
% bar2: two-cell obj at r(1,0)-r(1,1), color b, size 2.
bar2(obj(b, [r(1,0),r(1,1)])).
% bar3: three-cell obj at r(2,0)-r(2,2), color g, size 3.
bar3(obj(g, [r(2,0),r(2,1),r(2,2)])).
% bar4: four-cell obj at r(3,0)-r(3,3), color y, size 4.
bar4(obj(y, [r(3,0),r(3,1),r(3,2),r(3,3)])).
% col0: single-cell at r(0,0), color r, size 1.
col0(obj(r, [r(0,0)])).
% col1: single-cell at r(2,0), color r, size 1 (2 rows below col0).
col1(obj(r, [r(2,0)])).
% col2: single-cell at r(4,0), color r, size 1 (2 rows below col1).
col2(obj(r, [r(4,0)])).
% off1: single-cell at r(0,0), color r, size 1.
off1(obj(r, [r(0,0)])).
% off2: single-cell at r(1,3), color g, size 1 (inconsistent col step).
off2(obj(g, [r(1,3)])).
% off3: single-cell at r(2,5), color b, size 1 (inconsistent col step again).
off3(obj(b, [r(2,5)])).

% --- oq_color_seq/2 ---

test(color_seq_basic) :-
    dot1(A), dot2(B), dot3(C),
    oq_color_seq([A,B,C], Colors),
    Colors == [r,b,g].

test(color_seq_single) :-
    bar2(X),
    oq_color_seq([X], Colors),
    Colors == [b].

test(color_seq_empty) :-
    oq_color_seq([], Colors),
    Colors == [].

% --- oq_size_seq/2 ---

test(size_seq_basic) :-
    bar2(A), bar3(B), bar4(C),
    oq_size_seq([A,B,C], Sizes),
    Sizes == [2,3,4].

test(size_seq_single) :-
    dot1(X),
    oq_size_seq([X], Sizes),
    Sizes == [1].

test(size_seq_empty) :-
    oq_size_seq([], Sizes),
    Sizes == [].

% --- oq_centroid_seq/2 ---

test(centroid_seq_basic) :-
    dot1(A), dot2(B), dot3(C),
    oq_centroid_seq([A,B,C], Cs),
    Cs == [r(0,0), r(0,2), r(0,4)].

test(centroid_seq_bar) :-
    bar3(X),
    oq_centroid_seq([X], Cs),
    Cs == [r(2,1)].

test(centroid_seq_empty) :-
    oq_centroid_seq([], Cs),
    Cs == [].

% --- oq_step_seq/2 ---

test(step_seq_basic) :-
    col0(A), col1(B), col2(C),
    oq_step_seq([A,B,C], Steps),
    Steps == [dr(2,0), dr(2,0)].

test(step_seq_one_element) :-
    dot1(X),
    oq_step_seq([X], Steps),
    Steps == [].

test(step_seq_empty) :-
    oq_step_seq([], Steps),
    Steps == [].

% --- oq_is_growing/1 ---

test(is_growing_yes) :-
    bar2(A), bar3(B), bar4(C),
    oq_is_growing([A,B,C]).

test(is_growing_no_equal, [fail]) :-
    bar2(A), bar2(B),
    oq_is_growing([A,B]).

test(is_growing_no_decreasing, [fail]) :-
    bar4(A), bar3(B), bar2(C),
    oq_is_growing([A,B,C]).

% --- oq_is_shrinking/1 ---

test(is_shrinking_yes) :-
    bar4(A), bar3(B), bar2(C),
    oq_is_shrinking([A,B,C]).

test(is_shrinking_no_equal, [fail]) :-
    bar3(A), bar3(B),
    oq_is_shrinking([A,B]).

test(is_shrinking_no_increasing, [fail]) :-
    bar2(A), bar3(B), bar4(C),
    oq_is_shrinking([A,B,C]).

% --- oq_const_step/3 ---

test(const_step_yes) :-
    col0(A), col1(B), col2(C),
    oq_const_step([A,B,C], DR, DC),
    DR == 2, DC == 0.

test(const_step_fail_inconsistent, [fail]) :-
    off1(A), off2(B), off3(C),
    oq_const_step([A,B,C], _, _).

test(const_step_fail_single, [fail]) :-
    dot1(X),
    oq_const_step([X], _, _).

% --- oq_const_row_step/2 ---

test(const_row_step_yes) :-
    col0(A), col1(B), col2(C),
    oq_const_row_step([A,B,C], DR),
    DR == 2.

test(const_row_step_with_varying_col) :-
    off1(A), off2(B), off3(C),
    oq_const_row_step([A,B,C], DR),
    DR == 1.

test(const_row_step_fail_single, [fail]) :-
    dot1(X),
    oq_const_row_step([X], _).

% --- oq_const_col_step/2 ---

test(const_col_step_yes) :-
    dot1(A), dot2(B), dot3(C),
    oq_const_col_step([A,B,C], DC),
    DC == 2.

test(const_col_step_fail_inconsistent, [fail]) :-
    off1(A), off2(B), off3(C),
    oq_const_col_step([A,B,C], _).

test(const_col_step_fail_single, [fail]) :-
    dot1(X),
    oq_const_col_step([X], _).

% --- oq_color_period/3 ---

test(color_period_1) :-
    A = obj(r,[r(0,0)]), B = obj(r,[r(1,0)]), C = obj(r,[r(2,0)]),
    oq_color_period([A,B,C], P, Cycle),
    P == 1, Cycle == [r].

test(color_period_2) :-
    A = obj(r,[r(0,0)]), B = obj(b,[r(0,1)]),
    C = obj(r,[r(0,2)]), D = obj(b,[r(0,3)]),
    oq_color_period([A,B,C,D], P, Cycle),
    P == 2, Cycle == [r,b].

test(color_period_3) :-
    A = obj(r,[r(0,0)]), B = obj(g,[r(0,1)]), C = obj(b,[r(0,2)]),
    D = obj(r,[r(0,3)]), E = obj(g,[r(0,4)]), F = obj(b,[r(0,5)]),
    oq_color_period([A,B,C,D,E,F], P, Cycle),
    P == 3, Cycle == [r,g,b].

% --- oq_size_period/3 ---

test(size_period_1) :-
    A = obj(r,[r(0,0)]), B = obj(b,[r(1,0)]),
    C = obj(g,[r(2,0)]),
    oq_size_period([A,B,C], P, Cycle),
    P == 1, Cycle == [1].

test(size_period_2) :-
    A = obj(r,[r(0,0)]),
    B = obj(b,[r(0,1),r(0,2)]),
    C = obj(g,[r(1,0)]),
    D = obj(y,[r(1,1),r(1,2)]),
    oq_size_period([A,B,C,D], P, Cycle),
    P == 2, Cycle == [1,2].

test(size_period_full) :-
    A = obj(r,[r(0,0)]), B = obj(b,[r(0,1),r(0,2)]),
    C = obj(g,[r(0,3),r(0,4),r(0,5)]),
    oq_size_period([A,B,C], P, _),
    P == 3.

% --- oq_collinear/1 ---

test(collinear_horizontal) :-
    dot1(A), dot2(B), dot3(C),
    oq_collinear([A,B,C]).

test(collinear_diagonal) :-
    A = obj(r,[r(0,0)]), B = obj(b,[r(1,1)]), C = obj(g,[r(2,2)]),
    oq_collinear([A,B,C]).

test(collinear_not, [fail]) :-
    A = obj(r,[r(0,0)]), B = obj(b,[r(0,1)]), C = obj(g,[r(1,0)]),
    oq_collinear([A,B,C]).

% --- oq_next_centroid/2 ---

test(next_centroid_row) :-
    col0(A), col1(B), col2(C),
    oq_next_centroid([A,B,C], r(NR,NC)),
    NR == 6, NC == 0.

test(next_centroid_col) :-
    dot1(A), dot2(B), dot3(C),
    oq_next_centroid([A,B,C], r(NR,NC)),
    NR == 0, NC == 6.

test(next_centroid_fail_inconsistent, [fail]) :-
    off1(A), off2(B), off3(C),
    oq_next_centroid([A,B,C], _).

% --- oq_zip_colors/3 ---

test(zip_colors_basic) :-
    dot1(A), dot2(B), dot3(C),
    bar2(X), bar3(Y), bar4(Z),
    oq_zip_colors([A,B,C], [X,Y,Z], Pairs),
    Pairs == [r-b, b-g, g-y].

test(zip_colors_empty) :-
    oq_zip_colors([], [], Pairs),
    Pairs == [].

:- end_tests(objseq).
