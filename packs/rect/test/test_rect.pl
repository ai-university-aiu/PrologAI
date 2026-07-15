:- use_module('../prolog/rect').

:- begin_tests(rect).

% rect_cells/5 tests

test(cells_3x3) :-
    rect_cells(0, 0, 2, 2, [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2]).

test(cells_1x1) :-
    rect_cells(1, 1, 1, 1, [1-1]).

test(cells_1x3) :-
    rect_cells(2, 0, 2, 2, [2-0,2-1,2-2]).

% rect_border/5 tests

test(border_3x3) :-
    rect_border(0, 0, 2, 2, Border),
    sort(Border, S),
    S = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

test(border_1x1) :-
    rect_border(1, 1, 1, 1, [1-1]).

test(border_2x4) :-
    rect_border(0, 0, 1, 3, Border),
    length(Border, 8).

% rect_interior/5 tests

test(interior_3x3) :-
    rect_interior(0, 0, 2, 2, [1-1]).

test(interior_1x1) :-
    rect_interior(1, 1, 1, 1, []).

test(interior_2x2) :-
    rect_interior(0, 0, 1, 1, []).

% rect_draw/7 tests

test(draw_full_3x3) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rect_draw(Grid, 0, 0, 2, 2, 5, Result),
    Result = [[5,5,5],[5,5,5],[5,5,5]].

test(draw_sub_rect) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rect_draw(Grid, 1, 1, 2, 2, 3, Result),
    Result = [[0,0,0],[0,3,3],[0,3,3]].

test(draw_single_cell) :-
    Grid = [[0,0],[0,0]],
    rect_draw(Grid, 0, 1, 0, 1, 7, Result),
    Result = [[0,7],[0,0]].

% rect_draw_border/7 tests

test(draw_border_3x3) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    rect_draw_border(Grid, 0, 0, 2, 2, 1, Result),
    Result = [[1,1,1],[1,0,1],[1,1,1]].

test(draw_border_2x2) :-
    Grid = [[0,0],[0,0]],
    rect_draw_border(Grid, 0, 0, 1, 1, 4, Result),
    Result = [[4,4],[4,4]].

test(draw_border_1x3) :-
    Grid = [[0,0,0]],
    rect_draw_border(Grid, 0, 0, 0, 2, 2, Result),
    Result = [[2,2,2]].

% rect_draw_interior/7 tests

test(draw_interior_3x3) :-
    Grid = [[1,1,1],[1,0,1],[1,1,1]],
    rect_draw_interior(Grid, 0, 0, 2, 2, 9, Result),
    Result = [[1,1,1],[1,9,1],[1,1,1]].

test(draw_interior_empty) :-
    Grid = [[0,0],[0,0]],
    rect_draw_interior(Grid, 0, 0, 1, 1, 5, Grid).

test(draw_interior_5x5) :-
    Grid = [[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1]],
    rect_draw_interior(Grid, 0, 0, 4, 4, 2, Result),
    Result = [[1,1,1,1,1],[1,2,2,2,1],[1,2,2,2,1],[1,2,2,2,1],[1,1,1,1,1]].

% rect_area/5 tests

test(area_3x3) :-
    rect_area(0, 0, 2, 2, 9).

test(area_1x1) :-
    rect_area(0, 0, 0, 0, 1).

test(area_2x4) :-
    rect_area(0, 0, 1, 3, 8).

% rect_contains/6 tests

test(contains_inside) :-
    rect_contains(0, 0, 2, 2, 1, 1).

test(contains_on_border) :-
    rect_contains(0, 0, 2, 2, 0, 0).

test(contains_outside) :-
    \+ rect_contains(0, 0, 2, 2, 3, 1).

% rect_corners/5 tests

test(corners_rect) :-
    rect_corners(0, 0, 2, 3, [0-0, 0-3, 2-0, 2-3]).

test(corners_1x1) :-
    rect_corners(1, 1, 1, 1, [1-1, 1-1, 1-1, 1-1]).

test(corners_1x3) :-
    rect_corners(0, 0, 0, 2, [0-0, 0-2, 0-0, 0-2]).

% rect_bbox/5 tests

test(bbox_basic) :-
    rect_bbox([0-0, 1-2, 3-1], MinR, MinC, MaxR, MaxC),
    MinR = 0, MinC = 0, MaxR = 3, MaxC = 2.

test(bbox_single) :-
    rect_bbox([2-3], MinR, MinC, MaxR, MaxC),
    MinR = 2, MinC = 3, MaxR = 2, MaxC = 3.

test(bbox_line) :-
    rect_bbox([1-0, 1-1, 1-2], MinR, MinC, MaxR, MaxC),
    MinR = 1, MinC = 0, MaxR = 1, MaxC = 2.

% rect_is_solid/6 tests

test(is_solid_true) :-
    Grid = [[5,5,5],[5,5,5],[5,5,5]],
    rect_is_solid(Grid, 0, 0, 2, 2, 5).

test(is_solid_1x1) :-
    Grid = [[0,7],[3,1]],
    rect_is_solid(Grid, 0, 1, 0, 1, 7).

test(is_solid_false) :-
    Grid = [[5,5,5],[5,3,5],[5,5,5]],
    \+ rect_is_solid(Grid, 0, 0, 2, 2, 5).

% rect_is_frame/6 tests

test(is_frame_true) :-
    Grid = [[1,1,1],[1,0,1],[1,1,1]],
    rect_is_frame(Grid, 0, 0, 2, 2, 1).

test(is_frame_1x1) :-
    Grid = [[9]],
    rect_is_frame(Grid, 0, 0, 0, 0, 9).

test(is_frame_false) :-
    Grid = [[1,1,1],[1,0,1],[1,2,1]],
    \+ rect_is_frame(Grid, 0, 0, 2, 2, 1).

% rect_overlap/8 tests

test(overlap_true) :-
    rect_overlap(0, 0, 2, 2, 1, 1, 3, 3).

test(overlap_contained) :-
    rect_overlap(0, 0, 4, 4, 1, 1, 3, 3).

test(overlap_false) :-
    \+ rect_overlap(0, 0, 1, 1, 2, 2, 3, 3).

% rect_scale/7 tests

test(scale_2x) :-
    rect_scale(0, 0, 2, 2, 2, R2, C2),
    R2 = 4, C2 = 4.

test(scale_1x) :-
    rect_scale(0, 0, 3, 5, 1, R2, C2),
    R2 = 3, C2 = 5.

test(scale_3x) :-
    rect_scale(1, 1, 2, 3, 3, R2, C2),
    R2 = 4, C2 = 7.

:- end_tests(rect).
