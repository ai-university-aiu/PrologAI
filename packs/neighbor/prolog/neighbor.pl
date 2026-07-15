% neighbor.pl - Layer 93: Cell Neighborhood Analysis (nb_* prefix).
% Provides raw 4/8 neighbor access, boundary and interior detection,
% neighbor value counting, color contact queries, grid-modifying flood
% fill, and single-step dilation for symbolic grid reasoning.
:- module(neighbor, [
    neighbor_4neighbors/4,
    neighbor_8neighbors/4,
    neighbor_is_boundary/4,
    neighbor_is_interior/4,
    neighbor_boundary_cells/3,
    neighbor_interior_cells/3,
    neighbor_count_same/4,
    neighbor_count_diff/4,
    neighbor_adjacent_colors/4,
    neighbor_contour/3,
    neighbor_color_touches/3,
    neighbor_touching_pairs/4,
    neighbor_flood_fill/5,
    neighbor_dilate/4
]).
% Import nth0/3 for cell access and nth0/4 for cell replacement.
:- use_module(library(lists), [nth0/3, nth0/4, member/2]).

% neighbor_cell_: get the value at row R, column C in Grid.
neighbor_cell_(Grid, R, C, Val) :-
% Access row R.
    nth0(R, Grid, Row),
% Access column C within that row.
    nth0(C, Row, Val).

% neighbor_set_cell_: replace the value at (R, C) in Grid0 with Val to produce Grid1.
neighbor_set_cell_(Grid0, R, C, Val, Grid1) :-
% Remove row R from Grid0; OldRow is the original row, RestRows is Grid0 without it.
    nth0(R, Grid0, OldRow, RestRows),
% Remove column C from OldRow; RestCols is OldRow without that column.
    nth0(C, OldRow, _, RestCols),
% Insert Val at column C in RestCols to produce NewRow.
    nth0(C, NewRow, Val, RestCols),
% Insert NewRow at row R in RestRows to produce Grid1.
    nth0(R, Grid1, NewRow, RestRows).

% neighbor_set_cells_: apply neighbor_set_cell_ for each R-C pair in Cells, setting all to Val.
neighbor_set_cells_(Grid, [], _, Grid) :- !.
neighbor_set_cells_(Grid0, [R-C|Rest], Val, Grid2) :-
% Set cell (R, C) to Val.
    neighbor_set_cell_(Grid0, R, C, Val, Grid1),
% Recurse on the remaining cells.
    neighbor_set_cells_(Grid1, Rest, Val, Grid2).

% neighbor_4neighbors(+Grid, +R, +C, -Neighbors): list of nb(Row,Col,Val) terms
% for each valid 4-connected neighbor of (R, C) within Grid bounds.
% Directions: up (-1,0), down (1,0), left (0,-1), right (0,1).
neighbor_4neighbors(Grid, R, C, Neighbors) :-
% Get row and column bounds.
    length(Grid, NR),
    Grid = [FirstRow|_],
    length(FirstRow, NC),
% Collect valid neighbors in direction order.
    findall(nb(R1, C1, V), (
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R1 is R + DR,
        C1 is C + DC,
        R1 >= 0, R1 < NR,
        C1 >= 0, C1 < NC,
        neighbor_cell_(Grid, R1, C1, V)
    ), Neighbors).

% neighbor_8neighbors(+Grid, +R, +C, -Neighbors): list of nb(Row,Col,Val) terms
% for each valid 8-connected neighbor of (R, C) within Grid bounds.
% Covers all 8 surrounding cells including diagonals.
neighbor_8neighbors(Grid, R, C, Neighbors) :-
% Get row and column bounds.
    length(Grid, NR),
    Grid = [FirstRow|_],
    length(FirstRow, NC),
% Collect all valid 8-connected neighbors.
    findall(nb(R1, C1, V), (
        member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
        R1 is R + DR,
        C1 is C + DC,
        R1 >= 0, R1 < NR,
        C1 >= 0, C1 < NC,
        neighbor_cell_(Grid, R1, C1, V)
    ), Neighbors).

% neighbor_is_boundary(+Grid, +R, +C, +Bg): succeed if cell (R, C) is non-Bg
% and at least one 4-neighbor is Bg or out of bounds.
neighbor_is_boundary(Grid, R, C, Bg) :-
% Cell must not be the background color.
    neighbor_cell_(Grid, R, C, V),
    V \== Bg,
% Get grid dimensions.
    length(Grid, NR),
    Grid = [FR|_],
    length(FR, NC),
