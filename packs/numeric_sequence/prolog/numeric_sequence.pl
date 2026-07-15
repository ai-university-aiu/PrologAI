% numseq.pl - Layer 124: Numerical Sequence Operations on 1D Lists (nr_* prefix).
% General-purpose predicates for analyzing and transforming 1D numerical lists.
:- module(numeric_sequence, [
    numeric_sequence_diff/2, numeric_sequence_cumsum/2, numeric_sequence_running_max/2, numeric_sequence_running_min/2,
    numeric_sequence_zip_add/3, numeric_sequence_zip_sub/3, numeric_sequence_zip_mul/3, numeric_sequence_zip_max/3, numeric_sequence_zip_min/3,
    numeric_sequence_scale/3, numeric_sequence_offset/3,
    numeric_sequence_is_sorted/1, numeric_sequence_is_arith/1, numeric_sequence_period/3
]).
% Import higher-order operation for uniform element transforms.
:- use_module(library(apply), [maplist/3]).
% Import list utilities for period detection and index access.
:- use_module(library(lists), [nth0/3, numlist/3]).

% numeric_sequence_diff(+List, -Diffs): consecutive pairwise differences [b-a, c-b, ...].
numeric_sequence_diff([], []).
numeric_sequence_diff([_], []).
numeric_sequence_diff([A,B|T], [D|Ds]) :-
% Compute difference B-A then recurse on the tail starting from B.
    D is B - A,
    numeric_sequence_diff([B|T], Ds).

% numeric_sequence_cumsum(+List, -Sums): prefix cumulative sums; List element I -> Sums[I]=sum(List[0..I]).
numeric_sequence_cumsum([], []).
numeric_sequence_cumsum([H|T], [H|Cs]) :-
% First element is itself; recurse with running total.
    numeric_sequence_cumsum_(T, H, Cs).
% Recursive helper accumulates running total Acc.
numeric_sequence_cumsum_([], _, []).
numeric_sequence_cumsum_([H|T], Acc, [S|Cs]) :-
% Add the next element to the running total.
    S is Acc + H,
    numeric_sequence_cumsum_(T, S, Cs).

% numeric_sequence_running_max(+List, -Maxs): running maximum; Maxs[I] = max(List[0..I]).
numeric_sequence_running_max([], []).
numeric_sequence_running_max([H|T], [H|Ms]) :-
% First element is the initial maximum.
    numeric_sequence_running_max_(T, H, Ms).
% Recursive helper tracks current maximum Max0.
numeric_sequence_running_max_([], _, []).
numeric_sequence_running_max_([H|T], Max0, [Max1|Ms]) :-
% Update maximum if H exceeds the current max.
    Max1 is max(H, Max0),
    numeric_sequence_running_max_(T, Max1, Ms).

% numeric_sequence_running_min(+List, -Mins): running minimum; Mins[I] = min(List[0..I]).
numeric_sequence_running_min([], []).
numeric_sequence_running_min([H|T], [H|Ms]) :-
% First element is the initial minimum.
    numeric_sequence_running_min_(T, H, Ms).
% Recursive helper tracks current minimum Min0.
numeric_sequence_running_min_([], _, []).
numeric_sequence_running_min_([H|T], Min0, [Min1|Ms]) :-
% Update minimum if H is less than the current min.
    Min1 is min(H, Min0),
    numeric_sequence_running_min_(T, Min1, Ms).

% numeric_sequence_zip_add(+ListA, +ListB, -Sums): element-wise sum; Sums[I] = ListA[I] + ListB[I].
numeric_sequence_zip_add(A, B, C) :-
% Delegate to named helper to keep maplist/4 clean.
    maplist(numeric_sequence_add_, A, B, C).
% Per-element addition helper.
numeric_sequence_add_(X, Y, Z) :- Z is X + Y.

% numeric_sequence_zip_sub(+ListA, +ListB, -Diffs): element-wise difference A[I] - B[I].
numeric_sequence_zip_sub(A, B, C) :-
% Delegate to named helper.
    maplist(numeric_sequence_sub_, A, B, C).
