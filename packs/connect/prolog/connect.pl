% Module declaration: connect pack, Layer 64.
:- module(connect, [
    % connect_flood4/4: 4-connected flood fill from a seed cell.
    connect_flood4/4,
    % connect_flood8/4: 8-connected flood fill from a seed cell.
    connect_flood8/4,
    % connect_components4/3: list of all 4-connected same-color regions.
    connect_components4/3,
    % connect_components8/3: list of all 8-connected same-color regions.
    connect_components8/3,
    % connect_count4/3: number of 4-connected same-color components.
    connect_count4/3,
    % connect_count8/3: number of 8-connected same-color components.
    connect_count8/3,
    % connect_sizes4/3: sorted list of 4-connected component sizes.
    connect_sizes4/3,
    % connect_sizes8/3: sorted list of 8-connected component sizes.
    connect_sizes8/3,
    % connect_largest4/3: largest 4-connected component of a color.
    connect_largest4/3,
    % connect_largest8/3: largest 8-connected component of a color.
    connect_largest8/3,
    % connect_smallest4/3: smallest non-empty 4-connected component.
    connect_smallest4/3,
    % connect_border_cells/3: cells in a region adjacent to non-region cells.
    connect_border_cells/3,
    % connect_interior_cells/3: cells in a region with all 4-neighbors inside.
    connect_interior_cells/3,
    % connect_enclosed/3: background cells not reachable from the grid border.
    connect_enclosed/3
]).

% Import list and apply utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, subtract/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% connect_grid_dims_(+Grid, -Rows, -Cols): grid dimensions.
connect_grid_dims_(Grid, Rows, Cols) :-
    % Count rows with length/2.
    length(Grid, Rows),
    % Cols from first row length; 0 for empty grid.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% connect_in_bounds_(+R, +C, +Rows, +Cols): true if (R,C) is within the grid.
connect_in_bounds_(R, C, Rows, Cols) :-
    % Row and column both within [0, max).
    R >= 0, R < Rows, C >= 0, C < Cols.

% connect_cell_color_(+Grid, +R, +C, -V): value at (R,C) using nth0.
connect_cell_color_(Grid, R, C, V) :-
    % Get row R, then column C within that row.
    nth0(R, Grid, Row), nth0(C, Row, V).

% connect_neighbors4_(+R, +C, -Ns): 4-connected neighbors of r(R,C).
connect_neighbors4_(R, C, Ns) :-
    % Compute offsets for up, down, left, right.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Return all four neighbors as r(Row,Col) terms.
    Ns = [r(R1,C), r(R2,C), r(R,C1), r(R,C2)].

% connect_neighbors8_(+R, +C, -Ns): 8-connected neighbors of r(R,C).
connect_neighbors8_(R, C, Ns) :-
    % Compute offsets for cardinal and diagonal directions.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Return all eight neighbors as r(Row,Col) terms.
    Ns = [r(R1,C), r(R2,C), r(R,C1), r(R,C2),
          r(R1,C1), r(R1,C2), r(R2,C1), r(R2,C2)].

% connect_dfs_(+Stack, +Grid, +Rows, +Cols, +Color, +NF, +Seen, -Region)
% DFS flood fill: expand all cells reachable from Stack via NF that match Color.
% NF is connect_neighbors4_ or connect_neighbors8_ (called as NF(R,C,Neighbors)).
connect_dfs_([], _G, _Rows, _Cols, _Color, _NF, Seen, Seen).
connect_dfs_([r(R,C)|Stack], Grid, Rows, Cols, Color, NF, Seen, Region) :-
    % If already visited, skip this cell.
    ( memberchk(r(R,C), Seen) ->
        connect_dfs_(Stack, Grid, Rows, Cols, Color, NF, Seen, Region)
    % If in bounds and matches Color, expand neighbors.
    ; connect_in_bounds_(R, C, Rows, Cols),
      connect_cell_color_(Grid, R, C, V), V =:= Color ->
        % Get neighbors using the provided neighbor function.
        call(NF, R, C, Neighbors),
        % Push neighbors onto the front of the stack.
        append(Neighbors, Stack, Stack1),
        % Mark this cell visited and recurse.
        connect_dfs_(Stack1, Grid, Rows, Cols, Color, NF, [r(R,C)|Seen], Region)
    % Out of bounds or wrong color: skip.
    ;   connect_dfs_(Stack, Grid, Rows, Cols, Color, NF, Seen, Region)
    ).

