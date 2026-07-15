% PLUnit tests for the pipeline pack (pl_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/pipeline').

% Helper step handlers for pipeline_run tests.
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

:- begin_tests(pipeline_register).

test(register_and_query) :-
    % Register a handler and query it.
    pipeline_register(double, double_all_handler_),
    pipeline_registered(double, double_all_handler_),
    pipeline_unregister(double).

test(register_replaces) :-
    % Registering a second time replaces the first.
    pipeline_register(step_x, add_one_handler_),
    pipeline_register(step_x, identity_handler_),
    pipeline_registered(step_x, identity_handler_),
    pipeline_unregister(step_x).

test(unregister_absent) :-
    % Unregistering a name that does not exist succeeds.
    pipeline_unregister(nonexistent_step_abc).

:- end_tests(pipeline_register).

:- begin_tests(pipeline_run).

test(run_empty) :-
    % Empty step list: output = input.
    Grid = [[1,2],[3,4]],
    pipeline_run([], Grid, Out),
    Out = Grid.

test(run_single_step) :-
    % Single step: double all values.
    pipeline_register(double, double_all_handler_),
    pipeline_run([double], [[1,2],[3,4]], Out),
    Out = [[2,4],[6,8]],
    pipeline_unregister(double).

test(run_two_steps) :-
    % Two steps: double then add_one.
    pipeline_register(double, double_all_handler_),
    pipeline_register(add_one, add_one_handler_),
    pipeline_run([double, add_one], [[1,2],[3,4]], Out),
    Out = [[3,5],[7,9]],
    pipeline_unregister(double),
    pipeline_unregister(add_one).

test(run_three_steps) :-
    % Three steps in sequence.
    pipeline_register(add_one, add_one_handler_),
    pipeline_register(double, double_all_handler_),
    pipeline_register(negate, negate_handler_),
    pipeline_run([add_one, double, negate], [[1,2]], Out),
    Out = [[-4,-6]],
    pipeline_unregister(add_one),
    pipeline_unregister(double),
    pipeline_unregister(negate).

test(run_unknown_step_passthrough) :-
    % Unknown step name: grid passes through unchanged.
    pipeline_run([completely_unknown_step_xyz], [[1,2],[3,4]], Out),
    Out = [[1,2],[3,4]].

:- end_tests(pipeline_run).

:- begin_tests(pipeline_step).

test(step_with_registry) :-
    % Use a local registry (no dynamic facts needed).
    pipeline_step(add_one, [[1,2]], Out, [add_one-add_one_handler_]),
    Out = [[2,3]].

test(step_unknown_passthrough) :-
    % No handler in registry or dynamic: pass through.
    pipeline_step(unknown_xyz, [[5,6]], Out, []),
    Out = [[5,6]].

:- end_tests(pipeline_step).

:- begin_tests(pipeline_map).

test(map_basic) :-
    % Double each integer.
    pipeline_map([X, Y]>>(Y is X * 2), [1,2,3,4], Results),
    Results = [2,4,6,8].

test(map_empty) :-
    % Empty list maps to empty list.
    pipeline_map([X,Y]>>(Y is X + 1), [], Results),
    Results = [].

test(map_strings) :-
    % Map a predicate that builds a pair.
    pipeline_map([X, X-X]>>true, [a,b,c], Results),
    Results = [a-a, b-b, c-c].

:- end_tests(pipeline_map).

:- begin_tests(pipeline_filter).

test(filter_even) :-
    % Keep only even numbers.
    pipeline_filter([X]>>(0 is X mod 2), [1,2,3,4,5,6], Kept),
    Kept = [2,4,6].

test(filter_all) :-
    % All pass: kept = input.
    pipeline_filter([X]>>(X > 0), [1,2,3], Kept),
    Kept = [1,2,3].

test(filter_none) :-
    % None pass: kept = [].
    pipeline_filter([X]>>(X > 100), [1,2,3], Kept),
    Kept = [].

test(filter_empty) :-
    % Empty list: kept = [].
    pipeline_filter([X]>>(X > 0), [], Kept),
    Kept = [].

:- end_tests(pipeline_filter).

:- begin_tests(pipeline_fold).

test(fold_sum) :-
    % Fold sum: 1+2+3+4 = 10.
    pipeline_fold([X, Acc, Acc2]>>(Acc2 is Acc + X), [1,2,3,4], 0, Sum),
    Sum =:= 10.

test(fold_product) :-
    % Fold product: 1*2*3*4 = 24.
    pipeline_fold([X, Acc, Acc2]>>(Acc2 is Acc * X), [1,2,3,4], 1, Prod),
    Prod =:= 24.

test(fold_empty) :-
    % Empty list: accumulator unchanged.
    pipeline_fold([X, A, B]>>(B is A + X), [], 7, Result),
    Result =:= 7.

test(fold_reverse) :-
    % Fold to reverse a list.
    pipeline_fold([X, Acc, [X|Acc]]>>true, [1,2,3], [], Rev),
    Rev = [3,2,1].

:- end_tests(pipeline_fold).

:- begin_tests(pipeline_zip).

test(zip_basic) :-
    % Zip two equal-length lists.
    pipeline_zip([1,2,3], [a,b,c], Pairs),
    Pairs = [1-a, 2-b, 3-c].

test(zip_empty) :-
    % Zip two empty lists.
    pipeline_zip([], [], Pairs),
    Pairs = [].

test(zip_single) :-
    % Single-element lists.
    pipeline_zip([x], [y], Pairs),
    Pairs = [x-y].

:- end_tests(pipeline_zip).

:- begin_tests(pipeline_unzip).

test(unzip_basic) :-
    % Unzip a list of pairs.
    pipeline_unzip([1-a, 2-b, 3-c], Ls, Rs),
    Ls = [1,2,3],
    Rs = [a,b,c].

test(unzip_empty) :-
    % Unzip an empty list.
    pipeline_unzip([], Ls, Rs),
    Ls = [],
    Rs = [].

test(unzip_single) :-
    % Single-pair list.
    pipeline_unzip([x-y], Ls, Rs),
    Ls = [x],
    Rs = [y].

:- end_tests(pipeline_unzip).

:- begin_tests(pipeline_take).

test(take_basic) :-
    % Take 3 from a 5-element list.
    pipeline_take(3, [1,2,3,4,5], Taken),
    Taken = [1,2,3].

test(take_zero) :-
    % Take 0: empty list.
    pipeline_take(0, [1,2,3], Taken),
    Taken = [].

test(take_more_than_length) :-
    % Take more than available: return full list.
    pipeline_take(10, [1,2,3], Taken),
    Taken = [1,2,3].

test(take_exact) :-
    % Take exactly the list length.
    pipeline_take(4, [a,b,c,d], Taken),
    Taken = [a,b,c,d].

:- end_tests(pipeline_take).

:- begin_tests(pipeline_drop).

test(drop_basic) :-
    % Drop 2 from a 5-element list.
    pipeline_drop(2, [1,2,3,4,5], Rest),
    Rest = [3,4,5].

test(drop_zero) :-
    % Drop 0: list unchanged.
    pipeline_drop(0, [1,2,3], Rest),
    Rest = [1,2,3].

test(drop_more_than_length) :-
    % Drop more than available: empty list.
    pipeline_drop(10, [1,2,3], Rest),
    Rest = [].

test(drop_all) :-
    % Drop exactly the list length: empty list.
    pipeline_drop(3, [a,b,c], Rest),
    Rest = [].

:- end_tests(pipeline_drop).

:- begin_tests(pipeline_partition).

test(partition_basic) :-
    % Partition by even/odd.
    pipeline_partition([X]>>(0 is X mod 2), [1,2,3,4,5,6], Evens, Odds),
    Evens = [2,4,6],
    Odds = [1,3,5].

test(partition_all_sat) :-
    % All satisfy: rejected is empty.
    pipeline_partition([X]>>(X > 0), [1,2,3], Sat, Rej),
    Sat = [1,2,3],
    Rej = [].

test(partition_none_sat) :-
    % None satisfy: satisfied is empty.
    pipeline_partition([X]>>(X > 100), [1,2,3], Sat, Rej),
    Sat = [],
    Rej = [1,2,3].

test(partition_empty) :-
    % Empty list: both parts empty.
    pipeline_partition([X]>>(X > 0), [], Sat, Rej),
    Sat = [],
    Rej = [].

:- end_tests(pipeline_partition).
