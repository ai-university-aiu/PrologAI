:- use_module('../prolog/gridgrav.pl').

% Test grids used throughout.
% G1: 3x3 with bg=b and some non-bg cells.
%   Row0: [a, b, b]
%   Row1: [b, a, b]
%   Row2: [b, b, a]
g1([[a,b,b],[b,a,b],[b,b,a]]).

% G2: 4x3 used for settlement tests.
%   Row0: [b, x, b]
%   Row1: [x, b, b]
%   Row2: [b, b, x]
%   Row3: [b, b, b]
g2([[b,x,b],[x,b,b],[b,b,x],[b,b,b]]).

% G3: 3x4 for row-based tests.
%   Row0: [a, b, a, b]
%   Row1: [b, b, b, b]
%   Row2: [a, b, b, a]
g3([[a,b,a,b],[b,b,b,b],[a,b,b,a]]).

% G4: 3x3 already settled downward (non-bg at bottom).
%   Row0: [b, b, b]
%   Row1: [a, b, b]
%   Row2: [a, a, a]
g4([[b,b,b],[a,b,b],[a,a,a]]).

% G5: 1x1 bg grid.
g5([[b]]).

:- begin_tests(gridgrav).

% --- gv_fall_down ---

% AC-GV-001: falling down settles all non-bg to the bottom of each column
test(fall_down_g2) :-
    g2(G), gv_fall_down(G, b, F),
    F = [[b,b,b],[b,b,b],[b,b,b],[x,x,x]].

% AC-GV-002: fall_down on diagonal grid
test(fall_down_g1) :-
    g1(G), gv_fall_down(G, b, F),
    F = [[b,b,b],[b,b,b],[a,a,a]].

% AC-GV-003: fall_down on already settled grid is idempotent
test(fall_down_idempotent) :-
    g4(G), gv_fall_down(G, b, F),
    F = [[b,b,b],[a,b,b],[a,a,a]].

% --- gv_fall_up ---

% AC-GV-004: falling up settles all non-bg to the top of each column
test(fall_up_g2) :-
    g2(G), gv_fall_up(G, b, F),
    F = [[x,x,x],[b,b,b],[b,b,b],[b,b,b]].

% AC-GV-005: fall_up on diagonal grid
test(fall_up_g1) :-
    g1(G), gv_fall_up(G, b, F),
    F = [[a,a,a],[b,b,b],[b,b,b]].

% AC-GV-006: fall_up followed by fall_down gives same as fall_down alone
test(fall_up_then_down) :-
    g2(G),
    gv_fall_up(G, b, Up),
    gv_fall_down(Up, b, UpDown),
    gv_fall_down(G, b, Down),
    UpDown = Down.

% --- gv_fall_left ---

% AC-GV-007: falling left packs non-bg to the left of each row
test(fall_left_g3) :-
    g3(G), gv_fall_left(G, b, F),
    F = [[a,a,b,b],[b,b,b,b],[a,a,b,b]].

% AC-GV-008: fall_left on uniform bg row leaves it unchanged
test(fall_left_uniform_row) :-
    G = [[b,b,b],[a,b,a]],
    gv_fall_left(G, b, F),
    F = [[b,b,b],[a,a,b]].

% AC-GV-009: fall_left on fully non-bg row leaves it unchanged
test(fall_left_full_row) :-
    G = [[a,a,a]],
    gv_fall_left(G, b, F),
    F = [[a,a,a]].

% --- gv_fall_right ---

% AC-GV-010: falling right packs non-bg to the right of each row
test(fall_right_g3) :-
    g3(G), gv_fall_right(G, b, F),
    F = [[b,b,a,a],[b,b,b,b],[b,b,a,a]].

% AC-GV-011: fall_right on single-non-bg row
test(fall_right_single) :-
    G = [[b,b,x,b]],
    gv_fall_right(G, b, F),
    F = [[b,b,b,x]].

% AC-GV-012: fall_right then fall_left gives same non-bg count
test(fall_right_then_left_count) :-
    g3(G),
    gv_fall_right(G, b, Right),
    gv_fall_left(Right, b, BackLeft),
    gv_non_bg_count(G, b, N1),
    gv_non_bg_count(BackLeft, b, N2),
    N1 = N2.

% --- gv_col_pile_h ---

% AC-GV-013: column pile height counts non-bg cells in that column
test(col_pile_h_g1) :-
    g1(G), gv_col_pile_h(G, 0, b, H),
    H = 1.

% AC-GV-014: column with no non-bg has pile height 0
test(col_pile_h_zero) :-
    G = [[b,b],[b,b]],
    gv_col_pile_h(G, 0, b, H),
    H = 0.

% AC-GV-015: column with all non-bg has pile height = grid height
test(col_pile_h_full) :-
    G = [[a],[a],[a]],
    gv_col_pile_h(G, 0, b, H),
    H = 3.

% --- gv_row_pile_w ---

% AC-GV-016: row pile width counts non-bg cells in that row
test(row_pile_w_g3) :-
    g3(G), gv_row_pile_w(G, 0, b, W),
    W = 2.

% AC-GV-017: all-bg row has pile width 0
test(row_pile_w_zero) :-
    g3(G), gv_row_pile_w(G, 1, b, W),
    W = 0.

% AC-GV-018: row with all non-bg has pile width = grid width
test(row_pile_w_full) :-
    G = [[a,a,a]],
    gv_row_pile_w(G, 0, b, W),
    W = 3.

% --- gv_all_col_piles ---

% AC-GV-019: all column piles for diagonal grid
test(all_col_piles_g1) :-
    g1(G), gv_all_col_piles(G, b, Piles),
    Piles = [1,1,1].

