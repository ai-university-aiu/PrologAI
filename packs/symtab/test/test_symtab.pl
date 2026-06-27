% Test suite for symtab (st_*, Layer 247).
:- use_module('../prolog/symtab.pl').

:- begin_tests(symtab).

% --- Shared test data ---

% Simple ob/3 objects used across tests.
% ob(Color, Cells, BBox)
red1(ob(r, [r(0,0)], r0(0,0,0,0))).           % red, size 1
blue1(ob(b, [r(1,1)], r0(1,1,1,1))).           % blue, size 1
green1(ob(g, [r(2,2)], r0(2,2,2,2))).          % green, size 1
yellow1(ob(y, [r(3,3)], r0(3,3,3,3))).         % yellow, size 1
red2(ob(r, [r(0,0),r(0,1)], r0(0,0,0,1))).     % red, size 2
blue3(ob(b, [r(0,0),r(0,1),r(0,2)], r0(0,0,0,2))). % blue, size 3
% Object that looks like it has a hole: 2x2 bbox but only 3 cells (missing center).
hollow(ob(r, [r(0,0),r(0,1),r(1,0)], r0(0,0,1,1))). % red, L-shape, bbox 2x2

% Training pairs: pair(InputObjs, OutputObjs).
% Pair where color co-varies: red in → blue out, blue in → green out.
pair1(pair([ob(r,[r(0,0)],r0(0,0,0,0)), ob(b,[r(1,1)],r0(1,1,1,1))],
          [ob(b,[r(0,0)],r0(0,0,0,0)), ob(g,[r(1,1)],r0(1,1,1,1))])).

% Pair where size co-varies: size-1 → yellow, size-2 → green.
pair2(pair([ob(r,[r(0,0)],r0(0,0,0,0)), ob(b,[r(0,1),r(0,2)],r0(0,1,0,2))],
          [ob(y,[r(0,0)],r0(0,0,0,0)), ob(g,[r(0,1),r(0,2)],r0(0,1,0,2))])).

% Pair where color stays the same.
pair_same(pair([ob(r,[r(0,0)],r0(0,0,0,0))],
               [ob(r,[r(1,0)],r0(1,0,1,0))])).

% Two consistent pairs: color(r) → b in both.
pair_a(pair([ob(r,[r(0,0)],r0(0,0,0,0))], [ob(b,[r(0,0)],r0(0,0,0,0))])).
pair_b(pair([ob(r,[r(1,1)],r0(1,1,1,1))], [ob(b,[r(1,1)],r0(1,1,1,1))])).

% --- st_color_feature ---

test('AC-ST-001: st_color_feature extracts color(r) from red object') :-
    red1(R), st_color_feature(R, F), F = color(r).

test('AC-ST-002: st_color_feature extracts color(b) from blue object') :-
    blue1(B), st_color_feature(B, F), F = color(b).

test('AC-ST-003: st_color_feature extracts color(g) from green object') :-
    green1(G), st_color_feature(G, F), F = color(g).

% --- st_size_feature ---

test('AC-ST-004: st_size_feature extracts size(1) from single-cell object') :-
    red1(R), st_size_feature(R, F), F = size(1).

test('AC-ST-005: st_size_feature extracts size(2) from two-cell object') :-
    red2(R), st_size_feature(R, F), F = size(2).

test('AC-ST-006: st_size_feature extracts size(3) from three-cell object') :-
    blue3(B), st_size_feature(B, F), F = size(3).

% --- st_hole_count ---

test('AC-ST-007: st_hole_count returns 0 for solid single cell') :-
    red1(R), st_hole_count(R, N), N =:= 0.

test('AC-ST-008: st_hole_count returns 0 for solid two-cell object') :-
    red2(R), st_hole_count(R, N), N =:= 0.

test('AC-ST-009: st_hole_count returns positive for L-shape with missing corner') :-
    hollow(H), st_hole_count(H, N), N > 0.

test('AC-ST-010: st_hole_count for 1x1 solid returns 0') :-
    O = ob(r, [r(5,5)], r0(5,5,5,5)),
    st_hole_count(O, N), N =:= 0.

% --- st_lookup ---

test('AC-ST-011: st_lookup finds first matching entry') :-
    Table = [sym(color(r), b), sym(color(b), g)],
    st_lookup(Table, color(r), V),
    V = b.

test('AC-ST-012: st_lookup finds second entry') :-
    Table = [sym(color(r), b), sym(color(b), g)],
    st_lookup(Table, color(b), V),
    V = g.

test('AC-ST-013: st_lookup fails for unknown feature') :-
    Table = [sym(color(r), b)],
    \+ st_lookup(Table, color(g), _).

% --- st_entry_consistent ---

test('AC-ST-014: entry consistent with empty table') :-
    st_entry_consistent(sym(color(r), b), []).

test('AC-ST-015: entry consistent when table maps same F to same V') :-
    st_entry_consistent(sym(color(r), b), [sym(color(r), b)]).

test('AC-ST-016: entry inconsistent when table maps F to different V') :-
    \+ st_entry_consistent(sym(color(r), b), [sym(color(r), g)]).

test('AC-ST-017: entry consistent when table maps different F') :-
    st_entry_consistent(sym(color(r), b), [sym(color(g), y)]).

% --- st_position_feature ---

test('AC-ST-018: position feature top-left quadrant') :-
    O = ob(r, [r(0,0)], r0(0,0,0,0)),
    st_position_feature(O, dims(10,10), pos(tl)).

test('AC-ST-019: position feature top-right quadrant') :-
    O = ob(r, [r(0,8)], r0(0,8,0,8)),
    st_position_feature(O, dims(10,10), pos(tr)).

