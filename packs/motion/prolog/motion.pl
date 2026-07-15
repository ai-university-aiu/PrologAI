% Module declaration: motion exports all mv_* predicates.
:- module(motion, [
    motion_gravity_down/3,
    motion_gravity_up/3,
    motion_gravity_left/3,
    motion_gravity_right/3,
    motion_shift_grid/5,
    motion_obj_translate/4,
    motion_scene_translate/4,
    motion_scene_to_grid/2,
    motion_scene_gravity/2,
    motion_distance/3,
    motion_closest_cell/3,
    motion_slide_col/4,
    motion_slide_row/4
]).

% Import list utilities.
:- use_module(library(lists),
    [member/2, nth0/3, append/2, append/3, numlist/3,
     min_list/2, max_list/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4, include/3]).
% Import grid pack for raw grid operations.
:- use_module(library(grid)).
% Import scene pack for object representation.
:- use_module(library(scene)).


% GRAVITY ON RAW GRIDS
% motion_gravity_down(+Grid, +Bg, -Grid2): non-Bg cells sink to the bottom of each column.
motion_gravity_down(Grid, Bg, Grid2) :-
% Get column count.
    gd_size(Grid, _, Cols),
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
% Apply downward gravity to each column in sequence.
    foldl(apply_gravity_down(Bg), ColIndices, Grid, Grid2).

% apply_gravity_down(+Bg, +C, +GridAcc, -GridAcc2): sink non-Bg in column C.
apply_gravity_down(Bg, C, GridAcc, GridAcc2) :-
% Extract the column.
    gd_col(GridAcc, C, Col),
