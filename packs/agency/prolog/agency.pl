/*  PrologAI — Agency: Agentic Execution Loop  (Specification PR 54)

    Gives PrologAI a formal, observable, bounded execution loop for pursuing
    goals through sequences of reasoning and action steps.

    Inspired by:
    - Agentic AI Principles Parts 2-3 (bounded autonomy, reasoning, planning)
    - Agentic AI Patterns Parts 4-6 (core patterns, workflow, planning)
    - The silicon-and-code substrate approach: use proven agentic patterns
      directly rather than simulating the neuroscience of goal pursuit.

    The Loop Lifecycle:
    1. ag_loop_create/3  -- allocate a loop ID, set goal and step budget
    2. ag_loop_run/3     -- run observe-reason-act-observe until done or limit
    3. ag_loop_outcome/2 -- retrieve the final outcome
    4. ag_loop_trace/2   -- retrieve the full trace of steps

    Within each step:
    - The current goal and state are examined.
    - An action is chosen from the available action types.
    - The action is executed.
    - The observation is incorporated into the new state.

    Action types (dispatched by ag_act/3):
    - action_eval(GoalTerm)          -- evaluate a Prolog goal via ephemera
    - action_shell(Argv, Timeout)    -- run a shell command via ephemera
    - action_push_goal(Subgoal)      -- push a subgoal onto the goal stack
    - action_push_goals(Subgoals)    -- push multiple subgoals
    - action_mark_done(Result)       -- declare the loop done with a result
    - action_escalate(Reason)        -- request human oversight

    Loop control:
    - ag_budget_decrement/1  -- use one step of the budget
    - ag_detect_loop/2       -- detect repeated thought-action pairs
    - ag_push_subgoal/2      -- add a subgoal to the goal stack
    - ag_pop_subgoal/2       -- remove and return the next subgoal
    - ag_escalate/2          -- record an escalation event

    Predicates:
      ag_loop_create/3     -- +Goal, +Budget, -LoopId
      ag_loop_run/3        -- +LoopId, :ReasonGoal, -Outcome
      ag_loop_step/3       -- +LoopId, :ReasonGoal, -StepResult
      ag_loop_done/1       -- +LoopId
      ag_loop_outcome/2    -- +LoopId, -Outcome
      ag_loop_trace/2      -- +LoopId, -StepList
      ag_push_subgoal/2    -- +LoopId, +Subgoal
      ag_pop_subgoal/2     -- +LoopId, -Subgoal
      ag_budget_remaining/2-- +LoopId, -N
      ag_budget_decrement/1-- +LoopId
      ag_detect_loop/2     -- +LoopId, -Bool
      ag_escalate/2        -- +LoopId, +Reason
      ag_step_record/4     -- +LoopId, +Thought, +Action, +Observation
*/

% Declare this file as the 'agency' module and list its exported predicates.
:- module(agency, [
    % Export ag_loop_create/3: allocate a new loop.
    ag_loop_create/3,    % +Goal, +Budget, -LoopId
    % Export ag_loop_run/3: run the full loop to completion.
    ag_loop_run/3,       % +LoopId, :ReasonGoal, -Outcome
    % Export ag_loop_step/3: execute a single loop step.
    ag_loop_step/3,      % +LoopId, :ReasonGoal, -StepResult
    % Export ag_loop_done/1: check whether a loop has reached a terminal state.
    ag_loop_done/1,      % +LoopId
    % Export ag_loop_outcome/2: retrieve the final outcome of a completed loop.
    ag_loop_outcome/2,   % +LoopId, -Outcome
    % Export ag_loop_trace/2: retrieve all recorded steps of a loop.
    ag_loop_trace/2,     % +LoopId, -StepList
    % Export ag_push_subgoal/2: push one subgoal onto the loop's goal stack.
    ag_push_subgoal/2,   % +LoopId, +Subgoal
    % Export ag_pop_subgoal/2: pop the next subgoal from the loop's goal stack.
    ag_pop_subgoal/2,    % +LoopId, -Subgoal
    % Export ag_budget_remaining/2: query remaining step budget.
    ag_budget_remaining/2, % +LoopId, -N
    % Export ag_budget_decrement/1: consume one step of the budget.
    ag_budget_decrement/1, % +LoopId
    % Export ag_detect_loop/2: detect whether the loop is stuck repeating.
    ag_detect_loop/2,    % +LoopId, -Bool
    % Export ag_escalate/2: record an escalation to human oversight.
    ag_escalate/2,       % +LoopId, +Reason
    % Export ag_step_record/4: record one observe-reason-act-observe step.
    ag_step_record/4     % +LoopId, +Thought, +Action, +Observation
% Close the module declaration.
]).

