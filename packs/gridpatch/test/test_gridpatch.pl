:- use_module('../prolog/gridpatch').

% Test grids used throughout.
% base4: 4x4 all-b grid.
% base3: 3x3 all-b grid.
% checker: 4x4 checkerboard x/b.
% stripe: 4x4 vertical stripes x/b/x/b per row.
% p2x2: 2x2 patch [[x,x],[x,x]].
% p1x1: 1x1 patch [[m]].
% p2x2b: 2x2 patch [[b,b],[b,b]] (all background).

base4([[b,b,b,b],[b,b,b,b],[b,b,b,b],[b,b,b,b]]).
base3([[b,b,b],[b,b,b],[b,b,b]]).
checker([[x,b,x,b],[b,x,b,x],[x,b,x,b],[b,x,b,x]]).
stripe([[x,b,x,b],[x,b,x,b],[x,b,x,b],[x,b,x,b]]).
p2x2([[x,x],[x,x]]).
p1x1([[m]]).
p2x2b([[b,b],[b,b]]).

:- begin_tests(gridpatch_extract).

% AC-GPT-001: extract 2x2 from top-left of checker.
test(extract_topleft) :-
    checker(G), gridpatch_extract(G, 0, 0, 1, 1, P),
    P = [[x,b],[b,x]].

% AC-GPT-002: extract single cell (2,3).
test(extract_single) :-
    checker(G), gridpatch_extract(G, 2, 3, 2, 3, P),
    P = [[b]].

% AC-GPT-003: extract bottom-right 2x2 from checker.
test(extract_bottomright) :-
    checker(G), gridpatch_extract(G, 2, 2, 3, 3, P),
    P = [[x,b],[b,x]].

:- end_tests(gridpatch_extract).

:- begin_tests(gridpatch_place).

% AC-GPT-004: place 2x2 all-x at (1,1) in base4.
test(place_2x2_center) :-
    base4(G), p2x2(P),
    gridpatch_place(G, P, 1, 1, R),
    R = [[b,b,b,b],[b,x,x,b],[b,x,x,b],[b,b,b,b]].

% AC-GPT-005: place 1x1 at (0,0).
test(place_1x1_origin) :-
    base3(G), p1x1(P),
    gridpatch_place(G, P, 0, 0, R),
    nth0(0, R, Row0), nth0(0, Row0, m).

% AC-GPT-006: place at position that extends exactly to edge.
test(place_at_edge) :-
    base4(G), p2x2(P),
    gridpatch_place(G, P, 2, 2, R),
    R = [[b,b,b,b],[b,b,b,b],[b,b,x,x],[b,b,x,x]].

:- end_tests(gridpatch_place).

:- begin_tests(gridpatch_overlay).

% AC-GPT-007: overlay with TranspColor = b: b cells in patch are transparent.
test(overlay_transparent_b) :-
    checker(G),
    Patch = [[b,m],[m,b]],
    gridpatch_overlay(G, Patch, 0, 0, b, R),
    % (0,0): Patch=b→keep checker x; (0,1): Patch=m→m; (1,0): Patch=m→m; (1,1): Patch=b→keep checker x
    nth0(0, R, R0), R0 = [x,m|_],
    nth0(1, R, R1), nth0(0, R1, m), nth0(1, R1, x).

% AC-GPT-008: overlay with no transparent cells = same as gridpatch_place.
test(overlay_no_transparency) :-
    base4(G), p2x2(P),
    gridpatch_overlay(G, P, 1, 1, z, R1),
    gridpatch_place(G, P, 1, 1, R2),
    R1 = R2.

% AC-GPT-009: overlay all-transparent patch leaves grid unchanged.
test(overlay_all_transparent) :-
    checker(G),
    Patch = [[b,b],[b,b]],
    gridpatch_overlay(G, Patch, 0, 0, b, R),
    nth0(0, R, Row0), Row0 = [x,b|_].

:- end_tests(gridpatch_overlay).

:- begin_tests(gridpatch_match_at).

% AC-GPT-010: [[x,b],[b,x]] matches checker at (0,0).
test(match_checker_00) :-
    checker(G), gridpatch_match_at(G, [[x,b],[b,x]], 0, 0).

% AC-GPT-011: [[b,x],[x,b]] matches checker at (0,1).
test(match_checker_01) :-
    checker(G), gridpatch_match_at(G, [[b,x],[x,b]], 0, 1).

