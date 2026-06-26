% warp.pl - Layer 145: Shear, Cyclic Shift, and Non-Uniform Grid Warping (wr_* prefix).
% Provides predicates for linearly shifting individual rows or columns, applying
% shear transformations (row I shifts right by I*Step), undoing shears, cyclically
% shifting rows or columns with wrap-around (toroidal), applying per-row arbitrary
% offsets, computing the anti-diagonal transpose, and finding the shear step that
% maps one grid to another. These predicates support visual reasoning tasks where
% objects or entire grids undergo progressive, non-uniform, or wrapping shifts.
%
% Shear conventions (all shifts measured rightward or downward; negative = reverse):
%   wr_shear_h: row I shifts right by I*Step; row 0 unchanged.
%   wr_shear_v: column J shifts down by J*Step; column 0 unchanged.
%   wr_unshear_h: row I shifts left by I*Step (inverse of shear_h).
%   wr_cyclic_*: wrap-around (toroidal); no fill color needed.
%   wr_transpose_anti: Out[W-1-C][H-1-R] = Grid[R][C]; anti-diagonal transpose.
:- module(warp, [
    % wr_shift_row/5: shift single row R right by N cells; fill vacated cells with Bg.
    wr_shift_row/5,
    % wr_shift_col/5: shift single column C down by N cells; fill vacated cells with Bg.
    wr_shift_col/5,
    % wr_shear_h/4: horizontal shear: row I shifts right by I*Step; fill with Bg.
    wr_shear_h/4,
    % wr_shear_v/4: vertical shear: column J shifts down by J*Step; fill with Bg.
    wr_shear_v/4,
    % wr_unshear_h/4: undo horizontal shear: row I shifts left by I*Step.
    wr_unshear_h/4,
    % wr_unshear_v/4: undo vertical shear: column J shifts up by J*Step.
    wr_unshear_v/4,
    % wr_cyclic_h/3: cyclically shift all rows right by N (toroidal, no fill).
    wr_cyclic_h/3,
    % wr_cyclic_v/3: cyclically shift all columns down by N (toroidal, no fill).
    wr_cyclic_v/3,
    % wr_cyclic_shear_h/3: cyclic shear: row I wraps right by I*Step.
    wr_cyclic_shear_h/3,
    % wr_cyclic_shear_v/3: cyclic shear: column J wraps down by J*Step.
    wr_cyclic_shear_v/3,
    % wr_skew_offsets/4: per-row offsets: row I shifts right by Offsets[I]; fill with Bg.
    wr_skew_offsets/4,
    % wr_transpose_anti/2: anti-diagonal transpose: Out[W-1-C][H-1-R] = Grid[R][C].
    wr_transpose_anti/2,
    % wr_find_shear_h/4: find Step such that wr_shear_h(GridA, Step, Bg) = GridB.
    wr_find_shear_h/4,
    % wr_find_shear_v/4: find Step such that wr_shear_v(GridA, Step, Bg) = GridB.
    wr_find_shear_v/4
]).

% Import list utilities for indexing, enumeration, and column operations.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/2, reverse/2]).
% Import higher-order utilities (retained for future callers combining this module).
:- use_module(library(apply), [maplist/2, maplist/3]).

% wr_dims_(+Grid, -H, -W): get the row count H and column count W of a grid.
wr_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Extract column count from the first row; 0 if grid is empty.
    ( H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0 ).

% wr_shift_linear_(+Row, +N, +Bg, -Out): shift row right by N (N may be negative).
% Positive N: content moves right; Bg fills the left. Negative N: content moves left.
% Formula: Out[C] = Row[C - N] if 0 <= C-N < W, else Bg.
wr_shift_linear_(Row, N, Bg, Out) :-
% Get row width.
    length(Row, W),
% W-1 is the max column index.
    W1 is W - 1,
% Build each output cell from the shifted source position.
    findall(V, (
        between(0, W1, C),
        Src is C - N,
        ( Src >= 0, Src < W ->
            nth0(Src, Row, V)
        ;
            V = Bg
        )
    ), Out).

% wr_replace_nth_(+I, +List, +V, -NewList): replace element at index I with V.
wr_replace_nth_(0, [_|T], V, [V|T]) :- !.
% Recurse to index I; I must be positive.
wr_replace_nth_(I, [H|T], V, [H|T2]) :-
    I > 0,
    I1 is I - 1,
    wr_replace_nth_(I1, T, V, T2).

% wr_get_col_(+Grid, +C, -ColVals): extract column C as a top-to-bottom list.
wr_get_col_(Grid, C, ColVals) :-
% Collect value at column C from each row.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals).

% wr_put_col_(+Grid, +C, +ColVals, -Out): replace column C in Grid with ColVals.
wr_put_col_([], _, [], []).
% Replace the C-th element of each row with the corresponding ColVals entry.
wr_put_col_([Row|RestRows], C, [V|RestVals], [NewRow|RestOut]) :-
    wr_replace_nth_(C, Row, V, NewRow),
    wr_put_col_(RestRows, C, RestVals, RestOut).

