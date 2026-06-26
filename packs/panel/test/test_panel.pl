:- use_module('../prolog/panel').

:- begin_tests(panel).

% pn_is_divider_row/3 tests

% A row of all zeros is a divider row.
test(is_divider_row_all_bg) :-
    pn_is_divider_row([[1,2],[0,0],[3,4]], 1, 0).

% A row with a non-background value is not a divider row.
test(is_divider_row_not_bg, [fail]) :-
    pn_is_divider_row([[1,2],[0,1],[3,4]], 1, 0).

% The first row can be a divider row.
test(is_divider_row_first) :-
    pn_is_divider_row([[0,0,0],[1,2,3]], 0, 0).

% pn_is_divider_col/3 tests

% Column 1 is all zeros: it is a divider column.
test(is_divider_col_all_bg) :-
    pn_is_divider_col([[1,0,2],[3,0,4]], 1, 0).

% Column 0 has a non-zero value: not a divider.
test(is_divider_col_not_bg, [fail]) :-
    pn_is_divider_col([[1,0],[0,0]], 0, 0).

% Last column is all background.
test(is_divider_col_last) :-
    pn_is_divider_col([[1,2,0],[3,4,0]], 2, 0).

% pn_divider_rows/3 tests

% Grid with one divider row at index 2.
test(divider_rows_one) :-
    pn_divider_rows([[1,2],[3,4],[0,0],[5,6]], 0, Rows),
    Rows = [2].

% Grid with no divider rows.
test(divider_rows_none) :-
    pn_divider_rows([[1,2],[3,4]], 0, Rows),
    Rows = [].

% Grid with two divider rows at indices 1 and 3.
test(divider_rows_two) :-
    pn_divider_rows([[1],[0],[2],[0],[3]], 0, Rows),
    Rows = [1,3].

% pn_divider_cols/3 tests

% Grid with one divider column at index 1.
test(divider_cols_one) :-
    pn_divider_cols([[1,0,2],[3,0,4]], 0, Cols),
    Cols = [1].

% Grid with no divider columns.
test(divider_cols_none) :-
    pn_divider_cols([[1,2],[3,4]], 0, Cols),
    Cols = [].

% Grid with divider columns at indices 0 and 2.
test(divider_cols_two) :-
    pn_divider_cols([[0,1,0],[0,2,0]], 0, Cols),
    Cols = [0,2].

% pn_split_rows/3 tests

% Split a 5-row grid at row 2: two parts (rows 0-1 and rows 3-4).
test(split_rows_one_divider) :-
    pn_split_rows([[r0],[r1],[divider],[r3],[r4]], [2], Parts),
    Parts = [[[r0],[r1]], [[r3],[r4]]].

% Split a 5-row grid at rows 1 and 3: three parts.
test(split_rows_two_dividers) :-
    pn_split_rows([[a],[b],[c],[d],[e]], [1,3], Parts),
    Parts = [[[a]], [[c]], [[e]]].

% No dividers: one part = the whole grid.
test(split_rows_no_dividers) :-
    pn_split_rows([[1],[2],[3]], [], Parts),
    Parts = [[[1],[2],[3]]].

% pn_split_cols/3 tests

% Split a 1x5 grid at column 2: two parts.
test(split_cols_one_divider) :-
    pn_split_cols([[1,2,0,3,4]], [2], Parts),
    Parts = [[[1,2]], [[3,4]]].

% Split a 2x5 grid at columns 1 and 3: three column strips.
test(split_cols_two_dividers) :-
    pn_split_cols([[a,b,c,d,e],[f,g,h,i,j]], [1,3], Parts),
    Parts = [[[a],[f]], [[c],[h]], [[e],[j]]].

% No column dividers: one part = the whole grid.
test(split_cols_no_dividers) :-
    pn_split_cols([[1,2,3]], [], Parts),
    Parts = [[[1,2,3]]].

% pn_auto_split_rows/3 tests

% Grid with one all-0 divider row: auto-split produces two panels.
test(auto_split_rows_one_divider) :-
    pn_auto_split_rows([[1,2],[3,4],[0,0],[5,6],[7,8]], 0, Parts),
    Parts = [[[1,2],[3,4]], [[5,6],[7,8]]].

% Grid with no divider rows: one part = whole grid.
test(auto_split_rows_none) :-
    pn_auto_split_rows([[1,2],[3,4]], 0, Parts),
    Parts = [[[1,2],[3,4]]].

% Grid with divider at first row: empty first part, non-empty second part.
test(auto_split_rows_first_is_divider) :-
    pn_auto_split_rows([[0,0],[1,2],[3,4]], 0, Parts),
    Parts = [[], [[1,2],[3,4]]].

% pn_auto_split_cols/3 tests

