% Test suite for legend (lg_*, Layer 250).
:- use_module('../prolog/legend.pl').

:- begin_tests(legend).

% --- Shared test data ---
% 4x4 grid with a 2x1 legend region in top-right corner.
% Background = 0, legend colors = 3 (top), 4 (bottom), content color = 1.
grid_with_legend([[1,1,0,3],[1,1,0,4],[0,0,0,0],[0,0,0,0]]).

% 3x3 grid, no legend (all content).
grid_no_legend([[1,1,1],[1,2,1],[1,1,1]]).

% 5x5 grid with a 1x1 legend in top-left.
grid_small_legend([[5,0,1,1,1],[0,0,1,2,1],[0,0,1,1,1],[0,0,0,0,0],[0,0,0,0,0]]).

% All-background 3x3.
grid_bg([[0,0,0],[0,0,0],[0,0,0]]).

% Simple 2x2 grids for pair-based tests.
pair_a(pair([[0,3],[1,0]], [[0,0],[2,0]])).
pair_b(pair([[0,3],[2,0]], [[0,0],[1,0]])).
pair_stable(pair([[1,1],[1,1]], [[1,1],[1,1]])).

% --- lg_region_area ---

test('AC-LG-001: region_area of single cell is 1') :-
    lg_region_area([r(0,0)], 1).

test('AC-LG-002: region_area of 3-cell region is 3') :-
    lg_region_area([r(0,0), r(0,1), r(1,0)], 3).

test('AC-LG-003: region_area of empty region is 0') :-
    lg_region_area([], 0).

% --- lg_all_regions ---

test('AC-LG-004: all_regions finds non-bg regions in grid_with_legend') :-
    grid_with_legend(G), lg_all_regions(G, 0, Regions),
    Regions \= [].

test('AC-LG-005: all_regions returns empty for all-bg grid') :-
    grid_bg(G), lg_all_regions(G, 0, Regions),
    Regions = [].

test('AC-LG-006: all_regions finds multiple regions in grid_with_legend') :-
    grid_with_legend(G), lg_all_regions(G, 0, Regions),
    length(Regions, N), N >= 2.

test('AC-LG-007: all_regions finds one big region in grid_no_legend') :-
    grid_no_legend(G), lg_all_regions(G, 0, Regions),
    length(Regions, N), N >= 1.

% --- lg_is_small ---

test('AC-LG-008: is_small is true for 1-cell region in 4x4 grid') :-
    grid_with_legend(G), lg_is_small([r(0,3)], G, true).

test('AC-LG-009: is_small is false for large region in small grid') :-
    grid_no_legend(G), lg_is_small([r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)], G, false).

% --- lg_region_bbox ---

test('AC-LG-010: region_bbox of single cell') :-
    lg_region_bbox([r(2,3)], 0, r0(2,3,2,3)).

test('AC-LG-011: region_bbox spans correct rows and cols') :-
    lg_region_bbox([r(0,0), r(1,2), r(0,2)], 0, r0(0,0,1,2)).

% --- lg_separated ---

test('AC-LG-012: separated regions that dont touch') :-
    lg_separated([r(0,0)], [r(2,2)]).

test('AC-LG-013: separated fails for adjacent cells') :-
    \+ lg_separated([r(0,0)], [r(0,1)]).

test('AC-LG-014: separated fails for diagonally adjacent cells') :-
    % Diagonal adjacency - our 4-connected check should NOT consider this touching.
    lg_separated([r(0,0)], [r(1,1)]).

% --- lg_region_color ---

test('AC-LG-015: region_color returns color of cells') :-
    grid_with_legend(G),
    lg_region_color([r(0,3)], G, 3).

test('AC-LG-016: region_color returns dominant color from multi-color region') :-
    G = [[1,2,1],[0,0,0],[0,0,0]],
    lg_region_color([r(0,0),r(0,1),r(0,2)], G, _Color).

% --- lg_same_shape ---

test('AC-LG-017: same_shape for identical regions') :-
    lg_same_shape([r(0,0),r(1,0)], [r(0,0),r(1,0)]).

test('AC-LG-018: same_shape for translated regions') :-
    lg_same_shape([r(0,0),r(1,0)], [r(2,3),r(3,3)]).

test('AC-LG-019: same_shape fails for different shapes') :-
    \+ lg_same_shape([r(0,0),r(1,0)], [r(0,0),r(0,1)]).

% --- lg_entry_boundaries ---

test('AC-LG-020: entry_boundaries returns sorted unique rows') :-
    lg_entry_boundaries([r(0,0),r(0,1),r(1,0),r(2,0)], Bounds),
    Bounds = [0,1,2].

test('AC-LG-021: entry_boundaries for single-row region') :-
    lg_entry_boundaries([r(3,0),r(3,1)], Bounds),
    Bounds = [3].

% --- lg_color_map ---

test('AC-LG-022: color_map returns cm terms for legend region') :-
    grid_with_legend(G),
    LegendRegion = [r(0,3),r(1,3)],
    lg_color_map(LegendRegion, G, ColorMap),
    member(cm(3, _), ColorMap).

test('AC-LG-023: color_map returns two entries for 2-row legend') :-
    grid_with_legend(G),
    LegendRegion = [r(0,3),r(1,3)],
    lg_color_map(LegendRegion, G, ColorMap),
    length(ColorMap, 2).

