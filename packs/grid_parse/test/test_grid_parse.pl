:- use_module('../prolog/grid_parse').
:- use_module(library(plunit)).

% Grid fixtures.
% A 3x3 grid with background r and one blue object at center
%   r r r
%   r b r
%   r r r
grid_ring([[r,r,r],[r,b,r],[r,r,r]]).

% A 3x3 grid with two separate blue objects (not connected)
%   b r b
%   r r r
%   r r r
grid_two_b([[b,r,b],[r,r,r],[r,r,r]]).

% A 4x4 grid with r background and a 2x2 blue square
%   r r r r
%   r b b r
%   r b b r
%   r r r r
grid_blue_square([[r,r,r,r],[r,b,b,r],[r,b,b,r],[r,r,r,r]]).

% A 2x2 uniform grid (all r)
grid_uniform([[r,r],[r,r]]).

% A 2x3 grid
%   r b r
%   r b r
grid_vstripe([[r,b,r],[r,b,r]]).

% A grid with two colors of objects: b and g
%   r r r
%   b r g
%   r r r
grid_two_colors([[r,r,r],[b,r,g],[r,r,r]]).

:- begin_tests(grid_parse).

% grid_parse_bg_color: most frequent is r in grid_ring
test(bg_color_ring) :-
    grid_ring(G), grid_parse_bg_color(G, C), C == r.

% grid_parse_bg_color: uniform grid
test(bg_color_uniform) :-
    grid_uniform(G), grid_parse_bg_color(G, C), C == r.

% grid_parse_bg_color: vertical stripe (r=4, b=2)
test(bg_color_vstripe) :-
    grid_vstripe(G), grid_parse_bg_color(G, C), C == r.

% grid_parse_grid_cells: find blue cells in ring grid
test(grid_cells_blue_ring) :-
    grid_ring(G), grid_parse_grid_cells(G, b, Cells),
    Cells == [r(1,1)].

% grid_parse_grid_cells: find all r cells in ring
test(grid_cells_r_ring) :-
    grid_ring(G), grid_parse_grid_cells(G, r, Cells),
    length(Cells, 8).

% grid_parse_grid_cells: absent color
test(grid_cells_absent) :-
    grid_ring(G), grid_parse_grid_cells(G, g, Cells), Cells == [].

% grid_parse_color_components: single-cell blue in ring = one component
test(color_comps_ring) :-
    grid_ring(G), grid_parse_color_components(G, b, Comps),
    length(Comps, 1).

% grid_parse_color_components: two separate blue cells = two components
test(color_comps_two_b) :-
    grid_two_b(G), grid_parse_color_components(G, b, Comps),
    length(Comps, 2).

% grid_parse_color_components: connected 2x2 blue square = one component with 4 cells
test(color_comps_square) :-
    grid_blue_square(G), grid_parse_color_components(G, b, Comps),
    length(Comps, 1),
    Comps = [Cells], length(Cells, 4).

% grid_parse_color_components: no cells of color = no components
test(color_comps_absent) :-
    grid_ring(G), grid_parse_color_components(G, g, Comps), Comps == [].

% grid_parse_grid_to_scene: one blue object in ring
test(grid_to_scene_ring) :-
    grid_ring(G), grid_parse_grid_to_scene(G, r, Scene),
    length(Scene, 1),
    Scene = [obj(b, Cells)], length(Cells, 1).

% grid_parse_grid_to_scene: two separate blue objects
test(grid_to_scene_two_b) :-
    grid_two_b(G), grid_parse_grid_to_scene(G, r, Scene),
    length(Scene, 2).

% grid_parse_grid_to_scene: uniform grid has no objects
test(grid_to_scene_uniform) :-
    grid_uniform(G), grid_parse_grid_to_scene(G, r, Scene),
    Scene == [].

% grid_parse_grid_to_scene: two colors produce one obj per component
test(grid_to_scene_two_colors) :-
    grid_two_colors(G), grid_parse_grid_to_scene(G, r, Scene),
    length(Scene, 2).

% grid_parse_grid_from_rows: 2x2 blank grid
test(grid_from_rows_2x2) :-
    grid_parse_grid_from_rows(2, 2, r, Grid),
    Grid == [[r,r],[r,r]].

% grid_parse_grid_from_rows: 1x3 blank grid
test(grid_from_rows_1x3) :-
    grid_parse_grid_from_rows(1, 3, b, Grid),
    Grid == [[b,b,b]].

% grid_parse_grid_from_rows: 3x1 blank grid
test(grid_from_rows_3x1) :-
    grid_parse_grid_from_rows(3, 1, g, Grid),
    Grid == [[g],[g],[g]].

% grid_parse_paint_obj: paint single cell onto blank
test(paint_obj_single_cell) :-
    grid_parse_grid_from_rows(3, 3, r, Blank),
    grid_parse_paint_obj(Blank, obj(b, [r(1,1)]), NewGrid),
    nth0(1, NewGrid, Row), nth0(1, Row, b).

% grid_parse_paint_obj: paint 2-cell object
test(paint_obj_two_cells) :-
    grid_parse_grid_from_rows(2, 2, r, Blank),
    grid_parse_paint_obj(Blank, obj(b, [r(0,0), r(0,1)]), NewGrid),
    nth0(0, NewGrid, [b, b]).

% grid_parse_paint_scene: paint one object
test(paint_scene_one_obj) :-
    grid_parse_grid_from_rows(3, 3, r, Blank),
    grid_parse_paint_scene(Blank, [obj(b, [r(1,1)])], NewGrid),
    nth0(1, NewGrid, Row), nth0(1, Row, b).

