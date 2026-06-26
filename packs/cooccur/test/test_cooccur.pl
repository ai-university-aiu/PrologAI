% test_cooccur.pl - 42 PLUnit tests for the cooccur pack (co_* predicates).
:- use_module('../prolog/cooccur.pl').

% Shared test grids.
% G3: 3x3 sequential grid with values 1-9 (all distinct).
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G2c: 2x2 checkerboard of values 1 and 2.
% H pairs: [1-2, 2-1]. V pairs: [1-2, 2-1]. DR diagonal: [1-1]. DL diagonal: [2-2].
g2c([[1,2],[2,1]]).
% G3c: 3x3 grid with value 2 at the center and 1 everywhere else.
% Center (1,1) has four 1-neighbors. All 1 cells at corners/edges.
g3c([[1,1,1],[1,2,1],[1,1,1]]).

% Tests for co_h_pairs/2.
:- begin_tests(co_h_pairs).
test(h_pairs_g3) :- g3(G), co_h_pairs(G, P),
    P = [1-2,2-3,4-5,5-6,7-8,8-9].
test(h_pairs_g2c) :- g2c(G), co_h_pairs(G, P), P = [1-2,2-1].
test(h_pairs_g3c) :- g3c(G), co_h_pairs(G, P),
    P = [1-1,1-1,1-2,2-1,1-1,1-1].
:- end_tests(co_h_pairs).

% Tests for co_v_pairs/2.
:- begin_tests(co_v_pairs).
test(v_pairs_g3) :- g3(G), co_v_pairs(G, P),
    P = [1-4,4-7,2-5,5-8,3-6,6-9].
test(v_pairs_g2c) :- g2c(G), co_v_pairs(G, P), P = [1-2,2-1].
test(v_pairs_g3c) :- g3c(G), co_v_pairs(G, P),
    P = [1-1,1-1,1-2,2-1,1-1,1-1].
:- end_tests(co_v_pairs).

% Tests for co_d_pairs_dr/2.
% G3: (0,0)->(1,1)=1-5, (0,1)->(1,2)=2-6, (1,0)->(2,1)=4-8, (1,1)->(2,2)=5-9.
% G2c: (0,0)->(1,1)=1-1.
% G3c: (0,0)->(1,1)=1-2, (0,1)->(1,2)=1-1, (1,0)->(2,1)=1-1, (1,1)->(2,2)=2-1.
:- begin_tests(co_d_pairs_dr).
test(dr_g3) :- g3(G), co_d_pairs_dr(G, P), P = [1-5,2-6,4-8,5-9].
test(dr_g2c) :- g2c(G), co_d_pairs_dr(G, P), P = [1-1].
test(dr_g3c) :- g3c(G), co_d_pairs_dr(G, P), P = [1-2,1-1,1-1,2-1].
:- end_tests(co_d_pairs_dr).

% Tests for co_d_pairs_dl/2.
% G3: (0,1)->(1,0)=2-4, (0,2)->(1,1)=3-5, (1,1)->(2,0)=5-7, (1,2)->(2,1)=6-8.
% G2c: (0,1)->(1,0)=2-2.
% G3c: (0,1)->(1,0)=1-1, (0,2)->(1,1)=1-2, (1,1)->(2,0)=2-1, (1,2)->(2,1)=1-1.
:- begin_tests(co_d_pairs_dl).
test(dl_g3) :- g3(G), co_d_pairs_dl(G, P), P = [2-4,3-5,5-7,6-8].
test(dl_g2c) :- g2c(G), co_d_pairs_dl(G, P), P = [2-2].
test(dl_g3c) :- g3c(G), co_d_pairs_dl(G, P), P = [1-1,1-2,2-1,1-1].
:- end_tests(co_d_pairs_dl).

% Tests for co_count_h/4.
:- begin_tests(co_count_h).
test(count_h_g3_12) :- g3(G), co_count_h(G, 1, 2, N), N =:= 1.
test(count_h_g2c_12) :- g2c(G), co_count_h(G, 1, 2, N), N =:= 1.
test(count_h_g3c_11) :- g3c(G), co_count_h(G, 1, 1, N), N =:= 4.
:- end_tests(co_count_h).

% Tests for co_count_v/4.
:- begin_tests(co_count_v).
test(count_v_g3_14) :- g3(G), co_count_v(G, 1, 4, N), N =:= 1.
test(count_v_g2c_12) :- g2c(G), co_count_v(G, 1, 2, N), N =:= 1.
test(count_v_g3c_12) :- g3c(G), co_count_v(G, 1, 2, N), N =:= 1.
:- end_tests(co_count_v).

% Tests for co_count_adj4/4.
% G2c: co_count_adj4(g2c,1,2,N): h has 1-2(1)+2-1(1)=2; v has 1-2(1)+2-1(1)=2 => N=4.
% G3c: co_count_adj4(g3c,1,2,N): h has 1-2(1)+2-1(1)=2; v has 1-2(1)+2-1(1)=2 => N=4.
% G3c: co_count_adj4(g3c,1,1,N): h has 1-1(4); v has 1-1(4) => N=8.
:- begin_tests(co_count_adj4).
test(adj4_g2c_12) :- g2c(G), co_count_adj4(G, 1, 2, N), N =:= 4.
test(adj4_g3c_12) :- g3c(G), co_count_adj4(G, 1, 2, N), N =:= 4.
test(adj4_g3c_11) :- g3c(G), co_count_adj4(G, 1, 1, N), N =:= 8.
:- end_tests(co_count_adj4).

