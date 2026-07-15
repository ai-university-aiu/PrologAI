% project.pl - Layer 88: Axis Projection and Shadow Casting (pj_* prefix).
:- module(project, [
    project_shadow_down/3, project_shadow_up/3, project_shadow_left/3, project_shadow_right/3,
    project_shadow_dir/4,
    project_nonbg_rows/3, project_nonbg_cols/3,
    project_row_counts/3, project_col_counts/3,
    project_collapse_rows/3, project_collapse_cols/3,
    project_col_first/4, project_col_last/4, project_row_first/4
]).
% Import list operations: member, nth0, numlist, append, reverse, last.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, reverse/2, last/2]).
% Import higher-order operations: maplist, foldl, include.
:- use_module(library(apply), [maplist/3, foldl/4, include/3]).

% project_not_bg_: V is not the background value.
project_not_bg_(BG, V) :- V \= BG.

% project_prop_fwd_: propagate non-BG values forward (left to right) through BG in a list.
% BG = background value; Cur = current shadow (BG means no shadow active yet).
project_prop_fwd_(_, _, [], []) :- !.
% If V is non-BG, keep it and update the shadow to V.
project_prop_fwd_(BG, Cur, [V|Vs], [R|Rs]) :-
    (   V \= BG
    ->  R = V, Next = V
% If V is BG and a shadow is active, paint with the shadow; else keep BG.
    ;   (Cur \= BG -> R = Cur ; R = BG), Next = Cur
    ),
    project_prop_fwd_(BG, Next, Vs, Rs).

% project_nth_: extract element N from a list (helper for maplist over rows).
project_nth_(N, Row, V) :- nth0(N, Row, V).

% project_extract_col_: extract column Col from Grid as a top-to-bottom value list.
project_extract_col_(Grid, Col, Vals) :-
    maplist(project_nth_(Col), Grid, Vals).

% project_set_col_: replace column Col in Grid with the values in Vals.
project_set_col_([], _, [], []) :- !.
% Decompose each row at Col, replace the value, reassemble.
project_set_col_([Row|Rows], Col, [V|Vs], [Row2|Grid2]) :-
    length(Pre, Col),
    append(Pre, [_|Post], Row),
    append(Pre, [V|Post], Row2),
    project_set_col_(Rows, Col, Vs, Grid2).

% project_grid_cols_: produce the list of valid column indices for a grid.
project_grid_cols_(Grid, Cols) :-
    (   Grid = [FR|_], FR \= []
    ->  length(FR, NC), NC1 is NC - 1, numlist(0, NC1, Cols)
    ;   Cols = []
    ).

% project_shadow_col_fwd_: apply forward (downward) shadow to one column.
project_shadow_col_fwd_(BG, Col, G0, G1) :-
    project_extract_col_(G0, Col, Vals),
    project_prop_fwd_(BG, BG, Vals, Vals2),
    project_set_col_(G0, Col, Vals2, G1).

% project_shadow_col_bwd_: apply backward (upward) shadow to one column.
project_shadow_col_bwd_(BG, Col, G0, G1) :-
    project_extract_col_(G0, Col, Vals),
    reverse(Vals, RevVals),
    project_prop_fwd_(BG, BG, RevVals, PropVals),
    reverse(PropVals, Vals2),
    project_set_col_(G0, Col, Vals2, G1).

% project_shadow_row_fwd_: apply forward (rightward) shadow to one row.
project_shadow_row_fwd_(BG, Row, Row2) :-
    project_prop_fwd_(BG, BG, Row, Row2).

% project_shadow_row_bwd_: apply backward (leftward) shadow to one row.
project_shadow_row_bwd_(BG, Row, Row2) :-
    reverse(Row, RevRow),
    project_prop_fwd_(BG, BG, RevRow, PropRow),
    reverse(PropRow, Row2).

% project_shadow_down: each non-BG cell casts its value downward through BG cells.
% Shadow stops when it hits another non-BG cell from below.
project_shadow_down(Grid, BG, Grid2) :-
    project_grid_cols_(Grid, Cols),
    foldl(project_shadow_col_fwd_(BG), Cols, Grid, Grid2).

% project_shadow_up: each non-BG cell casts its value upward through BG cells.
project_shadow_up(Grid, BG, Grid2) :-
    project_grid_cols_(Grid, Cols),
    foldl(project_shadow_col_bwd_(BG), Cols, Grid, Grid2).

% project_shadow_left: each non-BG cell casts its value leftward through BG cells.
project_shadow_left(Grid, BG, Grid2) :-
    maplist(project_shadow_row_bwd_(BG), Grid, Grid2).

