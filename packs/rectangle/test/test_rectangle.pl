:- use_module('../prolog/rectangle').

:- begin_tests(rectangle).

% rectangle_cells/5 tests

test(cells_3x3) :-
    rectangle_cells(0, 0, 2, 2, [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2]).

test(cells_1x1) :-
    rectangle_cells(1, 1, 1, 1, [1-1]).

test(cells_1x3) :-
    rectangle_cells(2, 0, 2, 2, [2-0,2-1,2-2]).

% rectangle_border/5 tests

test(border_3x3) :-
    rectangle_border(0, 0, 2, 2, Border),
    sort(Border, S),
    S = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

test(border_1x1) :-
    rectangle_border(1, 1, 1, 1, [1-1]).

test(border_2x4) :-
    rectangle_border(0, 0, 1, 3, Border),
    length(Border, 8).

% rectangle_interior/5 tests

test(interior_3x3) :-
    rectangle_interior(0, 0, 2, 2, [1-1]).

test(interior_1x1) :-
    rectangle_interior(1, 1, 1, 1, []).

test(interior_2x2) :-
    rectangle_interior(0, 0, 1, 1, []).

% rectangle_draw/7 tests

test(draw_full_3x3) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rectangle_draw(Grid, 0, 0, 2, 2, 5, Result),
    Result = [[5,5,5],[5,5,5],[5,5,5]].

test(draw_sub_rect) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rectangle_draw(Grid, 1, 1, 2, 2, 3, Result),
    Result = [[0,0,0],[0,3,3],[0,3,3]].

test(draw_single_cell) :-
    Grid = [[0,0],[0,0]],
    rectangle_draw(Grid, 0, 1, 0, 1, 7, Result),
    Result = [[0,7],[0,0]].

% rectangle_draw_border/7 tests

test(draw_border_3x3) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rectangle_draw_border(Grid, 0, 0, 2, 2, 1, Result),
    Result = [[1,1,1],[1,0,1],[1,1,1]].

test(draw_border_2x2) :-
    Grid = [[0,0],[0,0]],
    rectangle_draw_border(Grid, 0, 0, 1, 1, 4, Result),
    Result = [[4,4],[4,4]].

test(draw_border_1x3) :-
    Grid = [[0,0,0]],
    rectangle_draw_border(Grid, 0, 0, 0, 2, 2, Result),
    Result = [[2,2,2]].

% rectangle_draw_interior/7 tests

test(draw_interior_3x3) :-
    Grid = [[1,1,1],[1,0,1],[1,1,1]],
    rectangle_draw_interior(Grid, 0, 0, 2, 2, 9, Result),
    Result = [[1,1,1],[1,9,1],[1,1,1]].

test(draw_interior_empty) :-
    Grid = [[0,0],[0,0]],
    rectangle_draw_interior(Grid, 0, 0, 1, 1, 5, Grid).

test(draw_interior_5x5) :-
    Grid = [[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1]],
    rectangle_draw_interior(Grid, 0, 0, 4, 4, 2, Result),
    Result = [[1,1,1,1,1],[1,2,2,2,1],[1,2,2,2,1],[1,2,2,2,1],[1,1,1,1,1]].

% rectangle_area/5 tests

test(area_3x3) :-
    rectangle_area(0, 0, 2, 2, 9).

test(area_1x1) :-
    rectangle_area(0, 0, 0, 0, 1).

test(area_2x4) :-
    rectangle_area(0, 0, 1, 3, 8).

% rectangle_contains/6 tests

test(contains_inside) :-
    rectangle_contains(0, 0, 2, 2, 1, 1).

test(contains_on_border) :-
    rectangle_contains(0, 0, 2, 2, 0, 0).

test(contains_outside) :-
    \+ rectangle_contains(0, 0, 2, 2, 3, 1).

% rectangle_corners/5 tests

test(corners_rect) :-
    rectangle_corners(0, 0, 2, 3, [0-0, 0-3, 2-0, 2-3]).

test(corners_1x1) :-
    rectangle_corners(1, 1, 1, 1, [1-1, 1-1, 1-1, 1-1]).

test(corners_1x3) :-
    rectangle_corners(0, 0, 0, 2, [0-0, 0-2, 0-0, 0-2]).

% rectangle_bbox/5 tests

test(bbox_basic) :-
    rectangle_bbox([0-0, 1-2, 3-1], MinR, MinC, MaxR, MaxC),
    MinR = 0, MinC = 0, MaxR = 3, MaxC = 2.

test(bbox_single) :-
    rectangle_bbox([2-3], MinR, MinC, MaxR, MaxC),
    MinR = 2, MinC = 3, MaxR = 2, MaxC = 3.

test(bbox_line) :-
    rectangle_bbox([1-0, 1-1, 1-2], MinR, MinC, MaxR, MaxC),
    MinR = 1, MinC = 0, MaxR = 1, MaxC = 2.

% rectangle_is_solid/6 tests

test(is_solid_true) :-
    Grid = [[5,5,5],[5,5,5],[5,5,5]],
    rectangle_is_solid(Grid, 0, 0, 2, 2, 5).

test(is_solid_1x1) :-
    Grid = [[0,7],[3,1]],
    rectangle_is_solid(Grid, 0, 1, 0, 1, 7).

test(is_solid_false) :-
    Grid = [[5,5,5],[5,3,5],[5,5,5]],
    \+ rectangle_is_solid(Grid, 0, 0, 2, 2, 5).

% rectangle_is_frame/6 tests

test(is_frame_true) :-
    Grid = [[1,1,1],[1,0,1],[1,1,1]],
    rectangle_is_frame(Grid, 0, 0, 2, 2, 1).

test(is_frame_1x1) :-
    Grid = [[9]],
    rectangle_is_frame(Grid, 0, 0, 0, 0, 9).

test(is_frame_false) :-
    Grid = [[1,1,1],[1,0,1],[1,2,1]],
    \+ rectangle_is_frame(Grid, 0, 0, 2, 2, 1).

% rectangle_overlap/8 tests

test(overlap_true) :-
    rectangle_overlap(0, 0, 2, 2, 1, 1, 3, 3).

test(overlap_contained) :-
    rectangle_overlap(0, 0, 4, 4, 1, 1, 3, 3).

test(overlap_false) :-
    \+ rectangle_overlap(0, 0, 1, 1, 2, 2, 3, 3).

% rectangle_scale/7 tests

test(scale_2x) :-
    rectangle_scale(0, 0, 2, 2, 2, R2, C2),
    R2 = 4, C2 = 4.

test(scale_1x) :-
    rectangle_scale(0, 0, 3, 5, 1, R2, C2),
    R2 = 3, C2 = 5.

test(scale_3x) :-
    rectangle_scale(1, 1, 2, 3, 3, R2, C2),
    R2 = 4, C2 = 7.

:- end_tests(rectangle).
