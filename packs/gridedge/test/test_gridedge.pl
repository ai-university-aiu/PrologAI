:- use_module('../prolog/gridedge').

% Grid fixtures
% 3x3 grid with r region in top-left, x background
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% Uniform grid (no edges)
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
% Single-row strip
g1x5([[r,r,x,r,r]]).
% 3x3 with a cross pattern
g3x3_cross([[x,r,x],[r,r,r],[x,r,x]]).
% 3x3 with all same color
g3x3_all_x([[x,x,x],[x,x,x],[x,x,x]]).
% 5x5 with interior r region surrounded by x
g5x5_ring([[x,x,x,x,x],[x,r,r,r,x],[x,r,r,r,x],[x,r,r,r,x],[x,x,x,x,x]]).
% 3x3 diagonal pattern
g3x3_diag([[r,x,x],[x,r,x],[x,x,r]]).
% 1x1 grid
g1x1([[r]]).
% Small line grid
g3x3_line([[x,x,x],[r,r,r],[x,x,x]]).
% 2x2 checkerboard
g2x2_checker([[r,x],[x,r]]).

:- begin_tests(gridedge).

% --- ge_edge_cells ---
test(edge_cells_rb_region, []) :-
    g3x3_rb(G),
    ge_edge_cells(G, r, Cells),
    % r cells (0,1),(1,0),(1,1) have x neighbors; (0,0) only touches r cells
    length(Cells, 3).

test(edge_cells_uniform_none, []) :-
    g3x3_all_r(G),
    ge_edge_cells(G, r, []).

test(edge_cells_cross, []) :-
    g3x3_cross(G),
    ge_edge_cells(G, r, Cells),
    % 4 arm cells have x neighbors; center (1,1) has all-r neighbors
    length(Cells, 4).

test(edge_cells_ring_interior_not_edge, []) :-
    g5x5_ring(G),
    ge_edge_cells(G, r, Cells),
    % Only the 8 border r cells are edge cells; center r cell has all r neighbors
    length(Cells, 8).

% --- ge_edge_cells8 ---
test(edge_cells8_rb_all, []) :-
    g3x3_rb(G),
    ge_edge_cells8(G, r, Cells),
    % (0,0) has only r 8-neighbors; (0,1),(1,0),(1,1) each have x 8-neighbors
    length(Cells, 3).

test(edge_cells8_diag_are_edges, []) :-
    g3x3_diag(G),
    ge_edge_cells8(G, r, Cells),
    % All 3 r cells in diagonal: center r has x on all 8 sides? No, each diag r
    % has x 4-neighbors and x 8-neighbors of different color
    length(Cells, 3).

% --- ge_is_edge ---
test(is_edge_boundary_cell, []) :-
    g3x3_rb(G),
    % (0,1) is r with x neighbor at (0,2)
    ge_is_edge(G, 0-1, yes).

test(is_edge_interior_uniform, []) :-
    g3x3_all_r(G),
    ge_is_edge(G, 1-1, no).

test(is_edge_center_of_ring, []) :-
    g5x5_ring(G),
    ge_is_edge(G, 2-2, no).

test(is_edge_border_of_ring, []) :-
    g5x5_ring(G),
    ge_is_edge(G, 1-1, yes).

% --- ge_boundary ---
test(boundary_r_touching_x, []) :-
    g3x3_rb(G),
    ge_boundary(G, r, x, Cells),
    % r cells with x neighbors: (0,1) via (0,2), (1,0) via (2,0), (1,1) via (2,1)/(1,2)
    % (0,0) has only r neighbors -> not in boundary
    length(Cells, 3).

test(boundary_no_contact, []) :-
    g3x3_all_r(G),
    ge_boundary(G, r, x, []).

test(boundary_x_touching_r, []) :-
    g3x3_rb(G),
    ge_boundary(G, x, r, Cells),
    % x cells touching r: (0,2),(1,2),(2,0),(2,1)
    length(Cells, 4).

% --- ge_inner_border ---
test(inner_border_ring_no_bg_interior, []) :-
    g5x5_ring(G),
    ge_inner_border(G, x, Cells),
    % x cells adjacent to r: the 12 x cells on the inner rim
    length(Cells, 12).

test(inner_border_uniform_none, []) :-
    g3x3_all_r(G),
    ge_inner_border(G, x, []).

