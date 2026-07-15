:- use_module('../prolog/gridconv').

% Grid fixtures
% 3x3 with r region in top-left corner
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% 5x5 with r block center
g5x5_block([[x,x,x,x,x],[x,r,r,r,x],[x,r,r,r,x],[x,r,r,r,x],[x,x,x,x,x]]).
% 5x5 dot (single r)
g5x5_dot([[x,x,x,x,x],[x,x,x,x,x],[x,x,r,x,x],[x,x,x,x,x],[x,x,x,x,x]]).
% Uniform grids
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
g3x3_all_x([[x,x,x],[x,x,x],[x,x,x]]).
% 5x5 ring
g5x5_ring([[r,r,r,r,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,r,r,r,r]]).
% 2x2 uniform
g2x2_r([[r,r],[r,r]]).
% 4x4 grid with small pattern
g4x4_ab([[a,b,a,b],[b,a,b,a],[a,b,a,b],[b,a,b,a]]).
% Grid with a 2x2 r block inside
g5x5_twoblock([[x,x,x,x,x],[x,r,r,x,x],[x,r,r,x,x],[x,x,x,r,r],[x,x,x,r,r]]).

:- begin_tests(gridconv).

% --- gridconv_window ---
test(window_center, []) :-
    g3x3_rb(G),
    % N=1: 3x3 window at center (1,1); entire grid; fill=z (no out-of-bounds)
    gridconv_window(G, 1, 1, 1, z, W),
    W = [[r,r,x],[r,r,x],[x,x,x]].

test(window_corner_with_fill, []) :-
    g3x3_rb(G),
    % N=1: 3x3 window at (0,0); out-of-bounds fill=z
    gridconv_window(G, 0, 0, 1, z, W),
    W = [[z,z,z],[z,r,r],[z,r,r]].

test(window_radius_0, []) :-
    g3x3_rb(G),
    % N=0: 1x1 window at (0,1) = just that cell
    gridconv_window(G, 0, 1, 0, z, W),
    W = [[r]].

% --- gridconv_count_in ---
test(count_in_center, []) :-
    g3x3_rb(G),
    % N=1: 3x3 window at (1,1); 4 r cells in top-left
    gridconv_count_in(G, 1, 1, 1, r, 4).

test(count_in_corner, []) :-
    g3x3_rb(G),
    % N=1: window at (0,0); only in-bounds: (0,0)=r,(0,1)=r,(1,0)=r,(1,1)=r = 4 r
    % Wait: in-bounds at (0,0) with N=1 are (0,0),(0,1),(1,0),(1,1) = 4 cells, all r
    gridconv_count_in(G, 0, 0, 1, r, 4).

test(count_in_zero, []) :-
    g3x3_all_x(G),
    gridconv_count_in(G, 1, 1, 1, r, 0).

test(count_in_dot, []) :-
    g5x5_dot(G),
    % N=0: 1x1 window at center (2,2) = 1 r
    gridconv_count_in(G, 2, 2, 0, r, 1).

% --- gridconv_density_map ---
test(density_map_dot, []) :-
    g5x5_dot(G),
    % N=1: center cell (2,2) has 1 r in 3x3 window; edges have 0 or 1
    gridconv_density_map(G, 1, r, DMap),
    nth0(2, DMap, Row), nth0(2, Row, 1).

test(density_map_uniform_x, []) :-
    g3x3_all_x(G),
    gridconv_density_map(G, 1, r, DMap),
    % All zeros
    DMap = [[0,0,0],[0,0,0],[0,0,0]].

test(density_map_all_r, []) :-
    g3x3_all_r(G),
    gridconv_density_map(G, 0, r, DMap),
    % N=0: each cell's window is just itself; all are r -> all 1
    DMap = [[1,1,1],[1,1,1],[1,1,1]].

% --- gridconv_majority ---
test(majority_center_rb, []) :-
    g3x3_rb(G),
    % N=1 at center (1,1): 4 r, 5 x -> x is majority
    % Wait: 3x3 window: r,r,x / r,r,x / x,x,x = 4r, 5x -> majority = x
    gridconv_majority(G, 1, 1, 1, x).

test(majority_top_left_rb, []) :-
    g3x3_rb(G),
    % N=1 at (0,0): in-bounds only: (0,0)=r,(0,1)=r,(1,0)=r,(1,1)=r -> all r
    gridconv_majority(G, 0, 0, 1, r).

