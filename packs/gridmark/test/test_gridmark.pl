:- use_module('../prolog/gridmark.pl').

% Base grid: 4x4 all background color b.
bg([[b,b,b,b],[b,b,b,b],[b,b,b,b],[b,b,b,b]]).

% Mixed grid: 3x3 with some marks.
g33([[b,b,b],[b,x,b],[b,b,b]]).

% 1x1 grid.
g11([[b]]).

% 2x2 grid.
g22([[b,b],[b,b]]).

:- begin_tests(gridmark).

% --- gridmark_mark_cell ---

% AC-GMK-001: mark cell (1,2) of 4x4 bg grid
test(mark_cell_4x4) :-
    bg(G), gridmark_mark_cell(G, 1, 2, m, M),
    nth0(1, M, Row), nth0(2, Row, m).

% AC-GMK-002: all other cells remain unchanged after mark_cell
test(mark_cell_unchanged) :-
    bg(G), gridmark_mark_cell(G, 0, 0, m, M),
    nth0(1, M, Row), nth0(1, Row, b).

% AC-GMK-003: mark_cell on 1x1 works
test(mark_cell_1x1) :-
    g11(G), gridmark_mark_cell(G, 0, 0, m, M),
    M = [[m]].

% --- gridmark_mark_cells ---

% AC-GMK-004: mark list of cells in bg grid
test(mark_cells_list) :-
    bg(G), gridmark_mark_cells(G, [0-0, 1-1, 2-2, 3-3], m, M),
    nth0(0, M, R0), nth0(0, R0, m),
    nth0(1, M, R1), nth0(1, R1, m),
    nth0(2, M, R2), nth0(2, R2, m),
    nth0(3, M, R3), nth0(3, R3, m).

% AC-GMK-005: mark empty list changes nothing
test(mark_cells_empty) :-
    bg(G), gridmark_mark_cells(G, [], m, M),
    M = G.

% AC-GMK-006: mark overlapping cells only marks once (no arity issues)
test(mark_cells_overlap) :-
    bg(G), gridmark_mark_cells(G, [0-0, 0-0], m, M),
    nth0(0, M, Row), nth0(0, Row, m).

% --- gridmark_mark_row ---

% AC-GMK-007: mark row 1 of 4x4 bg grid gives all m in row 1
test(mark_row_4x4) :-
    bg(G), gridmark_mark_row(G, 1, m, M),
    nth0(1, M, Row), Row = [m,m,m,m].

% AC-GMK-008: other rows unchanged after mark_row
test(mark_row_unchanged) :-
    bg(G), gridmark_mark_row(G, 2, m, M),
    nth0(0, M, Row), Row = [b,b,b,b].

% AC-GMK-009: mark row 0 of 1x1 gives [[m]]
test(mark_row_1x1) :-
    g11(G), gridmark_mark_row(G, 0, m, M),
    M = [[m]].

% --- gridmark_mark_col ---

% AC-GMK-010: mark col 2 of 4x4 bg grid
test(mark_col_4x4) :-
    bg(G), gridmark_mark_col(G, 2, m, M),
    findall(V, (member(Row, M), nth0(2, Row, V)), Vs),
    Vs = [m,m,m,m].

% AC-GMK-011: other columns unchanged after mark_col
test(mark_col_unchanged) :-
    bg(G), gridmark_mark_col(G, 0, m, M),
    nth0(0, M, Row), nth0(1, Row, b).

% AC-GMK-012: mark col 0 of 1x1 gives [[m]]
test(mark_col_1x1) :-
    g11(G), gridmark_mark_col(G, 0, m, M),
    M = [[m]].

% --- gridmark_mark_rect ---

% AC-GMK-013: mark 2x2 rect at (1,1) of 4x4 bg
test(mark_rect_4x4) :-
    bg(G), gridmark_mark_rect(G, 1, 1, 2, 2, m, M),
    nth0(1, M, R1), nth0(1, R1, m), nth0(2, R1, m),
    nth0(2, M, R2), nth0(2, R2, m).

% AC-GMK-014: cells outside rect unchanged
test(mark_rect_outside) :-
    bg(G), gridmark_mark_rect(G, 1, 1, 2, 2, m, M),
    nth0(0, M, R0), R0 = [b,b,b,b].

