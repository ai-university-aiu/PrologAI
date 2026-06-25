% diff.pl - Layer 89: Multi-Pair Grid Difference Analysis (df_* prefix).
:- module(diff, [
    df_cell_diff/3,
    df_added/4,
    df_removed/4,
    df_recolored/4,
    df_stable/3,
    df_palette_change/4,
    df_common_diffs/2,
    df_common_stable/2,
    df_always_added/3,
    df_always_removed/3,
    df_total_changes/3,
    df_apply_diffs/3,
    df_invert_diffs/2,
    df_filter_diffs/3
]).
% Import list utilities; sort/2, length/2, between/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, append/3, subtract/3,
                                intersection/3]).
% Import higher-order utilities for maplist, include, and foldl.
:- use_module(library(apply), [maplist/3, include/3, foldl/4]).

% df_pal_: extract the sorted palette of all distinct values in a grid.
df_pal_(Grid, Pal) :-
% Collect all cell values by scanning each row.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
% Sort to remove duplicates and produce a canonical palette.
    sort(Vs, Pal).

% df_dims_: extract NR (row count) and NC1 (max col index) from a grid.
df_dims_(Grid, NR1, NC1) :-
% Count rows.
    length(Grid, NR), NR1 is NR - 1,
% Count columns from the first row.
    Grid = [FR|_], length(FR, NC), NC1 is NC - 1.

% df_set_cell_: replace the value at (R, C) in Grid with V, producing Grid2.
df_set_cell_(Grid, R, C, V, Grid2) :-
% Extract the current row at index R.
    nth0(R, Grid, OldRow),
% Split OldRow at position C.
    length(Pre, C),
% Decompose row into prefix, old cell, and suffix.
    append(Pre, [_|Post], OldRow),
% Reconstruct row with V at position C.
    append(Pre, [V|Post], NewRow),
% Split Grid at row R.
    length(Pre2, R),
% Decompose Grid into above, old row, and below.
    append(Pre2, [_|Suf], Grid),
% Reconstruct Grid with the new row.
    append(Pre2, [NewRow|Suf], Grid2).

% df_apply_one_: apply a single diff(R,C,_,V2) change to a grid.
df_apply_one_(diff(R, C, _, V2), G0, G1) :-
% Delegate to df_set_cell_ using the new value V2.
    df_set_cell_(G0, R, C, V2, G1).

% df_invert_one_: invert a single diff(R,C,V1,V2) to diff(R,C,V2,V1).
df_invert_one_(diff(R, C, V1, V2), diff(R, C, V2, V1)).

% df_changed_cells_: collect R-C pairs that differ between two same-size grids.
df_changed_cells_(G1, G2, Cells) :-
% Get grid bounds from G1.
    df_dims_(G1, NR1, NC1),
% Collect each cell position where values differ.
    findall(R-C, (
        between(0, NR1, R),
        nth0(R, G1, Row1), nth0(R, G2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, V1), nth0(C, Row2, V2),
        V1 \= V2
    ), Cells).

% df_stable_cells_: collect R-C pairs where both grids agree.
df_stable_cells_(G1, G2, Cells) :-
% Get grid bounds from G1.
    df_dims_(G1, NR1, NC1),
% Collect each cell position where values are equal.
    findall(R-C, (
        between(0, NR1, R),
        nth0(R, G1, Row1), nth0(R, G2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, V), nth0(C, Row2, V)
    ), Cells).

% df_added_cells_: collect R-C pairs that went from BG to non-BG.
df_added_cells_(G1, G2, BG, Cells) :-
% Get grid bounds from G1.
    df_dims_(G1, NR1, NC1),
% Collect cells that were BG in G1 and non-BG in G2.
    findall(R-C, (
        between(0, NR1, R),
        nth0(R, G1, Row1), nth0(R, G2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, BG),
        nth0(C, Row2, V2), V2 \= BG
    ), Cells).

% df_removed_cells_: collect R-C pairs that went from non-BG to BG.
df_removed_cells_(G1, G2, BG, Cells) :-
% Get grid bounds from G1.
    df_dims_(G1, NR1, NC1),
% Collect cells that were non-BG in G1 and BG in G2.
    findall(R-C, (
        between(0, NR1, R),
        nth0(R, G1, Row1), nth0(R, G2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, V1), V1 \= BG,
        nth0(C, Row2, BG)
    ), Cells).

% df_intersect_all_: intersect a list of cell lists to find common elements.
df_intersect_all_([], []) :- !.
df_intersect_all_([Cells], Cells) :- !.
df_intersect_all_([C1, C2 | Rest], Common) :-
% Intersect the first two lists.
    intersection(C1, C2, C12),
% Recursively intersect with the rest.
    df_intersect_all_([C12|Rest], Common).

% df_cell_diff(+Grid1, +Grid2, -Diffs): list of diff(R,C,V1,V2) for each changed cell.
% Each diff term records the row, column, old value, and new value for a cell that differs.
df_cell_diff(Grid1, Grid2, Diffs) :-
% Get grid bounds.
    df_dims_(Grid1, NR1, NC1),
% Collect diff terms for all changed cells.
    findall(diff(R, C, V1, V2), (
        between(0, NR1, R),
        nth0(R, Grid1, Row1), nth0(R, Grid2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, V1), nth0(C, Row2, V2),
        V1 \= V2
    ), Diffs).

% df_added(+Grid1, +Grid2, +BG, -Cells): R-C pairs that changed from BG to non-BG.
% Cells are positions where Grid1 had the background value and Grid2 has a non-background value.
df_added(Grid1, Grid2, BG, Cells) :-
% Delegate to the internal helper.
    df_added_cells_(Grid1, Grid2, BG, Cells).

