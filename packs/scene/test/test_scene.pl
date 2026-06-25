:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(grid)).
:- use_module('../prolog/scene').

% FIXTURE GRIDS
% grid_3color: 4x4 grid with background 0, two red (1) objects, one blue (2) object.
% Top-left 2x2 block of 1s = one object (4 cells).
% Bottom-right isolated 1 = second object (1 cell).
% Single 2 at (1,3) = third object (1 cell).
grid_3color([[1,1,0,0],
             [1,0,0,2],
             [0,0,0,0],
             [0,0,0,1]]).

% grid_bg_clear: 5x5 mostly-0 grid; background is 0.
grid_bg_clear([[0,0,0,0,0],
               [0,1,0,0,0],
               [0,1,1,0,0],
               [0,0,0,2,0],
               [0,0,0,0,0]]).


:- begin_tests(scene_bg).

% Background of grid_3color is 0 (10 zeros vs 4 ones and 1 two).
test(bg_is_zero) :-
    grid_3color(G),
    sc_bg_color(G, BgColor),
    BgColor =:= 0.

% Background of a grid with no clear dominant: most frequent wins.
test(bg_all_same, nondet) :-
    sc_bg_color([[5,5,5],[5,5,5]], 5).

% Single-color grid: that color is the background.
test(bg_single_color) :-
    sc_bg_color([[3,3],[3,3]], 3).

:- end_tests(scene_bg).


:- begin_tests(scene_objects).

% grid_3color has 3 foreground objects (two of color 1, one of color 2).
test(objects_count) :-
    grid_3color(G),
    sc_objects(G, Objects),
    length(Objects, 3).

% All objects in grid_3color have a valid color (1 or 2).
test(objects_colors, nondet) :-
    grid_3color(G),
    sc_objects(G, Objects),
    maplist([obj(C,_)]>>(member(C, [1,2])), Objects).

% sc_objects_of_color filters correctly: 2 objects of color 1.
test(objects_of_color_1) :-
    grid_3color(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 1, RedObjs),
    length(RedObjs, 2).

% sc_objects_of_color returns 1 object of color 2.
test(objects_of_color_2) :-
    grid_3color(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 2, BlueObjs),
    length(BlueObjs, 1).

% Fully uniform grid has no foreground objects.
test(objects_empty) :-
    sc_objects([[0,0],[0,0]], Objects),
    Objects = [].

:- end_tests(scene_objects).


:- begin_tests(scene_scene).

% sc_grid_to_scene produces a scene/4 term with correct dimensions.
test(scene_dims) :-
    grid_3color(G),
    sc_grid_to_scene(G, scene(Rows, Cols, _, _)),
    Rows =:= 4,
    Cols =:= 4.

% sc_grid_to_scene includes background color.
test(scene_bg) :-
    grid_3color(G),
    sc_grid_to_scene(G, scene(_, _, BgColor, _)),
    BgColor =:= 0.

% sc_grid_to_scene includes 3 objects for grid_3color.
test(scene_objects_count) :-
    grid_3color(G),
    sc_grid_to_scene(G, scene(_, _, _, Objects)),
    length(Objects, 3).

:- end_tests(scene_scene).


:- begin_tests(scene_properties).

% obj_size: the large red object in grid_bg_clear has 3 cells.
test(obj_size_large) :-
    grid_bg_clear(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 1, RedObjs),
    RedObjs = [Obj],
    sc_obj_size(Obj, 3).

% obj_size: the blue object has 1 cell.
test(obj_size_small) :-
    grid_bg_clear(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 2, BlueObjs),
    BlueObjs = [Obj],
    sc_obj_size(Obj, 1).

% obj_bbox: the large red L-shape in grid_bg_clear spans rows 1-2, cols 1-2.
test(obj_bbox_red) :-
    grid_bg_clear(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 1, [Obj]),
    sc_obj_bbox(Obj, r(1,1), r(2,2)).

% obj_centroid: single-cell object centroid is the cell itself.
test(obj_centroid_single) :-
    grid_bg_clear(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 2, [Obj]),
    sc_obj_centroid(Obj, 3, 3).

% obj_shape: single-cell object normalizes to [r(0,0)].
test(obj_shape_single) :-
    grid_bg_clear(G),
    sc_objects(G, Objects),
    sc_objects_of_color(Objects, 2, [Obj]),
    sc_obj_shape(Obj, [r(0,0)]).

% obj_color: accessor returns the stored color.
test(obj_color) :-
    sc_obj_color(obj(7, [r(0,0)]), 7).

% obj_cells: accessor returns the stored cells.
test(obj_cells) :-
    sc_obj_cells(obj(3, [r(1,2)]), [r(1,2)]).

:- end_tests(scene_properties).


:- begin_tests(scene_normalize).

% Normalizing a cell set already at (0,0) returns the same set.
test(normalize_at_origin) :-
    sc_normalize_cells([r(0,0), r(0,1), r(1,0)], N),
    N = [r(0,0), r(0,1), r(1,0)].

% Normalizing shifts so the top-left is at (0,0).
test(normalize_offset) :-
    sc_normalize_cells([r(2,3), r(2,4), r(3,3)], N),
    N = [r(0,0), r(0,1), r(1,0)].

% Single cell normalizes to r(0,0).
test(normalize_single) :-
    sc_normalize_cells([r(5,7)], [r(0,0)]).

:- end_tests(scene_normalize).


