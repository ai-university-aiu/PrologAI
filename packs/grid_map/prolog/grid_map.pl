:- module(grid_map, [
    grid_map_remap/3,
    grid_map_swap/4,
    grid_map_replace/4,
    grid_map_merge/4,
    grid_map_normalize/3,
    grid_map_palette/3,
    grid_map_recolor_fg/4,
    grid_map_mask_color/4,
    grid_map_invert/3,
    grid_map_cycle/4,
    grid_map_build_map/4,
    grid_map_invert_map/2,
    grid_map_compose_maps/3,
    grid_map_map_count/3
]).
% gridmap.pl - Layer 231: Grid Color Mapping (gmp_* prefix).
% Fourteen predicates for remapping, swapping, replacing, merging, normalizing,
% and composing color mappings on symbolic grids.
% grid_map_remap/swap/replace/merge: apply atomic color substitutions.
% grid_map_normalize/palette: canonical labeling and palette extraction.
% grid_map_recolor_fg/mask_color: coarsen all non-bg or isolate one color.
% grid_map_invert/cycle: palette-based permutations.
% grid_map_build_map/invert_map/compose_maps/map_count: mapping utilities.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, nth1/3, append/3]).

% --- PRIVATE HELPERS ---

% grid_map_cell_map_(+V, +Mapping, -V2): look up V in Mapping; V2 = V if not found.
grid_map_cell_map_(V, Mapping, V2) :-
% Try the mapping first; fall back to identity if no entry found.
    (member(V-V2, Mapping) -> true ; V2 = V).

% grid_map_apply_mapping_(+Grid, +Mapping, -Result): apply cell mapping to entire grid.
grid_map_apply_mapping_(Grid, Mapping, Result) :-
% Build each output row by applying the mapping to every cell.
    findall(NewRow,
        (member(GRow, Grid),
         findall(V2, (member(V, GRow), grid_map_cell_map_(V, Mapping, V2)), NewRow)),
        Result).

% grid_map_unique_ordered_(+List, -Unique): deduplicate List preserving first-occurrence order.
grid_map_unique_ordered_(List, Unique) :-
    grid_map_unique_ordered_(List, [], Unique).

% Base case: empty input yields empty output.
grid_map_unique_ordered_([], _, []).
grid_map_unique_ordered_([H|T], Seen, Result) :-
% If H already seen, skip it; otherwise prepend H and mark as seen.
    (member(H, Seen) ->
        grid_map_unique_ordered_(T, Seen, Result)
    ;
        Result = [H|Rest],
        grid_map_unique_ordered_(T, [H|Seen], Rest)
    ).

% grid_map_rank_mapping_(+Palette, +StartRank, -Mapping): assign integer ranks starting at StartRank.
grid_map_rank_mapping_([], _, []).
grid_map_rank_mapping_([C|Rest], N, [C-N|More]) :-
    N1 is N + 1,
    grid_map_rank_mapping_(Rest, N1, More).

% grid_map_build_map_cells_(+Row1, +Row2, +Bg, -Pairs): collect From-To pairs from one row.
grid_map_build_map_cells_([], [], _, []).
grid_map_build_map_cells_([V1|T1], [V2|T2], Bg, Pairs) :-
% Include pair only when both are non-bg and differ.
    (V1 \= Bg, V2 \= Bg, V1 \= V2 ->
        Pairs = [V1-V2|Rest]
    ;
        Pairs = Rest
    ),
    grid_map_build_map_cells_(T1, T2, Bg, Rest).

% grid_map_build_map_rows_(+Rows1, +Rows2, +Bg, -Pairs): collect From-To pairs row by row.
grid_map_build_map_rows_([], [], _, []).
grid_map_build_map_rows_([R1|Rest1], [R2|Rest2], Bg, Pairs) :-
% Collect pairs from this row pair.
    grid_map_build_map_cells_(R1, R2, Bg, RowPairs),
% Recurse over remaining rows.
    grid_map_build_map_rows_(Rest1, Rest2, Bg, RestPairs),
    append(RowPairs, RestPairs, Pairs).

% --- PUBLIC PREDICATES ---

% grid_map_remap(+Grid, +Mapping, -Result)
% Apply a list of From-To color pairs to every cell in Grid.
% Cells whose color does not appear as a From key are left unchanged.
grid_map_remap(Grid, Mapping, Result) :-
% Delegate to the shared apply helper.
    grid_map_apply_mapping_(Grid, Mapping, Result).

% grid_map_swap(+Grid, +C1, +C2, -Result)
% Swap all occurrences of C1 and C2 throughout Grid.
% Cells of other colors are unchanged.
grid_map_swap(Grid, C1, C2, Result) :-
% Build a two-entry bidirectional mapping then apply.
    grid_map_apply_mapping_(Grid, [C1-C2, C2-C1], Result).

% grid_map_replace(+Grid, +From, +To, -Result)
% Replace every occurrence of From with To in Grid.
% Cells of other colors are unchanged.
grid_map_replace(Grid, From, To, Result) :-
% Build a one-entry mapping then apply.
    grid_map_apply_mapping_(Grid, [From-To], Result).

