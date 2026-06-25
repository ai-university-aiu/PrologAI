% remap - Layer 77: color remapping, palette manipulation, and grid recoloring.
% Module remap exports 14 rm_* predicates covering single-value replacement,
% two-color swapping, map-based recoloring, palette normalization, color
% inversion, conditional recoloring, and background-relative operations.
:- module(remap, [
    % Replace every occurrence of one value with another.
    rm_replace/4,
    % Swap two values everywhere in a grid.
    rm_swap/4,
    % Apply a color substitution map (identity for unmapped values).
    rm_apply_map/3,
    % Apply a map only to cells matching a specific current value.
    rm_apply_map_to/4,
    % Invert a color substitution map (swap keys and values).
    rm_invert_map/2,
    % Compose two color substitution maps (apply first then second).
    rm_compose_maps/3,
    % Normalize all distinct values to consecutive integers starting from 1.
    rm_normalize/2,
    % Shift all cell values by an integer offset.
    rm_shift/3,
    % Clamp all cell values to [Lo,Hi]; values outside are set to the nearest bound.
    rm_clamp/4,
    % Recolor cells matching a predicate using a recoloring goal.
    rm_conditional/4,
    % Replace all non-background values with a single foreground value.
    rm_binarize/4,
    % Remap a specific background value to a new background value.
    rm_remap_bg/4,
    % Extract the palette (sorted list of distinct values) from a grid.
    rm_palette/2,
    % Map each value in the palette to a new value using a parallel list.
    rm_reindex/3
]).

% Load member/2 for map lookup and palette collection.
:- use_module(library(lists), [member/2]).
% Load maplist/2, maplist/3 for row and cell iteration.
:- use_module(library(apply), [maplist/2, maplist/3]).

% rm_replace(+Grid, +Old, +New, -Grid2)
% Grid2 is Grid with every occurrence of Old replaced by New.
rm_replace(Grid, Old, New, Grid2) :-
    % Map replacement over every row and every cell.
    maplist(rm_replace_row_(Old, New), Grid, Grid2).

% rm_replace_row_(+Old, +New, +Row, -Row2): replace in one row.
rm_replace_row_(Old, New, Row, Row2) :-
    % Map replacement over every cell in the row.
    maplist(rm_replace_cell_(Old, New), Row, Row2).

% rm_replace_cell_(+Old, +New, +Cell, -Cell2): replace cell value if it matches Old.
rm_replace_cell_(Old, New, Cell, Cell2) :-
    % If cell equals Old, use New; otherwise keep Cell unchanged.
    (Cell == Old -> Cell2 = New ; Cell2 = Cell).

% rm_swap(+Grid, +A, +B, -Grid2)
% Grid2 is Grid with every A replaced by B and every B replaced by A.
rm_swap(Grid, A, B, Grid2) :-
    % Map swap over every row.
    maplist(rm_swap_row_(A, B), Grid, Grid2).

% rm_swap_row_(+A, +B, +Row, -Row2): swap in one row.
rm_swap_row_(A, B, Row, Row2) :-
    % Map swap over every cell in the row.
    maplist(rm_swap_cell_(A, B), Row, Row2).

% rm_swap_cell_(+A, +B, +Cell, -Cell2): swap A<->B in a single cell.
rm_swap_cell_(A, B, Cell, Cell2) :-
    % Cell is A: swap to B.
    (Cell == A -> Cell2 = B
    % Cell is B: swap to A.
    ; Cell == B -> Cell2 = A
    % Cell is neither: keep unchanged.
    ; Cell2 = Cell).

% rm_apply_map(+Map, +Grid, -Grid2)
% Apply Map (list of Old-New pairs) to every cell; unmapped cells are unchanged.
% Map is a list of Key-Value pairs: [old1-new1, old2-new2, ...].
rm_apply_map(Map, Grid, Grid2) :-
    % Map application over every row.
    maplist(rm_apply_map_row_(Map), Grid, Grid2).

