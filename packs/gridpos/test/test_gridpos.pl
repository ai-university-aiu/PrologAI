:- use_module('../prolog/gridpos.pl').

% Test grids used throughout
g44([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]]).
g33([[a,b,c],[d,e,f],[g,h,i]]).
g11([[a]]).

:- begin_tests(gridpos).

% --- gridpos_top_half ---

% AC-GPS-001: top half of 4x4 is first two rows
test(top_half_4x4) :-
    g44(G), gridpos_top_half(G, T),
    T = [[a,b,c,d],[e,f,g,h]].

% AC-GPS-002: top half of 3x3 (H=3, HMid=1) is row 0 only
test(top_half_3x3) :-
    g33(G), gridpos_top_half(G, T),
    T = [[a,b,c]].

% AC-GPS-003: top half of 1x1 (HMid=0) is empty
test(top_half_1x1) :-
    g11(G), gridpos_top_half(G, T),
    T = [].

% --- gridpos_bottom_half ---

% AC-GPS-004: bottom half of 4x4 is last two rows
test(bottom_half_4x4) :-
    g44(G), gridpos_bottom_half(G, B),
    B = [[i,j,k,l],[m,n,o,p]].

% AC-GPS-005: bottom half of 3x3 (HMid=1) is rows 1-2
test(bottom_half_3x3) :-
    g33(G), gridpos_bottom_half(G, B),
    B = [[d,e,f],[g,h,i]].

% AC-GPS-006: bottom half of 1x1 is the whole grid
test(bottom_half_1x1) :-
    g11(G), gridpos_bottom_half(G, B),
    B = [[a]].

% --- gridpos_left_half ---

% AC-GPS-007: left half of 4x4 is first two columns
test(left_half_4x4) :-
    g44(G), gridpos_left_half(G, L),
    L = [[a,b],[e,f],[i,j],[m,n]].

% AC-GPS-008: left half of 3x3 (WMid=1) is column 0 only
test(left_half_3x3) :-
    g33(G), gridpos_left_half(G, L),
    L = [[a],[d],[g]].

% AC-GPS-009: left half of 1x1 (WMid=0) produces one empty row
test(left_half_1x1) :-
    g11(G), gridpos_left_half(G, L),
    L = [[]].

% --- gridpos_right_half ---

% AC-GPS-010: right half of 4x4 is last two columns
test(right_half_4x4) :-
    g44(G), gridpos_right_half(G, R),
    R = [[c,d],[g,h],[k,l],[o,p]].

% AC-GPS-011: right half of 3x3 (WMid=1) is columns 1-2
test(right_half_3x3) :-
    g33(G), gridpos_right_half(G, R),
    R = [[b,c],[e,f],[h,i]].

% AC-GPS-012: right half of 1x1 (WMid=0) is the whole column
test(right_half_1x1) :-
    g11(G), gridpos_right_half(G, R),
    R = [[a]].

% --- gridpos_quadrant ---

% AC-GPS-013: top-left quadrant of 4x4 is rows 0-1, cols 0-1
test(quadrant_tl) :-
    g44(G), gridpos_quadrant(G, tl, Q),
    Q = [[a,b],[e,f]].

% AC-GPS-014: top-right quadrant of 4x4 is rows 0-1, cols 2-3
test(quadrant_tr) :-
    g44(G), gridpos_quadrant(G, tr, Q),
    Q = [[c,d],[g,h]].

% AC-GPS-015: bottom-left quadrant of 4x4 is rows 2-3, cols 0-1
test(quadrant_bl) :-
    g44(G), gridpos_quadrant(G, bl, Q),
    Q = [[i,j],[m,n]].

% AC-GPS-016: bottom-right quadrant of 4x4 is rows 2-3, cols 2-3
test(quadrant_br) :-
    g44(G), gridpos_quadrant(G, br, Q),
    Q = [[k,l],[o,p]].

% --- gridpos_even_rows ---

% AC-GPS-017: even rows of 4x4 are rows 0 and 2
test(even_rows_4x4) :-
    g44(G), gridpos_even_rows(G, E),
    E = [[a,b,c,d],[i,j,k,l]].

% AC-GPS-018: even rows of 3x3 are rows 0 and 2
test(even_rows_3x3) :-
    g33(G), gridpos_even_rows(G, E),
    E = [[a,b,c],[g,h,i]].

% AC-GPS-019: even rows of 1x1 is row 0 only
test(even_rows_1x1) :-
    g11(G), gridpos_even_rows(G, E),
    E = [[a]].

% --- gridpos_odd_rows ---

% AC-GPS-020: odd rows of 4x4 are rows 1 and 3
test(odd_rows_4x4) :-
    g44(G), gridpos_odd_rows(G, O),
    O = [[e,f,g,h],[m,n,o,p]].

% AC-GPS-021: odd rows of 3x3 is row 1 only
test(odd_rows_3x3) :-
    g33(G), gridpos_odd_rows(G, O),
    O = [[d,e,f]].

% AC-GPS-022: odd rows of 1x1 is empty (only row 0 which is even)
test(odd_rows_1x1) :-
    g11(G), gridpos_odd_rows(G, O),
    O = [].

