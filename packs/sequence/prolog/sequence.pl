% Module sequence: arithmetic sequences, chunking, zipping, and list structure.
% Layer 48. Prefix: sq_. No pack dependencies.
:- module(sequence, [
    % Generate a list of consecutive integers from Lo to Hi inclusive.
    sq_range/3,
    % First differences: Deltas[i] = List[i+1] - List[i].
    sq_delta/2,
    % Succeed if every consecutive pair has the same difference.
    sq_is_arithmetic/1,
    % Common difference of an arithmetic sequence (fails if not arithmetic).
    sq_common_diff/2,
    % Extend an arithmetic sequence by N more terms.
    sq_extend_arith/3,
    % Group a list into consecutive chunks of exactly N elements.
    sq_chunk/3,
    % Zip two same-length lists into a list of A-B pairs.
    sq_zip/3,
    % Unzip a list of A-B pairs into two lists.
    sq_unzip/3,
    % Cumulative sums: Sums[i] = sum(List[0..i]).
    sq_cumsum/2,
    % Sublist from index From (inclusive) to To (exclusive), 0-indexed.
    sq_slice/4,
    % Flatten one level: equivalent to append/2.
    sq_flatten1/2,
    % Transpose a rectangular list-of-lists.
    sq_transpose/2,
    % Smallest period P such that List = P repeated length(List)/length(P) times.
    sq_period/2,
    % Succeed if List has a period strictly shorter than itself.
    sq_is_periodic/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2, numlist/3, last/2, append/2, append/3,
                                nth0/3, reverse/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% sq_range(+Lo, +Hi, -List)
% List is [Lo, Lo+1, ..., Hi]. List is empty if Lo > Hi.
sq_range(Lo, Hi, List) :-
    (   Lo =< Hi
    ->  numlist(Lo, Hi, List)
    ;   List = []
    ).

% sq_delta(+List, -Deltas)
% Deltas[i] = List[i+1] - List[i] for each consecutive pair.
sq_delta([_], []) :- !.
sq_delta([], []) :- !.
sq_delta([A,B|T], [D|Ds]) :-
    D is B - A,
    sq_delta([B|T], Ds).

% sq_is_arithmetic(+List)
% Succeed if every consecutive pair in List has the same difference.
% Lists of 0 or 1 element are trivially arithmetic.
sq_is_arithmetic([]) :- !.
sq_is_arithmetic([_]) :- !.
sq_is_arithmetic([A,B|T]) :-
    D is B - A,
    sq_is_arithmetic_([B|T], D).

% sq_is_arithmetic_(+List, +D)
% All consecutive differences in List equal D.
sq_is_arithmetic_([_], _) :- !.
sq_is_arithmetic_([A,B|T], D) :-
    D =:= B - A,
    sq_is_arithmetic_([B|T], D).

% sq_common_diff(+List, -D)
% D is the common difference of an arithmetic sequence.
% Fails if List has fewer than 2 elements or is not arithmetic.
sq_common_diff([A,B|T], D) :-
    D is B - A,
    sq_is_arithmetic_([B|T], D).

% sq_gen_arith_(+Prev, +D, +N, -Extra)
% Generate N more terms of an arithmetic sequence with common difference D.
sq_gen_arith_(_, _, 0, []) :- !.
sq_gen_arith_(Prev, D, N, [Next|Rest]) :-
    N > 0,
    Next is Prev + D,
    N1 is N - 1,
    sq_gen_arith_(Next, D, N1, Rest).

% sq_extend_arith(+List, +N, -Extended)
% Extended is List with N more terms appended, following the same common difference.
sq_extend_arith(List, N, Extended) :-
    sq_common_diff(List, D),
    last(List, Last),
    sq_gen_arith_(Last, D, N, Extra),
    append(List, Extra, Extended).

% sq_chunk(+List, +N, -Chunks)
% Chunks is a list of consecutive N-element sublists of List.
% Fails if length(List) is not divisible by N.
sq_chunk([], _, []) :- !.
sq_chunk(List, N, [Chunk|Chunks]) :-
    N > 0,
    length(Chunk, N),
    append(Chunk, Rest, List),
    sq_chunk(Rest, N, Chunks).

% sq_zip(+As, +Bs, -Pairs)
% Pairs is the list of A-B pairs from corresponding elements of As and Bs.
sq_zip([], [], []).
sq_zip([A|As], [B|Bs], [A-B|Ps]) :-
    sq_zip(As, Bs, Ps).

% sq_unzip(+Pairs, -As, -Bs)
% Split a list of A-B pairs into two separate lists.
sq_unzip([], [], []).
sq_unzip([A-B|Ps], [A|As], [B|Bs]) :-
    sq_unzip(Ps, As, Bs).

% sq_cumsum_h_(+Rest, +PrevSum, -Sums)
% Accumulate prefix sums for the tail of a list.
sq_cumsum_h_([], _, []).
sq_cumsum_h_([H|T], Prev, [Curr|Rest]) :-
    Curr is Prev + H,
    sq_cumsum_h_(T, Curr, Rest).

% sq_cumsum(+List, -Sums)
% Sums[i] = List[0] + List[1] + ... + List[i].
sq_cumsum([], []).
sq_cumsum([H|T], [H|Rest]) :-
    sq_cumsum_h_(T, H, Rest).

% sq_slice(+List, +From, +To, -Sub)
% Sub is elements at 0-indexed positions From, From+1, ..., To-1.
% Fails if From or To are out of range.
sq_slice(List, From, To, Sub) :-
    From >= 0,
    To >= From,
    length(Prefix, From),
    append(Prefix, Rest, List),
    Len is To - From,
    length(Sub, Len),
    append(Sub, _, Rest).

% sq_flatten1(+Lists, -Flat)
% Flat is the concatenation of all sublists in Lists (one level of flattening).
sq_flatten1(Lists, Flat) :-
    append(Lists, Flat).

% sq_head_(+List, -Head)
% Extract the head of a list. Used in sq_transpose.
sq_head_([H|_], H).

% sq_tail_(+List, -Tail)
% Extract the tail of a list. Used in sq_transpose.
sq_tail_([_|T], T).

% sq_transpose(+Matrix, -Transposed)
% Transpose a rectangular list-of-lists.
% sq_transpose([[1,2,3],[4,5,6]], T) -> T = [[1,4],[2,5],[3,6]].
sq_transpose([], []) :- !.
sq_transpose([[]|_], []) :- !.
sq_transpose(Matrix, [Row|Rows]) :-
    maplist(sq_head_, Matrix, Row),
    maplist(sq_tail_, Matrix, RestMatrix),
    sq_transpose(RestMatrix, Rows).

% sq_repeats_(+List, +Period)
% Succeed if List is exactly Period repeated (length(List)/length(Period)) times.
sq_repeats_([], _) :- !.
sq_repeats_(List, Period) :-
    append(Period, Rest, List),
    sq_repeats_(Rest, Period).

% sq_find_period_(+List, +Len, +K, -Period)
% Find the smallest period of List starting from length K.
sq_find_period_(List, Len, K, Period) :-
    K =< Len,
    (   0 is Len mod K,
        length(Period, K),
        append(Period, _, List),
        sq_repeats_(List, Period)
    ->  true
    ;   K1 is K + 1,
        sq_find_period_(List, Len, K1, Period)
    ).

% sq_period(+List, -Period)
% Period is the smallest repeating unit of List.
% sq_period([1,2,1,2], P) -> P = [1,2].
% sq_period([1,2,3], P) -> P = [1,2,3] (itself; trivial period).
sq_period(List, Period) :-
    List = [_|_],
    length(List, Len),
    sq_find_period_(List, Len, 1, Period).

% sq_is_periodic(+List)
% Succeed if List has a period strictly shorter than itself.
% Fails for lists of 0 or 1 element, and for lists with no proper period.
sq_is_periodic(List) :-
    length(List, Len),
    Len >= 2,
    sq_period(List, Period),
    length(Period, K),
    K < Len.
