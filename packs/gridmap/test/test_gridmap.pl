:- use_module('../prolog/gridmap').

% Test grids:
%   pal3 = [[r,g,r],[g,b,g],[r,g,r]]  BgColor=b; palette=[r,g]
%   two  = [[r,b,r],[b,r,b]]           BgColor=b; palette=[r]
%   abc  = [[a,b,c],[d,e,f]]           BgColor=z; palette=[a,b,c,d,e,f]
%   ab3  = [[b,b,b],[b,b,b],[b,b,b]]  all-bg
%   mono = [[x,x],[x,x]]               no bg; palette=[x]
%   g12  = [[r,g],[b,r]]               BgColor=z; two colors r and g

:- begin_tests(gridmap).

% --- gridmap_remap ---

test('AC-GMP-001: remap two colors on pal3') :-
    gridmap_remap([[r,g,r],[g,b,g],[r,g,r]], [r-x, g-y], R),
    R = [[x,y,x],[y,b,y],[x,y,x]].

test('AC-GMP-002: remap with partial match leaves unmatched unchanged') :-
    gridmap_remap([[r,g,r],[g,b,g],[r,g,r]], [r-x], R),
    R = [[x,g,x],[g,b,g],[x,g,x]].

test('AC-GMP-003: remap with empty mapping is identity') :-
    gridmap_remap([[a,b],[c,d]], [], R),
    R = [[a,b],[c,d]].

% --- gridmap_swap ---

