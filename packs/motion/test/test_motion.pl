:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(grid)).
:- use_module(library(scene)).
:- use_module('../prolog/motion').

% FIXTURE GRIDS
% A 4x4 grid with foreground (non-zero) cells scattered above the floor.
%   0 1 0 0
%   0 0 2 0
%   0 0 0 3
%   0 0 0 0
grid_scattered([[0,1,0,0],[0,0,2,0],[0,0,0,3],[0,0,0,0]]).

% A 3x4 grid for gravity-left and gravity-right tests.
%   0 1 0 2
%   3 0 0 0
%   0 0 4 0
grid_sparse([[0,1,0,2],[3,0,0,0],[0,0,4,0]]).

% A 2x2 grid with foreground in top-left and bottom-right.
grid_2x2([[1,0],[0,2]]).

% A scene with two objects for translation and rendering tests.
scene_two_objs(scene(4,4,0,[obj(1,[r(0,0)]),obj(2,[r(1,2)])])).


:- begin_tests(motion_gravity_down).

% Gravity-down: all foreground cells sink to the bottom of their columns.
test(gravity_down_basic, nondet) :-
    grid_scattered(G),
    mv_gravity_down(G, 0, G2),
% Column 0: no foreground; column 1: 1 cell sinks to row 3.
    gd_cell(G2, 3, 1, 1),
    gd_cell(G2, 0, 1, 0),
% Column 2: 1 cell sinks to row 3.
    gd_cell(G2, 3, 2, 2),
% Column 3: 1 cell sinks to row 3.
    gd_cell(G2, 3, 3, 3).

% Gravity-down on a grid with no foreground is identity.
test(gravity_down_empty, nondet) :-
    gd_make(3, 3, 0, G),
    mv_gravity_down(G, 0, G2),
    gd_equal(G, G2).

% Gravity-down on a grid already at the bottom is identity.
test(gravity_down_already_down, nondet) :-
    G = [[0,0],[1,2]],
    mv_gravity_down(G, 0, G2),
    gd_equal(G, G2).

% Gravity-down preserves grid dimensions.
test(gravity_down_size, nondet) :-
    grid_sparse(G),
    mv_gravity_down(G, 0, G2),
    gd_size(G, R, C),
    gd_size(G2, R, C).

:- end_tests(motion_gravity_down).


:- begin_tests(motion_gravity_up).

% Gravity-up: all foreground cells rise to the top of their columns.
test(gravity_up_basic, nondet) :-
    grid_scattered(G),
    mv_gravity_up(G, 0, G2),
    gd_cell(G2, 0, 1, 1),
    gd_cell(G2, 0, 2, 2),
    gd_cell(G2, 0, 3, 3).

% Gravity-up on empty grid is identity.
test(gravity_up_empty, nondet) :-
    gd_make(3, 3, 0, G),
    mv_gravity_up(G, 0, G2),
    gd_equal(G, G2).

% Gravity-up on a grid already at the top is identity.
test(gravity_up_already_up, nondet) :-
    G = [[1,2],[0,0]],
    mv_gravity_up(G, 0, G2),
    gd_equal(G, G2).

:- end_tests(motion_gravity_up).


:- begin_tests(motion_gravity_lr).

% Gravity-left: foreground cells slide to the left of each row.
test(gravity_left_basic) :-
    grid_sparse(G),
    mv_gravity_left(G, 0, G2),
% Row 0: [0,1,0,2] -> [1,2,0,0].
    gd_cell(G2, 0, 0, 1),
    gd_cell(G2, 0, 1, 2),
    gd_cell(G2, 0, 2, 0),
% Row 1: [3,0,0,0] -> [3,0,0,0] (already leftmost).
    gd_cell(G2, 1, 0, 3).

% Gravity-right: foreground cells slide to the right of each row.
test(gravity_right_basic) :-
    grid_sparse(G),
    mv_gravity_right(G, 0, G2),
% Row 0: [0,1,0,2] -> [0,0,1,2].
    gd_cell(G2, 0, 2, 1),
    gd_cell(G2, 0, 3, 2).

% Gravity-left then gravity-right is not necessarily identity, but sizes match.
test(gravity_lr_size) :-
    grid_sparse(G),
    mv_gravity_left(G, 0, G2),
    gd_size(G, R, C),
    gd_size(G2, R, C).

:- end_tests(motion_gravity_lr).


:- begin_tests(motion_slide_col_row).

% Slide column down (same as gravity on one column).
test(slide_col_down, nondet) :-
    G = [[1,0],[0,0],[0,0]],
    mv_slide_col(G, 0, down, G2),
    gd_cell(G2, 2, 0, 1),
    gd_cell(G2, 0, 0, 0).

% Slide column up.
test(slide_col_up, nondet) :-
    G = [[0,0],[0,0],[1,0]],
    mv_slide_col(G, 0, up, G2),
    gd_cell(G2, 0, 0, 1),
    gd_cell(G2, 2, 0, 0).

% Slide row left.
test(slide_row_left, nondet) :-
    G = [[0,1,0],[0,0,0]],
    mv_slide_row(G, 0, left, G2),
    gd_cell(G2, 0, 0, 1),
    gd_cell(G2, 0, 1, 0).

% Slide row right.
test(slide_row_right) :-
    G = [[1,0,0],[0,0,0]],
    mv_slide_row(G, 0, right, G2),
    gd_cell(G2, 0, 2, 1),
    gd_cell(G2, 0, 0, 0).

