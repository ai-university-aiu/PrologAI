% numseq.pl - Layer 124: Numerical Sequence Operations on 1D Lists (nr_* prefix).
% General-purpose predicates for analyzing and transforming 1D numerical lists.
:- module(numseq, [
    nr_diff/2, nr_cumsum/2, nr_running_max/2, nr_running_min/2,
    nr_zip_add/3, nr_zip_sub/3, nr_zip_mul/3, nr_zip_max/3, nr_zip_min/3,
    nr_scale/3, nr_offset/3,
    nr_is_sorted/1, nr_is_arith/1, nr_period/3
]).
% Import higher-order operation for uniform element transforms.
:- use_module(library(apply), [maplist/3]).
% Import list utilities for period detection and index access.
:- use_module(library(lists), [nth0/3, numlist/3]).

% nr_diff(+List, -Diffs): consecutive pairwise differences [b-a, c-b, ...].
nr_diff([], []).
nr_diff([_], []).
nr_diff([A,B|T], [D|Ds]) :-
% Compute difference B-A then recurse on the tail starting from B.
    D is B - A,
    nr_diff([B|T], Ds).

% nr_cumsum(+List, -Sums): prefix cumulative sums; List element I -> Sums[I]=sum(List[0..I]).
nr_cumsum([], []).
nr_cumsum([H|T], [H|Cs]) :-
% First element is itself; recurse with running total.
    nr_cumsum_(T, H, Cs).
% Recursive helper accumulates running total Acc.
nr_cumsum_([], _, []).
nr_cumsum_([H|T], Acc, [S|Cs]) :-
% Add the next element to the running total.
    S is Acc + H,
    nr_cumsum_(T, S, Cs).

% nr_running_max(+List, -Maxs): running maximum; Maxs[I] = max(List[0..I]).
nr_running_max([], []).
nr_running_max([H|T], [H|Ms]) :-
% First element is the initial maximum.
    nr_running_max_(T, H, Ms).
% Recursive helper tracks current maximum Max0.
nr_running_max_([], _, []).
nr_running_max_([H|T], Max0, [Max1|Ms]) :-
% Update maximum if H exceeds the current max.
    Max1 is max(H, Max0),
    nr_running_max_(T, Max1, Ms).

% nr_running_min(+List, -Mins): running minimum; Mins[I] = min(List[0..I]).
nr_running_min([], []).
nr_running_min([H|T], [H|Ms]) :-
% First element is the initial minimum.
    nr_running_min_(T, H, Ms).
% Recursive helper tracks current minimum Min0.
nr_running_min_([], _, []).
nr_running_min_([H|T], Min0, [Min1|Ms]) :-
% Update minimum if H is less than the current min.
    Min1 is min(H, Min0),
    nr_running_min_(T, Min1, Ms).

% nr_zip_add(+ListA, +ListB, -Sums): element-wise sum; Sums[I] = ListA[I] + ListB[I].
nr_zip_add(A, B, C) :-
% Delegate to named helper to keep maplist/4 clean.
    maplist(nr_add_, A, B, C).
% Per-element addition helper.
nr_add_(X, Y, Z) :- Z is X + Y.

% nr_zip_sub(+ListA, +ListB, -Diffs): element-wise difference A[I] - B[I].
nr_zip_sub(A, B, C) :-
% Delegate to named helper.
    maplist(nr_sub_, A, B, C).
% Per-element subtraction helper.
nr_sub_(X, Y, Z) :- Z is X - Y.

% nr_zip_mul(+ListA, +ListB, -Prods): element-wise product A[I] * B[I].
nr_zip_mul(A, B, C) :-
% Delegate to named helper.
    maplist(nr_mul_, A, B, C).
% Per-element multiplication helper.
nr_mul_(X, Y, Z) :- Z is X * Y.

% nr_zip_max(+ListA, +ListB, -Maxs): element-wise maximum max(A[I], B[I]).
nr_zip_max(A, B, C) :-
% Delegate to named helper.
    maplist(nr_max_, A, B, C).
% Per-element maximum helper.
nr_max_(X, Y, Z) :- Z is max(X, Y).

% nr_zip_min(+ListA, +ListB, -Mins): element-wise minimum min(A[I], B[I]).
nr_zip_min(A, B, C) :-
% Delegate to named helper.
    maplist(nr_min_, A, B, C).
% Per-element minimum helper.
nr_min_(X, Y, Z) :- Z is min(X, Y).

% nr_scale(+List, +K, -Scaled): multiply every element by scalar K.
nr_scale(List, K, Scaled) :-
% Use maplist/3 with a per-element helper capturing K.
    maplist(nr_scale_(K), List, Scaled).
% Per-element scale helper; K is captured from the outer call.
nr_scale_(K, V, S) :- S is V * K.

% nr_offset(+List, +D, -Shifted): add constant D to every element.
nr_offset(List, D, Shifted) :-
% Use maplist/3 with a per-element helper capturing D.
    maplist(nr_offset_(D), List, Shifted).
% Per-element offset helper; D is captured from the outer call.
nr_offset_(D, V, S) :- S is V + D.

% nr_is_sorted(+List): succeeds iff List is non-decreasing (A[I] =< A[I+1]).
nr_is_sorted([]).
nr_is_sorted([_]).
nr_is_sorted([A,B|T]) :-
% Each pair must satisfy A =< B; recurse on the tail.
    A =< B,
    nr_is_sorted([B|T]).

% nr_is_arith(+List): succeeds iff List is an arithmetic sequence (constant diff).
nr_is_arith([]).
nr_is_arith([_]).
nr_is_arith([A,B|T]) :-
% Compute the common difference then verify it holds throughout.
    D is B - A,
    nr_is_arith_([B|T], D).
% Helper verifies remaining elements maintain the same common difference D.
nr_is_arith_([], _).
nr_is_arith_([_], _).
nr_is_arith_([B,C|T], D) :-
% Check that the difference between each consecutive pair equals D.
    D2 is C - B,
    D =:= D2,
    nr_is_arith_([C|T], D).

% nr_period(+List, +MaxP, -P): shortest repeating period P (1..MaxP) of List.
% Fails if no period divides Len and passes the element-comparison check.
nr_period(List, MaxP, P) :-
% Try periods in ascending order; cut on the first one that works.
    length(List, Len),
    between(1, MaxP, P),
    Len mod P =:= 0,
    nr_check_period_(List, Len, P), !.

% nr_check_period_: verify that each element equals the element P positions later.
nr_check_period_(List, Len, P) :-
% For a true period P, every element at index I equals element at I+P.
    MaxI is Len - P - 1,
    (MaxI < 0
    ->  true
    ;   forall(
            between(0, MaxI, I),
            (nth0(I, List, V), I2 is I + P, nth0(I2, List, V))
        )
    ).