% Tests for co_always_adj4/3.
% G3c: 2 is at (1,1), all 4 neighbors are 1 => co_always_adj4(g3c,2,1) true.
% G3c: 1 cells at corners have no 2-neighbor => co_always_adj4(g3c,1,2) fails.
% G2c: each 1 cell has 2 neighbors => co_always_adj4(g2c,1,2) true.
:- begin_tests(co_always_adj4).
test(always_g3c_2to1) :- g3c(G), co_always_adj4(G, 2, 1).
test(always_g2c_1to2) :- g2c(G), co_always_adj4(G, 1, 2).
test(always_g3c_1to2_fails) :- g3c(G), \+ co_always_adj4(G, 1, 2).
:- end_tests(co_always_adj4).

% Tests for co_never_adj4/3.
% G3c: 2-2 never adjacent (only one 2 cell) => co_never_adj4(g3c,2,2) true.
% G3: 1 and 9 never adjacent (opposite corners) => co_never_adj4(g3,1,9) true.
% G3c: 1-2 adjacent => co_never_adj4(g3c,1,2) fails.
:- begin_tests(co_never_adj4).
test(never_g3c_22) :- g3c(G), co_never_adj4(G, 2, 2).
test(never_g3_19) :- g3(G), co_never_adj4(G, 1, 9).
test(never_g3c_12_fails) :- g3c(G), \+ co_never_adj4(G, 1, 2).
:- end_tests(co_never_adj4).

% Tests for co_isolated4/3.
% G3c: 2 at (1,1) has no 2-neighbor => [1-1].
% G3c: all 1 cells have 1-neighbors => [].
% G3: all cells are distinct values, so every cell is isolated from itself => [0-0] for V=1.
:- begin_tests(co_isolated4).
test(isolated_g3c_2) :- g3c(G), co_isolated4(G, 2, C), C = [1-1].
test(isolated_g3c_1) :- g3c(G), co_isolated4(G, 1, C), C = [].
test(isolated_g3_1) :- g3(G), co_isolated4(G, 1, C), C = [0-0].
:- end_tests(co_isolated4).

% Tests for co_border_vals/3.
% G3c: 2 borders only 1 => [1].
% G3c: 1 borders only 2 => [2].
% G3: 5 (center) neighbors 2,4,6,8 => [2,4,6,8].
:- begin_tests(co_border_vals).
test(border_g3c_2) :- g3c(G), co_border_vals(G, 2, V), V = [1].
test(border_g3c_1) :- g3c(G), co_border_vals(G, 1, V), V = [2].
test(border_g3_5) :- g3(G), co_border_vals(G, 5, V), V = [2,4,6,8].
:- end_tests(co_border_vals).

% Tests for co_shared_border/3.
% G3c: 1-2 share a border => true.
% G3c: 2-2 share no border => fails.
% G3: 1-5 do not share a border (not adjacent) => fails.
:- begin_tests(co_shared_border).
test(shared_g3c_12) :- g3c(G), co_shared_border(G, 1, 2).
test(shared_g3c_22_fails) :- g3c(G), \+ co_shared_border(G, 2, 2).
test(shared_g3_15_fails) :- g3(G), \+ co_shared_border(G, 1, 5).
:- end_tests(co_shared_border).

% Tests for co_row_transitions/2.
% G2c: h_pairs=[1-2, 2-1], each once. Sorted desc by count: tied at 1.
%      msort([1-1-2, 1-2-1]) = [1-1-2, 1-2-1], reverse = [1-2-1, 1-1-2].
%      Triples = [2-1-1, 1-2-1].
% G3c: 1-1 appears 4 times, 1-2 and 2-1 each once.
%      Triples = [1-1-4, 2-1-1, 1-2-1].
% G3: all h pairs are distinct, each appears once.
%      Sorted descending: all tied at N=1. msort by A then B after N tie.
%      msort([1-1-2, 1-2-3, 1-4-5, 1-5-6, 1-7-8, 1-8-9])=[1-1-2,..,1-8-9].
%      reverse=[1-8-9,..,1-1-2]. Triples=[8-9-1,7-8-1,5-6-1,4-5-1,2-3-1,1-2-1].
:- begin_tests(co_row_transitions).
test(rtrans_g2c) :- g2c(G), co_row_transitions(G, T), T = [2-1-1,1-2-1].
test(rtrans_g3c) :- g3c(G), co_row_transitions(G, T), T = [1-1-4,2-1-1,1-2-1].
test(rtrans_g3) :- g3(G), co_row_transitions(G, T),
    T = [8-9-1,7-8-1,5-6-1,4-5-1,2-3-1,1-2-1].
:- end_tests(co_row_transitions).

% Tests for co_most_common_adj4/3.
% G3c: most common adj4 of 1 is 2 (4 edges, the only other value).
%      most common adj4 of 2 is 1 (4 edges, the only adjacent value).
% G3: most common adj4 of 5 (center): neighbors 2,4,6,8 each with count 1.
%      Tied at 1; last in msort by value => W=8.
:- begin_tests(co_most_common_adj4).
test(most_g3c_1) :- g3c(G), co_most_common_adj4(G, 1, W), W =:= 2.
test(most_g3c_2) :- g3c(G), co_most_common_adj4(G, 2, W), W =:= 1.
test(most_g3_5) :- g3(G), co_most_common_adj4(G, 5, W), W =:= 8.
:- end_tests(co_most_common_adj4).
