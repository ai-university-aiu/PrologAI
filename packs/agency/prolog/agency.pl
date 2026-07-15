/*  PrologAI — Agency: Agentic Execution Loop  (Specification PR 54)

    Gives PrologAI a formal, observable, bounded execution loop for pursuing
    goals through sequences of reasoning and action steps.

    Inspired by:
    - Agentic AI Principles Parts 2-3 (bounded autonomy, reasoning, planning)
    - Agentic AI Patterns Parts 4-6 (core patterns, workflow, planning)
    - The silicon-and-code substrate approach: use proven agentic patterns
      directly rather than simulating the neuroscience of goal pursuit.

    The Loop Lifecycle:
    1. agency_loop_create/3  -- allocate a loop ID, set goal and step budget
    2. agency_loop_run/3     -- run observe-reason-act-observe until done or limit
    3. agency_loop_outcome/2 -- retrieve the final outcome
    4. agency_loop_trace/2   -- retrieve the full trace of steps

    Within each step:
    - The current goal and state are examined.
    - An action is chosen from the available action types.
    - The action is executed.
    - The observation is incorporated into the new state.

    Action types (dispatched by agency_act/3):
    - action_eval(GoalTerm)          -- evaluate a Prolog goal via ephemera
    - action_shell(Argv, Timeout)    -- run a shell command via ephemera
    - action_push_goal(Subgoal)      -- push a subgoal onto the goal stack
    - action_push_goals(Subgoals)    -- push multiple subgoals
    - action_mark_done(Result)       -- declare the loop done with a result
    - action_escalate(Reason)        -- request human oversight

    Loop control:
    - agency_budget_decrement/1  -- use one step of the budget
    - agency_detect_loop/2       -- detect repeated thought-action pairs
    - agency_push_subgoal/2      -- add a subgoal to the goal stack
    - agency_pop_subgoal/2       -- remove and return the next subgoal
    - agency_escalate/2          -- record an escalation event

    Predicates:
      agency_loop_create/3     -- +Goal, +Budget, -LoopId
      agency_loop_run/3        -- +LoopId, :ReasonGoal, -Outcome
      agency_loop_step/3       -- +LoopId, :ReasonGoal, -StepResult
      agency_loop_done/1       -- +LoopId
      agency_loop_outcome/2    -- +LoopId, -Outcome
      agency_loop_trace/2      -- +LoopId, -StepList
      agency_push_subgoal/2    -- +LoopId, +Subgoal
      agency_pop_subgoal/2     -- +LoopId, -Subgoal
      agency_budget_remaining/2-- +LoopId, -N
      agency_budget_decrement/1-- +LoopId
      agency_detect_loop/2     -- +LoopId, -Bool
      agency_escalate/2        -- +LoopId, +Reason
      agency_step_record/4     -- +LoopId, +Thought, +Action, +Observation
*/

% Declare this file as the 'agency' module and list its exported predicates.
:- module(agency, [
    % Export agency_loop_create/3: allocate a new loop.
    agency_loop_create/3,    % +Goal, +Budget, -LoopId
    % Export agency_loop_run/3: run the full loop to completion.
    agency_loop_run/3,       % +LoopId, :ReasonGoal, -Outcome
    % Export agency_loop_step/3: execute a single loop step.
    agency_loop_step/3,      % +LoopId, :ReasonGoal, -StepResult
    % Export agency_loop_done/1: check whether a loop has reached a terminal state.
    agency_loop_done/1,      % +LoopId
    % Export agency_loop_outcome/2: retrieve the final outcome of a completed loop.
    agency_loop_outcome/2,   % +LoopId, -Outcome
    % Export agency_loop_trace/2: retrieve all recorded steps of a loop.
    agency_loop_trace/2,     % +LoopId, -StepList
    % Export agency_push_subgoal/2: push one subgoal onto the loop's goal stack.
    agency_push_subgoal/2,   % +LoopId, +Subgoal
    % Export agency_pop_subgoal/2: pop the next subgoal from the loop's goal stack.
    agency_pop_subgoal/2,    % +LoopId, -Subgoal
    % Export agency_budget_remaining/2: query remaining step budget.
    agency_budget_remaining/2, % +LoopId, -N
    % Export agency_budget_decrement/1: consume one step of the budget.
    agency_budget_decrement/1, % +LoopId
    % Export agency_detect_loop/2: detect whether the loop is stuck repeating.
    agency_detect_loop/2,    % +LoopId, -Bool
    % Export agency_escalate/2: record an escalation to human oversight.
    agency_escalate/2,       % +LoopId, +Reason
    % Export agency_step_record/4: record one observe-reason-act-observe step.
    agency_step_record/4     % +LoopId, +Thought, +Action, +Observation
% Close the module declaration.
]).