% grid_map_merge(+Grid, +Colors, +To, -Result)
% Replace every cell whose color is in the list Colors with To.
% Cells of other colors are unchanged.
grid_map_merge(Grid, Colors, To, Result) :-
% Build one mapping entry per color to merge.
    findall(C-To, member(C, Colors), Mapping),
    grid_map_apply_mapping_(Grid, Mapping, Result).

% grid_map_normalize(+Grid, +BgColor, -Normalized)
% Assign integer rank labels (1, 2, 3, ...) to non-BgColor cells in the
% order they first appear (row-major). BgColor cells remain BgColor.
grid_map_normalize(Grid, BgColor, Normalized) :-
% Collect all non-bg colors in row-major order.
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), AllColors),
% Deduplicate preserving first-occurrence order.
    grid_map_unique_ordered_(AllColors, Palette),
% Assign rank 1, 2, 3, ... to each palette color.
    grid_map_rank_mapping_(Palette, 1, Mapping),
    grid_map_apply_mapping_(Grid, Mapping, Normalized).

% grid_map_palette(+Grid, +BgColor, -Palette)
% Return the ordered list of distinct non-BgColor colors in first-occurrence
% (row-major) order.
grid_map_palette(Grid, BgColor, Palette) :-
% Collect all non-bg colors row-major.
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), AllColors),
% Deduplicate preserving first-occurrence order.
    grid_map_unique_ordered_(AllColors, Palette).

% grid_map_recolor_fg(+Grid, +BgColor, +FgColor, -Result)
% Replace every non-BgColor cell with FgColor. BgColor cells are unchanged.
grid_map_recolor_fg(Grid, BgColor, FgColor, Result) :-
% For each cell: bg stays bg; anything else becomes FgColor.
    findall(NewRow,
        (member(GRow, Grid),
         findall(V2, (member(V, GRow),
                      (V = BgColor -> V2 = BgColor ; V2 = FgColor)), NewRow)),
        Result).

% grid_map_mask_color(+Grid, +Color, +BgColor, -Result)
% Keep cells of Color; replace all other cells with BgColor.
grid_map_mask_color(Grid, Color, BgColor, Result) :-
% For each cell: Color stays; everything else becomes BgColor.
    findall(NewRow,
        (member(GRow, Grid),
         findall(V2, (member(V, GRow),
                      (V = Color -> V2 = Color ; V2 = BgColor)), NewRow)),
        Result).

% grid_map_invert(+Grid, +Palette, -Result)
% Given Palette = [c1, c2, ..., cn], replace c_i with c_(n+1-i) for all i.
% Reverses the order of color assignments. Cells not in Palette are unchanged.
grid_map_invert(Grid, Palette, Result) :-
% Count palette entries.
    length(Palette, N),
% Build reversed mapping: c_i -> c_(N+1-i).
    findall(C1-C2,
        (nth1(I, Palette, C1),
         RI is N + 1 - I,
         nth1(RI, Palette, C2)),
        Mapping),
    grid_map_apply_mapping_(Grid, Mapping, Result).

% grid_map_cycle(+Grid, +Palette, +N, -Result)
% Cyclically advance each cell's palette index by N positions (mod |Palette|).
% Cells not in Palette are unchanged.
grid_map_cycle(Grid, Palette, N, Result) :-
% Count palette entries.
    length(Palette, M),
% Build cyclic shift mapping: c_i -> c_((i+N-1 mod M)+1).
    findall(C1-C2,
        (nth1(I, Palette, C1),
         J is (I + N - 1) mod M + 1,
         nth1(J, Palette, C2)),
        Mapping),
    grid_map_apply_mapping_(Grid, Mapping, Result).

% grid_map_build_map(+Grid1, +Grid2, +BgColor, -Mapping)
% Derive a From-To color mapping from two same-sized grids.
% For each position where both grids have non-BgColor values and the values differ,
% record From-To. Duplicates are removed preserving first-occurrence order.
grid_map_build_map(Grid1, Grid2, BgColor, Mapping) :-
% Walk both grids row by row to collect all From-To pairs.
    grid_map_build_map_rows_(Grid1, Grid2, BgColor, AllPairs),
% Remove duplicates preserving order.
    grid_map_unique_ordered_(AllPairs, Mapping).

% grid_map_invert_map(+Map, -InvMap)
% Reverse each From-To pair to produce To-From.
grid_map_invert_map(Map, InvMap) :-
% Swap direction of every pair.
    findall(To-From, member(From-To, Map), InvMap).

% grid_map_compose_maps(+Map1, +Map2, -Composed)
% Chain two mappings: for each From-Mid in Map1 where Mid-To exists in Map2,
% produce From-To in Composed.
grid_map_compose_maps(Map1, Map2, Composed) :-
% Find all valid two-step paths through the two maps.
    findall(From-To,
        (member(From-Mid, Map1),
         member(Mid-To, Map2)),
        Composed).

% grid_map_map_count(+Grid, +Mapping, -Count)
% Count cells in Grid whose color appears as a From key in Mapping.
grid_map_map_count(Grid, Mapping, Count) :-
% Collect every cell that has a mapping entry.
    findall(V,
        (member(Row, Grid), member(V, Row),
         member(V-_, Mapping)),
        Cells),
    length(Cells, Count).