test('AC-GMP-004: swap r and g on pal3') :-
    gridmap_swap([[r,g,r],[g,b,g],[r,g,r]], r, g, R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-005: swap r and b on two') :-
    gridmap_swap([[r,b,r],[b,r,b]], r, b, R),
    R = [[b,r,b],[r,b,r]].

test('AC-GMP-006: swap when color absent leaves grid unchanged') :-
    gridmap_swap([[a,a],[a,a]], a, z, R),
    R = [[z,z],[z,z]].

% --- gridmap_replace ---

test('AC-GMP-007: replace r with x on pal3') :-
    gridmap_replace([[r,g,r],[g,b,g],[r,g,r]], r, x, R),
    R = [[x,g,x],[g,b,g],[x,g,x]].

test('AC-GMP-008: replace b with x on two') :-
    gridmap_replace([[r,b,r],[b,r,b]], b, x, R),
    R = [[r,x,r],[x,r,x]].

test('AC-GMP-009: replace absent color is identity') :-
    gridmap_replace([[a,b],[c,d]], z, x, R),
    R = [[a,b],[c,d]].

% --- gridmap_merge ---

test('AC-GMP-010: merge [r,g] into x on pal3') :-
    gridmap_merge([[r,g,r],[g,b,g],[r,g,r]], [r,g], x, R),
    R = [[x,x,x],[x,b,x],[x,x,x]].

test('AC-GMP-011: merge single color is like replace') :-
    gridmap_merge([[r,b,r],[b,r,b]], [b], x, R),
    R = [[r,x,r],[x,r,x]].

test('AC-GMP-012: merge all colors into z on abc') :-
    gridmap_merge([[a,b,c],[d,e,f]], [a,b,c,d,e,f], z, R),
    R = [[z,z,z],[z,z,z]].

% --- gridmap_normalize ---

test('AC-GMP-013: normalize pal3 with bg=b') :-
    gridmap_normalize([[r,g,r],[g,b,g],[r,g,r]], b, N),
    N = [[1,2,1],[2,b,2],[1,2,1]].

test('AC-GMP-014: normalize all-bg grid is identity') :-
    gridmap_normalize([[b,b,b],[b,b,b]], b, N),
    N = [[b,b,b],[b,b,b]].

test('AC-GMP-015: normalize abc assigns ranks in row-major order') :-
    gridmap_normalize([[a,b,c],[d,e,f]], z, N),
    N = [[1,2,3],[4,5,6]].

% --- gridmap_palette ---

test('AC-GMP-016: palette of pal3 with bg=b is [r,g]') :-
    gridmap_palette([[r,g,r],[g,b,g],[r,g,r]], b, P),
    P = [r,g].

test('AC-GMP-017: palette of all-bg grid is empty') :-
    gridmap_palette([[b,b,b],[b,b,b]], b, P),
    P = [].

test('AC-GMP-018: palette of abc with bg=z is [a,b,c,d,e,f]') :-
    gridmap_palette([[a,b,c],[d,e,f]], z, P),
    P = [a,b,c,d,e,f].

% --- gridmap_recolor_fg ---

test('AC-GMP-019: recolor_fg pal3 bg=b fg=x replaces r and g') :-
    gridmap_recolor_fg([[r,g,r],[g,b,g],[r,g,r]], b, x, R),
    R = [[x,x,x],[x,b,x],[x,x,x]].

test('AC-GMP-020: recolor_fg on all-bg grid is identity') :-
    gridmap_recolor_fg([[b,b],[b,b]], b, x, R),
    R = [[b,b],[b,b]].

test('AC-GMP-021: recolor_fg on two bg=b fg=x replaces r only') :-
    gridmap_recolor_fg([[r,b,r],[b,r,b]], b, x, R),
    R = [[x,b,x],[b,x,b]].

% --- gridmap_mask_color ---

test('AC-GMP-022: mask_color keep r in pal3 bg=b') :-
    gridmap_mask_color([[r,g,r],[g,b,g],[r,g,r]], r, b, R),
    R = [[r,b,r],[b,b,b],[r,b,r]].

test('AC-GMP-023: mask_color keep g in pal3 bg=b') :-
    gridmap_mask_color([[r,g,r],[g,b,g],[r,g,r]], g, b, R),
    R = [[b,g,b],[g,b,g],[b,g,b]].

test('AC-GMP-024: mask_color with absent color produces all-bg') :-
    gridmap_mask_color([[a,b],[c,d]], z, x, R),
    R = [[x,x],[x,x]].

% --- gridmap_invert ---

test('AC-GMP-025: invert pal3 with palette [r,g] swaps r and g') :-
    gridmap_invert([[r,g,r],[g,b,g],[r,g,r]], [r,g], R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-026: invert with 3-color palette reverses order') :-
    gridmap_invert([[a,b,c],[c,b,a]], [a,b,c], R),
    R = [[c,b,a],[a,b,c]].

test('AC-GMP-027: invert with single-color palette is identity') :-
    gridmap_invert([[x,x],[x,x]], [x], R),
    R = [[x,x],[x,x]].

% --- gridmap_cycle ---

test('AC-GMP-028: cycle two on [r,b] by 1 swaps') :-
    gridmap_cycle([[r,b,r],[b,r,b]], [r,b], 1, R),
    R = [[b,r,b],[r,b,r]].

test('AC-GMP-029: cycle pal3 palette [r,g] by 1 rotates') :-
    gridmap_cycle([[r,g,r],[g,b,g],[r,g,r]], [r,g], 1, R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-030: cycle by 0 is identity') :-
    gridmap_cycle([[a,b,c]], [a,b,c], 0, R),
    R = [[a,b,c]].

test('AC-GMP-031: cycle by len is identity (full wrap)') :-
    gridmap_cycle([[a,b,c]], [a,b,c], 3, R),
    R = [[a,b,c]].

% --- gridmap_build_map ---

test('AC-GMP-032: build_map from [[r,g],[b,r]] to [[x,y],[z,x]] bg=q') :-
    gridmap_build_map([[r,g],[b,r]], [[x,y],[z,x]], q, M),
    M = [r-x, g-y, b-z].

test('AC-GMP-033: build_map skips bg cells (bg=b)') :-
    gridmap_build_map([[r,b],[b,g]], [[x,b],[b,y]], b, M),
    M = [r-x, g-y].

test('AC-GMP-034: build_map skips equal values') :-
    gridmap_build_map([[r,g]], [[r,x]], z, M),
    M = [g-x].

% --- gridmap_invert_map ---

test('AC-GMP-035: invert_map reverses From-To pairs') :-
    gridmap_invert_map([r-x, g-y, b-z], InvM),
    InvM = [x-r, y-g, z-b].

test('AC-GMP-036: invert_map of empty is empty') :-
    gridmap_invert_map([], InvM),
    InvM = [].

test('AC-GMP-037: double invert_map is identity') :-
    gridmap_invert_map([a-b, c-d], M1),
    gridmap_invert_map(M1, M2),
    M2 = [a-b, c-d].

% --- gridmap_compose_maps ---

test('AC-GMP-038: compose [r-g,g-b] with [g-x,b-y]') :-
    gridmap_compose_maps([r-g, g-b], [g-x, b-y], C),
    C = [r-x, g-y].

test('AC-GMP-039: compose where no mid matches gives empty') :-
    gridmap_compose_maps([r-g], [x-y], C),
    C = [].

test('AC-GMP-040: compose empty first map is empty') :-
    gridmap_compose_maps([], [a-b], C),
    C = [].

% --- gridmap_map_count ---

test('AC-GMP-041: map_count counts r cells in pal3 with [r-x]') :-
    gridmap_map_count([[r,g,r],[g,b,g],[r,g,r]], [r-x], Count),
    Count = 4.

test('AC-GMP-042: map_count with [r-x,g-y] counts both') :-
    gridmap_map_count([[r,g,r],[g,b,g],[r,g,r]], [r-x, g-y], Count),
    Count = 8.

test('AC-GMP-043: map_count with empty mapping is 0') :-
    gridmap_map_count([[r,g,r]], [], Count),
    Count = 0.

% --- combined ---

test('AC-GMP-044: remap then invert_map round-trips') :-
% Apply [r-x,g-y], then invert the map and apply back.
    G = [[r,g,r],[g,b,g],[r,g,r]],
    Map = [r-x, g-y],
    gridmap_remap(G, Map, Mapped),
    gridmap_invert_map(Map, InvMap),
    gridmap_remap(Mapped, InvMap, Restored),
    Restored = [[r,g,r],[g,b,g],[r,g,r]].

:- end_tests(gridmap).
