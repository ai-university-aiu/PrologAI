:- use_module('../prolog/hull').

:- begin_tests(hull).

% hull_convex_hull/2 tests

% Five cells: four corners plus center; hull is the four corners only.
test(convex_hull_square) :-
    hull_convex_hull([0-0, 0-2, 2-0, 2-2, 1-1], Hull),
    sort(Hull, S),
    S = [0-0, 0-2, 2-0, 2-2].

% Three collinear cells in the same row; hull has only the two endpoints.
test(convex_hull_collinear) :-
    hull_convex_hull([0-0, 0-1, 0-2], Hull),
    sort(Hull, S),
    S = [0-0, 0-2].

% Single cell; hull is that cell.
test(convex_hull_single) :-
    hull_convex_hull([1-1], Hull),
    Hull = [1-1].

% hull_is_convex/1 tests

% Nine cells of a 3x3 grid; they fill the interior of their hull exactly.
test(is_convex_filled_square) :-
    hull_is_convex([0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2]).

% L-shape; the hull interior contains cells not in the set.
test(is_convex_l_shape, [fail]) :-
    hull_is_convex([0-0, 1-0, 2-0, 2-1, 2-2]).

% Single cell is trivially convex.
test(is_convex_single) :-
    hull_is_convex([1-1]).

% hull_hull_size/2 tests

% Five cells with four-corner hull gives size 4.
test(hull_size_four) :-
    hull_hull_size([0-0, 0-2, 2-0, 2-2, 1-1], N), N = 4.

% Three collinear cells give a two-vertex hull.
test(hull_size_collinear) :-
    hull_hull_size([0-0, 0-1, 0-2], N), N = 2.

% Three non-collinear cells give a triangular hull with three vertices.
test(hull_size_triangle) :-
    hull_hull_size([0-0, 0-2, 2-0], N), N = 3.

% hull_hull_area2/2 tests

% Unit square has area 1, so twice the area is 2.
test(hull_area2_unit_square) :-
    hull_hull_area2([0-0, 0-1, 1-0, 1-1], A2), A2 = 2.

% A 2-unit square (3x3 corners) has area 4, so twice the area is 8.
test(hull_area2_big_square) :-
    hull_hull_area2([0-0, 0-2, 2-0, 2-2], A2), A2 = 8.

% Collinear cells have zero area.
test(hull_area2_collinear) :-
    hull_hull_area2([0-0, 0-1, 0-2], A2), A2 = 0.

% hull_in_hull/3 tests

% Center of 3x3 square is inside the hull of its four corners.
test(in_hull_center) :-
    hull_in_hull(1, 1, [0-0, 2-0, 2-2, 0-2]).

% A point outside the hull fails the test.
test(in_hull_outside, [fail]) :-
    hull_in_hull(3, 3, [0-0, 2-0, 2-2, 0-2]).

% A point on a hull edge passes the test.
test(in_hull_boundary) :-
    hull_in_hull(2, 1, [0-0, 2-0, 2-2, 0-2]).

% hull_cells_in_hull/3 tests

% Hull of four corners of 3x3 grid contains all nine cells.
test(cells_in_hull_all_nine) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_cells_in_hull(Grid, [0-0, 0-2, 2-0, 2-2], InHull),
    length(InHull, 9).

% Hull of a single cell contains only that cell.
test(cells_in_hull_single) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_cells_in_hull(Grid, [1-1], InHull),
    InHull = [1-1].

% Hull of two cells at the same row contains all cells on that segment.
test(cells_in_hull_segment) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_cells_in_hull(Grid, [0-0, 0-2], InHull),
    InHull = [0-0, 0-1, 0-2].

% hull_fill_hull/4 tests

% Fill hull of four 3x3 corners colors all nine cells.
test(fill_hull_all_nine) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_fill_hull(Grid, [0-0, 0-2, 2-0, 2-2], 1, Out),
    Out = [[1,1,1],[1,1,1],[1,1,1]].

% Fill hull of a single cell colors only that cell.
test(fill_hull_single) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_fill_hull(Grid, [1-1], 5, Out),
    nth0(1, Out, Row), nth0(1, Row, 5),
    nth0(0, Out, R0), nth0(0, R0, V), V =:= 0.

% Fill hull of three corners of 3x3 triangle colors six cells inside.
test(fill_hull_triangle) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_fill_hull(Grid, [0-0, 0-2, 2-0], 3, Out),
    Out = [[3,3,3],[3,3,0],[3,0,0]].

% hull_concavities/4 tests

% L-shape in 3x3 grid has one concavity at (1,1).
test(concavities_l_shape) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_concavities(Grid, [0-0,1-0,2-0,2-1,2-2], 0, Missing),
    Missing = [1-1].