% --- ge_outer_border ---
test(outer_border_r_in_rb, []) :-
    g3x3_rb(G),
    ge_outer_border(G, r, Cells),
    % non-r cells adjacent to r: (0,2),(1,2),(2,0),(2,1)
    length(Cells, 4).

test(outer_border_uniform_none, []) :-
    g3x3_all_r(G),
    ge_outer_border(G, r, []).

% --- ge_edge_grid ---
test(edge_grid_marks_boundary, []) :-
    g3x3_rb(G),
    ge_edge_grid(G, r, e, Result),
    % e cells at (0,1),(1,0),(1,1); (0,0) is smooth r
    findall(R-C, (nth0(R, Result, Row), nth0(C, Row, e)), ECells),
    length(ECells, 3).

test(edge_grid_uniform_unchanged, []) :-
    g3x3_all_r(G),
    ge_edge_grid(G, r, e, G).

% --- ge_edge_count ---
test(edge_count_rb, []) :-
    g3x3_rb(G),
    ge_edge_count(G, r, 3).

test(edge_count_uniform_zero, []) :-
    g3x3_all_r(G),
    ge_edge_count(G, r, 0).

test(edge_count_cross, []) :-
    g3x3_cross(G),
    ge_edge_count(G, r, 4).

% --- ge_neighbors_diff ---
test(neighbors_diff_corner_cell, []) :-
    g3x3_rb(G),
    ge_neighbors_diff(G, 0, 0, Nbrs),
    % (0,0) is r; neighbors: (0,1)=r (same), (1,0)=r (same)
    % Those are in-bounds; no x neighbors for (0,0): it's corner
    Nbrs = [].

test(neighbors_diff_edge_cell, []) :-
    g3x3_rb(G),
    ge_neighbors_diff(G, 0, 1, Nbrs),
    % (0,1) is r; neighbors: (0,0)=r, (0,2)=x(diff), (1,1)=r
    length(Nbrs, 1).

test(neighbors_diff_cross_center, []) :-
    g3x3_cross(G),
    ge_neighbors_diff(G, 1, 1, Nbrs),
    % Center (1,1) is r; all 4 neighbors are: (0,1)=r,(1,0)=r,(1,2)=r,(2,1)=r
    Nbrs = [].

% --- ge_corners ---
test(corners_rb_region, []) :-
    g3x3_rb(G),
    ge_corners(G, r, Cells),
    % r corner cells (2+ diff-colored neighbors):
    % (0,1): neighbors=(0,0)=r,(0,2)=x,(1,1)=r -> 1 diff: NOT corner
    % (1,0): neighbors=(0,0)=r,(2,0)=x,(1,1)=r -> 1 diff: NOT corner
    % (1,1): neighbors=(0,1)=r,(2,1)=x,(1,0)=r,(1,2)=x -> 2 diff: CORNER
    % (0,0): neighbors=(0,1)=r,(1,0)=r -> 0 diff: NOT corner
    Cells = [1-1].

test(corners_uniform_none, []) :-
    g3x3_all_r(G),
    ge_corners(G, r, []).

% --- ge_endpoints ---
test(endpoints_cross_arms, []) :-
    g3x3_cross(G),
    ge_endpoints(G, r, Cells),
    % Cells with exactly 1 r neighbor:
    % (0,1): neighbors=(1,1)=r only -> 1 same-color: ENDPOINT
    % (1,0): neighbors=(1,1)=r only -> 1 same-color: ENDPOINT
    % (1,1): neighbors=(0,1)=r,(2,1)=r,(1,0)=r,(1,2)=r -> 4 same: NOT endpoint
    % (1,2): neighbors=(1,1)=r only -> 1 same-color: ENDPOINT
    % (2,1): neighbors=(1,1)=r only -> 1 same-color: ENDPOINT
    length(Cells, 4).

test(endpoints_line_ends, []) :-
    g3x3_line(G),
    ge_endpoints(G, r, Cells),
    % r line: (1,0),(1,1),(1,2)
    % (1,0): r-neighbor (1,1) only -> endpoint
    % (1,2): r-neighbor (1,1) only -> endpoint
    % (1,1): r-neighbors (1,0) and (1,2) -> not endpoint
    length(Cells, 2).