% connect_flood4(+Grid, +r(R0,C0), +Color, -Region)
% Region is the 4-connected set of cells with Color reachable from r(R0,C0).
connect_flood4(Grid, r(R0,C0), Color, Region) :-
    % Get grid dimensions.
    connect_grid_dims_(Grid, Rows, Cols),
    % Check seed is in bounds and has the right color; empty region otherwise.
    ( connect_in_bounds_(R0, C0, Rows, Cols),
      connect_cell_color_(Grid, R0, C0, V), V =:= Color ->
        % DFS flood fill using 4-connected neighbor function.
        connect_dfs_([r(R0,C0)], Grid, Rows, Cols, Color, connect_neighbors4_, [], Region)
    ;   Region = []
    ).

% connect_flood8(+Grid, +r(R0,C0), +Color, -Region)
% Region is the 8-connected set of cells with Color reachable from r(R0,C0).
connect_flood8(Grid, r(R0,C0), Color, Region) :-
    % Get grid dimensions.
    connect_grid_dims_(Grid, Rows, Cols),
    % Check seed is in bounds and has the right color; empty region otherwise.
    ( connect_in_bounds_(R0, C0, Rows, Cols),
      connect_cell_color_(Grid, R0, C0, V), V =:= Color ->
        % DFS flood fill using 8-connected neighbor function.
        connect_dfs_([r(R0,C0)], Grid, Rows, Cols, Color, connect_neighbors8_, [], Region)
    ;   Region = []
    ).

% connect_all_cells_(+Grid, +Rows, +Cols, +Color, -Cells)
% Cells is the list of all r(R,C) positions in Grid with value Color.
connect_all_cells_(Grid, Rows, Cols, Color, Cells) :-
    % Build row index list; empty if no rows.
    ( Rows > 0 -> R1 is Rows-1, numlist(0, R1, Rs) ; Rs = [] ),
    % Build col index list; empty if no cols.
    ( Cols > 0 -> C1 is Cols-1, numlist(0, C1, Cs) ; Cs = [] ),
    % Collect all matching positions.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          connect_cell_color_(Grid, R, C, V), V =:= Color ),
        Cells).

% connect_extract_(+Cells, +Grid, +Rows, +Cols, +Color, +NF, -Components)
% Iteratively extract connected components from a list of same-color cells.
connect_extract_([], _, _, _, _, _, []).
connect_extract_([Seed|Rest], Grid, Rows, Cols, Color, NF, [Comp|Comps]) :-
    % Flood fill from Seed to find its component.
    connect_dfs_([Seed], Grid, Rows, Cols, Color, NF, [], Comp),
    % Remove component cells from the remaining pool.
    subtract(Rest, Comp, Remaining),
    % Recurse on remaining cells.
    connect_extract_(Remaining, Grid, Rows, Cols, Color, NF, Comps).

% connect_components4(+Grid, +Color, -Components)
% Components is the list of all 4-connected regions of Color in Grid.
connect_components4(Grid, Color, Components) :-
    % Get grid dimensions.
    connect_grid_dims_(Grid, Rows, Cols),
    % Collect all cells with Color.
    connect_all_cells_(Grid, Rows, Cols, Color, AllCells),
    % Extract components using 4-connected neighbor function.
    connect_extract_(AllCells, Grid, Rows, Cols, Color, connect_neighbors4_, Components).

% connect_components8(+Grid, +Color, -Components)
% Components is the list of all 8-connected regions of Color in Grid.
connect_components8(Grid, Color, Components) :-
    % Get grid dimensions.
    connect_grid_dims_(Grid, Rows, Cols),
    % Collect all cells with Color.
    connect_all_cells_(Grid, Rows, Cols, Color, AllCells),
    % Extract components using 8-connected neighbor function.
    connect_extract_(AllCells, Grid, Rows, Cols, Color, connect_neighbors8_, Components).