% AC-GPT-012: all-x patch does NOT match checker at (0,0).
test(match_fail) :-
    checker(G), \+ gridpatch_match_at(G, [[x,x],[x,x]], 0, 0).

:- end_tests(gridpatch_match_at).

:- begin_tests(gridpatch_find_all).

% AC-GPT-013: find all [[x,b],[b,x]] in checker: 5 positions.
test(find_all_checker) :-
    checker(G),
    gridpatch_find_all(G, [[x,b],[b,x]], Pos),
    length(Pos, 5).

% AC-GPT-014: find [[b,b],[b,b]] in base4: 9 positions (3x3 possible offsets).
test(find_all_bg_in_base4) :-
    base4(G), p2x2b(P),
    gridpatch_find_all(G, P, Pos),
    length(Pos, 9).

% AC-GPT-015: no match returns empty list.
test(find_all_none) :-
    base4(G),
    gridpatch_find_all(G, [[m,m],[m,m]], Pos),
    Pos = [].

:- end_tests(gridpatch_find_all).

:- begin_tests(gridpatch_count).

% AC-GPT-016: 5 occurrences of [[x,b],[b,x]] in checker.
test(count_checker) :-
    checker(G),
    gridpatch_count(G, [[x,b],[b,x]], N), N =:= 5.

% AC-GPT-017: zero occurrences of all-m patch in base4.
test(count_zero) :-
    base4(G), gridpatch_count(G, [[m,m],[m,m]], N), N =:= 0.

:- end_tests(gridpatch_count).

:- begin_tests(gridpatch_scatter).

% AC-GPT-018: scatter 1x1 [[m]] at [(0,0),(2,2)] in base4.
test(scatter_two) :-
    base4(G), p1x1(P),
    gridpatch_scatter(G, P, [0-0, 2-2], R),
    nth0(0, R, R0), nth0(0, R0, m),
    nth0(2, R, R2), nth0(2, R2, m).

% AC-GPT-019: scatter with empty list leaves grid unchanged.
test(scatter_empty) :-
    checker(G), gridpatch_scatter(G, [[m]], [], R), R = G.

% AC-GPT-020: scatter same position twice uses last placement.
test(scatter_same_twice) :-
    base4(G), p1x1(P),
    gridpatch_scatter(G, P, [1-1, 1-1], R),
    nth0(1, R, Row), nth0(1, Row, m).

:- end_tests(gridpatch_scatter).

:- begin_tests(gridpatch_tile_fill).

% AC-GPT-021: tile [[x,b],[b,x]] to 4x4 = checker.
test(tile_fill_4x4) :-
    gridpatch_tile_fill([[x,b],[b,x]], 4, 4, G),
    checker(G).

% AC-GPT-022: tile [[x]] to 3x3 = all-x.
test(tile_fill_1x1) :-
    gridpatch_tile_fill([[x]], 3, 3, G),
    G = [[x,x,x],[x,x,x],[x,x,x]].

% AC-GPT-023: tile 1x2 [[a,b]] to 2x4.
test(tile_fill_1x2) :-
    gridpatch_tile_fill([[a,b]], 2, 4, G),
    G = [[a,b,a,b],[a,b,a,b]].

:- end_tests(gridpatch_tile_fill).

:- begin_tests(gridpatch_h).

% AC-GPT-024: height of 2x2 patch.
test(h_2x2) :- p2x2(P), gridpatch_h(P, H), H =:= 2.

% AC-GPT-025: height of 1x1 patch.
test(h_1x1) :- p1x1(P), gridpatch_h(P, H), H =:= 1.

:- end_tests(gridpatch_h).

:- begin_tests(gridpatch_w).

% AC-GPT-026: width of 2x2 patch.
test(w_2x2) :- p2x2(P), gridpatch_w(P, W), W =:= 2.

% AC-GPT-027: width of 4x4 checker.
test(w_4x4) :- checker(G), gridpatch_w(G, W), W =:= 4.

:- end_tests(gridpatch_w).

:- begin_tests(gridpatch_size).

% AC-GPT-028: size of 2x2 patch.
test(size_2x2) :- p2x2(P), gridpatch_size(P, H, W), H =:= 2, W =:= 2.

% AC-GPT-029: size of 4x4 checker.
test(size_4x4) :- checker(G), gridpatch_size(G, H, W), H =:= 4, W =:= 4.

:- end_tests(gridpatch_size).

:- begin_tests(gridpatch_eq).

% AC-GPT-030: two equal patches unify.
test(eq_same) :- p2x2(P), gridpatch_eq(P, P).