% AC-GV-020: all column piles for g2 (cols 0=1, 1=1, 2=1)
test(all_col_piles_g2) :-
    g2(G), gv_all_col_piles(G, b, Piles),
    Piles = [1,1,1].

% AC-GV-021: all column piles for uniform bg grid
test(all_col_piles_zeros) :-
    G = [[b,b,b],[b,b,b]],
    gv_all_col_piles(G, b, Piles),
    Piles = [0,0,0].

% --- gv_all_row_piles ---

% AC-GV-022: all row piles for diagonal grid
test(all_row_piles_g1) :-
    g1(G), gv_all_row_piles(G, b, Piles),
    Piles = [1,1,1].

% AC-GV-023: all row piles for g3 (rows 0=2, 1=0, 2=2)
test(all_row_piles_g3) :-
    g3(G), gv_all_row_piles(G, b, Piles),
    Piles = [2,0,2].

% AC-GV-024: sum of all col piles equals total non-bg count
test(all_col_piles_sum) :-
    g2(G),
    gv_all_col_piles(G, b, Piles),
    sumlist(Piles, Sum),
    gv_non_bg_count(G, b, N),
    Sum = N.

% --- gv_floating_cells ---

% AC-GV-025: g2 has floating cells: (0,1), (1,0), and (2,2) each have bg directly below
test(floating_cells_g2) :-
    g2(G), gv_floating_cells(G, b, Cells),
    Cells = [0-1, 1-0, 2-2].

% AC-GV-026: already settled grid has no floating cells
test(floating_cells_settled) :-
    g4(G), gv_floating_cells(G, b, Cells),
    Cells = [].

% AC-GV-027: diagonal grid has 2 floating cells (row 0 col 0, row 1 col 1)
test(floating_cells_g1) :-
    g1(G), gv_floating_cells(G, b, Cells),
    Cells = [0-0, 1-1].

% --- gv_settled ---

% AC-GV-028: already settled grid satisfies gv_settled
test(settled_true) :-
    g4(G), gv_settled(G, b).

% AC-GV-029: g2 is not settled
test(settled_false) :-
    g2(G), \+ gv_settled(G, b).

% AC-GV-030: after fall_down a grid is settled
test(settled_after_fall) :-
    g2(G), gv_fall_down(G, b, F),
    gv_settled(F, b).

% --- gv_col_gap_above ---

% AC-GV-031: column with non-bg at top has gap 0
test(col_gap_above_zero) :-
    g1(G), gv_col_gap_above(G, 0, b, Gap),
    Gap = 0.

% AC-GV-032: column 1 of g2 has one bg cell at top before x
test(col_gap_above_g2) :-
    g2(G), gv_col_gap_above(G, 1, b, Gap),
    Gap = 0.

% AC-GV-033: all-bg column returns full column height as gap
test(col_gap_above_all_bg) :-
    G = [[b,b],[b,b],[b,b]],
    gv_col_gap_above(G, 0, b, Gap),
    Gap = 3.

% --- gv_max_col_pile ---

% AC-GV-034: max column pile for g1 is column 0 (all tied; lowest index wins)
test(max_col_pile_g1) :-
    g1(G), gv_max_col_pile(G, b, MaxC),
    MaxC = 0.

% AC-GV-035: max column pile in grid with clear winner
test(max_col_pile_clear) :-
    G = [[a,b,b],[a,b,b],[a,a,b]],
    gv_max_col_pile(G, b, MaxC),
    MaxC = 0.

% AC-GV-036: max column pile tie goes to lowest index
test(max_col_pile_tie) :-
    G = [[a,a,b],[b,b,b],[b,b,b]],
    gv_max_col_pile(G, b, MaxC),
    MaxC = 0.

% --- gv_min_col_pile ---

% AC-GV-037: min column pile for g1 is column 0 (all tied; lowest index wins)
test(min_col_pile_g1) :-
    g1(G), gv_min_col_pile(G, b, MinC),
    MinC = 0.

% AC-GV-038: min column pile in grid with clear minimum
test(min_col_pile_clear) :-
    G = [[a,b,b],[a,b,b],[a,a,b]],
    gv_min_col_pile(G, b, MinC),
    MinC = 2.

% AC-GV-039: min column pile includes zero-pile columns
test(min_col_pile_zero) :-
    G = [[b,b,a],[b,b,a],[b,b,a]],
    gv_min_col_pile(G, b, MinC),
    MinC = 0.

% --- gv_non_bg_count ---

% AC-GV-040: total non-bg count for g1 (3 cells)
test(non_bg_count_g1) :-
    g1(G), gv_non_bg_count(G, b, N),
    N = 3.

% AC-GV-041: total non-bg count for g2 (3 cells: x at 0-1, 1-0, 2-2)
test(non_bg_count_g2) :-
    g2(G), gv_non_bg_count(G, b, N),
    N = 3.

% AC-GV-042: total non-bg count for uniform bg grid is 0
test(non_bg_count_zero) :-
    g5(G), gv_non_bg_count(G, b, N),
    N = 0.

% AC-GV-043: non_bg_count is preserved after fall_down
test(non_bg_count_preserved_fall) :-
    g2(G),
    gv_non_bg_count(G, b, N),
    gv_fall_down(G, b, F),
    gv_non_bg_count(F, b, NF),
    N = NF.

% AC-GV-044: non_bg_count is preserved after fall_left
test(non_bg_count_preserved_left) :-
    g3(G),
    gv_non_bg_count(G, b, N),
    gv_fall_left(G, b, F),
    gv_non_bg_count(F, b, NF),
    N = NF.

:- end_tests(gridgrav).
