:- use_module('../prolog/periodfix.pl').

% Test data.
% L6_p2: [a,b,a,b,a,b] — period 2, no violations.
l6_p2([a,b,a,b,a,b]).
% L6_p3: [a,b,c,a,b,c] — period 3, no violations.
l6_p3([a,b,c,a,b,c]).
% L6_p3_v1: [a,b,c,a,x,c] — period 3, one violation at index 4 (x should be b).
l6_p3_v1([a,b,c,a,x,c]).
% L4_p2_v2: [a,b,a,c] — period 2, one violation at index 3 (c should be b).
l4_p2_v2([a,b,a,c]).
% L6_p1: [a,a,a,a,a,a] — period 1, no violations.
l6_p1([a,a,a,a,a,a]).
% G44_p2: 4x4 grid with row period 2 and col period 2.
g44_p2([[a,b,a,b],[c,d,c,d],[a,b,a,b],[c,d,c,d]]).
% G44_p2_v1: same grid but one corruption at (1,2): d->x.
g44_p2_v1([[a,b,a,b],[c,d,x,d],[a,b,a,b],[c,d,c,d]]).
% G33_p1: trivial 3x3 all-same grid, period (1,1).
g33_p1([[z,z,z],[z,z,z],[z,z,z]]).
% G32_p2: 3-row 4-col grid, col period 2, row period 3.
g32_p2([[a,b,a,b],[c,d,c,d],[e,f,e,f]]).

:- begin_tests(periodfix).

% --- ppf_list_period ---

% AC-PPF-001: exact period 2 detected for l6_p2.
test(list_period_2) :-
    l6_p2(L), ppf_list_period(L, P), P = 2.

% AC-PPF-002: exact period 3 detected for l6_p3.
test(list_period_3) :-
    l6_p3(L), ppf_list_period(L, P), P = 3.

% AC-PPF-003: period 1 detected for uniform list.
test(list_period_1) :-
    l6_p1(L), ppf_list_period(L, P), P = 1.

% AC-PPF-004: a list with one violation has no exact period less than its length.
test(list_period_violation, [fail]) :-
    l6_p3_v1(L), ppf_list_period(L, P), P < 6.

% --- ppf_majority ---

% AC-PPF-005: majority of [a,a,b] is a.
test(majority_simple) :-
    ppf_majority([a,a,b], a).

% AC-PPF-006: majority of a singleton is that element.
test(majority_singleton) :-
    ppf_majority([x], x).

% AC-PPF-007: majority of [a,b,a,b,a] is a (3 vs 2).
test(majority_tie_breaking) :-
    ppf_majority([a,b,a,b,a], a).

% --- ppf_tile_from_list ---

% AC-PPF-008: majority tile from l6_p2 with P=2 is [a,b].
test(tile_from_list_p2) :-
    l6_p2(L), ppf_tile_from_list(L, 2, T), T = [a,b].

% AC-PPF-009: majority tile from l6_p3_v1 with P=3 is [a,b,c].
% Phase 0: [a,a] -> a. Phase 1: [b,x] -> depends on order; x!=b so one of them.
% Actually phase 1 values: index 1 (b), index 4 (x). Majority = first-appearing in mode.
% Let's use P=3: phase 0 -> [a,a], phase 1 -> [b,x], phase 2 -> [c,c].
% majority([b,x]) = b (b appears once, x once; first encountered b since sort [b,x]).
test(tile_from_list_corrupted) :-
    l6_p3_v1(L), ppf_tile_from_list(L, 3, T), T = [a,b,c].

% AC-PPF-010: tile with P=1 from [a,a,b,a] is [a] (majority is a, 3 vs 1).
test(tile_from_list_p1) :-
    ppf_tile_from_list([a,a,b,a], 1, T), T = [a].

% --- ppf_violations_list ---

% AC-PPF-011: no violations for exact period list.
test(violations_list_none) :-
    l6_p2(L), ppf_tile_from_list(L, 2, T),
    ppf_violations_list(L, 2, T, V), V = [].

% AC-PPF-012: one violation for l6_p3_v1 with P=3 and tile [a,b,c].
test(violations_list_one) :-
    l6_p3_v1(L), ppf_tile_from_list(L, 3, T),
    ppf_violations_list(L, 3, T, V), V = [viol(4, x, b)].

% AC-PPF-013: one violation in l4_p2_v2 at index 3.
test(violations_list_l4) :-
    l4_p2_v2(L), ppf_tile_from_list(L, 2, T),
    ppf_violations_list(L, 2, T, V), V = [viol(3, c, b)].

% --- ppf_repair_list ---

% AC-PPF-014: repairing l6_p3_v1 with P=3 yields [a,b,c,a,b,c].
test(repair_list) :-
    l6_p3_v1(L), ppf_tile_from_list(L, 3, T),
    ppf_repair_list(L, 3, T, R), R = [a,b,c,a,b,c].