% --- gridpos_even_cols ---

% AC-GPS-023: even cols of 4x4 are cols 0 and 2 of each row
test(even_cols_4x4) :-
    g44(G), gridpos_even_cols(G, E),
    E = [[a,c],[e,g],[i,k],[m,o]].

% AC-GPS-024: even cols of 3x3 are cols 0 and 2 of each row
test(even_cols_3x3) :-
    g33(G), gridpos_even_cols(G, E),
    E = [[a,c],[d,f],[g,i]].

% AC-GPS-025: even cols of 1x1 is col 0 only
test(even_cols_1x1) :-
    g11(G), gridpos_even_cols(G, E),
    E = [[a]].

% --- gridpos_odd_cols ---

% AC-GPS-026: odd cols of 4x4 are cols 1 and 3 of each row
test(odd_cols_4x4) :-
    g44(G), gridpos_odd_cols(G, O),
    O = [[b,d],[f,h],[j,l],[n,p]].

% AC-GPS-027: odd cols of 3x3 is col 1 only per row
test(odd_cols_3x3) :-
    g33(G), gridpos_odd_cols(G, O),
    O = [[b],[e],[h]].

% AC-GPS-028: odd cols of 1x1 is one row of empty (no odd indices)
test(odd_cols_1x1) :-
    g11(G), gridpos_odd_cols(G, O),
    O = [[]].

% --- gridpos_checkerboard ---

% AC-GPS-029: parity-0 cells of 4x4 are all (R,C) with (R+C) even
test(checkerboard_parity0_4x4) :-
    g44(G), gridpos_checkerboard(G, 0, Cells),
    Cells = [0-0,0-2,1-1,1-3,2-0,2-2,3-1,3-3].

% AC-GPS-030: parity-1 cells of 4x4 are all (R,C) with (R+C) odd
test(checkerboard_parity1_4x4) :-
    g44(G), gridpos_checkerboard(G, 1, Cells),
    Cells = [0-1,0-3,1-0,1-2,2-1,2-3,3-0,3-2].

% AC-GPS-031: parity-0 of 1x1 is just [0-0]
test(checkerboard_parity0_1x1) :-
    g11(G), gridpos_checkerboard(G, 0, Cells),
    Cells = [0-0].

% AC-GPS-032: parity-1 of 1x1 is empty
test(checkerboard_parity1_1x1) :-
    g11(G), gridpos_checkerboard(G, 1, Cells),
    Cells = [].

% --- gridpos_center_cell ---

% AC-GPS-033: center of 4x4 is row 2, col 2
test(center_cell_4x4) :-
    g44(G), gridpos_center_cell(G, R, C),
    R = 2, C = 2.

% AC-GPS-034: center of 3x3 is row 1, col 1
test(center_cell_3x3) :-
    g33(G), gridpos_center_cell(G, R, C),
    R = 1, C = 1.

% AC-GPS-035: center of 1x1 is row 0, col 0
test(center_cell_1x1) :-
    g11(G), gridpos_center_cell(G, R, C),
    R = 0, C = 0.

% --- gridpos_corners ---

% AC-GPS-036: corners of 4x4 are a, d, m, p
test(corners_4x4) :-
    g44(G), gridpos_corners(G, Cs),
    Cs = [0-0-a, 0-3-d, 3-0-m, 3-3-p].

% AC-GPS-037: corners of 3x3 are a, c, g, i
test(corners_3x3) :-
    g33(G), gridpos_corners(G, Cs),
    Cs = [0-0-a, 0-2-c, 2-0-g, 2-2-i].

% AC-GPS-038: corners of 1x1 all point to the single cell
test(corners_1x1) :-
    g11(G), gridpos_corners(G, Cs),
    Cs = [0-0-a, 0-0-a, 0-0-a, 0-0-a].

% --- gridpos_cross_h ---

% AC-GPS-039: horizontal cross of 4x4 is row 2
test(cross_h_4x4) :-
    g44(G), gridpos_cross_h(G, R, Row),
    R = 2, Row = [i,j,k,l].

% AC-GPS-040: horizontal cross of 3x3 is row 1
test(cross_h_3x3) :-
    g33(G), gridpos_cross_h(G, R, Row),
    R = 1, Row = [d,e,f].

% AC-GPS-041: horizontal cross of 1x1 is row 0
test(cross_h_1x1) :-
    g11(G), gridpos_cross_h(G, R, Row),
    R = 0, Row = [a].

% --- gridpos_cross_v ---

% AC-GPS-042: vertical cross of 4x4 is column 2
test(cross_v_4x4) :-
    g44(G), gridpos_cross_v(G, C, Col),
    C = 2, Col = [c,g,k,o].

% AC-GPS-043: vertical cross of 3x3 is column 1
test(cross_v_3x3) :-
    g33(G), gridpos_cross_v(G, C, Col),
    C = 1, Col = [b,e,h].

% AC-GPS-044: vertical cross of 1x1 is column 0
test(cross_v_1x1) :-
    g11(G), gridpos_cross_v(G, C, Col),
    C = 0, Col = [a].

:- end_tests(gridpos).
