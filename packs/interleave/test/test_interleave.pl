:- use_module('../prolog/interleave').

:- begin_tests(interleave).

% il_rows/3 tests

% Interleave rows of two 2-row grids: [A0,B0,A1,B1].
test(rows_two_each) :-
    il_rows([[1,2],[3,4]], [[5,6],[7,8]], R),
    R = [[1,2],[5,6],[3,4],[7,8]].

% Interleave rows of two single-row grids: [A0,B0].
test(rows_one_each) :-
    il_rows([[1,2,3]], [[4,5,6]], R),
    R = [[1,2,3],[4,5,6]].

% Interleave rows of two empty grids: result is empty.
test(rows_empty) :-
    il_rows([], [], R),
    R = [].

% il_cols/3 tests

% Interleave columns of two 2x2 grids: each row gets interleaved elements.
test(cols_2x2) :-
    il_cols([[1,2],[3,4]], [[5,6],[7,8]], R),
    R = [[1,5,2,6],[3,7,4,8]].

% Interleave columns of two 1x3 grids.
test(cols_1x3) :-
    il_cols([[1,2,3]], [[4,5,6]], R),
    R = [[1,4,2,5,3,6]].

% Interleave columns of two 2x1 grids (single column each).
test(cols_2x1) :-
    il_cols([[1],[2]], [[3],[4]], R),
    R = [[1,3],[2,4]].

% il_derows/3 tests

% Split a 4-row grid into rows 0,2 and rows 1,3.
test(derows_four) :-
    il_derows([[a],[b],[c],[d]], E, O),
    E = [[a],[c]], O = [[b],[d]].

% Single row goes entirely to Even.
test(derows_one) :-
    il_derows([[1,2]], E, O),
    E = [[1,2]], O = [].

% Odd-count rows: 3 rows -> Even has 2 (indices 0,2), Odd has 1 (index 1).
test(derows_three) :-
    il_derows([[r0],[r1],[r2]], E, O),
    E = [[r0],[r2]], O = [[r1]].

% il_decols/3 tests

% Split each row into even-indexed and odd-indexed elements (4 columns).
test(decols_four) :-
    il_decols([[1,2,3,4]], E, O),
    E = [[1,3]], O = [[2,4]].

% Single column: all goes to Even.
test(decols_one) :-
    il_decols([[9]], E, O),
    E = [[9]], O = [[]].

% Three columns: Even gets indices 0 and 2, Odd gets index 1.
test(decols_three) :-
    il_decols([[a,b,c],[d,e,f]], E, O),
    E = [[a,c],[d,f]], O = [[b],[e]].

% il_weave_rows/3 tests

% Weave 3 rows with background 0: result is 5 rows with background rows inserted.
test(weave_rows_three) :-
    il_weave_rows([[1,2],[3,4],[5,6]], 0, W),
    W = [[1,2],[0,0],[3,4],[0,0],[5,6]].

% Single row needs no separator: returned unchanged.
test(weave_rows_one) :-
    il_weave_rows([[1,2,3]], 0, W),
    W = [[1,2,3]].

% Empty grid stays empty.
test(weave_rows_empty) :-
    il_weave_rows([], 9, W),
    W = [].

% il_weave_cols/3 tests

% Weave a 2x3 grid with background 0: each row becomes length 5.
test(weave_cols_2x3) :-
    il_weave_cols([[1,2,3],[4,5,6]], 0, W),
    W = [[1,0,2,0,3],[4,0,5,0,6]].

% Single column row stays single: no separator added.
test(weave_cols_one) :-
    il_weave_cols([[7]], 0, W),
    W = [[7]].

% Two-column row becomes three-column row.
test(weave_cols_two) :-
    il_weave_cols([[1,2]], 0, W),
    W = [[1,0,2]].

% il_unweave_rows/2 tests

% Unweave a 5-row grid (woven from 3 rows): recover rows 0, 2, 4.
test(unweave_rows_five) :-
    il_unweave_rows([[1,2],[0,0],[3,4],[0,0],[5,6]], Core),
    Core = [[1,2],[3,4],[5,6]].

% Single row stays single.
test(unweave_rows_one) :-
    il_unweave_rows([[1,2,3]], Core),
    Core = [[1,2,3]].

% Four-row grid: keep rows at indices 0 and 2.
test(unweave_rows_four) :-
    il_unweave_rows([[a],[b],[c],[d]], Core),
    Core = [[a],[c]].

% il_unweave_cols/2 tests

