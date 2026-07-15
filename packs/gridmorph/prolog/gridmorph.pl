:- module(gridmorph, [
    gridmorph_dilate/4,
    gridmorph_erode/4,
    gridmorph_open/4,
    gridmorph_close/4,
    gridmorph_dilate1/3,
    gridmorph_erode1/3,
    gridmorph_boundary_inner/3,
    gridmorph_boundary_outer/3,
    gridmorph_gradient_cells/3,
    gridmorph_top_hat/4,
    gridmorph_bottom_hat/4,
    gridmorph_fill_holes/4,
    gridmorph_connected_border/4,
    gridmorph_remove_small/5
]).
% gridmorph.pl - Layer 212: Grid Morphological Operations - dilation, erosion,
% opening, closing, boundary extraction, hole filling, and size filtering (gmo_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Binary morphology treats FgColor as foreground; all other colors as background.
:- use_module(library(lists), [
    nth0/3, member/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gridmorph_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
gridmorph_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gridmorph_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% 4-connected neighbor offsets.
gridmorph_nbr4_(R, C, NR, NC) :-
% Generate one of four neighbor directions.
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR,
    NC is C + DC.

% Single dilation step: BgColor cells adjacent to FgColor become FgColor.
gridmorph_dilate1_step_(Grid, FgColor, Result) :-
% Get dimensions.
    gridmorph_dims_(Grid, H, W),
% Build result: FgColor cells stay FgColor; non-FgColor adjacent to FgColor become FgColor.
    gridmorph_build_(H, W,
        [R, C, V]>>(gridmorph_cell_(Grid, R, C, GV),
                    (GV = FgColor -> V = FgColor
                    ; (once((gridmorph_nbr4_(R, C, NR, NC),
                              gridmorph_cell_(Grid, NR, NC, FgColor))) ->
                           V = FgColor
                       ;
                           V = GV))),
        Result).

% Single erosion step: FgColor cells adjacent to non-FgColor become non-FgColor (BgColor).
% Background color is determined by the first non-FgColor cell found.
gridmorph_erode1_step_(Grid, FgColor, BgColor, Result) :-
% Get dimensions.
    gridmorph_dims_(Grid, H, W),
% Build result: FgColor cells with any non-FgColor neighbor become BgColor; others keep value.
    gridmorph_build_(H, W,
        [R, C, V]>>(gridmorph_cell_(Grid, R, C, GV),
                    (GV = FgColor ->
                        (once((gridmorph_nbr4_(R, C, NR, NC),
                               gridmorph_cell_(Grid, NR, NC, NV),
                               NV \= FgColor)) ->
                             V = BgColor
                        ;
                             V = FgColor)
                    ;
                        V = GV)),
        Result).

% Find the background color (first non-FgColor cell in row-major order).
gridmorph_bg_color_(Grid, FgColor, BgColor) :-
% Iterate over cells to find first non-FgColor value.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(V,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, V), V \= FgColor),
        [BgColor|_]).

% Iterate N dilation steps.
gridmorph_dilate_n_(Grid, _, 0, Grid) :- !.
gridmorph_dilate_n_(Grid, FgColor, N, Result) :-
    N > 0,
    gridmorph_dilate1_step_(Grid, FgColor, G1),
    N1 is N - 1,
    gridmorph_dilate_n_(G1, FgColor, N1, Result).

% Iterate N erosion steps using discovered BgColor.
gridmorph_erode_n_(Grid, _, _, 0, Grid) :- !.
gridmorph_erode_n_(Grid, FgColor, BgColor, N, Result) :-
    N > 0,
    gridmorph_erode1_step_(Grid, FgColor, BgColor, G1),
    N1 is N - 1,
    gridmorph_erode_n_(G1, FgColor, BgColor, N1, Result).

% --- MORPHOLOGICAL OPERATIONS ---

% gridmorph_dilate(+Grid, +FgColor, +N, -Result)
% Result is Grid with the FgColor region expanded by N layers in all 4 directions.
% Non-FgColor cells adjacent to FgColor in each step become FgColor.
gridmorph_dilate(Grid, FgColor, N, Result) :-
% Iterate N dilation steps.
    gridmorph_dilate_n_(Grid, FgColor, N, Result).

% gridmorph_erode(+Grid, +FgColor, +N, -Result)
% Result is Grid with the FgColor region shrunk by N layers.
% FgColor cells with any non-FgColor neighbor in each step become BgColor.
gridmorph_erode(Grid, FgColor, N, Result) :-
% Find background color for erosion fill.
    (gridmorph_bg_color_(Grid, FgColor, BgColor) -> true ; BgColor = bg),
% Iterate N erosion steps.
    gridmorph_erode_n_(Grid, FgColor, BgColor, N, Result).

% gridmorph_dilate1(+Grid, +FgColor, -Result)
% Single dilation step: one-layer expansion of FgColor region.
gridmorph_dilate1(Grid, FgColor, Result) :-
% Apply a single dilation step.
    gridmorph_dilate1_step_(Grid, FgColor, Result).

% gridmorph_erode1(+Grid, +FgColor, -Result)
% Single erosion step: remove one layer from FgColor boundary.
gridmorph_erode1(Grid, FgColor, Result) :-
% Find background color.
    (gridmorph_bg_color_(Grid, FgColor, BgColor) -> true ; BgColor = bg),
% Apply a single erosion step.
    gridmorph_erode1_step_(Grid, FgColor, BgColor, Result).

% gridmorph_open(+Grid, +FgColor, +N, -Result)
% Morphological opening: N erosions followed by N dilations.
% Removes small protrusions and isolated FgColor regions smaller than N.
gridmorph_open(Grid, FgColor, N, Result) :-
% Erode first to shrink.
    gridmorph_erode(Grid, FgColor, N, Eroded),
% Then dilate to restore approximate original size.
    gridmorph_dilate(Eroded, FgColor, N, Result).

% gridmorph_close(+Grid, +FgColor, +N, -Result)
% Morphological closing: N dilations followed by N erosions.
% Fills small gaps and holes within FgColor regions.
gridmorph_close(Grid, FgColor, N, Result) :-
% Dilate first to fill gaps.
    gridmorph_dilate(Grid, FgColor, N, Dilated),
% Then erode to restore approximate original size.
    gridmorph_erode(Dilated, FgColor, N, Result).

% --- BOUNDARY EXTRACTION ---

% gridmorph_boundary_inner(+Grid, +FgColor, -Cells)
% Cells is the list of FgColor positions that have at least one non-FgColor
% 4-connected neighbor (the inner border of the FgColor region).
gridmorph_boundary_inner(Grid, FgColor, Cells) :-
% Get grid dimensions.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect FgColor cells with at least one non-FgColor neighbor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, FgColor),
         once((gridmorph_nbr4_(R, C, NR, NC),
               gridmorph_cell_(Grid, NR, NC, NV),
               NV \= FgColor))),
        Cells).