% A full 2x2 square has no concavities.
test(concavities_none) :-
    Grid = [[0,0],[0,0]],
    hull_concavities(Grid, [0-0,0-1,1-0,1-1], 0, Missing),
    Missing = [].

% Three triangle corners in 3x3 grid leave three concavities in the hull.
test(concavities_triangle_corners) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    hull_concavities(Grid, [0-0, 0-2, 2-0], 0, Missing),
    sort(Missing, S),
    S = [0-1, 1-0, 1-1].

% hull_diameter/4 tests

% Four corners of 3x3; longest diagonal has squared distance 8.
test(diameter_square_corners) :-
    hull_diameter([0-0, 0-2, 2-0, 2-2], _P1, _P2, D2),
    D2 = 8.

% Three collinear cells; diameter is distance between endpoints.
test(diameter_collinear) :-
    hull_diameter([0-0, 0-1, 0-2], P1, P2, D2),
    sort([P1,P2], S), S = [0-0, 0-2], D2 = 4.

% Right triangle; longest side is the hypotenuse.
test(diameter_triangle) :-
    hull_diameter([0-0, 0-2, 2-0], _P1, _P2, D2),
    D2 = 8.

% hull_aspect/3 tests

% 3x3 square corners; height and width are both 2.
test(aspect_square) :-
    hull_aspect([0-0, 0-2, 2-0, 2-2], H, W),
    H = 2, W = 2.

% Horizontal segment; height is 0, width is 2.
test(aspect_horizontal) :-
    hull_aspect([0-0, 0-2], H, W),
    H = 0, W = 2.

% L-shape; hull spans 2 rows and 2 columns.
test(aspect_l_shape) :-
    hull_aspect([0-0, 1-0, 2-0, 2-1, 2-2], H, W),
    H = 2, W = 2.

% hull_is_rect/1 tests

% Axis-aligned rectangle with four corner cells.
test(is_rect_axis) :-
    hull_is_rect([0-0, 0-3, 2-0, 2-3]).

% Triangle has only three hull vertices; not a rectangle.
test(is_rect_triangle, [fail]) :-
    hull_is_rect([0-0, 0-2, 2-0]).

% Tilted square (diamond) with four right-angle corners.
test(is_rect_tilted) :-
    hull_is_rect([0-1, 1-2, 2-1, 1-0]).

% hull_hull_perim2/2 tests

% Unit square has four edges each of squared length 1; total is 4.
test(hull_perim2_unit) :-
    hull_hull_perim2([0-0, 0-1, 1-0, 1-1], P2), P2 = 4.

% 3x3 square has four edges each of squared length 4; total is 16.
test(hull_perim2_big) :-
    hull_hull_perim2([0-0, 0-2, 2-0, 2-2], P2), P2 = 16.

% Right triangle: two legs (L2=4 each) plus hypotenuse (L2=8); total is 16.
test(hull_perim2_triangle) :-
    hull_hull_perim2([0-0, 0-2, 2-0], P2), P2 = 16.

% hull_centroid/3 tests

% Centroid of the four 3x3 corners is the center (1,1).
test(centroid_square) :-
    hull_centroid([0-0, 0-2, 2-0, 2-2], AvgR, AvgC),
    AvgR = 1, AvgC = 1.

% Centroid of right triangle vertices: (0+2+0)/3=0, (0+0+2)/3=0 (floor).
test(centroid_triangle) :-
    hull_centroid([0-0, 0-2, 2-0], AvgR, AvgC),
    AvgR = 0, AvgC = 0.

% Centroid of tilted square [0-1,1-2,2-1,1-0]: R avg=(1+2+1+0)/4=1, C=(1+2+1+0)/4=1.
test(centroid_tilted) :-
    hull_centroid([0-1, 1-2, 2-1, 1-0], AvgR, AvgC),
    AvgR = 1, AvgC = 1.

% hull_hull_contains/2 tests

% Center cell of 3x3 grid is contained in hull of the four corners.
test(hull_contains_center) :-
    hull_hull_contains([0-0, 0-2, 2-0, 2-2], [1-1]).

% A cell far outside the 3x3 hull is not contained.
test(hull_contains_outside, [fail]) :-
    hull_hull_contains([0-0, 0-2, 2-0, 2-2], [5-5]).

% All boundary edge midpoints of the 3x3 hull are contained in it.
test(hull_contains_boundary) :-
    hull_hull_contains([0-0, 0-2, 2-0, 2-2], [0-1, 1-0, 1-2, 2-1]).

:- end_tests(hull).