% grid_parse_paint_scene: empty scene leaves grid unchanged
test(paint_scene_empty) :-
    grid_parse_grid_from_rows(2, 2, r, Blank),
    grid_parse_paint_scene(Blank, [], Result),
    grid_parse_grid_equal(Result, Blank).

% grid_parse_scene_to_grid: round-trip scene -> grid -> scene
test(scene_to_grid_single) :-
    Scene = [obj(b, [r(1,1)])],
    grid_parse_scene_to_grid(Scene, 3, 3, r, Grid),
    nth0(1, Grid, Row), nth0(1, Row, b),
    nth0(0, Grid, [r,r,r]).

% grid_parse_n_objects: ring grid has 1 object
test(n_objects_ring) :-
    grid_ring(G), grid_parse_n_objects(G, r, N), N == 1.

% grid_parse_n_objects: two-b grid has 2 objects
test(n_objects_two_b) :-
    grid_two_b(G), grid_parse_n_objects(G, r, N), N == 2.

% grid_parse_n_objects: uniform grid has 0 objects
test(n_objects_uniform) :-
    grid_uniform(G), grid_parse_n_objects(G, r, N), N == 0.

% grid_parse_object_colors: ring grid has [b]
test(object_colors_ring) :-
    grid_ring(G), grid_parse_object_colors(G, r, Colors), Colors == [b].

% grid_parse_object_colors: two-color grid has [b, g]
test(object_colors_two_colors) :-
    grid_two_colors(G), grid_parse_object_colors(G, r, Colors),
    msort(Colors, Sorted), Sorted == [b, g].

% grid_parse_object_colors: uniform grid has no object colors
test(object_colors_uniform) :-
    grid_uniform(G), grid_parse_object_colors(G, r, Colors), Colors == [].

% grid_parse_largest_object: ring has one object
test(largest_object_ring) :-
    grid_ring(G), grid_parse_largest_object(G, r, Obj),
    Obj = obj(b, _).

% grid_parse_largest_object: blue square has 4 cells
test(largest_object_square) :-
    grid_blue_square(G), grid_parse_largest_object(G, r, Obj),
    Obj = obj(b, Cells), length(Cells, 4).

% grid_parse_smallest_object: in ring grid, smallest is the only object
test(smallest_object_ring) :-
    grid_ring(G), grid_parse_smallest_object(G, r, Obj),
    Obj = obj(b, Cells), length(Cells, 1).

% grid_parse_objects_by_size: ring grid returns one object
test(objects_by_size_ring) :-
    grid_ring(G), grid_parse_objects_by_size(G, r, Objs),
    length(Objs, 1).

% grid_parse_objects_by_size: two-b grid returns two objects
test(objects_by_size_two_b) :-
    grid_two_b(G), grid_parse_objects_by_size(G, r, Objs),
    length(Objs, 2).

% grid_parse_grid_equal: same grid
test(grid_equal_same) :-
    grid_ring(G), grid_parse_grid_equal(G, G).

% grid_parse_grid_equal: different grids fail
test(grid_equal_diff) :-
    grid_ring(G1), grid_uniform(G2), \+ grid_parse_grid_equal(G1, G2).

% grid_parse_color_components: vertical stripe (b column) = one 2-cell component
test(color_comps_vstripe) :-
    grid_vstripe(G), grid_parse_color_components(G, b, Comps),
    length(Comps, 1),
    Comps = [Cells], length(Cells, 2).

% grid_parse_grid_to_scene: vstripe has one b object with 2 cells
test(grid_to_scene_vstripe) :-
    grid_vstripe(G), grid_parse_grid_to_scene(G, r, Scene),
    length(Scene, 1),
    Scene = [obj(b, Cells)], length(Cells, 2).

% grid_parse_grid_cells: vstripe b cells in row-major order
test(grid_cells_vstripe_b) :-
    grid_vstripe(G), grid_parse_grid_cells(G, b, Cells),
    length(Cells, 2).

% round-trip: grid_to_scene then scene_to_grid should reproduce original
test(round_trip_ring) :-
    grid_ring(G),
    grid_parse_grid_to_scene(G, r, Scene),
    grid_parse_scene_to_grid(Scene, 3, 3, r, G2),
    grid_parse_grid_equal(G, G2).

% round-trip: blue square round-trips correctly
test(round_trip_blue_square) :-
    grid_blue_square(G),
    grid_parse_grid_to_scene(G, r, Scene),
    grid_parse_scene_to_grid(Scene, 4, 4, r, G2),
    grid_parse_grid_equal(G, G2).

% grid_parse_paint_obj: paint overwrites background
test(paint_obj_overwrites) :-
    grid_parse_grid_from_rows(2, 2, b, Grid),
    grid_parse_paint_obj(Grid, obj(r, [r(0,0)]), NewGrid),
    nth0(0, NewGrid, [r, b]).

% grid_parse_objects_by_size: largest first when two objects have different sizes
test(objects_by_size_order) :-
    grid_two_colors(G),
    grid_parse_objects_by_size(G, r, Objs),
    Objs = [Obj1, Obj2],
    Obj1 = obj(_, Cells1), Obj2 = obj(_, Cells2),
    length(Cells1, N1), length(Cells2, N2),
    N1 >= N2.

% grid_parse_bg_color: in grid_two_colors, r (7 cells) beats b (1) and g (1)
test(bg_color_two_colors) :-
    grid_two_colors(G), grid_parse_bg_color(G, C), C == r.

:- end_tests(grid_parse).