:- end_tests(motion_slide_col_row).


:- begin_tests(motion_shift_grid).

% Shift grid down by 1: content moves down, top row filled with Bg.
test(shift_down) :-
    grid_2x2(G),
    mv_shift_grid(G, 1, 0, 0, G2),
    gd_cell(G2, 1, 0, 1),
    gd_cell(G2, 0, 0, 0).

% Shift grid right by 1.
test(shift_right) :-
    grid_2x2(G),
    mv_shift_grid(G, 0, 1, 0, G2),
    gd_cell(G2, 0, 1, 1),
    gd_cell(G2, 0, 0, 0).

% Shift by (0,0) is identity.
test(shift_zero) :-
    grid_2x2(G),
    mv_shift_grid(G, 0, 0, 0, G2),
    gd_equal(G, G2).

:- end_tests(motion_shift_grid).


:- begin_tests(motion_obj_translate).

% Translate object down by 1.
test(translate_down) :-
    mv_obj_translate(obj(1,[r(0,0),r(0,1)]), 1, 0, obj(1,NewCells)),
    msort(NewCells, [r(1,0),r(1,1)]).

% Translate object right by 2.
test(translate_right) :-
    mv_obj_translate(obj(2,[r(1,0)]), 0, 2, obj(2,[r(1,2)])).

% Translate by (0,0) is identity.
test(translate_zero) :-
    Obj = obj(3,[r(2,2),r(3,2)]),
    mv_obj_translate(Obj, 0, 0, Obj2),
    Obj2 = obj(3,_),
    sc_obj_cells(Obj, Cells),
    sc_obj_cells(Obj2, Cells2),
    msort(Cells, S), msort(Cells2, S).

% Color is preserved through translation.
test(translate_preserves_color) :-
    mv_obj_translate(obj(5,[r(0,0)]), 3, 3, Obj2),
    sc_obj_color(Obj2, 5).

:- end_tests(motion_obj_translate).


:- begin_tests(motion_scene_translate).

% Translating all objects in a scene moves each one.
test(scene_translate_all, nondet) :-
    scene_two_objs(Scene),
    mv_scene_translate(Scene, 1, 1, scene(_, _, _, Objects2)),
    member(obj(1,Cells1), Objects2),
    member(r(1,1), Cells1),
    member(obj(2,Cells2), Objects2),
    member(r(2,3), Cells2).

% Scene dimensions are preserved by translation.
test(scene_translate_dims) :-
    scene_two_objs(Scene),
    mv_scene_translate(Scene, 0, 0, Scene2),
    Scene = scene(R, C, Bg, _),
    Scene2 = scene(R, C, Bg, _).

:- end_tests(motion_scene_translate).


:- begin_tests(motion_scene_to_grid).

% Rendering a scene produces a grid with correct dimensions.
test(scene_to_grid_size) :-
    scene_two_objs(Scene),
    mv_scene_to_grid(Scene, Grid),
    gd_size(Grid, 4, 4).

% Object cells appear in the rendered grid with correct colors.
test(scene_to_grid_cells) :-
    scene_two_objs(Scene),
    mv_scene_to_grid(Scene, Grid),
    gd_cell(Grid, 0, 0, 1),
    gd_cell(Grid, 1, 2, 2),
    gd_cell(Grid, 0, 1, 0).

% Rendering a scene with no objects gives a uniform background.
test(scene_to_grid_empty_scene) :-
    mv_scene_to_grid(scene(3, 3, 0, []), Grid),
    gd_make(3, 3, 0, Expected),
    gd_equal(Grid, Expected).

:- end_tests(motion_scene_to_grid).


:- begin_tests(motion_scene_gravity).

% Applying scene gravity moves objects downward.
test(scene_gravity_basic, nondet) :-
    scene_two_objs(Scene),
    mv_scene_gravity(Scene, Scene2),
% After gravity, the grid should have objects at the bottom rows.
    mv_scene_to_grid(Scene2, Grid2),
    gd_size(Grid2, 4, 4),
% Color 1 object was at (0,0); should now be near row 3.
    gd_cell(Grid2, 3, 0, 1).

:- end_tests(motion_scene_gravity).


:- begin_tests(motion_distance).

% Manhattan distance between adjacent cells is 1.
test(distance_adjacent) :-
    mv_distance(r(0,0), r(0,1), 1).

% Manhattan distance is symmetric.
test(distance_symmetric) :-
    mv_distance(r(1,2), r(4,6), D1),
    mv_distance(r(4,6), r(1,2), D2),
    D1 =:= D2.

% Distance to self is 0.
test(distance_self) :-
    mv_distance(r(3,3), r(3,3), 0).

% Manhattan distance: |R2-R1| + |C2-C1|.
test(distance_formula) :-
    mv_distance(r(0,0), r(3,4), 7).

% mv_closest_cell finds the nearest cell (r(0,1) is at distance 1; others are farther).
test(closest_cell) :-
    Cells = [r(5,5), r(1,1), r(0,1)],
    mv_closest_cell(Cells, r(0,0), Closest),
    Closest = r(0,1).

% mv_closest_cell with one cell returns that cell.
test(closest_cell_single) :-
    mv_closest_cell([r(3,3)], r(0,0), r(3,3)).

:- end_tests(motion_distance).