% wr_cyclic_row_(+Row, +N, -Out): cyclically shift Row right by N (toroidal).
% Out[C] = Row[(C - N) mod W]. SWI-Prolog mod handles negative N correctly.
wr_cyclic_row_(Row, N, Out) :-
% Get row width.
    length(Row, W),
% W-1 is the max column index.
    W1 is W - 1,
% Build each output cell from the cyclic source position.
    findall(V, (
        between(0, W1, C),
        Src is (C - N) mod W,
        nth0(Src, Row, V)
    ), Out).

% wr_shift_row(+Grid, +R, +N, +Bg, -Out): shift row R right by N cells; fill with Bg.
% All other rows are unchanged. N may be negative (shift left).
wr_shift_row(Grid, R, N, Bg, Out) :-
% Get grid height.
    length(Grid, H),
% H-1 is the max row index.
    H1 is H - 1,
% Build each output row: shift row R, pass through all others.
    findall(NewRow, (
        between(0, H1, I),
        nth0(I, Grid, Row),
        ( I =:= R ->
            wr_shift_linear_(Row, N, Bg, NewRow)
        ;
            NewRow = Row
        )
    ), Out).

% wr_shift_col(+Grid, +C, +N, +Bg, -Out): shift column C down by N cells; fill with Bg.
% All other columns are unchanged. N may be negative (shift up).
wr_shift_col(Grid, C, N, Bg, Out) :-
% Extract column C as a list of values.
    wr_get_col_(Grid, C, ColVals),
% Shift the column values downward by N using the linear shift.
    wr_shift_linear_(ColVals, N, Bg, ShiftedCol),
% Put the shifted column back into the grid.
    wr_put_col_(Grid, C, ShiftedCol, Out).

% wr_shear_h(+Grid, +Step, +Bg, -Out): horizontal shear; row I shifts right by I*Step.
% Row 0 is unchanged. Vacated cells are filled with Bg.
% Step > 0: content shifts rightward with increasing row index.
% Step < 0: content shifts leftward with increasing row index.
wr_shear_h(Grid, Step, Bg, Out) :-
% Build each output row by applying the per-row shift.
    findall(NewRow, (
        nth0(I, Grid, Row),
        Shift is I * Step,
        wr_shift_linear_(Row, Shift, Bg, NewRow)
    ), Out).

% wr_shear_v(+Grid, +Step, +Bg, -Out): vertical shear; column J shifts down by J*Step.
% Column 0 is unchanged. Vacated cells are filled with Bg.
% Formula: Out[R][J] = Grid[R - J*Step][J] if in bounds, else Bg.
wr_shear_v(Grid, Step, Bg, Out) :-
% Get grid dimensions.
    wr_dims_(Grid, H, W),
% H-1 and W-1 are the max indices.
    H1 is H - 1,
    W1 is W - 1,
% Build each output cell row by row using the vertical shear formula.
    findall(NewRow, (
        between(0, H1, R),
        findall(V, (
            between(0, W1, J),
            Src is R - J * Step,
            ( Src >= 0, Src < H ->
                nth0(Src, Grid, GRow),
                nth0(J, GRow, V)
            ;
                V = Bg
            )
        ), NewRow)
    ), Out).

% wr_unshear_h(+Grid, +Step, +Bg, -Out): undo horizontal shear; row I shifts left by I*Step.
% Equivalent to wr_shear_h with -Step. Inverse of wr_shear_h when no content was lost.
wr_unshear_h(Grid, Step, Bg, Out) :-
% Negate Step to reverse the shear direction.
    NegStep is -Step,
    wr_shear_h(Grid, NegStep, Bg, Out).

% wr_unshear_v(+Grid, +Step, +Bg, -Out): undo vertical shear; column J shifts up by J*Step.
% Equivalent to wr_shear_v with -Step. Inverse of wr_shear_v when no content was lost.
wr_unshear_v(Grid, Step, Bg, Out) :-
% Negate Step to reverse the shear direction.
    NegStep is -Step,
    wr_shear_v(Grid, NegStep, Bg, Out).

% wr_cyclic_h(+Grid, +N, -Out): cyclically shift all rows right by N (toroidal).
% No fill: values wrap around to the other side of each row.
wr_cyclic_h(Grid, N, Out) :-
% Apply cyclic row shift to every row; collect results into Out.
    findall(NewRow, (member(Row, Grid), wr_cyclic_row_(Row, N, NewRow)), Out).

% wr_cyclic_v(+Grid, +N, -Out): cyclically shift all columns down by N (toroidal).
% No fill: values wrap around to the top of each column.
% Formula: Out[R][C] = Grid[(R - N) mod H][C].
wr_cyclic_v(Grid, N, Out) :-
% Get grid dimensions.
    wr_dims_(Grid, H, W),
