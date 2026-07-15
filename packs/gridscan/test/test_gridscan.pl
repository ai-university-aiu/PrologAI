:- use_module('../prolog/gridscan').

% Test grids used throughout.
% g1: 5x5 with objects; bg = b.
%   Row 0: b b b b b
%   Row 1: b x b b b
%   Row 2: b b b y b
%   Row 3: b b x b b
%   Row 4: b b b b z
% g2: 3x7 row of mixed values.
%   Row 0: b b x b b x b
%   Row 1: b b b b b b b
%   Row 2: x b b b b b x
% g3: 4x4 all-b grid.

g1([[b,b,b,b,b],
    [b,x,b,b,b],
    [b,b,b,y,b],
    [b,b,x,b,b],
    [b,b,b,b,z]]).

g2([[b,b,x,b,b,x,b],
    [b,b,b,b,b,b,b],
    [x,b,b,b,b,b,x]]).

g3([[b,b,b,b],[b,b,b,b],[b,b,b,b],[b,b,b,b]]).

:- begin_tests(gridscan_scan_row).

% AC-GSN-001: scan row 0 of g1 (all b) = [].
test(scan_row_empty) :-
    g1(G), gridscan_scan_row(G, 0, b, Pairs), Pairs = [].

% AC-GSN-002: scan row 1 of g1 = [1-x].
test(scan_row_one) :-
    g1(G), gridscan_scan_row(G, 1, b, Pairs), Pairs = [1-x].

% AC-GSN-003: scan row 0 of g2 = [2-x, 5-x].
test(scan_row_two) :-
    g2(G), gridscan_scan_row(G, 0, b, Pairs), Pairs = [2-x, 5-x].

:- end_tests(gridscan_scan_row).

:- begin_tests(gridscan_scan_col).

% AC-GSN-004: scan col 0 of g1 (all b) = [].
test(scan_col_empty) :-
    g1(G), gridscan_scan_col(G, 0, b, Pairs), Pairs = [].

% AC-GSN-005: scan col 2 of g1 = [3-x].
test(scan_col_one) :-
    g1(G), gridscan_scan_col(G, 2, b, Pairs), Pairs = [3-x].

% AC-GSN-006: scan col 0 of g2 = [2-x].
test(scan_col_col0_g2) :-
    g2(G), gridscan_scan_col(G, 0, b, Pairs), Pairs = [2-x].

:- end_tests(gridscan_scan_col).

:- begin_tests(gridscan_first_right).

% AC-GSN-007: first right from (1,0) in g1 = 1-x (at col 1, row 1).
test(first_right_g1_r1) :-
    g1(G), gridscan_first_right(G, 1, 0, b, C-V), C =:= 1, V = x.

% AC-GSN-008: first right from (2,0) in g1 = 3-y.
test(first_right_g1_r2) :-
    g1(G), gridscan_first_right(G, 2, 0, b, C-V), C =:= 3, V = y.

% AC-GSN-009: first right fails when no non-bg exists.
test(first_right_fail) :-
    g1(G), \+ gridscan_first_right(G, 0, 0, b, _).

:- end_tests(gridscan_first_right).

:- begin_tests(gridscan_first_left).

% AC-GSN-010: first left from (1,4) in g1 = 1-x (nearest to the left).
test(first_left_g1_r1) :-
    g1(G), gridscan_first_left(G, 1, 4, b, C-V), C =:= 1, V = x.

% AC-GSN-011: first left from (2,4) in g1 = 3-y.
test(first_left_g1_r2) :-
    g1(G), gridscan_first_left(G, 2, 4, b, C-V), C =:= 3, V = y.

% AC-GSN-012: first left fails when no non-bg exists to left.
test(first_left_fail) :-
    g1(G), \+ gridscan_first_left(G, 0, 2, b, _).

:- end_tests(gridscan_first_left).

:- begin_tests(gridscan_first_down).