% Succeed if any direction leads to Bg or out of bounds.
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    R1 is R + DR,
    C1 is C + DC,
    (   R1 < 0 ; R1 >= NR ; C1 < 0 ; C1 >= NC
    ;   neighbor_cell_(Grid, R1, C1, NV), NV == Bg
    ),
% Cut: one such neighbor is sufficient.
    !.

% neighbor_is_interior(+Grid, +R, +C, +Bg): succeed if cell (R, C) is non-Bg
% and all 4-neighbors are within bounds and non-Bg.
neighbor_is_interior(Grid, R, C, Bg) :-
% Cell must not be the background color.
    neighbor_cell_(Grid, R, C, V),
    V \== Bg,
% Get grid dimensions.
    length(Grid, NR),
    Grid = [FR|_],
    length(FR, NC),
% Succeed only if NO 4-neighbor is Bg or out of bounds.
    \+ (
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R1 is R + DR,
        C1 is C + DC,
        (   R1 < 0 ; R1 >= NR ; C1 < 0 ; C1 >= NC
        ;   neighbor_cell_(Grid, R1, C1, NV), NV == Bg
        )
    ).

% neighbor_boundary_cells(+Grid, +Bg, -Cells): sorted list of R-C pairs for
% all non-Bg cells that are on the boundary (adjacent to Bg or grid edge).
neighbor_boundary_cells(Grid, Bg, Cells) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Collect all boundary cells.
    findall(R-C, (
        between(0, NR1, R),
        between(0, NC1, C),
        neighbor_is_boundary(Grid, R, C, Bg)
    ), Cells0),
% Sort to deduplicate and order.
    sort(Cells0, Cells).

% neighbor_interior_cells(+Grid, +Bg, -Cells): sorted list of R-C pairs for
% all non-Bg cells that are interior (no Bg 4-neighbor, no grid-edge neighbor).
neighbor_interior_cells(Grid, Bg, Cells) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Collect all interior cells.
    findall(R-C, (
        between(0, NR1, R),
        between(0, NC1, C),
        neighbor_is_interior(Grid, R, C, Bg)
    ), Cells0),
% Sort to deduplicate and order.
    sort(Cells0, Cells).

% neighbor_count_same(+Grid, +R, +C, -N): count of 4-neighbors of (R,C)
% that have the same color value as (R,C).
neighbor_count_same(Grid, R, C, N) :-
% Get the cell value to compare against.
    neighbor_cell_(Grid, R, C, Val),
% Get all 4-neighbors.
    neighbor_4neighbors(Grid, R, C, Neighbors),
% Count neighbors with the same value.
    findall(V, (member(nb(_, _, V), Neighbors), V == Val), Same),
    length(Same, N).

% neighbor_count_diff(+Grid, +R, +C, -N): count of 4-neighbors of (R,C)
% that have a different color value from (R,C).
neighbor_count_diff(Grid, R, C, N) :-
% Get the cell value to compare against.
    neighbor_cell_(Grid, R, C, Val),
% Get all 4-neighbors.
    neighbor_4neighbors(Grid, R, C, Neighbors),
% Count neighbors with a different value.
    findall(V, (member(nb(_, _, V), Neighbors), V \== Val), Diff),
    length(Diff, N).

% neighbor_adjacent_colors(+Grid, +R, +C, -Colors): sorted list of distinct
% color values among the 4-neighbors of (R, C).
neighbor_adjacent_colors(Grid, R, C, Colors) :-
% Get all 4-neighbors.
    neighbor_4neighbors(Grid, R, C, Neighbors),
% Extract all neighbor values.
    findall(V, member(nb(_, _, V), Neighbors), Vals),
% Sort removes duplicates and gives a canonical order.
    sort(Vals, Colors).

% neighbor_contour(+Grid, +Color, -Cells): sorted R-C pairs of all cells of
% Color that are adjacent to a cell of different color or out of bounds.
% This is the visible edge or outline of the Color region.
neighbor_contour(Grid, Color, Cells) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Collect cells of Color that touch non-Color or the grid edge.
    findall(R-C, (
        between(0, NR1, R),
        between(0, NC1, C),
        neighbor_cell_(Grid, R, C, Color),
        (
            member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
            R1 is R + DR,
            C1 is C + DC,
            (   R1 < 0 ; R1 >= NR ; C1 < 0 ; C1 >= NC
            ;   neighbor_cell_(Grid, R1, C1, NV), NV \== Color
            )
        )
    ), Cells0),
% Sort to deduplicate and order by row then column.
    sort(Cells0, Cells).