% Per-element subtraction helper.
numeric_sequence_sub_(X, Y, Z) :- Z is X - Y.

% numeric_sequence_zip_mul(+ListA, +ListB, -Prods): element-wise product A[I] * B[I].
numeric_sequence_zip_mul(A, B, C) :-
% Delegate to named helper.
    maplist(numeric_sequence_mul_, A, B, C).
% Per-element multiplication helper.
numeric_sequence_mul_(X, Y, Z) :- Z is X * Y.

% numeric_sequence_zip_max(+ListA, +ListB, -Maxs): element-wise maximum max(A[I], B[I]).
numeric_sequence_zip_max(A, B, C) :-
% Delegate to named helper.
    maplist(numeric_sequence_max_, A, B, C).
% Per-element maximum helper.
numeric_sequence_max_(X, Y, Z) :- Z is max(X, Y).

% numeric_sequence_zip_min(+ListA, +ListB, -Mins): element-wise minimum min(A[I], B[I]).
numeric_sequence_zip_min(A, B, C) :-
% Delegate to named helper.
    maplist(numeric_sequence_min_, A, B, C).
% Per-element minimum helper.
numeric_sequence_min_(X, Y, Z) :- Z is min(X, Y).

% numeric_sequence_scale(+List, +K, -Scaled): multiply every element by scalar K.
numeric_sequence_scale(List, K, Scaled) :-
% Use maplist/3 with a per-element helper capturing K.
    maplist(numeric_sequence_scale_(K), List, Scaled).
% Per-element scale helper; K is captured from the outer call.
numeric_sequence_scale_(K, V, S) :- S is V * K.

% numeric_sequence_offset(+List, +D, -Shifted): add constant D to every element.
numeric_sequence_offset(List, D, Shifted) :-
% Use maplist/3 with a per-element helper capturing D.
    maplist(numeric_sequence_offset_(D), List, Shifted).
% Per-element offset helper; D is captured from the outer call.
numeric_sequence_offset_(D, V, S) :- S is V + D.

% numeric_sequence_is_sorted(+List): succeeds iff List is non-decreasing (A[I] =< A[I+1]).
numeric_sequence_is_sorted([]).
numeric_sequence_is_sorted([_]).
numeric_sequence_is_sorted([A,B|T]) :-
% Each pair must satisfy A =< B; recurse on the tail.
    A =< B,
    numeric_sequence_is_sorted([B|T]).

% numeric_sequence_is_arith(+List): succeeds iff List is an arithmetic sequence (constant diff).
numeric_sequence_is_arith([]).
numeric_sequence_is_arith([_]).
numeric_sequence_is_arith([A,B|T]) :-
% Compute the common difference then verify it holds throughout.
    D is B - A,
    numeric_sequence_is_arith_([B|T], D).
% Helper verifies remaining elements maintain the same common difference D.
numeric_sequence_is_arith_([], _).
numeric_sequence_is_arith_([_], _).
numeric_sequence_is_arith_([B,C|T], D) :-
% Check that the difference between each consecutive pair equals D.
    D2 is C - B,
    D =:= D2,
    numeric_sequence_is_arith_([C|T], D).

% numeric_sequence_period(+List, +MaxP, -P): shortest repeating period P (1..MaxP) of List.
% Fails if no period divides Len and passes the element-comparison check.
numeric_sequence_period(List, MaxP, P) :-
% Try periods in ascending order; cut on the first one that works.
    length(List, Len),
    between(1, MaxP, P),
    Len mod P =:= 0,
    numeric_sequence_check_period_(List, Len, P), !.

% numeric_sequence_check_period_: verify that each element equals the element P positions later.
numeric_sequence_check_period_(List, Len, P) :-
% For a true period P, every element at index I equals element at I+P.
    MaxI is Len - P - 1,
    (MaxI < 0
    ->  true
    ;   forall(
            between(0, MaxI, I),
            (nth0(I, List, V), I2 is I + P, nth0(I2, List, V))
        )
    ).
