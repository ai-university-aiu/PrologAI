:- use_module('../prolog/gridnbr').
:- use_module(library(plunit)).

% Grid fixtures.
% G3X3: 3x3 grid with b at center (1,1); background r.
g3x3([[r,r,r],[r,b,r],[r,r,r]]).

% G3X3_RING: 3x3 grid with b border and r center.
g3x3_ring([[b,b,b],[b,r,b],[b,b,b]]).

% G3X3_ROW: 3x3 grid with full middle row as b.
g3x3_row([[r,r,r],[b,b,b],[r,r,r]]).

% G5X5: 5x5 grid with 3x3 b block at center.
g5x5([[r,r,r,r,r],
      [r,b,b,b,r],
      [r,b,b,b,r],
      [r,b,b,b,r],
      [r,r,r,r,r]]).

% G2X2: 2x2 uniform grid.
g2x2([[r,r],[r,r]]).

% G1X1: 1x1 grid.
g1x1([[r]]).

% G3X3_TWO: 3x3 with two isolated b cells (no b neighbors).
g3x3_two([[r,r,r],[b,r,b],[r,r,r]]).

% G3X3_LINE: 3x3 with vertical line of b cells.
g3x3_line([[r,b,r],[r,b,r],[r,b,r]]).

:- begin_tests(gridnbr).

% gn_nbr4: center cell of 3x3 has 4 neighbors
test(nbr4_center_count) :-
    g3x3(G),
    gn_nbr4(G, 1, 1, Vals),
    length(Vals, 4).

% gn_nbr4: center cell neighbors are all r
test(nbr4_center_all_r) :-
    g3x3(G),
    gn_nbr4(G, 1, 1, Vals),
    \+ member(b, Vals).

% gn_nbr4: corner cell has only 2 neighbors
test(nbr4_corner_count) :-
    g3x3(G),
    gn_nbr4(G, 0, 0, Vals),
    length(Vals, 2).

% gn_nbr4: edge cell has 3 neighbors
test(nbr4_edge_count) :-
    g3x3(G),
    gn_nbr4(G, 0, 1, Vals),
    length(Vals, 3).

% gn_nbr4: 1x1 grid center has no neighbors
test(nbr4_1x1_empty) :-
    g1x1(G),
    gn_nbr4(G, 0, 0, Vals),
    Vals == [].

% gn_nbr8: center cell of 3x3 has 8 neighbors
test(nbr8_center_count) :-
    g3x3(G),
    gn_nbr8(G, 1, 1, Vals),
    length(Vals, 8).

% gn_nbr8: corner cell of 3x3 has 3 neighbors
test(nbr8_corner_count) :-
    g3x3(G),
    gn_nbr8(G, 0, 0, Vals),
    length(Vals, 3).

% gn_nbr8: edge cell of 3x3 has 5 neighbors
test(nbr8_edge_count) :-
    g3x3(G),
    gn_nbr8(G, 0, 1, Vals),
    length(Vals, 5).

% gn_count4: center cell of g3x3 has 0 b neighbors (b is at center, neighbors are r)
test(count4_center_b_zero) :-
    g3x3(G),
    gn_count4(G, 1, 1, b, N),
    N == 0.

% gn_count4: center cell has 4 r neighbors
test(count4_center_r_four) :-
    g3x3(G),
    gn_count4(G, 1, 1, r, N),
    N == 4.

% gn_count4: top-center of g3x3_ring has 2 b neighbors (left=b, right=b)
test(count4_ring_top_b_two) :-
    g3x3_ring(G),
    gn_count4(G, 0, 1, b, N),
    N == 2.

% gn_count8: center of g3x3 has 0 b neighbors (only r around it)
test(count8_center_b_zero) :-
    g3x3(G),
    gn_count8(G, 1, 1, b, N),
    N == 0.

% gn_count8: b-at-center, r surrounding: corner cell (0,0) has 1 r neighbor at (0,1), 1 at (1,0), 1 at (1,1)
test(count8_corner_b_one) :-
    g3x3(G),
    gn_count8(G, 0, 0, b, N),
    N == 1.

% gn_count4_grid: all-r grid, counting b neighbors => all zeros
test(count4_grid_all_zero) :-
    g2x2(G),
    gn_count4_grid(G, b, CG),
    CG == [[0,0],[0,0]].

% gn_count4_grid: g3x3 counting r neighbors at center = 4, corners = 2
test(count4_grid_center_four) :-
    g3x3(G),
    gn_count4_grid(G, r, CG),
    nth0(1, CG, MidRow),
    nth0(1, MidRow, N),
    N == 4.