% AC-GPT-031: different patches fail.
test(eq_diff) :- p2x2(P), p2x2b(Q), \+ gridpatch_eq(P, Q).

:- end_tests(gridpatch_eq).

:- begin_tests(gridpatch_inpaint).

% AC-GPT-032: inpaint 2x2 block at (1,1) with m in base4.
test(inpaint_block) :-
    base4(G),
    gridpatch_inpaint(G, 1, 1, 2, 2, m, R),
    R = [[b,b,b,b],[b,m,m,b],[b,m,m,b],[b,b,b,b]].

% AC-GPT-033: inpaint entire grid with x.
test(inpaint_full) :-
    base3(G),
    gridpatch_inpaint(G, 0, 0, 2, 2, x, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% AC-GPT-034: inpaint single cell.
test(inpaint_single) :-
    checker(G),
    gridpatch_inpaint(G, 0, 0, 0, 0, z, R),
    nth0(0, R, Row0), nth0(0, Row0, z),
    nth0(0, R, Row0b), nth0(1, Row0b, b).

:- end_tests(gridpatch_inpaint).

:- begin_tests(gridpatch_replace_first).

% AC-GPT-035: replace first [[x,b],[b,x]] in checker with [[m,m],[m,m]].
test(replace_first_checker) :-
    checker(G),
    gridpatch_replace_first(G, [[x,b],[b,x]], [[m,m],[m,m]], R),
    nth0(0, R, Row0), Row0 = [m,m,x,b].

% AC-GPT-036: replace first occurrence in striped grid.
test(replace_first_stripe) :-
    stripe(G),
    gridpatch_replace_first(G, [[x,b],[x,b]], [[a,a],[a,a]], R),
    nth0(0, R, Row0), Row0 = [a,a,x,b].

% AC-GPT-037: replace_first fails when no match.
test(replace_first_nomatch) :-
    base4(G),
    \+ gridpatch_replace_first(G, [[m,m]], _, _).

:- end_tests(gridpatch_replace_first).

:- begin_tests(gpt_combined).

% AC-GPT-038: extract then place recovers original region.
test(extract_then_place) :-
    checker(G),
    gridpatch_extract(G, 0, 0, 1, 1, Patch),
    base4(Blank),
    gridpatch_place(Blank, Patch, 0, 0, R),
    nth0(0, R, R0), R0 = [x,b|_],
    nth0(1, R, R1), nth0(0, R1, b), nth0(1, R1, x).

% AC-GPT-039: tile then find_all finds 5 positions of 2x2 tile in 4x4.
test(tile_then_find) :-
    gridpatch_tile_fill([[x,b],[b,x]], 4, 4, G),
    gridpatch_find_all(G, [[x,b],[b,x]], Pos),
    length(Pos, 5).

% AC-GPT-040: overlay then extract gives expected patch.
test(overlay_then_extract) :-
    base4(G), p2x2(P),
    gridpatch_overlay(G, P, 1, 1, z, R),
    gridpatch_extract(R, 1, 1, 2, 2, Q),
    Q = [[x,x],[x,x]].

% AC-GPT-041: inpaint then place restores content.
test(inpaint_then_place) :-
    checker(G),
    gridpatch_extract(G, 0, 0, 1, 1, Patch),
    gridpatch_inpaint(G, 0, 0, 1, 1, b, Blank),
    gridpatch_place(Blank, Patch, 0, 0, Restored),
    nth0(0, Restored, R0), nth0(0, R0, x).

% AC-GPT-042: scatter then count.
test(scatter_then_count) :-
    base4(G), p1x1(P),
    gridpatch_scatter(G, P, [0-0, 1-1, 2-2, 3-3], R),
    gridpatch_count(R, [[m]], N), N =:= 4.

% AC-GPT-043: replace_first reduces the match count.
test(replace_first_reduces_count) :-
    checker(G),
    gridpatch_count(G, [[x,b],[b,x]], N0),
    gridpatch_replace_first(G, [[x,b],[b,x]], [[b,b],[b,b]], R),
    gridpatch_count(R, [[x,b],[b,x]], N1),
    N1 < N0.

% AC-GPT-044: gridpatch_size and tile_fill agree on dimensions.
test(size_tile_agree) :-
    Patch = [[a,b],[c,d]],
    gridpatch_tile_fill(Patch, 6, 6, G),
    gridpatch_size(G, H, W), H =:= 6, W =:= 6.

:- end_tests(gpt_combined).
