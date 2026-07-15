% weave.pl - Layer 160: List Interlacing, Slicing, and Cycling (wv_* prefix).
% General-purpose predicates for interleaving two lists, splitting into
% even/odd indexed positions, striding through a list at a fixed step,
% chunking into sub-lists, extracting sliding windows of width 2 and 3,
% rotating left or right, reflecting, repeating, taking, dropping,
% cycling to a target length, and zipping two lists into pairs.
% All predicates work on any list; no dependency on obj() terms.
:- module(weave, [
    weave_alternate/3,
    weave_split_even_odd/3,
    weave_stride/3,
    weave_chunk/3,
    weave_pair_wise/2,
    weave_triple_wise/2,
    weave_rotate_left/3,
    weave_rotate_right/3,
    weave_reflect/2,
    weave_repeat/3,
    weave_take/3,
    weave_drop/3,
    weave_cycle/3,
    weave_zip/3
]).
% Import list utilities; length/2, msort/2, between/3 are built-ins, not imported.
:- use_module(library(lists), [reverse/2, append/3, member/2]).

% weave_alternate(+L1, +L2, -Result): interleave elements of L1 and L2 alternately.
% Result = [L1[0], L2[0], L1[1], L2[1], ...]; when one list runs out, the
% remaining elements of the other list are appended at the end.
% Base case: L1 is exhausted; append all remaining L2 elements.
weave_alternate([], Rest, Rest).
% Recursive case: place the head of L1, then swap roles to interleave L2 next.
weave_alternate([H|T], L2, [H|Result]) :-
    weave_alternate(L2, T, Result).

% weave_split_even_odd(+List, -Evens, -Odds): split List into elements at even
% indices (0, 2, 4, ...) and odd indices (1, 3, 5, ...) using 0-based indexing.
% Base case: empty list yields empty Evens and Odds.
weave_split_even_odd([], [], []).
% At each step the head goes to Evens; the Evens and Odds roles are swapped for
% the recursive call so the next element goes to Odds, and so on alternately.
weave_split_even_odd([H|T], [H|Evens], Odds) :-
    weave_split_even_odd(T, Odds, Evens).

% weave_stride(+List, +Step, -Result): collect every Step-th element starting at
% index 0. Step must be >= 1. e.g. weave_stride([a,b,c,d,e,f], 2, [a,c,e]).
% Base case: empty list yields empty result.
weave_stride([], _, []) :- !.
% Take the head, skip the next Step-1 elements using the private helper, recurse.
weave_stride([H|T], Step, [H|Rest]) :-
    Step > 0,
    Skip is Step - 1,
    weave_drop_(T, Skip, Remaining),
    weave_stride(Remaining, Step, Rest).

% weave_drop_(+List, +N, -Rest): drop the first N elements; private helper for stride.
% Base case: drop 0 elements leaves the list unchanged.
weave_drop_(List, 0, List) :- !.
% Base case: dropping from empty list gives empty list.
weave_drop_([], _, []) :- !.
% Drop one element at a time, decrementing N.
weave_drop_([_|T], N, Rest) :-
    N > 0,
    N1 is N - 1,
    weave_drop_(T, N1, Rest).

% weave_chunk(+List, +N, -Chunks): split List into consecutive non-overlapping chunks
% of exactly N elements. Any trailing elements that do not form a complete chunk
% are silently discarded. e.g. weave_chunk([a,b,c,d,e], 2, [[a,b],[c,d]]).
% Base case: empty list yields no chunks.
weave_chunk([], _, []) :- !.
% Extract a chunk of exactly N elements via append/3; cut prevents backtracking.
weave_chunk(List, N, [Chunk|Chunks]) :-
    length(Chunk, N),
    append(Chunk, Rest, List), !,
    weave_chunk(Rest, N, Chunks).
% If fewer than N elements remain, no more complete chunks can be formed.
weave_chunk(_, _, []).

% weave_pair_wise(+List, -Pairs): produce all consecutive overlapping pairs.
% e.g. weave_pair_wise([a,b,c,d], [[a,b],[b,c],[c,d]]).
% Base case: empty list has no pairs.
weave_pair_wise([], []) :- !.
% Base case: singleton has no pairs.
weave_pair_wise([_], []) :- !.
% Emit pair [A,B] and recurse keeping B as the start of the next pair.
weave_pair_wise([A,B|T], [[A,B]|Pairs]) :-
    weave_pair_wise([B|T], Pairs).

% weave_triple_wise(+List, -Triples): produce all consecutive overlapping triples.
% e.g. weave_triple_wise([a,b,c,d], [[a,b,c],[b,c,d]]).
% Base case: empty list has no triples.
weave_triple_wise([], []) :- !.
% Base case: singleton has no triples.
weave_triple_wise([_], []) :- !.
% Base case: two elements have no triples.
weave_triple_wise([_,_], []) :- !.
% Emit triple [A,B,C] and recurse keeping [B,C|T] as the start of the next window.
weave_triple_wise([A,B,C|T], [[A,B,C]|Triples]) :-
    weave_triple_wise([B,C|T], Triples).

