% ray.pl - Layer 103: Ray Casting and Line-of-Sight Operations (ry_* prefix).
% Provides directional ray traversal, obstacle detection, line-of-sight tests,
% distance-to-edge and distance-to-obstacle queries, direction reflection,
% and multi-direction casting in 2D integer-coordinate grids.
:- module(ray, [
    ry_in_bounds/3,
    ry_cells_in_dir/6,
    ry_first_hit/7,
    ry_cast_clear/7,
    ry_distance_to_hit/7,
    ry_distance_to_edge/6,
    ry_is_clear/6,
    ry_project/8,
    ry_dir_to_delta/3,
    ry_reflect_h/4,
    ry_reflect_v/4,
    ry_los/6,
    ry_los_cells/6,
    ry_cast_all_4/5
]).
% Import list utilities for range generation and element lookup.
:- use_module(library(lists), [nth0/3, numlist/3, member/2]).
% Import higher-order utilities for mapping.
:- use_module(library(apply), [maplist/3]).

% ry_dims_: extract row and column count from a grid.
ry_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Get column count from first row when grid is non-empty.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% ry_in_bounds(+Grid, +R, +C): succeed if (R,C) is within the grid bounds.
ry_in_bounds(Grid, R, C) :-
% Get grid dimensions.
    ry_dims_(Grid, NR, NC),
% Test row and column bounds (0-based, inclusive).
    0 =< R, R < NR,
    0 =< C, C < NC.

% ry_cells_in_dir_: helper to enumerate cells stepping from (R,C) in direction.
ry_cells_in_dir_(R, C, DR, DC, NR, NC, Cells) :-
    (0 =< R, R < NR, 0 =< C, C < NC ->
% Cell is in bounds: include it and step to the next.
        Cells = [R-C|Rest],
        R1 is R + DR, C1 is C + DC,
        ry_cells_in_dir_(R1, C1, DR, DC, NR, NC, Rest)
    ;
% Cell is out of bounds: terminate the ray.
        Cells = []
    ).

% ry_cells_in_dir(+Grid, +R, +C, +DR, +DC, -Cells): all in-bounds cells stepping
% from (R+DR, C+DC) in direction (DR,DC) until leaving the grid. The starting
% cell (R,C) is NOT included.
ry_cells_in_dir(Grid, R, C, DR, DC, Cells) :-
% Get grid dimensions for bounds checking.
    ry_dims_(Grid, NR, NC),
% Start one step beyond the origin.
    R1 is R + DR, C1 is C + DC,
% Walk until out of bounds.
    ry_cells_in_dir_(R1, C1, DR, DC, NR, NC, Cells).

