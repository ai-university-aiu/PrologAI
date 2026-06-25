% step.pl - Layer 86: Directional Grid Movement (st_* prefix).
% Provides 8-directional stepping, ray casting, direction arithmetic,
% path following, and edge-reaching utilities for grid navigation.
:- module(step, [
    st_step/3,
    st_step_in/4,
    st_ray/4,
    st_ray_to/5,
    st_walk/4,
    st_dirs4/1,
    st_dirs8/1,
    st_rotate_cw/2,
    st_rotate_ccw/2,
    st_opposite/2,
    st_normalize/3,
    st_path/3,
    st_first/5,
    st_to_edge/4
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, reverse/2]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3]).

% st_dims_(+Grid, -NR, -NC): measure grid row and column counts.
st_dims_(Grid, NR, NC) :-
    % Count rows.
    length(Grid, NR),
    % Count columns from first row; 0 for empty grid.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% st_step(+R-C, +DR-DC, -R2-C2): take one step in direction (DR,DC).
% R2 = R + DR, C2 = C + DC. No bounds checking.
st_step(R-C, DR-DC, R2-C2) :-
    % Compute new position without bounds checking.
    R2 is R + DR,
    C2 is C + DC.

% st_step_in(+Grid, +R-C, +DR-DC, -R2-C2): one step that stays in bounds.
% Fails if the result position is outside Grid.
st_step_in(Grid, R-C, DR-DC, R2-C2) :-
    % Compute new position.
    R2 is R + DR, C2 is C + DC,
    % Get grid bounds.
    st_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    % Fail if out of bounds.
    between(0, NR1, R2), between(0, NC1, C2).

% st_ray(+Grid, +R-C, +DR-DC, -Cells): all in-bounds cells in direction (DR,DC).
% Cells does not include the start (R,C). Order is nearest to farthest.
st_ray(Grid, R-C, DR-DC, Cells) :-
    % Get grid bounds.
    st_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    DR-DC = DR0-DC0,
    % Collect cells by advancing one step at a time until out of bounds.
    st_ray_acc_(R-C, DR0-DC0, NR1, NC1, [], RevCells),
    reverse(RevCells, Cells).

% st_ray_acc_(+Cur, +Dir, +MaxR, +MaxC, +Acc, -RevCells): ray accumulator.
st_ray_acc_(R-C, DR-DC, MaxR, MaxC, Acc, Out) :-
    % Compute next position.
    R2 is R + DR, C2 is C + DC,
    % Stop if out of bounds.
    (   between(0, MaxR, R2), between(0, MaxC, C2)
    ->  st_ray_acc_(R2-C2, DR-DC, MaxR, MaxC, [R2-C2|Acc], Out)
    ;   Out = Acc
    ).

% st_ray_to(+Grid, +R-C, +DR-DC, +StopV, -Cells): ray until value StopV is seen.
% Cells includes positions up to but not including the first cell with value StopV.
% Does not include the start (R,C).
st_ray_to(Grid, R-C, DR-DC, StopV, Cells) :-
    % Get grid bounds.
    st_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    DR-DC = DR0-DC0,
    % Collect cells, stopping before StopV.
    st_ray_to_acc_(R-C, DR0-DC0, Grid, NR1, NC1, StopV, [], RevCells),
    reverse(RevCells, Cells).

% st_ray_to_acc_: accumulator for st_ray_to.
st_ray_to_acc_(R-C, DR-DC, Grid, MaxR, MaxC, StopV, Acc, Out) :-
    % Compute next position.
    R2 is R + DR, C2 is C + DC,
    % Stop at boundary or when StopV is found.
    (   between(0, MaxR, R2), between(0, MaxC, C2)
    ->  nth0(R2, Grid, Row2), nth0(C2, Row2, V2),
        (V2 == StopV ->
            Out = Acc
        ;
            st_ray_to_acc_(R2-C2, DR-DC, Grid, MaxR, MaxC, StopV, [R2-C2|Acc], Out)
        )
    ;   Out = Acc
    ).

% st_walk(+Grid, +R-C, +DR-DC, -Cells): all in-bounds cells starting at (R,C).
% Cells includes the start position. Order is nearest to farthest.
st_walk(Grid, R-C, DR-DC, Cells) :-
    % Collect the ray (not including start).
    st_ray(Grid, R-C, DR-DC, Ray),
    % Prepend the start position.
    Cells = [R-C|Ray].

% st_dirs4(-Dirs): the four cardinal directions as DR-DC pairs.
% Up, down, left, right in 4-connected grids.
st_dirs4(Dirs) :-
    % Cardinal directions: up, down, left, right.
    Dirs = [(-1)-0, 1-0, 0-(-1), 0-1].

