:- use_module('../prolog/signal').

:- begin_tests(signal).

% sg_peaks/2 tests

% A list with one interior peak at index 1.
test(peaks_one) :-
    sg_peaks([1,3,1], PeakIdxs),
    PeakIdxs = [1].

% A strictly increasing list has no interior peaks.
test(peaks_none) :-
    sg_peaks([1,2,3], PeakIdxs),
    PeakIdxs = [].

% A list with two alternating peaks at indices 1 and 3.
test(peaks_two) :-
    sg_peaks([1,3,1,3,1], PeakIdxs),
    PeakIdxs = [1,3].

% sg_valleys/2 tests

% A list with one interior valley at index 1.
test(valleys_one) :-
    sg_valleys([3,1,3], ValleyIdxs),
    ValleyIdxs = [1].

% A strictly decreasing list has no interior valleys.
test(valleys_none) :-
    sg_valleys([3,2,1], ValleyIdxs),
    ValleyIdxs = [].

% A two-element list has no interior points and thus no valleys.
test(valleys_short) :-
    sg_valleys([5,1], ValleyIdxs),
    ValleyIdxs = [].

% sg_argmax/2 tests

% Maximum is at index 1.
test(argmax_middle) :-
    sg_argmax([1,3,2], Idx),
    Idx = 1.

% On ties, first index wins.
test(argmax_tie) :-
    sg_argmax([3,3,3], Idx),
    Idx = 0.

% Maximum at the last position.
test(argmax_last) :-
    sg_argmax([0,0,5], Idx),
    Idx = 2.

% sg_argmin/2 tests

% Minimum is at index 1.
test(argmin_middle) :-
    sg_argmin([3,1,2], Idx),
    Idx = 1.

% On ties, first index wins.
test(argmin_tie) :-
    sg_argmin([1,1,1], Idx),
    Idx = 0.

% Minimum at the first position.
test(argmin_first) :-
    sg_argmin([0,2,5], Idx),
    Idx = 0.

% sg_diffs/2 tests

% Consecutive differences of an increasing list.
test(diffs_increasing) :-
    sg_diffs([1,3,6], Diffs),
    Diffs = [2,3].

% Consecutive differences of a decreasing list.
test(diffs_decreasing) :-
    sg_diffs([5,3,1], Diffs),
    Diffs = [-2,-2].

% A single-element list has no differences.
test(diffs_single) :-
    sg_diffs([5], Diffs),
    Diffs = [].

% sg_slope_signs/2 tests

% Increasing list gives all +1 signs.
test(slope_signs_increasing) :-
    sg_slope_signs([1,3,6], Signs),
    Signs = [1,1].

% Decreasing list gives all -1 signs.
test(slope_signs_decreasing) :-
    sg_slope_signs([5,3,1], Signs),
    Signs = [-1,-1].

% Mixed sequence gives mixed signs.
test(slope_signs_mixed) :-
    sg_slope_signs([1,2,2,1], Signs),
    Signs = [1,0,-1].

% sg_is_increasing/1 tests

% Strictly increasing list succeeds.
test(is_increasing_yes) :-
    sg_is_increasing([1,2,3]).

% List with an equal pair fails for strict increase.
test(is_increasing_no, [fail]) :-
    sg_is_increasing([1,1,3]).

% Single element is vacuously increasing.
test(is_increasing_single) :-
    sg_is_increasing([5]).

% sg_is_decreasing/1 tests

% Strictly decreasing succeeds.
test(is_decreasing_yes) :-
    sg_is_decreasing([3,2,1]).

% Increasing list fails for decreasing test.
test(is_decreasing_no, [fail]) :-
    sg_is_decreasing([1,2,3]).

% Single element is vacuously decreasing.
test(is_decreasing_single) :-
    sg_is_decreasing([7]).

% sg_is_nondecreasing/1 tests

% A list with equal adjacent elements passes non-decreasing.
test(is_nondecreasing_equal) :-
    sg_is_nondecreasing([1,1,2]).

% A list that dips fails non-decreasing.
test(is_nondecreasing_fail, [fail]) :-
    sg_is_nondecreasing([1,0,2]).

% Strictly increasing also qualifies as non-decreasing.
test(is_nondecreasing_strict) :-
    sg_is_nondecreasing([1,2,3]).

% sg_is_nonincreasing/1 tests

% A list with equal adjacent elements passes non-increasing.
test(is_nonincreasing_equal) :-
    sg_is_nonincreasing([3,3,2]).

% A list that rises fails non-increasing.
test(is_nonincreasing_fail, [fail]) :-
    sg_is_nonincreasing([3,4,3]).

% Strictly decreasing qualifies as non-increasing.
test(is_nonincreasing_strict) :-
    sg_is_nonincreasing([3,2,1]).

% sg_threshold/4 tests

% Values 5 and 7 are above T=4; values 1, 3, 2 are at or below.
test(threshold_mixed) :-
    sg_threshold([1,5,3,7,2], 4, Above, Below),
    Above = [1,3],
    Below = [0,2,4].

% T=0 puts all positive values above and nothing below.
test(threshold_all_above) :-
    sg_threshold([1,2,3], 0, Above, Below),
    Above = [0,1,2],
    Below = [].

% T=10 puts all values below and nothing above.
test(threshold_all_below) :-
    sg_threshold([1,2,3], 10, Above, Below),
    Above = [],
    Below = [0,1,2].

% sg_row_profile/3 tests

% Extract the second row (index 1) of a 2x3 grid.
test(row_profile_second) :-
    sg_row_profile([[1,2,3],[4,5,6]], 1, V),
    V = [4,5,6].

% Extract the first row (index 0).
test(row_profile_first) :-
    sg_row_profile([[7,8,9],[1,2,3]], 0, V),
    V = [7,8,9].

% Extract a single-cell row.
test(row_profile_single) :-
    sg_row_profile([[5],[6],[7]], 2, V),
    V = [7].

% sg_col_profile/3 tests

% Extract column 1 (second column) of a 3x3 grid.
test(col_profile_middle) :-
    sg_col_profile([[1,2,3],[4,5,6],[7,8,9]], 1, V),
    V = [2,5,8].

% Extract column 0 (first column).
test(col_profile_first) :-
    sg_col_profile([[1,2,3],[4,5,6]], 0, V),
    V = [1,4].

% Extract the last column (index 2) of a 3-column grid.
test(col_profile_last) :-
    sg_col_profile([[1,2,3],[4,5,6],[7,8,9]], 2, V),
    V = [3,6,9].

% sg_cross_profile/5 tests

% Cross at center (1,1) of a 3x3 grid: row 1 and column 1.
test(cross_center) :-
    sg_cross_profile([[1,2,3],[4,5,6],[7,8,9]], 1, 1, RowVals, ColVals),
    RowVals = [4,5,6],
    ColVals = [2,5,8].

% Cross at top-left (0,0): row 0 and column 0.
test(cross_corner) :-
    sg_cross_profile([[1,2,3],[4,5,6],[7,8,9]], 0, 0, RowVals, ColVals),
    RowVals = [1,2,3],
    ColVals = [1,4,7].

% Cross in a 2x3 grid at (0,2).
test(cross_edge) :-
    sg_cross_profile([[1,2,3],[4,5,6]], 0, 2, RowVals, ColVals),
    RowVals = [1,2,3],
    ColVals = [3,6].

:- end_tests(signal).