% Separate non-Bg cells from Bg cells.
    include(not_color(Bg), Col, Fg),
    length(Col, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
% New column: BgLen Bg cells on top, then all Fg cells.
    length(BgTop, BgLen),
    maplist(=(Bg), BgTop),
    append(BgTop, Fg, NewCol),
% Replace column C in the grid.
    set_col(GridAcc, C, NewCol, GridAcc2).

% not_color(+Bg, +Color): Color is not Bg.
not_color(Bg, Color) :- Color \== Bg.

% motion_gravity_up(+Grid, +Bg, -Grid2): non-Bg cells rise to the top of each column.
motion_gravity_up(Grid, Bg, Grid2) :-
    gd_size(Grid, _, Cols),
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
    foldl(apply_gravity_up(Bg), ColIndices, Grid, Grid2).

% apply_gravity_up(+Bg, +C, +GridAcc, -GridAcc2): raise non-Bg in column C.
apply_gravity_up(Bg, C, GridAcc, GridAcc2) :-
    gd_col(GridAcc, C, Col),
    include(not_color(Bg), Col, Fg),
    length(Col, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
% New column: Fg cells on top, then BgLen Bg cells.
    length(BgBot, BgLen),
    maplist(=(Bg), BgBot),
    append(Fg, BgBot, NewCol),
    set_col(GridAcc, C, NewCol, GridAcc2).

% motion_gravity_left(+Grid, +Bg, -Grid2): non-Bg cells slide to the left of each row.
motion_gravity_left(Grid, Bg, Grid2) :-
    maplist(slide_row_left(Bg), Grid, Grid2).

% slide_row_left(+Bg, +Row, -Row2): slide non-Bg cells to the left.
slide_row_left(Bg, Row, Row2) :-
    include(not_color(Bg), Row, Fg),
    length(Row, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgRight, BgLen),
    maplist(=(Bg), BgRight),
    append(Fg, BgRight, Row2).

% motion_gravity_right(+Grid, +Bg, -Grid2): non-Bg cells slide to the right of each row.
motion_gravity_right(Grid, Bg, Grid2) :-
    maplist(slide_row_right(Bg), Grid, Grid2).

% slide_row_right(+Bg, +Row, -Row2): slide non-Bg cells to the right.
slide_row_right(Bg, Row, Row2) :-
    include(not_color(Bg), Row, Fg),
    length(Row, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgLeft, BgLen),
    maplist(=(Bg), BgLeft),
    append(BgLeft, Fg, Row2).


% SET A COLUMN IN A GRID
% set_col(+Grid, +C, +NewCol, -Grid2): replace column C with NewCol.
set_col(Grid, C, NewCol, Grid2) :-
    gd_size(Grid, Rows, _),
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(set_col_row(Grid, C, NewCol), RowIndices, Grid2).

% set_col_row(+Grid, +C, +NewCol, +R, -Row2): update cell C in row R.
set_col_row(Grid, C, NewCol, R, Row2) :-
    gd_row(Grid, R, Row),
    nth0(R, NewCol, NewColor),
    set_nth(Row, C, NewColor, Row2).

% set_nth(+List, +I, +Val, -List2): replace the I-th element.
set_nth([_|T], 0, Val, [Val|T]).
set_nth([H|T], I, Val, [H|T2]) :-
    I > 0, I1 is I - 1,
    set_nth(T, I1, Val, T2).


% GRID SHIFT
% motion_shift_grid(+Grid, +DR, +DC, +Bg, -Grid2): shift all content by (DR, DC).
motion_shift_grid(Grid, DR, DC, Bg, Grid2) :-
% Delegate to gd_translate which handles out-of-bounds with a fill color.
    gd_translate(Grid, DR, DC, Bg, Grid2).


% INDIVIDUAL COLUMN AND ROW SLIDING
% motion_slide_col(+Grid, +C, +Dir, -Grid2): slide column C up or down.
motion_slide_col(Grid, C, down, Grid2) :-
% Extract column, apply downward gravity.
    gd_col(Grid, C, Col),
    gd_size(Grid, _, _),
% Move all non-zero cells to the bottom.
    include(is_fg, Col, Fg),
    length(Col, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgTop, BgLen),
    maplist(=(0), BgTop),
    append(BgTop, Fg, NewCol),
    set_col(Grid, C, NewCol, Grid2).
motion_slide_col(Grid, C, up, Grid2) :-
    gd_col(Grid, C, Col),
    include(is_fg, Col, Fg),
    length(Col, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgBot, BgLen),
    maplist(=(0), BgBot),
    append(Fg, BgBot, NewCol),
    set_col(Grid, C, NewCol, Grid2).

% motion_slide_row(+Grid, +R, +Dir, -Grid2): slide row R left or right.
motion_slide_row(Grid, R, left, Grid2) :-
    gd_row(Grid, R, Row),
    include(is_fg, Row, Fg),
    length(Row, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgRight, BgLen),
    maplist(=(0), BgRight),
    append(Fg, BgRight, NewRow),
    set_row(Grid, R, NewRow, Grid2).
motion_slide_row(Grid, R, right, Grid2) :-
    gd_row(Grid, R, Row),
    include(is_fg, Row, Fg),
    length(Row, Len),
    length(Fg, FgLen),
    BgLen is Len - FgLen,
    length(BgLeft, BgLen),
    maplist(=(0), BgLeft),
    append(BgLeft, Fg, NewRow),
    set_row(Grid, R, NewRow, Grid2).

% set_row(+Grid, +R, +NewRow, -Grid2): replace row R with NewRow.
set_row(Grid, R, NewRow, Grid2) :-
    nth0(R, Grid, _, Rest),
    nth0(R, Grid2, NewRow, Rest).

% is_fg(+Color): color 0 is background; anything else is foreground.
is_fg(Color) :- Color \== 0.


% OBJECT TRANSLATION
% motion_obj_translate(+Obj, +DR, +DC, -Obj2): shift all cells of an object by (DR,DC).
motion_obj_translate(obj(Color, Cells), DR, DC, obj(Color, NewCells)) :-
% Shift every cell and sort the result.
    maplist(shift_cell(DR, DC), Cells, Shifted),
    msort(Shifted, NewCells).

% shift_cell(+DR, +DC, +r(R,C), -r(R2,C2)): shift one cell.
shift_cell(DR, DC, r(R, C), r(R2, C2)) :-
    R2 is R + DR,
    C2 is C + DC.

% motion_scene_translate(+Scene, +DR, +DC, -Scene2): translate all objects in a scene.
motion_scene_translate(scene(Rows, Cols, Bg, Objects), DR, DC, scene(Rows, Cols, Bg, Objects2)) :-
% Translate every object.
    maplist(translate_obj(DR, DC), Objects, Objects2).

% translate_obj(+DR, +DC, +Obj, -Obj2): helper for maplist.
translate_obj(DR, DC, Obj, Obj2) :-
    motion_obj_translate(Obj, DR, DC, Obj2).


% SCENE TO GRID RENDERING
% motion_scene_to_grid(+Scene, -Grid): render a scene back to a raw grid.
motion_scene_to_grid(scene(Rows, Cols, Bg, Objects), Grid) :-
% Start with a uniform background grid.
    gd_make(Rows, Cols, Bg, BaseGrid),
% Paint each object's cells onto the grid.
    foldl(paint_obj, Objects, BaseGrid, Grid).

% paint_obj(+Obj, +GridAcc, -GridAcc2): paint all cells of Obj onto the grid.
paint_obj(obj(Color, Cells), GridAcc, GridAcc2) :-
% Paint each cell with the object color.
    foldl(paint_cell(Color), Cells, GridAcc, GridAcc2).

% paint_cell(+Color, +r(R,C), +GridAcc, -GridAcc2): set one cell's color.
paint_cell(Color, r(R, C), GridAcc, GridAcc2) :-
    gd_set_cell(GridAcc, R, C, Color, GridAcc2).


% SCENE-LEVEL GRAVITY (ROUND-TRIP)
% motion_scene_gravity(+Scene, -Scene2): render scene, apply column gravity, re-parse.
motion_scene_gravity(Scene, Scene2) :-
    Scene = scene(_, _, Bg, _),
% Render scene to grid.
    motion_scene_to_grid(Scene, Grid),
% Apply column gravity with Bg as background color.
    motion_gravity_down(Grid, Bg, Grid2),
% Re-parse the grid into a new scene.
    sc_grid_to_scene(Grid2, Scene2).


% DISTANCE METRICS
% motion_distance(+r(R1,C1), +r(R2,C2), -D): Manhattan distance between two cells.
motion_distance(r(R1, C1), r(R2, C2), D) :-
    DR is abs(R2 - R1),
    DC is abs(C2 - C1),
    D is DR + DC.

% motion_closest_cell(+Cells, +Ref, -Closest): cell in Cells closest to Ref.
motion_closest_cell([H|T], Ref, Closest) :-
% Compute distances to all cells.
    motion_distance(H, Ref, D0),
% Fold to find the minimum.
    foldl(closer_cell(Ref), T, H-D0, Closest-_).

% closer_cell(+Ref, +Cell, +BestSoFar-BestD, -NewBest-NewD): keep the closer cell.
closer_cell(Ref, Cell, Best-BestD, NewBest-NewD) :-
    motion_distance(Cell, Ref, D),
    ( D < BestD ->
        NewBest = Cell, NewD = D
    ;
        NewBest = Best, NewD = BestD
    ).
