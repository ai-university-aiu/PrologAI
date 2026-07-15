:- use_module('../prolog/grid_graph').

% Grid fixtures
% 3x3 with r in top-left, x elsewhere
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% Uniform grids
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
g3x3_all_x([[x,x,x],[x,x,x],[x,x,x]]).
% 5x5 ring: r border, x hole
g5x5_ring([[r,r,r,r,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,r,r,r,r]]).
% 5x5 with r block in center
g5x5_block([[x,x,x,x,x],[x,r,r,r,x],[x,r,r,r,x],[x,r,r,r,x],[x,x,x,x,x]]).
% 3-color grid: top=a, middle=b, bottom=c
g3x3_abc([[a,a,a],[b,b,b],[c,c,c]]).
% Grid with two separate r regions
g5x5_two([[r,x,x,x,r],[x,x,x,x,x],[x,x,x,x,x],[x,x,x,x,x],[r,x,x,x,r]]).
% 5x5 with r spanning full width
g5x5_span([[x,x,x,x,x],[r,r,r,r,r],[x,x,x,x,x],[x,x,x,x,x],[x,x,x,x,x]]).
% 5x5 r spanning full height (column 0 and column 4 are r)
g5x5_vspan([[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r]]).

:- begin_tests(grid_graph).

% --- grid_graph_adj_colors ---
test(adj_colors_rb, []) :-
    g3x3_rb(G),
    % Only pair: r-x
    grid_graph_adj_colors(G, Pairs),
    Pairs = [r-x].

test(adj_colors_abc, []) :-
    g3x3_abc(G),
    % a-b and b-c adjacent; a and c not adjacent
    grid_graph_adj_colors(G, Pairs),
    member(a-b, Pairs), member(b-c, Pairs),
    \+ member(a-c, Pairs).

test(adj_colors_uniform, []) :-
    g3x3_all_r(G),
    % Single color: no pairs
    grid_graph_adj_colors(G, []).

% --- grid_graph_adj_of ---
test(adj_of_r_in_rb, []) :-
    g3x3_rb(G),
    grid_graph_adj_of(G, r, [x]).

test(adj_of_x_in_rb, []) :-
    g3x3_rb(G),
    grid_graph_adj_of(G, x, [r]).

test(adj_of_b_in_abc, []) :-
    g3x3_abc(G),
    % b is between a (above) and c (below)
    grid_graph_adj_of(G, b, Nbrs),
    msort(Nbrs, Sorted),
    Sorted = [a, c].

test(adj_of_uniform, []) :-
    g3x3_all_r(G),
    grid_graph_adj_of(G, r, []).

% --- grid_graph_adj_graph ---
test(adj_graph_rb, []) :-
    g3x3_rb(G),
    grid_graph_adj_graph(G, Graph),
    member(r-[x], Graph),
    member(x-[r], Graph).

test(adj_graph_uniform, []) :-
    g3x3_all_r(G),
    grid_graph_adj_graph(G, [r-[]]).

% --- grid_graph_are_adj ---
test(are_adj_r_x, []) :-
    g3x3_rb(G),
    grid_graph_are_adj(G, r, x).

test(are_not_adj_same, []) :-
    g3x3_rb(G),
    \+ grid_graph_are_adj(G, r, r).

test(are_adj_a_b, []) :-
    g3x3_abc(G),
    grid_graph_are_adj(G, a, b).

test(are_not_adj_a_c, []) :-
    g3x3_abc(G),
    % a (top row) and c (bottom row) do not share a border
    \+ grid_graph_are_adj(G, a, c).

% --- grid_graph_color_degree ---
test(degree_r_in_rb, []) :-
    g3x3_rb(G),
    grid_graph_color_degree(G, r, 1).

test(degree_b_in_abc, []) :-
    g3x3_abc(G),
    % b is adjacent to a and c -> degree 2
    grid_graph_color_degree(G, b, 2).

test(degree_uniform, []) :-
    g3x3_all_r(G),
    grid_graph_color_degree(G, r, 0).

% --- grid_graph_shared_border ---
test(shared_border_r_x, []) :-
    g3x3_rb(G),
    % r cells adjacent to x: (0,1),(1,0),(1,1)
    grid_graph_shared_border(G, r, x, Cells),
    length(Cells, 3).

test(shared_border_x_r, []) :-
    g3x3_rb(G),
    % x cells adjacent to r: (0,2),(1,2),(2,0),(2,1)
    grid_graph_shared_border(G, x, r, Cells),
    length(Cells, 4).

% --- grid_graph_border_length ---
test(border_length_r_x, []) :-
    g3x3_rb(G),
    grid_graph_border_length(G, r, x, 3).

test(border_length_x_r, []) :-
    g3x3_rb(G),
    grid_graph_border_length(G, x, r, 4).

% --- grid_graph_isolated_colors ---
test(isolated_uniform_r, []) :-
    g3x3_all_r(G),
    % r has no different-colored neighbors -> isolated
    grid_graph_isolated_colors(G, [r]).

test(isolated_none_rb, []) :-
    g3x3_rb(G),
    % Both r and x are adjacent to each other -> neither isolated
    grid_graph_isolated_colors(G, []).

% --- grid_graph_enclosed_colors ---
test(enclosed_x_in_ring, []) :-
    g5x5_ring(G),
    % x is enclosed by r: x has no border cells, every x neighbor is r or x,
    % and every non-x neighbor of x is r
    grid_graph_enclosed_colors(G, Inner, r),
    Inner = [x].

