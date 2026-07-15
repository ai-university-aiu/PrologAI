% numseq.pl - Layer 124: Numerical Sequence Operations on 1D Lists (nr_* prefix).
% General-purpose predicates for analyzing and transforming 1D numerical lists.
:- module(numseq, [
    numseq_diff/2, numseq_cumsum/2, numseq_running_max/2, numseq_running_min/2,
    numseq_zip_add/3, numseq_zip_sub/3, numseq_zip_mul/3, numseq_zip_max/3, numseq_zip_min/3,
    numseq_scale/3, numseq_offset/3,
    numseq_is_sorted/1, numseq_is_arith/1, numseq_period/3
]).
% Import higher-order operation for uniform element transforms.
:- use_module(library(apply), [maplist/3]).
% Import list utilities for period detection and index access.
:- use_module(library(lists), [nth0/3, numlist/3]).

% numseq_diff(+List, -Diffs): consecutive pairwise differences [b-a, c-b, ...].
numseq_diff([], []).
numseq_diff([_], []).
numseq_diff([A,B|T], [D|Ds]) :-
% Compute difference B-A then recurse on the tail starting from B.
    D is B - A,
    numseq_diff([B|T], Ds).

% numseq_cumsum(+List, -Sums): prefix cumulative sums; List element I -> Sums[I]=sum(List[0..I]).
numseq_cumsum([], []).
numseq_cumsum([H|T], [H|Cs]) :-
% First element is itself; recurse with running total.
    numseq_cumsum_(T, H, Cs).
% Recursive helper accumulates running total Acc.
numseq_cumsum_([], _, []).
numseq_cumsum_([H|T], Acc, [S|Cs]) :-
% Add the next element to the running total.
    S is Acc + H,
    numseq_cumsum_(T, S, Cs).

% numseq_running_max(+List, -Maxs): running maximum; Maxs[I] = max(List[0..I]).
numseq_running_max([], []).
numseq_running_max([H|T], [H|Ms]) :-
% First element is the initial maximum.
    numseq_running_max_(T, H, Ms).
% Recursive helper tracks current maximum Max0.
numseq_running_max_([], _, []).
numseq_running_max_([H|T], Max0, [Max1|Ms]) :-
% Update maximum if H exceeds the current max.
    Max1 is max(H, Max0),
    numseq_running_max_(T, Max1, Ms).

% numseq_running_min(+List, -Mins): running minimum; Mins[I] = min(List[0..I]).
numseq_running_min([], []).
numseq_running_min([H|T], [H|Ms]) :-
% First element is the initial minimum.
    numseq_running_min_(T, H, Ms).
% Recursive helper tracks current minimum Min0.
numseq_running_min_([], _, []).
numseq_running_min_([H|T], Min0, [Min1|Ms]) :-
% Update minimum if H is less than the current min.
    Min1 is min(H, Min0),
    numseq_running_min_(T, Min1, Ms).

% numseq_zip_add(+ListA, +ListB, -Sums): element-wise sum; Sums[I] = ListA[I] + ListB[I].
numseq_zip_add(A, B, C) :-
% Delegate to named helper to keep maplist/4 clean.
    maplist(numseq_add_, A, B, C).
% Per-element addition helper.
numseq_add_(X, Y, Z) :- Z is X + Y.

% numseq_zip_sub(+ListA, +ListB, -Diffs): element-wise difference A[I] - B[I].
numseq_zip_sub(A, B, C) :-
% Delegate to named helper.
    maplist(numseq_sub_, A, B, C).
% Per-element subtraction helper.
numseq_sub_(X, Y, Z) :- Z is X - Y.

% numseq_zip_mul(+ListA, +ListB, -Prods): element-wise product A[I] * B[I].
numseq_zip_mul(A, B, C) :-
% Delegate to named helper.
    maplist(numseq_mul_, A, B, C).
% Per-element multiplication helper.
numseq_mul_(X, Y, Z) :- Z is X * Y.

% numseq_zip_max(+ListA, +ListB, -Maxs): element-wise maximum max(A[I], B[I]).
numseq_zip_max(A, B, C) :-
% Delegate to named helper.
    maplist(numseq_max_, A, B, C).
% Per-element maximum helper.
numseq_max_(X, Y, Z) :- Z is max(X, Y).

% numseq_zip_min(+ListA, +ListB, -Mins): element-wise minimum min(A[I], B[I]).
numseq_zip_min(A, B, C) :-
% Delegate to named helper.
    maplist(numseq_min_, A, B, C).
% Per-element minimum helper.
numseq_min_(X, Y, Z) :- Z is min(X, Y).

% numseq_scale(+List, +K, -Scaled): multiply every element by scalar K.
numseq_scale(List, K, Scaled) :-
% Use maplist/3 with a per-element helper capturing K.
    maplist(numseq_scale_(K), List, Scaled).
% Per-element scale helper; K is captured from the outer call.
numseq_scale_(K, V, S) :- S is V * K.

% numseq_offset(+List, +D, -Shifted): add constant D to every element.
numseq_offset(List, D, Shifted) :-
% Use maplist/3 with a per-element helper capturing D.
    maplist(numseq_offset_(D), List, Shifted).
% Per-element offset helper; D is captured from the outer call.
numseq_offset_(D, V, S) :- S is V + D.

% numseq_is_sorted(+List): succeeds iff List is non-decreasing (A[I] =< A[I+1]).
numseq_is_sorted([]).
numseq_is_sorted([_]).
numseq_is_sorted([A,B|T]) :-
% Each pair must satisfy A =< B; recurse on the tail.
    A =< B,
    numseq_is_sorted([B|T]).

% numseq_is_arith(+List): succeeds iff List is an arithmetic sequence (constant diff).
numseq_is_arith([]).
numseq_is_arith([_]).
numseq_is_arith([A,B|T]) :-
% Compute the common difference then verify it holds throughout.
    D is B - A,
    numseq_is_arith_([B|T], D).
% Helper verifies remaining elements maintain the same common difference D.
numseq_is_arith_([], _).
numseq_is_arith_([_], _).
numseq_is_arith_([B,C|T], D) :-
% Check that the difference between each consecutive pair equals D.
    D2 is C - B,
    D =:= D2,
    numseq_is_arith_([C|T], D).

% numseq_period(+List, +MaxP, -P): shortest repeating period P (1..MaxP) of List.
% Fails if no period divides Len and passes the element-comparison check.
numseq_period(List, MaxP, P) :-
% Try periods in ascending order; cut on the first one that works.
    length(List, Len),
    between(1, MaxP, P),
    Len mod P =:= 0,
    numseq_check_period_(List, Len, P), !.

% numseq_check_period_: verify that each element equals the element P positions later.
numseq_check_period_(List, Len, P) :-
% For a true period P, every element at index I equals element at I+P.
    MaxI is Len - P - 1,
    (MaxI < 0
    ->  true
    ;   forall(
            between(0, MaxI, I),
            (nth0(I, List, V), I2 is I + P, nth0(I2, List, V))
        )
    ).
