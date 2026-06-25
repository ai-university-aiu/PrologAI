% Module path: path-finding, flood-fill, connectivity, and reachability in grids.
% Layer 43. Prefix: pf_. Depends on grid pack only.
:- module(path, [
    % 4-connected flood fill: find all cells reachable from a seed cell with
    % the same color as the seed, using 4-connectivity (up,down,left,right).
    pf_flood_fill/4,
    % Test whether two cells are connected (reachable from each other via same color).
    pf_connected/4,
    % Find all connected components of a given color in a grid.
    pf_components/3,
    % Count how many connected components of a given color exist.
    pf_component_count/3,
    % Find the size (cell count) of the connected component containing a seed cell.
    pf_component_size/4,
    % Find the largest connected component of a given color.
    pf_largest_component/3,
    % BFS shortest path between two cells in a grid (only cells not equal to Wall color).
    pf_shortest_path/5,
    % BFS shortest path length.
    pf_path_length/5,
    % Test whether a path exists between two cells.
    pf_path_exists/4,
    % Find all cells reachable from a seed by 4-connectivity (any color, not Wall).
    pf_reachable/4,
    % Flood fill and return the bounding box of the filled region.
    pf_fill_bbox/7,
    % Test whether a grid region is fully connected (all same-color cells reachable
    % from any one of them).
    pf_is_connected/2,
    % Find all neighbor cells of r(R,C) that are within bounds.
    pf_neighbors/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, numlist/3,
                                last/2, min_list/2, max_list/2, subtract/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).
% Load grid pack.
:- use_module(library(grid)).

% pf_neighbors(+Grid, +r(R,C), -Neighbors)
% Return the list of valid 4-connected neighbors of r(R,C) within grid bounds.
pf_neighbors(Grid, r(R, C), Neighbors) :-
    gd_size(Grid, Rows, Cols),
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Compute the four candidate neighbor coordinates.
    R0 is R - 1, R1 is R + 1, C0 is C - 1, C1 is C + 1,
    % Collect only those within bounds.
    findall(r(NR, NC),
        (   member(r(NR, NC), [r(R0,C), r(R1,C), r(R,C0), r(R,C1)]),
            NR >= 0, NR =< MaxR,
            NC >= 0, NC =< MaxC
        ),
        Neighbors).

% pf_flood_fill(+Grid, +r(R,C), +Color, -Region)
% Find all cells reachable from r(R,C) via 4-connectivity where the cell color = Color.
% Region is a sorted list of r(R,C) terms.
pf_flood_fill(Grid, Seed, Color, Region) :-
    gd_cell(Grid, Seed, Color),
    pf_bfs_same_color_(Grid, Color, [Seed], [Seed], Region0),
    msort(Region0, Region).

% pf_bfs_same_color_(Grid, Color, Queue, Visited, Region)
% BFS over cells matching Color.
pf_bfs_same_color_(_Grid, _Color, [], Visited, Visited).
pf_bfs_same_color_(Grid, Color, [Current|Rest], Visited, Region) :-
    % Get neighbors within bounds.
    pf_neighbors(Grid, Current, Neighbors),
    % Keep only those with the right color not yet visited.
    include(pf_unvisited_color_(Grid, Color, Visited), Neighbors, New),
    % Add new cells to queue and visited.
    append(Rest, New, Queue2),
    append(Visited, New, Visited2),
    pf_bfs_same_color_(Grid, Color, Queue2, Visited2, Region).

% pf_unvisited_color_(Grid, Color, Visited, Cell)
% Succeeds if Cell has Color and is not in Visited.
pf_unvisited_color_(Grid, Color, Visited, Cell) :-
    gd_cell(Grid, Cell, Color),
    \+ member(Cell, Visited).

% pf_connected(+Grid, +CellA, +CellB, +Color)
% Succeed if CellA and CellB are in the same connected component of Color.
pf_connected(Grid, CellA, CellB, Color) :-
    pf_flood_fill(Grid, CellA, Color, Region),
    member(CellB, Region).

% pf_components(+Grid, +Color, -Components)
% Find all connected components of Color in Grid.
% Components is a list of sorted cell lists.
pf_components(Grid, Color, Components) :-
    % Find all cells of this Color.
    gd_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(r(R, C),
        (   between(0, R1, R),
            between(0, C1, C),
            gd_cell(Grid, R, C, Color)
        ),
        AllCells),
    % Group into connected components.
    pf_group_components_(Grid, Color, AllCells, Components).

% pf_group_components_(Grid, Color, Remaining, Components)
% Iteratively pick the first remaining cell, flood fill, subtract the region,
% and recurse.
pf_group_components_(_Grid, _Color, [], []).
pf_group_components_(Grid, Color, [Seed|Rest], [Region|More]) :-
    pf_flood_fill(Grid, Seed, Color, Region),
    subtract(Rest, Region, Remaining),
    pf_group_components_(Grid, Color, Remaining, More).

% pf_component_count(+Grid, +Color, -N)
% N is the number of connected components of Color in Grid.
pf_component_count(Grid, Color, N) :-
    pf_components(Grid, Color, Components),
    length(Components, N).

% pf_component_size(+Grid, +r(R,C), +Color, -Size)
% Size is the number of cells in the connected component containing r(R,C).
pf_component_size(Grid, Seed, Color, Size) :-
    pf_flood_fill(Grid, Seed, Color, Region),
    length(Region, Size).

% pf_largest_component(+Grid, +Color, -Region)
% Region is the largest connected component of Color (by cell count).
% If tied, the component appearing first (sorted by seed position) wins.
pf_largest_component(Grid, Color, Region) :-
    pf_components(Grid, Color, Components),
    Components = [_|_],
    foldl(pf_max_component_, Components, [], Region).

% pf_max_component_(Comp, Best, NewBest)
% Keep the larger of two components; on tie, keep the current best.
pf_max_component_(Comp, [], Comp) :- !.
pf_max_component_(Comp, Best, NewBest) :-
    length(Comp, LC),
    length(Best, LB),
    (LC > LB -> NewBest = Comp ; NewBest = Best).

% pf_shortest_path(+Grid, +Start, +Goal, +Wall, -Path)
% BFS from Start to Goal avoiding cells of color Wall.
% Path is a list of r(R,C) terms from Start to Goal (inclusive).
% Fails if no path exists.
pf_shortest_path(Grid, Start, Goal, Wall, Path) :-
    gd_cell(Grid, Start, StartColor), StartColor \= Wall,
    gd_cell(Grid, Goal, GoalColor), GoalColor \= Wall,
    pf_bfs_path_(Grid, Wall, [[Start]], Goal, RevPath),
    reverse(RevPath, Path).

% pf_bfs_path_(Grid, Wall, Frontier, Goal, Path)
% Frontier is a list of partial paths (each a list in reverse order from Start).
pf_bfs_path_(_Grid, _Wall, [Current|_], Goal, Current) :-
    Current = [Goal|_].
pf_bfs_path_(Grid, Wall, [Current|Rest], Goal, Path) :-
    Current = [Head|_],
    pf_neighbors(Grid, Head, Neighbors),
    % Filter: not Wall, not already in Current path.
    include(pf_not_wall_or_visited_(Grid, Wall, Current), Neighbors, New),
    % Extend path.
    maplist(pf_extend_path_(Current), New, NewPaths),
    append(Rest, NewPaths, Frontier2),
    pf_bfs_path_(Grid, Wall, Frontier2, Goal, Path).

% pf_not_wall_or_visited_(Grid, Wall, Visited, Cell)
pf_not_wall_or_visited_(Grid, Wall, Visited, Cell) :-
    gd_cell(Grid, Cell, CellColor),
    CellColor \= Wall,
    \+ member(Cell, Visited).

% pf_extend_path_(Current, New, Extended)
pf_extend_path_(Current, New, [New|Current]).

% pf_path_length(+Grid, +Start, +Goal, +Wall, -Len)
% BFS shortest path length (number of cells in path minus 1 = number of steps).
pf_path_length(Grid, Start, Goal, Wall, Len) :-
    pf_shortest_path(Grid, Start, Goal, Wall, Path),
    length(Path, L),
    Len is L - 1.

% pf_path_exists(+Grid, +Start, +Goal, +Wall)
% Succeed if a path exists from Start to Goal avoiding Wall.
pf_path_exists(Grid, Start, Goal, Wall) :-
    pf_shortest_path(Grid, Start, Goal, Wall, _Path).

% pf_reachable(+Grid, +Seed, +Wall, -Cells)
% Find all cells reachable from Seed by 4-connectivity without crossing Wall-colored cells.
% Seed itself must not be Wall.
pf_reachable(Grid, Seed, Wall, Cells) :-
    gd_cell(Grid, Seed, SeedColor),
    SeedColor \= Wall,
    pf_bfs_not_wall_(Grid, Wall, [Seed], [Seed], Cells0),
    msort(Cells0, Cells).

% pf_bfs_not_wall_(Grid, Wall, Queue, Visited, Result)
pf_bfs_not_wall_(_Grid, _Wall, [], Visited, Visited).
pf_bfs_not_wall_(Grid, Wall, [Current|Rest], Visited, Result) :-
    pf_neighbors(Grid, Current, Neighbors),
    include(pf_not_wall_unvisited_(Grid, Wall, Visited), Neighbors, New),
    append(Rest, New, Queue2),
    append(Visited, New, Visited2),
    pf_bfs_not_wall_(Grid, Wall, Queue2, Visited2, Result).

% pf_not_wall_unvisited_(Grid, Wall, Visited, Cell)
pf_not_wall_unvisited_(Grid, Wall, Visited, Cell) :-
    gd_cell(Grid, Cell, Color),
    Color \= Wall,
    \+ member(Cell, Visited).

% pf_fill_bbox(+Grid, +Seed, +Color, -R0, -C0, -R1, -C1)
% Flood fill from Seed (matching Color) and return the bounding box of the region.
% R0,C0 = top-left; R1,C1 = bottom-right.
pf_fill_bbox(Grid, Seed, Color, R0, C0, R1, C1) :-
    pf_flood_fill(Grid, Seed, Color, Region),
    maplist(pf_row_of_, Region, Rows),
    maplist(pf_col_of_, Region, Cols),
    min_list(Rows, R0),
    max_list(Rows, R1),
    min_list(Cols, C0),
    max_list(Cols, C1).

% pf_row_of_(r(R,_), R).
pf_row_of_(r(R, _), R).

% pf_col_of_(r(_,C), C).
pf_col_of_(r(_, C), C).

% pf_is_connected(+Grid, +Color)
% Succeed if all cells of Color in Grid are in a single connected component.
% Trivially true if there are 0 or 1 cells of Color.
pf_is_connected(Grid, Color) :-
    pf_components(Grid, Color, Components),
    length(Components, N),
    N =< 1.

% gd_cell/3 overload accepting r(R,C) term - delegates to gd_cell/4.
gd_cell(Grid, r(R, C), Color) :-
    gd_cell(Grid, R, C, Color).
