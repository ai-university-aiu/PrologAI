/*  PrologAI — Agency Unit Tests  (PR 54)

    Acceptance criteria:
        AC-AG-001: agency_loop_create/3 allocates a unique loop ID
        AC-AG-002: agency_loop_create/3 sets the initial budget correctly
        AC-AG-003: agency_push_subgoal/2 adds a goal to the goal stack
        AC-AG-004: agency_pop_subgoal/2 removes the top goal from the goal stack
        AC-AG-005: agency_budget_remaining/2 returns the initial budget
        AC-AG-006: agency_budget_decrement/1 reduces the budget by one
        AC-AG-007: agency_loop_done/1 is false for a running loop
        AC-AG-008: agency_step_record/4 stores a step in the trace
        AC-AG-009: agency_loop_trace/2 returns all recorded steps
        AC-AG-010: agency_escalate/2 sets the loop status to escalated
*/

% Declare this file as the 'test_agency' module.
:- module(test_agency, []).

% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load the agency module under test.
:- use_module(library(agency)).

% Begin the test suite.
:- begin_tests(agency).

% AC-AG-001: agency_loop_create/3 allocates a unique loop ID.
test(loop_create_unique, []) :-
    % Create two loops.
    agency_loop_create(goal_a, 5, LoopId1),
    agency_loop_create(goal_b, 5, LoopId2),
    % They must have different IDs.
    LoopId1 \= LoopId2.

% AC-AG-002: agency_loop_create/3 sets the initial budget correctly.
test(loop_create_budget, []) :-
    % Create a loop with budget 7.
    agency_loop_create(test_goal, 7, LoopId),
    % The remaining budget must be 7.
    agency_budget_remaining(LoopId, 7).

% AC-AG-003: agency_push_subgoal/2 adds a goal to the goal stack.
test(push_subgoal, []) :-
    % Create a loop.
    agency_loop_create(outer_goal, 5, LoopId),
    % Push a subgoal.
    agency_push_subgoal(LoopId, subgoal_x),
    % The goal stack must contain the pushed subgoal at the front.
    agency:agency_goal_stack(LoopId, [subgoal_x | _]).

% AC-AG-004: agency_pop_subgoal/2 removes the top goal from the goal stack.
test(pop_subgoal, []) :-
    % Create a loop.
    agency_loop_create(outer_pop, 5, LoopId),
    % Push two subgoals.
    agency_push_subgoal(LoopId, goal_first),
    agency_push_subgoal(LoopId, goal_second),
    % Pop the top subgoal (should be goal_second, pushed last).
    agency_pop_subgoal(LoopId, Popped),
    % Must be the most recently pushed subgoal.
    Popped = goal_second.

% AC-AG-005: agency_budget_remaining/2 returns the initial budget after creation.
test(budget_initial, []) :-
    % Create a loop with budget 10.
    agency_loop_create(budget_test, 10, LoopId),
    % Budget must be 10.
    agency_budget_remaining(LoopId, 10).

% AC-AG-006: agency_budget_decrement/1 reduces the budget by exactly one.
test(budget_decrement, []) :-
    % Create a loop with budget 5.
    agency_loop_create(dec_test, 5, LoopId),
    % Decrement the budget.
    agency_budget_decrement(LoopId),
    % Budget must now be 4.
    agency_budget_remaining(LoopId, 4).

% AC-AG-007: agency_loop_done/1 is false for a freshly created running loop.
test(loop_not_done_initially, [fail]) :-
    % Create a fresh loop.
    agency_loop_create(not_done, 5, LoopId),
    % This test is marked [fail], so it passes only if agency_loop_done/1 fails.
    agency_loop_done(LoopId).

% AC-AG-008: agency_step_record/4 stores a step in the trace.
test(step_record, []) :-
    % Create a loop.
    agency_loop_create(record_test, 5, LoopId),
    % Record one step.
    agency_step_record(LoopId, thought_a, action_b, obs_c),
    % Verify the step fact exists.
    agency:agency_step_fact(LoopId, _, thought_a, action_b, obs_c).

% AC-AG-009: agency_loop_trace/2 returns all recorded steps.
test(loop_trace, []) :-
    % Create a loop.
    agency_loop_create(trace_test, 5, LoopId),
    % Record two steps.
    agency_step_record(LoopId, t1, a1, o1),
    agency_step_record(LoopId, t2, a2, o2),
    % Retrieve the trace.
    agency_loop_trace(LoopId, Steps),
    % The trace must have exactly two entries.
    length(Steps, 2).

% AC-AG-010: agency_escalate/2 sets the loop status to escalated(Reason).
test(escalate, []) :-
    % Create a loop.
    agency_loop_create(escalate_test, 5, LoopId),
    % Escalate with a reason.
    agency_escalate(LoopId, stuck_in_loop),
    % The loop must now be done (escalated is a terminal state).
    agency_loop_done(LoopId),
    % The outcome must be escalated with the given reason.
    agency_loop_outcome(LoopId, escalated(stuck_in_loop)).

% End the test suite.
:- end_tests(agency).
