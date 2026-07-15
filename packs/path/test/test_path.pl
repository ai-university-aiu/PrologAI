% PLUnit tests for the path pack (pf_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(path)).

% Grid fixtures.
% A 4x4 grid: 0 = open, 1 = wall.
% Two open regions: top-left 2x2 and bottom-right 2x2, separated by wall.
two_regions(Grid) :-
    Grid = [[0,0,1,1],
            [0,0,1,1],
            [1,1,0,0],
            [1,1,0,0]].

% A 5x5 maze: 0 = open, 1 = wall. Open path from (0,0) to (4,4).
maze_5x5(Grid) :-
    Grid = [[0,1,0,0,0],
            [0,1,0,1,0],
            [0,0,0,1,0],
            [1,1,1,1,0],
            [0,0,0,0,0]].

% A 3x3 uniform grid (all color 2).
uniform_3x3(Grid) :-
    Grid = [[2,2,2],
            [2,2,2],
            [2,2,2]].

% A 4x4 grid with two separate color-3 blobs.
two_blobs(Grid) :-
    Grid = [[3,3,0,0],
            [3,0,0,3],
            [0,0,3,3],
            [0,0,3,0]].

% A 3x3 grid for bounding box test.
blob_bbox(Grid) :-
    Grid = [[0,0,0],
            [0,5,5],
            [0,5,0]].

:- begin_tests(path_neighbors).

test(neighbors_center, [nondet]) :-
    uniform_3x3(G),
    path_neighbors(G, r(1,1), Ns),
    msort(Ns, NSorted),
    NSorted = [r(0,1), r(1,0), r(1,2), r(2,1)].

test(neighbors_corner, [nondet]) :-
    uniform_3x3(G),
    path_neighbors(G, r(0,0), Ns),
    msort(Ns, NSorted),
    NSorted = [r(0,1), r(1,0)].

test(neighbors_edge, [nondet]) :-
    uniform_3x3(G),
    path_neighbors(G, r(0,1), Ns),
    msort(Ns, NSorted),
    NSorted = [r(0,0), r(0,2), r(1,1)].

:- end_tests(path_neighbors).

:- begin_tests(path_flood_fill).

test(flood_fill_full, [nondet]) :-
    uniform_3x3(G),
    path_flood_fill(G, r(0,0), 2, Region),
    length(Region, 9).

test(flood_fill_partial, [nondet]) :-
    two_regions(G),
    path_flood_fill(G, r(0,0), 0, Region),
    % Top-left 2x2 open region: r(0,0), r(0,1), r(1,0), r(1,1).
    length(Region, 4),
    member(r(0,0), Region),
    member(r(1,1), Region).

test(flood_fill_single, [nondet]) :-
    two_regions(G),
    % r(0,2) is color 1; the top-right 1-block has 4 cells.
    % The bottom-left 1-block is separate (not connected via 4-connectivity).
    path_flood_fill(G, r(0,2), 1, Region),
    length(Region, 4).

test(flood_fill_bottom_right, [nondet]) :-
    two_regions(G),
    path_flood_fill(G, r(2,2), 0, Region),
    length(Region, 4),
    member(r(3,3), Region).

:- end_tests(path_flood_fill).

:- begin_tests(path_connected).

test(connected_same_region, [nondet]) :-
    two_regions(G),
    path_connected(G, r(0,0), r(1,1), 0).

test(not_connected_diff_region, [fail]) :-
    two_regions(G),
    path_connected(G, r(0,0), r(2,2), 0).

test(connected_uniform, [nondet]) :-
    uniform_3x3(G),
    path_connected(G, r(0,0), r(2,2), 2).

:- end_tests(path_connected).

:- begin_tests(path_components).

test(components_two_regions, [nondet]) :-
    two_regions(G),
    path_components(G, 0, Comps),
    length(Comps, 2),
    % Each component has 4 cells.
    maplist([C]>>(length(C, 4)), Comps).

test(components_uniform, [nondet]) :-
    uniform_3x3(G),
    path_components(G, 2, Comps),
    length(Comps, 1),
    Comps = [Region],
    length(Region, 9).

test(components_none, [nondet]) :-
    uniform_3x3(G),
    path_components(G, 9, Comps),
    Comps = [].

test(components_two_blobs, [nondet]) :-
    two_blobs(G),
    path_components(G, 3, Comps),
    length(Comps, 2).

:- end_tests(path_components).

:- begin_tests(path_component_count).

test(count_two, [nondet]) :-
    two_regions(G),
    path_component_count(G, 0, N),
    N =:= 2.

test(count_one, [nondet]) :-
    uniform_3x3(G),
    path_component_count(G, 2, N),
    N =:= 1.