% project_shadow_right: each non-BG cell casts its value rightward through BG cells.
project_shadow_right(Grid, BG, Grid2) :-
    maplist(project_shadow_row_fwd_(BG), Grid, Grid2).

% project_shadow_dir: dispatch shadow casting to a direction by atom name.
project_shadow_dir(Grid, BG, down,  Grid2) :- !, project_shadow_down(Grid, BG, Grid2).
project_shadow_dir(Grid, BG, up,    Grid2) :- !, project_shadow_up(Grid, BG, Grid2).
project_shadow_dir(Grid, BG, left,  Grid2) :- !, project_shadow_left(Grid, BG, Grid2).
project_shadow_dir(Grid, BG, right, Grid2) :- project_shadow_right(Grid, BG, Grid2).

% project_nonbg_rows: sorted list of row indices containing at least one non-BG cell.
project_nonbg_rows(Grid, BG, Rows) :-
    length(Grid, NR), NR1 is NR - 1,
    findall(R, (
        between(0, NR1, R),
        nth0(R, Grid, Row),
        once((member(V, Row), V \= BG))
    ), Rows).

% project_nonbg_cols: sorted list of column indices containing at least one non-BG cell.
project_nonbg_cols(Grid, BG, Cols) :-
    project_grid_cols_(Grid, AllCols),
    findall(C, (
        member(C, AllCols),
        project_extract_col_(Grid, C, Vals),
        once((member(V, Vals), V \= BG))
    ), Cols).

% project_count_nonbg_: count non-BG cells in a row list.
project_count_nonbg_(BG, Row, Count) :-
    include(project_not_bg_(BG), Row, NonBG),
    length(NonBG, Count).

% project_row_counts: list of non-BG cell counts per row, one entry per row.
project_row_counts(Grid, BG, Counts) :-
    maplist(project_count_nonbg_(BG), Grid, Counts).

% project_col_count_: count non-BG cells in one column.
project_col_count_(Grid, BG, Col, Count) :-
    project_extract_col_(Grid, Col, Vals),
    project_count_nonbg_(BG, Vals, Count).

% project_col_counts: list of non-BG cell counts per column, one entry per column.
project_col_counts(Grid, BG, Counts) :-
    project_grid_cols_(Grid, Cols),
    maplist(project_col_count_(Grid, BG), Cols, Counts).

% project_first_nonbg_: first non-BG value in a list; BG if all cells are BG.
project_first_nonbg_([], BG, BG) :- !.
% Non-BG head: return it immediately.
project_first_nonbg_([V|_], BG, V) :- V \= BG, !.
% BG head: recurse on tail.
project_first_nonbg_([_|Vs], BG, R) :- project_first_nonbg_(Vs, BG, R).

% project_col_first_val_: first non-BG value in column Col (BG if all BG).
project_col_first_val_(Grid, BG, Col, V) :-
    project_extract_col_(Grid, Col, Vals),
    project_first_nonbg_(Vals, BG, V).

% project_row_first_val_: first non-BG value in a row (BG if all BG).
project_row_first_val_(BG, Row, V) :-
    project_first_nonbg_(Row, BG, V).

% project_collapse_rows: merge all rows to one row; first non-BG value wins per column.
project_collapse_rows(Grid, BG, Row) :-
    project_grid_cols_(Grid, Cols),
    maplist(project_col_first_val_(Grid, BG), Cols, Row).

% project_collapse_cols: merge all columns to one column; first non-BG value wins per row.
project_collapse_cols(Grid, BG, Col) :-
    maplist(project_row_first_val_(BG), Grid, Col).

% project_col_first: row index of the topmost non-BG cell in column Col.
% Uses between/3 (ascending) with cut; fails if column is all BG.
project_col_first(Grid, Col, BG, R) :-
    length(Grid, NR), NR1 is NR - 1,
    between(0, NR1, R),
    nth0(R, Grid, Row),
    nth0(Col, Row, V),
    V \= BG, !.

% project_col_last: row index of the bottommost non-BG cell in column Col.
% Collects all non-BG rows then takes the last; fails if column is all BG.
project_col_last(Grid, Col, BG, R) :-
    length(Grid, NR), NR1 is NR - 1,
    findall(R2, (
        between(0, NR1, R2),
        nth0(R2, Grid, Row2),
        nth0(Col, Row2, V2),
        V2 \= BG
    ), Rs),
    last(Rs, R).

% project_row_first: column index of the leftmost non-BG cell in row Row.
% Uses between/3 (ascending) with cut; fails if row is all BG.
project_row_first(Grid, Row, BG, C) :-
    nth0(Row, Grid, RowList),
    length(RowList, NC), NC1 is NC - 1,
    between(0, NC1, C),
    nth0(C, RowList, V),
    V \= BG, !.
