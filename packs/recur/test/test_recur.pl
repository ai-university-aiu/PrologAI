:- use_module('../prolog/recur').

:- begin_tests(recur).

% rc_arith/4 tests

test(arith_basic) :-
    rc_arith(1, 2, 3, [1,3,5]).

test(arith_zero_step) :-
    rc_arith(7, 0, 4, [7,7,7,7]).

test(arith_negative_step) :-
    rc_arith(10, -3, 4, [10,7,4,1]).

% rc_arith_step/2 tests

test(arith_step_positive) :-
    rc_arith_step([1,3,5,7], 2).

test(arith_step_negative) :-
    rc_arith_step([10,7,4,1], -3).

test(arith_step_zero) :-
    rc_arith_step([5,5,5], 0).

% rc_is_arith/2 tests

test(is_arith_succeeds) :-
    rc_is_arith([2,4,6,8], 2).

test(is_arith_constant) :-
    rc_is_arith([3,3,3], 0).

test(is_arith_fails_geometric) :-
    \+ rc_is_arith([1,2,4,8], _).

% rc_repeat/3 tests

test(repeat_basic) :-
    rc_repeat([a,b], 3, [a,b,a,b,a,b]).

test(repeat_single_element) :-
    rc_repeat([1], 4, [1,1,1,1]).

test(repeat_triple) :-
    rc_repeat([1,2,3], 2, [1,2,3,1,2,3]).

% rc_period/2 tests

test(period_two) :-
    rc_period([1,2,1,2,1,2], [1,2]).

test(period_three) :-
    rc_period([a,b,c,a,b,c], [a,b,c]).

test(period_constant) :-
    rc_period([7,7,7,7], [7]).

% rc_is_periodic/2 tests

test(is_periodic_two) :-
    rc_is_periodic([1,2,1,2], [1,2]).

test(is_periodic_constant) :-
    rc_is_periodic([x,x,x], [x]).

test(is_periodic_three) :-
    rc_is_periodic([1,2,3,1,2,3], [1,2,3]).

% rc_next_arith/3 tests

test(next_arith_two_terms) :-
    rc_next_arith([1,3,5], 2, [7,9]).

test(next_arith_decreasing) :-
    rc_next_arith([10,7,4], 3, [1,-2,-5]).

test(next_arith_constant) :-
    rc_next_arith([5,5,5], 1, [5]).

% rc_next_repeat/3 tests

test(next_repeat_period3) :-
    rc_next_repeat([1,2,3,1,2,3], 3, [1,2,3]).

test(next_repeat_period2) :-
    rc_next_repeat([a,b,a,b], 4, [a,b,a,b]).

test(next_repeat_partial) :-
    rc_next_repeat([1,2,3,1,2,3], 2, [1,2]).

% rc_extend_arith/4 tests

test(extend_arith_two) :-
    rc_extend_arith([1,3,5], 2, [1,3,5,7,9], 2).

test(extend_arith_one) :-
    rc_extend_arith([10,7], 1, [10,7,4], -3).

test(extend_arith_constant) :-
    rc_extend_arith([5,5,5], 3, [5,5,5,5,5,5], 0).

% rc_extend_repeat/4 tests

test(extend_repeat_period2) :-
    rc_extend_repeat([1,2,1,2], 2, [1,2,1,2,1,2], [1,2]).

test(extend_repeat_period3) :-
    rc_extend_repeat([a,b,c], 3, [a,b,c,a,b,c], [a,b,c]).

test(extend_repeat_constant) :-
    rc_extend_repeat([x,x], 4, [x,x,x,x,x,x], [x]).

% rc_cycle_nth/3 tests

test(cycle_nth_first) :-
    rc_cycle_nth([a,b,c], 1, a).

test(cycle_nth_wrap) :-
    rc_cycle_nth([a,b,c], 4, a).

test(cycle_nth_period2) :-
    rc_cycle_nth([1,2], 7, 1).

% rc_zip_with/4 tests

test(zip_with_add) :-
    rc_zip_with([1,2,3], [4,5,6], [A,B,C]>>(C is A+B), [5,7,9]).

test(zip_with_empty) :-
    rc_zip_with([], [], [_,_,_]>>true, []).

test(zip_with_single) :-
    rc_zip_with([10], [3], [A,B,C]>>(C is A - B), [7]).

% rc_diff_list/2 tests

test(diff_list_variable) :-
    rc_diff_list([1,3,6,10], [2,3,4]).

test(diff_list_negative) :-
    rc_diff_list([5,3,1], [-2,-2]).

test(diff_list_zero) :-
    rc_diff_list([7,7], [0]).

% rc_const_diffs/2 tests

test(const_diffs_positive) :-
    rc_const_diffs([1,3,5,7], 2).

test(const_diffs_negative) :-
    rc_const_diffs([8,5,2], -3).

test(const_diffs_fails_geometric) :-
    \+ rc_const_diffs([1,2,4,8], _).

:- end_tests(recur).