% gn_count8_grid: all-r 2x2 grid, counting r neighbors
test(count8_grid_2x2) :-
    g2x2(G),
    gn_count8_grid(G, r, CG),
    % corner has 3 r neighbors; but all are 3 except the center has 3 too in 2x2
    nth0(0, CG, Row0),
    nth0(0, Row0, N),
    N == 3.

% gn_any4: center of g3x3 does have r neighbor
test(any4_has_r) :-
    g3x3(G),
    gn_any4(G, 1, 1, r).

% gn_any4: center of g3x3 does NOT have b neighbor
test(any4_no_b, [fail]) :-
    g3x3(G),
    gn_any4(G, 1, 1, b).

% gn_all4: center of g3x3 has all r neighbors
test(all4_all_r) :-
    g3x3(G),
    gn_all4(G, 1, 1, r).

% gn_all4: center of g3x3_ring has all b 4-neighbors
test(all4_ring_center_all_b) :-
    g3x3_ring(G),
    gn_all4(G, 1, 1, b).

% gn_all4: corner of g3x3 does NOT have all b neighbors
test(all4_corner_not_b, [fail]) :-
    g3x3(G),
    gn_all4(G, 0, 0, b).

% gn_mark_border: center b of g3x3 is a border cell (all 4 neighbors are r=bg)
test(mark_border_center_marked) :-
    g3x3(G),
    gn_mark_border(G, r, MG),
    nth0(1, MG, MRow),
    nth0(1, MRow, V),
    V == border.

% gn_mark_border: background cells unchanged
test(mark_border_bg_unchanged) :-
    g3x3(G),
    gn_mark_border(G, r, MG),
    nth0(0, MG, Row0),
    nth0(0, Row0, V),
    V == r.

% gn_mark_border: g5x5 inner b cells (no r neighbor) are NOT border
test(mark_border_inner_not_border) :-
    g5x5(G),
    gn_mark_border(G, r, MG),
    nth0(2, MG, MidRow),
    nth0(2, MidRow, V),
    V == b.

% gn_mark_border: g5x5 outer ring of b cells ARE border
test(mark_border_outer_b_is_border) :-
    g5x5(G),
    gn_mark_border(G, r, MG),
    nth0(1, MG, Row1),
    nth0(1, Row1, V),
    V == border.

% gn_mark_isolated: g3x3_two has two isolated b cells
test(mark_isolated_two_isolated) :-
    g3x3_two(G),
    gn_mark_isolated(G, r, MG),
    nth0(1, MG, MRow),
    nth0(0, MRow, V1),
    nth0(2, MRow, V2),
    V1 == isolated,
    V2 == isolated.

% gn_mark_isolated: g3x3_line cells have same-color neighbors — NOT isolated
test(mark_isolated_line_not_isolated) :-
    g3x3_line(G),
    gn_mark_isolated(G, r, MG),
    nth0(1, MG, MRow),
    nth0(1, MRow, V),
    V == b.

% gn_expand_color: expanding b in g3x3 fills its r neighbors
test(expand_color_fills_neighbors) :-
    g3x3(G),
    gn_expand_color(G, b, E),
    nth0(1, E, Row1),
    nth0(0, Row1, V),
    V == b.

% gn_expand_color: the original b cell remains b
test(expand_color_keeps_original) :-
    g3x3(G),
    gn_expand_color(G, b, E),
    nth0(1, E, Row1),
    nth0(1, Row1, V),
    V == b.

% gn_expand_color: corners are not expanded (no b 4-neighbor)
test(expand_color_corner_unchanged) :-
    g3x3(G),
    gn_expand_color(G, b, E),
    nth0(0, E, Row0),
    nth0(0, Row0, V),
    V == r.

% gn_shrink_color: shrinking b in g3x3 removes the single b cell (it has 4 r neighbors)
test(shrink_color_removes_isolated) :-
    g3x3(G),
    gn_shrink_color(G, b, S),
    nth0(1, S, Row1),
    nth0(1, Row1, V),
    V == r.

% gn_shrink_color: shrinking b in g5x5 removes outer ring of b, keeps inner
test(shrink_color_removes_outer) :-
    g5x5(G),
    gn_shrink_color(G, b, S),
    nth0(1, S, Row1),
    nth0(1, Row1, V),
    V == r.

