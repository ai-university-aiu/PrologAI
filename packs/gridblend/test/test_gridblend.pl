:- use_module('../prolog/gridblend').

:- begin_tests(gridblend).

% --- gbld_overlay/4 ---

test('AC-GBLD-001: gbld_overlay top non-bg cell wins') :-
    Top    = [[r,b],[b,b]],
    Bottom = [[g,g],[g,g]],
    gbld_overlay(Top, Bottom, b, [[r,g],[g,g]]).

test('AC-GBLD-002: gbld_overlay bg in top reveals bottom') :-
    Top    = [[b,b],[b,b]],
    Bottom = [[r,g],[g,r]],
    gbld_overlay(Top, Bottom, b, [[r,g],[g,r]]).

test('AC-GBLD-003: gbld_overlay both non-bg: top wins') :-
    Top    = [[r,g],[b,b]],
    Bottom = [[y,y],[y,y]],
    gbld_overlay(Top, Bottom, b, [[r,g],[y,y]]).

% --- gbld_underlay/4 ---

test('AC-GBLD-004: gbld_underlay bottom non-bg cell wins') :-
    Top    = [[r,r],[r,r]],
    Bottom = [[g,b],[b,b]],
    gbld_underlay(Top, Bottom, b, [[g,r],[r,r]]).

test('AC-GBLD-005: gbld_underlay bg in bottom reveals top') :-
    Top    = [[r,g],[g,r]],
    Bottom = [[b,b],[b,b]],
    gbld_underlay(Top, Bottom, b, [[r,g],[g,r]]).

test('AC-GBLD-006: gbld_underlay both non-bg: bottom wins') :-
    Top    = [[r,r],[r,r]],
    Bottom = [[g,g],[g,g]],
    gbld_underlay(Top, Bottom, b, [[g,g],[g,g]]).

% --- gbld_stencil/4 ---

test('AC-GBLD-007: gbld_stencil keeps source only at mask-match positions') :-
    Source  = [[r,g],[g,r]],
    Stencil = [[m,b],[b,m]],
    gbld_stencil(Source, Stencil, m, [[r,m],[m,r]]).

test('AC-GBLD-008: gbld_stencil all mask positions match: identity of source') :-
    Source  = [[r,g],[g,r]],
    Stencil = [[m,m],[m,m]],
    gbld_stencil(Source, Stencil, m, [[r,g],[g,r]]).

test('AC-GBLD-009: gbld_stencil no mask positions match: all-SC output') :-
    Source  = [[r,g],[g,r]],
    Stencil = [[b,b],[b,b]],
    gbld_stencil(Source, Stencil, m, [[m,m],[m,m]]).

% --- gbld_priority/3 ---

test('AC-GBLD-010: gbld_priority first grid on top') :-
    G1 = [[r,b],[b,b]],
    G2 = [[g,g],[b,b]],
    G3 = [[y,y],[y,y]],
    gbld_priority([G1,G2,G3], b, [[r,g],[y,y]]).

test('AC-GBLD-011: gbld_priority single grid is identity') :-
    G = [[r,b],[b,r]],
    gbld_priority([G], b, G).

test('AC-GBLD-012: gbld_priority all grids contribute at different positions') :-
    G1 = [[r,b],[b,b]],
    G2 = [[b,g],[b,b]],
    G3 = [[b,b],[x,b]],
    gbld_priority([G1,G2,G3], b, [[r,g],[x,b]]).

% --- gbld_checker_blend/5 ---

test('AC-GBLD-013: gbld_checker_blend parity 0 on 2x2 grid') :-
    G1 = [[r,r],[r,r]],
    G2 = [[g,g],[g,g]],
    % (0+0)=0 even→G1, (0+1)=1 odd→G2; (1+0)=1 odd→G2, (1+1)=2 even→G1
    gbld_checker_blend(G1, G2, b, 0, [[r,g],[g,r]]).

test('AC-GBLD-014: gbld_checker_blend parity 1 on 2x2 grid') :-
    G1 = [[r,r],[r,r]],
    G2 = [[g,g],[g,g]],
    gbld_checker_blend(G1, G2, b, 1, [[g,r],[r,g]]).

