% Test suite for gridobjmatch (gom_*, Layer 246).
:- use_module('../prolog/gridobjmatch.pl').

:- begin_tests(gridobjmatch).

% Shared test objects (ob(Color, Cells, BBox)).
% Single-cell objects at specific positions.
or00(ob(r, [r(0,0)], r0(0,0,0,0))).   % red,   size 1, top-left (0,0)
ob11(ob(b, [r(1,1)], r0(1,1,1,1))).   % blue,  size 1, top-left (1,1)
og22(ob(g, [r(2,2)], r0(2,2,2,2))).   % green, size 1, top-left (2,2)
or01(ob(r, [r(0,1)], r0(0,1,0,1))).   % red,   size 1, top-left (0,1) moved right
ob12(ob(b, [r(1,2)], r0(1,2,1,2))).   % blue,  size 1, top-left (1,2) moved right
og23(ob(g, [r(2,3)], r0(2,3,2,3))).   % green, size 1, top-left (2,3) moved right
oy00(ob(y, [r(0,0)], r0(0,0,0,0))).   % yellow, new color, top-left (0,0)
or10(ob(r, [r(1,0)], r0(1,0,1,0))).   % red,   size 1, top-left (1,0) moved down
% Size-2 objects.
or2a(ob(r, [r(0,0),r(0,1)], r0(0,0,0,1))). % red,  size 2, top-left (0,0)
ob2a(ob(b, [r(1,0),r(1,1)], r0(1,0,1,1))). % blue, size 2, top-left (1,0)
% Recolored objects (same position, different color).
ob00(ob(b, [r(0,0)], r0(0,0,0,0))).   % blue at (0,0) - was red or00
og11(ob(g, [r(1,1)], r0(1,1,1,1))).   % green at (1,1) - was blue ob11

% --- gridobjmatch_match_color ---

test('AC-GOM-001: match single red object by color') :-
    or00(O1), or01(O2),
    gridobjmatch_match_color([O1], [O2], Pairs),
    Pairs = [match(O1, O2)].

test('AC-GOM-002: match two objects by color, each a different color') :-
    or00(R1), ob11(B1),
    or01(R2), ob12(B2),
    gridobjmatch_match_color([R1, B1], [R2, B2], Pairs),
    Pairs = [match(R1, R2), match(B1, B2)].

test('AC-GOM-003: no match when colors differ') :-
    or00(R), ob11(B),
    gridobjmatch_match_color([R], [B], Pairs),
    Pairs = [].

% --- gridobjmatch_match_nearest ---

test('AC-GOM-004: match single pair by nearest centroid') :-
    or00(O1), or01(O2),
    gridobjmatch_match_nearest([O1], [O2], Pairs),
    Pairs = [match(O1, O2)].

test('AC-GOM-005: nearest match selects closest, not first') :-
    or00(O1),
    or01(Near), og22(Far),
    gridobjmatch_match_nearest([O1], [Far, Near], Pairs),
    Pairs = [match(O1, Near)].

test('AC-GOM-006: empty Objs2 yields no pairs') :-
    or00(O1),
    gridobjmatch_match_nearest([O1], [], Pairs),
    Pairs = [].

% --- gridobjmatch_match_size ---

test('AC-GOM-007: match two size-1 objects') :-
    or00(O1), ob11(O2),
    gridobjmatch_match_size([O1], [O2], Pairs),
    Pairs = [match(O1, O2)].

test('AC-GOM-008: no match when sizes differ') :-
    or00(Size1), or2a(Size2),
    gridobjmatch_match_size([Size1], [Size2], Pairs),
    Pairs = [].

test('AC-GOM-009: match multiple objects by size') :-
    or2a(R2), ob2a(B2),
    or00(R1), ob11(B1),
    gridobjmatch_match_size([R2, R1], [B2, B1], Pairs),
    length(Pairs, 2),
    memberchk(match(R2, B2), Pairs),
    memberchk(match(R1, B1), Pairs).

% --- gridobjmatch_unmatched_a ---

test('AC-GOM-010: all objects matched, unmatched_a is empty') :-
    or00(O1), or01(O2),
    Pairs = [match(O1, O2)],
    gridobjmatch_unmatched_a(Pairs, [O1], Unmatched),
    Unmatched = [].

test('AC-GOM-011: one object in Objs1 not in any pair') :-
    or00(O1), ob11(O2), or01(O3),
    Pairs = [match(O1, O3)],
    gridobjmatch_unmatched_a(Pairs, [O1, O2], Unmatched),
    Unmatched = [O2].

% --- gridobjmatch_unmatched_b ---