% --- ge_smooth_cells ---
test(smooth_cells_interior, []) :-
    g5x5_ring(G),
    ge_smooth_cells(G, r, Cells),
    % Only the center r cell (2,2) has all 4 r neighbors
    Cells = [2-2].

test(smooth_cells_uniform, []) :-
    g3x3_all_r(G),
    ge_smooth_cells(G, r, Cells),
    % All 9 cells: interior cells have all-r neighbors; grid edges have fewer
    % but grid boundary cells don't have out-of-bounds neighbors counted,
    % only in-bounds ones. All in-bounds neighbors of any r cell are r.
    length(Cells, 9).

test(smooth_cells_no_smooth_in_rb, []) :-
    g3x3_rb(G),
    ge_smooth_cells(G, r, Cells),
    % (0,0): in-bounds neighbors (0,1)=r,(1,0)=r -> all same: SMOOTH
    Cells = [0-0].

% --- ge_transition_map ---
test(transition_map_uniform_all_zero, []) :-
    g3x3_all_x(G),
    ge_transition_map(G, R),
    % All cells have 0 differently-colored neighbors
    R = [[0,0,0],[0,0,0],[0,0,0]].

test(transition_map_rb_corner, []) :-
    g3x3_rb(G),
    ge_transition_map(G, R),
    % (0,0) r: nbrs (0,1)=r,(1,0)=r -> 0 diff
    % (0,1) r: nbrs (0,0)=r,(0,2)=x,(1,1)=r -> 1 diff
    % (0,2) x: nbrs (0,1)=r,(1,2)=x -> 1 diff
    % (1,0) r: nbrs (0,0)=r,(2,0)=x,(1,1)=r -> 1 diff
    % (1,1) r: nbrs (0,1)=r,(2,1)=x,(1,0)=r,(1,2)=x -> 2 diff
    % (1,2) x: nbrs (1,1)=r,(0,2)=x,(2,2)=x -> 1 diff
    % (2,0) x: nbrs (1,0)=r,(2,1)=x -> 1 diff
    % (2,1) x: nbrs (2,0)=x,(2,2)=x,(1,1)=r -> 1 diff
    % (2,2) x: nbrs (2,1)=x,(1,2)=x -> 0 diff
    R = [[0,1,1],[1,2,1],[1,1,0]].

test(transition_map_checkerboard, []) :-
    g2x2_checker(G),
    ge_transition_map(G, R),
    % All cells are edge cells (each has 2 differently-colored neighbors)
    R = [[2,2],[2,2]].

% --- ge_edge_color_count ---
test(edge_color_count_r_to_x, []) :-
    g3x3_rb(G),
    ge_edge_color_count(G, r, x, N),
    N =:= 3.

test(edge_color_count_none, []) :-
    g3x3_all_r(G),
    ge_edge_color_count(G, r, x, 0).

% --- Combined tests ---
test(edge_cells_plus_smooth_partition, []) :-
    g5x5_ring(G),
    ge_edge_cells(G, r, ECells),
    ge_smooth_cells(G, r, SCells),
    length(ECells, E), length(SCells, S),
    % 9 r cells total: 8 edge + 1 smooth
    N is E + S,
    N =:= 9.

test(outer_border_subset_of_x_cells, []) :-
    g3x3_rb(G),
    ge_outer_border(G, r, OB),
    % All outer border cells should be x
    maplist([RC]>>(RC = R-C, nth0(R, G, Row), nth0(C, Row, x)), OB).

test(transition_map_value_leq_4, []) :-
    g3x3_rb(G),
    ge_transition_map(G, R),
    findall(V, (member(Row, R), member(V, Row)), Vs),
    maplist([V]>>(V >= 0, V =< 4), Vs).

test(edge_cells_1x1_none, []) :-
    g1x1(G),
    ge_edge_cells(G, r, []).

test(is_edge_1x1_no, []) :-
    g1x1(G),
    ge_is_edge(G, 0-0, no).

test(smooth_cells_cross_center, []) :-
    g3x3_cross(G),
    ge_smooth_cells(G, r, Cells),
    Cells = [1-1].

test(endpoints_uniform_none, []) :-
    g3x3_all_r(G),
    ge_endpoints(G, r, []).

:- end_tests(gridedge).