% st_dirs8(-Dirs): the eight principal directions as DR-DC pairs.
% Includes the four cardinals plus four diagonals.
st_dirs8(Dirs) :-
    % Cardinals and diagonals.
    Dirs = [(-1)-0, 1-0, 0-(-1), 0-1, (-1)-(-1), (-1)-1, 1-(-1), 1-1].

% st_rotate_cw(+DR-DC, -DR2-DC2): rotate direction 90 degrees clockwise.
% Up->Right, Right->Down, Down->Left, Left->Up. Also works for diagonals.
st_rotate_cw(DR-DC, DR2-DC2) :-
    % Clockwise rotation: (DR,DC) -> (DC,-DR).
    DR2 is DC, DC2 is -DR.

% st_rotate_ccw(+DR-DC, -DR2-DC2): rotate direction 90 degrees counter-clockwise.
% Up->Left, Left->Down, Down->Right, Right->Up.
st_rotate_ccw(DR-DC, DR2-DC2) :-
    % Counter-clockwise rotation: (DR,DC) -> (-DC,DR).
    DR2 is -DC, DC2 is DR.

% st_opposite(+DR-DC, -DR2-DC2): reverse a direction.
% Up->Down, Left->Right, and so on.
st_opposite(DR-DC, DR2-DC2) :-
    % Negate both components.
    DR2 is -DR, DC2 is -DC.

% st_normalize(+R-C, +R2-C2, -DR-DC): compute unit step direction.
% DR is sign(R2-R), DC is sign(C2-C). Returns (-1), 0, or 1 per component.
st_normalize(R-C, R2-C2, DR-DC) :-
    % Compute row sign.
    DRRaw is R2 - R,
    (DRRaw > 0 -> DR = 1 ; DRRaw < 0 -> DR = -1 ; DR = 0),
    % Compute column sign.
    DCRaw is C2 - C,
    (DCRaw > 0 -> DC = 1 ; DCRaw < 0 -> DC = -1 ; DC = 0).

% st_path(+R-C, +Dirs, -Cells): follow a list of DR-DC directions from R-C.
% Cells includes R-C and every position reached by successive steps.
st_path(Start, Dirs, Cells) :-
    % Accumulate positions by following each direction in sequence.
    st_path_acc_(Start, Dirs, [Start], RevCells),
    reverse(RevCells, Cells).

% st_path_acc_: accumulator for st_path.
% Cut prevents choicepoint when direction list is empty.
st_path_acc_(_, [], Acc, Acc) :- !.
st_path_acc_(R-C, [DR-DC|RestDirs], Acc, Out) :-
    % Advance one step.
    R2 is R + DR, C2 is C + DC,
    % Continue from new position.
    st_path_acc_(R2-C2, RestDirs, [R2-C2|Acc], Out).

% st_first(+Grid, +R-C, +DR-DC, +V, -R2-C2): first cell with value V in direction.
% Fails if no cell with value V is found before the grid boundary.
st_first(Grid, R-C, DR-DC, V, R2-C2) :-
    % Get grid bounds.
    st_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    % Search step by step in direction.
    st_first_acc_(R-C, DR-DC, Grid, NR1, NC1, V, R2-C2).

% st_first_acc_: step-by-step search for st_first.
st_first_acc_(R-C, DR-DC, Grid, MaxR, MaxC, V, Found) :-
    % Advance one step.
    R2 is R + DR, C2 is C + DC,
    % Fail if out of bounds.
    between(0, MaxR, R2), between(0, MaxC, C2),
    % Check the cell value.
    nth0(R2, Grid, Row2), nth0(C2, Row2, V2),
    (V2 == V ->
        Found = R2-C2
    ;
        st_first_acc_(R2-C2, DR-DC, Grid, MaxR, MaxC, V, Found)
    ).

% st_to_edge(+Grid, +R-C, +DR-DC, -Steps): count steps until grid boundary.
% Steps is the number of steps that can be taken before going out of bounds.
% For a cell already on the edge in the given direction, Steps = 0.
st_to_edge(Grid, R-C, DR-DC, Steps) :-
    % Get grid bounds.
    st_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    % Count steps until the next position would be out of bounds.
    st_to_edge_acc_(R-C, DR-DC, NR1, NC1, 0, Steps).

% st_to_edge_acc_: counter for st_to_edge.
st_to_edge_acc_(R-C, DR-DC, MaxR, MaxC, Acc, Steps) :-
    % Try the next step.
    R2 is R + DR, C2 is C + DC,
    (   between(0, MaxR, R2), between(0, MaxC, C2)
    ->  Acc1 is Acc + 1,
        st_to_edge_acc_(R2-C2, DR-DC, MaxR, MaxC, Acc1, Steps)
    ;   Steps = Acc
    ).