% Import ephemera_eval and ephemera_shell from the ephemera pack for code execution.
:- use_module(library(ephemera), [ephemera_eval/3, ephemera_shell/3]).
% Import lists predicates.
:- use_module(library(lists),    [member/2, last/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% agency_loop_meta/4: (LoopId, Goal, BudgetRemaining, Status)
%   Status = running | done(Result) | escalated(Reason) | budget_exhausted
:- dynamic agency_loop_meta/4.

% agency_goal_stack/2: (LoopId, [Subgoal | Rest]) -- ordered subgoal list.
:- dynamic agency_goal_stack/2.

% agency_step_fact/5: (LoopId, StepNum, Thought, Action, Observation)
:- dynamic agency_step_fact/5.

% agency_step_counter/2: (LoopId, StepCount) -- number of steps taken so far.
:- dynamic agency_step_counter/2.

% agency_escalation/2: (LoopId, Reason) -- escalation records.
:- dynamic agency_escalation/2.

% agency_loop_id_counter/1: global counter for unique loop IDs.
:- dynamic agency_loop_id_counter/1.
% Initialize loop ID counter.
agency_loop_id_counter(0).

% ---------------------------------------------------------------------------
% agency_loop_create/3 -- allocate a new loop with a goal and step budget
% ---------------------------------------------------------------------------

% Define agency_loop_create: allocate unique ID, initialize all state facts.
agency_loop_create(Goal, Budget, LoopId) :-
    % Allocate a unique loop ID.
    retract(agency_loop_id_counter(N)),
    N1 is N + 1,
    assertz(agency_loop_id_counter(N1)),
    atomic_list_concat([agency_loop_, N1], LoopId),
    % Store the loop metadata: goal, budget, initial status = running.
    assertz(agency_loop_meta(LoopId, Goal, Budget, running)),
    % Initialize the goal stack with the top-level goal.
    assertz(agency_goal_stack(LoopId, [Goal])),
    % Initialize the step counter to zero.
    assertz(agency_step_counter(LoopId, 0)).

% ---------------------------------------------------------------------------
% agency_loop_run/3 -- run the full observe-reason-act-observe loop
% ---------------------------------------------------------------------------

% Define agency_loop_run: iterate steps until the loop reaches a terminal state.
agency_loop_run(LoopId, ReasonGoal, Outcome) :-
    % Check if the loop is already done before starting.
    ( agency_loop_done(LoopId)
    % If already done, retrieve the existing outcome.
    ->  agency_loop_outcome(LoopId, Outcome)
    % Otherwise, take one step and continue.
    ;   agency_loop_step(LoopId, ReasonGoal, _StepResult),
        agency_loop_run(LoopId, ReasonGoal, Outcome)
    ).

% ---------------------------------------------------------------------------
% agency_loop_step/3 -- execute one step of the agentic loop
% ---------------------------------------------------------------------------

% Define agency_loop_step: check preconditions, reason, act, record.
agency_loop_step(LoopId, _ReasonGoal, step_done(Outcome)) :-
    % If loop is already done, just return the existing outcome.
    agency_loop_done(LoopId), !,
    agency_loop_outcome(LoopId, Outcome).
agency_loop_step(LoopId, _ReasonGoal, step_budget_exhausted) :-
    % If budget is zero, mark loop exhausted.
    agency_budget_remaining(LoopId, 0), !,
    agency_loop_set_status(LoopId, budget_exhausted).
agency_loop_step(LoopId, ReasonGoal, step_ok(Thought, Action, Observation)) :-
    % Decrement the step budget.
    agency_budget_decrement(LoopId),
    % Get the current goal from the top of the goal stack.
    ( agency_goal_stack(LoopId, [CurrentGoal | _])
    ->  true
    ;   CurrentGoal = none
    ),
    % Call the ReasonGoal to produce a Thought and an Action for this step.
    call(ReasonGoal, LoopId, CurrentGoal, Thought, Action),
    % Execute the chosen Action and produce an Observation.
    agency_act(LoopId, Action, Observation),
    % Record this step in the trace log.
    agency_step_record(LoopId, Thought, Action, Observation).

% ---------------------------------------------------------------------------
% agency_act/3 -- dispatch and execute an action, return an observation
% ---------------------------------------------------------------------------

% Define agency_act for action_eval(GoalTerm): call a Prolog goal via ephemera.
agency_act(_LoopId, action_eval(GoalTerm), obs_eval(EvalResult)) :-
    % Evaluate the goal term with a 30-second default timeout.
    ephemera_eval(GoalTerm, 30, EvalResult).

% Define agency_act for action_shell(Argv, Timeout): run a shell command.
agency_act(_LoopId, action_shell(Argv, Timeout), obs_shell(ShellResult)) :-
    % Execute the shell command via ephemera_shell.
    ephemera_shell(Argv, Timeout, ShellResult).

% Define agency_act for action_push_goal(Subgoal): push one subgoal.
agency_act(LoopId, action_push_goal(Subgoal), obs_pushed(Subgoal)) :-
    % Push the subgoal onto the goal stack.
    agency_push_subgoal(LoopId, Subgoal).

% Define agency_act for action_push_goals(Subgoals): push a list of subgoals.
agency_act(LoopId, action_push_goals(Subgoals), obs_pushed_many(N)) :-
    % Push each subgoal in order.
    maplist(agency_push_subgoal(LoopId), Subgoals),
    % Report how many were pushed.
    length(Subgoals, N).

% Define agency_act for action_mark_done(Result): declare the loop done.
agency_act(LoopId, action_mark_done(Result), obs_done(Result)) :-
    % Update the loop status to done with the given result.
    agency_loop_set_status(LoopId, done(Result)).

% Define agency_act for action_escalate(Reason): record escalation.
agency_act(LoopId, action_escalate(Reason), obs_escalated(Reason)) :-
    % Record the escalation and mark the loop status.
    agency_escalate(LoopId, Reason).

% Define agency_act for action_pop_goal: pop the current subgoal when it is done.
agency_act(LoopId, action_pop_goal, obs_popped(Popped)) :-
    % Pop the top subgoal.
    agency_pop_subgoal(LoopId, Popped).

% Define agency_act for an unknown action: record a warning observation.
agency_act(_LoopId, UnknownAction, obs_unknown_action(UnknownAction)) :- !.

% Helper: map agency_push_subgoal with LoopId as first arg for maplist.
% Define agency_push_subgoal_for_loop: push one subgoal using the captured LoopId.
agency_push_subgoal_for_loop(LoopId, Goal) :- agency_push_subgoal(LoopId, Goal).

% Define maplist/2 usage for pushing subgoals -- use forall instead.
% Override: maplist over a list calling agency_push_subgoal(LoopId, Goal).
maplist(_, []).
maplist(Goal, [H|T]) :- call(Goal, H), maplist(Goal, T).

% ---------------------------------------------------------------------------
% agency_loop_done/1 -- true when loop has reached a terminal state
% ---------------------------------------------------------------------------

% Define agency_loop_done: succeed when the status is not 'running'.
agency_loop_done(LoopId) :-
    % Retrieve the loop metadata.
    agency_loop_meta(LoopId, _, _, Status),
    % The loop is done if the status is anything other than running.
    Status \= running.

% ---------------------------------------------------------------------------
% agency_loop_outcome/2 -- retrieve the final outcome of a completed loop
% ---------------------------------------------------------------------------

% Define agency_loop_outcome: return the status as the outcome.
agency_loop_outcome(LoopId, Outcome) :-
    % Retrieve the stored status.
    agency_loop_meta(LoopId, _, _, Outcome).

% ---------------------------------------------------------------------------
% agency_loop_set_status/2 -- update the loop status (internal)
% ---------------------------------------------------------------------------

% Define agency_loop_set_status: retract and reassert the metadata with new status.
agency_loop_set_status(LoopId, NewStatus) :-
    % Retract the current metadata.
    retract(agency_loop_meta(LoopId, Goal, Budget, _OldStatus)),
    % Reassert with the new status.
    assertz(agency_loop_meta(LoopId, Goal, Budget, NewStatus)).

% ---------------------------------------------------------------------------
% agency_loop_trace/2 -- retrieve all recorded steps
% ---------------------------------------------------------------------------

% Define agency_loop_trace: collect all step facts for the loop.
agency_loop_trace(LoopId, Steps) :-
    % Collect all step records, preserving step number for sorting.
    findall(step(N, T, A, O),
            agency_step_fact(LoopId, N, T, A, O),
            Steps).

% ---------------------------------------------------------------------------
% agency_step_record/4 -- record one step to the trace log
% ---------------------------------------------------------------------------

% Define agency_step_record: increment counter and store step fact.
agency_step_record(LoopId, Thought, Action, Observation) :-
    % Get and increment the step counter.
    retract(agency_step_counter(LoopId, N)),
    N1 is N + 1,
    assertz(agency_step_counter(LoopId, N1)),
    % Store the step record.
    assertz(agency_step_fact(LoopId, N1, Thought, Action, Observation)).

% ---------------------------------------------------------------------------
% agency_push_subgoal/2 -- push one subgoal onto the front of the goal stack
% ---------------------------------------------------------------------------

% Define agency_push_subgoal: retract and reassert the goal stack with new head.
agency_push_subgoal(LoopId, Subgoal) :-
    % Retract the current goal stack.
    ( retract(agency_goal_stack(LoopId, Stack))
    ->  true
    ;   Stack = []
    ),
    % Push the new subgoal to the front.
    assertz(agency_goal_stack(LoopId, [Subgoal | Stack])).

% ---------------------------------------------------------------------------
% agency_pop_subgoal/2 -- pop the top subgoal from the goal stack
% ---------------------------------------------------------------------------

% Define agency_pop_subgoal: retract the stack, return its head, reassert the tail.
agency_pop_subgoal(LoopId, Subgoal) :-
    % Retract the current goal stack.
    retract(agency_goal_stack(LoopId, [Subgoal | Rest])),
    % Reassert with the top goal removed.
    assertz(agency_goal_stack(LoopId, Rest)).

% ---------------------------------------------------------------------------
% agency_budget_remaining/2 -- query how many steps are left in the budget
% ---------------------------------------------------------------------------

% Define agency_budget_remaining: retrieve from the loop metadata.
agency_budget_remaining(LoopId, N) :-
    % Read the current budget from the metadata fact.
    agency_loop_meta(LoopId, _, N, _).

% ---------------------------------------------------------------------------
% agency_budget_decrement/1 -- consume one step of the budget
% ---------------------------------------------------------------------------

% Define agency_budget_decrement: update the budget in the metadata.
agency_budget_decrement(LoopId) :-
    % Retract the current metadata.
    retract(agency_loop_meta(LoopId, Goal, Budget, Status)),
    % Compute new budget (floor at zero).
    NewBudget is max(0, Budget - 1),
    % Reassert with decremented budget.
    assertz(agency_loop_meta(LoopId, Goal, NewBudget, Status)).

% ---------------------------------------------------------------------------
% agency_detect_loop/2 -- detect whether the loop is stuck repeating itself
%
% Examines the last four steps; returns true if the last two Thought-Action
% pairs are identical (a direct repeat), which is a common failure mode of
% agentic loops.
% ---------------------------------------------------------------------------

% Define agency_detect_loop: check for repeated thought-action pairs.
agency_detect_loop(LoopId, IsLooping) :-
    % Collect all thought-action pairs in step order.
    findall(T-A, agency_step_fact(LoopId, _, T, A, _), TAPairs),
    % Check if the last two thought-action pairs are identical.
    ( TAPairs = [_|_],
      last(TAPairs, LastTA),
      append(_, [LastTA, LastTA], TAPairs)
    ->  IsLooping = true
    ;   IsLooping = false
    ).

% ---------------------------------------------------------------------------
% agency_escalate/2 -- record an escalation to human oversight
% ---------------------------------------------------------------------------

% Define agency_escalate: store escalation and update loop status.
agency_escalate(LoopId, Reason) :-
    % Store the escalation record.
    assertz(agency_escalation(LoopId, Reason)),
    % Update the loop status to escalated.
    agency_loop_set_status(LoopId, escalated(Reason)).