% gridmorph_boundary_outer(+Grid, +FgColor, -Cells)
% Cells is the list of non-FgColor positions that have at least one FgColor
% 4-connected neighbor (the outer border around the FgColor region).
gridmorph_boundary_outer(Grid, FgColor, Cells) :-
% Get grid dimensions.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect non-FgColor cells with at least one FgColor neighbor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, V), V \= FgColor,
         once((gridmorph_nbr4_(R, C, NR, NC),
               gridmorph_cell_(Grid, NR, NC, FgColor)))),
        Cells).

% gridmorph_gradient_cells(+Grid, +FgColor, -Cells)
% Cells is the morphological gradient: the union of the inner and outer boundary.
% Equivalent to all cells in the border region between FgColor and background.
gridmorph_gradient_cells(Grid, FgColor, Cells) :-
% Get inner and outer boundaries.
    gridmorph_boundary_inner(Grid, FgColor, Inner),
    gridmorph_boundary_outer(Grid, FgColor, Outer),
% Combine inner and outer boundaries (may have no overlap by construction).
    append(Inner, Outer, Cells).

% --- DERIVED OPERATIONS ---

% gridmorph_top_hat(+Grid, +FgColor, +N, -Cells)
% Top-hat transform: FgColor cells present in Grid but absent after opening.
% Highlights small bright structures removed by opening.
gridmorph_top_hat(Grid, FgColor, N, Cells) :-
% Compute morphological opening.
    gridmorph_open(Grid, FgColor, N, Opened),
% Collect FgColor cells in Grid that became non-FgColor in Opened.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, FgColor),
         gridmorph_cell_(Opened, R, C, OV),
         OV \= FgColor),
        Cells).

% gridmorph_bottom_hat(+Grid, +FgColor, +N, -Cells)
% Bottom-hat (black-hat) transform: FgColor cells present after closing but absent in Grid.
% Highlights small dark holes filled by closing.
gridmorph_bottom_hat(Grid, FgColor, N, Cells) :-
% Compute morphological closing.
    gridmorph_close(Grid, FgColor, N, Closed),