test('AC-GBLD-015: gbld_checker_blend with same grid yields that grid') :-
    G = [[r,g],[g,r]],
    gbld_checker_blend(G, G, b, 0, G).

% --- gbld_stripe_blend/5 ---

test('AC-GBLD-016: gbld_stripe_blend stripe width 1 on 2-row grid') :-
    G1 = [[r,r],[r,r]],
    G2 = [[g,g],[g,g]],
    % row 0: stripe 0 (even) → G1 over G2 = [[r,r]]
    % row 1: stripe 1 (odd)  → G2 over G1 = [[g,g]]
    gbld_stripe_blend(G1, G2, b, 1, [[r,r],[g,g]]).

test('AC-GBLD-017: gbld_stripe_blend stripe width 2 on 4-row grid') :-
    G1 = [[r],[r],[r],[r]],
    G2 = [[g],[g],[g],[g]],
    % rows 0-1: stripe 0 → G1; rows 2-3: stripe 1 → G2
    gbld_stripe_blend(G1, G2, b, 2, [[r],[r],[g],[g]]).

test('AC-GBLD-018: gbld_stripe_blend with same grid yields that grid') :-
    G = [[r,g],[g,r]],
    gbld_stripe_blend(G, G, b, 1, G).

% --- gbld_threshold_replace/5 ---

test('AC-GBLD-019: gbld_threshold_replace row at threshold replaced') :-
    Grid = [[r,g,r],[b,b,b]],
    % row 0 has 3 non-bg; threshold 3 → replace with x
    % row 1 has 0 non-bg; threshold 3 → keep
    gbld_threshold_replace(Grid, 3, x, b, [[x,x,x],[b,b,b]]).

test('AC-GBLD-020: gbld_threshold_replace row below threshold kept') :-
    Grid = [[r,b,r],[g,g,g]],
    % row 0 has 2 non-bg; threshold 3 → keep
    % row 1 has 3 non-bg; threshold 3 → replace
    gbld_threshold_replace(Grid, 3, x, b, [[r,b,r],[x,x,x]]).

test('AC-GBLD-021: gbld_threshold_replace threshold 1 replaces all non-empty rows') :-
    Grid = [[r,g],[b,b]],
    % row 0: 2 non-bg → replace; row 1: 0 → keep
    gbld_threshold_replace(Grid, 1, x, b, [[x,x],[b,b]]).

% --- gbld_merge_many/3 ---

test('AC-GBLD-022: gbld_merge_many last grid on top') :-
    G1 = [[r,b],[b,b]],
    G2 = [[b,g],[b,b]],
    G3 = [[b,b],[y,b]],
    % G3 on top of G2 on top of G1: non-overlapping regions each show their source
    gbld_merge_many([G1,G2,G3], b, [[r,g],[y,b]]).

test('AC-GBLD-023: gbld_merge_many single grid is identity') :-
    G = [[r,b],[b,r]],
    gbld_merge_many([G], b, G).

test('AC-GBLD-024: gbld_merge_many later grids override earlier') :-
    G1 = [[r,r],[r,r]],
    G2 = [[g,b],[b,b]],
    % G2 (last) is on top: (0,0)=g from G2; rest from G1
    gbld_merge_many([G1,G2], b, [[g,r],[r,r]]).

% --- gbld_dominant/3 ---

test('AC-GBLD-025: gbld_dominant majority wins at each cell') :-
    G1 = [[r,b],[b,b]],
    G2 = [[r,g],[b,b]],
    G3 = [[b,g],[b,b]],
    % (0,0): r,r → r; (0,1): g,g → g
    gbld_dominant([G1,G2,G3], b, [[r,g],[b,b]]).

test('AC-GBLD-026: gbld_dominant all bg returns all bg') :-
    G = [[b,b],[b,b]],
    gbld_dominant([G,G,G], b, [[b,b],[b,b]]).

test('AC-GBLD-027: gbld_dominant single grid is identity') :-
    G = [[r,g],[g,r]],
    gbld_dominant([G], b, G).

% --- gbld_composite/4 ---