% AC-PPF-015: repairing l4_p2_v2 with P=2 yields [a,b,a,b].
test(repair_list_l4) :-
    l4_p2_v2(L), ppf_tile_from_list(L, 2, T),
    ppf_repair_list(L, 2, T, R), R = [a,b,a,b].

% --- ppf_best_period_list ---

% AC-PPF-016: best period for l6_p2 is 1 or 2 with 0 violations.
% (Period 1 also has 0 violations if all same value; l6_p2 has a,b so P=1 has violations)
test(best_period_l6p2) :-
    l6_p2(L), ppf_best_period_list(L, P, NV), NV = 0, P = 2.

% AC-PPF-017: best period for l6_p3_v1 is 3 with 1 violation.
test(best_period_l6p3v1) :-
    l6_p3_v1(L), ppf_best_period_list(L, P, NV), P = 3, NV = 1.

% --- ppf_tile_2d ---

% AC-PPF-018: 2D tile (PH=2, PW=2) from g44_p2 is [[a,b],[c,d]].
test(tile_2d_basic) :-
    g44_p2(G), ppf_tile_2d(G, 2, 2, T),
    T = [[a,b],[c,d]].

% AC-PPF-019: 2D tile (PH=1, PW=1) from g33_p1 is [[z]].
test(tile_2d_trivial) :-
    g33_p1(G), ppf_tile_2d(G, 1, 1, T), T = [[z]].

% --- ppf_violations_2d ---

% AC-PPF-020: no violations in g44_p2 with tile [[a,b],[c,d]].
test(violations_2d_none) :-
    g44_p2(G), ppf_tile_2d(G, 2, 2, Tile),
    ppf_violations_2d(G, Tile, 2, 2, V), V = [].

% AC-PPF-021: one violation in g44_p2_v1 at (1,2): x should be c (tile[1 mod 2=1][2 mod 2=0]=c).
test(violations_2d_one) :-
    g44_p2_v1(G), ppf_tile_2d(G, 2, 2, Tile),
    ppf_violations_2d(G, Tile, 2, 2, V),
    V = [viol(1, 2, x, c)].

% --- ppf_repair_grid ---

% AC-PPF-022: repairing g44_p2_v1 gives g44_p2.
test(repair_grid) :-
    g44_p2_v1(G), g44_p2(Expected),
    ppf_tile_2d(G, 2, 2, Tile),
    ppf_repair_grid(G, Tile, 2, 2, R), R = Expected.

% --- ppf_best_periods ---

% AC-PPF-023: best periods for g44_p2_v1 are (2,2) with 1 violation.
test(best_periods) :-
    g44_p2_v1(G), ppf_best_periods(G, PH, PW), PH = 2, PW = 2.

% --- ppf_single_violation_list ---

% AC-PPF-024: l6_p3_v1 has exactly one violation with P=3.
test(single_viol_list) :-
    l6_p3_v1(L), ppf_tile_from_list(L, 3, T),
    ppf_single_violation_list(L, 3, T, viol(4, x, b)).

% AC-PPF-025: l6_p2 has no violation so single_violation_list fails.
test(single_viol_list_fail, [fail]) :-
    l6_p2(L), ppf_tile_from_list(L, 2, T),
    ppf_single_violation_list(L, 2, T, _).

% --- ppf_repair_single_list ---

% AC-PPF-026: repair_single_list on l6_p3_v1 gives [a,b,c,a,b,c].
test(repair_single_list) :-
    l6_p3_v1(L), ppf_tile_from_list(L, 3, T),
    ppf_repair_single_list(L, 3, T, R), R = [a,b,c,a,b,c].

% --- ppf_single_violation_2d ---

% AC-PPF-027: g44_p2_v1 has exactly one 2D violation (x should be c).
test(single_viol_2d) :-
    g44_p2_v1(G), ppf_tile_2d(G, 2, 2, Tile),
    ppf_single_violation_2d(G, Tile, 2, 2, viol(1, 2, x, c)).

% --- ppf_repair_single_grid ---

% AC-PPF-028: repair_single_grid on g44_p2_v1 gives g44_p2.
test(repair_single_grid) :-
    g44_p2_v1(G), g44_p2(Expected),
    ppf_tile_2d(G, 2, 2, Tile),
    ppf_repair_single_grid(G, Tile, 2, 2, R), R = Expected.

% AC-PPF-029: repair_single_grid fails for g44_p2 (0 violations, not exactly 1).
test(repair_single_grid_fail, [fail]) :-
    g44_p2(G), ppf_tile_2d(G, 2, 2, Tile),
    ppf_repair_single_grid(G, Tile, 2, 2, _).

% AC-PPF-030: tile from [1,3,1,3,1,3,3,3,1] with P=2 is [1,3].
% This models the inner row of ARC-AGI-2 task frame window with period 2.
test(tile_from_arc_row) :-
    ppf_tile_from_list([1,3,1,3,1,3,3,3,1], 2, T), T = [1,3].

:- end_tests(periodfix).
