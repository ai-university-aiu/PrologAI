:- module(gridscan, [
    gridscan_scan_row/4,
    gridscan_scan_col/4,
    gridscan_first_right/5,
    gridscan_first_left/5,
    gridscan_first_down/5,
    gridscan_first_up/5,
    gridscan_dist_right/5,
    gridscan_dist_left/5,
    gridscan_dist_down/5,
    gridscan_dist_up/5,
    gridscan_blocked_right/4,
    gridscan_blocked_left/4,
    gridscan_blocked_down/4,
    gridscan_blocked_up/4
]).
% gridscan.pl - Layer 228: Grid Ray Scanning (gsn_* prefix).
% Fourteen predicates for scanning rows and columns to find non-background cells.
% Four directions of scanning: right, left, down, up.
% gsn_scan_* collects all non-bg cells in a row or column.
% gsn_first_* returns the nearest non-bg cell in a direction.
% gsn_dist_* returns the number of steps to the nearest non-bg cell.
% gsn_blocked_* checks whether any non-bg cell exists in a direction.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, last/2]).

% --- PUBLIC PREDICATES ---

% gridscan_scan_row(+Grid, +R, +BgColor, -CVPairs)
% CVPairs is the list of C-V pairs for all non-BgColor cells in row R.
% Pairs are ordered by column index (ascending).
gridscan_scan_row(Grid, R, BgColor, CVPairs) :-
% Extract row R.
    nth0(R, Grid, Row),
    length(Row, W), W1 is W - 1,
% Collect non-bg cells as column-value pairs.
    findall(C-V, (between(0, W1, C), nth0(C, Row, V), V \= BgColor), CVPairs).

% gridscan_scan_col(+Grid, +C, +BgColor, -RVPairs)
% RVPairs is the list of R-V pairs for all non-BgColor cells in column C.
% Pairs are ordered by row index (ascending).
gridscan_scan_col(Grid, C, BgColor, RVPairs) :-
% Column length equals grid height.
    length(Grid, H), H1 is H - 1,
% Collect non-bg cells as row-value pairs.
    findall(R-V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V),
                  V \= BgColor), RVPairs).

% gridscan_first_right(+Grid, +R, +C0, +BgColor, -C-V)
% C-V is the first (leftmost) non-BgColor cell in row R with column > C0.
% Fails if no such cell exists.
gridscan_first_right(Grid, R, C0, BgColor, C-V) :-
% Get row R.
    nth0(R, Grid, Row), length(Row, W), W1 is W - 1,
% Start scanning from C0+1.
    C1 is C0 + 1, C1 =< W1,
% Find first non-bg cell going right.
    between(C1, W1, C), nth0(C, Row, V), V \= BgColor, !.

% gridscan_first_left(+Grid, +R, +C0, +BgColor, -C-V)
% C-V is the nearest (rightmost) non-BgColor cell in row R with column < C0.
% Fails if no such cell exists.
gridscan_first_left(Grid, R, C0, BgColor, C-V) :-
% Get row R.
    nth0(R, Grid, Row),
% Must have at least one column to the left.
    C1 is C0 - 1, C1 >= 0,
% Collect all non-bg cells to the left (ascending column order).
    findall(C2-V2, (between(0, C1, C2), nth0(C2, Row, V2), V2 \= BgColor), Pairs),
    Pairs \= [],
% The last pair has the highest column index = nearest to C0.
    last(Pairs, C-V).

% gridscan_first_down(+Grid, +R0, +C, +BgColor, -R-V)
% R-V is the first (topmost) non-BgColor cell in column C with row > R0.
% Fails if no such cell exists.
gridscan_first_down(Grid, R0, C, BgColor, R-V) :-
% Must have rows below R0.
    length(Grid, H), H1 is H - 1,
    R1 is R0 + 1, R1 =< H1,
% Find first non-bg cell going down.
    between(R1, H1, R), nth0(R, Grid, Row), nth0(C, Row, V), V \= BgColor, !.

% gridscan_first_up(+Grid, +R0, +C, +BgColor, -R-V)
% R-V is the nearest (bottommost) non-BgColor cell in column C with row < R0.
% Fails if no such cell exists.
gridscan_first_up(Grid, R0, C, BgColor, R-V) :-
% Must have rows above R0.
    R1 is R0 - 1, R1 >= 0,
% Collect all non-bg cells above (ascending row order).
    findall(R2-V2, (between(0, R1, R2), nth0(R2, Grid, Row2), nth0(C, Row2, V2),
                    V2 \= BgColor), Pairs),
    Pairs \= [],
% The last pair has the highest row index = nearest to R0.
    last(Pairs, R-V).

% gridscan_dist_right(+Grid, +R, +C0, +BgColor, -D)
% D is the number of steps from C0 to the first non-BgColor cell going right
% (D = C_hit - C0; minimum 1). Fails if no such cell exists.
gridscan_dist_right(Grid, R, C0, BgColor, D) :-
    gridscan_first_right(Grid, R, C0, BgColor, C-_),
    D is C - C0.

% gridscan_dist_left(+Grid, +R, +C0, +BgColor, -D)
% D is the number of steps from C0 to the nearest non-BgColor cell going left
% (D = C0 - C_hit; minimum 1). Fails if no such cell exists.
gridscan_dist_left(Grid, R, C0, BgColor, D) :-
    gridscan_first_left(Grid, R, C0, BgColor, C-_),
    D is C0 - C.

% gridscan_dist_down(+Grid, +R0, +C, +BgColor, -D)
% D is the number of steps from R0 to the first non-BgColor cell going down
% (D = R_hit - R0; minimum 1). Fails if no such cell exists.
gridscan_dist_down(Grid, R0, C, BgColor, D) :-
    gridscan_first_down(Grid, R0, C, BgColor, R-_),
    D is R - R0.

% gridscan_dist_up(+Grid, +R0, +C, +BgColor, -D)
% D is the number of steps from R0 to the nearest non-BgColor cell going up
% (D = R0 - R_hit; minimum 1). Fails if no such cell exists.
gridscan_dist_up(Grid, R0, C, BgColor, D) :-
    gridscan_first_up(Grid, R0, C, BgColor, R-_),
    D is R0 - R.

% gridscan_blocked_right(+Grid, +R, +C0, +BgColor)
% Succeeds if there is at least one non-BgColor cell in row R to the right of C0.
gridscan_blocked_right(Grid, R, C0, BgColor) :-
    gridscan_first_right(Grid, R, C0, BgColor, _).

% gridscan_blocked_left(+Grid, +R, +C0, +BgColor)
% Succeeds if there is at least one non-BgColor cell in row R to the left of C0.
gridscan_blocked_left(Grid, R, C0, BgColor) :-
    gridscan_first_left(Grid, R, C0, BgColor, _).

% gridscan_blocked_down(+Grid, +R0, +C, +BgColor)
% Succeeds if there is at least one non-BgColor cell in column C below row R0.
gridscan_blocked_down(Grid, R0, C, BgColor) :-
    gridscan_first_down(Grid, R0, C, BgColor, _).

% gridscan_blocked_up(+Grid, +R0, +C, +BgColor)
% Succeeds if there is at least one non-BgColor cell in column C above row R0.
gridscan_blocked_up(Grid, R0, C, BgColor) :-
    gridscan_first_up(Grid, R0, C, BgColor, _).
