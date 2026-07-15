% ray.pl - Layer 103: Ray Casting and Line-of-Sight Operations (ry_* prefix).
% Provides directional ray traversal, obstacle detection, line-of-sight tests,
% distance-to-edge and distance-to-obstacle queries, direction reflection,
% and multi-direction casting in 2D integer-coordinate grids.
:- module(ray, [
    ray_in_bounds/3,
    ray_cells_in_dir/6,
    ray_first_hit/7,
    ray_cast_clear/7,
    ray_distance_to_hit/7,
    ray_distance_to_edge/6,
    ray_is_clear/6,
    ray_project/8,
    ray_dir_to_delta/3,
    ray_reflect_h/4,
    ray_reflect_v/4,
    ray_los/6,
    ray_los_cells/6,
    ray_cast_all_4/5
]).
% Import list utilities for range generation and element lookup.
:- use_module(library(lists), [nth0/3, numlist/3, member/2]).
% Import higher-order utilities for mapping.
:- use_module(library(apply), [maplist/3]).

% ray_dims_: extract row and column count from a grid.
ray_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Get column count from first row when grid is non-empty.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% ray_in_bounds(+Grid, +R, +C): succeed if (R,C) is within the grid bounds.
ray_in_bounds(Grid, R, C) :-
% Get grid dimensions.
    ray_dims_(Grid, NR, NC),
% Test row and column bounds (0-based, inclusive).
    0 =< R, R < NR,
    0 =< C, C < NC.

% ray_cells_in_dir_: helper to enumerate cells stepping from (R,C) in direction.
ray_cells_in_dir_(R, C, DR, DC, NR, NC, Cells) :-
    (0 =< R, R < NR, 0 =< C, C < NC ->
% Cell is in bounds: include it and step to the next.
        Cells = [R-C|Rest],
        R1 is R + DR, C1 is C + DC,
        ray_cells_in_dir_(R1, C1, DR, DC, NR, NC, Rest)
    ;
% Cell is out of bounds: terminate the ray.
        Cells = []
    ).

% ray_cells_in_dir(+Grid, +R, +C, +DR, +DC, -Cells): all in-bounds cells stepping
% from (R+DR, C+DC) in direction (DR,DC) until leaving the grid. The starting
% cell (R,C) is NOT included.
ray_cells_in_dir(Grid, R, C, DR, DC, Cells) :-
% Get grid dimensions for bounds checking.
    ray_dims_(Grid, NR, NC),
% Start one step beyond the origin.
    R1 is R + DR, C1 is C + DC,
% Walk until out of bounds.
    ray_cells_in_dir_(R1, C1, DR, DC, NR, NC, Cells).