% ry_cell_val_: retrieve value at a cell coordinate.
ry_cell_val_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% ry_first_hit_(: find the first non-Bg cell in a list.
ry_first_hit_([], _, _, _) :- fail.
ry_first_hit_([Cell|Rest], Grid, Bg, Hit) :-
    ry_cell_val_(Grid, Cell, Val),
    (Val \== Bg ->
% This cell is the obstacle.
        Hit = Cell
    ;
% Continue searching.
        ry_first_hit_(Rest, Grid, Bg, Hit)
    ).

% ry_first_hit(+Grid, +R, +C, +DR, +DC, +Bg, -Hit): first cell in direction
% (DR,DC) from (R,C) with a value different from Bg. Fails if no such cell.
ry_first_hit(Grid, R, C, DR, DC, Bg, Hit) :-
    ry_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ry_first_hit_(Cells, Grid, Bg, Hit).

% ry_take_while_bg_: collect cells while they are the background color.
ry_take_while_bg_([], _, _, []) :- !.
ry_take_while_bg_([Cell|Rest], Grid, Bg, Result) :-
    ry_cell_val_(Grid, Cell, Val),
    (Val == Bg ->
% Cell is background; include it and continue.
        Result = [Cell|RestResult],
        ry_take_while_bg_(Rest, Grid, Bg, RestResult)
    ;
% Cell is an obstacle; stop here.
        Result = []
    ).

% ry_cast_clear(+Grid, +R, +C, +DR, +DC, +Bg, -Clear): cells in direction
% (DR,DC) that have value Bg, stopping before the first non-Bg cell.
% Clear does NOT include the obstacle cell.
ry_cast_clear(Grid, R, C, DR, DC, Bg, Clear) :-
    ry_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ry_take_while_bg_(Cells, Grid, Bg, Clear).

% ry_dist_hit_: count steps to the first non-Bg cell.
ry_dist_hit_([], _, _, _, _) :- fail.
ry_dist_hit_([Cell|Rest], Grid, Bg, N, D) :-
    ry_cell_val_(Grid, Cell, Val),
    (Val \== Bg ->
% Found the obstacle at step N.
        D = N
    ;
% Continue counting.
        N1 is N + 1,
        ry_dist_hit_(Rest, Grid, Bg, N1, D)
    ).

% ry_distance_to_hit(+Grid, +R, +C, +DR, +DC, +Bg, -D): number of steps from
% (R,C) to the first non-Bg cell in direction (DR,DC). Fails if no obstacle.
ry_distance_to_hit(Grid, R, C, DR, DC, Bg, D) :-
    ry_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ry_dist_hit_(Cells, Grid, Bg, 1, D).

% ry_distance_to_edge(+Grid, +R, +C, +DR, +DC, -D): number of steps from (R,C)
% to the last in-bounds cell in direction (DR,DC). Returns 0 if the next cell
% is already out of bounds.
ry_distance_to_edge(Grid, R, C, DR, DC, D) :-
    ry_cells_in_dir(Grid, R, C, DR, DC, Cells),
    length(Cells, D).

% ry_is_clear(+Grid, +R, +C, +DR, +DC, +Bg): succeed if all cells in direction
% (DR,DC) from (R,C) until the grid boundary have value Bg.
ry_is_clear(Grid, R, C, DR, DC, Bg) :-
    ry_cells_in_dir(Grid, R, C, DR, DC, Cells),
    forall(member(Cell, Cells), (ry_cell_val_(Grid, Cell, Val), Val == Bg)).

% ry_project(+Grid, +R, +C, +DR, +DC, +N, -NewR, -NewC): cell N steps from
% (R,C) in direction (DR,DC). Fails if the result is out of grid bounds.
ry_project(Grid, R, C, DR, DC, N, NewR, NewC) :-
% Compute the new coordinates.
    NewR is R + DR * N,
    NewC is C + DC * N,
% Verify the result is within bounds.
    ry_in_bounds(Grid, NewR, NewC).

% ry_dir_to_delta(+Dir, -DR, -DC): map a named direction atom to a unit step.
% Named directions: up, down, left, right, ul, ur, dl, dr.
ry_dir_to_delta(Dir, DR, DC) :-
    (Dir = up    -> DR = -1, DC =  0
    ; Dir = down  -> DR =  1, DC =  0
    ; Dir = left  -> DR =  0, DC = -1
    ; Dir = right -> DR =  0, DC =  1
    ; Dir = ul    -> DR = -1, DC = -1
    ; Dir = ur    -> DR = -1, DC =  1
    ; Dir = dl    -> DR =  1, DC = -1
    ; Dir = dr    -> DR =  1, DC =  1
    ).

% ry_reflect_h(+DR, +DC, -RDR, -RDC): reflect a direction across a horizontal axis.
% The row component negates; the column component is unchanged.
ry_reflect_h(DR, DC, RDR, DC) :-
    RDR is -DR.

% ry_reflect_v(+DR, +DC, -RDR, -RDC): reflect a direction across a vertical axis.
% The column component negates; the row component is unchanged.
ry_reflect_v(DR, DC, DR, RDC) :-
    RDC is -DC.

% ry_diag_walk_: enumerate cells along a 45-degree walk from (R,C) to (R2,C2).
ry_diag_walk_(R, C, R2, C2, DR, DC, Cells) :-
    (R =:= R2, C =:= C2 ->
% Reached endpoint: include it.
        Cells = [R-C]
    ;
% Step and continue.
        R1 is R + DR, C1 is C + DC,
        ry_diag_walk_(R1, C1, R2, C2, DR, DC, Rest),
        Cells = [R-C|Rest]
    ).

% ry_los_cells(+Grid, +R1, +C1, +R2, +C2, -Cells): cells strictly between
% (R1,C1) and (R2,C2) on the same line. The two points must share a row,
% column, diagonal (C-R constant), or anti-diagonal (R+C constant).
% Endpoints are excluded. Grid is used only for type safety; not accessed.
ry_los_cells(_, R1, C1, R2, C2, Cells) :-
    (R1 =:= R2 ->
% Horizontal: vary columns between C1 and C2.
        Lo is min(C1, C2) + 1, Hi is max(C1, C2) - 1,
        (Lo =< Hi ->
            numlist(Lo, Hi, Cols),
            maplist([C, RC]>>(RC = R1-C), Cols, Cells)
        ;
            Cells = []
        )
    ; C1 =:= C2 ->
% Vertical: vary rows between R1 and R2.
        Lo is min(R1, R2) + 1, Hi is max(R1, R2) - 1,
        (Lo =< Hi ->
            numlist(Lo, Hi, Rows),
            maplist([R, RC]>>(RC = R-C1), Rows, Cells)
        ;
            Cells = []
        )
    ;
% Diagonal or anti-diagonal: walk from just past (R1,C1) to just before (R2,C2).
        DR is sign(R2 - R1), DC is sign(C2 - C1),
        R1s is R1 + DR, C1s is C1 + DC,
        R2s is R2 - DR, C2s is C2 - DC,
        (R1s =:= R2 + DR ->
% Adjacent cells: no interior.
            Cells = []
        ;
            ry_diag_walk_(R1s, C1s, R2s, C2s, DR, DC, Cells)
        )
    ).

% ry_los(+Grid, +R1, +C1, +R2, +C2, +Bg): succeed if all cells strictly between
% (R1,C1) and (R2,C2) on the same line have value Bg (line of sight is clear).
ry_los(Grid, R1, C1, R2, C2, Bg) :-
    ry_los_cells(Grid, R1, C1, R2, C2, Cells),
    forall(member(Cell, Cells), (ry_cell_val_(Grid, Cell, Val), Val == Bg)).

% ry_cast_one_: cast one ray and unify Dir with the result pair.
ry_cast_one_(Grid, R, C, DR, DC, Bg, Dir, Dir-Result) :-
    (ry_first_hit(Grid, R, C, DR, DC, Bg, Hit) ->
% Obstacle found: record the hit cell.
        Result = Hit
    ;
% No obstacle: direction is clear to boundary.
        Result = none
    ).

% ry_cast_all_4(+Grid, +R, +C, +Bg, -Hits): cast rays in all 4 compass
% directions from (R,C). Hits is [up-Ru, down-Rd, left-Rl, right-Rr] where
% each Result is a R-C cell pair if an obstacle was found or the atom 'none'.
ry_cast_all_4(Grid, R, C, Bg, Hits) :-
% Cast upward (-1,0).
    ry_cast_one_(Grid, R, C, -1, 0, Bg, up, H1),
% Cast downward (1,0).
    ry_cast_one_(Grid, R, C,  1, 0, Bg, down, H2),
% Cast leftward (0,-1).
    ry_cast_one_(Grid, R, C,  0,-1, Bg, left, H3),
% Cast rightward (0,1).
    ry_cast_one_(Grid, R, C,  0, 1, Bg, right, H4),
% Combine all four results.
    Hits = [H1, H2, H3, H4].
