% PLUnit tests for the pipeline pack (pl_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/pipeline').

% Helper step handlers for pl_run tests.
% double_all: multiplies every cell value by 2.
double_all_handler_(_, Grid, Grid2) :-
    maplist(maplist([V, V2]>>(V2 is V * 2)), Grid, Grid2).

% add_one: adds 1 to every cell value.
add_one_handler_(_, Grid, Grid2) :-
    maplist(maplist([V, V2]>>(V2 is V + 1)), Grid, Grid2).

% identity: passes the grid through unchanged.
identity_handler_(_, Grid, Grid).

% negate: negates every cell value.
negate_handler_(_, Grid, Grid2) :-
    maplist(maplist([V, V2]>>(V2 is -V)), Grid, Grid2).

:- begin_tests(pl_register).

test(register_and_query) :-
    % Register a handler and query it.
    pl_register(double, double_all_handler_),
    pl_registered(double, double_all_handler_),
    pl_unregister(double).

test(register_replaces) :-
    % Registering a second time replaces the first.
    pl_register(step_x, add_one_handler_),
    pl_register(step_x, identity_handler_),
    pl_registered(step_x, identity_handler_),
    pl_unregister(step_x).

test(unregister_absent) :-
    % Unregistering a name that does not exist succeeds.
    pl_unregister(nonexistent_step_abc).

:- end_tests(pl_register).

:- begin_tests(pl_run).

test(run_empty) :-
    % Empty step list: output = input.
    Grid = [[1,2],[3,4]],
    pl_run([], Grid, Out),
    Out = Grid.

test(run_single_step) :-
    % Single step: double all values.
    pl_register(double, double_all_handler_),
    pl_run([double], [[1,2],[3,4]], Out),
    Out = [[2,4],[6,8]],
    pl_unregister(double).

test(run_two_steps) :-
    % Two steps: double then add_one.
    pl_register(double, double_all_handler_),
    pl_register(add_one, add_one_handler_),
    pl_run([double, add_one], [[1,2],[3,4]], Out),
    Out = [[3,5],[7,9]],
    pl_unregister(double),
    pl_unregister(add_one).

test(run_three_steps) :-
    % Three steps in sequence.
    pl_register(add_one, add_one_handler_),
    pl_register(double, double_all_handler_),
    pl_register(negate, negate_handler_),
    pl_run([add_one, double, negate], [[1,2]], Out),
    Out = [[-4,-6]],
    pl_unregister(add_one),
    pl_unregister(double),
    pl_unregister(negate).

test(run_unknown_step_passthrough) :-
    % Unknown step name: grid passes through unchanged.
    pl_run([completely_unknown_step_xyz], [[1,2],[3,4]], Out),
    Out = [[1,2],[3,4]].

:- end_tests(pl_run).

:- begin_tests(pl_step).

test(step_with_registry) :-
    % Use a local registry (no dynamic facts needed).
    pl_step(add_one, [[1,2]], Out, [add_one-add_one_handler_]),
    Out = [[2,3]].

test(step_unknown_passthrough) :-
    % No handler in registry or dynamic: pass through.
    pl_step(unknown_xyz, [[5,6]], Out, []),
    Out = [[5,6]].

:- end_tests(pl_step).

:- begin_tests(pl_map).

test(map_basic) :-
    % Double each integer.
    pl_map([X, Y]>>(Y is X * 2), [1,2,3,4], Results),
    Results = [2,4,6,8].

test(map_empty) :-
    % Empty list maps to empty list.
    pl_map([X,Y]>>(Y is X + 1), [], Results),
    Results = [].

test(map_strings) :-
    % Map a predicate that builds a pair.
    pl_map([X, X-X]>>true, [a,b,c], Results),
    Results = [a-a, b-b, c-c].

:- end_tests(pl_map).

:- begin_tests(pl_filter).

test(filter_even) :-
    % Keep only even numbers.
    pl_filter([X]>>(0 is X mod 2), [1,2,3,4,5,6], Kept),
    Kept = [2,4,6].

test(filter_all) :-
    % All pass: kept = input.
    pl_filter([X]>>(X > 0), [1,2,3], Kept),
    Kept = [1,2,3].

test(filter_none) :-
    % None pass: kept = [].
    pl_filter([X]>>(X > 100), [1,2,3], Kept),
    Kept = [].

test(filter_empty) :-
    % Empty list: kept = [].
    pl_filter([X]>>(X > 0), [], Kept),
    Kept = [].

:- end_tests(pl_filter).

:- begin_tests(pl_fold).

test(fold_sum) :-
    % Fold sum: 1+2+3+4 = 10.
    pl_fold([X, Acc, Acc2]>>(Acc2 is Acc + X), [1,2,3,4], 0, Sum),
    Sum =:= 10.

test(fold_product) :-
    % Fold product: 1*2*3*4 = 24.
    pl_fold([X, Acc, Acc2]>>(Acc2 is Acc * X), [1,2,3,4], 1, Prod),
    Prod =:= 24.

test(fold_empty) :-
    % Empty list: accumulator unchanged.
    pl_fold([X, A, B]>>(B is A + X), [], 7, Result),
    Result =:= 7.

test(fold_reverse) :-
    % Fold to reverse a list.
    pl_fold([X, Acc, [X|Acc]]>>true, [1,2,3], [], Rev),
    Rev = [3,2,1].

:- end_tests(pl_fold).

:- begin_tests(pl_zip).

test(zip_basic) :-
    % Zip two equal-length lists.
    pl_zip([1,2,3], [a,b,c], Pairs),
    Pairs = [1-a, 2-b, 3-c].

test(zip_empty) :-
    % Zip two empty lists.
    pl_zip([], [], Pairs),
    Pairs = [].

test(zip_single) :-
    % Single-element lists.
    pl_zip([x], [y], Pairs),
    Pairs = [x-y].

:- end_tests(pl_zip).

:- begin_tests(pl_unzip).

test(unzip_basic) :-
    % Unzip a list of pairs.
    pl_unzip([1-a, 2-b, 3-c], Ls, Rs),
    Ls = [1,2,3],
    Rs = [a,b,c].

test(unzip_empty) :-
    % Unzip an empty list.
    pl_unzip([], Ls, Rs),
    Ls = [],
    Rs = [].

test(unzip_single) :-
    % Single-pair list.
    pl_unzip([x-y], Ls, Rs),
    Ls = [x],
    Rs = [y].

:- end_tests(pl_unzip).

:- begin_tests(pl_take).

test(take_basic) :-
    % Take 3 from a 5-element list.
    pl_take(3, [1,2,3,4,5], Taken),
    Taken = [1,2,3].

test(take_zero) :-
    % Take 0: empty list.
    pl_take(0, [1,2,3], Taken),
    Taken = [].

test(take_more_than_length) :-
    % Take more than available: return full list.
    pl_take(10, [1,2,3], Taken),
    Taken = [1,2,3].

test(take_exact) :-
    % Take exactly the list length.
    pl_take(4, [a,b,c,d], Taken),
    Taken = [a,b,c,d].

:- end_tests(pl_take).

:- begin_tests(pl_drop).

test(drop_basic) :-
    % Drop 2 from a 5-element list.
    pl_drop(2, [1,2,3,4,5], Rest),
    Rest = [3,4,5].

test(drop_zero) :-
    % Drop 0: list unchanged.
    pl_drop(0, [1,2,3], Rest),
    Rest = [1,2,3].

test(drop_more_than_length) :-
    % Drop more than available: empty list.
    pl_drop(10, [1,2,3], Rest),
    Rest = [].

test(drop_all) :-
    % Drop exactly the list length: empty list.
    pl_drop(3, [a,b,c], Rest),
    Rest = [].

:- end_tests(pl_drop).

:- begin_tests(pl_partition).

test(partition_basic) :-
    % Partition by even/odd.
    pl_partition([X]>>(0 is X mod 2), [1,2,3,4,5,6], Evens, Odds),
    Evens = [2,4,6],
    Odds = [1,3,5].

test(partition_all_sat) :-
    % All satisfy: rejected is empty.
    pl_partition([X]>>(X > 0), [1,2,3], Sat, Rej),
    Sat = [1,2,3],
    Rej = [].

test(partition_none_sat) :-
    % None satisfy: satisfied is empty.
    pl_partition([X]>>(X > 100), [1,2,3], Sat, Rej),
    Sat = [],
    Rej = [1,2,3].

test(partition_empty) :-
    % Empty list: both parts empty.
    pl_partition([X]>>(X > 0), [], Sat, Rej),
    Sat = [],
    Rej = [].

:- end_tests(pl_partition).
