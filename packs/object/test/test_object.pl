% PLUnit tests for the obj pack (object_* predicates).
:- use_module(library(plunit)).
% Load the connect pack so object_inventory can find connect_components4.
:- use_module('../../connect/prolog/connect').
:- use_module('../prolog/object').

% Helper grid with two red (1) objects and one blue (2) object.
% Grid:
% 1 1 0 2
% 1 0 0 2
% 0 0 1 0
% 0 1 1 0
% The 1-objects: {r(0,0),r(0,1),r(1,0)} and {r(2,2),r(3,1),r(3,2)}.
% The 2-objects: {r(0,3),r(1,3)}.
test_grid([[1,1,0,2],[1,0,0,2],[0,0,1,0],[0,1,1,0]]).

:- begin_tests(object_from_cells).

test(construct_basic) :-
    % Constructing an object sorts its cells.
    object_from_cells(3, [r(1,0), r(0,0)], Obj),
    Obj = obj(3, [r(0,0), r(1,0)]).

test(construct_single) :-
    % Single-cell object.
    object_from_cells(5, [r(2,3)], Obj),
    Obj = obj(5, [r(2,3)]).

test(construct_preserves_color) :-
    % Color is stored in the object term.
    object_from_cells(7, [r(0,0)], Obj),
    object_color(Obj, 7).

:- end_tests(object_from_cells).

:- begin_tests(object_color).

test(color_basic) :-
    % Extract color from an object.
    object_from_cells(4, [r(0,0), r(0,1)], Obj),
    object_color(Obj, 4).

test(color_zero) :-
    % Color 0 can be stored (even though object_all skips 0).
    object_from_cells(0, [r(0,0)], Obj),
    object_color(Obj, 0).

:- end_tests(object_color).

:- begin_tests(object_cells).

test(cells_sorted) :-
    % Cells come back sorted.
    object_from_cells(1, [r(2,0), r(0,1), r(1,0)], Obj),
    object_cells(Obj, [r(0,1), r(1,0), r(2,0)]).

test(cells_single) :-
    % Single-cell object.
    object_from_cells(1, [r(3,2)], Obj),
    object_cells(Obj, [r(3,2)]).

:- end_tests(object_cells).

:- begin_tests(object_size).

test(size_three) :-
    % Object with three cells has size 3.
    object_from_cells(1, [r(0,0), r(0,1), r(1,0)], Obj),
    object_size(Obj, 3).

test(size_one) :-
    % Single-cell object has size 1.
    object_from_cells(2, [r(4,4)], Obj),
    object_size(Obj, 1).

