% Module declaration: gravity pack, Layer 60.
:- module(gravity, [
    % gv_compact_col/3: move all non-background values to the bottom of each column.
    gv_compact_col/3,
    % gv_compact_row/3: move all non-background values to the left of each row.
    gv_compact_row/3,
    % gv_fall_down/3: each non-background cell falls as far down as possible.
    gv_fall_down/3,
    % gv_fall_up/3: each non-background cell rises as far up as possible.
    gv_fall_up/3,
    % gv_fall_left/3: each non-background cell shifts as far left as possible.
    gv_fall_left/3,
    % gv_fall_right/3: each non-background cell shifts as far right as possible.
    gv_fall_right/3,
    % gv_settle_color/4: let cells of a specific color fall to bottom past background.
    gv_settle_color/4,
    % gv_float_color/4: let cells of a specific color rise to top past background.
    gv_float_color/4,
    % gv_stack_down/4: stack cells of a color at the bottom, preserving order.
    gv_stack_down/4,
    % gv_stack_up/4: stack cells of a color at the top, preserving order.
    gv_stack_up/4,
    % gv_apply_col/4: apply a list transform to each column of a grid.
    gv_apply_col/4,
    % gv_apply_row/4: apply a list transform to each row of a grid.
    gv_apply_row/4,
    % gv_col_values/3: extract all values in a given column as a list.
    gv_col_values/3,
    % gv_set_col/4: replace a column in a grid with a given list.
    gv_set_col/4
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, foldl/4]).

% gv_grid_dims_(+Grid, -Rows, -Cols): dimensions of a grid.
gv_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% gv_col_values(+Grid, +C, -Values): list of values in column C, top to bottom.
gv_col_values(Grid, C, Values) :-
    % Map each row to its C-th element.
    maplist(gv_row_nth_(C), Grid, Values).

% gv_row_nth_(+C, +Row, -V): value at column C in Row.
gv_row_nth_(C, Row, V) :-
    % Access element by index.
    nth0(C, Row, V).

% gv_set_col(+Grid, +C, +Values, -Result): replace column C with Values.
gv_set_col(Grid, C, Values, Result) :-
    % Pair each row with its new column value.
    maplist(gv_replace_col_(C), Grid, Values, Result).

% gv_replace_col_(+C, +Row, +V, -NewRow): set element C of Row to V.
gv_replace_col_(C, Row, V, NewRow) :-
    % Build prefix, skip old element, attach new value and suffix.
    length(Pre, C),
    append(Pre, [_|Suf], Row),
    append(Pre, [V|Suf], NewRow).

% gv_is_bg_(+BG, +V): V equals BG.
gv_is_bg_(BG, V) :- V =:= BG, !.

% gv_not_bg_(+BG, +V): V does not equal BG.
gv_not_bg_(BG, V) :- V =\= BG, !.

% gv_eq_(+X, +Y): Y equals X.
gv_eq_(X, Y) :- Y =:= X, !.

% gv_is_other_(+Color, +BG, +V): V is neither Color nor BG.
gv_is_other_(Color, BG, V) :- V =\= Color, V =\= BG, !.

% gv_compact_list_bottom_(+BG, +List, -Compacted): non-BG values sink to end.
gv_compact_list_bottom_(BG, List, Compacted) :-
    % Separate BG and non-BG values.
    include(gv_is_bg_(BG), List, Bgs),
    include(gv_not_bg_(BG), List, Vals),
    % Background at top, values at bottom.
    append(Bgs, Vals, Compacted).

% gv_compact_list_top_(+BG, +List, -Compacted): non-BG values rise to start.
gv_compact_list_top_(BG, List, Compacted) :-
    % Separate non-BG and BG values.
    include(gv_not_bg_(BG), List, Vals),
    include(gv_is_bg_(BG), List, Bgs),
    % Values at top, background at bottom.
    append(Vals, Bgs, Compacted).

% gv_compact_col(+Grid, +BG, -Result): compact each column so non-BG sinks to bottom.
gv_compact_col(Grid, BG, Result) :-
    % Get grid column count.
    gv_grid_dims_(Grid, _Rows, Cols),
    % Enumerate column indices.
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Fold over column indices, compacting each one.
    foldl(gv_compact_one_col_bottom_(BG), ColIds, Grid, Result).

% gv_compact_one_col_bottom_(+BG, +C, +G, -G2): compact column C toward bottom.
gv_compact_one_col_bottom_(BG, C, G, G2) :-
    % Extract column, compact, write back.
    gv_col_values(G, C, ColVals),
    gv_compact_list_bottom_(BG, ColVals, Compacted),
    gv_set_col(G, C, Compacted, G2).

% gv_compact_col_top_(+BG, +C, +G, -G2): compact column C toward top.
gv_compact_col_top_(BG, C, G, G2) :-
    % Extract column, compact upward, write back.
    gv_col_values(G, C, ColVals),
    gv_compact_list_top_(BG, ColVals, Compacted),
    gv_set_col(G, C, Compacted, G2).

% gv_compact_row_left_(+BG, +Row, -Compacted): non-BG values move to front.
gv_compact_row_left_(BG, Row, Compacted) :-
    gv_compact_list_top_(BG, Row, Compacted).

% gv_compact_row_right_(+BG, +Row, -Compacted): non-BG values move to end.
gv_compact_row_right_(BG, Row, Compacted) :-
    gv_compact_list_bottom_(BG, Row, Compacted).

