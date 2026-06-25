% PLUnit tests for the project pack (pj_* predicates, Layer 88).
:- use_module(library(plunit)).
:- use_module('../prolog/project').

:- begin_tests(project_pj_shadow_down).

% Non-BG cell at row 0 casts value 1 downward through two BG rows.
test(shadow_down_single_source) :-
    pj_shadow_down([[1,0],[0,0],[0,0]], 0, R),
    R = [[1,0],[1,0],[1,0]].

% Two sources in the same column: each casts until the other blocks.
test(shadow_down_two_sources) :-
    pj_shadow_down([[0,2],[0,0],[0,3]], 0, R),
    R = [[0,2],[0,2],[0,3]].

% All BG: no shadow, grid unchanged.
test(shadow_down_all_bg) :-
    pj_shadow_down([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(project_pj_shadow_down).

:- begin_tests(project_pj_shadow_up).

% Non-BG cell at bottom row casts upward through two BG rows.
test(shadow_up_single_source) :-
    pj_shadow_up([[0,0],[0,0],[1,0]], 0, R),
    R = [[1,0],[1,0],[1,0]].

% Cell already at top: nothing above to fill, column unchanged.
test(shadow_up_already_top) :-
    pj_shadow_up([[2,0],[0,0]], 0, R),
    R = [[2,0],[0,0]].

% Source at row 2 of 4-row column: fills rows 0 and 1 above it.
test(shadow_up_mid_source) :-
    pj_shadow_up([[0],[0],[3],[0]], 0, R),
    R = [[3],[3],[3],[0]].

:- end_tests(project_pj_shadow_up).

:- begin_tests(project_pj_shadow_left).

% Non-BG cell at rightmost position casts entire row left.
test(shadow_left_fills_row) :-
    pj_shadow_left([[0,0,2]], 0, R),
    R = [[2,2,2]].

% Two sources: right source stops at the left source.
test(shadow_left_two_sources) :-
    pj_shadow_left([[1,0,2]], 0, R),
    R = [[1,2,2]].

% Source at col 0 has nothing to its left; row unchanged.
test(shadow_left_at_col0) :-
    pj_shadow_left([[2,0,0]], 0, R),
    R = [[2,0,0]].

:- end_tests(project_pj_shadow_left).

:- begin_tests(project_pj_shadow_right).

% Non-BG cell at leftmost position casts entire row right.
test(shadow_right_fills_row) :-
    pj_shadow_right([[1,0,0]], 0, R),
    R = [[1,1,1]].

% Two sources: left source stops at the right source.
test(shadow_right_two_sources) :-
    pj_shadow_right([[1,0,2]], 0, R),
    R = [[1,1,2]].

% Source at rightmost col: nothing to its right; row unchanged.
test(shadow_right_at_last_col) :-
    pj_shadow_right([[0,0,3]], 0, R),
    R = [[0,0,3]].

:- end_tests(project_pj_shadow_right).

:- begin_tests(project_pj_shadow_dir).

% direction atom 'down' dispatches to shadow_down.
test(shadow_dir_down) :-
    pj_shadow_dir([[2,0],[0,0]], 0, down, R),
    R = [[2,0],[2,0]].

% direction atom 'up' dispatches to shadow_up.
test(shadow_dir_up) :-
    pj_shadow_dir([[0,0],[3,0]], 0, up, R),
    R = [[3,0],[3,0]].

% direction atom 'right' dispatches to shadow_right.
test(shadow_dir_right) :-
    pj_shadow_dir([[4,0,0]], 0, right, R),
    R = [[4,4,4]].

:- end_tests(project_pj_shadow_dir).

:- begin_tests(project_pj_nonbg_rows).

% One non-BG row among three.
test(nonbg_rows_one) :-
    pj_nonbg_rows([[0,0],[1,0],[0,0]], 0, Rows),
    Rows = [1].

% All rows are non-BG.
test(nonbg_rows_all) :-
    pj_nonbg_rows([[1,2],[3,4]], 0, Rows),
    Rows = [0,1].

% All BG: no non-BG rows.
test(nonbg_rows_none) :-
    pj_nonbg_rows([[0,0],[0,0]], 0, Rows),
    Rows = [].

:- end_tests(project_pj_nonbg_rows).

:- begin_tests(project_pj_nonbg_cols).

% One non-BG column.
test(nonbg_cols_one) :-
    pj_nonbg_cols([[0,1,0],[0,0,0]], 0, Cols),
    Cols = [1].

% All columns are non-BG.
test(nonbg_cols_all) :-
    pj_nonbg_cols([[1,0,1],[0,2,0]], 0, Cols),
    Cols = [0,1,2].

% All BG: empty list.
test(nonbg_cols_none) :-
    pj_nonbg_cols([[0,0],[0,0]], 0, Cols),
    Cols = [].

:- end_tests(project_pj_nonbg_cols).

:- begin_tests(project_pj_row_counts).

% Mixed rows: counts per row.
test(row_counts_mixed) :-
    pj_row_counts([[1,0,1],[0,0,0],[0,2,0]], 0, Counts),
    Counts = [2,0,1].

% All BG rows: all zero.
test(row_counts_all_bg) :-
    pj_row_counts([[0,0],[0,0]], 0, Counts),
    Counts = [0,0].

% Full row: count equals row width.
test(row_counts_full_row) :-
    pj_row_counts([[1,2,3]], 0, Counts),
    Counts = [3].

:- end_tests(project_pj_row_counts).

:- begin_tests(project_pj_col_counts).

% Two non-BG cells in two different columns.
test(col_counts_mixed) :-
    pj_col_counts([[1,0],[0,2],[0,0]], 0, Counts),
    Counts = [1,1].

% All cells non-BG: each column count equals number of rows.
test(col_counts_full) :-
    pj_col_counts([[1,1],[1,1]], 0, Counts),
    Counts = [2,2].

% All BG: all counts zero.
test(col_counts_all_bg) :-
    pj_col_counts([[0,0],[0,0]], 0, Counts),
    Counts = [0,0].

:- end_tests(project_pj_col_counts).

:- begin_tests(project_pj_collapse_rows).

% Two rows each contributing one non-BG per column.
test(collapse_rows_basic) :-
    pj_collapse_rows([[1,0],[0,2]], 0, Row),
    Row = [1,2].

% All BG: result row is all BG.
test(collapse_rows_all_bg) :-
    pj_collapse_rows([[0,0],[0,0]], 0, Row),
    Row = [0,0].

% First non-BG row wins when multiple rows have non-BG in same column.
test(collapse_rows_first_wins) :-
    pj_collapse_rows([[0,3],[1,0]], 0, Row),
    Row = [1,3].

:- end_tests(project_pj_collapse_rows).

:- begin_tests(project_pj_collapse_cols).

% Two rows each contributing a single non-BG value.
test(collapse_cols_basic) :-
    pj_collapse_cols([[1,0],[0,2]], 0, Col),
    Col = [1,2].

% All BG: result column is all BG.
test(collapse_cols_all_bg) :-
    pj_collapse_cols([[0,0],[0,0]], 0, Col),
    Col = [0,0].

% First non-BG in row wins.
test(collapse_cols_first_wins) :-
    pj_collapse_cols([[0,3],[1,0]], 0, Col),
    Col = [3,1].

:- end_tests(project_pj_collapse_cols).

:- begin_tests(project_pj_col_first).

% Non-BG appears at row 1.
test(col_first_row1) :-
    pj_col_first([[0,0],[1,0],[0,0]], 0, 0, R),
    R =:= 1.

% Non-BG appears at last row.
test(col_first_last_row) :-
    pj_col_first([[0,0],[0,0],[0,1]], 1, 0, R),
    R =:= 2.

% Non-BG at row 0 (topmost position).
test(col_first_row0) :-
    pj_col_first([[1,0],[0,0]], 0, 0, R),
    R =:= 0.

:- end_tests(project_pj_col_first).

:- begin_tests(project_pj_col_last).

% Two non-BG cells in column; last is at row 1.
test(col_last_row1) :-
    pj_col_last([[1,0],[1,0],[0,0]], 0, 0, R),
    R =:= 1.

% Non-BG cells at rows 0 and 2; last is row 2.
test(col_last_row2) :-
    pj_col_last([[0,1],[0,0],[0,1]], 1, 0, R),
    R =:= 2.

% Single non-BG cell at bottom row.
test(col_last_bottom) :-
    pj_col_last([[0,0],[0,0],[1,0]], 0, 0, R),
    R =:= 2.

:- end_tests(project_pj_col_last).

:- begin_tests(project_pj_row_first).

% Non-BG at column 2 (first from left).
test(row_first_col2) :-
    pj_row_first([[0,0,1,0]], 0, 0, C),
    C =:= 2.

% In row 1 the first non-BG is at column 3.
test(row_first_row1) :-
    pj_row_first([[0,1,0,1],[0,0,0,2]], 1, 0, C),
    C =:= 3.

% Non-BG at column 0 (leftmost position).
test(row_first_col0) :-
    pj_row_first([[1,0,0]], 0, 0, C),
    C =:= 0.

:- end_tests(project_pj_row_first).
