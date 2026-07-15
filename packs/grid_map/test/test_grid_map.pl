:- use_module('../prolog/grid_map').

% Test grids:
%   pal3 = [[r,g,r],[g,b,g],[r,g,r]]  BgColor=b; palette=[r,g]
%   two  = [[r,b,r],[b,r,b]]           BgColor=b; palette=[r]
%   abc  = [[a,b,c],[d,e,f]]           BgColor=z; palette=[a,b,c,d,e,f]
%   ab3  = [[b,b,b],[b,b,b],[b,b,b]]  all-bg
%   mono = [[x,x],[x,x]]               no bg; palette=[x]
%   g12  = [[r,g],[b,r]]               BgColor=z; two colors r and g

:- begin_tests(grid_map).

% --- grid_map_remap ---

test('AC-GMP-001: remap two colors on pal3') :-
    grid_map_remap([[r,g,r],[g,b,g],[r,g,r]], [r-x, g-y], R),
    R = [[x,y,x],[y,b,y],[x,y,x]].

test('AC-GMP-002: remap with partial match leaves unmatched unchanged') :-
    grid_map_remap([[r,g,r],[g,b,g],[r,g,r]], [r-x], R),
    R = [[x,g,x],[g,b,g],[x,g,x]].

test('AC-GMP-003: remap with empty mapping is identity') :-
    grid_map_remap([[a,b],[c,d]], [], R),
    R = [[a,b],[c,d]].

% --- grid_map_swap ---