% AC-GSN-013: first down from (0,1) in g1 = 1-x.
test(first_down_g1_c1) :-
    g1(G), gridscan_first_down(G, 0, 1, b, R-V), R =:= 1, V = x.

% AC-GSN-014: first down from (0,2) in g1 = 3-x.
test(first_down_g1_c2) :-
    g1(G), gridscan_first_down(G, 0, 2, b, R-V), R =:= 3, V = x.

% AC-GSN-015: first down fails when no non-bg below.
test(first_down_fail) :-
    g1(G), \+ gridscan_first_down(G, 0, 0, b, _).

:- end_tests(gridscan_first_down).

:- begin_tests(gridscan_first_up).

% AC-GSN-016: first up from (4,1) in g1 = 1-x (nearest above).
test(first_up_g1_c1) :-
    g1(G), gridscan_first_up(G, 4, 1, b, R-V), R =:= 1, V = x.

% AC-GSN-017: first up from (4,2) in g1 = 3-x.
test(first_up_g1_c2) :-
    g1(G), gridscan_first_up(G, 4, 2, b, R-V), R =:= 3, V = x.

% AC-GSN-018: first up fails when no non-bg above.
test(first_up_fail) :-
    g1(G), \+ gridscan_first_up(G, 4, 0, b, _).

:- end_tests(gridscan_first_up).

:- begin_tests(gridscan_dist_right).

% AC-GSN-019: dist_right from (1,0) in g1 = 1 (x is 1 step right).
test(dist_right_g1) :-
    g1(G), gridscan_dist_right(G, 1, 0, b, D), D =:= 1.

% AC-GSN-020: dist_right from (2,0) in g1 = 3 (y at col 3).
test(dist_right_g1_r2) :-
    g1(G), gridscan_dist_right(G, 2, 0, b, D), D =:= 3.

% AC-GSN-021: dist_right fails when no non-bg to right.
test(dist_right_fail) :-
    g1(G), \+ gridscan_dist_right(G, 0, 0, b, _).

:- end_tests(gridscan_dist_right).

:- begin_tests(gridscan_dist_left).

% AC-GSN-022: dist_left from (1,4) in g1 = 3 (x at col 1, distance = 4-1=3).
test(dist_left_g1) :-
    g1(G), gridscan_dist_left(G, 1, 4, b, D), D =:= 3.

% AC-GSN-023: dist_left from (2,4) in g1 = 1 (y at col 3, distance = 4-3=1).
test(dist_left_g1_r2) :-
    g1(G), gridscan_dist_left(G, 2, 4, b, D), D =:= 1.

% AC-GSN-024: dist_left fails when no non-bg to left.
test(dist_left_fail) :-
    g1(G), \+ gridscan_dist_left(G, 0, 0, b, _).

:- end_tests(gridscan_dist_left).

:- begin_tests(gridscan_dist_down).

% AC-GSN-025: dist_down from (0,1) in g1 = 1 (x at row 1).
test(dist_down_g1) :-
    g1(G), gridscan_dist_down(G, 0, 1, b, D), D =:= 1.

% AC-GSN-026: dist_down from (0,2) in g1 = 3 (x at row 3).
test(dist_down_g1_c2) :-
    g1(G), gridscan_dist_down(G, 0, 2, b, D), D =:= 3.

% AC-GSN-027: dist_down fails when no non-bg below.
test(dist_down_fail) :-
    g1(G), \+ gridscan_dist_down(G, 0, 0, b, _).

:- end_tests(gridscan_dist_down).

:- begin_tests(gridscan_dist_up).

% AC-GSN-028: dist_up from (4,1) in g1 = 3 (x at row 1, distance = 4-1=3).
test(dist_up_g1) :-
    g1(G), gridscan_dist_up(G, 4, 1, b, D), D =:= 3.

% AC-GSN-029: dist_up from (4,3) in g1 = 2 (y at row 2, distance = 4-2=2).
test(dist_up_g1_c3) :-
    g1(G), gridscan_dist_up(G, 4, 3, b, D), D =:= 2.

