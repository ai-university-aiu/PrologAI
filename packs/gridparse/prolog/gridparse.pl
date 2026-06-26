% gridparse.pl - Layer 197: Conversion between Raw Grid Format and obj(Color,Cells) Scenes
%                (gp_* prefix).
% A raw grid is a list of rows, each row a list of color atoms (0-indexed R,C).
% An obj(Color, Cells) scene is a list of object terms where each object has a color
% atom and a list of r(Row,Col) cell coordinates.
% Provides: background detection, cell extraction, 4-connected component flood fill,
% grid-to-scene parsing, scene-to-grid rendering, object statistics, grid equality.
% No cross-pack dependencies. Uses library(lists) and library(apply) only.
:- module(gridparse, [
    % gp_bg_color/2: most frequent color in the grid (background).
    gp_bg_color/2,
    % gp_grid_cells/3: list of r(R,C) positions where the grid has a given color.
    gp_grid_cells/3,
    % gp_color_components/3: partition gp_grid_cells into 4-connected components.
    gp_color_components/3,
    % gp_grid_to_scene/3: extract all non-background objects from a grid.
    gp_grid_to_scene/3,
    % gp_scene_to_grid/5: render a scene onto a blank grid with a background color.
    gp_scene_to_grid/5,
    % gp_n_objects/3: count of non-background 4-connected objects in a grid.
    gp_n_objects/3,
    % gp_object_colors/3: sorted list of distinct non-background colors in a grid.
    gp_object_colors/3,
    % gp_largest_object/3: largest non-background object by cell count.
    gp_largest_object/3,
    % gp_smallest_object/3: smallest non-background object by cell count.
    gp_smallest_object/3,
    % gp_objects_by_size/3: non-background objects sorted by cell count descending.
    gp_objects_by_size/3,
    % gp_grid_from_rows/4: create an H x W grid filled uniformly with Color.
    gp_grid_from_rows/4,
    % gp_paint_obj/3: paint one obj(Color,Cells) term onto a grid.
    gp_paint_obj/3,
    % gp_paint_scene/3: paint all objects in a scene onto a grid.
    gp_paint_scene/3,
    % gp_grid_equal/2: succeed if two grids are identical cell-by-cell.
    gp_grid_equal/2
]).

% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, memberchk/2, subtract/3, numlist/3]).
% Import apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).

% gp_bg_color(+Grid, -BgColor)
% BgColor is the most frequent color in Grid (background by convention).
% Ties broken by standard term order.
gp_bg_color(Grid, BgColor) :-
% Collect all cells.
    findall(C, (member(Row, Grid), member(C, Row)), All),
% Sort to get distinct colors.
    sort(All, Colors),
    Colors \= [],
% Key each color by negative count for msort descending.
    findall(NegN-C, (member(C, Colors), gp_count_(All, C, N), NegN is -N), Keyed),
    msort(Keyed, [_-BgColor | _]).

% gp_count_(+List, +Elem, -N): count occurrences of Elem in List.
gp_count_(List, Elem, N) :-
    include(=(Elem), List, Matches), length(Matches, N).

% gp_grid_cells(+Grid, +Color, -Cells)
% Cells is the list of r(R,C) positions where Grid has value Color.
% Order is row-major: row 0 first, left-to-right within each row.
gp_grid_cells(Grid, Color, Cells) :-
    findall(r(R,C),
        (nth0(R, Grid, Row),
         nth0(C, Row, V),
         V == Color),
        Cells).

% gp_color_components(+Grid, +Color, -Components)
% Components is a list of cell-lists, one per 4-connected component of Color in Grid.
% Uses a flood-fill starting from the first unvisited Color cell.
gp_color_components(Grid, Color, Components) :-
    gp_grid_cells(Grid, Color, AllCells),
    gp_partition_comps_(AllCells, Components).

% gp_partition_comps_(+Available, -Components): iteratively flood-fill from each seed.
gp_partition_comps_([], []).
gp_partition_comps_([Seed|Rest], [Comp|Others]) :-
% Flood fill from Seed using the remaining available cells.
    gp_flood_fill_([Seed], Rest, [], Comp, Remaining),
    gp_partition_comps_(Remaining, Others).

% gp_flood_fill_(+Queue, +Available, +Visited, -Component, -Remaining)
% BFS: expand from cells in Queue; only move to cells in Available.
gp_flood_fill_([], Available, Visited, Visited, Available).
gp_flood_fill_([Cell|Queue], Available, Visited, Component, Remaining) :-
% Get 4-connected neighbors of Cell.
    Cell = r(R, C),
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    Neighbors4 = [r(R1,C), r(R2,C), r(R,C1), r(R,C2)],
% Keep only neighbors that are still in Available (unvisited Color cells).
    include(gp_in_list_(Available), Neighbors4, NewNeighbors),
% Remove found neighbors from Available so they won't be re-seeded.
    subtract(Available, NewNeighbors, ShrunkAvailable),
% Extend queue; add current cell to visited.
    append(Queue, NewNeighbors, ExtendedQueue),
    gp_flood_fill_(ExtendedQueue, ShrunkAvailable, [Cell|Visited], Component, Remaining).

