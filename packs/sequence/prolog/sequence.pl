% Module sequence: arithmetic sequences, chunking, zipping, and list structure.
% Layer 48. Prefix: sq_. No pack dependencies.
:- module(sequence, [
    % Generate a list of consecutive integers from Lo to Hi inclusive.
    sequence_range/3,
    % First differences: Deltas[i] = List[i+1] - List[i].
    sequence_delta/2,
    % Succeed if every consecutive pair has the same difference.
    sequence_is_arithmetic/1,
    % Common difference of an arithmetic sequence (fails if not arithmetic).
    sequence_common_diff/2,
    % Extend an arithmetic sequence by N more terms.
    sequence_extend_arith/3,
    % Group a list into consecutive chunks of exactly N elements.
    sequence_chunk/3,
    % Zip two same-length lists into a list of A-B pairs.
    sequence_zip/3,
    % Unzip a list of A-B pairs into two lists.
    sequence_unzip/3,
    % Cumulative sums: Sums[i] = sum(List[0..i]).
    sequence_cumsum/2,
    % Sublist from index From (inclusive) to To (exclusive), 0-indexed.
    sequence_slice/4,
    % Flatten one level: equivalent to append/2.
    sequence_flatten1/2,
    % Transpose a rectangular list-of-lists.
    sequence_transpose/2,
    % Smallest period P such that List = P repeated length(List)/length(P) times.
    sequence_period/2,
    % Succeed if List has a period strictly shorter than itself.
    sequence_is_periodic/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2, numlist/3, last/2, append/2, append/3,
                                nth0/3, reverse/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% sequence_range(+Lo, +Hi, -List)
% List is [Lo, Lo+1, ..., Hi]. List is empty if Lo > Hi.
sequence_range(Lo, Hi, List) :-
    (   Lo =< Hi
    ->  numlist(Lo, Hi, List)
    ;   List = []
    ).

% sequence_delta(+List, -Deltas)
% Deltas[i] = List[i+1] - List[i] for each consecutive pair.
sequence_delta([_], []) :- !.
sequence_delta([], []) :- !.
sequence_delta([A,B|T], [D|Ds]) :-
    D is B - A,
    sequence_delta([B|T], Ds).

% sequence_is_arithmetic(+List)
% Succeed if every consecutive pair in List has the same difference.
% Lists of 0 or 1 element are trivially arithmetic.
sequence_is_arithmetic([]) :- !.
sequence_is_arithmetic([_]) :- !.
sequence_is_arithmetic([A,B|T]) :-
    D is B - A,
    sequence_is_arithmetic_([B|T], D).

% sequence_is_arithmetic_(+List, +D)
% All consecutive differences in List equal D.
sequence_is_arithmetic_([_], _) :- !.
sequence_is_arithmetic_([A,B|T], D) :-
    D =:= B - A,
    sequence_is_arithmetic_([B|T], D).

% sequence_common_diff(+List, -D)
% D is the common difference of an arithmetic sequence.
% Fails if List has fewer than 2 elements or is not arithmetic.
sequence_common_diff([A,B|T], D) :-
    D is B - A,
    sequence_is_arithmetic_([B|T], D).

% sequence_gen_arith_(+Prev, +D, +N, -Extra)
% Generate N more terms of an arithmetic sequence with common difference D.
sequence_gen_arith_(_, _, 0, []) :- !.
sequence_gen_arith_(Prev, D, N, [Next|Rest]) :-
    N > 0,
    Next is Prev + D,
    N1 is N - 1,
    sequence_gen_arith_(Next, D, N1, Rest).

% sequence_extend_arith(+List, +N, -Extended)
% Extended is List with N more terms appended, following the same common difference.
sequence_extend_arith(List, N, Extended) :-
    sequence_common_diff(List, D),
    last(List, Last),
    sequence_gen_arith_(Last, D, N, Extra),
    append(List, Extra, Extended).

% sequence_chunk(+List, +N, -Chunks)
% Chunks is a list of consecutive N-element sublists of List.
% Fails if length(List) is not divisible by N.
sequence_chunk([], _, []) :- !.
sequence_chunk(List, N, [Chunk|Chunks]) :-
    N > 0,
    length(Chunk, N),
    append(Chunk, Rest, List),
    sequence_chunk(Rest, N, Chunks).

% sequence_zip(+As, +Bs, -Pairs)
% Pairs is the list of A-B pairs from corresponding elements of As and Bs.
sequence_zip([], [], []).
sequence_zip([A|As], [B|Bs], [A-B|Ps]) :-
    sequence_zip(As, Bs, Ps).

% sequence_unzip(+Pairs, -As, -Bs)
% Split a list of A-B pairs into two separate lists.
sequence_unzip([], [], []).
sequence_unzip([A-B|Ps], [A|As], [B|Bs]) :-
    sequence_unzip(Ps, As, Bs).

% sequence_cumsum_h_(+Rest, +PrevSum, -Sums)
% Accumulate prefix sums for the tail of a list.
sequence_cumsum_h_([], _, []).
sequence_cumsum_h_([H|T], Prev, [Curr|Rest]) :-
    Curr is Prev + H,
    sequence_cumsum_h_(T, Curr, Rest).

% sequence_cumsum(+List, -Sums)
% Sums[i] = List[0] + List[1] + ... + List[i].
sequence_cumsum([], []).
sequence_cumsum([H|T], [H|Rest]) :-
    sequence_cumsum_h_(T, H, Rest).

% sequence_slice(+List, +From, +To, -Sub)
% Sub is elements at 0-indexed positions From, From+1, ..., To-1.
% Fails if From or To are out of range.
sequence_slice(List, From, To, Sub) :-
    From >= 0,
    To >= From,
    length(Prefix, From),
    append(Prefix, Rest, List),
    Len is To - From,
    length(Sub, Len),
    append(Sub, _, Rest).

% sequence_flatten1(+Lists, -Flat)
% Flat is the concatenation of all sublists in Lists (one level of flattening).
sequence_flatten1(Lists, Flat) :-
    append(Lists, Flat).

% sequence_head_(+List, -Head)
% Extract the head of a list. Used in sequence_transpose.
sequence_head_([H|_], H).

% sequence_tail_(+List, -Tail)
% Extract the tail of a list. Used in sequence_transpose.
sequence_tail_([_|T], T).

% sequence_transpose(+Matrix, -Transposed)
% Transpose a rectangular list-of-lists.
% sequence_transpose([[1,2,3],[4,5,6]], T) -> T = [[1,4],[2,5],[3,6]].
sequence_transpose([], []) :- !.
sequence_transpose([[]|_], []) :- !.
sequence_transpose(Matrix, [Row|Rows]) :-
    maplist(sequence_head_, Matrix, Row),
    maplist(sequence_tail_, Matrix, RestMatrix),
    sequence_transpose(RestMatrix, Rows).

% sequence_repeats_(+List, +Period)
% Succeed if List is exactly Period repeated (length(List)/length(Period)) times.
sequence_repeats_([], _) :- !.
sequence_repeats_(List, Period) :-
    append(Period, Rest, List),
    sequence_repeats_(Rest, Period).

% sequence_find_period_(+List, +Len, +K, -Period)
% Find the smallest period of List starting from length K.
sequence_find_period_(List, Len, K, Period) :-
    K =< Len,
    (   0 is Len mod K,
        length(Period, K),
        append(Period, _, List),
        sequence_repeats_(List, Period)
    ->  true
    ;   K1 is K + 1,
        sequence_find_period_(List, Len, K1, Period)
    ).

% sequence_period(+List, -Period)
% Period is the smallest repeating unit of List.
% sequence_period([1,2,1,2], P) -> P = [1,2].
% sequence_period([1,2,3], P) -> P = [1,2,3] (itself; trivial period).
sequence_period(List, Period) :-
    List = [_|_],
    length(List, Len),
    sequence_find_period_(List, Len, 1, Period).

% sequence_is_periodic(+List)
% Succeed if List has a period strictly shorter than itself.
% Fails for lists of 0 or 1 element, and for lists with no proper period.
sequence_is_periodic(List) :-
    length(List, Len),
    Len >= 2,
    sequence_period(List, Period),
    length(Period, K),
    K < Len.