% H-1 and W-1 are the max indices.
    H1 is H - 1,
    W1 is W - 1,
% Build each output row using the cyclic column shift formula.
    findall(NewRow, (
        between(0, H1, R),
        findall(V, (
            between(0, W1, C),
            SrcR is (R - N) mod H,
            nth0(SrcR, Grid, GRow),
            nth0(C, GRow, V)
        ), NewRow)
    ), Out).

% wr_cyclic_shear_h(+Grid, +Step, -Out): cyclic shear; row I wraps right by I*Step.
% Like wr_shear_h but with toroidal wrap-around; no fill color needed.
wr_cyclic_shear_h(Grid, Step, Out) :-
% Build each output row by applying a per-row cyclic shift.
    findall(NewRow, (
        nth0(I, Grid, Row),
        Shift is I * Step,
        wr_cyclic_row_(Row, Shift, NewRow)
    ), Out).

% wr_cyclic_shear_v(+Grid, +Step, -Out): cyclic shear; column J wraps down by J*Step.
% Like wr_shear_v but with toroidal wrap-around; no fill color needed.
% Formula: Out[R][J] = Grid[(R - J*Step) mod H][J].
wr_cyclic_shear_v(Grid, Step, Out) :-
% Get grid dimensions.
    wr_dims_(Grid, H, W),
% H-1 and W-1 are the max indices.
    H1 is H - 1,
    W1 is W - 1,
% Build each output cell using the cyclic vertical shear formula.
    findall(NewRow, (
        between(0, H1, R),
        findall(V, (
            between(0, W1, J),
            SrcR is (R - J * Step) mod H,
            nth0(SrcR, Grid, GRow),
            nth0(J, GRow, V)
        ), NewRow)
    ), Out).

% wr_skew_offsets(+Grid, +Offsets, +Bg, -Out): per-row arbitrary offsets.
% Row I shifts right by Offsets[I]; vacated cells are filled with Bg.
% Offsets must have the same length as Grid.
% wr_shear_h(Grid, Step, Bg, Out) equals wr_skew_offsets with Offsets=[0,Step,2*Step,...].
wr_skew_offsets(Grid, Offsets, Bg, Out) :-
% Build each output row by shifting it by the corresponding offset.
    findall(NewRow, (
        nth0(I, Grid, Row),
        nth0(I, Offsets, Shift),
        wr_shift_linear_(Row, Shift, Bg, NewRow)
    ), Out).

% wr_transpose_anti(+Grid, -Out): anti-diagonal transpose.
% Maps (R, C) to (W-1-C, H-1-R). Out has W rows and H columns.
% Formula: Out[J][I] = Grid[H-1-I][W-1-J] where J in 0..W-1, I in 0..H-1.
% For square grids, applying this twice returns the original grid.
wr_transpose_anti(Grid, Out) :-
% Get original dimensions.
    wr_dims_(Grid, H, W),
% Max indices for the original grid.
    H1 is H - 1,
    W1 is W - 1,
% Build each row of Out (one per original column J).
    findall(NewRow, (
        between(0, W1, J),
        findall(V, (
            between(0, H1, I),
            R is H1 - I,
            C is W1 - J,
            nth0(R, Grid, GRow),
            nth0(C, GRow, V)
        ), NewRow)
    ), Out).

% wr_find_shear_h(+GridA, +GridB, +Bg, -Step): find Step such that shear_h(A,Step,Bg)=B.
% Searches Step in -(W-1)..(W-1) and returns the first match. Fails if none found.
wr_find_shear_h(GridA, GridB, Bg, Step) :-
% Get grid width to set search bounds.
    wr_dims_(GridA, _, W),
% Compute the maximum step magnitude; search from -Max to +Max.
    Max is W - 1,
    MaxK is 2 * Max,
% Try each candidate step value in order from -Max to +Max.
    between(0, MaxK, K),
    Step is K - Max,
% Apply the horizontal shear with this step.
    wr_shear_h(GridA, Step, Bg, Candidate),
% Check if the result equals GridB.
    Candidate == GridB,
% Cut to return the first match.
    !.

% wr_find_shear_v(+GridA, +GridB, +Bg, -Step): find Step such that shear_v(A,Step,Bg)=B.
% Searches Step in -(H-1)..(H-1) and returns the first match. Fails if none found.
wr_find_shear_v(GridA, GridB, Bg, Step) :-
% Get grid height to set search bounds.
    wr_dims_(GridA, H, _),
% Compute the maximum step magnitude; search from -Max to +Max.
    Max is H - 1,
    MaxK is 2 * Max,
% Try each candidate step value in order from -Max to +Max.
    between(0, MaxK, K),
    Step is K - Max,
% Apply the vertical shear with this step.
    wr_shear_v(GridA, Step, Bg, Candidate),
% Check if the result equals GridB.
    Candidate == GridB,
% Cut to return the first match.
    !.