% gp_in_list_(+List, +Elem): succeed if Elem is memberchk of List.
gp_in_list_(List, Elem) :- memberchk(Elem, List).

% gp_grid_to_scene(+Grid, +BgColor, -Scene)
% Scene is a list of obj(Color, Cells) terms: one per 4-connected non-background region.
% Objects are listed in color-alphabetical order; within color by flood-fill order.
gp_grid_to_scene(Grid, BgColor, Scene) :-
    gp_object_colors(Grid, BgColor, ObjColors),
    findall(obj(Color, Cells),
        (member(Color, ObjColors),
         gp_color_components(Grid, Color, Comps),
         member(Cells, Comps)),
        Scene).

% gp_scene_to_grid(+Scene, +H, +W, +BgColor, -Grid)
% Render Scene onto an H x W background grid and return the resulting Grid.
gp_scene_to_grid(Scene, H, W, BgColor, Grid) :-
    gp_grid_from_rows(H, W, BgColor, Blank),
    gp_paint_scene(Blank, Scene, Grid).

% gp_n_objects(+Grid, +BgColor, -N)
% N is the total count of 4-connected non-background objects in Grid.
gp_n_objects(Grid, BgColor, N) :-
    gp_grid_to_scene(Grid, BgColor, Scene),
    length(Scene, N).

% gp_object_colors(+Grid, +BgColor, -Colors)
% Colors is a sorted list of distinct non-background colors in Grid.
gp_object_colors(Grid, BgColor, Colors) :-
    findall(C, (member(Row, Grid), member(C, Row), C \== BgColor), All),
    sort(All, Colors).

% gp_largest_object(+Grid, +BgColor, -Obj)
% Obj is the obj term with the most cells among all non-background objects.
% Ties broken by term order of cell lists.
gp_largest_object(Grid, BgColor, Obj) :-
    gp_grid_to_scene(Grid, BgColor, Scene),
    Scene \= [],
    findall(NegN-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, [_-Obj | _]).

% gp_smallest_object(+Grid, +BgColor, -Obj)
% Obj is the obj term with the fewest cells among all non-background objects.
gp_smallest_object(Grid, BgColor, Obj) :-
    gp_grid_to_scene(Grid, BgColor, Scene),
    Scene \= [],
    findall(N-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, [_-Obj | _]).

% gp_objects_by_size(+Grid, +BgColor, -Objs)
% Objs is the list of non-background objects sorted by cell count descending.
gp_objects_by_size(Grid, BgColor, Objs) :-
    gp_grid_to_scene(Grid, BgColor, Scene),
    findall(NegN-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    maplist([_-O, O]>>true, Sorted, Objs).

% gp_grid_from_rows(+H, +W, +Color, -Grid)
% Create an H x W grid with every cell set to Color.
gp_grid_from_rows(H, W, Color, Grid) :-
% Build one row of W cells all equal to Color.
    length(Row, W), maplist(=(Color), Row),
% Build H copies of that row.
    length(Grid, H), maplist(=(Row), Grid).

% gp_paint_obj(+Grid, +Obj, -NewGrid)
% Paint all cells of Obj onto Grid, replacing whatever was there.
gp_paint_obj(Grid, obj(Color, Cells), NewGrid) :-
    foldl(gp_paint_cell_(Color), Cells, Grid, NewGrid).

% gp_paint_cell_(+Color, +Cell, +Grid, -NewGrid): replace one cell.
gp_paint_cell_(Color, r(R, C), Grid, NewGrid) :-
    nth0(R, Grid, OldRow),
    gp_replace_in_row_(OldRow, C, Color, NewRow),
    gp_replace_row_(Grid, R, NewRow, NewGrid).

% gp_replace_in_row_(+Row, +C, +Val, -NewRow): replace element at index C.
gp_replace_in_row_(Row, C, Val, NewRow) :-
    length(Row, W), W1 is W - 1,
    numlist(0, W1, Idxs),
    maplist([I, Cell]>>(I =:= C -> Cell = Val ; nth0(I, Row, Cell)), Idxs, NewRow).

% gp_replace_row_(+Grid, +R, +NewRow, -NewGrid): replace row R in Grid.
gp_replace_row_(Grid, R, NewRow, NewGrid) :-
    length(Grid, H), H1 is H - 1,
    numlist(0, H1, Idxs),
    maplist([I, Row]>>(I =:= R -> Row = NewRow ; nth0(I, Grid, Row)), Idxs, NewGrid).

% gp_paint_scene(+Grid, +Scene, -NewGrid)
% Paint all objects in Scene onto Grid in list order.
gp_paint_scene(Grid, Scene, NewGrid) :-
    foldl([Obj, G, G2]>>(gp_paint_obj(G, Obj, G2)), Scene, Grid, NewGrid).

% gp_grid_equal(+Grid1, +Grid2)
% Succeed if Grid1 and Grid2 are identical (same dimensions and same values).
gp_grid_equal(Grid1, Grid2) :-
    Grid1 == Grid2.