test(size_four) :-
    % Object with four cells has size 4.
    object_from_cells(3, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    object_size(Obj, 4).

:- end_tests(object_size).

:- begin_tests(object_bbox).

test(bbox_basic) :-
    % Bounding box of a 2x2 block at (0,0).
    object_from_cells(1, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    object_bbox(Obj, 0, 0, 1, 1).

test(bbox_L_shape) :-
    % L-shaped object.
    object_from_cells(2, [r(0,0),r(1,0),r(2,0),r(2,1)], Obj),
    object_bbox(Obj, 0, 0, 2, 1).

test(bbox_single) :-
    % Single-cell object: min = max.
    object_from_cells(3, [r(3,5)], Obj),
    object_bbox(Obj, 3, 5, 3, 5).

test(bbox_wide) :-
    % Wide horizontal object.
    object_from_cells(1, [r(2,0),r(2,1),r(2,2),r(2,3)], Obj),
    object_bbox(Obj, 2, 0, 2, 3).

:- end_tests(object_bbox).

:- begin_tests(object_center).

test(center_2x2) :-
    % Center of a 2x2 block at (0,0): floor(0.5) = 0.
    object_from_cells(1, [r(0,0),r(0,1),r(1,0),r(1,1)], Obj),
    object_center(Obj, 0, 0).

test(center_single) :-
    % Single cell: center is the cell itself.
    object_from_cells(2, [r(3,4)], Obj),
    object_center(Obj, 3, 4).

test(center_horizontal) :-
    % Three cells in a row: center is the middle.
    object_from_cells(1, [r(0,0),r(0,1),r(0,2)], Obj),
    object_center(Obj, 0, 1).

:- end_tests(object_center).

:- begin_tests(object_shape).

test(shape_L) :-
    % L-shape at offset (2,3): normalized to origin.
    object_from_cells(1, [r(2,3),r(3,3),r(4,3),r(4,4)], Obj),
    object_shape(Obj, Shape),
    msort(Shape, Sorted),
    msort([r(0,0),r(1,0),r(2,0),r(2,1)], Expected),
    Sorted = Expected.

test(shape_single) :-
    % Single cell anywhere normalizes to r(0,0).
    object_from_cells(2, [r(5,6)], Obj),
    object_shape(Obj, [r(0,0)]).

test(shape_row) :-
    % Row of three cells normalizes to r(0,0),r(0,1),r(0,2).
    object_from_cells(1, [r(4,2),r(4,3),r(4,4)], Obj),
    object_shape(Obj, Shape),
    msort(Shape, Sorted),
    Sorted = [r(0,0),r(0,1),r(0,2)].

:- end_tests(object_shape).

:- begin_tests(object_inventory).

test(inventory_color1) :-
    % Two 1-objects in the test grid.
    test_grid(G),
    object_inventory(G, 1, Objs),
    length(Objs, 2).

test(inventory_color2) :-
    % One 2-object in the test grid.
    test_grid(G),
    object_inventory(G, 2, Objs),
    length(Objs, 1).

test(inventory_absent) :-
    % Color not in grid: empty list.
    test_grid(G),
    object_inventory(G, 9, Objs),
    Objs = [].

test(inventory_sizes) :-
    % The two 1-objects have sizes 3 and 3.
    test_grid(G),
    object_inventory(G, 1, Objs),
    maplist(object_size, Objs, Sizes),
    msort(Sizes, [3, 3]).

:- end_tests(object_inventory).

:- begin_tests(object_all).

test(all_basic) :-
    % Grid has two colors (1 and 2): total 3 objects.
    test_grid(G),
    object_all(G, Objs),
    length(Objs, 3).

test(all_uniform_grid) :-
    % A uniform single-color grid has one object.
    object_all([[1,1],[1,1]], Objs),
    length(Objs, 1).

test(all_no_bg) :-
    % Background (0) cells are not included as objects.
    object_all([[0,0],[0,1]], Objs),
    length(Objs, 1),
    [Obj] = Objs,
    object_color(Obj, 1).

:- end_tests(object_all).

:- begin_tests(object_count).

test(count_color1) :-
    % Two 1-objects in the test grid.
    test_grid(G),
    object_count(G, 1, N),
    N =:= 2.

test(count_color2) :-
    % One 2-object in the test grid.
    test_grid(G),
    object_count(G, 2, N),
    N =:= 1.

test(count_absent) :-
    % Absent color has count 0.
    test_grid(G),
    object_count(G, 5, N),
    N =:= 0.

:- end_tests(object_count).

:- begin_tests(object_largest).

test(largest_basic) :-
    % Both 1-objects have 3 cells; largest returns one with size 3.
    test_grid(G),
    object_largest(G, 1, Obj),
    object_size(Obj, 3).

test(largest_unique) :-
    % The unique 2-object has 2 cells; largest returns size 2.
    test_grid(G),
    object_largest(G, 2, Obj),
    object_size(Obj, 2).

test(largest_distinct_sizes) :-
    % Grid with objects of sizes 1 and 3: largest has size 3.
    object_largest([[1,0,0],[1,0,2],[1,0,0]], 1, Obj),
    object_size(Obj, 3).

:- end_tests(object_largest).

:- begin_tests(object_smallest).

test(smallest_basic) :-
    % Both 1-objects have 3 cells; smallest returns one with size 3.
    test_grid(G),
    object_smallest(G, 1, Obj),
    object_size(Obj, 3).

test(smallest_distinct_sizes) :-
    % Grid with objects of sizes 1 and 3: smallest has size 1.
    object_smallest([[1,0,2],[1,0,0],[1,0,0]], 2, Obj),
    object_size(Obj, 1).

:- end_tests(object_smallest).

:- begin_tests(object_at_cell).

test(at_cell_basic) :-
    % Find the object that contains cell r(0,0) from a list.
    object_from_cells(1, [r(0,0),r(0,1)], ObjA),
    object_from_cells(2, [r(1,0)], ObjB),
    object_at_cell([ObjA, ObjB], r(0,1), Found),
    Found = ObjA.

test(at_cell_second) :-
    % Cell is in the second object.
    object_from_cells(1, [r(0,0)], ObjA),
    object_from_cells(2, [r(1,0),r(2,0)], ObjB),
    object_at_cell([ObjA, ObjB], r(2,0), Found),
    Found = ObjB.

:- end_tests(object_at_cell).

:- begin_tests(object_sort_size).

test(sorting_asc) :-
    % Sort three objects ascending by size.
    object_from_cells(1, [r(0,0)], O1),
    object_from_cells(2, [r(0,0),r(0,1),r(0,2)], O3),
    object_from_cells(3, [r(0,0),r(0,1)], O2),
    object_sort_size([O3, O1, O2], asc, Sorted),
    maplist(object_size, Sorted, [1,2,3]).

test(sorting_desc) :-
    % Sort three objects descending by size.
    object_from_cells(1, [r(0,0)], O1),
    object_from_cells(2, [r(0,0),r(0,1),r(0,2)], O3),
    object_from_cells(3, [r(0,0),r(0,1)], O2),
    object_sort_size([O1, O2, O3], desc, Sorted),
    maplist(object_size, Sorted, [3,2,1]).

test(sorting_single) :-
    % Single object: sort is identity.
    object_from_cells(1, [r(0,0),r(1,0)], Obj),
    object_sort_size([Obj], asc, [Obj]).

:- end_tests(object_sort_size).