test(count_zero, [nondet]) :-
    uniform_3x3(G),
    path_component_count(G, 9, N),
    N =:= 0.

:- end_tests(path_component_count).

:- begin_tests(path_component_size).

test(size_region, [nondet]) :-
    two_regions(G),
    path_component_size(G, r(0,0), 0, Size),
    Size =:= 4.

test(size_uniform, [nondet]) :-
    uniform_3x3(G),
    path_component_size(G, r(1,1), 2, Size),
    Size =:= 9.

:- end_tests(path_component_size).

:- begin_tests(path_largest_component).

test(largest_two_blobs, [nondet]) :-
    % two_blobs has two color-3 blobs; first blob: r(0,0),r(0,1),r(1,0) = 3 cells;
    % second blob: r(1,3),r(2,2),r(2,3),r(3,2) = 4 cells. Largest = 4.
    two_blobs(G),
    path_largest_component(G, 3, Region),
    length(Region, 4).

test(largest_uniform, [nondet]) :-
    uniform_3x3(G),
    path_largest_component(G, 2, Region),
    length(Region, 9).

:- end_tests(path_largest_component).

:- begin_tests(path_shortest_path).

test(path_straight, [nondet]) :-
    % 3x3 uniform open grid; wall = 9 (not present).
    uniform_3x3(G),
    path_shortest_path(G, r(0,0), r(0,2), 9, Path),
    % Shortest is along top row: [r(0,0),r(0,1),r(0,2)].
    length(Path, 3),
    last(Path, r(0,2)).

test(path_maze, [nondet]) :-
    % maze_5x5: path from (0,0) to (4,4), wall = 1.
    maze_5x5(G),
    path_shortest_path(G, r(0,0), r(4,4), 1, Path),
    % Path exists and ends at goal.
    last(Path, r(4,4)),
    Path = [r(0,0)|_].

test(path_no_path, [fail]) :-
    two_regions(G),
    % r(0,0) and r(2,2) are in different open regions separated by walls.
    path_shortest_path(G, r(0,0), r(2,2), 1, _).

:- end_tests(path_shortest_path).

:- begin_tests(path_length).

test(path_length_adjacent, [nondet]) :-
    uniform_3x3(G),
    path_path_length(G, r(0,0), r(0,1), 9, Len),
    Len =:= 1.

test(path_length_two_steps, [nondet]) :-
    uniform_3x3(G),
    path_path_length(G, r(0,0), r(0,2), 9, Len),
    Len =:= 2.

test(path_length_self, [nondet]) :-
    uniform_3x3(G),
    path_path_length(G, r(1,1), r(1,1), 9, Len),
    Len =:= 0.

:- end_tests(path_length).

:- begin_tests(path_exists).

test(path_exists_yes, [nondet]) :-
    maze_5x5(G),
    path_path_exists(G, r(0,0), r(4,4), 1).

test(path_exists_no, [fail]) :-
    two_regions(G),
    path_path_exists(G, r(0,0), r(2,2), 1).

:- end_tests(path_exists).

:- begin_tests(path_reachable).

test(reachable_open_region, [nondet]) :-
    two_regions(G),
    path_reachable(G, r(0,0), 1, Cells),
    length(Cells, 4).

test(reachable_whole_grid, [nondet]) :-
    uniform_3x3(G),
    path_reachable(G, r(0,0), 9, Cells),
    length(Cells, 9).

:- end_tests(path_reachable).

:- begin_tests(path_fill_bbox).

test(fill_bbox_blob, [nondet]) :-
    blob_bbox(G),
    path_fill_bbox(G, r(1,1), 5, R0, C0, R1, C1),
    % r(1,1), r(1,2), r(2,1) are all 5 and connected.
    R0 =:= 1, C0 =:= 1, R1 =:= 2, C1 =:= 2.

test(fill_bbox_full, [nondet]) :-
    uniform_3x3(G),
    path_fill_bbox(G, r(0,0), 2, R0, C0, R1, C1),
    R0 =:= 0, C0 =:= 0, R1 =:= 2, C1 =:= 2.

:- end_tests(path_fill_bbox).

:- begin_tests(path_is_connected).

test(is_connected_uniform, [nondet]) :-
    uniform_3x3(G),
    path_is_connected(G, 2).

test(is_connected_single_cell, [nondet]) :-
    Grid = [[5,0],[0,0]],
    path_is_connected(Grid, 5).

test(is_connected_no_cells, [nondet]) :-
    uniform_3x3(G),
    path_is_connected(G, 9).

test(not_connected_two_regions, [fail]) :-
    two_regions(G),
    path_is_connected(G, 0).

:- end_tests(path_is_connected).
