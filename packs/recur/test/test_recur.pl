:- use_module('../prolog/recur').

:- begin_tests(recur).

% recur_arith/4 tests

test(arithmetic_basic) :-
    recur_arith(1, 2, 3, [1,3,5]).

test(arithmetic_zero_step) :-
    recur_arith(7, 0, 4, [7,7,7,7]).

test(arithmetic_negative_step) :-
    recur_arith(10, -3, 4, [10,7,4,1]).

% recur_arith_step/2 tests

test(arithmetic_step_positive) :-
    recur_arith_step([1,3,5,7], 2).

test(arithmetic_step_negative) :-
    recur_arith_step([10,7,4,1], -3).

test(arithmetic_step_zero) :-
    recur_arith_step([5,5,5], 0).

% recur_is_arith/2 tests

test(is_arith_succeeds) :-
    recur_is_arith([2,4,6,8], 2).

test(is_arith_constant) :-
    recur_is_arith([3,3,3], 0).

test(is_arith_fails_geometric) :-
    \+ recur_is_arith([1,2,4,8], _).

% recur_repeat/3 tests

test(repeat_basic) :-
    recur_repeat([a,b], 3, [a,b,a,b,a,b]).

test(repeat_single_element) :-
    recur_repeat([1], 4, [1,1,1,1]).

test(repeat_triple) :-
    recur_repeat([1,2,3], 2, [1,2,3,1,2,3]).

% recur_period/2 tests

test(period_two) :-
    recur_period([1,2,1,2,1,2], [1,2]).

test(period_three) :-
    recur_period([a,b,c,a,b,c], [a,b,c]).

test(period_constant) :-
    recur_period([7,7,7,7], [7]).

% recur_is_periodic/2 tests

test(is_periodic_two) :-
    recur_is_periodic([1,2,1,2], [1,2]).

test(is_periodic_constant) :-
    recur_is_periodic([x,x,x], [x]).

test(is_periodic_three) :-
    recur_is_periodic([1,2,3,1,2,3], [1,2,3]).

% recur_next_arith/3 tests

test(next_arith_two_terms) :-
    recur_next_arith([1,3,5], 2, [7,9]).

test(next_arith_decreasing) :-
    recur_next_arith([10,7,4], 3, [1,-2,-5]).

test(next_arith_constant) :-
    recur_next_arith([5,5,5], 1, [5]).

% recur_next_repeat/3 tests

test(next_repeat_period3) :-
    recur_next_repeat([1,2,3,1,2,3], 3, [1,2,3]).

test(next_repeat_period2) :-
    recur_next_repeat([a,b,a,b], 4, [a,b,a,b]).

test(next_repeat_partial) :-
    recur_next_repeat([1,2,3,1,2,3], 2, [1,2]).

% recur_extend_arith/4 tests

test(extend_arith_two) :-
    recur_extend_arith([1,3,5], 2, [1,3,5,7,9], 2).

test(extend_arith_one) :-
    recur_extend_arith([10,7], 1, [10,7,4], -3).

test(extend_arith_constant) :-
    recur_extend_arith([5,5,5], 3, [5,5,5,5,5,5], 0).

% recur_extend_repeat/4 tests

test(extend_repeat_period2) :-
    recur_extend_repeat([1,2,1,2], 2, [1,2,1,2,1,2], [1,2]).

test(extend_repeat_period3) :-
    recur_extend_repeat([a,b,c], 3, [a,b,c,a,b,c], [a,b,c]).

test(extend_repeat_constant) :-
    recur_extend_repeat([x,x], 4, [x,x,x,x,x,x], [x]).

% recur_cycle_nth/3 tests

test(cycle_nth_first) :-
    recur_cycle_nth([a,b,c], 1, a).

test(cycle_nth_wrap) :-
    recur_cycle_nth([a,b,c], 4, a).

test(cycle_nth_period2) :-
    recur_cycle_nth([1,2], 7, 1).

% recur_zip_with/4 tests

test(zip_with_add) :-
    recur_zip_with([1,2,3], [4,5,6], [A,B,C]>>(C is A+B), [5,7,9]).

test(zip_with_empty) :-
    recur_zip_with([], [], [_,_,_]>>true, []).

test(zip_with_single) :-
    recur_zip_with([10], [3], [A,B,C]>>(C is A - B), [7]).

% recur_diff_list/2 tests

test(difference_list_variable) :-
    recur_diff_list([1,3,6,10], [2,3,4]).

test(difference_list_negative) :-
    recur_diff_list([5,3,1], [-2,-2]).

test(difference_list_zero) :-
    recur_diff_list([7,7], [0]).

% recur_const_diffs/2 tests

test(const_diffs_positive) :-
    recur_const_diffs([1,3,5,7], 2).

test(const_diffs_negative) :-
    recur_const_diffs([8,5,2], -3).

test(const_diffs_fails_geometric) :-
    \+ recur_const_diffs([1,2,4,8], _).

:- end_tests(recur).
