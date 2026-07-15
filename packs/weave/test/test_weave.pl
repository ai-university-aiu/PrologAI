:- use_module('../prolog/weave.pl').
:- use_module(library(plunit)).

:- begin_tests(weave_alternate).

test(equal_length) :-
    weave_alternate([a,b,c], [1,2,3], [a,1,b,2,c,3]).

test(left_longer) :-
    % L1 has 3 elements, L2 has 1: interleave then append remainder of L1.
    weave_alternate([a,b,c], [1], [a,1,b,c]).

test(right_longer) :-
    % L1 has 1 element, L2 has 3: interleave then append remainder of L2.
    weave_alternate([a], [1,2,3], [a,1,2,3]).

test(both_empty) :-
    weave_alternate([], [], []).

test(left_empty) :-
    weave_alternate([], [1,2,3], [1,2,3]).

:- end_tests(weave_alternate).

:- begin_tests(weave_split_even_odd).

test(four_elements) :-
    % Indices 0,1,2,3: evens=[a,c], odds=[b,d].
    weave_split_even_odd([a,b,c,d], [a,c], [b,d]).

test(five_elements) :-
    % Indices 0,1,2,3,4: evens=[a,c,e], odds=[b,d].
    weave_split_even_odd([a,b,c,d,e], [a,c,e], [b,d]).

test(singleton) :-
    weave_split_even_odd([a], [a], []).

test(empty) :-
    weave_split_even_odd([], [], []).

:- end_tests(weave_split_even_odd).

:- begin_tests(weave_stride).

test(stride_2) :-
    % Every second element: 0,2,4 -> a,c,e.
    weave_stride([a,b,c,d,e,f], 2, [a,c,e]).

test(stride_3) :-
    % Every third element: 0,3 -> a,d.
    weave_stride([a,b,c,d,e,f], 3, [a,d]).

test(stride_1_identity) :-
    % Stride 1 returns all elements.
    weave_stride([a,b,c], 1, [a,b,c]).

test(stride_exact) :-
    % Stride equals length: only the first element.
    weave_stride([a,b,c,d], 4, [a]).

test(stride_longer_than_list) :-
    % Stride larger than list: only the first element returned.
    weave_stride([a,b,c], 5, [a]).

:- end_tests(weave_stride).

:- begin_tests(weave_chunk).

test(evenly_divisible) :-
    weave_chunk([a,b,c,d,e,f], 2, [[a,b],[c,d],[e,f]]).

test(remainder_dropped) :-
    % 5 elements, chunk size 2: last element dropped.
    weave_chunk([a,b,c,d,e], 2, [[a,b],[c,d]]).

test(chunk_size_1) :-
    weave_chunk([a,b,c], 1, [[a],[b],[c]]).

test(chunk_equals_length) :-
    % One chunk containing the entire list.
    weave_chunk([a,b,c], 3, [[a,b,c]]).

test(empty_list) :-
    weave_chunk([], 2, []).

:- end_tests(weave_chunk).

:- begin_tests(weave_pair_wise).

test(four_elements) :-
    weave_pair_wise([a,b,c,d], [[a,b],[b,c],[c,d]]).

test(two_elements) :-
    weave_pair_wise([a,b], [[a,b]]).

test(singleton_empty_result) :-
    weave_pair_wise([a], []).

test(empty_empty) :-
    weave_pair_wise([], []).

:- end_tests(weave_pair_wise).

:- begin_tests(weave_triple_wise).

test(four_elements) :-
    weave_triple_wise([a,b,c,d], [[a,b,c],[b,c,d]]).

test(three_elements) :-
    weave_triple_wise([a,b,c], [[a,b,c]]).

test(two_elements_empty) :-
    weave_triple_wise([a,b], []).

test(singleton_empty) :-
    weave_triple_wise([a], []).

test(empty_empty) :-
    weave_triple_wise([], []).

:- end_tests(weave_triple_wise).

:- begin_tests(weave_rotate_left).

test(rotate_by_1) :-
    weave_rotate_left([a,b,c,d], 1, [b,c,d,a]).

test(rotate_by_2) :-
    weave_rotate_left([a,b,c,d], 2, [c,d,a,b]).