:- begin_tests(scene_sort).

% Sort ascending by size returns smallest first.
test(sort_asc, nondet) :-
    Objs = [obj(1, [r(0,0), r(0,1), r(0,2)]),
            obj(2, [r(0,0)]),
            obj(3, [r(0,0), r(0,1)])],
    sc_sort_by_size(Objs, asc, [O1,O2,O3]),
    sc_obj_size(O1, 1),
    sc_obj_size(O2, 2),
    sc_obj_size(O3, 3).

% Sort descending returns largest first.
test(sort_desc, nondet) :-
    Objs = [obj(1, [r(0,0)]),
            obj(2, [r(0,0), r(0,1), r(0,2)])],
    sc_sort_by_size(Objs, desc, [First|_]),
    sc_obj_size(First, 3).

% sc_largest returns the biggest object.
test(largest, nondet) :-
    Objs = [obj(1, [r(0,0)]),
            obj(2, [r(0,0), r(1,0), r(2,0)])],
    sc_largest(Objs, Big),
    sc_obj_size(Big, 3).

% sc_smallest returns the object with fewest cells.
test(smallest, nondet) :-
    Objs = [obj(1, [r(0,0)]),
            obj(2, [r(0,0), r(1,0)])],
    sc_smallest(Objs, Small),
    sc_obj_size(Small, 1).

:- end_tests(scene_sort).


:- begin_tests(scene_counting).

% sc_count returns the total number of objects.
test(count_total) :-
    grid_3color(G),
    sc_objects(G, Objects),
    sc_count(Objects, 3).

% sc_count_of_color returns 2 for color 1 in grid_3color.
test(count_of_color_1) :-
    grid_3color(G),
    sc_objects(G, Objects),
    sc_count_of_color(Objects, 1, 2).

% sc_count_of_color returns 1 for color 2 in grid_3color.
test(count_of_color_2) :-
    grid_3color(G),
    sc_objects(G, Objects),
    sc_count_of_color(Objects, 2, 1).

% sc_count returns 0 for empty list.
test(count_empty) :-
    sc_count([], 0).

:- end_tests(scene_counting).


:- begin_tests(scene_spatial).

% sc_above: object at row 0 is above object at row 3.
test(above) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(3,0)]),
    sc_above(Obj1, Obj2).

% sc_below: object at row 3 is below object at row 0.
test(below) :-
    Obj1 = obj(1, [r(3,0)]),
    Obj2 = obj(2, [r(0,0)]),
    sc_below(Obj1, Obj2).

% sc_left_of: object at col 0 is left of object at col 5.
test(left_of) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(0,5)]),
    sc_left_of(Obj1, Obj2).

% sc_right_of: object at col 5 is right of object at col 0.
test(right_of) :-
    Obj1 = obj(1, [r(0,5)]),
    Obj2 = obj(2, [r(0,0)]),
    sc_right_of(Obj1, Obj2).

% sc_above is not symmetric: if Obj1 above Obj2, Obj2 is not above Obj1.
test(above_asymmetric) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(3,0)]),
    sc_above(Obj1, Obj2),
    \+ sc_above(Obj2, Obj1).

:- end_tests(scene_spatial).


:- begin_tests(scene_touching).

% Objects at r(0,0) and r(0,1) are 4-connected (adjacent columns).
test(touching_h) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(0,1)]),
    sc_cells_touching(Obj1, Obj2).

% Objects at r(0,0) and r(1,0) are 4-connected (adjacent rows).
test(touching_v) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(1,0)]),
    sc_cells_touching(Obj1, Obj2).

% Objects separated by one cell gap are not touching.
test(not_touching) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(0,2)]),
    \+ sc_cells_touching(Obj1, Obj2).

% Diagonal neighbors are not 4-connected.
test(diagonal_not_touching) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(1,1)]),
    \+ sc_cells_touching(Obj1, Obj2).

:- end_tests(scene_touching).


:- begin_tests(scene_containment).

% A single-cell object inside a multi-cell object's bounding box.
test(contained) :-
    Inner = obj(1, [r(1,1)]),
    Outer = obj(2, [r(0,0), r(0,3), r(3,0), r(3,3)]),
    sc_contained_in(Inner, Outer).

% An object outside another object's bounding box is not contained.
test(not_contained) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(2,2), r(3,3)]),
    \+ sc_contained_in(Obj1, Obj2).

:- end_tests(scene_containment).


:- begin_tests(scene_comparison).

% Two single-cell objects of the same color are same_color.
test(same_color_yes) :-
    sc_same_color(obj(3, [r(0,0)]), obj(3, [r(1,1)])).

% Two objects of different colors are not same_color.
test(same_color_no) :-
    \+ sc_same_color(obj(1, [r(0,0)]), obj(2, [r(0,0)])).

% Two L-shaped objects with the same structure are same_shape.
test(same_shape_yes) :-
    Obj1 = obj(1, [r(0,0), r(1,0), r(1,1)]),
    Obj2 = obj(2, [r(5,3), r(6,3), r(6,4)]),
    sc_same_shape(Obj1, Obj2).

% Two objects with different shapes are not same_shape.
test(same_shape_no) :-
    Obj1 = obj(1, [r(0,0), r(0,1)]),
    Obj2 = obj(1, [r(0,0), r(1,0), r(2,0)]),
    \+ sc_same_shape(Obj1, Obj2).

:- end_tests(scene_comparison).