% ray_cell_val_: retrieve value at a cell coordinate.
ray_cell_val_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% ray_first_hit_(: find the first non-Bg cell in a list.
ray_first_hit_([], _, _, _) :- fail.
ray_first_hit_([Cell|Rest], Grid, Bg, Hit) :-
    ray_cell_val_(Grid, Cell, Val),
    (Val \== Bg ->
% This cell is the obstacle.
        Hit = Cell
    ;
% Continue searching.
        ray_first_hit_(Rest, Grid, Bg, Hit)
    ).

% ray_first_hit(+Grid, +R, +C, +DR, +DC, +Bg, -Hit): first cell in direction
% (DR,DC) from (R,C) with a value different from Bg. Fails if no such cell.
ray_first_hit(Grid, R, C, DR, DC, Bg, Hit) :-
    ray_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ray_first_hit_(Cells, Grid, Bg, Hit).

% ray_take_while_bg_: collect cells while they are the background color.
ray_take_while_bg_([], _, _, []) :- !.
ray_take_while_bg_([Cell|Rest], Grid, Bg, Result) :-
    ray_cell_val_(Grid, Cell, Val),
    (Val == Bg ->
% Cell is background; include it and continue.
        Result = [Cell|RestResult],
        ray_take_while_bg_(Rest, Grid, Bg, RestResult)
    ;
% Cell is an obstacle; stop here.
        Result = []
    ).

% ray_cast_clear(+Grid, +R, +C, +DR, +DC, +Bg, -Clear): cells in direction
% (DR,DC) that have value Bg, stopping before the first non-Bg cell.
% Clear does NOT include the obstacle cell.
ray_cast_clear(Grid, R, C, DR, DC, Bg, Clear) :-
    ray_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ray_take_while_bg_(Cells, Grid, Bg, Clear).

% ray_dist_hit_: count steps to the first non-Bg cell.
ray_dist_hit_([], _, _, _, _) :- fail.
ray_dist_hit_([Cell|Rest], Grid, Bg, N, D) :-
    ray_cell_val_(Grid, Cell, Val),
    (Val \== Bg ->
% Found the obstacle at step N.
        D = N
    ;
% Continue counting.
        N1 is N + 1,
        ray_dist_hit_(Rest, Grid, Bg, N1, D)
    ).

% ray_distance_to_hit(+Grid, +R, +C, +DR, +DC, +Bg, -D): number of steps from
% (R,C) to the first non-Bg cell in direction (DR,DC). Fails if no obstacle.
ray_distance_to_hit(Grid, R, C, DR, DC, Bg, D) :-
    ray_cells_in_dir(Grid, R, C, DR, DC, Cells),
    ray_dist_hit_(Cells, Grid, Bg, 1, D).

% ray_distance_to_edge(+Grid, +R, +C, +DR, +DC, -D): number of steps from (R,C)
% to the last in-bounds cell in direction (DR,DC). Returns 0 if the next cell
% is already out of bounds.
ray_distance_to_edge(Grid, R, C, DR, DC, D) :-
    ray_cells_in_dir(Grid, R, C, DR, DC, Cells),
    length(Cells, D).

% ray_is_clear(+Grid, +R, +C, +DR, +DC, +Bg): succeed if all cells in direction
% (DR,DC) from (R,C) until the grid boundary have value Bg.
ray_is_clear(Grid, R, C, DR, DC, Bg) :-
    ray_cells_in_dir(Grid, R, C, DR, DC, Cells),
    forall(member(Cell, Cells), (ray_cell_val_(Grid, Cell, Val), Val == Bg)).

% ray_project(+Grid, +R, +C, +DR, +DC, +N, -NewR, -NewC): cell N steps from
% (R,C) in direction (DR,DC). Fails if the result is out of grid bounds.
ray_project(Grid, R, C, DR, DC, N, NewR, NewC) :-
% Compute the new coordinates.
    NewR is R + DR * N,
    NewC is C + DC * N,
% Verify the result is within bounds.
    ray_in_bounds(Grid, NewR, NewC).

% ray_dir_to_delta(+Dir, -DR, -DC): map a named direction atom to a unit step.
% Named directions: up, down, left, right, ul, ur, dl, dr.
ray_dir_to_delta(Dir, DR, DC) :-
    (Dir = up    -> DR = -1, DC =  0
    ; Dir = down  -> DR =  1, DC =  0
    ; Dir = left  -> DR =  0, DC = -1
    ; Dir = right -> DR =  0, DC =  1
    ; Dir = ul    -> DR = -1, DC = -1
    ; Dir = ur    -> DR = -1, DC =  1
    ; Dir = dl    -> DR =  1, DC = -1
    ; Dir = dr    -> DR =  1, DC =  1
    ).

% ray_reflect_h(+DR, +DC, -RDR, -RDC): reflect a direction across a horizontal axis.
% The row component negates; the column component is unchanged.
ray_reflect_h(DR, DC, RDR, DC) :-
    RDR is -DR.

% ray_reflect_v(+DR, +DC, -RDR, -RDC): reflect a direction across a vertical axis.
% The column component negates; the row component is unchanged.
ray_reflect_v(DR, DC, DR, RDC) :-
    RDC is -DC.

% ray_diag_walk_: enumerate cells along a 45-degree walk from (R,C) to (R2,C2).
ray_diag_walk_(R, C, R2, C2, DR, DC, Cells) :-
    (R =:= R2, C =:= C2 ->
% Reached endpoint: include it.
        Cells = [R-C]
    ;
% Step and continue.
        R1 is R + DR, C1 is C + DC,
        ray_diag_walk_(R1, C1, R2, C2, DR, DC, Rest),
        Cells = [R-C|Rest]
    ).

% ray_los_cells(+Grid, +R1, +C1, +R2, +C2, -Cells): cells strictly between
% (R1,C1) and (R2,C2) on the same line. The two points must share a row,
% column, diagonal (C-R constant), or anti-diagonal (R+C constant).
% Endpoints are excluded. Grid is used only for type safety; not accessed.
ray_los_cells(_, R1, C1, R2, C2, Cells) :-
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
            ray_diag_walk_(R1s, C1s, R2s, C2s, DR, DC, Cells)
        )
    ).

% ray_los(+Grid, +R1, +C1, +R2, +C2, +Bg): succeed if all cells strictly between
% (R1,C1) and (R2,C2) on the same line have value Bg (line of sight is clear).
ray_los(Grid, R1, C1, R2, C2, Bg) :-
    ray_los_cells(Grid, R1, C1, R2, C2, Cells),
    forall(member(Cell, Cells), (ray_cell_val_(Grid, Cell, Val), Val == Bg)).

% ray_cast_one_: cast one ray and unify Dir with the result pair.
ray_cast_one_(Grid, R, C, DR, DC, Bg, Dir, Dir-Result) :-
    (ray_first_hit(Grid, R, C, DR, DC, Bg, Hit) ->
% Obstacle found: record the hit cell.
        Result = Hit
    ;
% No obstacle: direction is clear to boundary.
        Result = none
    ).

% ray_cast_all_4(+Grid, +R, +C, +Bg, -Hits): cast rays in all 4 compass
% directions from (R,C). Hits is [up-Ru, down-Rd, left-Rl, right-Rr] where
% each Result is a R-C cell pair if an obstacle was found or the atom 'none'.
ray_cast_all_4(Grid, R, C, Bg, Hits) :-
% Cast upward (-1,0).
    ray_cast_one_(Grid, R, C, -1, 0, Bg, up, H1),
% Cast downward (1,0).
    ray_cast_one_(Grid, R, C,  1, 0, Bg, down, H2),
% Cast leftward (0,-1).
    ray_cast_one_(Grid, R, C,  0,-1, Bg, left, H3),
% Cast rightward (0,1).
    ray_cast_one_(Grid, R, C,  0, 1, Bg, right, H4),
% Combine all four results.
    Hits = [H1, H2, H3, H4].