test('AC-GBLD-028: gbld_composite overlay mode: first grid on top') :-
    G1 = [[r,b],[b,b]],
    G2 = [[g,g],[b,b]],
    G3 = [[y,y],[y,y]],
    gbld_composite([G1,G2,G3], b, overlay, [[r,g],[y,y]]).

test('AC-GBLD-029: gbld_composite underlay mode: last grid on top') :-
    G1 = [[r,b],[b,b]],
    G2 = [[b,g],[b,b]],
    G3 = [[b,b],[y,b]],
    % non-overlapping regions: r from G1 (bottom), g from G2 (middle), y from G3 (top)
    gbld_composite([G1,G2,G3], b, underlay, [[r,g],[y,b]]).

test('AC-GBLD-030: gbld_composite dominant mode: most frequent wins') :-
    G1 = [[r,b],[b,b]],
    G2 = [[r,g],[b,b]],
    G3 = [[b,g],[b,b]],
    gbld_composite([G1,G2,G3], b, dominant, [[r,g],[b,b]]).

% --- additional edge cases ---

test('AC-GBLD-031: gbld_overlay all-bg top yields bottom') :-
    Bottom = [[r,g],[g,r]],
    gbld_overlay([[b,b],[b,b]], Bottom, b, Bottom).

test('AC-GBLD-032: gbld_underlay all-bg bottom yields top') :-
    Top = [[r,g],[g,r]],
    gbld_underlay(Top, [[b,b],[b,b]], b, Top).

test('AC-GBLD-033: gbld_priority empty list yields empty grid') :-
    gbld_priority([], b, []).

test('AC-GBLD-034: gbld_merge_many empty list yields empty grid') :-
    gbld_merge_many([], b, []).

test('AC-GBLD-035: gbld_dominant two grids same color: that color wins') :-
    G = [[r,g],[g,r]],
    gbld_dominant([G,G], b, G).

test('AC-GBLD-036: gbld_checker_blend 3x3 grid parity 0') :-
    G1 = [[r,r,r],[r,r,r],[r,r,r]],
    G2 = [[g,g,g],[g,g,g],[g,g,g]],
    gbld_checker_blend(G1, G2, b, 0,
        [[r,g,r],[g,r,g],[r,g,r]]).

test('AC-GBLD-037: gbld_stencil partial mask') :-
    Source  = [[r,g,b],[b,y,r]],
    Stencil = [[m,b,m],[b,m,b]],
    gbld_stencil(Source, Stencil, m,
        [[r,m,b],[m,y,m]]).

test('AC-GBLD-038: gbld_threshold_replace threshold 0 replaces all rows') :-
    Grid = [[r,b],[g,r]],
    gbld_threshold_replace(Grid, 0, x, b, [[x,b],[x,x]]).

test('AC-GBLD-039: gbld_overlay single-cell grids') :-
    gbld_overlay([[r]], [[g]], b, [[r]]).

test('AC-GBLD-040: gbld_underlay single-cell grids') :-
    gbld_underlay([[r]], [[g]], b, [[g]]).

test('AC-GBLD-041: gbld_stripe_blend width equals height: single stripe') :-
    G1 = [[r,r],[r,r]],
    G2 = [[g,g],[g,g]],
    % All rows in stripe 0 (even) → G1 over G2 = G1 (all non-bg)
    gbld_stripe_blend(G1, G2, b, 3, [[r,r],[r,r]]).

test('AC-GBLD-042: gbld_composite overlay single grid') :-
    G = [[r,b],[b,r]],
    gbld_composite([G], b, overlay, G).

test('AC-GBLD-043: gbld_composite underlay single grid') :-
    G = [[r,b],[b,r]],
    gbld_composite([G], b, underlay, G).

test('AC-GBLD-044: gbld_overlay then underlay: overlay result as Top, original as Bottom') :-
    G1 = [[r,b],[b,b]],
    G2 = [[b,g],[b,b]],
    G3 = [[y,y],[y,y]],
    gbld_overlay(G1, G2, b, Layer1),
    gbld_underlay(Layer1, G3, b, Final),
    Final = [[y,y],[y,y]].

:- end_tests(gridblend).
