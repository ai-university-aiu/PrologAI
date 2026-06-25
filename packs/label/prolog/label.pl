% label.pl - Layer 83: Connected Component Labeling (lb_* prefix).
% ARC-AGI-2 visual reasoning: assign, query, filter, and recolor labeled regions.
:- module(label, [
    lb_label/3,
    lb_components/3,
    lb_count/3,
    lb_size_of/3,
    lb_sizes_all/3,
    lb_cells_of/3,
    lb_bbox_of/4,
    lb_neighbors_of/4,
    lb_fill_label/4,
    lb_keep_largest/3,
    lb_remove_small/4,
    lb_color_labels/4,
    lb_merge_two/4,
    lb_select_label/4
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                subtract/3, min_member/2, max_member/2]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, foldl/4, include/3]).

% lb_bfs_(+Queue, +Visited, +Grid, +Bg, +MaxR, +MaxC, -Component): BFS flood-fill.
lb_bfs_([], Visited, _, _, _, _, Visited).
lb_bfs_([R-C|Queue], Visited, Grid, Bg, MaxR, MaxC, Component) :-
    % Find 4-connected non-Bg neighbors not yet in Visited.
    findall(R2-C2, (
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< MaxR, C2 >= 0, C2 =< MaxC,
        nth0(R2, Grid, Row2), nth0(C2, Row2, V2), V2 \== Bg,
        \+ member(R2-C2, Visited)
    ), NewCells0),
    % Deduplicate to avoid processing the same cell multiple times.
    sort(NewCells0, NewCells),
    % Add new cells to visited and to the BFS queue.
    append(Visited, NewCells, NewVisited),
    append(Queue, NewCells, NewQueue0),
    sort(NewQueue0, NewQueue),
    lb_bfs_(NewQueue, NewVisited, Grid, Bg, MaxR, MaxC, Component).

% lb_partition_components_: assign labels to connected components from AllCells.
lb_partition_components_([], _, _, _, _, _, []).
lb_partition_components_([Seed|Rest], Grid, Bg, MaxR, MaxC, L, [L-Component|More]) :-
    % BFS from Seed to find all cells in its component.
    lb_bfs_([Seed], [Seed], Grid, Bg, MaxR, MaxC, Component),
    % Remove this component's cells from the remaining unvisited cells.
    subtract(Rest, Component, Remaining),
    % Assign the next integer label to the next component.
    L1 is L + 1,
    lb_partition_components_(Remaining, Grid, Bg, MaxR, MaxC, L1, More).

% lb_build_lookup_: convert Label-Cells pairs to a flat R-C-Label lookup list.
lb_build_lookup_([], []).
lb_build_lookup_([Label-Cells|Rest], Lookup) :-
    % Map each cell in this component to a triple for point lookup.
    maplist([R-C, R-C-Label]>>true, Cells, Pairs),
    lb_build_lookup_(Rest, RestLookup),
    append(Pairs, RestLookup, Lookup).

% lb_pairs_to_grid_: build LabelGrid from a Label-Cells association.
lb_pairs_to_grid_(NRows, NCols, LabelPairs, Bg, LabelGrid) :-
    % Build a flat lookup list for O(n) per-cell lookup.
    lb_build_lookup_(LabelPairs, Lookup),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each cell: look up its label or use Bg if not found.
    maplist([RI, Row]>>(
        maplist([CI, V]>>(
            (member(RI-CI-LV, Lookup) -> V = LV ; V = Bg)
        ), ColIdxs, Row)
    ), RowIdxs, LabelGrid).

% lb_label(+Grid, +Bg, -LabelGrid): assign unique integer labels to connected components.
% LabelGrid[R][C] is the component label (1, 2, ...) or Bg for background cells.
lb_label(Grid, Bg, LabelGrid) :-
    % Collect all non-Bg cells in sorted order to fix component discovery order.
    length(Grid, NRows), Grid = [FR|_], length(FR, NCols),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V \== Bg
    ), AllCells0),
    sort(AllCells0, AllCells),
    % Partition cells into labeled components by BFS.
    lb_partition_components_(AllCells, Grid, Bg, NRowsM1, NColsM1, 1, LabelPairs),
    % Build the integer label grid from the labeled components.
    lb_pairs_to_grid_(NRows, NCols, LabelPairs, Bg, LabelGrid).