test(not_enclosed_r_in_block, []) :-
    g5x5_block(G),
    % r is NOT enclosed by x: r has no cells on border (true), but some r cells
    % have r neighbors that lead to... wait all r neighbors are r.
    % Actually condition 2: every non-r neighbor of r must be x.
    % For g5x5_block: r cells at (1..3, 1..3); all non-r neighbors are x -> satisfied.
    % Condition 1: no r cell on border -> satisfied.
    % So r IS enclosed by x.
    grid_graph_enclosed_colors(G, Inner, x),
    Inner = [r].

test(not_enclosed_border_color, []) :-
    g5x5_ring(G),
    % r has cells on the border -> NOT enclosed
    grid_graph_enclosed_colors(G, Inner, x),
    % r is on border -> not in Inner; x might not be enclosed by x either
    \+ member(r, Inner).

% --- grid_graph_spanning_h ---
test(spanning_h_none_in_rb, []) :-
    g3x3_rb(G),
    % r: col 0 cells at (0,0),(1,0) yes; col 2 (last) = x; r NOT in col 2 -> not spanning h
    % x: col 2 cells at (0,2),(1,2),(2,2) yes; col 0 cells at (2,0) yes -> x spans h
    grid_graph_spanning_h(G, Colors),
    member(x, Colors),
    \+ member(r, Colors).

test(spanning_h_full_row, []) :-
    % Grid where r spans the entire width
    G = [[r,r,r],[x,x,x],[x,x,x]],
    grid_graph_spanning_h(G, Colors),
    member(r, Colors).

% --- grid_graph_spanning_v ---
test(spanning_v_abc, []) :-
    g3x3_abc(G),
    % a in row 0, c in last row (2), b in middle
    % a spans v? a in row 0 yes; a in row 2? No -> not spanning
    % c in row 2? yes; c in row 0? No -> not spanning
    % No color spans v
    grid_graph_spanning_v(G, []).

test(spanning_v_full_col, []) :-
    g5x5_vspan(G),
    % r is in col 0 of row 0 and col 0 of row 4 -> r spans v
    grid_graph_spanning_v(G, Colors),
    member(r, Colors).

% --- grid_graph_merge_colors ---
test(merge_r_to_x, []) :-
    g3x3_rb(G),
    grid_graph_merge_colors(G, r, x, Result),
    Result = [[x,x,x],[x,x,x],[x,x,x]].

test(merge_noop, []) :-
    g3x3_rb(G),
    % Merge a color not in Grid -> no change
    grid_graph_merge_colors(G, z, y, G).

% --- grid_graph_color_components ---
test(components_one, []) :-
    g5x5_block(G),
    % 3x3 r block is all connected -> 1 component
    grid_graph_color_components(G, r, 1).

test(components_four_corners, []) :-
    g5x5_two(G),
    % 4 isolated r cells at corners -> 4 components
    grid_graph_color_components(G, r, 4).

test(components_uniform, []) :-
    g3x3_all_r(G),
    grid_graph_color_components(G, r, 1).

% --- grid_graph_component_cells ---
test(component_cells_one, []) :-
    g5x5_block(G),
    grid_graph_component_cells(G, r, Components),
    length(Components, 1),
    [Cells] = Components,
    length(Cells, 9).

test(component_cells_four, []) :-
    g5x5_two(G),
    grid_graph_component_cells(G, r, Components),
    length(Components, 4),
    % Each component has exactly 1 cell
    findall(1, (member(Comp, Components), length(Comp, 1)), Ones),
    length(Ones, 4).

% --- Combined tests ---
test(adj_colors_symmetric, []) :-
    g3x3_rb(G),
    grid_graph_adj_colors(G, Pairs),
    % All pairs C1-C2 have C1 @< C2 (sorted)
    \+ (member(C1-C2, Pairs), \+ C1 @< C2).

test(degree_equals_adj_of_length, []) :-
    g3x3_abc(G),
    grid_graph_adj_of(G, b, Nbrs),
    grid_graph_color_degree(G, b, N),
    length(Nbrs, N).

test(border_length_asymmetric, []) :-
    g3x3_rb(G),
    % r->x and x->r border lengths can differ (asymmetric)
    grid_graph_border_length(G, r, x, N1),
    grid_graph_border_length(G, x, r, N2),
    N1 \= N2.

test(merge_then_uniform, []) :-
    g3x3_rb(G),
    grid_graph_merge_colors(G, x, r, All_r),
    grid_graph_isolated_colors(All_r, [r]).

test(component_cells_count_eq_color_components, []) :-
    g5x5_two(G),
    grid_graph_component_cells(G, r, Comps),
    grid_graph_color_components(G, r, N),
    length(Comps, N).

test(adj_colors_three_pair_count, []) :-
    g3x3_abc(G),
    grid_graph_adj_colors(G, Pairs),
    % a-b and b-c: exactly 2 pairs
    length(Pairs, 2).

test(spanning_h_both_borders_x, []) :-
    g5x5_block(G),
    % x has cells in col 0 (all border) and col 4 (all border) -> x spans h
    grid_graph_spanning_h(G, Colors),
    member(x, Colors).

test(component_cells_all_in_correct_color, []) :-
    g5x5_block(G),
    grid_graph_component_cells(G, r, [Comp]),
    % All cells in the component should be r
    \+ (member(R-C, Comp), \+ (nth0(R, G, Row), nth0(C, Row, r))).

:- end_tests(grid_graph).
