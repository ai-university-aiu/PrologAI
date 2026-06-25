% PLUnit tests for the obj pack (obj_* predicates).
:- use_module(library(plunit)).
% Load the connect pack so obj_inventory can find cc_components4.
:- use_module('../../connect/prolog/connect').
:- use_module('../prolog/obj').

% Helper grid with two red (1) objects and one blue (2) object.
% Grid:
% 1 1 0 2
% 1 0 0 2
% 0 0 1 0
% 0 1 1 0
% The 1-objects: {r(0,0),r(0,1),r(1,0)} and {r(2,2),r(3,1),r(3,2)}.
% The 2-objects: {r(0,3),r(1,3)}.
test_grid([[1,1,0,2],[1,0,0,2],[0,0,1,0],[0,1,1,0]]).

:- begin_tests(obj_from_cells).

test(construct_basic) :-
    % Constructing an object sorts its cells.
    obj_from_cells(3, [r(1,0), r(0,0)], Obj),
    Obj = obj(3, [r(0,0), r(1,0)]).

test(construct_single) :-
    % Single-cell object.
    obj_from_cells(5, [r(2,3)], Obj),
    Obj = obj(5, [r(2,3)]).

test(construct_preserves_color) :-
    % Color is stored in the object term.
    obj_from_cells(7, [r(0,0)], Obj),
    obj_color(Obj, 7).

:- end_tests(obj_from_cells).

:- begin_tests(obj_color).

test(color_basic) :-
    % Extract color from an object.
    obj_from_cells(4, [r(0,0), r(0,1)], Obj),
    obj_color(Obj, 4).

test(color_zero) :-
    % Color 0 can be stored (even though obj_all skips 0).
    obj_from_cells(0, [r(0,0)], Obj),
    obj_color(Obj, 0).

:- end_tests(obj_color).

:- begin_tests(obj_cells).

test(cells_sorted) :-
    % Cells come back sorted.
    obj_from_cells(1, [r(2,0), r(0,1), r(1,0)], Obj),
    obj_cells(Obj, [r(0,1), r(1,0), r(2,0)]).

test(cells_single) :-
    % Single-cell object.
    obj_from_cells(1, [r(3,2)], Obj),
    obj_cells(Obj, [r(3,2)]).

:- end_tests(obj_cells).

:- begin_tests(obj_size).

test(size_three) :-
    % Object with three cells has size 3.
    obj_from_cells(1, [r(0,0), r(0,1), r(1,0)], Obj),
    obj_size(Obj, 3).

test(size_one) :-
    % Single-cell object has size 1.
    obj_from_cells(2, [r(4,4)], Obj),
    obj_size(Obj, 1).