% connect_count4(+Grid, +Color, -N)
% N is the number of 4-connected components of Color in Grid.
connect_count4(Grid, Color, N) :-
    % Find all components, then count.
    connect_components4(Grid, Color, Comps),
    % length/2 is a SWI-Prolog built-in.
    length(Comps, N).

% connect_count8(+Grid, +Color, -N)
% N is the number of 8-connected components of Color in Grid.
connect_count8(Grid, Color, N) :-
    % Find all components, then count.
    connect_components8(Grid, Color, Comps),
    % length/2 is a SWI-Prolog built-in.
    length(Comps, N).

% connect_sizes4(+Grid, +Color, -Sizes)
% Sizes is the sorted list of 4-connected component sizes for Color.
connect_sizes4(Grid, Color, Sizes) :-
    % Find all components.
    connect_components4(Grid, Color, Comps),
    % Get raw sizes using maplist with length/2.
    maplist(length, Comps, RawSizes),
    % Sort ascending.
    msort(RawSizes, Sizes).

% connect_sizes8(+Grid, +Color, -Sizes)
% Sizes is the sorted list of 8-connected component sizes for Color.
connect_sizes8(Grid, Color, Sizes) :-
    % Find all components.
    connect_components8(Grid, Color, Comps),
    % Get raw sizes using maplist with length/2.
    maplist(length, Comps, RawSizes),
    % Sort ascending.
    msort(RawSizes, Sizes).

% connect_largest_from_(+Rest, +Current, -Largest)
% Largest is the longest list among [Current|Rest].
connect_largest_from_([], Best, Best).
connect_largest_from_([H|T], Best, Result) :-
    % Compare sizes; keep whichever is larger.
    length(H, NH), length(Best, NBest),
    ( NH > NBest ->
        connect_largest_from_(T, H, Result)
    ;   connect_largest_from_(T, Best, Result)
    ).

% connect_largest4(+Grid, +Color, -Largest)
% Largest is the largest 4-connected component of Color. Fails if none exist.
connect_largest4(Grid, Color, Largest) :-
    % Need at least one component; [First|Rest] fails if empty.
    connect_components4(Grid, Color, [First|Rest]),
    % Scan all components to find the largest.
    connect_largest_from_(Rest, First, Largest).

% connect_largest8(+Grid, +Color, -Largest)
% Largest is the largest 8-connected component of Color. Fails if none exist.
connect_largest8(Grid, Color, Largest) :-
    % Need at least one component; [First|Rest] fails if empty.
    connect_components8(Grid, Color, [First|Rest]),
    % Scan all components to find the largest.
    connect_largest_from_(Rest, First, Largest).

% connect_smallest_from_(+Rest, +Current, -Smallest)
% Smallest is the shortest list among [Current|Rest].
connect_smallest_from_([], Best, Best).
connect_smallest_from_([H|T], Best, Result) :-
    % Compare sizes; keep whichever is smaller.
    length(H, NH), length(Best, NBest),
    ( NH < NBest ->
        connect_smallest_from_(T, H, Result)
    ;   connect_smallest_from_(T, Best, Result)
    ).

% connect_smallest4(+Grid, +Color, -Smallest)
% Smallest is the smallest 4-connected component of Color. Fails if none exist.
connect_smallest4(Grid, Color, Smallest) :-
    % Need at least one component; [First|Rest] fails if empty.
    connect_components4(Grid, Color, [First|Rest]),
    % Scan all components to find the smallest.
    connect_smallest_from_(Rest, First, Smallest).

% connect_is_border_(+Rows, +Cols, +Region, +r(R,C)): true if r(R,C) is a border cell.
% A border cell has at least one 4-neighbor outside the grid or not in Region.
connect_is_border_(Rows, Cols, Region, r(R,C)) :-
    % Get 4-neighbors.
    connect_neighbors4_(R, C, Neighbors),
    % At least one neighbor is out-of-bounds or not in Region.
    member(r(NR,NC), Neighbors),
    ( \+ connect_in_bounds_(NR, NC, Rows, Cols)
    ; \+ memberchk(r(NR,NC), Region)
    ), !.