% gn_shrink_color: inner center of g5x5 remains b after shrink
test(shrink_color_keeps_inner) :-
    g5x5(G),
    gn_shrink_color(G, b, S),
    nth0(2, S, Row2),
    nth0(2, Row2, V),
    V == b.

% gn_majority_nbr4: center of all-r grid — majority is r
test(majority_nbr4_all_r) :-
    g3x3(G),
    gn_majority_nbr4(G, 1, 1, Maj),
    Maj == r.

% gn_majority_nbr4: center of g3x3_ring (r center, b border) — majority of center is b
test(majority_nbr4_ring_center) :-
    g3x3_ring(G),
    gn_majority_nbr4(G, 1, 1, Maj),
    Maj == b.

% gn_majority_nbr4: fails for 1x1 grid (no neighbors)
test(majority_nbr4_1x1_fails, [fail]) :-
    g1x1(G),
    gn_majority_nbr4(G, 0, 0, _).

% gn_conway_step: isolated b cell in g3x3 has 0 b neighbors — rule with N=0 kills it
test(conway_step_kills_isolated) :-
    g3x3(G),
    gn_conway_step(G, b, 0, NG),
    nth0(1, NG, Row1),
    nth0(1, Row1, V),
    V == r.

% gn_conway_step: rule with N=1 does NOT kill isolated b (has 0, not 1 b-neighbor)
test(conway_step_no_kill_wrong_n) :-
    g3x3(G),
    gn_conway_step(G, b, 1, NG),
    nth0(1, NG, Row1),
    nth0(1, Row1, V),
    V == b.

% gn_conway_step: uniform r grid — rule on r with N=3 kills corner cells
% corner has 2 r neighbors, not 3 — not killed
test(conway_step_corner_not_killed) :-
    g2x2(G),
    gn_conway_step(G, r, 3, NG),
    nth0(0, NG, Row0),
    nth0(0, Row0, V),
    V == r.

% gn_count4: 1x1 grid has 0 neighbors of any color
test(count4_1x1_zero) :-
    g1x1(G),
    gn_count4(G, 0, 0, r, N),
    N == 0.

% gn_count8: 1x1 grid has 0 8-neighbors
test(count8_1x1_zero) :-
    g1x1(G),
    gn_count8(G, 0, 0, r, N),
    N == 0.

% gn_nbr8: b cell at center of g3x3 has 0 b 8-neighbors
test(nbr8_center_no_b) :-
    g3x3(G),
    gn_nbr8(G, 1, 1, Vals),
    \+ member(b, Vals).

% gn_all4: fails for 1x1 (no neighbors)
test(all4_1x1_fails, [fail]) :-
    g1x1(G),
    gn_all4(G, 0, 0, r).

% gn_mark_border: uniform r grid — no non-bg cells, so result equals input
test(mark_border_uniform_unchanged) :-
    g2x2(G),
    gn_mark_border(G, r, MG),
    MG == G.

% gn_mark_isolated: uniform r grid unchanged
test(mark_isolated_uniform_unchanged) :-
    g2x2(G),
    gn_mark_isolated(G, r, MG),
    MG == G.

% gn_expand_color: expanding r in all-r grid keeps it unchanged
test(expand_color_all_same) :-
    g2x2(G),
    gn_expand_color(G, r, E),
    E == G.

% gn_shrink_color: shrinking r in all-r grid — all r cells touch non-r? No, only r exists.
% All cells ARE the same color; but bg=r, and non-r neighbors don't exist. Eroding r:
% a cell erodes if it touches a non-r neighbor. In all-r grid, no cell has a non-r neighbor.
test(shrink_color_all_same_unchanged) :-
    g2x2(G),
    gn_shrink_color(G, r, S),
    S == G.

% gn_conway_step: no Color cells — grid unchanged
test(conway_step_no_color_cells) :-
    g2x2(G),
    gn_conway_step(G, b, 0, NG),
    NG == G.

% gn_count4_grid: 1x1 grid
test(count4_grid_1x1) :-
    g1x1(G),
    gn_count4_grid(G, r, CG),
    CG == [[0]].

% gn_count8_grid: 1x1 grid
test(count8_grid_1x1) :-
    g1x1(G),
    gn_count8_grid(G, r, CG),
    CG == [[0]].

% gn_majority_nbr4: g3x3_two — left isolated b at (1,0) has majority neighbor r
test(majority_nbr4_isolated_r) :-
    g3x3_two(G),
    gn_majority_nbr4(G, 1, 0, Maj),
    Maj == r.

:- end_tests(gridnbr).
