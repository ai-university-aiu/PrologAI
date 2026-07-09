/*  PrologAI — Hierarchical Planner Pack Test Suite  (WP-386)

    Acceptance tests for all ht_* predicates.

    Run with:
        swipl -g "run_tests, halt" test_planner.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/planner').

% ===========================================================================
% TEST FIXTURE DOMAIN — TRAVELLING BY FOOT OR BY TAXI
% ===========================================================================

% The travel domain: walk short distances, take a taxi otherwise.
travel_domain(Domain) :-
    % Assemble the domain from primitives and methods.
    ht_domain(
        % The four primitive actions.
        [prim(walk(X1, Y1), [at(me, X1), short(X1, Y1)], [at(me, Y1)], [at(me, X1)]),
         prim(call_taxi(X2), [at(me, X2)], [taxi_at(X2)], []),
         prim(ride(X3, Y3), [at(me, X3), taxi_at(X3)], [at(me, Y3)], [at(me, X3), taxi_at(X3)]),
         prim(pay, [has_cash], [paid], [has_cash])],
        % The decomposition methods; walking is preferred when possible.
        [meth(go_by_foot, travel(X4, Y4), [short(X4, Y4)], [walk(X4, Y4)]),
         meth(go_by_taxi, travel(X5, Y5), [has_cash], [call_taxi(X5), ride(X5, Y5), pay]),
         meth(two_leg, trip(X6, Y6, Z6), [], [travel(X6, Y6), travel(Y6, Z6)])],
        Domain).

% A recursive domain used to prove the depth bound terminates.
loopy_domain(Domain) :-
    % A single method that decomposes a task into itself forever.
    ht_domain([], [meth(loop_m, loopy, [], [loopy])], Domain).

% ===========================================================================
% DOMAIN CLASSIFICATION
% ===========================================================================

:- begin_tests(planner_domain).

% Primitive tasks are recognized.
test(primitive_recognized) :-
    % Build the travel domain.
    travel_domain(D),
    % Walking is a primitive action.
    ht_primitive(D, walk(home, park)).

% Compound tasks are recognized.
test(compound_recognized) :-
    % Build the travel domain.
    travel_domain(D),
    % Travelling is a compound task.
    ht_compound(D, travel(home, park)).

% A compound task is not a primitive.
test(compound_not_primitive, [fail]) :-
    % Build the travel domain.
    travel_domain(D),
    % Travelling has no primitive declaration.
    ht_primitive(D, travel(home, park)).

% The matching methods are reported in declaration order.
test(methods_in_order) :-
    % Build the travel domain.
    travel_domain(D),
    % Both travel methods match a travel task.
    ht_methods_for(D, travel(home, park), Names),
    % Walking is declared first, so it is preferred.
    Names == [go_by_foot, go_by_taxi].

% A malformed method declaration is rejected.
test(bad_method_rejected, [fail]) :-
    % The subtasks slot must be a list.
    ht_domain([], [meth(bad, t, [], not_a_list)], _).

:- end_tests(planner_domain).

% ===========================================================================
% PLANNING BY DECOMPOSITION
% ===========================================================================

:- begin_tests(planner_plan).

% A short distance decomposes to the preferred walking method.
test(plan_prefers_walking) :-
    % Build the travel domain.
    travel_domain(D),
    % Home and park are within walking distance.
    State = [at(me, home), short(home, park), has_cash],
    % Plan the journey.
    ht_plan(D, State, [travel(home, park)], 10, Plan),
    % The first plan found uses the preferred method.
    Plan == [walk(home, park)],
    % Commit to the first plan.
    !.

% A long distance falls through to the taxi method by backtracking.
test(plan_falls_back_to_taxi) :-
    % Build the travel domain.
    travel_domain(D),
    % No short-distance fluent, so walking is impossible.
    State = [at(me, home), has_cash],
    % Plan the journey.
    ht_plan(D, State, [travel(home, park)], 10, Plan),
    % The taxi method expands to its three primitive steps.
    Plan == [call_taxi(home), ride(home, park), pay],
    % Commit to the first plan.
    !.

% With neither walking distance nor cash, no plan exists.
test(plan_impossible, [fail]) :-
    % Build the travel domain.
    travel_domain(D),
    % No way to travel at all.
    ht_plan(D, [at(me, home)], [travel(home, park)], 10, _).

% Nested compound tasks decompose recursively across two legs.
test(plan_nested_trip) :-
    % Build the travel domain.
    travel_domain(D),
    % The first leg is walkable; the second needs a taxi.
    State = [at(me, home), short(home, park), has_cash],
    % Plan the two-leg trip.
    ht_plan(D, State, [trip(home, park, museum)], 10, Plan),
    % Walking covers leg one; the taxi covers leg two.
    Plan == [walk(home, park), call_taxi(park), ride(park, museum), pay],
    % Commit to the first plan.
    !.

% The depth bound terminates even a hopelessly recursive method set.
test(depth_bound_terminates, [fail]) :-
    % Build the recursive domain.
    loopy_domain(D),
    % The looping task can never bottom out.
    ht_plan(D, [], [loopy], 5, _).

% The plan cost counts the primitive steps.
test(plan_cost) :-
    % Cost of a three-step plan.
    ht_plan_cost([a, b, c], Cost),
    % Check the count.
    Cost =:= 3.

:- end_tests(planner_plan).

% ===========================================================================
% GLASS-BOX PLAN TREES
% ===========================================================================

:- begin_tests(planner_tree).

% The tree records which method was chosen for the compound task.
test(tree_shows_method) :-
    % Build the travel domain.
    travel_domain(D),
    % Home and park are within walking distance.
    State = [at(me, home), short(home, park), has_cash],
    % Build the decomposition tree.
    ht_task_tree(D, State, travel(home, park), 10, Tree),
    % The tree names the chosen method and its primitive leaf.
    Tree == tree(travel(home, park), go_by_foot, [primitive(walk(home, park))]),
    % Commit to the first tree.
    !.

% A nested trip yields a tree with one subtree per leg.
test(tree_nested) :-
    % Build the travel domain.
    travel_domain(D),
    % The first leg is walkable; the second needs a taxi.
    State = [at(me, home), short(home, park), has_cash],
    % Build the decomposition tree.
    ht_task_tree(D, State, trip(home, park, museum), 10, Tree),
    % The root uses the two-leg method.
    Tree = tree(trip(home, park, museum), two_leg, [Leg1, Leg2]),
    % Leg one decomposes by foot.
    Leg1 = tree(travel(home, park), go_by_foot, _),
    % Leg two decomposes by taxi.
    Leg2 = tree(travel(park, museum), go_by_taxi, _),
    % Commit to the first tree.
    !.

:- end_tests(planner_tree).

% ===========================================================================
% EXECUTION AND MONITORING
% ===========================================================================

:- begin_tests(planner_execute).

% Executing the taxi plan reaches the park and spends the cash.
test(execute_taxi_plan, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % Start at home with cash.
    State = [at(me, home), has_cash],
    % Run the three-step taxi plan.
    ht_execute(D, State, [call_taxi(home), ride(home, park), pay], Final),
    % The traveller arrived.
    memberchk(at(me, park), Final),
    % The fare was paid.
    memberchk(paid, Final),
    % The cash is gone.
    \+ memberchk(has_cash, Final).

% A plan that executes end to end is valid.
test(valid_plan, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % Start at home with cash.
    ht_valid_plan(D, [at(me, home), has_cash],
        % The full taxi plan.
        [call_taxi(home), ride(home, park), pay]).

% Monitoring a runnable plan reports ok.
test(monitor_ok, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % Start at home with cash.
    ht_monitor(D, [at(me, home), has_cash],
        % The full taxi plan.
        [call_taxi(home), ride(home, park), pay], Status),
    % Every step runs.
    Status == ok.

% Monitoring reports the first step that can no longer run.
test(monitor_detects_break) :-
    % Build the travel domain.
    travel_domain(D),
    % The cash disappeared before execution.
    ht_monitor(D, [at(me, home)],
        % The full taxi plan.
        [call_taxi(home), ride(home, park), pay], Status),
    % The third step, paying, is the first to fail.
    Status == fails_at(3, pay).

% Replanning from the broken situation finds a fresh valid plan.
test(replan_recovers) :-
    % Build the travel domain.
    travel_domain(D),
    % The new situation: no cash, but the park is now walkable.
    State = [at(me, home), short(home, park)],
    % Plan again from the new situation.
    ht_replan(D, State, [travel(home, park)], 10, Plan),
    % Walking saves the day.
    Plan == [walk(home, park)],
    % Commit to the first plan.
    !.

:- end_tests(planner_execute).