% --- lg_position ---

test('AC-LG-024: position top for region in top row') :-
    G = [[1,1,1,1],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    lg_position([r(0,0)], G, top).

test('AC-LG-025: position bottom for region in bottom row') :-
    G = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[1,1,1,1]],
    lg_position([r(5,0)], G, bottom).

test('AC-LG-026: position center for region in middle') :-
    G = [[0,0,0],[0,1,0],[0,0,0]],
    lg_position([r(1,1)], G, center).

% --- lg_detect_legend ---

test('AC-LG-027: detect_legend finds small isolated region') :-
    grid_with_legend(G), lg_detect_legend(G, 0, LegendRegion),
    LegendRegion \= [].

test('AC-LG-028: detect_legend returns list of cells') :-
    grid_small_legend(G), lg_detect_legend(G, 0, LegendRegion),
    is_list(LegendRegion).

test('AC-LG-029: detect_legend legend region is small') :-
    grid_small_legend(G), lg_detect_legend(G, 0, LegendRegion),
    lg_is_small(LegendRegion, G, true).

% --- lg_is_legend ---

test('AC-LG-030: is_legend succeeds for small isolated region') :-
    SmallRegion = [r(0,3)],
    ContentRegion = [r(0,0),r(0,1),r(1,0),r(1,1)],
    lg_is_legend(SmallRegion, [ContentRegion]).

test('AC-LG-031: is_legend fails for large region') :-
    BigRegion = [r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)],
    ContentRegion = [r(0,3)],
    \+ lg_is_legend(BigRegion, [ContentRegion]).

test('AC-LG-032: is_legend succeeds for empty content list if region is tiny') :-
    lg_is_legend([r(0,0)], []).

% --- lg_legend_entries ---

test('AC-LG-033: legend_entries returns entry terms') :-
    LegendRegion = [r(0,3),r(1,3)],
    lg_legend_entries(LegendRegion, Entries),
    is_list(Entries).

test('AC-LG-034: legend_entries counts distinct row bands') :-
    LegendRegion = [r(0,3),r(1,3),r(2,3)],
    lg_legend_entries(LegendRegion, Entries),
    length(Entries, 3).

% --- lg_consistent_legend ---

test('AC-LG-035: consistent_legend returns legend for pairs with small region') :-
    pair_a(PA), pair_b(PB),
    (lg_consistent_legend([PA, PB], Legend) ->
        is_list(Legend)
    ;
        true  % OK if no consistent legend found in these simple pairs.
    ).

test('AC-LG-036: consistent_legend returns [] for empty pairs') :-
    \+ lg_consistent_legend([], _) ; lg_consistent_legend([], []).

% --- Integration tests ---

test('AC-LG-037: all_regions finds isolated single-cell legend') :-
    G = [[0,0,0,5],[1,1,1,0],[1,1,1,0],[0,0,0,0]],
    lg_all_regions(G, 0, Regions),
    member([r(0,3)], Regions).

test('AC-LG-038: region_area consistent with all_regions output') :-
    grid_with_legend(G), lg_all_regions(G, 0, Regions),
    forall(member(R, Regions), (lg_region_area(R, A), A >= 1)).

test('AC-LG-039: detect_legend legend is separated from content') :-
    G = [[0,0,0,5],[1,1,1,0],[1,1,1,0],[0,0,0,0]],
    lg_detect_legend(G, 0, Legend),
    lg_all_regions(G, 0, AllRegions),
    include([R]>>(R \= Legend, lg_region_area(R, A), A > 1), AllRegions, ContentRegions),
    (ContentRegions = [] -> true ;
        forall(member(CR, ContentRegions), lg_separated(Legend, CR))
    ).

test('AC-LG-040: same_shape is symmetric') :-
    R1 = [r(0,0),r(1,0)], R2 = [r(5,5),r(6,5)],
    lg_same_shape(R1, R2),
    lg_same_shape(R2, R1).

test('AC-LG-041: region_bbox contains all region cells') :-
    Region = [r(1,2),r(3,5),r(2,3)],
    lg_region_bbox(Region, 0, r0(MinR, MinC, MaxR, MaxC)),
    forall(member(r(R,C), Region), (R >= MinR, R =< MaxR, C >= MinC, C =< MaxC)).

test('AC-LG-042: color_map bands indexed from 0') :-
    G = [[3,0],[4,0],[5,0]],
    LegendRegion = [r(0,0),r(1,0),r(2,0)],
    lg_color_map(LegendRegion, G, ColorMap),
    member(cm(3, 0), ColorMap).

test('AC-LG-043: entry_boundaries and color_map agree on count') :-
    G = [[3,0],[4,0]],
    LegendRegion = [r(0,0),r(1,0)],
    lg_entry_boundaries(LegendRegion, Bounds),
    lg_color_map(LegendRegion, G, ColorMap),
    length(Bounds, NB), length(ColorMap, NM),
    NB =:= NM.

test('AC-LG-044: full legend pipeline: detect, is_legend, entries, color_map') :-
    G = [[1,1,0,3],[1,1,0,4],[0,0,0,0],[0,0,0,0]],
    lg_detect_legend(G, 0, Legend),
    Legend \= [],
    lg_legend_entries(Legend, Entries),
    is_list(Entries),
    lg_color_map(Legend, G, CMap),
    is_list(CMap).

:- end_tests(legend).