% AC-GMK-015: mark full grid via rect
test(mark_rect_full) :-
    bg(G), gridmark_mark_rect(G, 0, 0, 3, 3, m, M),
    M = [[m,m,m,m],[m,m,m,m],[m,m,m,m],[m,m,m,m]].

% --- gridmark_mark_border ---

% AC-GMK-016: border of 4x4 bg marks outer ring
test(mark_border_4x4) :-
    bg(G), gridmark_mark_border(G, m, M),
    nth0(0, M, R0), R0 = [m,m,m,m],
    nth0(3, M, R3), R3 = [m,m,m,m],
    nth0(1, M, R1), nth0(0, R1, m), nth0(3, R1, m),
    nth0(1, R1, Cb), Cb = b.

% AC-GMK-017: border of 1x1 gives [[m]]
test(mark_border_1x1) :-
    g11(G), gridmark_mark_border(G, m, M),
    M = [[m]].

% AC-GMK-018: inner cell of 4x4 unchanged after border mark
test(mark_border_inner_unchanged) :-
    bg(G), gridmark_mark_border(G, m, M),
    nth0(1, M, R1), nth0(1, R1, b),
    nth0(2, M, R2), nth0(2, R2, b).

% --- gridmark_mark_diagonal ---

% AC-GMK-019: diagonal of 4x4 bg marks (0,0),(1,1),(2,2),(3,3)
test(mark_diagonal_4x4) :-
    bg(G), gridmark_mark_diagonal(G, m, M),
    nth0(0, M, R0), nth0(0, R0, m),
    nth0(1, M, R1), nth0(1, R1, m),
    nth0(2, M, R2), nth0(2, R2, m),
    nth0(3, M, R3), nth0(3, R3, m).

% AC-GMK-020: non-diagonal cells unchanged
test(mark_diagonal_off) :-
    bg(G), gridmark_mark_diagonal(G, m, M),
    nth0(0, M, R0), nth0(1, R0, b).

% AC-GMK-021: diagonal of 1x1 marks (0,0)
test(mark_diagonal_1x1) :-
    g11(G), gridmark_mark_diagonal(G, m, M),
    M = [[m]].

% --- gridmark_mark_anti_diagonal ---

% AC-GMK-022: anti-diagonal of 4x4 bg marks (0,3),(1,2),(2,1),(3,0)
test(mark_anti_diagonal_4x4) :-
    bg(G), gridmark_mark_anti_diagonal(G, m, M),
    nth0(0, M, R0), nth0(3, R0, m),
    nth0(1, M, R1), nth0(2, R1, m),
    nth0(2, M, R2), nth0(1, R2, m),
    nth0(3, M, R3), nth0(0, R3, m).

% AC-GMK-023: main diagonal cell (1,1) is not on anti-diagonal (for W=4, ASum=3; 1+1=2 != 3)
test(mark_anti_diagonal_not_main) :-
    bg(G), gridmark_mark_anti_diagonal(G, m, M),
    nth0(1, M, R1), nth0(1, R1, b).

% AC-GMK-024: anti-diagonal of 3x3 marks (0,2),(1,1),(2,0)
test(mark_anti_diagonal_3x3) :-
    G = [[b,b,b],[b,b,b],[b,b,b]],
    gridmark_mark_anti_diagonal(G, m, M),
    nth0(0, M, R0), nth0(2, R0, m),
    nth0(1, M, R1), nth0(1, R1, m),
    nth0(2, M, R2), nth0(0, R2, m).

% --- gridmark_mark_corners ---

% AC-GMK-025: corners of 4x4 marks (0,0),(0,3),(3,0),(3,3)
test(mark_corners_4x4) :-
    bg(G), gridmark_mark_corners(G, m, M),
    nth0(0, M, R0), nth0(0, R0, m), nth0(3, R0, m),
    nth0(3, M, R3), nth0(0, R3, m), nth0(3, R3, m).

% AC-GMK-026: non-corner cells unchanged
test(mark_corners_inner) :-
    bg(G), gridmark_mark_corners(G, m, M),
    nth0(1, M, R1), R1 = [b,b,b,b].

% --- gridmark_mark_cross ---

% AC-GMK-027: cross of 4x4 marks row 2 and col 2
test(mark_cross_4x4) :-
    bg(G), gridmark_mark_cross(G, m, M),
    nth0(2, M, R2), R2 = [m,m,m,m],
    findall(V, (member(Row, M), nth0(2, Row, V)), Vs),
    Vs = [m,m,m,m].

