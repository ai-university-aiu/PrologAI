:- use_module('../prolog/wavefront').
:- begin_tests(wavefront).

% g1: 3x3 grid with walls at r(0,1) and r(2,1).
% Passable (0) cells: r(0,0) r(0,2) r(1,0) r(1,1) r(1,2) r(2,0) r(2,2).
% The wave from r(0,0) must go around both walls.
g1([[0,1,0],[0,0,0],[0,1,0]]).

% g2: 2x2 fully open grid. BFS from r(0,0) reaches all 4 cells.
g2([[0,0],[0,0]]).

% g3: 4x4 grid with an enclosed 2x2 pocket at center.
% Border passable cells: r(0,0) r(0,3) r(3,0) r(3,3) only.
% Inner passable cells: r(1,1) r(1,2) r(2,1) r(2,2) — enclosed.
g3([[0,1,1,0],[1,0,0,1],[1,0,0,1],[0,1,1,0]]).

% g4: 3x3 fully open grid. Used for multi-wave and collision tests.
g4([[0,0,0],[0,0,0],[0,0,0]]).

% g_split: grid split into two isolated regions by a solid wall.
% r(0,0) region: {r(0,0)}.
% Unreachable: {r(0,2), r(2,0), r(2,1), r(2,2)}.
g_split([[0,1,0],[1,1,1],[0,0,0]]).

% bfs result for g1 from r(0,0) — precomputed for multiple tests.
bfs_g1(DP) :-
    g1(G), wavefront_bfs(G, [r(0,0)], 0, DP).

% wavefront_passable tests.

test(passable_g1_count) :-
    g1(G), wavefront_passable(G, 0, Cells), length(Cells, 7).

test(passable_g1_contains_r00) :-
    g1(G), wavefront_passable(G, 0, Cells), memberchk(r(0,0), Cells).

test(passable_g1_no_wall) :-
    g1(G), wavefront_passable(G, 0, Cells), \+ memberchk(r(0,1), Cells).

test(passable_g2_all_four) :-
    g2(G), wavefront_passable(G, 0, Cells),
    sort([r(0,0),r(0,1),r(1,0),r(1,1)], Expected),
    Cells == Expected.

% wavefront_bfs tests.

test(bfs_seed_at_zero) :-
    bfs_g1(DP), memberchk(0-r(0,0), DP).

test(bfs_g1_total_entries) :-
    bfs_g1(DP), length(DP, 7).

test(bfs_g1_dist1) :-
    bfs_g1(DP), memberchk(1-r(1,0), DP).

test(bfs_g1_dist2_r11) :-
    bfs_g1(DP), memberchk(2-r(1,1), DP).

test(bfs_g1_dist2_r20) :-
    bfs_g1(DP), memberchk(2-r(2,0), DP).

test(bfs_g1_dist3_r12) :-
    bfs_g1(DP), memberchk(3-r(1,2), DP).

test(bfs_g1_dist4_r02) :-
    bfs_g1(DP), memberchk(4-r(0,2), DP).

test(bfs_g1_dist4_r22) :-
    bfs_g1(DP), memberchk(4-r(2,2), DP).

test(bfs_g2_four_entries) :-
    g2(G), wavefront_bfs(G, [r(0,0)], 0, DP), length(DP, 4).

% wavefront_reachable and wavefront_unreachable tests.

test(reachable_g2_all) :-
    g2(G), wavefront_reachable(G, [r(0,0)], 0, Cells),
    sort([r(0,0),r(0,1),r(1,0),r(1,1)], Expected),
    Cells == Expected.

test(reachable_g1_count) :-
    g1(G), wavefront_reachable(G, [r(0,0)], 0, Cells), length(Cells, 7).

test(unreachable_g2_empty) :-
    g2(G), wavefront_unreachable(G, [r(0,0)], 0, U), U == [].

test(unreachable_split_nonempty) :-
    g_split(G), wavefront_unreachable(G, [r(0,0)], 0, U),
    sort([r(0,2),r(2,0),r(2,1),r(2,2)], Expected),
    U == Expected.

% wavefront_at_dist and wavefront_within_dist tests.

test(at_dist_0_is_seed) :-
    bfs_g1(DP), wavefront_at_dist(DP, 0, Cells), Cells == [r(0,0)].