test('AC-ST-020: position feature bottom-left quadrant') :-
    O = ob(r, [r(8,0)], r0(8,0,8,0)),
    st_position_feature(O, dims(10,10), pos(bl)).

test('AC-ST-021: position feature bottom-right quadrant') :-
    O = ob(r, [r(8,8)], r0(8,8,8,8)),
    st_position_feature(O, dims(10,10), pos(br)).

% --- st_is_symbol ---

test('AC-ST-022: small object is symbol among larger content objects') :-
    Small = ob(r, [r(0,0)], r0(0,0,0,0)),
    Large = ob(b, [r(1,0),r(1,1),r(1,2),r(1,3)], r0(1,0,1,3)),
    st_is_symbol(Small, [Large]).

test('AC-ST-023: object with unique color is symbol') :-
    Sym = ob(y, [r(0,0),r(0,1)], r0(0,0,0,1)),
    Content = ob(r, [r(1,0),r(1,1)], r0(1,0,1,1)),
    st_is_symbol(Sym, [Content]).

test('AC-ST-024: empty content list - any object could be symbol') :-
    red1(R), st_is_symbol(R, []).

% --- st_candidate_symbols ---

test('AC-ST-025: candidate symbols picks smallest quartile') :-
    O1 = ob(r, [r(0,0)], r0(0,0,0,0)),          % size 1
    O2 = ob(b, [r(0,1),r(0,2)], r0(0,1,0,2)),   % size 2
    O3 = ob(g, [r(1,0),r(1,1),r(1,2)], r0(1,0,1,2)), % size 3
    O4 = ob(y, [r(2,0),r(2,1),r(2,2),r(2,3)], r0(2,0,2,3)), % size 4
    st_candidate_symbols([O1, O2, O3, O4], Cands),
    length(Cands, Len), Len >= 1,
    memberchk(O1, Cands).

test('AC-ST-026: empty input gives empty candidates') :-
    st_candidate_symbols([], []).

test('AC-ST-027: single object always a candidate') :-
    red1(R), st_candidate_symbols([R], Cands), Cands = [R].

% --- st_apply_table ---

test('AC-ST-028: apply color table - red becomes blue') :-
    Table = [sym(color(r), b)],
    InObjs = [ob(r,[r(0,0)],r0(0,0,0,0))],
    st_apply_table(Table, InObjs, Map),
    memberchk(cm(r, b), Map).

test('AC-ST-029: apply size table - size-1 becomes yellow') :-
    Table = [sym(size(1), y)],
    InObjs = [ob(r,[r(0,0)],r0(0,0,0,0))],
    st_apply_table(Table, InObjs, Map),
    memberchk(cm(r, y), Map).

test('AC-ST-030: apply table to empty objs gives empty map') :-
    Table = [sym(color(r), b)],
    st_apply_table(Table, [], Map),
    Map = [].

test('AC-ST-031: empty table gives empty map') :-
    InObjs = [ob(r,[r(0,0)],r0(0,0,0,0))],
    st_apply_table([], InObjs, Map),
    Map = [].

test('AC-ST-032: apply table with two entries produces two cm terms') :-
    Table = [sym(color(r), b), sym(color(g), y)],
    InObjs = [ob(r,[r(0,0)],r0(0,0,0,0)), ob(g,[r(1,1)],r0(1,1,1,1))],
    st_apply_table(Table, InObjs, Map),
    length(Map, 2),
    memberchk(cm(r, b), Map),
    memberchk(cm(g, y), Map).

% --- st_identify_symbols ---

test('AC-ST-033: identify symbols from color-covarying pair') :-
    pair1(P),
    st_identify_symbols([P], Syms),
    Syms \= [].

test('AC-ST-034: no symbols when colors stay same') :-
    pair_same(P),
    st_identify_symbols([P], Syms),
    Syms = [].

% --- st_contrastive_learn ---

test('AC-ST-035: contrastive learn from single pair finds color feature') :-
    pair_a(P),
    st_contrastive_learn([P], Findings),
    Findings \= [].

test('AC-ST-036: contrastive learn from two consistent pairs') :-
    pair_a(A), pair_b(B),
    st_contrastive_learn([A, B], Findings),
    Findings \= [].

test('AC-ST-037: contrastive learn from empty pairs gives empty') :-
    st_contrastive_learn([], F),
    F = [].

% --- st_score_table ---

test('AC-ST-038: score table that explains all pairs = pair count') :-
    pair_a(A), pair_b(B),
    Table = [sym(color(r), b)],
    st_score_table(Table, [A, B], Score),
    Score =:= 2.

test('AC-ST-039: score table that explains no pairs = 0') :-
    pair_a(A),
    Table = [sym(color(g), y)],   % g→y, but pair has r→b
    st_score_table(Table, [A], Score),
    Score =:= 0.

test('AC-ST-040: score empty table against no pairs = 0') :-
    st_score_table([], [], Score),
    Score =:= 0.

% --- st_build_table ---

test('AC-ST-041: build table from single pair') :-
    pair_a(P),
    st_build_table([P], Table),
    is_list(Table).

test('AC-ST-042: build table from two consistent pairs') :-
    pair_a(A), pair_b(B),
    st_build_table([A, B], Table),
    is_list(Table),
    Table \= [].

test('AC-ST-043: build table from empty pairs gives empty table') :-
    st_build_table([], Table),
    Table = [].

% --- st_best_table ---

test('AC-ST-044: best table selects highest scoring candidate') :-
    pair_a(A),
    Good = [sym(color(r), b)],
    Bad  = [sym(color(g), y)],
    st_best_table([Good, Bad], [A], Best),
    Best = Good.

:- end_tests(symtab).