% neighbor_color_touches(+Grid, +ColorA, +ColorB): succeed if any cell of
% ColorA is 4-adjacent to any cell of ColorB anywhere in Grid.
neighbor_color_touches(Grid, ColorA, ColorB) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Find one adjacency with cut for determinism.
    between(0, NR1, R),
    between(0, NC1, C),
    neighbor_cell_(Grid, R, C, ColorA),
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    R1 is R + DR,
    C1 is C + DC,
    R1 >= 0, R1 < NR,
    C1 >= 0, C1 < NC,
    neighbor_cell_(Grid, R1, C1, ColorB),
% Stop at first found adjacency.
    !.

% neighbor_touching_pairs(+Grid, +ColorA, +ColorB, -Pairs): sorted list of
% (R1-C1)-(R2-C2) pairs where cell (R1,C1) has ColorA and is
% 4-adjacent to cell (R2,C2) with ColorB.
neighbor_touching_pairs(Grid, ColorA, ColorB, Pairs) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Collect all adjacent ColorA-ColorB cell pairs.
    findall((R-C)-(R1-C1), (
        between(0, NR1, R),
        between(0, NC1, C),
        neighbor_cell_(Grid, R, C, ColorA),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R1 is R + DR,
        C1 is C + DC,
        R1 >= 0, R1 < NR,
        C1 >= 0, C1 < NC,
        neighbor_cell_(Grid, R1, C1, ColorB)
    ), Pairs0),
% Sort to deduplicate and order.
    sort(Pairs0, Pairs).

% neighbor_flood_fill(+Grid, +R, +C, +FillVal, -Result): replace the
% 4-connected region containing (R,C) with FillVal in the output grid.
% The seed color is the value at (R,C); all 4-connected cells of that
% color reachable from the seed are replaced. If seed color equals
% FillVal, returns Grid unchanged.
neighbor_flood_fill(Grid, R, C, FillVal, Result) :-
% Get the seed color.
    neighbor_cell_(Grid, R, C, SeedVal),
% If seed already equals FillVal, nothing to do.
    (SeedVal == FillVal ->
        Result = Grid
    ;
        length(Grid, NR),
        Grid = [FR|_],
        length(FR, NC),
% Start the worklist-based fill from the seed cell.
        neighbor_fill_step_([R-C], SeedVal, FillVal, NR, NC, Grid, Result)
    ).

% neighbor_fill_step_: process one cell from the worklist.
% When a cell matches SeedVal, replace it with FillVal and enqueue its valid 4-neighbors.
% When a cell does not match SeedVal (already filled or different color), skip it.
neighbor_fill_step_([], _, _, _, _, Grid, Grid).
neighbor_fill_step_([R-C|Worklist], SeedVal, FillVal, NR, NC, Grid0, Result) :-
% Check current value of this cell.
    neighbor_cell_(Grid0, R, C, CurVal),
    (CurVal == SeedVal ->
% Replace this cell with FillVal.
        neighbor_set_cell_(Grid0, R, C, FillVal, Grid1),
% Collect valid 4-neighbors to enqueue.
        findall(R1-C1, (
            member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
            R1 is R + DR,
            C1 is C + DC,
            R1 >= 0, R1 < NR,
            C1 >= 0, C1 < NC
        ), NewCells),
% Append new cells to end of worklist.
        append(Worklist, NewCells, NewWorklist),
        neighbor_fill_step_(NewWorklist, SeedVal, FillVal, NR, NC, Grid1, Result)
    ;
% Cell is not SeedVal (already filled or different): skip.
        neighbor_fill_step_(Worklist, SeedVal, FillVal, NR, NC, Grid0, Result)
    ).

% neighbor_dilate(+Grid, +Bg, +Color, -Result): expand the Color region by
% one cell in all four 4-connected directions. Bg cells adjacent to any
% Color cell are replaced with Color. Non-Bg, non-Color cells are unchanged.
neighbor_dilate(Grid, Bg, Color, Result) :-
% Compute grid dimensions.
    length(Grid, NR),
    NR1 is NR - 1,
    Grid = [FR|_],
    length(FR, NC),
    NC1 is NC - 1,
% Find all Bg cells adjacent to any Color cell.
    findall(R1-C1, (
        between(0, NR1, R),
        between(0, NC1, C),
        neighbor_cell_(Grid, R, C, Color),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R1 is R + DR,
        C1 is C + DC,
        R1 >= 0, R1 < NR,
        C1 >= 0, C1 < NC,
        neighbor_cell_(Grid, R1, C1, Bg)
    ), NewCells0),
% Remove duplicates.
    sort(NewCells0, NewCells),
% Set all new cells to Color.
    neighbor_set_cells_(Grid, NewCells, Color, Result).