% lb_components(+Grid, +Bg, -Components): list of R-C cell lists, one per component.
lb_components(Grid, Bg, Components) :-
    % Reuse the labeling infrastructure to get component cell lists.
    length(Grid, NRows), Grid = [FR|_], length(FR, NCols),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V \== Bg
    ), AllCells0),
    sort(AllCells0, AllCells),
    lb_partition_components_(AllCells, Grid, Bg, NRowsM1, NColsM1, 1, LabelPairs),
    % Strip labels; keep only the cell lists.
    maplist([_-Cells, Cells]>>true, LabelPairs, Components).

% lb_count(+Grid, +Bg, -N): N is the number of distinct connected components.
lb_count(Grid, Bg, N) :-
    % Delegate to lb_components and count.
    lb_components(Grid, Bg, Components),
    length(Components, N).

% lb_cells_of(+LabelGrid, +Label, -Cells): sorted list of R-C positions with value Label.
lb_cells_of(LabelGrid, Label, Cells) :-
    % Scan the LabelGrid for cells matching the requested label.
    length(LabelGrid, NRows), NRowsM1 is NRows - 1,
    LabelGrid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, LabelGrid, Row), nth0(C, Row, Label)
    ), Cells).

% lb_size_of(+LabelGrid, +Label, -Size): Size is the cell count of label Label.
lb_size_of(LabelGrid, Label, Size) :-
    % Get cells for this label and count them.
    lb_cells_of(LabelGrid, Label, Cells),
    length(Cells, Size).

% lb_sizes_all(+LabelGrid, +Bg, -Sizes): Sizes is a sorted Label-Size pairs list.
lb_sizes_all(LabelGrid, Bg, Sizes) :-
    % Find all distinct non-Bg values (component labels) present in the grid.
    length(LabelGrid, NRows), NRowsM1 is NRows - 1,
    LabelGrid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    findall(L, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, LabelGrid, Row), nth0(C, Row, L), L \== Bg
    ), LabelsDup),
    sort(LabelsDup, Labels),
    % Compute the size for each unique label.
    maplist([L, L-S]>>(lb_size_of(LabelGrid, L, S)), Labels, Sizes).

% lb_bbox_of(+LabelGrid, +Label, -TopLeft, -BottomRight): bounding box corners of label.
% TopLeft = R0-C0 (min row, min col); BottomRight = R1-C1 (max row, max col).
lb_bbox_of(LabelGrid, Label, R0-C0, R1-C1) :-
    % Collect cells of this label and compute min/max coordinates.
    lb_cells_of(LabelGrid, Label, Cells),
    Cells \= [],
    findall(R, member(R-_, Cells), Rs),
    findall(C, member(_-C, Cells), Cs),
    min_member(R0, Rs), max_member(R1, Rs),
    min_member(C0, Cs), max_member(C1, Cs).

% lb_neighbors_of(+LabelGrid, +Label, +Bg, -NeighborLabels): sorted foreground labels 4-adjacent to Label.
% Bg is excluded from the result; only component labels are returned.
lb_neighbors_of(LabelGrid, Label, Bg, NeighborLabels) :-
    % Find all cells of this label.
    lb_cells_of(LabelGrid, Label, Cells),
    length(LabelGrid, NRows), NRowsM1 is NRows - 1,
    LabelGrid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    % Collect all distinct non-Bg labels 4-adjacent to any cell in this component.
    findall(NL, (
        member(R-C, Cells),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
        nth0(R2, LabelGrid, Row2), nth0(C2, Row2, NL), NL \== Label, NL \== Bg
    ), NLDup),
    sort(NLDup, NeighborLabels).

% lb_fill_label(+LabelGrid, +Label, +Val, -Grid): replace every cell of Label with Val.
lb_fill_label(LabelGrid, Label, Val, Grid) :-
    % Map over every cell: replace Label with Val, leave others unchanged.
    maplist([Row, NewRow]>>(
        maplist([V, NV]>>(V == Label -> NV = Val ; NV = V), Row, NewRow)
    ), LabelGrid, Grid).

