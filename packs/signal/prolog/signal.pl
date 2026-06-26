% signal.pl - Layer 109: 1D Signal Analysis of Grid Rows and Columns (sg_* prefix).
% Provides predicates for finding local extrema, testing monotone order,
% computing consecutive differences and slope signs, locating the index of
% the maximum or minimum value, partitioning values by threshold, and
% extracting row, column, and cross-shaped value profiles from a grid.
:- module(signal, [
    sg_peaks/2,
    sg_valleys/2,
    sg_argmax/2,
    sg_argmin/2,
    sg_diffs/2,
    sg_slope_signs/2,
    sg_is_increasing/1,
    sg_is_decreasing/1,
    sg_is_nondecreasing/1,
    sg_is_nonincreasing/1,
    sg_threshold/4,
    sg_row_profile/3,
    sg_col_profile/3,
    sg_cross_profile/5
]).
% Import list utilities.
:- use_module(library(lists), [nth0/3, max_list/2, min_list/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3]).

% sg_peaks(+List, -PeakIdxs): PeakIdxs is the sorted list of 0-based indices
% of strict interior local maxima in List. A strict interior maximum at index I
% requires I > 0, I < length(List)-1, and List[I] > both neighbors.
% Returns [] for lists of length 0, 1, or 2, or when no interior maxima exist.
sg_peaks(List, PeakIdxs) :-
% Compute the range of valid interior indices (1 through length-2).
    length(List, N),
    N2 is N - 2,
    findall(I, (
% Enumerate only interior indices.
        between(1, N2, I),
        Iminus1 is I - 1,
        Iplus1 is I + 1,
        nth0(I, List, V),
        nth0(Iminus1, List, Vprev),
        nth0(Iplus1, List, Vnext),
% Strict interior maximum: value strictly exceeds both neighbors.
        V > Vprev,
        V > Vnext
    ), PeakIdxs).

% sg_valleys(+List, -ValleyIdxs): ValleyIdxs is the sorted list of 0-based
% indices of strict interior local minima. A strict interior minimum at index I
% requires I > 0, I < length(List)-1, and List[I] < both neighbors.
% Returns [] for lists of length 0, 1, or 2, or when no interior minima exist.
sg_valleys(List, ValleyIdxs) :-
% Compute the range of valid interior indices (1 through length-2).
    length(List, N),
    N2 is N - 2,
    findall(I, (
% Enumerate only interior indices.
        between(1, N2, I),
        Iminus1 is I - 1,
        Iplus1 is I + 1,
        nth0(I, List, V),
        nth0(Iminus1, List, Vprev),
        nth0(Iplus1, List, Vnext),
% Strict interior minimum: value strictly below both neighbors.
        V < Vprev,
        V < Vnext
    ), ValleyIdxs).

% sg_argmax(+List, -Idx): Idx is the 0-based index of the maximum value in
% List. On ties the first (leftmost) occurrence wins. Fails if List is empty.
sg_argmax(List, Idx) :-
% Find the maximum value first, then locate its first index.
    max_list(List, Max),
    nth0(Idx, List, Max),
    !.

% sg_argmin(+List, -Idx): Idx is the 0-based index of the minimum value in
% List. On ties the first (leftmost) occurrence wins. Fails if List is empty.
sg_argmin(List, Idx) :-
% Find the minimum value first, then locate its first index.
    min_list(List, Min),
    nth0(Idx, List, Min),
    !.

% sg_diffs(+List, -Diffs): Diffs is the list of consecutive element-wise
% differences: Diffs[i] = List[i+1] - List[i]. Length of Diffs is
% length(List) - 1. Returns [] for lists of length 0 or 1.
sg_diffs([], []) :- !.
sg_diffs([_], []) :- !.
sg_diffs([A, B | Rest], [D | Ds]) :-
% Compute the difference for the current pair.
    D is B - A,
    sg_diffs([B | Rest], Ds).

% sg_sign_: compute the sign of an integer: 1 for positive, -1 for negative, 0 for zero.
sg_sign_(D, S) :-
    (D > 0 -> S = 1 ; D < 0 -> S = -1 ; S = 0).

% sg_slope_signs(+List, -Signs): Signs is the list of slope signs for
% consecutive element pairs. Signs[i] is 1 if List[i+1] > List[i],
% -1 if List[i+1] < List[i], and 0 if they are equal.
sg_slope_signs(List, Signs) :-
% Compute differences and then map each to its sign.
    sg_diffs(List, Diffs),
    maplist(sg_sign_, Diffs, Signs).

% sg_is_increasing(+List): succeed if List is strictly increasing.
% Each element must be strictly less than the next. Vacuously true for
% lists of length 0 or 1.
sg_is_increasing([]) :- !.
sg_is_increasing([_]) :- !.
sg_is_increasing([A, B | Rest]) :-
    A < B,
    sg_is_increasing([B | Rest]).

% sg_is_decreasing(+List): succeed if List is strictly decreasing.
% Each element must be strictly greater than the next.
sg_is_decreasing([]) :- !.
sg_is_decreasing([_]) :- !.
sg_is_decreasing([A, B | Rest]) :-
    A > B,
    sg_is_decreasing([B | Rest]).

% sg_is_nondecreasing(+List): succeed if List is non-strictly increasing.
% Each element must be less than or equal to the next.
sg_is_nondecreasing([]) :- !.
sg_is_nondecreasing([_]) :- !.
sg_is_nondecreasing([A, B | Rest]) :-
    A =< B,
    sg_is_nondecreasing([B | Rest]).

% sg_is_nonincreasing(+List): succeed if List is non-strictly decreasing.
% Each element must be greater than or equal to the next.
sg_is_nonincreasing([]) :- !.
sg_is_nonincreasing([_]) :- !.
sg_is_nonincreasing([A, B | Rest]) :-
    A >= B,
    sg_is_nonincreasing([B | Rest]).

% sg_threshold(+List, +T, -AboveIdxs, -BelowOrEqIdxs): AboveIdxs is the
% sorted list of 0-based indices where List[i] > T; BelowOrEqIdxs is the
% sorted list of indices where List[i] =< T.
sg_threshold(List, T, AboveIdxs, BelowOrEqIdxs) :-
    length(List, N),
    N1 is N - 1,
% Collect indices with value strictly above T.
    findall(I, (between(0, N1, I), nth0(I, List, V), V > T), AboveIdxs),
% Collect indices with value at or below T.
    findall(I, (between(0, N1, I), nth0(I, List, V), V =< T), BelowOrEqIdxs).

% sg_row_profile(+Grid, +R, -Values): Values is the list of cell values in
% row R (0-based) of Grid.
sg_row_profile(Grid, R, Values) :-
    nth0(R, Grid, Values).

% sg_col_profile(+Grid, +C, -Values): Values is the list of cell values in
% column C (0-based) of Grid, from row 0 to the last row.
sg_col_profile(Grid, C, Values) :-
% Extract the Cth element from each row.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Values).

% sg_cross_profile(+Grid, +R, +C, -RowVals, -ColVals): RowVals is the list
% of values in row R; ColVals is the list of values in column C. Together they
% form the cross-shaped profile of cell (R, C) in the grid.
sg_cross_profile(Grid, R, C, RowVals, ColVals) :-
    sg_row_profile(Grid, R, RowVals),
    sg_col_profile(Grid, C, ColVals).
