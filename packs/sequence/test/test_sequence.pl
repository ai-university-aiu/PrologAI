% PLUnit tests for the sequence pack (sq_* predicates).
:- use_module(library(plunit)).
:- use_module(library(sequence)).

:- begin_tests(sequence_range).

test(range_basic) :-
    sequence_range(1, 5, L),
    L = [1,2,3,4,5].

test(range_single) :-
    sequence_range(3, 3, L),
    L = [3].

test(range_empty) :-
    sequence_range(5, 2, L),
    L = [].

test(range_zero_start) :-
    sequence_range(0, 3, L),
    L = [0,1,2,3].

:- end_tests(sequence_range).

:- begin_tests(sequence_delta).

test(delta_basic) :-
    sequence_delta([1,3,6,10], D),
    D = [2,3,4].

test(delta_constant) :-
    sequence_delta([2,4,6,8], D),
    D = [2,2,2].

test(delta_single) :-
    sequence_delta([5], D),
    D = [].

test(delta_two) :-
    sequence_delta([3,7], D),
    D = [4].

:- end_tests(sequence_delta).

:- begin_tests(sequence_is_arithmetic).

test(arith_yes) :-
    sequence_is_arithmetic([2,4,6,8,10]).

test(arith_constant) :-
    sequence_is_arithmetic([5,5,5,5]).

test(arith_single) :-
    sequence_is_arithmetic([7]).

test(arith_empty) :-
    sequence_is_arithmetic([]).

test(arith_no, [fail]) :-
    sequence_is_arithmetic([1,3,6,10]).

test(arith_two) :-
    sequence_is_arithmetic([3,7]).

:- end_tests(sequence_is_arithmetic).

:- begin_tests(sequence_common_diff).

test(common_diff_basic) :-
    sequence_common_diff([2,4,6,8], D),
    D =:= 2.

test(common_diff_negative) :-
    sequence_common_diff([10,7,4,1], D),
    D =:= -3.

test(common_diff_zero) :-
    sequence_common_diff([5,5,5], D),
    D =:= 0.

test(common_diff_fails, [fail]) :-
    sequence_common_diff([1,3,6,10], _D).

:- end_tests(sequence_common_diff).

:- begin_tests(sequence_extend_arith).

test(extend_basic) :-
    sequence_extend_arith([1,3,5], 2, Extended),
    Extended = [1,3,5,7,9].

test(extend_by_zero) :-
    sequence_extend_arith([1,2,3], 0, Extended),
    Extended = [1,2,3].

test(extend_negative_diff) :-
    sequence_extend_arith([10,8,6], 3, Extended),
    Extended = [10,8,6,4,2,0].

:- end_tests(sequence_extend_arith).

:- begin_tests(sequence_chunk).

test(chunk_basic) :-
    sequence_chunk([1,2,3,4,5,6], 2, Chunks),
    Chunks = [[1,2],[3,4],[5,6]].

test(chunk_by_three) :-
    sequence_chunk([1,2,3,4,5,6], 3, Chunks),
    Chunks = [[1,2,3],[4,5,6]].

test(chunk_single) :-
    sequence_chunk([1,2,3], 1, Chunks),
    Chunks = [[1],[2],[3]].

test(chunk_empty) :-
    sequence_chunk([], 3, Chunks),
    Chunks = [].

test(chunk_fails, [fail]) :-
    sequence_chunk([1,2,3,4,5], 2, _Chunks).

:- end_tests(sequence_chunk).

:- begin_tests(sequence_zip).

test(zip_basic) :-
    sequence_zip([1,2,3], [a,b,c], Pairs),
    Pairs = [1-a, 2-b, 3-c].

test(zip_empty) :-
    sequence_zip([], [], Pairs),
    Pairs = [].

:- end_tests(sequence_zip).

:- begin_tests(sequence_unzip).

test(unzip_basic) :-
    sequence_unzip([1-a, 2-b, 3-c], As, Bs),
    As = [1,2,3],
    Bs = [a,b,c].

test(unzip_empty) :-
    sequence_unzip([], As, Bs),
    As = [],
    Bs = [].

test(unzip_roundtrip) :-
    sequence_zip([x,y,z], [1,2,3], Pairs),
    sequence_unzip(Pairs, Xs, Ns),
    Xs = [x,y,z],
    Ns = [1,2,3].

:- end_tests(sequence_unzip).

:- begin_tests(sequence_cumsum).

test(cumsum_basic) :-
    sequence_cumsum([1,2,3,4], Sums),
    Sums = [1,3,6,10].

test(cumsum_single) :-
    sequence_cumsum([5], Sums),
    Sums = [5].

test(cumsum_empty) :-
    sequence_cumsum([], Sums),
    Sums = [].

test(cumsum_zeros) :-
    sequence_cumsum([0,0,0], Sums),
    Sums = [0,0,0].

:- end_tests(sequence_cumsum).

:- begin_tests(sequence_slice).

test(slice_basic) :-
    sequence_slice([a,b,c,d,e], 1, 3, Sub),
    Sub = [b,c].

test(slice_from_zero) :-
    sequence_slice([1,2,3,4,5], 0, 3, Sub),
    Sub = [1,2,3].

test(slice_single) :-
    sequence_slice([a,b,c,d], 2, 3, Sub),
    Sub = [c].

test(slice_empty) :-
    sequence_slice([1,2,3], 2, 2, Sub),
    Sub = [].

:- end_tests(sequence_slice).

:- begin_tests(sequence_flatten1).

test(flatten1_basic) :-
    sequence_flatten1([[1,2],[3,4],[5]], Flat),
    Flat = [1,2,3,4,5].

test(flatten1_empty) :-
    sequence_flatten1([], Flat),
    Flat = [].

test(flatten1_single) :-
    sequence_flatten1([[a,b,c]], Flat),
    Flat = [a,b,c].

:- end_tests(sequence_flatten1).

:- begin_tests(sequence_transpose).

test(transpose_2x3) :-
    sequence_transpose([[1,2,3],[4,5,6]], T),
    T = [[1,4],[2,5],[3,6]].

test(transpose_3x2) :-
    sequence_transpose([[1,2],[3,4],[5,6]], T),
    T = [[1,3,5],[2,4,6]].

test(transpose_1x3) :-
    sequence_transpose([[1,2,3]], T),
    T = [[1],[2],[3]].

test(transpose_empty) :-
    sequence_transpose([], T),
    T = [].

:- end_tests(sequence_transpose).

:- begin_tests(sequence_period).

test(period_basic) :-
    sequence_period([1,2,1,2,1,2], P),
    P = [1,2].

test(period_longer) :-
    sequence_period([1,2,3,1,2,3], P),
    P = [1,2,3].

test(period_trivial) :-
    % [1,2,3] has no proper period; smallest period is itself.
    sequence_period([1,2,3], P),
    P = [1,2,3].

test(period_constant) :-
    sequence_period([5,5,5,5], P),
    P = [5].

:- end_tests(sequence_period).

:- begin_tests(sequence_is_periodic).

test(periodic_yes) :-
    sequence_is_periodic([1,2,1,2]).

test(periodic_constant) :-
    sequence_is_periodic([3,3,3,3]).

test(periodic_no, [fail]) :-
    sequence_is_periodic([1,2,3]).

test(periodic_no_single, [fail]) :-
    sequence_is_periodic([1]).

:- end_tests(sequence_is_periodic).