% AC-GSN-030: dist_up fails when no non-bg above.
test(dist_up_fail) :-
    g1(G), \+ gridscan_dist_up(G, 4, 0, b, _).

:- end_tests(gridscan_dist_up).

:- begin_tests(gridscan_blocked_right).

% AC-GSN-031: blocked_right from (1,0) in g1 succeeds (x at col 1).
test(blocked_right_yes) :-
    g1(G), gridscan_blocked_right(G, 1, 0, b).

% AC-GSN-032: blocked_right from (0,0) in g1 fails (row 0 all bg).
test(blocked_right_no) :-
    g1(G), \+ gridscan_blocked_right(G, 0, 0, b).

:- end_tests(gridscan_blocked_right).

:- begin_tests(gridscan_blocked_left).

% AC-GSN-033: blocked_left from (1,4) in g1 succeeds (x at col 1).
test(blocked_left_yes) :-
    g1(G), gridscan_blocked_left(G, 1, 4, b).

% AC-GSN-034: blocked_left from (0,4) in g1 fails (row 0 all bg).
test(blocked_left_no) :-
    g1(G), \+ gridscan_blocked_left(G, 0, 4, b).

:- end_tests(gridscan_blocked_left).

:- begin_tests(gridscan_blocked_down).

% AC-GSN-035: blocked_down from (0,1) in g1 succeeds (x at row 1).
test(blocked_down_yes) :-
    g1(G), gridscan_blocked_down(G, 0, 1, b).

% AC-GSN-036: blocked_down from (0,0) in g1 fails (col 0 all bg).
test(blocked_down_no) :-
    g1(G), \+ gridscan_blocked_down(G, 0, 0, b).

:- end_tests(gridscan_blocked_down).

:- begin_tests(gridscan_blocked_up).

% AC-GSN-037: blocked_up from (4,1) in g1 succeeds (x at row 1).
test(blocked_up_yes) :-
    g1(G), gridscan_blocked_up(G, 4, 1, b).

% AC-GSN-038: blocked_up from (4,0) in g1 fails (col 0 all bg).
test(blocked_up_no) :-
    g1(G), \+ gridscan_blocked_up(G, 4, 0, b).

:- end_tests(gridscan_blocked_up).

:- begin_tests(gsn_combined).

% AC-GSN-039: dist_right + dist_left from bg cell (row 0, col 3 of g2) between two x cells.
test(left_right_symmetry) :-
    g2(G), gridscan_dist_right(G, 0, 3, b, DR), gridscan_dist_left(G, 0, 3, b, DL),
    DR =:= 2, DL =:= 1.

% AC-GSN-040: scan_row and scan_col count check.
test(scan_count) :-
    g2(G), gridscan_scan_row(G, 0, b, R), length(R, NR), NR =:= 2,
    gridscan_scan_col(G, 6, b, C), length(C, NC), NC =:= 1.

% AC-GSN-041: dist_down then dist_up from between two x cells.
test(dist_down_up) :-
    g1(G), gridscan_dist_down(G, 1, 2, b, DD), gridscan_dist_up(G, 4, 2, b, DU),
    DD =:= 2, DU =:= 1.

% AC-GSN-042: blocked checks match first_* existence.
test(blocked_vs_first) :-
    g1(G),
    gridscan_blocked_right(G, 2, 0, b),
    gridscan_first_right(G, 2, 0, b, 3-y).

% AC-GSN-043: all-bg grid: no hits in any direction.
test(all_bg_no_hits) :-
    g3(G),
    \+ gridscan_blocked_right(G, 1, 0, b),
    \+ gridscan_blocked_left(G, 1, 3, b),
    \+ gridscan_blocked_down(G, 0, 1, b),
    \+ gridscan_blocked_up(G, 3, 1, b).

% AC-GSN-044: scan_col g2 col 6 has one hit.
test(scan_col_g2_c6) :-
    g2(G), gridscan_scan_col(G, 6, b, Pairs), Pairs = [2-x].

:- end_tests(gsn_combined).