% Unweave a row of 5 elements: keep elements at indices 0, 2, 4.
test(unweave_cols_five) :-
    il_unweave_cols([[1,0,2,0,3]], Core),
    Core = [[1,2,3]].

% Single element: returned unchanged.
test(unweave_cols_one) :-
    il_unweave_cols([[5]], Core),
    Core = [[5]].

% Four-element row: keep indices 0 and 2.
test(unweave_cols_four) :-
    il_unweave_cols([[a,b,c,d]], Core),
    Core = [[a,c]].

% il_stride_rows/4 tests

% Every 2nd row from index 0 of a 4-row grid: rows 0 and 2.
test(stride_rows_step2_start0) :-
    il_stride_rows([[r0],[r1],[r2],[r3]], 2, 0, S),
    S = [[r0],[r2]].

% Every 2nd row from index 1: rows 1 and 3.
test(stride_rows_step2_start1) :-
    il_stride_rows([[r0],[r1],[r2],[r3]], 2, 1, S),
    S = [[r1],[r3]].

% Stride 1 from start 0: all rows.
test(stride_rows_step1) :-
    il_stride_rows([[a],[b],[c]], 1, 0, S),
    S = [[a],[b],[c]].

% il_stride_cols/4 tests

% Every 2nd column from index 0 of a 1x4 grid: columns 0 and 2.
test(stride_cols_step2_start0) :-
    il_stride_cols([[1,2,3,4]], 2, 0, S),
    S = [[1,3]].

% Every 2nd column from index 1: columns 1 and 3.
test(stride_cols_step2_start1) :-
    il_stride_cols([[1,2,3,4]], 2, 1, S),
    S = [[2,4]].

% Stride 1 from start 0 in a 2x3 grid: all columns.
test(stride_cols_step1) :-
    il_stride_cols([[1,2,3],[4,5,6]], 1, 0, S),
    S = [[1,2,3],[4,5,6]].

% il_select_rows/3 tests

% Select rows 0 and 2 from a 3-row grid.
test(select_rows_0_and_2) :-
    il_select_rows([[r0],[r1],[r2]], [0,2], S),
    S = [[r0],[r2]].

% Select only row 1 from a 3-row grid.
test(select_rows_middle) :-
    il_select_rows([[a],[b],[c]], [1], S),
    S = [[b]].

% Select all rows in order [0,1,2].
test(select_rows_all) :-
    il_select_rows([[x],[y],[z]], [0,1,2], S),
    S = [[x],[y],[z]].

% il_select_cols/3 tests

% Select columns 0 and 2 from a 1x3 grid.
test(select_cols_0_and_2) :-
    il_select_cols([[a,b,c]], [0,2], S),
    S = [[a,c]].

% Select only column 1 from a 2x3 grid.
test(select_cols_middle) :-
    il_select_cols([[1,2,3],[4,5,6]], [1], S),
    S = [[2],[5]].

% Select all columns in order [0,1,2].
test(select_cols_all) :-
    il_select_cols([[p,q,r]], [0,1,2], S),
    S = [[p,q,r]].

% il_rows_n/2 tests

% Round-robin interleave 3 two-row grids: G1[0],G2[0],G3[0],G1[1],G2[1],G3[1].
test(rows_n_three_grids) :-
    il_rows_n([[[a],[b]],[[c],[d]],[[e],[f]]], R),
    R = [[a],[c],[e],[b],[d],[f]].

% Round-robin interleave 2 single-row grids: G1[0], G2[0].
test(rows_n_two_grids) :-
    il_rows_n([[[1,2]],[[3,4]]], R),
    R = [[1,2],[3,4]].

% Empty grid list yields empty result.
test(rows_n_empty) :-
    il_rows_n([], R),
    R = [].

% il_block_rows/3 tests

% Partition 6 rows into blocks of 2: three blocks.
test(block_rows_even) :-
    il_block_rows([[r0],[r1],[r2],[r3],[r4],[r5]], 2, Bs),
    Bs = [[[r0],[r1]],[[r2],[r3]],[[r4],[r5]]].

% Partition 5 rows into blocks of 2: last block has 1 row.
test(block_rows_partial) :-
    il_block_rows([[a],[b],[c],[d],[e]], 2, Bs),
    Bs = [[[a],[b]],[[c],[d]],[[e]]].

% Partition 3 rows into blocks of 3: one full block.
test(block_rows_one_block) :-
    il_block_rows([[1,2],[3,4],[5,6]], 3, Bs),
    Bs = [[[1,2],[3,4],[5,6]]].

:- end_tests(interleave).