test('AC-GOM-012: all objects matched, unmatched_b is empty') :-
    or00(O1), or01(O2),
    Pairs = [match(O1, O2)],
    gridobjmatch_unmatched_b(Pairs, [O2], Unmatched),
    Unmatched = [].

test('AC-GOM-013: one object in Objs2 not in any pair') :-
    or00(O1), or01(O2), ob11(O3),
    Pairs = [match(O1, O2)],
    gridobjmatch_unmatched_b(Pairs, [O2, O3], Unmatched),
    Unmatched = [O3].

% --- gridobjmatch_color_diff ---

test('AC-GOM-014: all same-color pairs go into Same') :-
    or00(O1), or01(O2),
    Pairs = [match(O1, O2)],
    gridobjmatch_color_diff(Pairs, Same, Diff),
    Same = [match(O1, O2)],
    Diff = [].

test('AC-GOM-015: all different-color pairs go into Diff') :-
    or00(O1), ob00(O2),
    Pairs = [match(O1, O2)],
    gridobjmatch_color_diff(Pairs, Same, Diff),
    Same = [],
    Diff = [match(O1, O2)].

test('AC-GOM-016: mixed pairs split correctly') :-
    or00(R1), or01(R2),    % red -> red: same color
    ob11(B1), og11(B2),    % blue -> green: different color
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_color_diff(Pairs, Same, Diff),
    Same = [match(R1, R2)],
    Diff = [match(B1, B2)].

% --- gridobjmatch_move_vector ---

test('AC-GOM-017: no movement gives mv(0,0)') :-
    or00(O1), or00(O2),
    gridobjmatch_move_vector(match(O1, O2), V),
    V = mv(0, 0).

test('AC-GOM-018: move right by 1 gives mv(0,1)') :-
    or00(O1), or01(O2),
    gridobjmatch_move_vector(match(O1, O2), V),
    V = mv(0, 1).

test('AC-GOM-019: move down by 1 gives mv(1,0)') :-
    or00(O1), or10(O2),
    gridobjmatch_move_vector(match(O1, O2), V),
    V = mv(1, 0).

% --- gridobjmatch_move_vectors ---

test('AC-GOM-020: list of pairs produces list of vectors') :-
    or00(R1), or01(R2), ob11(B1), ob12(B2),
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_move_vectors(Pairs, Vectors),
    Vectors = [mv(0,1), mv(0,1)].

test('AC-GOM-021: empty pairs list gives empty vectors list') :-
    gridobjmatch_move_vectors([], Vectors),
    Vectors = [].

% --- gridobjmatch_constant_move ---

test('AC-GOM-022: all pairs same vector - constant move succeeds') :-
    or00(R1), or01(R2), ob11(B1), ob12(B2),
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_constant_move(Pairs, V),
    V = mv(0, 1).

test('AC-GOM-023: different vectors - constant move fails') :-
    or00(O1), or01(O2),   % top-left (0,0)->(0,1): mv(0,1)
    og22(O3), ob11(O4),   % top-left (2,2)->(1,1): mv(-1,-1)
    Pairs = [match(O1, O2), match(O3, O4)],
    \+ gridobjmatch_constant_move(Pairs, _).

test('AC-GOM-024: single pair always constant') :-
    or00(O1), og22(O2),
    gridobjmatch_constant_move([match(O1, O2)], V),
    V = mv(2, 2).

% --- gridobjmatch_infer_color_map ---

test('AC-GOM-025: no color changes - empty map') :-
    or00(O1), or01(O2),
    gridobjmatch_infer_color_map([match(O1, O2)], Map),
    Map = [].

test('AC-GOM-026: one color change inferred correctly') :-
    or00(O1), ob00(O2),
    gridobjmatch_infer_color_map([match(O1, O2)], Map),
    Map = [cm(r, b)].

test('AC-GOM-027: multiple color changes deduplicated and sorted') :-
    or00(R1), ob00(R2),
    ob11(B1), og11(B2),
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_infer_color_map(Pairs, Map),
    msort(Map, Sorted),
    msort([cm(r,b), cm(b,g)], Sorted).

% --- gridobjmatch_appeared ---

test('AC-GOM-028: no new colors - appeared is empty') :-
    or00(O1), ob11(O2),
    or01(O3), ob12(O4),
    gridobjmatch_appeared([O1, O2], [O3, O4], Appeared),
    Appeared = [].

test('AC-GOM-029: one new color in Objs2') :-
    or00(O1), oy00(O2),
    gridobjmatch_appeared([O1], [O1, O2], Appeared),
    Appeared = [O2].

% --- gridobjmatch_disappeared ---

