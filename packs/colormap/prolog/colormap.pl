% colormap.pl - Layer 126: Color Lookup Table and Palette Substitution (cm_* prefix).
% General-purpose predicates for mapping, substituting, and analyzing color values in grids.
:- module(colormap, [
    colormap_apply/3, colormap_apply_default/4,
    colormap_invert/3, colormap_compose/3,
    colormap_from_grids/3, colormap_identity/2,
    colormap_remap/3, colormap_remap_list/3,
    colormap_palette/2, colormap_used/2,
    colormap_has_key/2, colormap_lookup/3,
    colormap_restrict/3, colormap_expand/4
]).
% Import list utilities for palette collection and map traversal.
% sort/2 is a SWI-Prolog built-in and is not imported from any library.
:- use_module(library(lists), [member/2, memberchk/2, nth0/3, append/3]).
% Import apply for row-level transforms.
:- use_module(library(apply), [maplist/3]).

% colormap_apply(+Map, +Grid, -Grid2): substitute each cell value using Map (list of Old-New pairs).
% Cells with no matching key are left unchanged.
colormap_apply(Map, Grid, Grid2) :-
% Apply per-row substitution using maplist/3 with a row helper capturing Map.
    maplist(colormap_apply_row_(Map), Grid, Grid2).
% Per-row helper applies substitution to every cell.
colormap_apply_row_(Map, Row, Row2) :-
    maplist(colormap_apply_cell_(Map), Row, Row2).
% Per-cell substitution: replace via memberchk lookup; preserve on miss.
colormap_apply_cell_(Map, V, V2) :-
    (memberchk(V-V2, Map) -> true ; V2 = V).

% colormap_apply_default(+Map, +Bg, +Grid, -Grid2): substitute cells; replace unmatched with Bg.
colormap_apply_default(Map, Bg, Grid, Grid2) :-
% Apply per-row substitution with default using maplist/3.
    maplist(colormap_apply_default_row_(Map, Bg), Grid, Grid2).
% Per-row helper applies substitution with default to every cell.
colormap_apply_default_row_(Map, Bg, Row, Row2) :-
    maplist(colormap_apply_default_cell_(Map, Bg), Row, Row2).
% Per-cell substitution with default: memberchk lookup or Bg.
colormap_apply_default_cell_(Map, Bg, V, V2) :-
    (memberchk(V-V2, Map) -> true ; V2 = Bg).

% colormap_invert(+Map, +Grid, -Grid2): apply the inverse of Map (swap Old-New to New-Old).
colormap_invert(Map, Grid, Grid2) :-
% Build the inverse map by swapping key-value in every pair.
    findall(N-O, member(O-N, Map), InvMap),
    colormap_apply(InvMap, Grid, Grid2).

% colormap_compose(+MapA, +MapB, -MapAB): compose two maps: MapAB[k] = MapB[MapA[k]].
colormap_compose(MapA, MapB, MapAB) :-
% For each entry in MapA, look up the intermediate value in MapB.
    findall(K-V2, (
        member(K-V1, MapA),
        (memberchk(V1-V2, MapB) -> true ; V2 = V1)
    ), MapAB).

% colormap_from_grids(+GridA, +GridB, -Map): build a map from cell correspondences.
% Collects V_A-V_B pairs from matching positions and deduplicates.
colormap_from_grids(GridA, GridB, Map) :-
% Collect all position-aligned value pairs from both grids.
    findall(VA-VB, (
        nth0(R, GridA, RowA), nth0(R, GridB, RowB),
        nth0(C, RowA, VA), nth0(C, RowB, VB)
    ), Pairs0),
    sort(Pairs0, Map).

% colormap_identity(+Palette, -Map): build the identity map V-V for every value in Palette.
colormap_identity(Palette, Map) :-
% Each palette value maps to itself.
    findall(V-V, member(V, Palette), Map).

% colormap_remap(+OldVals, +NewVals, -Map): build a map from parallel old/new value lists.
% OldVals and NewVals must have the same length.
colormap_remap(OldVals, NewVals, Map) :-
% Pair corresponding elements from the two lists.
    findall(O-N, (nth0(I, OldVals, O), nth0(I, NewVals, N)), Map).

% colormap_remap_list(+Map, +List, -List2): apply Map to a 1D list (not a grid).
% Cells with no matching key are left unchanged.
colormap_remap_list(Map, List, List2) :-
% Apply per-element substitution using maplist/3.
    maplist(colormap_apply_cell_(Map), List, List2).

% colormap_palette(+Map, -Palette): sorted list of all source (key) values in Map.
colormap_palette(Map, Palette) :-
% Collect all keys from the map and sort to deduplicate.
    findall(K, member(K-_, Map), Ks),
    sort(Ks, Palette).

% colormap_used(+Grid, -UsedVals): sorted list of all distinct values actually used in Grid.
colormap_used(Grid, UsedVals) :-
% Collect all cell values from the grid then sort to deduplicate.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
    sort(Vs, UsedVals).

% colormap_has_key(+Map, +K): succeeds iff K appears as a key in Map.
colormap_has_key(Map, K) :-
% memberchk provides deterministic first-match lookup.
    memberchk(K-_, Map).

% colormap_lookup(+Map, +K, -V): look up the value for key K in Map.
% Fails if K is not present.
colormap_lookup(Map, K, V) :-
% memberchk is deterministic and cuts on first match.
    memberchk(K-V, Map).

% colormap_restrict(+Map, +Keys, -Map2): keep only entries whose key is in Keys.
colormap_restrict(Map, Keys, Map2) :-
% Filter map entries using memberchk against the key set.
    findall(K-V, (member(K-V, Map), memberchk(K, Keys)), Map2).

% colormap_expand(+Map, +Bg, +Palette, -Map2): extend Map with K-Bg entries for each
% palette value K that has no entry in Map.
colormap_expand(Map, Bg, Palette, Map2) :-
% Find palette keys missing from Map and add them with the default Bg value.
    findall(K-Bg, (member(K, Palette), \+ memberchk(K-_, Map)), NewEntries),
    append(Map, NewEntries, Map2).