test(rotate_by_length_identity) :-
    % Rotating by the full length is a no-op.
    weave_rotate_left([a,b,c,d], 4, [a,b,c,d]).

test(rotate_by_0) :-
    weave_rotate_left([a,b,c], 0, [a,b,c]).

test(rotate_empty) :-
    weave_rotate_left([], 3, []).

:- end_tests(weave_rotate_left).

:- begin_tests(weave_rotate_right).

test(rotate_by_1) :-
    weave_rotate_right([a,b,c,d], 1, [d,a,b,c]).

test(rotate_by_2) :-
    weave_rotate_right([a,b,c,d], 2, [c,d,a,b]).

test(rotate_by_length_identity) :-
    weave_rotate_right([a,b,c,d], 4, [a,b,c,d]).

test(rotate_by_0) :-
    weave_rotate_right([a,b,c], 0, [a,b,c]).

test(rotate_empty) :-
    weave_rotate_right([], 2, []).

:- end_tests(weave_rotate_right).

:- begin_tests(weave_reflect).

test(four_elements) :-
    weave_reflect([a,b,c,d], [d,c,b,a]).

test(singleton) :-
    weave_reflect([a], [a]).

test(empty) :-
    weave_reflect([], []).

test(two_elements) :-
    weave_reflect([a,b], [b,a]).

:- end_tests(weave_reflect).

:- begin_tests(weave_repeat).

test(repeat_2) :-
    weave_repeat([a,b], 2, [a,b,a,b]).

test(repeat_3) :-
    weave_repeat([a,b,c], 3, [a,b,c,a,b,c,a,b,c]).

test(repeat_0) :-
    weave_repeat([a,b], 0, []).

test(repeat_1_identity) :-
    weave_repeat([a,b,c], 1, [a,b,c]).

:- end_tests(weave_repeat).

:- begin_tests(weave_take).

test(take_2_from_4) :-
    weave_take([a,b,c,d], 2, [a,b]).

test(take_all) :-
    % Taking all 3 elements from a 3-element list.
    weave_take([a,b,c], 3, [a,b,c]).

test(take_more_than_length) :-
    % Taking more than available returns the whole list.
    weave_take([a,b], 5, [a,b]).

test(take_0) :-
    weave_take([a,b,c], 0, []).

test(take_from_empty) :-
    weave_take([], 3, []).

:- end_tests(weave_take).

:- begin_tests(weave_drop).

test(drop_2_from_4) :-
    weave_drop([a,b,c,d], 2, [c,d]).

test(drop_all) :-
    weave_drop([a,b,c], 3, []).

test(drop_more_than_length) :-
    % Dropping more than available returns empty list.
    weave_drop([a,b], 5, []).

test(drop_0) :-
    weave_drop([a,b,c], 0, [a,b,c]).

test(drop_from_empty) :-
    weave_drop([], 3, []).

:- end_tests(weave_drop).

:- begin_tests(weave_cycle).

test(cycle_7_from_3) :-
    weave_cycle([a,b,c], 7, [a,b,c,a,b,c,a]).

test(cycle_exact_multiple) :-
    % 2 elements cycled to 6 = 3 full repetitions.
    weave_cycle([a,b], 6, [a,b,a,b,a,b]).

test(cycle_shorter_than_source) :-
    % Requesting fewer elements than the source list length.
    weave_cycle([a,b,c,d,e], 3, [a,b,c]).

test(cycle_0) :-
    weave_cycle([a,b,c], 0, []).

test(cycle_1) :-
    % Single element cycle: just the first element.
    weave_cycle([a,b,c], 1, [a]).

:- end_tests(weave_cycle).

:- begin_tests(weave_zip).

test(equal_length) :-
    weave_zip([a,b,c], [1,2,3], [a-1,b-2,c-3]).

test(left_shorter) :-
    % Left list shorter: stops when left is exhausted.
    weave_zip([a,b], [1,2,3], [a-1,b-2]).

test(right_shorter) :-
    % Right list shorter: stops when right is exhausted.
    weave_zip([a,b,c], [1,2], [a-1,b-2]).

test(left_empty) :-
    weave_zip([], [1,2,3], []).

test(right_empty) :-
    weave_zip([a,b,c], [], []).

:- end_tests(weave_zip).