test('AC-GMP-004: swap r and g on pal3') :-
    grid_map_swap([[r,g,r],[g,b,g],[r,g,r]], r, g, R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-005: swap r and b on two') :-
    grid_map_swap([[r,b,r],[b,r,b]], r, b, R),
    R = [[b,r,b],[r,b,r]].

test('AC-GMP-006: swap when color absent leaves grid unchanged') :-
    grid_map_swap([[a,a],[a,a]], a, z, R),
    R = [[z,z],[z,z]].

% --- grid_map_replace ---

test('AC-GMP-007: replace r with x on pal3') :-
    grid_map_replace([[r,g,r],[g,b,g],[r,g,r]], r, x, R),
    R = [[x,g,x],[g,b,g],[x,g,x]].

test('AC-GMP-008: replace b with x on two') :-
    grid_map_replace([[r,b,r],[b,r,b]], b, x, R),
    R = [[r,x,r],[x,r,x]].

test('AC-GMP-009: replace absent color is identity') :-
    grid_map_replace([[a,b],[c,d]], z, x, R),
    R = [[a,b],[c,d]].

% --- grid_map_merge ---

test('AC-GMP-010: merge [r,g] into x on pal3') :-
    grid_map_merge([[r,g,r],[g,b,g],[r,g,r]], [r,g], x, R),
    R = [[x,x,x],[x,b,x],[x,x,x]].

test('AC-GMP-011: merge single color is like replace') :-
    grid_map_merge([[r,b,r],[b,r,b]], [b], x, R),
    R = [[r,x,r],[x,r,x]].

test('AC-GMP-012: merge all colors into z on abc') :-
    grid_map_merge([[a,b,c],[d,e,f]], [a,b,c,d,e,f], z, R),
    R = [[z,z,z],[z,z,z]].

% --- grid_map_normalize ---

test('AC-GMP-013: normalize pal3 with bg=b') :-
    grid_map_normalize([[r,g,r],[g,b,g],[r,g,r]], b, N),
    N = [[1,2,1],[2,b,2],[1,2,1]].

test('AC-GMP-014: normalize all-bg grid is identity') :-
    grid_map_normalize([[b,b,b],[b,b,b]], b, N),
    N = [[b,b,b],[b,b,b]].

test('AC-GMP-015: normalize abc assigns ranks in row-major order') :-
    grid_map_normalize([[a,b,c],[d,e,f]], z, N),
    N = [[1,2,3],[4,5,6]].

% --- grid_map_palette ---

test('AC-GMP-016: palette of pal3 with bg=b is [r,g]') :-
    grid_map_palette([[r,g,r],[g,b,g],[r,g,r]], b, P),
    P = [r,g].

test('AC-GMP-017: palette of all-bg grid is empty') :-
    grid_map_palette([[b,b,b],[b,b,b]], b, P),
    P = [].

test('AC-GMP-018: palette of abc with bg=z is [a,b,c,d,e,f]') :-
    grid_map_palette([[a,b,c],[d,e,f]], z, P),
    P = [a,b,c,d,e,f].

% --- grid_map_recolor_fg ---

test('AC-GMP-019: recolor_fg pal3 bg=b fg=x replaces r and g') :-
    grid_map_recolor_fg([[r,g,r],[g,b,g],[r,g,r]], b, x, R),
    R = [[x,x,x],[x,b,x],[x,x,x]].

test('AC-GMP-020: recolor_fg on all-bg grid is identity') :-
    grid_map_recolor_fg([[b,b],[b,b]], b, x, R),
    R = [[b,b],[b,b]].

test('AC-GMP-021: recolor_fg on two bg=b fg=x replaces r only') :-
    grid_map_recolor_fg([[r,b,r],[b,r,b]], b, x, R),
    R = [[x,b,x],[b,x,b]].

% --- grid_map_mask_color ---

test('AC-GMP-022: mask_color keep r in pal3 bg=b') :-
    grid_map_mask_color([[r,g,r],[g,b,g],[r,g,r]], r, b, R),
    R = [[r,b,r],[b,b,b],[r,b,r]].

test('AC-GMP-023: mask_color keep g in pal3 bg=b') :-
    grid_map_mask_color([[r,g,r],[g,b,g],[r,g,r]], g, b, R),
    R = [[b,g,b],[g,b,g],[b,g,b]].

test('AC-GMP-024: mask_color with absent color produces all-bg') :-
    grid_map_mask_color([[a,b],[c,d]], z, x, R),
    R = [[x,x],[x,x]].

% --- grid_map_invert ---

test('AC-GMP-025: invert pal3 with palette [r,g] swaps r and g') :-
    grid_map_invert([[r,g,r],[g,b,g],[r,g,r]], [r,g], R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-026: invert with 3-color palette reverses order') :-
    grid_map_invert([[a,b,c],[c,b,a]], [a,b,c], R),
    R = [[c,b,a],[a,b,c]].

test('AC-GMP-027: invert with single-color palette is identity') :-
    grid_map_invert([[x,x],[x,x]], [x], R),
    R = [[x,x],[x,x]].

% --- grid_map_cycle ---

test('AC-GMP-028: cycle two on [r,b] by 1 swaps') :-
    grid_map_cycle([[r,b,r],[b,r,b]], [r,b], 1, R),
    R = [[b,r,b],[r,b,r]].

test('AC-GMP-029: cycle pal3 palette [r,g] by 1 rotates') :-
    grid_map_cycle([[r,g,r],[g,b,g],[r,g,r]], [r,g], 1, R),
    R = [[g,r,g],[r,b,r],[g,r,g]].

test('AC-GMP-030: cycle by 0 is identity') :-
    grid_map_cycle([[a,b,c]], [a,b,c], 0, R),
    R = [[a,b,c]].

test('AC-GMP-031: cycle by len is identity (full wrap)') :-
    grid_map_cycle([[a,b,c]], [a,b,c], 3, R),
    R = [[a,b,c]].

% --- grid_map_build_map ---

test('AC-GMP-032: build_map from [[r,g],[b,r]] to [[x,y],[z,x]] bg=q') :-
    grid_map_build_map([[r,g],[b,r]], [[x,y],[z,x]], q, M),
    M = [r-x, g-y, b-z].

test('AC-GMP-033: build_map skips bg cells (bg=b)') :-
    grid_map_build_map([[r,b],[b,g]], [[x,b],[b,y]], b, M),
    M = [r-x, g-y].

test('AC-GMP-034: build_map skips equal values') :-
    grid_map_build_map([[r,g]], [[r,x]], z, M),
    M = [g-x].

% --- grid_map_invert_map ---

test('AC-GMP-035: invert_map reverses From-To pairs') :-
    grid_map_invert_map([r-x, g-y, b-z], InvM),
    InvM = [x-r, y-g, z-b].

test('AC-GMP-036: invert_map of empty is empty') :-
    grid_map_invert_map([], InvM),
    InvM = [].

test('AC-GMP-037: double invert_map is identity') :-
    grid_map_invert_map([a-b, c-d], M1),
    grid_map_invert_map(M1, M2),
    M2 = [a-b, c-d].

% --- grid_map_compose_maps ---

test('AC-GMP-038: compose [r-g,g-b] with [g-x,b-y]') :-
    grid_map_compose_maps([r-g, g-b], [g-x, b-y], C),
    C = [r-x, g-y].

test('AC-GMP-039: compose where no mid matches gives empty') :-
    grid_map_compose_maps([r-g], [x-y], C),
    C = [].

test('AC-GMP-040: compose empty first map is empty') :-
    grid_map_compose_maps([], [a-b], C),
    C = [].

% --- grid_map_map_count ---

test('AC-GMP-041: map_count counts r cells in pal3 with [r-x]') :-
    grid_map_map_count([[r,g,r],[g,b,g],[r,g,r]], [r-x], Count),
    Count = 4.

test('AC-GMP-042: map_count with [r-x,g-y] counts both') :-
    grid_map_map_count([[r,g,r],[g,b,g],[r,g,r]], [r-x, g-y], Count),
    Count = 8.

test('AC-GMP-043: map_count with empty mapping is 0') :-
    grid_map_map_count([[r,g,r]], [], Count),
    Count = 0.

% --- combined ---

test('AC-GMP-044: remap then invert_map round-trips') :-
% Apply [r-x,g-y], then invert the map and apply back.
    G = [[r,g,r],[g,b,g],[r,g,r]],
    Map = [r-x, g-y],
    grid_map_remap(G, Map, Mapped),
    grid_map_invert_map(Map, InvMap),
    grid_map_remap(Mapped, InvMap, Restored),
    Restored = [[r,g,r],[g,b,g],[r,g,r]].

:- end_tests(grid_map).