% rm_apply_map_row_(+Map, +Row, -Row2): apply map to one row.
rm_apply_map_row_(Map, Row, Row2) :-
    % Apply map to every cell.
    maplist(rm_lookup_(Map), Row, Row2).

% rm_lookup_(+Map, +Cell, -Cell2): look up Cell in Map or keep unchanged.
rm_lookup_(Map, Cell, Cell2) :-
    % Search map for an entry matching Cell.
    (member(Cell-New, Map) -> Cell2 = New ; Cell2 = Cell).

% rm_apply_map_to(+Map, +Val, +Grid, -Grid2)
% Apply Map only to cells whose current value equals Val; other cells unchanged.
rm_apply_map_to(Map, Val, Grid, Grid2) :-
    % Map conditional application over every row.
    maplist(rm_apply_map_to_row_(Map, Val), Grid, Grid2).

% rm_apply_map_to_row_(+Map, +Val, +Row, -Row2): apply map only to Val cells.
rm_apply_map_to_row_(Map, Val, Row, Row2) :-
    % Apply selective replacement over every cell.
    maplist(rm_apply_map_to_cell_(Map, Val), Row, Row2).

% rm_apply_map_to_cell_(+Map, +Val, +Cell, -Cell2): apply map only if Cell = Val.
rm_apply_map_to_cell_(Map, Val, Cell, Cell2) :-
    % Only remap cells that have the target value.
    (Cell == Val
    -> (member(Cell-New, Map) -> Cell2 = New ; Cell2 = Cell)
    ;  Cell2 = Cell).

% rm_invert_map(+Map, -Inverted)
% Inverted has keys and values of Map swapped.
% Map is a list of Key-Value pairs; Inverted is a list of Value-Key pairs.
rm_invert_map(Map, Inverted) :-
    % Swap each pair.
    maplist([K-V, V-K]>>true, Map, Inverted).

% rm_compose_maps(+Map1, +Map2, -Composed)
% Composed applies Map1 first, then Map2, to a single value.
% For each Key-V1 in Map1, look up V1 in Map2 to get V2; result is Key-V2.
rm_compose_maps(Map1, Map2, Composed) :-
    % Build composed pair for each entry in Map1.
    maplist(rm_compose_pair_(Map2), Map1, Composed).

% rm_compose_pair_(+Map2, +K-V1, -K-V2): apply Map2 to V1.
rm_compose_pair_(Map2, K-V1, K-V2) :-
    % Look up V1 in Map2; use V1 itself if not found (identity fallback).
    (member(V1-V2, Map2) -> true ; V2 = V1).

% rm_normalize(+Grid, -Grid2)
% Replace the i-th distinct value (in sort order) with integer i.
% The mapping is: sort(distinct values), nth1 index gives new value.
rm_normalize(Grid, Grid2) :-
    % Collect all cell values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    % Get sorted distinct values.
    sort(Vals, Distinct),
    % Build map: each distinct value -> 1-based index.
    rm_build_index_map_(Distinct, 1, Map),
    % Apply the normalization map.
    rm_apply_map(Map, Grid, Grid2).

% rm_build_index_map_(+Values, +I, -Map): build Key-I pairs for each value.
rm_build_index_map_([], _I, []).
rm_build_index_map_([V|Vs], I, [V-I|Map]) :-
    % Increment index for next value.
    I1 is I + 1,
    % Recurse for remaining values.
    rm_build_index_map_(Vs, I1, Map).

% rm_shift(+Grid, +Delta, -Grid2)
% Add Delta to every cell value.
rm_shift(Grid, Delta, Grid2) :-
    % Apply shift over every row.
    maplist(rm_shift_row_(Delta), Grid, Grid2).

% rm_shift_row_(+Delta, +Row, -Row2): shift every cell in a row.
rm_shift_row_(Delta, Row, Row2) :-
    % Compute new value for each cell.
    maplist([Cell, Cell2]>>(Cell2 is Cell + Delta), Row, Row2).

% rm_clamp(+Grid, +Lo, +Hi, -Grid2)
% Clamp every cell value to [Lo, Hi]: values below Lo become Lo, above Hi become Hi.
rm_clamp(Grid, Lo, Hi, Grid2) :-
    % Apply clamping over every row.
    maplist(rm_clamp_row_(Lo, Hi), Grid, Grid2).