% lb_max_size_label_(+Sizes, -BestLabel): BestLabel has the greatest size in Sizes list.
lb_max_size_label_([L-S|Rest], BestLabel) :-
    % Accumulate through the list, tracking the current best.
    lb_max_size_acc_(Rest, L, S, BestLabel).

% lb_max_size_acc_(+Rest, +CurLabel, +CurMax, -Best): accumulate maximum.
lb_max_size_acc_([], Best, _, Best).
lb_max_size_acc_([L-S|Rest], CurBest, CurMax, Best) :-
    % Update if this label is strictly larger.
    (S > CurMax ->
        lb_max_size_acc_(Rest, L, S, Best)
    ;
        lb_max_size_acc_(Rest, CurBest, CurMax, Best)
    ).

% lb_keep_largest(+Grid, +Bg, -Result): keep only the largest component; others become Bg.
% When the grid is all background, Result = Grid.
lb_keep_largest(Grid, Bg, Result) :-
    % Label the grid and find all component sizes.
    lb_label(Grid, Bg, LabelGrid),
    lb_sizes_all(LabelGrid, Bg, Sizes),
    % Handle the all-background case: nothing to keep.
    (Sizes = [] ->
        Result = Grid
    ;
        % Identify the label with the most cells.
        lb_max_size_label_(Sizes, BigLabel),
        % Rebuild: preserve original Grid values where label matches, else Bg.
        maplist([GRow, LRow, RRow]>>(
            maplist([GV, LV, RV]>>(
                LV == BigLabel -> RV = GV ; RV = Bg
            ), GRow, LRow, RRow)
        ), Grid, LabelGrid, Result)
    ).

% lb_remove_small(+Grid, +Bg, +MinSize, -Result): remove components with fewer than MinSize cells.
lb_remove_small(Grid, Bg, MinSize, Result) :-
    % Label the grid and compute all component sizes.
    lb_label(Grid, Bg, LabelGrid),
    lb_sizes_all(LabelGrid, Bg, Sizes),
    % Collect labels large enough to keep.
    include([_-S]>>(S >= MinSize), Sizes, KeptSizes),
    findall(L, member(L-_, KeptSizes), KeptLabels),
    % Rebuild: keep original value for cells in kept labels; Bg otherwise.
    maplist([GRow, LRow, RRow]>>(
        maplist([GV, LV, RV]>>(
            (member(LV, KeptLabels) -> RV = GV ; RV = Bg)
        ), GRow, LRow, RRow)
    ), Grid, LabelGrid, Result).

% lb_color_labels(+LabelGrid, +Bg, +Colors, -Grid): color each label by cycling through Colors.
% Label L maps to Colors[(L - 1) mod len(Colors)].
lb_color_labels(LabelGrid, Bg, Colors, Grid) :-
    % Compute the palette size for modular index wrapping.
    length(Colors, NColors),
    maplist([Row, NewRow]>>(
        maplist([LV, NV]>>(
            (LV == Bg ->
                NV = Bg
            ;
                Idx is (LV - 1) mod NColors,
                nth0(Idx, Colors, NV)
            )
        ), Row, NewRow)
    ), LabelGrid, Grid).

% lb_merge_two(+LabelGrid, +L1, +L2, -NewGrid): merge label L2 into L1 (L2 cells become L1).
lb_merge_two(LabelGrid, L1, L2, NewGrid) :-
    % Replace all occurrences of L2 with L1 throughout the grid.
    maplist([Row, NewRow]>>(
        maplist([V, NV]>>(V == L2 -> NV = L1 ; NV = V), Row, NewRow)
    ), LabelGrid, NewGrid).

% lb_select_label(+Grid, +LabelGrid, +Label, -Result): extract original values for Label cells.
% Result[R][C] = Grid[R][C] where LabelGrid[R][C] = Label; 0 elsewhere.
lb_select_label(Grid, LabelGrid, Label, Result) :-
    % Keep Grid value where LabelGrid matches, zero out all other cells.
    maplist([GRow, LRow, RRow]>>(
        maplist([GV, LV, RV]>>(
            LV == Label -> RV = GV ; RV = 0
        ), GRow, LRow, RRow)
    ), Grid, LabelGrid, Result).