test(size_four) :-
    % Object with four cells has size 4.
    obj_from_cells(3, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    obj_size(Obj, 4).

:- end_tests(obj_size).

:- begin_tests(obj_bbox).

test(bbox_basic) :-
    % Bounding box of a 2x2 block at (0,0).
    obj_from_cells(1, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    obj_bbox(Obj, 0, 0, 1, 1).

test(bbox_L_shape) :-
    % L-shaped object.
    obj_from_cells(2, [r(0,0),r(1,0),r(2,0),r(2,1)], Obj),
    obj_bbox(Obj, 0, 0, 2, 1).

test(bbox_single) :-
    % Single-cell object: min = max.
    obj_from_cells(3, [r(3,5)], Obj),
    obj_bbox(Obj, 3, 5, 3, 5).

test(bbox_wide) :-
    % Wide horizontal object.
    obj_from_cells(1, [r(2,0),r(2,1),r(2,2),r(2,3)], Obj),
    obj_bbox(Obj, 2, 0, 2, 3).

:- end_tests(obj_bbox).

:- begin_tests(obj_center).

test(center_2x2) :-
    % Center of a 2x2 block at (0,0): floor(0.5) = 0.
    obj_from_cells(1, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    obj_center(Obj, 0, 0).

test(center_single) :-
    % Single cell: center is the cell itself.
    obj_from_cells(2, [r(3,4)], Obj),
    obj_center(Obj, 3, 4).

test(center_horizontal) :-
    % Three cells in a row: center is the middle.
    obj_from_cells(1, [r(0,0),r(0,1),r(0,2)], Obj),
    obj_center(Obj, 0, 1).

:- end_tests(obj_center).

:- begin_tests(obj_shape).

test(shape_L) :-
    % L-shape at offset (2,3): normalized to origin.
    obj_from_cells(1, [r(2,3),r(3,3),r(4,3),r(4,4)], Obj),
    obj_shape(Obj, Shape),
    msort(Shape, Sorted),
    msort([r(0,0),r(1,0),r(2,0),r(2,1)], Expected),
    Sorted = Expected.

test(shape_single) :-
    % Single cell anywhere normalizes to r(0,0).
    obj_from_cells(2, [r(5,6)], Obj),
    obj_shape(Obj, [r(0,0)]).

test(shape_row) :-
    % Row of three cells normalizes to r(0,0),r(0,1),r(0,2).
    obj_from_cells(1, [r(4,2),r(4,3),r(4,4)], Obj),
    obj_shape(Obj, Shape),
    msort(Shape, Sorted),
    Sorted = [r(0,0),r(0,1),r(0,2)].

:- end_tests(obj_shape).

:- begin_tests(obj_inventory).

test(inventory_color1) :-
    % Two 1-objects in the test grid.
    test_grid(G),
    obj_inventory(G, 1, Objs),
    length(Objs, 2).

test(inventory_color2) :-
    % One 2-object in the test grid.
    test_grid(G),
    obj_inventory(G, 2, Objs),
    length(Objs, 1).

test(inventory_absent) :-
    % Color not in grid: empty list.
    test_grid(G),
    obj_inventory(G, 9, Objs),
    Objs = [].

test(inventory_sizes) :-
    % The two 1-objects have sizes 3 and 3.
    test_grid(G),
    obj_inventory(G, 1, Objs),
    maplist(obj_size, Objs, Sizes),
    msort(Sizes, [3, 3]).

:- end_tests(obj_inventory).

:- begin_tests(obj_all).

test(all_basic) :-
    % Grid has two colors (1 and 2): total 3 objects.
    test_grid(G),
    obj_all(G, Objs),
    length(Objs, 3).

test(all_uniform_grid) :-
    % A uniform single-color grid has one object.
    obj_all([[1,1],[1,1]], Objs),
    length(Objs, 1).

test(all_no_bg) :-
    % Background (0) cells are not included as objects.
    obj_all([[0,0],[0,1]], Objs),
    length(Objs, 1),
    [Obj] = Objs,
    obj_color(Obj, 1).

:- end_tests(obj_all).

:- begin_tests(obj_count).

test(count_color1) :-
    % Two 1-objects in the test grid.
    test_grid(G),
    obj_count(G, 1, N),
    N =:= 2.

test(count_color2) :-
    % One 2-object in the test grid.
    test_grid(G),
    obj_count(G, 2, N),
    N =:= 1.

test(count_absent) :-
    % Absent color has count 0.
    test_grid(G),
    obj_count(G, 5, N),
    N =:= 0.

:- end_tests(obj_count).

:- begin_tests(obj_largest).

test(largest_basic) :-
    % Both 1-objects have 3 cells; largest returns one with size 3.
    test_grid(G),
    obj_largest(G, 1, Obj),
    obj_size(Obj, 3).

test(largest_unique) :-
    % The unique 2-object has 2 cells; largest returns size 2.
    test_grid(G),
    obj_largest(G, 2, Obj),
    obj_size(Obj, 2).

test(largest_distinct_sizes) :-
    % Grid with objects of sizes 1 and 3: largest has size 3.
    obj_largest([[1,0,0],[1,0,2],[1,0,0]], 1, Obj),
    obj_size(Obj, 3).

:- end_tests(obj_largest).

:- begin_tests(obj_smallest).

test(smallest_basic) :-
    % Both 1-objects have 3 cells; smallest returns one with size 3.
    test_grid(G),
    obj_smallest(G, 1, Obj),
    obj_size(Obj, 3).

test(smallest_distinct_sizes) :-
    % Grid with objects of sizes 1 and 3: smallest has size 1.
    obj_smallest([[1,0,2],[1,0,0],[1,0,0]], 2, Obj),
    obj_size(Obj, 1).

:- end_tests(obj_smallest).

:- begin_tests(obj_at_cell).

test(at_cell_basic) :-
    % Find the object that contains cell r(0,0) from a list.
    obj_from_cells(1, [r(0,0),r(0,1)], ObjA),
    obj_from_cells(2, [r(1,0)], ObjB),
    obj_at_cell([ObjA, ObjB], r(0,1), Found),
    Found = ObjA.

test(at_cell_second) :-
    % Cell is in the second object.
    obj_from_cells(1, [r(0,0)], ObjA),
    obj_from_cells(2, [r(1,0),r(2,0)], ObjB),
    obj_at_cell([ObjA, ObjB], r(2,0), Found),
    Found = ObjB.

:- end_tests(obj_at_cell).

:- begin_tests(obj_sort_size).

test(sort_asc) :-
    % Sort three objects ascending by size.
    obj_from_cells(1, [r(0,0)], O1),
    obj_from_cells(2, [r(0,0),r(0,1),r(0,2)], O3),
    obj_from_cells(3, [r(0,0),r(0,1)], O2),
    obj_sort_size([O3, O1, O2], asc, Sorted),
    maplist(obj_size, Sorted, [1,2,3]).

test(sort_desc) :-
    % Sort three objects descending by size.
    obj_from_cells(1, [r(0,0)], O1),
    obj_from_cells(2, [r(0,0),r(0,1),r(0,2)], O3),
    obj_from_cells(3, [r(0,0),r(0,1)], O2),
    obj_sort_size([O1, O2, O3], desc, Sorted),
    maplist(obj_size, Sorted, [3,2,1]).

test(sort_single) :-
    % Single object: sort is identity.
    obj_from_cells(1, [r(0,0),r(1,0)], Obj),
    obj_sort_size([Obj], asc, [Obj]).

:- end_tests(obj_sort_size).