test('AC-GOM-030: no lost colors - disappeared is empty') :-
    or00(O1), ob11(O2),
    or01(O3), ob12(O4),
    gridobjmatch_disappeared([O1, O2], [O3, O4], Disappeared),
    Disappeared = [].

test('AC-GOM-031: one color lost from Objs1') :-
    or00(O1), oy00(O2),
    gridobjmatch_disappeared([O1, O2], [O1], Disappeared),
    Disappeared = [O2].

% --- gridobjmatch_same_structure ---

test('AC-GOM-032: same color multiset - succeeds') :-
    or00(R1), ob11(B1),
    or01(R2), ob12(B2),
    gridobjmatch_same_structure([R1, B1], [R2, B2]).

test('AC-GOM-033: different color multiset - fails') :-
    or00(R), ob11(B), og22(G),
    \+ gridobjmatch_same_structure([R, B], [R, G]).

test('AC-GOM-034: same colors in different list order - succeeds') :-
    or00(R), ob11(B),
    or01(R2), ob12(B2),
    gridobjmatch_same_structure([R, B], [B2, R2]).

% --- gridobjmatch_count_change ---

test('AC-GOM-035: same count gives N=0') :-
    or00(R), ob11(B),
    gridobjmatch_count_change([R], [B], N),
    N =:= 0.

test('AC-GOM-036: more objects in Objs2 gives positive N') :-
    or00(R), ob11(B), og22(G),
    gridobjmatch_count_change([R], [B, G], N),
    N =:= 1.

% --- Integration tests ---

test('AC-GOM-037: match by color then color_diff all same') :-
    or00(R1), ob11(B1),
    or01(R2), ob12(B2),
    gridobjmatch_match_color([R1, B1], [R2, B2], Pairs),
    gridobjmatch_color_diff(Pairs, Same, Diff),
    length(Same, 2),
    Diff = [].

test('AC-GOM-038: match nearest, color_diff finds all pairs changed') :-
    or00(R1), ob11(B1),
    ob00(N1), og11(N2),   % ob(b) at (0,0), ob(g) at (1,1)
    gridobjmatch_match_nearest([R1, B1], [N1, N2], Pairs),
    gridobjmatch_color_diff(Pairs, Same, Diff),
    Same = [],
    length(Diff, 2).

test('AC-GOM-039: match nearest then constant move') :-
    or00(R1), ob11(B1), og22(G1),
    or01(R2), ob12(B2), og23(G2),
    gridobjmatch_match_nearest([R1, B1, G1], [R2, B2, G2], Pairs),
    gridobjmatch_constant_move(Pairs, V),
    V = mv(0, 1).

test('AC-GOM-040: infer color map from matched pairs') :-
    or00(R1), ob11(B1),
    ob00(R2), og11(B2),
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_infer_color_map(Pairs, Map),
    msort(Map, Sorted),
    msort([cm(r,b), cm(b,g)], Sorted).

test('AC-GOM-041: appeared and disappeared correct after color swap') :-
    or00(R), ob11(B), og22(G), oy00(Y),
    gridobjmatch_appeared([R, B], [B, G, Y], App),
    length(App, 2),
    memberchk(G, App), memberchk(Y, App),
    gridobjmatch_disappeared([R, B], [B, G, Y], Dis),
    Dis = [R].

test('AC-GOM-042: unmatched_a and unmatched_b after partial color match') :-
    or00(R), ob11(B), og22(G),
    or01(R2),
    gridobjmatch_match_color([R, B, G], [R2], Pairs),
    gridobjmatch_unmatched_a(Pairs, [R, B, G], UA),
    length(UA, 2),
    memberchk(B, UA), memberchk(G, UA),
    gridobjmatch_unmatched_b(Pairs, [R2], UB),
    UB = [].

test('AC-GOM-043: same structure check via match and structure') :-
    or00(R1), ob11(B1), og22(G1),
    or01(R2), ob12(B2), og23(G2),
    gridobjmatch_same_structure([R1, B1, G1], [R2, B2, G2]),
    gridobjmatch_count_change([R1, B1, G1], [R2, B2, G2], N),
    N =:= 0.

test('AC-GOM-044: full pipeline - pairs, color_diff, infer_color_map') :-
    or00(R1), ob11(B1),
    ob00(R2), og11(B2),    % R1(r)->R2(b), B1(b)->B2(g): both change color
    Pairs = [match(R1, R2), match(B1, B2)],
    gridobjmatch_color_diff(Pairs, Same, Diff),
    Same = [],
    length(Diff, 2),
    gridobjmatch_infer_color_map(Pairs, Map),
    length(Map, 2),
    memberchk(cm(r,b), Map),
    memberchk(cm(b,g), Map).

:- end_tests(gridobjmatch).
