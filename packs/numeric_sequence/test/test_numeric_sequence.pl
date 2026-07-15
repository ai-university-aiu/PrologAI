:- use_module('../prolog/numeric_sequence').

:- begin_tests(numeric_sequence).

% --- numeric_sequence_diff ---

test(difference_three) :-
    numeric_sequence_diff([1,3,6,10], Diffs),
    Diffs = [2,3,4].

test(difference_two) :-
    numeric_sequence_diff([5,3], Diffs),
    Diffs = [-2].

test(difference_one) :-
    numeric_sequence_diff([7], Diffs),
    Diffs = [].

% --- numeric_sequence_cumsum ---

test(cumsum_basic) :-
    numeric_sequence_cumsum([1,2,3,4], Sums),
    Sums = [1,3,6,10].

test(cumsum_single) :-
    numeric_sequence_cumsum([5], Sums),
    Sums = [5].

test(cumsum_zeros) :-
    numeric_sequence_cumsum([0,0,0], Sums),
    Sums = [0,0,0].

% --- numeric_sequence_running_max ---

test(running_max_basic) :-
    numeric_sequence_running_max([3,1,4,1,5,9,2], Maxs),
    Maxs = [3,3,4,4,5,9,9].

test(running_max_increasing) :-
    numeric_sequence_running_max([1,2,3], Maxs),
    Maxs = [1,2,3].

test(running_max_single) :-
    numeric_sequence_running_max([7], Maxs),
    Maxs = [7].

% --- numeric_sequence_running_min ---

test(running_min_basic) :-
    numeric_sequence_running_min([5,3,4,1,2], Mins),
    Mins = [5,3,3,1,1].

test(running_min_decreasing) :-
    numeric_sequence_running_min([3,2,1], Mins),
    Mins = [3,2,1].

test(running_min_single) :-
    numeric_sequence_running_min([4], Mins),
    Mins = [4].

% --- numeric_sequence_zip_add ---

test(zip_add_basic) :-
    numeric_sequence_zip_add([1,2,3], [4,5,6], Sums),
    Sums = [5,7,9].

test(zip_add_zeros) :-
    numeric_sequence_zip_add([0,0,0], [1,2,3], Sums),
    Sums = [1,2,3].

test(zip_add_negatives) :-
    numeric_sequence_zip_add([1,2], [-1,-2], Sums),
    Sums = [0,0].

% --- numeric_sequence_zip_sub ---

test(zip_sub_basic) :-
    numeric_sequence_zip_sub([5,6,7], [1,2,3], Diffs),
    Diffs = [4,4,4].

test(zip_sub_zeros) :-
    numeric_sequence_zip_sub([3,3,3], [3,3,3], Diffs),
    Diffs = [0,0,0].

test(zip_sub_negative_result) :-
    numeric_sequence_zip_sub([1,2], [3,4], Diffs),
    Diffs = [-2,-2].

% --- numeric_sequence_zip_mul ---

test(zip_mul_basic) :-
    numeric_sequence_zip_mul([2,3,4], [5,6,7], Prods),
    Prods = [10,18,28].

test(zip_mul_zeros) :-
    numeric_sequence_zip_mul([1,2,3], [0,0,0], Prods),
    Prods = [0,0,0].

test(zip_mul_ones) :-
    numeric_sequence_zip_mul([5,6,7], [1,1,1], Prods),
    Prods = [5,6,7].

% --- numeric_sequence_zip_max ---

test(zip_max_basic) :-
    numeric_sequence_zip_max([1,5,3], [4,2,6], Maxs),
    Maxs = [4,5,6].

test(zip_max_equal) :-
    numeric_sequence_zip_max([3,3,3], [3,3,3], Maxs),
    Maxs = [3,3,3].

test(zip_max_single) :-
    numeric_sequence_zip_max([2], [5], Maxs),
    Maxs = [5].

% --- numeric_sequence_zip_min ---

test(zip_min_basic) :-
    numeric_sequence_zip_min([1,5,3], [4,2,6], Mins),
    Mins = [1,2,3].

test(zip_min_equal) :-
    numeric_sequence_zip_min([3,3,3], [3,3,3], Mins),
    Mins = [3,3,3].

test(zip_min_single) :-
    numeric_sequence_zip_min([8], [3], Mins),
    Mins = [3].

% --- numeric_sequence_scale ---

test(scale_by_two) :-
    numeric_sequence_scale([1,2,3,4], 2, Scaled),
    Scaled = [2,4,6,8].

test(scale_by_zero) :-
    numeric_sequence_scale([5,6,7], 0, Scaled),
    Scaled = [0,0,0].

test(scale_by_one) :-
    numeric_sequence_scale([1,2,3], 1, Scaled),
    Scaled = [1,2,3].

% --- numeric_sequence_offset ---

test(offset_positive) :-
    numeric_sequence_offset([1,2,3], 10, Shifted),
    Shifted = [11,12,13].

test(offset_zero) :-
    numeric_sequence_offset([5,6,7], 0, Shifted),
    Shifted = [5,6,7].

test(offset_negative) :-
    numeric_sequence_offset([5,6,7], -3, Shifted),
    Shifted = [2,3,4].

% --- numeric_sequence_is_sorted ---

test(is_sorted_strict) :-
    numeric_sequence_is_sorted([1,2,3,4]).

test(is_sorted_equal) :-
    numeric_sequence_is_sorted([1,1,2,2]).

test(is_sorted_fails, fail) :-
    numeric_sequence_is_sorted([1,3,2]).

% --- numeric_sequence_is_arith ---

test(is_arith_positive_step) :-
    numeric_sequence_is_arith([2,4,6,8]).

test(is_arith_zero_step) :-
    numeric_sequence_is_arith([5,5,5,5]).

test(is_arith_fails, fail) :-
    numeric_sequence_is_arith([1,2,4,8]).

% --- numeric_sequence_period ---

test(period_2) :-
    numeric_sequence_period([1,2,1,2,1,2], 3, P),
    P = 2.

test(period_3) :-
    numeric_sequence_period([1,2,3,1,2,3], 3, P),
    P = 3.

test(period_1) :-
    numeric_sequence_period([5,5,5,5], 4, P),
    P = 1.

:- end_tests(numeric_sequence).