% weave_rotate_left(+List, +K, -Result): rotate List left by K positions.
% The element at index K becomes the new head. K is reduced modulo list length.
% e.g. weave_rotate_left([a,b,c,d], 1, [b,c,d,a]).
% Base case: empty list is unchanged.
weave_rotate_left([], _, []) :- !.
% Reduce K modulo length; if zero, no rotation needed; otherwise split at K.
weave_rotate_left(List, K, Result) :-
    length(List, N),
    K1 is K mod N,
    ( K1 =:= 0
    -> Result = List
    ;  length(Front, K1),
       append(Front, Back, List),
       append(Back, Front, Result)
    ).

% weave_rotate_right(+List, +K, -Result): rotate List right by K positions.
% Equivalent to rotating left by (length - K mod length).
% e.g. weave_rotate_right([a,b,c,d], 1, [d,a,b,c]).
% Base case: empty list is unchanged.
weave_rotate_right([], _, []) :- !.
% Convert right rotation to an equivalent left rotation.
weave_rotate_right(List, K, Result) :-
    length(List, N),
    K1 is K mod N,
    ( K1 =:= 0
    -> Result = List
    ;  K2 is N - K1,
       weave_rotate_left(List, K2, Result)
    ).

% weave_reflect(+List, -Result): reverse the order of elements (mirror reflection).
% e.g. weave_reflect([a,b,c], [c,b,a]).
% Delegate to reverse/2 from library(lists).
weave_reflect(List, Result) :-
    reverse(List, Result).

% weave_repeat(+List, +N, -Result): concatenate List with itself N times.
% e.g. weave_repeat([a,b], 3, [a,b,a,b,a,b]).
% Base case: zero repetitions yields empty list.
weave_repeat(_, 0, []) :- !.
% Prepend List to the result of (N-1) repetitions.
weave_repeat(List, N, Result) :-
    N > 0,
    N1 is N - 1,
    weave_repeat(List, N1, Rest),
    append(List, Rest, Result).

% weave_take(+List, +N, -Result): return the first N elements of List.
% If N >= length(List), the entire list is returned unchanged.
% e.g. weave_take([a,b,c,d], 2, [a,b]).
% Base case: take zero elements yields empty result.
weave_take(_, 0, []) :- !.
% Base case: take from empty list yields empty result.
weave_take([], _, []) :- !.
% Take one element, decrement count, recurse.
weave_take([H|T], N, [H|Rest]) :-
    N > 0,
    N1 is N - 1,
    weave_take(T, N1, Rest).

% weave_drop(+List, +N, -Result): discard the first N elements; return the remainder.
% If N >= length(List), the result is [].
% e.g. weave_drop([a,b,c,d], 2, [c,d]).
% Base case: drop zero elements returns the list unchanged.
weave_drop(List, 0, List) :- !.
% Base case: drop from empty list yields empty result.
weave_drop([], _, []) :- !.
% Discard one element, decrement count, recurse.
weave_drop([_|T], N, Result) :-
    N > 0,
    N1 is N - 1,
    weave_drop(T, N1, Result).

% weave_cycle(+List, +N, -Result): produce a list of exactly N elements by cycling
% through List repeatedly. Fails if List is empty and N > 0.
% e.g. weave_cycle([a,b,c], 7, [a,b,c,a,b,c,a]).
% Base case: zero elements requested yields empty result.
weave_cycle(_, 0, []) :- !.
% Guard: List must be non-empty to allow cycling.
weave_cycle(List, N, Result) :-
    List \= [],
    N > 0,
    weave_cycle_(List, List, N, Result).

% weave_cycle_(+Current, +Source, +N, -Result): private cycling helper.
% Current is the remaining portion of the current pass through Source.
% Base case: no more elements needed.
weave_cycle_(_, _, 0, []) :- !.
% When the current pass is exhausted, restart from Source.
weave_cycle_([], Source, N, Result) :- !,
    weave_cycle_(Source, Source, N, Result).
% Take one element from Current, decrement count, continue.
weave_cycle_([H|T], Source, N, [H|Rest]) :-
    N > 0,
    N1 is N - 1,
    weave_cycle_(T, Source, N1, Rest).

% weave_zip(+List1, +List2, -Pairs): pair corresponding elements as H1-H2 terms.
% Stops when either list is exhausted; surplus elements are silently discarded.
% e.g. weave_zip([a,b,c], [1,2,3], [a-1,b-2,c-3]).
% Base case: first list exhausted.
weave_zip([], _, []) :- !.
% Base case: second list exhausted.
weave_zip(_, [], []) :- !.
% Pair the heads using the -/2 functor; recurse on tails.
weave_zip([H1|T1], [H2|T2], [H1-H2|Pairs]) :-
    weave_zip(T1, T2, Pairs).
