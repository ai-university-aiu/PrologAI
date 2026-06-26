:- use_module('../prolog/numseq').

:- begin_tests(numseq).

% --- nr_diff ---

test(diff_three) :-
    nr_diff([1,3,6,10], Diffs),
    Diffs = [2,3,4].

test(diff_two) :-
    nr_diff([5,3], Diffs),
    Diffs = [-2].

test(diff_one) :-
    nr_diff([7], Diffs),
    Diffs = [].

% --- nr_cumsum ---

test(cumsum_basic) :-
    nr_cumsum([1,2,3,4], Sums),
    Sums = [1,3,6,10].

test(cumsum_single) :-
    nr_cumsum([5], Sums),
    Sums = [5].

test(cumsum_zeros) :-
    nr_cumsum([0,0,0], Sums),
    Sums = [0,0,0].

% --- nr_running_max ---

test(running_max_basic) :-
    nr_running_max([3,1,4,1,5,9,2], Maxs),
    Maxs = [3,3,4,4,5,9,9].

test(running_max_increasing) :-
    nr_running_max([1,2,3], Maxs),
    Maxs = [1,2,3].

test(running_max_single) :-
    nr_running_max([7], Maxs),
    Maxs = [7].

% --- nr_running_min ---

test(running_min_basic) :-
    nr_running_min([5,3,4,1,2], Mins),
    Mins = [5,3,3,1,1].

test(running_min_decreasing) :-
    nr_running_min([3,2,1], Mins),
    Mins = [3,2,1].

test(running_min_single) :-
    nr_running_min([4], Mins),
    Mins = [4].

% --- nr_zip_add ---

test(zip_add_basic) :-
    nr_zip_add([1,2,3], [4,5,6], Sums),
    Sums = [5,7,9].

test(zip_add_zeros) :-
    nr_zip_add([0,0,0], [1,2,3], Sums),
    Sums = [1,2,3].

test(zip_add_negatives) :-
    nr_zip_add([1,2], [-1,-2], Sums),
    Sums = [0,0].

% --- nr_zip_sub ---

test(zip_sub_basic) :-
    nr_zip_sub([5,6,7], [1,2,3], Diffs),
    Diffs = [4,4,4].

test(zip_sub_zeros) :-
    nr_zip_sub([3,3,3], [3,3,3], Diffs),
    Diffs = [0,0,0].

test(zip_sub_negative_result) :-
    nr_zip_sub([1,2], [3,4], Diffs),
    Diffs = [-2,-2].

% --- nr_zip_mul ---

test(zip_mul_basic) :-
    nr_zip_mul([2,3,4], [5,6,7], Prods),
    Prods = [10,18,28].

test(zip_mul_zeros) :-
    nr_zip_mul([1,2,3], [0,0,0], Prods),
    Prods = [0,0,0].

test(zip_mul_ones) :-
    nr_zip_mul([5,6,7], [1,1,1], Prods),
    Prods = [5,6,7].

% --- nr_zip_max ---

test(zip_max_basic) :-
    nr_zip_max([1,5,3], [4,2,6], Maxs),
    Maxs = [4,5,6].

test(zip_max_equal) :-
    nr_zip_max([3,3,3], [3,3,3], Maxs),
    Maxs = [3,3,3].

test(zip_max_single) :-
    nr_zip_max([2], [5], Maxs),
    Maxs = [5].

% --- nr_zip_min ---

test(zip_min_basic) :-
    nr_zip_min([1,5,3], [4,2,6], Mins),
    Mins = [1,2,3].

test(zip_min_equal) :-
    nr_zip_min([3,3,3], [3,3,3], Mins),
    Mins = [3,3,3].

test(zip_min_single) :-
    nr_zip_min([8], [3], Mins),
    Mins = [3].

% --- nr_scale ---

test(scale_by_two) :-
    nr_scale([1,2,3,4], 2, Scaled),
    Scaled = [2,4,6,8].

test(scale_by_zero) :-
    nr_scale([5,6,7], 0, Scaled),
    Scaled = [0,0,0].

test(scale_by_one) :-
    nr_scale([1,2,3], 1, Scaled),
    Scaled = [1,2,3].

% --- nr_offset ---

test(offset_positive) :-
    nr_offset([1,2,3], 10, Shifted),
    Shifted = [11,12,13].

test(offset_zero) :-
    nr_offset([5,6,7], 0, Shifted),
    Shifted = [5,6,7].

test(offset_negative) :-
    nr_offset([5,6,7], -3, Shifted),
    Shifted = [2,3,4].

% --- nr_is_sorted ---

test(is_sorted_strict) :-
    nr_is_sorted([1,2,3,4]).

test(is_sorted_equal) :-
    nr_is_sorted([1,1,2,2]).

test(is_sorted_fails, fail) :-
    nr_is_sorted([1,3,2]).

% --- nr_is_arith ---

test(is_arith_positive_step) :-
    nr_is_arith([2,4,6,8]).

test(is_arith_zero_step) :-
    nr_is_arith([5,5,5,5]).

test(is_arith_fails, fail) :-
    nr_is_arith([1,2,4,8]).

% --- nr_period ---

test(period_2) :-
    nr_period([1,2,1,2,1,2], 3, P),
    P = 2.

test(period_3) :-
    nr_period([1,2,3,1,2,3], 3, P),
    P = 3.

test(period_1) :-
    nr_period([5,5,5,5], 4, P),
    P = 1.

:- end_tests(numseq).