% connect_border_cells(+Grid, +Region, -Border)
% Border is the subset of Region whose cells are adjacent to non-Region or OOB.
connect_border_cells(Grid, Region, Border) :-
    % Get grid dimensions for bounds checking.
    connect_grid_dims_(Grid, Rows, Cols),
    % Keep only border cells.
    include(connect_is_border_(Rows, Cols, Region), Region, Border).

% connect_all_in_region_(+Neighbors, +Rows, +Cols, +Region)
% Succeeds if every neighbor is in-bounds AND in Region.
% An OOB neighbor fails: r(R,C) on the grid edge cannot be interior.
connect_all_in_region_([], _, _, _).
connect_all_in_region_([r(R,C)|Rest], Rows, Cols, Region) :-
    % Neighbor must be in-bounds (OOB means cell touches grid edge, not interior).
    connect_in_bounds_(R, C, Rows, Cols),
    % Neighbor must be in Region.
    memberchk(r(R,C), Region),
    % Check remaining neighbors.
    connect_all_in_region_(Rest, Rows, Cols, Region).

% connect_is_interior_(+Rows, +Cols, +Region, +r(R,C)): true if r(R,C) is interior.
% An interior cell has all 4 neighbors in-bounds AND in Region.
connect_is_interior_(Rows, Cols, Region, r(R,C)) :-
    % Get 4-neighbors.
    connect_neighbors4_(R, C, Neighbors),
    % All 4 neighbors must be in-bounds and in Region.
    connect_all_in_region_(Neighbors, Rows, Cols, Region).

% connect_interior_cells(+Grid, +Region, -Interior)
% Interior is the subset of Region where all 4-in-bounds-neighbors are in Region.
connect_interior_cells(Grid, Region, Interior) :-
    % Get grid dimensions for bounds checking.
    connect_grid_dims_(Grid, Rows, Cols),
    % Keep only interior cells.
    include(connect_is_interior_(Rows, Cols, Region), Region, Interior).

% connect_is_on_border_(+Rows, +Cols, +r(R,C)): true if cell is on the grid boundary.
connect_is_on_border_(Rows, Cols, r(R,C)) :-
    % Cell is on a grid edge.
    ( R =:= 0 ; R =:= Rows-1 ; C =:= 0 ; C =:= Cols-1 ).

% connect_multi_dfs_(+Seeds, +Grid, +Rows, +Cols, +Color, +Seen, -Reachable)
% Flood fill from multiple seeds, accumulating visited cells across all fills.
connect_multi_dfs_([], _, _, _, _, Seen, Seen).
connect_multi_dfs_([Seed|Seeds], Grid, Rows, Cols, Color, Seen, Result) :-
    % Flood fill from one seed, accumulating into Seen.
    connect_dfs_([Seed], Grid, Rows, Cols, Color, connect_neighbors4_, Seen, Seen1),
    % Continue with remaining seeds and accumulated visited set.
    connect_multi_dfs_(Seeds, Grid, Rows, Cols, Color, Seen1, Result).

% connect_enclosed(+Grid, +BG, -Enclosed)
% Enclosed is the list of BG-colored cells not reachable from any grid-border BG cell.
connect_enclosed(Grid, BG, Enclosed) :-
    % Get grid dimensions.
    connect_grid_dims_(Grid, Rows, Cols),
    % Find all BG cells.
    connect_all_cells_(Grid, Rows, Cols, BG, BGCells),
    % Filter to those on the grid border as flood seeds.
    include(connect_is_on_border_(Rows, Cols), BGCells, BorderSeeds),
    % Flood fill from all border BG cells to find all reachable BG cells.
    connect_multi_dfs_(BorderSeeds, Grid, Rows, Cols, BG, [], Reachable),
    % Enclosed = BG cells not reached from border.
    subtract(BGCells, Reachable, Enclosed).