test(at_dist_1) :-
    bfs_g1(DP), wavefront_at_dist(DP, 1, Cells), Cells == [r(1,0)].

test(at_dist_2_count) :-
    bfs_g1(DP), wavefront_at_dist(DP, 2, Cells), length(Cells, 2).

test(within_dist_2_count) :-
    bfs_g1(DP), wavefront_within_dist(DP, 2, Cells), length(Cells, 4).

test(within_dist_0_is_seed) :-
    bfs_g1(DP), wavefront_within_dist(DP, 0, Cells), Cells == [r(0,0)].

% wavefront_dist_of, wavefront_max_dist, wavefront_all_dists tests.

test(dist_of_seed) :-
    bfs_g1(DP), wavefront_dist_of(DP, r(0,0), D), D == 0.

test(dist_of_r12) :-
    bfs_g1(DP), wavefront_dist_of(DP, r(1,2), D), D == 3.

test(dist_of_r02) :-
    bfs_g1(DP), wavefront_dist_of(DP, r(0,2), D), D == 4.

test(max_dist_g1) :-
    bfs_g1(DP), wavefront_max_dist(DP, MaxD), MaxD == 4.

test(max_dist_g2) :-
    g2(G), wavefront_bfs(G, [r(0,0)], 0, DP), wavefront_max_dist(DP, MaxD), MaxD == 2.

test(all_dists_g1) :-
    bfs_g1(DP), wavefront_all_dists(DP, Ds), Ds == [0,1,2,3,4].

% wavefront_path_exists tests.

test(path_exists_yes) :-
    g1(G), wavefront_path_exists(G, r(0,0), r(0,2), 0).

test(path_exists_self) :-
    g1(G), wavefront_path_exists(G, r(0,0), r(0,0), 0).

test(path_not_exists) :-
    g_split(G), \+ wavefront_path_exists(G, r(0,0), r(2,0), 0).

% wavefront_paint_bg tests.

test(paint_bg_g2) :-
    g2(G),
    wavefront_paint_bg(G, [r(0,0)], 0, 9, Painted),
    Painted == [[0,1],[1,2]].

test(paint_bg_cap) :-
    g2(G),
    wavefront_paint_bg(G, [r(0,0)], 0, 1, Painted),
    Painted == [[0,1],[1,1]].

% wavefront_multi_wave tests.

test(multi_wave_a_wins_r00) :-
    g4(G),
    wavefront_multi_wave(G, [a-[r(0,0)], b-[r(0,2)]], 0, Painted),
    nth0(0, Painted, Row0), nth0(0, Row0, V), V == a.

test(multi_wave_b_wins_r02) :-
    g4(G),
    wavefront_multi_wave(G, [a-[r(0,0)], b-[r(0,2)]], 0, Painted),
    nth0(0, Painted, Row0), nth0(2, Row0, V), V == b.

test(multi_wave_a_wins_r10) :-
    g4(G),
    wavefront_multi_wave(G, [a-[r(0,0)], b-[r(0,2)]], 0, Painted),
    nth0(1, Painted, Row1), nth0(0, Row1, V), V == a.

% wavefront_collision tests.

test(collision_middle_col) :-
    g4(G),
    wavefront_collision(G, [a-[r(0,0)], b-[r(0,2)]], 0, Cells),
    sort([r(0,1),r(1,1),r(2,1)], Expected),
    Cells == Expected.

test(collision_empty_single_seed) :-
    g4(G),
    wavefront_collision(G, [a-[r(0,0)]], 0, Cells),
    Cells == [].

% wavefront_enclosed tests.

test(enclosed_inner_pocket) :-
    g3(G),
    wavefront_enclosed(G, 0, Cells),
    sort([r(1,1),r(1,2),r(2,1),r(2,2)], Expected),
    Cells == Expected.

test(enclosed_none_open_grid) :-
    g4(G), wavefront_enclosed(G, 0, Cells), Cells == [].

test(enclosed_fully_surrounded) :-
    G = [[1,1,1],[1,0,1],[1,1,1]],
    wavefront_enclosed(G, 0, Cells), Cells == [r(1,1)].

:- end_tests(wavefront).