% df_removed(+Grid1, +Grid2, +BG, -Cells): R-C pairs that changed from non-BG to BG.
% Cells are positions where Grid1 had a non-background value and Grid2 has the background value.
df_removed(Grid1, Grid2, BG, Cells) :-
% Delegate to the internal helper.
    df_removed_cells_(Grid1, Grid2, BG, Cells).

% df_recolored(+Grid1, +Grid2, +BG, -Triples): R-C-Old-New for non-BG color changes.
% Triples are positions where both grids are non-BG but the color changed.
df_recolored(Grid1, Grid2, BG, Triples) :-
% Get grid bounds.
    df_dims_(Grid1, NR1, NC1),
% Collect triples for cells that changed non-BG color.
    findall(R-C-V1-V2, (
        between(0, NR1, R),
        nth0(R, Grid1, Row1), nth0(R, Grid2, Row2),
        between(0, NC1, C),
        nth0(C, Row1, V1), V1 \= BG,
        nth0(C, Row2, V2), V2 \= BG,
        V1 \= V2
    ), Triples).

% df_stable(+Grid1, +Grid2, -Cells): R-C pairs whose value did not change.
% Every cell position where Grid1 and Grid2 hold the same value.
df_stable(Grid1, Grid2, Cells) :-
% Delegate to the internal helper.
    df_stable_cells_(Grid1, Grid2, Cells).

% df_palette_change(+Grid1, +Grid2, -Added, -Lost): palette additions and losses.
% Added = colors in Grid2 not in Grid1; Lost = colors in Grid1 not in Grid2.
df_palette_change(Grid1, Grid2, Added, Lost) :-
% Extract palettes from both grids.
    df_pal_(Grid1, Pal1),
    df_pal_(Grid2, Pal2),
% Colors in Grid2 not in Grid1 are added.
    subtract(Pal2, Pal1, Added),
% Colors in Grid1 not in Grid2 are lost.
    subtract(Pal1, Pal2, Lost).

% df_common_diffs(+Pairs, -CommonCells): R-C cells that changed in EVERY In-Out pair.
% Pairs is a list of In-Out terms. CommonCells are positions that differ in all pairs.
df_common_diffs([], []) :- !.
df_common_diffs(Pairs, CommonCells) :-
% Collect changed cell sets for each pair.
    findall(Cells, (
        member(In-Out, Pairs),
        df_changed_cells_(In, Out, Cells)
    ), AllCellSets),
% Intersect all sets to find cells changed in every pair.
    df_intersect_all_(AllCellSets, CommonCells).

% df_common_stable(+Pairs, -CommonCells): R-C cells that are stable in EVERY In-Out pair.
% Pairs is a list of In-Out terms. CommonCells are positions with equal value in all pairs.
df_common_stable([], []) :- !.
df_common_stable(Pairs, CommonCells) :-
% Collect stable cell sets for each pair.
    findall(Cells, (
        member(In-Out, Pairs),
        df_stable_cells_(In, Out, Cells)
    ), AllCellSets),
% Intersect all sets to find cells stable in every pair.
    df_intersect_all_(AllCellSets, CommonCells).

% df_always_added(+Pairs, +BG, -CommonCells): cells added (BG to non-BG) in EVERY pair.
% Pairs is a list of In-Out terms. CommonCells are positions added in all pairs.
df_always_added([], _, []) :- !.
df_always_added(Pairs, BG, CommonCells) :-
% Collect added cell sets for each pair.
    findall(Cells, (
        member(In-Out, Pairs),
        df_added_cells_(In, Out, BG, Cells)
    ), AllCellSets),
% Intersect all sets to find cells always added.
    df_intersect_all_(AllCellSets, CommonCells).

% df_always_removed(+Pairs, +BG, -CommonCells): cells removed (non-BG to BG) in EVERY pair.
% Pairs is a list of In-Out terms. CommonCells are positions removed in all pairs.
df_always_removed([], _, []) :- !.
df_always_removed(Pairs, BG, CommonCells) :-
% Collect removed cell sets for each pair.
    findall(Cells, (
        member(In-Out, Pairs),
        df_removed_cells_(In, Out, BG, Cells)
    ), AllCellSets),
% Intersect all sets to find cells always removed.
    df_intersect_all_(AllCellSets, CommonCells).

% df_total_changes(+Grid1, +Grid2, -N): total number of cells that changed.
% N is the count of cell positions where Grid1 and Grid2 differ.
df_total_changes(Grid1, Grid2, N) :-
% Collect all changed cells and count them.
    df_cell_diff(Grid1, Grid2, Diffs),
    length(Diffs, N).

% df_apply_diffs(+Grid, +Diffs, -Grid2): apply a list of diff/4 changes to a grid.
% Each diff(R,C,_,V2) sets Grid[R][C] to V2. Diffs are applied in order.
df_apply_diffs(Grid, Diffs, Grid2) :-
% Fold each diff term through the grid using the internal apply helper.
    foldl(df_apply_one_, Diffs, Grid, Grid2).

% df_invert_diffs(+Diffs, -Inverse): swap the old and new values in each diff.
% Inverse is the list of diff(R,C,V2,V1) corresponding to each diff(R,C,V1,V2) in Diffs.
df_invert_diffs(Diffs, Inverse) :-
% Map the inversion helper over the list.
    maplist(df_invert_one_, Diffs, Inverse).

% df_filter_diffs(+Diffs, +Goal, -Filtered): keep only diffs satisfying Goal.
% Goal is a 1-argument callable tested on each diff(R,C,V1,V2) term.
df_filter_diffs(Diffs, Goal, Filtered) :-
% Include only diffs for which Goal succeeds.
    include(Goal, Diffs, Filtered).