% Grid with one all-0 divider column: two column panels.
test(auto_split_cols_one_divider) :-
    pn_auto_split_cols([[1,0,2],[3,0,4]], 0, Parts),
    Parts = [[[1],[3]], [[2],[4]]].

% Grid with no divider columns.
test(auto_split_cols_none) :-
    pn_auto_split_cols([[1,2],[3,4]], 0, Parts),
    Parts = [[[1,2],[3,4]]].

% Grid with divider columns at 0 and 2: empty-column bands flank the center band.
test(auto_split_cols_two) :-
    pn_auto_split_cols([[0,1,0],[0,2,0]], 0, Parts),
    Parts = [[[],[]], [[1],[2]], [[],[]]].

% pn_strip_rows/3 tests

% Remove the divider row: result has 4 rows.
test(strip_rows_one) :-
    pn_strip_rows([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, S),
    S = [[1,2],[3,4],[5,6]].

% No dividers: grid unchanged.
test(strip_rows_none) :-
    pn_strip_rows([[1,2],[3,4]], 0, S),
    S = [[1,2],[3,4]].

% All rows are dividers: result is empty.
test(strip_rows_all) :-
    pn_strip_rows([[0,0],[0,0]], 0, S),
    S = [].

% pn_strip_cols/3 tests

% Remove divider column 1: result has 2 columns.
test(strip_cols_one) :-
    pn_strip_cols([[1,0,2],[3,0,4]], 0, S),
    S = [[1,2],[3,4]].

% No dividers: grid unchanged.
test(strip_cols_none) :-
    pn_strip_cols([[1,2],[3,4]], 0, S),
    S = [[1,2],[3,4]].

% All columns are dividers: each row becomes empty.
test(strip_cols_all) :-
    pn_strip_cols([[0,0],[0,0]], 0, S),
    S = [[],[]].

% pn_quadrants/5 tests

% Split a 4x4 grid at midpoint (2,2) into four 2x2 quadrants.
test(quadrants_4x4) :-
    pn_quadrants([[1,2,3,4],[5,6,7,8],[a,b,c,d],[e,f,g,h]],
                 TL, TR, BL, BR),
    TL = [[1,2],[5,6]],
    TR = [[3,4],[7,8]],
    BL = [[a,b],[e,f]],
    BR = [[c,d],[g,h]].

% Split a 2x2 grid: each quadrant is 1x1.
test(quadrants_2x2) :-
    pn_quadrants([[1,2],[3,4]], TL, TR, BL, BR),
    TL = [[1]], TR = [[2]], BL = [[3]], BR = [[4]].

% Split a 2x4 grid at midpoints (1,2).
test(quadrants_2x4) :-
    pn_quadrants([[1,2,3,4],[5,6,7,8]], TL, TR, BL, BR),
    TL = [[1,2]], TR = [[3,4]], BL = [[5,6]], BR = [[7,8]].

% pn_n_col_parts/3 tests

% Split a 1x6 grid into 3 equal parts of width 2.
test(n_col_parts_three) :-
    pn_n_col_parts([[1,2,3,4,5,6]], 3, Parts),
    Parts = [[[1,2]], [[3,4]], [[5,6]]].

% Split a 2x4 grid into 2 parts of width 2.
test(n_col_parts_two) :-
    pn_n_col_parts([[1,2,3,4],[5,6,7,8]], 2, Parts),
    Parts = [[[1,2],[5,6]], [[3,4],[7,8]]].

% Split into 1 part = the whole grid.
test(n_col_parts_one) :-
    pn_n_col_parts([[1,2,3]], 1, Parts),
    Parts = [[[1,2,3]]].

% pn_col_slices/3 tests

% Split a 1x6 grid using widths [2,3,1].
test(col_slices_three) :-
    pn_col_slices([[1,2,3,4,5,6]], [2,3,1], Parts),
    Parts = [[[1,2]], [[3,4,5]], [[6]]].

% Split a 2x4 grid into widths [1,3].
test(col_slices_unequal) :-
    pn_col_slices([[a,b,c,d],[e,f,g,h]], [1,3], Parts),
    Parts = [[[a],[e]], [[b,c,d],[f,g,h]]].

% Single slice = whole grid width.
test(col_slices_one) :-
    pn_col_slices([[1,2,3]], [3], Parts),
    Parts = [[[1,2,3]]].

% pn_has_dividers/2 tests

% Grid with a divider row: succeeds.
test(has_dividers_row) :-
    pn_has_dividers([[1,2],[0,0],[3,4]], 0).

% Grid with a divider column: succeeds.
test(has_dividers_col) :-
    pn_has_dividers([[1,0,2],[3,0,4]], 0).

% Grid with no dividers: fails.
test(has_dividers_none, [fail]) :-
    pn_has_dividers([[1,2],[3,4]], 0).

:- end_tests(panel).
