% line.pl - Layer 100: Straight-Line Segment Detection and Drawing Operations (li_* prefix).
% Provides cells on horizontal, vertical, and 45-degree diagonal segments;
% line drawing in 2D grids; collinearity tests; and endpoint/gap queries.
:- module(line, [
    line_hline/4,
    line_vline/4,
    line_diag_seg/5,
    line_draw_h/6,
    line_draw_v/6,
    line_draw_diag/7,
    line_same_row/4,
    line_same_col/4,
    line_same_diag/4,
    line_same_anti/4,
    line_collinear/6,
    line_endpoints/3,
    line_gap/5,
    line_line_type/5
]).
% Import list utilities for indexing and range generation.
:- use_module(library(lists), [nth0/3, numlist/3, append/2]).
% Import higher-order utilities for cell extraction.
:- use_module(library(apply), [maplist/2, maplist/3]).

% line_dims_: extract row and column count from a grid.
line_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Count columns from the first row.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% line_cell_at_: get value at row R, column C (0-based).
line_cell_at_(Grid, R, C, V) :-
% Retrieve row R.
    nth0(R, Grid, Row),
% Retrieve column C.
    nth0(C, Row, V).

% line_replace_nth_: replace element at index N in a list with V. Cut on base.
line_replace_nth_(0, [_|T], V, [V|T]) :- !.
line_replace_nth_(N, [H|T], V, [H|T2]) :-
    N1 is N - 1,
    line_replace_nth_(N1, T, V, T2).

% line_set_cell_: return Grid with cell (R,C) set to V.
line_set_cell_(Grid, R, C, V, Result) :-
% Get the row; cut to avoid backtracking.
    nth0(R, Grid, OldRow), !,
    line_replace_nth_(C, OldRow, V, NewRow),
    line_replace_nth_(R, Grid, NewRow, Result).

% line_fill_cells_: fill a list of R-C pairs with Color. If-then-else for determinism.
line_fill_cells_(Grid, Cells, Color, Result) :-
    (Cells = [] ->
% No more cells to fill.
        Result = Grid
    ;
        Cells = [R-C|Rest],
% Set the current cell and continue.
        line_set_cell_(Grid, R, C, Color, G2),
        line_fill_cells_(G2, Rest, Color, Result)
    ).

% line_hline(+R, +C1, +C2, -Cells): cells on the horizontal segment from (R,C1) to (R,C2).
% Cells are R-C pairs in order from min(C1,C2) to max(C1,C2).
line_hline(R, C1, C2, Cells) :-
% Determine left and right endpoints.
    Lo is min(C1, C2), Hi is max(C1, C2),
% Generate all column indices in this range.
    numlist(Lo, Hi, Cols),
% Build R-C pairs; unify RC to R-C deterministically.
    maplist([C, RC]>>(RC = R-C), Cols, Cells).

% line_vline(+C, +R1, +R2, -Cells): cells on the vertical segment from (R1,C) to (R2,C).
% Cells are R-C pairs in order from min(R1,R2) to max(R1,R2).
line_vline(C, R1, R2, Cells) :-
% Determine top and bottom endpoints.
    Lo is min(R1, R2), Hi is max(R1, R2),
% Generate all row indices in this range.
    numlist(Lo, Hi, Rows),
% Build R-C pairs; unify RC to R-C deterministically.
    maplist([R, RC]>>(RC = R-C), Rows, Cells).

% line_diag_step_: compute the unit step for a 45-degree diagonal.
% Steps are (1,1), (1,-1), (-1,1), or (-1,-1) depending on direction.
line_diag_step_(R1, C1, R2, C2, DR, DC) :-
% Row step: sign of (R2 - R1).
    DR is sign(R2 - R1),
% Column step: sign of (C2 - C1).
    DC is sign(C2 - C1).

% line_diag_walk_: collect cells along a 45-degree diagonal walk from (R,C) to (R2,C2).
line_diag_walk_(R, C, R2, C2, DR, DC, Cells) :-
    (R =:= R2, C =:= C2 ->
% Base case: at the endpoint, include it.
        Cells = [R-C]
    ;
% Recursive case: include current cell and step.
        R1 is R + DR, C1 is C + DC,
        line_diag_walk_(R1, C1, R2, C2, DR, DC, RestCells),
        Cells = [R-C|RestCells]
    ).

% line_diag_seg(+R1, +C1, +R2, +C2, -Cells): cells on the 45-degree diagonal from (R1,C1) to (R2,C2).
% Requires abs(R2-R1) = abs(C2-C1). Cells include both endpoints.
line_diag_seg(R1, C1, R2, C2, Cells) :-
% Verify this is actually a 45-degree diagonal.
    AbsR is abs(R2 - R1), AbsC is abs(C2 - C1), AbsR =:= AbsC,
% Compute the step direction.
    line_diag_step_(R1, C1, R2, C2, DR, DC),
% Walk from start to end.
    line_diag_walk_(R1, C1, R2, C2, DR, DC, Cells).

% line_draw_h(+Grid, +R, +C1, +C2, +Color, -Result): draw horizontal line on Row R.
% All cells from column min(C1,C2) to max(C1,C2) are set to Color.
line_draw_h(Grid, R, C1, C2, Color, Result) :-
    line_hline(R, C1, C2, Cells),
    line_fill_cells_(Grid, Cells, Color, Result).