% gv_compact_row(+Grid, +BG, -Result): compact each row so non-BG shifts left.
gv_compact_row(Grid, BG, Result) :-
    % Apply compact-left to every row.
    maplist(gv_compact_row_left_(BG), Grid, Result).

% gv_fall_down(+Grid, +BG, -Result): non-BG cells fall to bottom of their column.
gv_fall_down(Grid, BG, Result) :-
    gv_compact_col(Grid, BG, Result).

% gv_fall_up(+Grid, +BG, -Result): non-BG cells rise to top of their column.
gv_fall_up(Grid, BG, Result) :-
    % Get column count.
    gv_grid_dims_(Grid, _Rows, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Compact each column toward top.
    foldl(gv_compact_col_top_(BG), ColIds, Grid, Result).

% gv_fall_left(+Grid, +BG, -Result): non-BG cells shift to left of their row.
gv_fall_left(Grid, BG, Result) :-
    maplist(gv_compact_row_left_(BG), Grid, Result).

% gv_fall_right(+Grid, +BG, -Result): non-BG cells shift to right of their row.
gv_fall_right(Grid, BG, Result) :-
    maplist(gv_compact_row_right_(BG), Grid, Result).

% gv_settle_col_vals_(+Color, +BG, +List, -Settled): Color sinks to bottom past BG.
% Non-BG non-Color cells act as obstacles and maintain relative order above Colors.
% Output order: [Others...] [BGs...] [Colors...]  total = NO + NB + NC = len(List).
gv_settle_col_vals_(Color, BG, List, Settled) :-
    % Gather each category.
    include(gv_eq_(Color), List, Colors),
    include(gv_is_other_(Color, BG), List, Others),
    include(gv_is_bg_(BG), List, Bgs),
    % Colors sink to bottom; BGs fill gap above Colors; Others stay above.
    append(Others, Bgs, Top),
    append(Top, Colors, Settled).

% gv_settle_color(+Grid, +Color, +BG, -Result): cells of Color fall to bottom past BG.
gv_settle_color(Grid, Color, BG, Result) :-
    % Process each column independently.
    gv_grid_dims_(Grid, _Rows, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    foldl(gv_settle_color_col_(Color, BG), ColIds, Grid, Result).

% gv_settle_color_col_(+Color, +BG, +C, +G, -G2): settle Color in column C.
gv_settle_color_col_(Color, BG, C, G, G2) :-
    gv_col_values(G, C, ColVals),
    gv_settle_col_vals_(Color, BG, ColVals, Settled),
    gv_set_col(G, C, Settled, G2).

% gv_float_col_vals_(+Color, +BG, +List, -Floated): Color rises to top past BG.
% Output order: [Colors...] [Others...] [BGs...]  total = NC + NO + NB = len(List).
gv_float_col_vals_(Color, BG, List, Floated) :-
    % Gather each category.
    include(gv_eq_(Color), List, Colors),
    include(gv_is_other_(Color, BG), List, Others),
    include(gv_is_bg_(BG), List, Bgs),
    % Colors float to top; Others stay in middle; BGs sink to bottom.
    append(Colors, Others, Top),
    append(Top, Bgs, Floated).

% gv_float_color(+Grid, +Color, +BG, -Result): cells of Color rise to top past BG.
gv_float_color(Grid, Color, BG, Result) :-
    gv_grid_dims_(Grid, _Rows, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    foldl(gv_float_color_col_(Color, BG), ColIds, Grid, Result).

% gv_float_color_col_(+Color, +BG, +C, +G, -G2): float Color in column C.
gv_float_color_col_(Color, BG, C, G, G2) :-
    gv_col_values(G, C, ColVals),
    gv_float_col_vals_(Color, BG, ColVals, Floated),
    gv_set_col(G, C, Floated, G2).

% gv_stack_down(+Grid, +Color, +BG, -Result): Color cells stack at the bottom.
gv_stack_down(Grid, Color, BG, Result) :-
    gv_settle_color(Grid, Color, BG, Result).

% gv_stack_up(+Grid, +Color, +BG, -Result): Color cells stack at the top.
gv_stack_up(Grid, Color, BG, Result) :-
    gv_float_color(Grid, Color, BG, Result).

% gv_apply_col(+Grid, +BG, :Pred, -Result): apply Pred/3 to each column list.
% Pred(+BG, +ColIn, -ColOut).
gv_apply_col(Grid, BG, Pred, Result) :-
    % Enumerate column indices.
    gv_grid_dims_(Grid, _Rows, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Apply Pred to each column via foldl.
    foldl(gv_apply_one_col_(BG, Pred), ColIds, Grid, Result).

% gv_apply_one_col_(+BG, :Pred, +C, +G, -G2): apply Pred to column C.
gv_apply_one_col_(BG, Pred, C, G, G2) :-
    gv_col_values(G, C, ColVals),
    call(Pred, BG, ColVals, NewVals),
    gv_set_col(G, C, NewVals, G2).

% gv_apply_row(+Grid, +BG, :Pred, -Result): apply Pred/3 to each row list.
% Pred(+BG, +RowIn, -RowOut).
gv_apply_row(Grid, BG, Pred, Result) :-
    maplist(gv_apply_one_row_(BG, Pred), Grid, Result).

% gv_apply_one_row_(+BG, :Pred, +Row, -NewRow): apply Pred to one row.
gv_apply_one_row_(BG, Pred, Row, NewRow) :-
    call(Pred, BG, Row, NewRow).