% AC-GMK-028: cross of 3x3 marks row 1 and col 1
test(mark_cross_3x3) :-
    G = [[b,b,b],[b,b,b],[b,b,b]],
    gridmark_mark_cross(G, m, M),
    nth0(1, M, R1), R1 = [m,m,m],
    nth0(0, M, R0), nth0(1, R0, m).

% --- gridmark_marked_cells ---

% AC-GMK-029: marked cells of bg grid with mark m = []
test(marked_cells_none) :-
    bg(G), gridmark_marked_cells(G, m, Cs),
    Cs = [].

% AC-GMK-030: marked cells after marking diagonal
test(marked_cells_diagonal) :-
    bg(G), gridmark_mark_diagonal(G, m, M),
    gridmark_marked_cells(M, m, Cs),
    Cs = [0-0, 1-1, 2-2, 3-3].

% AC-GMK-031: marked cells of g33 with x
test(marked_cells_g33) :-
    g33(G), gridmark_marked_cells(G, x, Cs),
    Cs = [1-1].

% --- gridmark_is_marked ---

% AC-GMK-032: is_marked succeeds for center of g33
test(is_marked_true) :-
    g33(G), gridmark_is_marked(G, 1, 1, x).

% AC-GMK-033: is_marked fails for non-marked cell
test(is_marked_false) :-
    bg(G), \+ gridmark_is_marked(G, 0, 0, m).

% --- gridmark_mark_checkerboard ---

% AC-GMK-034: checkerboard of 2x2 marks (0,0) and (1,1)
test(mark_checkerboard_2x2) :-
    g22(G), gridmark_mark_checkerboard(G, m, M),
    M = [[m,b],[b,m]].

% AC-GMK-035: checkerboard of 4x4 has 8 marked cells
test(mark_checkerboard_count) :-
    bg(G), gridmark_mark_checkerboard(G, m, M),
    gridmark_marked_cells(M, m, Cs),
    length(Cs, 8).

% --- gridmark_erase ---

% AC-GMK-036: erase marks in diagonal-marked grid
test(erase_diagonal) :-
    bg(G), gridmark_mark_diagonal(G, m, M),
    gridmark_erase(M, m, b, E),
    E = G.

% AC-GMK-037: erase on grid with no marks changes nothing
test(erase_no_marks) :-
    bg(G), gridmark_erase(G, m, b, E),
    E = G.

% AC-GMK-038: erase replaces MarkColor with BgColor correctly
test(erase_replaces) :-
    G = [[m,b,m],[b,m,b]],
    gridmark_erase(G, m, b, E),
    E = [[b,b,b],[b,b,b]].

% --- combined tests ---

% AC-GMK-039: mark_row then marked_cells returns correct count
test(combined_mark_row_count) :-
    bg(G), gridmark_mark_row(G, 0, m, M),
    gridmark_marked_cells(M, m, Cs),
    length(Cs, 4).

% AC-GMK-040: mark_col then is_marked at all column positions
test(combined_mark_col_check) :-
    bg(G), gridmark_mark_col(G, 1, m, M),
    gridmark_is_marked(M, 0, 1, m),
    gridmark_is_marked(M, 3, 1, m).

% AC-GMK-041: mark_border then erase recovers original
test(combined_border_erase) :-
    bg(G), gridmark_mark_border(G, m, M),
    gridmark_erase(M, m, b, E),
    E = G.

% AC-GMK-042: mark_rect then marked_cells count
test(combined_rect_count) :-
    bg(G), gridmark_mark_rect(G, 0, 0, 1, 1, m, M),
    gridmark_marked_cells(M, m, Cs),
    length(Cs, 4).

% AC-GMK-043: mark_checkerboard then erase recovers original
test(combined_checker_erase) :-
    bg(G), gridmark_mark_checkerboard(G, m, M),
    gridmark_erase(M, m, b, E),
    E = G.

% AC-GMK-044: mark_cross then marked_cells count (row 2 = 4 + col 2 = 4 - center overlap = 7)
test(combined_cross_count) :-
    bg(G), gridmark_mark_cross(G, m, M),
    gridmark_marked_cells(M, m, Cs),
    length(Cs, 7).

:- end_tests(gridmark).