% line_draw_v(+Grid, +C, +R1, +R2, +Color, -Result): draw vertical line on Column C.
% All cells from row min(R1,R2) to max(R1,R2) are set to Color.
line_draw_v(Grid, C, R1, R2, Color, Result) :-
    line_vline(C, R1, R2, Cells),
    line_fill_cells_(Grid, Cells, Color, Result).

% line_draw_diag(+Grid, +R1, +C1, +R2, +C2, +Color, -Result): draw 45-degree diagonal.
% Requires abs(R2-R1) = abs(C2-C1). Both endpoints are included.
line_draw_diag(Grid, R1, C1, R2, C2, Color, Result) :-
    line_diag_seg(R1, C1, R2, C2, Cells),
    line_fill_cells_(Grid, Cells, Color, Result).

% line_same_row(+R1, +C1, +R2, +C2): succeed if (R1,C1) and (R2,C2) are in the same row.
line_same_row(R1, _, R2, _) :-
    R1 =:= R2.

% line_same_col(+R1, +C1, +R2, +C2): succeed if (R1,C1) and (R2,C2) are in the same column.
line_same_col(_, C1, _, C2) :-
    C1 =:= C2.

% line_same_diag(+R1, +C1, +R2, +C2): succeed if (R1,C1) and (R2,C2) are on the same diagonal.
% Both cells satisfy C - R = constant.
line_same_diag(R1, C1, R2, C2) :-
    C1 - R1 =:= C2 - R2.

% line_same_anti(+R1, +C1, +R2, +C2): succeed if on the same anti-diagonal (R+C = constant).
line_same_anti(R1, C1, R2, C2) :-
    R1 + C1 =:= R2 + C2.

% line_collinear(+R1, +C1, +R2, +C2, +R3, +C3): three cells are collinear iff they share
% a row, a column, a diagonal (C-R), or an anti-diagonal (R+C).
% Uses if-then-else chain to commit to the first matching case.
line_collinear(R1, C1, R2, C2, R3, C3) :-
    (R1 =:= R2, R2 =:= R3       -> true
    ; C1 =:= C2, C2 =:= C3      -> true
    ; C1-R1 =:= C2-R2, C2-R2 =:= C3-R3 -> true
    ; R1+C1 =:= R2+C2, R2+C2 =:= R3+C3
    ).

% line_endpoints(+Cells, -First, -Last): the first and last R-C pair in a non-empty list.
% Cells is the list of collinear cells in segment order; First = head, Last = last element.
line_endpoints([H|T], H, Last) :-
% Walk to the last element.
    line_last_(T, H, Last).

% line_last_: accumulate the last element of a non-empty list.
line_last_([], Acc, Acc) :- !.
line_last_([H|T], _, Last) :-
    line_last_(T, H, Last).

% line_gap(+R1, +C1, +R2, +C2, -Gap): cells strictly between (R1,C1) and (R2,C2).
% The two cells must be on the same row, column, diagonal, or anti-diagonal.
% Gap excludes both endpoints.
line_gap(R1, C1, R2, C2, Gap) :-
    (R1 =:= R2 ->
% Horizontal gap: all columns strictly between C1 and C2.
        Lo is min(C1,C2)+1, Hi is max(C1,C2)-1,
        (Lo =< Hi -> numlist(Lo, Hi, Cols), maplist([C, RC]>>(RC = R1-C), Cols, Gap) ; Gap = [])
    ; C1 =:= C2 ->
% Vertical gap: all rows strictly between R1 and R2.
        Lo is min(R1,R2)+1, Hi is max(R1,R2)-1,
        (Lo =< Hi -> numlist(Lo, Hi, Rows), maplist([R, RC]>>(RC = R-C1), Rows, Gap) ; Gap = [])
    ; C1-R1 =:= C2-R2 ->
% Diagonal gap: step from (R1,C1) towards (R2,C2), exclude endpoints.
        DR is sign(R2-R1), DC is sign(C2-C1),
        R1s is R1+DR, C1s is C1+DC, R2s is R2-DR, C2s is C2-DC,
        (R1s =:= R2+DR ->
% No interior cells.
            Gap = []
        ;
            line_diag_step_(R1s, C1s, R2s, C2s, DR, DC),
            line_diag_walk_(R1s, C1s, R2s, C2s, DR, DC, Gap)
        )
    ; R1+C1 =:= R2+C2 ->
% Anti-diagonal gap: same as diagonal but for anti-diagonals.
        DR is sign(R2-R1), DC is sign(C2-C1),
        R1s is R1+DR, C1s is C1+DC, R2s is R2-DR, C2s is C2-DC,
        (R1s =:= R2+DR ->
            Gap = []
        ;
            line_diag_walk_(R1s, C1s, R2s, C2s, DR, DC, Gap)
        )
    ).

% line_line_type(+R1, +C1, +R2, +C2, -Type): classify the line segment from (R1,C1) to (R2,C2).
% Type is one of: horizontal, vertical, diagonal, anti_diagonal, point.
line_line_type(R1, C1, R2, C2, Type) :-
    (R1 =:= R2, C1 =:= C2 -> Type = point
    ; R1 =:= R2               -> Type = horizontal
    ; C1 =:= C2               -> Type = vertical
    ; C1-R1 =:= C2-R2         -> Type = diagonal
    ; R1+C1 =:= R2+C2         -> Type = anti_diagonal
    ; Type = other
    ).
