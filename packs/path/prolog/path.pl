% Module path: path-finding, flood-fill, connectivity, and reachability in grids.
% Layer 43. Prefix: pf_. Depends on grid pack only.
:- module(path, [
    % 4-connected flood fill: find all cells reachable from a seed cell with
    % the same color as the seed, using 4-connectivity (up,down,left,right).
    path_flood_fill/4,
    % Test whether two cells are connected (reachable from each other via same color).
    path_connected/4,
    % Find all connected components of a given color in a grid.
    path_components/3,
    % Count how many connected components of a given color exist.
    path_component_count/3,
    % Find the size (cell count) of the connected component containing a seed cell.
    path_component_size/4,
    % Find the largest connected component of a given color.
    path_largest_component/3,
    % BFS shortest path between two cells in a grid (only cells not equal to Wall color).
    path_shortest_path/5,
    % BFS shortest path length.
    path_path_length/5,
    % Test whether a path exists between two cells.
    path_path_exists/4,
    % Find all cells reachable from a seed by 4-connectivity (any color, not Wall).
    path_reachable/4,
    % Flood fill and return the bounding box of the filled region.
    path_fill_bbox/7,
    % Test whether a grid region is fully connected (all same-color cells reachable
    % from any one of them).
    path_is_connected/2,
    % Find all neighbor cells of r(R,C) that are within bounds.
    path_neighbors/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, numlist/3,
                                last/2, min_list/2, max_list/2, subtract/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).
% Load grid pack.
:- use_module(library(grid)).

% path_neighbors(+Grid, +r(R,C), -Neighbors)
% Return the list of valid 4-connected neighbors of r(R,C) within grid bounds.
path_neighbors(Grid, r(R, C), Neighbors) :-
    grid_size(Grid, Rows, Cols),
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

% path_flood_fill(+Grid, +r(R,C), +Color, -Region)
% Find all cells reachable from r(R,C) via 4-connectivity where the cell color = Color.
% Region is a sorted list of r(R,C) terms.
path_flood_fill(Grid, Seed, Color, Region) :-
    grid_cell(Grid, Seed, Color),
    path_bfs_same_color_(Grid, Color, [Seed], [Seed], Region0),
    msort(Region0, Region).

% path_bfs_same_color_(Grid, Color, Queue, Visited, Region)
% BFS over cells matching Color.
path_bfs_same_color_(_Grid, _Color, [], Visited, Visited).
path_bfs_same_color_(Grid, Color, [Current|Rest], Visited, Region) :-
    % Get neighbors within bounds.
    path_neighbors(Grid, Current, Neighbors),
    % Keep only those with the right color not yet visited.
    include(path_unvisited_color_(Grid, Color, Visited), Neighbors, New),
    % Add new cells to queue and visited.
    append(Rest, New, Queue2),
    append(Visited, New, Visited2),
    path_bfs_same_color_(Grid, Color, Queue2, Visited2, Region).

% path_unvisited_color_(Grid, Color, Visited, Cell)
% Succeeds if Cell has Color and is not in Visited.
path_unvisited_color_(Grid, Color, Visited, Cell) :-
    grid_cell(Grid, Cell, Color),
    \+ member(Cell, Visited).

% path_connected(+Grid, +CellA, +CellB, +Color)
% Succeed if CellA and CellB are in the same connected component of Color.
path_connected(Grid, CellA, CellB, Color) :-
    path_flood_fill(Grid, CellA, Color, Region),
    member(CellB, Region).

% path_components(+Grid, +Color, -Components)
% Find all connected components of Color in Grid.
% Components is a list of sorted cell lists.
path_components(Grid, Color, Components) :-
    % Find all cells of this Color.
    grid_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(r(R, C),
        (   between(0, R1, R),
            between(0, C1, C),
            grid_cell(Grid, R, C, Color)
        ),
        AllCells),
    % Group into connected components.
    path_group_components_(Grid, Color, AllCells, Components).

% path_group_components_(Grid, Color, Remaining, Components)
% Iteratively pick the first remaining cell, flood fill, subtract the region,
% and recurse.
path_group_components_(_Grid, _Color, [], []).
path_group_components_(Grid, Color, [Seed|Rest], [Region|More]) :-
    path_flood_fill(Grid, Seed, Color, Region),
    subtract(Rest, Region, Remaining),
    path_group_components_(Grid, Color, Remaining, More).

% path_component_count(+Grid, +Color, -N)
% N is the number of connected components of Color in Grid.
path_component_count(Grid, Color, N) :-
    path_components(Grid, Color, Components),
    length(Components, N).

% path_component_size(+Grid, +r(R,C), +Color, -Size)
% Size is the number of cells in the connected component containing r(R,C).
path_component_size(Grid, Seed, Color, Size) :-
    path_flood_fill(Grid, Seed, Color, Region),
    length(Region, Size).

% path_largest_component(+Grid, +Color, -Region)
% Region is the largest connected component of Color (by cell count).
% If tied, the component appearing first (sorted by seed position) wins.
path_largest_component(Grid, Color, Region) :-
    path_components(Grid, Color, Components),
    Components = [_|_],
    foldl(path_max_component_, Components, [], Region).

% path_max_component_(Comp, Best, NewBest)
% Keep the larger of two components; on tie, keep the current best.
path_max_component_(Comp, [], Comp) :- !.
path_max_component_(Comp, Best, NewBest) :-
    length(Comp, LC),
    length(Best, LB),
    (LC > LB -> NewBest = Comp ; NewBest = Best).

% path_shortest_path(+Grid, +Start, +Goal, +Wall, -Path)
% BFS from Start to Goal avoiding cells of color Wall.
% Path is a list of r(R,C) terms from Start to Goal (inclusive).
% Fails if no path exists.
path_shortest_path(Grid, Start, Goal, Wall, Path) :-
    grid_cell(Grid, Start, StartColor), StartColor \= Wall,
    grid_cell(Grid, Goal, GoalColor), GoalColor \= Wall,
    path_bfs_path_(Grid, Wall, [[Start]], Goal, RevPath),
    reverse(RevPath, Path).

% path_bfs_path_(Grid, Wall, Frontier, Goal, Path)
% Frontier is a list of partial paths (each a list in reverse order from Start).
path_bfs_path_(_Grid, _Wall, [Current|_], Goal, Current) :-
    Current = [Goal|_].
path_bfs_path_(Grid, Wall, [Current|Rest], Goal, Path) :-
    Current = [Head|_],
    path_neighbors(Grid, Head, Neighbors),
    % Filter: not Wall, not already in Current path.
    include(path_not_wall_or_visited_(Grid, Wall, Current), Neighbors, New),
    % Extend path.
    maplist(path_extend_path_(Current), New, NewPaths),
    append(Rest, NewPaths, Frontier2),
    path_bfs_path_(Grid, Wall, Frontier2, Goal, Path).

% path_not_wall_or_visited_(Grid, Wall, Visited, Cell)
path_not_wall_or_visited_(Grid, Wall, Visited, Cell) :-
    grid_cell(Grid, Cell, CellColor),
    CellColor \= Wall,
    \+ member(Cell, Visited).

% path_extend_path_(Current, New, Extended)
path_extend_path_(Current, New, [New|Current]).

% path_path_length(+Grid, +Start, +Goal, +Wall, -Len)
% BFS shortest path length (number of cells in path minus 1 = number of steps).
path_path_length(Grid, Start, Goal, Wall, Len) :-
    path_shortest_path(Grid, Start, Goal, Wall, Path),
    length(Path, L),
    Len is L - 1.

% path_path_exists(+Grid, +Start, +Goal, +Wall)
% Succeed if a path exists from Start to Goal avoiding Wall.
path_path_exists(Grid, Start, Goal, Wall) :-
    path_shortest_path(Grid, Start, Goal, Wall, _Path).

% path_reachable(+Grid, +Seed, +Wall, -Cells)
% Find all cells reachable from Seed by 4-connectivity without crossing Wall-colored cells.
% Seed itself must not be Wall.
path_reachable(Grid, Seed, Wall, Cells) :-
    grid_cell(Grid, Seed, SeedColor),
    SeedColor \= Wall,
    path_bfs_not_wall_(Grid, Wall, [Seed], [Seed], Cells0),
    msort(Cells0, Cells).

% path_bfs_not_wall_(Grid, Wall, Queue, Visited, Result)
path_bfs_not_wall_(_Grid, _Wall, [], Visited, Visited).
path_bfs_not_wall_(Grid, Wall, [Current|Rest], Visited, Result) :-
    path_neighbors(Grid, Current, Neighbors),
    include(path_not_wall_unvisited_(Grid, Wall, Visited), Neighbors, New),
    append(Rest, New, Queue2),
    append(Visited, New, Visited2),
    path_bfs_not_wall_(Grid, Wall, Queue2, Visited2, Result).

% path_not_wall_unvisited_(Grid, Wall, Visited, Cell)
path_not_wall_unvisited_(Grid, Wall, Visited, Cell) :-
    grid_cell(Grid, Cell, Color),
    Color \= Wall,
    \+ member(Cell, Visited).

% path_fill_bbox(+Grid, +Seed, +Color, -R0, -C0, -R1, -C1)
% Flood fill from Seed (matching Color) and return the bounding box of the region.
% R0,C0 = top-left; R1,C1 = bottom-right.
path_fill_bbox(Grid, Seed, Color, R0, C0, R1, C1) :-
    path_flood_fill(Grid, Seed, Color, Region),
    maplist(path_row_of_, Region, Rows),
    maplist(path_col_of_, Region, Cols),
    min_list(Rows, R0),
    max_list(Rows, R1),
    min_list(Cols, C0),
    max_list(Cols, C1).

% path_row_of_(r(R,_), R).
path_row_of_(r(R, _), R).

% path_col_of_(r(_,C), C).
path_col_of_(r(_, C), C).

% path_is_connected(+Grid, +Color)
% Succeed if all cells of Color in Grid are in a single connected component.
% Trivially true if there are 0 or 1 cells of Color.
path_is_connected(Grid, Color) :-
    path_components(Grid, Color, Components),
    length(Components, N),
    N =< 1.

% grid_cell/3 overload accepting r(R,C) term - delegates to grid_cell/4.
grid_cell(Grid, r(R, C), Color) :-
    grid_cell(Grid, R, C, Color).