% Collect FgColor cells in Closed that were non-FgColor in Grid.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Closed, R, C, FgColor),
         gridmorph_cell_(Grid, R, C, GV),
         GV \= FgColor),
        Cells).

% gridmorph_fill_holes(+Grid, +FgColor, +BgColor, -Result)
% Result is Grid with all enclosed holes (BgColor regions not reachable from
% the grid border) replaced by FgColor.
gridmorph_fill_holes(Grid, FgColor, BgColor, Result) :-
% Find all BgColor cells reachable from the border (open background).
    gridmorph_connected_border(Grid, BgColor, FgColor, OpenBg),
% Build result: BgColor cells NOT in OpenBg become FgColor; everything else unchanged.
    gridmorph_dims_(Grid, H, W),
    gridmorph_build_(H, W,
        [R, C, V]>>(gridmorph_cell_(Grid, R, C, GV),
                    (GV = BgColor ->
                        (memberchk(R-C, OpenBg) -> V = BgColor ; V = FgColor)
                    ;
                        V = GV)),
        Result).

% gridmorph_connected_border(+Grid, +TargetColor, +BlockColor, -Cells)
% Cells is the list of TargetColor positions reachable from the grid border
% by 4-connected movement through TargetColor cells (BlockColor stops expansion).
gridmorph_connected_border(Grid, TargetColor, BlockColor, Cells) :-
% Get border cells that are TargetColor.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        ((R = 0 ; R = H1 ; C = 0 ; C = W1),
         between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, TargetColor)),
        Seeds),
% BFS from Seeds through TargetColor cells.
    gridmorph_bfs_(Grid, Seeds, TargetColor, BlockColor, [], Cells).

% BFS over TargetColor cells starting from Seeds, avoiding BlockColor.
gridmorph_bfs_(_, [], _, _, Visited, Visited).
gridmorph_bfs_(Grid, [RC|Queue], TargetColor, BlockColor, Visited, Result) :-
% Skip already visited cells.
    (memberchk(RC, Visited) ->
        gridmorph_bfs_(Grid, Queue, TargetColor, BlockColor, Visited, Result)
    ;
        RC = R-C,
% Add current cell to visited.
        NewVisited = [RC|Visited],
% Find unvisited TargetColor 4-neighbors.
        findall(NR-NC,
            (gridmorph_nbr4_(R, C, NR, NC),
             gridmorph_cell_(Grid, NR, NC, TargetColor),
             \+ memberchk(NR-NC, NewVisited)),
            NewNeighbors),
% Append new neighbors to the queue.
        append(Queue, NewNeighbors, NewQueue),
        gridmorph_bfs_(Grid, NewQueue, TargetColor, BlockColor, NewVisited, Result)).

% gridmorph_remove_small(+Grid, +FgColor, +BgColor, +MinSize, -Result)
% Result is Grid with FgColor connected regions smaller than MinSize cells
% replaced by BgColor.
gridmorph_remove_small(Grid, FgColor, BgColor, MinSize, Result) :-
% Find all FgColor cells.
    gridmorph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridmorph_cell_(Grid, R, C, FgColor)),
        AllFg),
% For each FgColor cell, find its connected component and mark small ones.
    gridmorph_small_cells_(Grid, FgColor, AllFg, MinSize, [], SmallCells),
% Build result: small-region cells become BgColor; others unchanged.
    gridmorph_build_(H, W,
        [R, C, V]>>(gridmorph_cell_(Grid, R, C, GV),
                    (memberchk(R-C, SmallCells) -> V = BgColor ; V = GV)),
        Result).

% Find all cells in connected components smaller than MinSize.
gridmorph_small_cells_(_, _, [], _, Acc, Acc).
gridmorph_small_cells_(Grid, FgColor, [RC|Rest], MinSize, Acc, SmallCells) :-
% Skip cells already classified.
    (memberchk(RC, Acc) ->
        gridmorph_small_cells_(Grid, FgColor, Rest, MinSize, Acc, SmallCells)
    ;
        RC = R-C,
% BFS to find the full connected component.
        gridmorph_bfs_(Grid, [R-C], FgColor, x, [], Component),
% Check if the component is smaller than MinSize.
        (length(Component, Len), Len < MinSize ->
            append(Acc, Component, NewAcc)
        ;
            NewAcc = Acc),
        gridmorph_small_cells_(Grid, FgColor, Rest, MinSize, NewAcc, SmallCells)).
