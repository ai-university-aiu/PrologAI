/*  PrologAI — Causalontology Planning  (WP-395, Layer 370)

    Composition and planning over the causal graph (Causalontology_v5,
    Sections 4.5 and 4.6): a procedure is a higher-level CRO whose cause is
    a sequence; planning chains backward from a goal to that sequence,
    provided each step is achievable and not on the avoid-set. Where no
    procedure has been composed yet, co_plan_chain/3 searches the graph of
    single-action relations backward from the goal, so the planner can
    assemble a sequence it was never given.

    Safety (Section 4.6): the planner will not use an avoided action, so a
    curious agent explores widely but never plans through a learned hazard.

    Predicates:
      co_compose_procedure/3  -- +Seq, +Goal, -Id  (a sequence-cause CRO)
      co_procedure/3          -- ?Id, ?Seq, ?Goal
      co_achievable/1         -- +Action  (known, non-preventive)
      co_plan/2               -- +Goal, -Plan  (via a procedure relation)
      co_plan_chain/3         -- +Goal, +MaxDepth, -Plan  (graph search)
      co_plan_safe/1          -- +Plan  (no avoided steps)
      co_execute/3            -- :ExecGoal, +Plan, -Result
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_plan, [
    % co_compose_procedure/3: reify a sequence as a higher-level relation.
    co_compose_procedure/3,
    % co_procedure/3: query the procedure relations.
    co_procedure/3,
    % co_achievable/1: an action the agent knows how to cause with.
    co_achievable/1,
    % co_plan/2: plan backward from a goal to a composed sequence.
    co_plan/2,
    % co_plan_chain/3: assemble a plan by backward graph search.
    co_plan_chain/3,
    % co_plan_safe/1: a plan free of avoided actions.
    co_plan_safe/1,
    % co_execute/3: run a plan through a caller-supplied executor.
    co_execute/3
]).

% Import the verb layer this pack plans over.
:- use_module(library(causal_core), [causal_core_cro/8, causal_core_new_cro/8]).
% Import the avoid-set the planner must respect.
:- use_module(library(causal_learning), [causal_learning_avoid/1]).
% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2]).

% The executor is a caller-module closure over a plan step.
:- meta_predicate co_execute(2, +, -).

% ---------------------------------------------------------------------------
% PROCEDURES — higher-level relations whose cause is a sequence
% ---------------------------------------------------------------------------

% Define co_compose_procedure: reify a step sequence as a procedure relation.
co_compose_procedure(Seq, Goal, Id) :-
    % A procedure needs at least one step.
    is_list(Seq),
    % Non-empty.
    Seq \== [],
    % Do not duplicate an existing procedure for this goal and sequence.
    (   causal_core_cro(Id0, [sequence(Seq)], [Goal], _, _, _, _, _)
    % Already composed: return the existing identifier.
    ->  Id = Id0
    % New: reify it at the canonical composed strength.
    ;   causal_core_new_cro([sequence(Seq)], [Goal], temporal(0, 1, short), sufficient,
                   0.60, [], prov(composition, composed_procedure, 0.60), Id)
    ).

% Define co_procedure: query the procedure relations.
co_procedure(Id, Seq, Goal) :-
    % A procedure is a relation whose single cause is a sequence.
    causal_core_cro(Id, [sequence(Seq)], [Goal], _, _, _, _, _).

% ---------------------------------------------------------------------------
% ACHIEVABILITY AND SAFETY
% ---------------------------------------------------------------------------

% Define co_achievable: the agent knows a non-preventive relation for it.
co_achievable(Action) :-
    % Some relation has this action as a cause.
    causal_core_cro(_, [Action], [_], _, Modality, _, _, _),
    % Preventive relations mark hazards, not abilities.
    Modality \== preventive,
    % One witness suffices.
    !.

% Define co_plan_safe: no step of the plan is on the avoid-set.
co_plan_safe(Plan) :-
    % Every step must be clear of the avoid-set.
    forall(member(Step, Plan), \+ causal_learning_avoid(Step)).

% ---------------------------------------------------------------------------
% PLANNING — first by procedure, then by backward graph search
% ---------------------------------------------------------------------------

% Define co_plan: the specification's planner — a composed procedure whose
% every step is achievable and not avoided (Section 4.5).
co_plan(Goal, Plan) :-
    % A procedure relation produces the goal.
    causal_core_cro(_, [sequence(Seq)], [Goal], _, _, _, _, _),
    % Every step must be achievable.
    forall(member(Step, Seq), co_achievable(Step)),
    % And none may be a learned hazard.
    co_plan_safe(Seq),
    % The sequence is the plan.
    Plan = Seq.

% Define co_plan_chain: assemble a plan the agent was never given, by
% chaining single-cause relations backward from the goal.
co_plan_chain(Goal, MaxDepth, Plan) :-
    % Search backward from the goal within the depth bound.
    co_chain_back(Goal, MaxDepth, [], RevPlan),
    % The plan was accumulated goal-first.
    reverse(RevPlan, Plan0),
    % A plan through a hazard is no plan.
    co_plan_safe(Plan0),
    % Return it.
    Plan = Plan0.

% co_chain_back(+Goal, +Depth, +Seen, -RevPlan): the backward search.
co_chain_back(Goal, Depth, Seen, [Action | Rest]) :-
    % Depth must remain.
    Depth > 0,
    % A non-preventive relation produces the goal.
    causal_core_cro(_, [Cause], Effects, _, Modality, _, _, _),
    % Preventive relations are never planned through.
    Modality \== preventive,
    % The goal is among its effects.
    memberchk(Goal, Effects),
    % Do not loop through the same subgoal twice.
    \+ memberchk(Cause, Seen),
    % The producing cause becomes a plan step.
    Action = Cause,
    % An action the environment affords directly ends the chain...
    (   co_action_like(Cause)
    % ...so nothing remains to plan.
    ->  Rest = []
    % Otherwise the cause is itself a state some earlier action must produce.
    ;   Depth1 is Depth - 1,
        % Recurse toward a producible cause.
        co_chain_back(Cause, Depth1, [Cause | Seen], Rest)
    ).

% co_action_like(+Term): a cause with no producer of its own is treated as
% a directly performable action.
co_action_like(Cause) :-
    % Nothing in the store produces it.
    \+ ( causal_core_cro(_, _, Effects, _, M, _, _, _), M \== preventive,
         memberchk(Cause, Effects) ).

% ---------------------------------------------------------------------------
% EXECUTION
% ---------------------------------------------------------------------------

% Define co_execute: run each plan step through the caller's executor,
% collecting the final result; a step that fails stops the plan honestly.
co_execute(_, [], done).
% Execute the first step, then the rest.
co_execute(ExecGoal, [Step | Rest], Result) :-
    % The executor performs one step and reports its outcome.
    (   call(ExecGoal, Step, StepResult)
    % Decide whether to continue.
    ->  (   Rest == []
        % The last step's outcome is the plan's result.
        ->  Result = StepResult
        % Otherwise continue with the remaining steps.
        ;   co_execute(ExecGoal, Rest, Result)
        )
    % A failing step stops the plan with the failure named.
    ;   Result = failed_at(Step)
    ).