test(majority_uniform, []) :-
    g3x3_all_r(G),
    gridconv_majority(G, 1, 1, 1, r).

% --- gridconv_majority_map ---
test(majority_map_uniform, []) :-
    g3x3_all_r(G),
    gridconv_majority_map(G, 1, G).

test(majority_map_dot, []) :-
    g5x5_dot(G),
    % N=1: majority at each cell is x (1 r vs many x); center might be x
    gridconv_majority_map(G, 1, Result),
    % Center (2,2) has 1 r in a 3x3 window of 9 in-bounds cells -> x majority
    nth0(2, Result, Row), nth0(2, Row, x).

% --- gridconv_uniform_at ---
test(uniform_at_uniform_grid, []) :-
    g3x3_all_r(G),
    gridconv_uniform_at(G, 1, 1, 1, yes).

test(uniform_at_mixed_no, []) :-
    g3x3_rb(G),
    gridconv_uniform_at(G, 1, 1, 1, no).

test(uniform_at_corner_rb, []) :-
    g3x3_rb(G),
    % N=1 at (0,0): in-bounds = (0,0)=r,(0,1)=r,(1,0)=r,(1,1)=r -> all r -> yes
    gridconv_uniform_at(G, 0, 0, 1, yes).

test(uniform_at_n0_single, []) :-
    g3x3_rb(G),
    % N=0: 1x1 window = just cell (0,2)=x -> uniform yes
    gridconv_uniform_at(G, 0, 2, 0, yes).

% --- gridconv_uniform_cells ---
test(uniform_cells_n0_all, []) :-
    g3x3_all_r(G),
    % N=0: each cell's window is itself; all uniform
    gridconv_uniform_cells(G, 0, Cells),
    length(Cells, 9).

test(uniform_cells_n1_all_r, []) :-
    g3x3_all_r(G),
    % N=1: all windows are all-r
    gridconv_uniform_cells(G, 1, Cells),
    length(Cells, 9).

test(uniform_cells_n1_rb_some, []) :-
    g3x3_rb(G),
    % N=1 on g3x3_rb: only (0,0) corner is uniform (all r in-bounds)
    gridconv_uniform_cells(G, 1, Cells),
    Cells = [0-0].

% --- gridconv_find_pattern ---
test(find_pattern_identity, []) :-
    g2x2_r(G),
    % Pattern = grid itself -> found at (0,0)
    gridconv_find_pattern(G, G, Positions),
    Positions = [0-0].

test(find_pattern_1x1, []) :-
    g3x3_rb(G),
    % Find 1x1 pattern [[r]] in g3x3_rb -> 4 positions
    gridconv_find_pattern(G, [[r]], Positions),
    length(Positions, 4).

test(find_pattern_not_found, []) :-
    g3x3_all_x(G),
    gridconv_find_pattern(G, [[r]], []).

test(find_pattern_2x2_in_5x5, []) :-
    g5x5_twoblock(G),
    % Find 2x2 r block: [[r,r],[r,r]] in g5x5_twoblock
    % Block at (1,1) and (3,3)
    gridconv_find_pattern(G, [[r,r],[r,r]], Positions),
    length(Positions, 2).

% --- gridconv_count_pattern ---
test(count_pattern_one, []) :-
    g3x3_rb(G),
    gridconv_count_pattern(G, [[r,r],[r,r]], 1).

test(count_pattern_zero, []) :-
    g3x3_all_x(G),
    gridconv_count_pattern(G, [[r]], 0).

% --- gridconv_has_pattern ---
test(has_pattern_yes, []) :-
    g3x3_rb(G),
    gridconv_has_pattern(G, [[r]]).

test(has_pattern_no, []) :-
    g3x3_all_x(G),
    \+ gridconv_has_pattern(G, [[r]]).

% --- gridconv_hot_spots ---
test(hot_spots_center, []) :-
    g5x5_dot(G),
    % N=1, Color=r, Threshold=1: cells where r count >= 1 in 3x3 window
    % Only cells within Manhattan dist <= sqrt(2) of center can see the dot
    % In-bounds neighbors of (2,2) in 3x3 window: (1,1),(1,2),(1,3),(2,1),(2,2),(2,3),(3,1),(3,2),(3,3)
    % All 9 have at least 1 r in their N=1 window -> 9 hot spots
    gridconv_hot_spots(G, 1, r, 1, Cells),
    length(Cells, 9).

