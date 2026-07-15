% Module declaration: compose exports all cp_* predicates.
:- module(compose, [
    compose_apply/3,
    compose_identity/2,
    compose_const/3,
    compose_pipe/3,
    compose_pipe_n/4,
    compose_branch/5,
    compose_repeat/4,
    compose_until/4,
    compose_fixed_point/3,
    compose_map_rows/3,
    compose_map_cols/3,
    compose_zip/4,
    compose_fold/4
]).

% Import list utilities.
:- use_module(library(lists), [nth0/3, append/2, append/3, numlist/3]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3, maplist/4]).
% Import grid pack for grid-level operations.
:- use_module(library(grid)).


% SINGLE STEP APPLICATION
% compose_apply(+Rule, +Grid, -Grid2): apply Rule as call(Rule, Grid, Grid2).
compose_apply(Rule, Grid, Grid2) :-
% Dispatch through meta-call; Rule may be a predicate name or partial application.
    call(Rule, Grid, Grid2).

% compose_identity(+Grid, -Grid2): identity transformation; output equals input.
compose_identity(Grid, Grid).

% compose_const(+ConstGrid, +_Grid, -Grid2): always return ConstGrid regardless of input.
compose_const(ConstGrid, _Grid, ConstGrid).


% SEQUENTIAL PIPELINE
% compose_pipe(+Rules, +Grid, -Grid2): apply Rules in sequence; output of each feeds the next.
compose_pipe([], Grid, Grid).
compose_pipe([Rule|Rest], Grid, Grid2) :-
% Apply the current rule to get the intermediate grid.
    compose_apply(Rule, Grid, Mid),
% Feed the intermediate into the rest of the pipeline.
    compose_pipe(Rest, Mid, Grid2).

% compose_pipe_n(+Rule, +N, +Grid, -Grid2): apply Rule exactly N times in sequence.
compose_pipe_n(Rule, N, Grid, Grid2) :-
% Build a list of N identical rule references.
    length(Rules, N),
    maplist(=(Rule), Rules),
% Execute as a sequential pipeline.
    compose_pipe(Rules, Grid, Grid2).


% CONDITIONAL BRANCHING
% compose_branch(+Cond,+ThenRule,+ElseRule,+Grid,-Grid2): apply Then or Else based on Cond.
compose_branch(Cond, ThenRule, _ElseRule, Grid, Grid2) :-
% Condition holds: apply ThenRule.
    call(Cond, Grid),
    !,
    compose_apply(ThenRule, Grid, Grid2).
compose_branch(_Cond, _ThenRule, ElseRule, Grid, Grid2) :-
% Condition failed: apply ElseRule.
    compose_apply(ElseRule, Grid, Grid2).


% REPETITION COMBINATORS
% compose_repeat(+Rule, +N, +Grid, -Grid2): apply Rule exactly N times (alias for compose_pipe_n).
compose_repeat(Rule, N, Grid, Grid2) :-
% Delegate to compose_pipe_n.
    compose_pipe_n(Rule, N, Grid, Grid2).

% compose_until(+Rule, +Cond, +Grid, -Grid2): apply Rule until call(Cond, Grid) succeeds.
compose_until(_Rule, Cond, Grid, Grid) :-
% Base case: condition already holds; return the grid unchanged.
    call(Cond, Grid),
    !.
compose_until(Rule, Cond, Grid, Grid2) :-
% Apply the rule once to get the next grid.
    compose_apply(Rule, Grid, Mid),
% Recurse until the condition holds.
    compose_until(Rule, Cond, Mid, Grid2).

% compose_fixed_point(+Rule, +Grid, -Grid2): apply Rule until the grid stops changing.
compose_fixed_point(Rule, Grid, Grid2) :-
% Apply the rule once.
    compose_apply(Rule, Grid, Mid),
% Check for convergence using structural equality.
    ( grid_equal(Grid, Mid) ->
% Grid unchanged: convergence reached.
        Grid2 = Grid
    ;
% Grid changed: recurse on the new grid.
        compose_fixed_point(Rule, Mid, Grid2)
    ).


% ROW AND COLUMN MAPPING
% compose_map_rows(+RowRule, +Grid, -Grid2): apply RowRule independently to each row.
compose_map_rows(RowRule, Grid, Grid2) :-
% maplist calls call(RowRule, Row, TransformedRow) for each row.
    maplist(RowRule, Grid, Grid2).

% compose_map_cols(+ColRule, +Grid, -Grid2): apply ColRule independently to each column.
compose_map_cols(ColRule, Grid, Grid2) :-
% Get grid dimensions.
    grid_size(Grid, Rows, Cols),
% Build the column index list.
    C1 is Cols - 1,
    numlist(0, C1, ColIndices),
% Transform each column with ColRule; result is a list of transformed columns.
    maplist(transform_col(Grid, ColRule), ColIndices, TransformedCols),
% Reassemble the grid from the transformed column data, row by row.
    R1 is Rows - 1,
    numlist(0, R1, RowIndices),
    maplist(assemble_row(TransformedCols, ColIndices), RowIndices, Grid2).

% transform_col(+Grid, +ColRule, +C, -TransformedCol): apply ColRule to column C.
transform_col(Grid, ColRule, C, TransformedCol) :-
% Extract the column as a flat list of cell colors.
    grid_col(Grid, C, Col),
% Apply ColRule: call(ColRule, Col, TransformedCol).
    call(ColRule, Col, TransformedCol).

% assemble_row(+TransformedCols, +ColIndices, +R, -Row): row R from transformed columns.
assemble_row(TransformedCols, ColIndices, R, Row) :-
% For each column index C: Row[C] = TransformedCols[C][R].
    maplist(pick_row_cell(TransformedCols, R), ColIndices, Row).

% pick_row_cell(+TransformedCols, +R, +C, -Color): cell (R,C) from transformed column list.
pick_row_cell(TransformedCols, R, C, Color) :-
% Select the C-th transformed column.
    nth0(C, TransformedCols, TransformedCol),
% Select the R-th element of that column.
    nth0(R, TransformedCol, Color).


% PAIRWISE GRID COMBINATION
% compose_zip(+Rule, +GridA, +GridB, -GridC): combine two same-size grids cell by cell.
compose_zip(Rule, GridA, GridB, GridC) :-
% Zip rows pairwise; maplist/4 iterates three lists in lock-step.
    maplist(zip_row(Rule), GridA, GridB, GridC).

% zip_row(+Rule, +RowA, +RowB, -RowC): combine two rows cell by cell.
zip_row(Rule, RowA, RowB, RowC) :-
% maplist/4 calls call(Rule, A, B, C) for each cell triple.
    maplist(Rule, RowA, RowB, RowC).


% LEFT FOLD OVER A LIST OF GRIDS
% compose_fold(+Rule, +Init, +Grids, -Result): left-fold Rule over Grids with accumulator Init.
compose_fold(_Rule, Acc, [], Acc).
compose_fold(Rule, Acc, [G|Gs], Result) :-
% Apply Rule to the accumulator and the current grid to get a new accumulator.
    call(Rule, Acc, G, NewAcc),
% Continue folding over the tail.
    compose_fold(Rule, NewAcc, Gs, Result).