% rm_clamp_row_(+Lo, +Hi, +Row, -Row2): clamp every cell in a row.
rm_clamp_row_(Lo, Hi, Row, Row2) :-
    % Clamp each cell value.
    maplist(rm_clamp_cell_(Lo, Hi), Row, Row2).

% rm_clamp_cell_(+Lo, +Hi, +Cell, -Cell2): clamp a single cell value.
rm_clamp_cell_(Lo, Hi, Cell, Cell2) :-
    % Apply lower bound.
    (Cell < Lo -> Cell2 = Lo
    % Apply upper bound.
    ; Cell > Hi -> Cell2 = Hi
    % Value is in range: keep unchanged.
    ; Cell2 = Cell).

% rm_conditional(+Goal, +Grid, +Bg, -Grid2)
% For each cell: if call(Goal, Cell) succeeds, set to Bg; else keep Cell.
% Goal is a 1-argument predicate: call(Goal, Cell) succeeds for cells to recolor.
:- meta_predicate rm_conditional(1, +, +, -).
rm_conditional(Goal, Grid, Bg, Grid2) :-
    % Apply conditional recoloring over every row.
    maplist(rm_conditional_row_(Goal, Bg), Grid, Grid2).

% rm_conditional_row_(+Goal, +Bg, +Row, -Row2): apply conditional to one row.
rm_conditional_row_(Goal, Bg, Row, Row2) :-
    % Apply conditional to each cell.
    maplist(rm_conditional_cell_(Goal, Bg), Row, Row2).

% rm_conditional_cell_(+Goal, +Bg, +Cell, -Cell2): recolor cell if Goal succeeds.
rm_conditional_cell_(Goal, Bg, Cell, Cell2) :-
    % If Goal holds for this cell, replace with Bg; else keep unchanged.
    (call(Goal, Cell) -> Cell2 = Bg ; Cell2 = Cell).

% rm_binarize(+Grid, +Bg, +Fg, -Grid2)
% Replace every non-Bg cell with Fg; Bg cells remain Bg.
rm_binarize(Grid, Bg, Fg, Grid2) :-
    % Apply binarization over every row.
    maplist(rm_binarize_row_(Bg, Fg), Grid, Grid2).

% rm_binarize_row_(+Bg, +Fg, +Row, -Row2): binarize one row.
rm_binarize_row_(Bg, Fg, Row, Row2) :-
    % Binarize each cell.
    maplist(rm_binarize_cell_(Bg, Fg), Row, Row2).

% rm_binarize_cell_(+Bg, +Fg, +Cell, -Cell2): keep Bg or set to Fg.
rm_binarize_cell_(Bg, Fg, Cell, Cell2) :-
    % If cell is background, keep it; otherwise set to Fg.
    (Cell == Bg -> Cell2 = Bg ; Cell2 = Fg).

% rm_remap_bg(+Grid, +OldBg, +NewBg, -Grid2)
% Replace every OldBg cell with NewBg; all other cells remain unchanged.
rm_remap_bg(Grid, OldBg, NewBg, Grid2) :-
    % This is a special case of rm_replace.
    rm_replace(Grid, OldBg, NewBg, Grid2).

% rm_palette(+Grid, -Palette)
% Palette is the sorted list of distinct values appearing in Grid.
rm_palette(Grid, Palette) :-
    % Collect all cell values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    % Sort to get distinct values.
    sort(Vals, Palette).

% rm_reindex(+Grid, +OldPalette, -Grid2)
% Replace the i-th value in OldPalette with integer i across Grid.
% OldPalette is a list of values; each value at position I (0-indexed) is
% replaced by I+1 (1-based).
rm_reindex(Grid, OldPalette, Grid2) :-
    % Build map from each palette value to its 1-based index.
    rm_build_index_map_(OldPalette, 1, Map),
    % Apply the reindex map to the grid.
    rm_apply_map(Map, Grid, Grid2).