test(hot_spots_none, []) :-
    g3x3_all_x(G),
    gridconv_hot_spots(G, 1, r, 1, []).

test(hot_spots_high_threshold, []) :-
    g3x3_all_r(G),
    % N=1, Threshold=9: center has 9 in-bounds cells all r -> count=9 >= 9
    % Corner cells have 4 in-bounds cells -> count=4 < 9
    % Edge cells (non-corner) have 6 in-bounds cells -> count=6 < 9
    % Only center (1,1) qualifies
    gridconv_hot_spots(G, 1, r, 9, Cells),
    Cells = [1-1].

% --- gridconv_dilate_sq ---
test(dilate_sq_n0_identity, []) :-
    g3x3_rb(G),
    gridconv_dilate_sq(G, r, 0, G).

test(dilate_sq_n1_dot_fills, []) :-
    g5x5_dot(G),
    gridconv_dilate_sq(G, r, 1, Result),
    % 3x3 window at center has the r dot; all 9 center-region cells become r
    findall(RC, (nth0(Row,Result,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 9).

test(dilate_sq_uniform_unchanged, []) :-
    g3x3_all_r(G),
    gridconv_dilate_sq(G, r, 1, G).

% --- gridconv_erode_sq ---
test(erode_sq_n0_identity, []) :-
    g3x3_all_r(G),
    gridconv_erode_sq(G, r, 0, G).

test(erode_sq_n1_block_to_center, []) :-
    g5x5_block(G),
    % 3x3 block: N=1 square erosion: center (2,2) has full 3x3 all-r window -> survives
    % All other r cells have some x in their 3x3 window -> eroded
    gridconv_erode_sq(G, r, 1, Result),
    findall(RC, (nth0(Row,Result,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [2-2].

test(erode_sq_uniform_unchanged, []) :-
    g3x3_all_r(G),
    gridconv_erode_sq(G, r, 1, G).

% --- gridconv_replace_pattern ---
test(replace_pattern_first_match, []) :-
    g5x5_twoblock(G),
    % Replace first 2x2 r block at (1,1) with [[a,a],[a,a]]
    gridconv_replace_pattern(G, [[r,r],[r,r]], [[a,a],[a,a]], Result),
    nth0(1, Result, Row1), nth0(1, Row1, a),
    nth0(1, Result, Row1), nth0(2, Row1, a).

test(replace_pattern_no_match_unchanged, []) :-
    g3x3_all_x(G),
    gridconv_replace_pattern(G, [[r]], [[a]], G).

% --- Combined tests ---
test(find_and_count_consistent, []) :-
    g5x5_twoblock(G),
    gridconv_find_pattern(G, [[r,r],[r,r]], Positions),
    gridconv_count_pattern(G, [[r,r],[r,r]], Count),
    length(Positions, Count).

test(density_map_matches_count_in, []) :-
    g3x3_rb(G),
    gridconv_density_map(G, 1, r, DMap),
    nth0(1, DMap, Row), nth0(1, Row, V),
    gridconv_count_in(G, 1, 1, 1, r, V).

test(dilate_sq_increases_fg, []) :-
    g5x5_dot(G),
    gridconv_dilate_sq(G, r, 1, D),
    findall(1, (member(Row,G), member(r,Row)), Orig),
    findall(1, (member(Row,D), member(r,Row)), Dil),
    length(Orig, NO), length(Dil, ND),
    ND > NO.

test(erode_sq_decreases_fg, []) :-
    g5x5_block(G),
    gridconv_erode_sq(G, r, 1, E),
    findall(1, (member(Row,G), member(r,Row)), Orig),
    findall(1, (member(Row,E), member(r,Row)), Ero),
    length(Orig, NO), length(Ero, NE),
    NE < NO.

test(hot_spots_subset_of_grid, []) :-
    g3x3_rb(G),
    gridconv_hot_spots(G, 1, r, 1, Cells),
    % g3x3_rb: r cells at (0,0),(0,1),(1,0),(1,1); all 9 cells see at least 1 r
    % in their N=1 window (each cell's 3x3 window shares at least one r)
    length(Cells, 9).

:- end_tests(gridconv).