% Import ep_eval and ep_shell from the ephemera pack for code execution.
:- use_module(library(ephemera), [ep_eval/3, ep_shell/3]).
% Import lists predicates.
:- use_module(library(lists),    [member/2, last/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% ag_loop_meta/4: (LoopId, Goal, BudgetRemaining, Status)
%   Status = running | done(Result) | escalated(Reason) | budget_exhausted
:- dynamic ag_loop_meta/4.

% ag_goal_stack/2: (LoopId, [Subgoal | Rest]) -- ordered subgoal list.
:- dynamic ag_goal_stack/2.

% ag_step_fact/5: (LoopId, StepNum, Thought, Action, Observation)
:- dynamic ag_step_fact/5.

% ag_step_counter/2: (LoopId, StepCount) -- number of steps taken so far.
:- dynamic ag_step_counter/2.

% ag_escalation/2: (LoopId, Reason) -- escalation records.
:- dynamic ag_escalation/2.

% ag_loop_id_counter/1: global counter for unique loop IDs.
:- dynamic ag_loop_id_counter/1.
% Initialize loop ID counter.
ag_loop_id_counter(0).

% ---------------------------------------------------------------------------
% ag_loop_create/3 -- allocate a new loop with a goal and step budget
% ---------------------------------------------------------------------------

% Define ag_loop_create: allocate unique ID, initialize all state facts.
ag_loop_create(Goal, Budget, LoopId) :-
    % Allocate a unique loop ID.
    retract(ag_loop_id_counter(N)),
    N1 is N + 1,
    assertz(ag_loop_id_counter(N1)),
    atomic_list_concat([ag_loop_, N1], LoopId),
    % Store the loop metadata: goal, budget, initial status = running.
    assertz(ag_loop_meta(LoopId, Goal, Budget, running)),
    % Initialize the goal stack with the top-level goal.
    assertz(ag_goal_stack(LoopId, [Goal])),
    % Initialize the step counter to zero.
    assertz(ag_step_counter(LoopId, 0)).

% ---------------------------------------------------------------------------
% ag_loop_run/3 -- run the full observe-reason-act-observe loop
% ---------------------------------------------------------------------------

% Define ag_loop_run: iterate steps until the loop reaches a terminal state.
ag_loop_run(LoopId, ReasonGoal, Outcome) :-
    % Check if the loop is already done before starting.
    ( ag_loop_done(LoopId)
    % If already done, retrieve the existing outcome.
    ->  ag_loop_outcome(LoopId, Outcome)
    % Otherwise, take one step and continue.
    ;   ag_loop_step(LoopId, ReasonGoal, _StepResult),
        ag_loop_run(LoopId, ReasonGoal, Outcome)
    ).

% ---------------------------------------------------------------------------
% ag_loop_step/3 -- execute one step of the agentic loop
% ---------------------------------------------------------------------------

% Define ag_loop_step: check preconditions, reason, act, record.
ag_loop_step(LoopId, _ReasonGoal, step_done(Outcome)) :-
    % If loop is already done, just return the existing outcome.
    ag_loop_done(LoopId), !,
    ag_loop_outcome(LoopId, Outcome).
ag_loop_step(LoopId, _ReasonGoal, step_budget_exhausted) :-
    % If budget is zero, mark loop exhausted.
    ag_budget_remaining(LoopId, 0), !,
    ag_loop_set_status(LoopId, budget_exhausted).
ag_loop_step(LoopId, ReasonGoal, step_ok(Thought, Action, Observation)) :-
    % Decrement the step budget.
    ag_budget_decrement(LoopId),
    % Get the current goal from the top of the goal stack.
    ( ag_goal_stack(LoopId, [CurrentGoal | _])
    ->  true
    ;   CurrentGoal = none
    ),
    % Call the ReasonGoal to produce a Thought and an Action for this step.
    call(ReasonGoal, LoopId, CurrentGoal, Thought, Action),
    % Execute the chosen Action and produce an Observation.
    ag_act(LoopId, Action, Observation),
    % Record this step in the trace log.
    ag_step_record(LoopId, Thought, Action, Observation).

% ---------------------------------------------------------------------------
% ag_act/3 -- dispatch and execute an action, return an observation
% ---------------------------------------------------------------------------

% Define ag_act for action_eval(GoalTerm): call a Prolog goal via ephemera.
ag_act(_LoopId, action_eval(GoalTerm), obs_eval(EvalResult)) :-
    % Evaluate the goal term with a 30-second default timeout.
    ep_eval(GoalTerm, 30, EvalResult).

% Define ag_act for action_shell(Argv, Timeout): run a shell command.
ag_act(_LoopId, action_shell(Argv, Timeout), obs_shell(ShellResult)) :-
    % Execute the shell command via ep_shell.
    ep_shell(Argv, Timeout, ShellResult).

% Define ag_act for action_push_goal(Subgoal): push one subgoal.
ag_act(LoopId, action_push_goal(Subgoal), obs_pushed(Subgoal)) :-
    % Push the subgoal onto the goal stack.
    ag_push_subgoal(LoopId, Subgoal).

% Define ag_act for action_push_goals(Subgoals): push a list of subgoals.
ag_act(LoopId, action_push_goals(Subgoals), obs_pushed_many(N)) :-
    % Push each subgoal in order.
    maplist(ag_push_subgoal(LoopId), Subgoals),
    % Report how many were pushed.
    length(Subgoals, N).

% Define ag_act for action_mark_done(Result): declare the loop done.
ag_act(LoopId, action_mark_done(Result), obs_done(Result)) :-
    % Update the loop status to done with the given result.
    ag_loop_set_status(LoopId, done(Result)).

% Define ag_act for action_escalate(Reason): record escalation.
ag_act(LoopId, action_escalate(Reason), obs_escalated(Reason)) :-
    % Record the escalation and mark the loop status.
    ag_escalate(LoopId, Reason).

% Define ag_act for action_pop_goal: pop the current subgoal when it is done.
ag_act(LoopId, action_pop_goal, obs_popped(Popped)) :-
    % Pop the top subgoal.
    ag_pop_subgoal(LoopId, Popped).

% Define ag_act for an unknown action: record a warning observation.
ag_act(_LoopId, UnknownAction, obs_unknown_action(UnknownAction)) :- !.

% Helper: map ag_push_subgoal with LoopId as first arg for maplist.
% Define ag_push_subgoal_for_loop: push one subgoal using the captured LoopId.
ag_push_subgoal_for_loop(LoopId, Goal) :- ag_push_subgoal(LoopId, Goal).

% Define maplist/2 usage for pushing subgoals -- use forall instead.
% Override: maplist over a list calling ag_push_subgoal(LoopId, Goal).
maplist(_, []).
maplist(Goal, [H|T]) :- call(Goal, H), maplist(Goal, T).

% ---------------------------------------------------------------------------
% ag_loop_done/1 -- true when loop has reached a terminal state
% ---------------------------------------------------------------------------

% Define ag_loop_done: succeed when the status is not 'running'.
ag_loop_done(LoopId) :-
    % Retrieve the loop metadata.
    ag_loop_meta(LoopId, _, _, Status),
    % The loop is done if the status is anything other than running.
    Status \= running.

% ---------------------------------------------------------------------------
% ag_loop_outcome/2 -- retrieve the final outcome of a completed loop
% ---------------------------------------------------------------------------

% Define ag_loop_outcome: return the status as the outcome.
ag_loop_outcome(LoopId, Outcome) :-
    % Retrieve the stored status.
    ag_loop_meta(LoopId, _, _, Outcome).

% ---------------------------------------------------------------------------
% ag_loop_set_status/2 -- update the loop status (internal)
% ---------------------------------------------------------------------------

% Define ag_loop_set_status: retract and reassert the metadata with new status.
ag_loop_set_status(LoopId, NewStatus) :-
    % Retract the current metadata.
    retract(ag_loop_meta(LoopId, Goal, Budget, _OldStatus)),
    % Reassert with the new status.
    assertz(ag_loop_meta(LoopId, Goal, Budget, NewStatus)).

% ---------------------------------------------------------------------------
% ag_loop_trace/2 -- retrieve all recorded steps
% ---------------------------------------------------------------------------

% Define ag_loop_trace: collect all step facts for the loop.
ag_loop_trace(LoopId, Steps) :-
    % Collect all step records, preserving step number for sorting.
    findall(step(N, T, A, O),
            ag_step_fact(LoopId, N, T, A, O),
            Steps).

% ---------------------------------------------------------------------------
% ag_step_record/4 -- record one step to the trace log
% ---------------------------------------------------------------------------

% Define ag_step_record: increment counter and store step fact.
ag_step_record(LoopId, Thought, Action, Observation) :-
    % Get and increment the step counter.
    retract(ag_step_counter(LoopId, N)),
    N1 is N + 1,
    assertz(ag_step_counter(LoopId, N1)),
    % Store the step record.
    assertz(ag_step_fact(LoopId, N1, Thought, Action, Observation)).

% ---------------------------------------------------------------------------
% ag_push_subgoal/2 -- push one subgoal onto the front of the goal stack
% ---------------------------------------------------------------------------

% Define ag_push_subgoal: retract and reassert the goal stack with new head.
ag_push_subgoal(LoopId, Subgoal) :-
    % Retract the current goal stack.
    ( retract(ag_goal_stack(LoopId, Stack))
    ->  true
    ;   Stack = []
    ),
    % Push the new subgoal to the front.
    assertz(ag_goal_stack(LoopId, [Subgoal | Stack])).

% ---------------------------------------------------------------------------
% ag_pop_subgoal/2 -- pop the top subgoal from the goal stack
% ---------------------------------------------------------------------------

% Define ag_pop_subgoal: retract the stack, return its head, reassert the tail.
ag_pop_subgoal(LoopId, Subgoal) :-
    % Retract the current goal stack.
    retract(ag_goal_stack(LoopId, [Subgoal | Rest])),
    % Reassert with the top goal removed.
    assertz(ag_goal_stack(LoopId, Rest)).

% ---------------------------------------------------------------------------
% ag_budget_remaining/2 -- query how many steps are left in the budget
% ---------------------------------------------------------------------------

% Define ag_budget_remaining: retrieve from the loop metadata.
ag_budget_remaining(LoopId, N) :-
    % Read the current budget from the metadata fact.
    ag_loop_meta(LoopId, _, N, _).

% ---------------------------------------------------------------------------
% ag_budget_decrement/1 -- consume one step of the budget
% ---------------------------------------------------------------------------

% Define ag_budget_decrement: update the budget in the metadata.
ag_budget_decrement(LoopId) :-
    % Retract the current metadata.
    retract(ag_loop_meta(LoopId, Goal, Budget, Status)),
    % Compute new budget (floor at zero).
    NewBudget is max(0, Budget - 1),
    % Reassert with decremented budget.
    assertz(ag_loop_meta(LoopId, Goal, NewBudget, Status)).

% ---------------------------------------------------------------------------
% ag_detect_loop/2 -- detect whether the loop is stuck repeating itself
%
% Examines the last four steps; returns true if the last two Thought-Action
% pairs are identical (a direct repeat), which is a common failure mode of
% agentic loops.
% ---------------------------------------------------------------------------

% Define ag_detect_loop: check for repeated thought-action pairs.
ag_detect_loop(LoopId, IsLooping) :-
    % Collect all thought-action pairs in step order.
    findall(T-A, ag_step_fact(LoopId, _, T, A, _), TAPairs),
    % Check if the last two thought-action pairs are identical.
    ( TAPairs = [_|_],
      last(TAPairs, LastTA),
      append(_, [LastTA, LastTA], TAPairs)
    ->  IsLooping = true
    ;   IsLooping = false
    ).

% ---------------------------------------------------------------------------
% ag_escalate/2 -- record an escalation to human oversight
% ---------------------------------------------------------------------------

% Define ag_escalate: store escalation and update loop status.
ag_escalate(LoopId, Reason) :-
    % Store the escalation record.
    assertz(ag_escalation(LoopId, Reason)),
    % Update the loop status to escalated.
    ag_loop_set_status(LoopId, escalated(Reason)).
