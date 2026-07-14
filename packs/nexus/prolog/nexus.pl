/*  PrologAI — Nexus: AGI Foundations Integration Layer  (WP-390, Layer 365)

    The seven AGI Foundations packs (causal, active_inference, world_model, planner,
    evolve, jspace, tom) were built as self-contained capabilities. This
    pack is the capstone that wires four of them into PrologAI's existing
    cognitive core, respecting the strictly acyclic layer order: nexus
    sits at Layer 365, above every pack it touches, so it may call up into
    the foundations and down into the substrate without any pack ever
    depending on something above it.

    Four wirings, one per bullet of the Building_AGI next-steps list:

      1. jspace  <- workspace   Every workspace broadcast holds its winning
                                coalition's concepts in a J-Space workspace,
                                so the readable J-Lens readout is live during
                                reasoning. (nexus_bind_workspace/1,
                                nexus_hold_broadcast/2, nexus_replay_broadcasts/2.)

      2. curiosity <- world_model  world_model_novelty feeds the curiosity pack's
                                learning-progress signal: a falling novelty
                                stream over an explored trajectory reads as
                                positive learning progress. (nexus_observe_novelty/5,
                                nexus_curiosity_explore/3.)

      3. agency + planner        The agency loop decomposes its goal with
                                planner_plan and recovers with planner_monitor/planner_replan,
                                escalating to human oversight when a goal cannot
                                be planned or recovered. (nexus_plan_and_run/5,
                                nexus_pursue_and_run/6.)

      4. evolve + refinery       evolve_run_until evolves candidate reasoning
                                models scored by refinery critique, under a
                                bounded generation budget — evolutionary
                                self-improvement. (nexus_evolve_with_critique/10,
                                nexus_refinery_fitness/3, nexus_critique_report/3.)

    All four wirings call the real predicates of both sides; nothing is
    stubbed. The pack adds no cognition of its own — it is pure plumbing,
    and every junction is a named, inspectable predicate.

    Exported predicates:

    nexus_wirings/1                 -Wirings
    nexus_hold_broadcast/2          +JSpace, +BroadcastContent
    nexus_bind_workspace/1          +JSpace
    nexus_replay_broadcasts/2       +JSpace, +Broadcasts
    nexus_broadcast_reading/2       +JSpace, -Reading
    nexus_novelty_signal/3          +KnownStates, +State, -Novelty
    nexus_observe_novelty/5         +Region, +KnownStates, +State, +Timestamp, -Novelty
    nexus_curiosity_explore/3       +Region, +Trajectory, -Progress
    nexus_agency_plan_reason/6      +Domain, +State, +LoopId, +CurrentGoal, -Thought, -Action
    nexus_plan_and_run/5            +Domain, +State, +Task, +Budget, -Outcome
    nexus_pursue_reason/7           +Domain, +PlanState, +WorldState, +LoopId, +CurrentGoal, -Thought, -Action
    nexus_pursue_and_run/6          +Domain, +PlanState, +WorldState, +Task, +Budget, -Outcome
    nexus_refinery_fitness/3        +Criteria, +Genome, -Score
    nexus_evolve_with_critique/10   +Criteria, +Params, +Size, +Length, +MaxGens, +Bar, +Seed, -Best, -Score, -Gens
    nexus_critique_report/3         +Criteria, +Genome, -Critique
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(nexus, [
    % nexus_wirings/1: describe the four integration wirings this pack provides.
    nexus_wirings/1,
    % nexus_hold_broadcast/2: hold a workspace broadcast's concepts in a J-Space.
    nexus_hold_broadcast/2,
    % nexus_bind_workspace/1: subscribe the J-Space hook to workspace broadcasts.
    nexus_bind_workspace/1,
    % nexus_replay_broadcasts/2: apply a sequence of broadcasts into a J-Space.
    nexus_replay_broadcasts/2,
    % nexus_broadcast_reading/2: the live J-Lens readout after broadcasts.
    nexus_broadcast_reading/2,
    % nexus_novelty_signal/3: world_model novelty of a state against known states.
    nexus_novelty_signal/3,
    % nexus_observe_novelty/5: feed one novelty reading as a curiosity error.
    nexus_observe_novelty/5,
    % nexus_curiosity_explore/3: feed a trajectory's falling novelty as learning.
    nexus_curiosity_explore/3,
    % nexus_agency_plan_reason/6: the agency reasoner that decomposes via planner_plan.
    nexus_agency_plan_reason/6,
    % nexus_plan_and_run/5: run an agency loop that plans its goal.
    nexus_plan_and_run/5,
    % nexus_pursue_reason/7: the agency reasoner that monitors and recovers.
    nexus_pursue_reason/7,
    % nexus_pursue_and_run/6: run an agency loop that plans, monitors, and recovers.
    nexus_pursue_and_run/6,
    % nexus_refinery_fitness/3: score a genome by refinery critique.
    nexus_refinery_fitness/3,
    % nexus_evolve_with_critique/10: evolve genomes scored by refinery critique.
    nexus_evolve_with_critique/10,
    % nexus_critique_report/3: the remaining refinery issues of a genome.
    nexus_critique_report/3
]).

% Foundation packs (Layers 358-363), each depending only on library(lists).
% Import the J-Space workspace predicates used by wiring one.
:- use_module(library(jspace), [js_hold/4, js_reading/2]).
% Import the world-model novelty predicate used by wiring two.
:- use_module(library(world_model), [world_model_novelty/3]).
% Import the hierarchical planner predicates used by wiring three.
:- use_module(library(planner), [planner_plan/5, planner_monitor/4]).
% Import the evolutionary run predicate used by wiring four.
:- use_module(library(evolve), [evolve_run_until/10]).

% Cognitive-core packs (substrate layers below 60).
% Import the workspace broadcast-subscription predicate for wiring one.
:- use_module(library(workspace), [pai_broadcast_subscribe/1]).
% Import the curiosity learning-progress predicates for wiring two.
:- use_module(library(curiosity), [curiosity_observe_error/3, curiosity_learning_progress/2]).
% Import the agency loop predicates for wiring three.
:- use_module(library(agency), [ag_loop_create/3, ag_loop_run/3]).
% Import the refinery scoring and critique predicates for wiring four.
:- use_module(library(refinery), [rn_score/3, rn_critique/4]).

% Import the membership helper used throughout.
:- use_module(library(lists), [member/2]).
% Import the fold helper used to thread the exploration accumulator.
:- use_module(library(apply), [foldl/4]).

% The default depth bound for planner decomposition inside the agency loop.
nexus_plan_depth(20).

% ===========================================================================
% INTROSPECTION
% ===========================================================================

% nexus_wirings(-Wirings): a glass-box description of the four integration wirings.
nexus_wirings([
    % Wiring one connects the J-Space workspace to the global workspace.
    wiring(jspace_from_workspace, "workspace broadcast -> J-Space held concepts"),
    % Wiring two connects curiosity to the world model's novelty signal.
    wiring(curiosity_from_world_model, "world_model_novelty -> curiosity learning progress"),
    % Wiring three connects the agency loop to the hierarchical planner.
    wiring(agency_with_planner, "planner_plan / planner_monitor -> agency loop decomposition and recovery"),
    % Wiring four connects evolutionary search to refinery critique.
    wiring(evolve_with_refinery, "rn_score -> evolve_run_until fitness, bounded generations")
]).

% ===========================================================================
% WIRING ONE — jspace <- workspace broadcast
% ===========================================================================

% nexus_hold_broadcast(+JSpace, +BroadcastContent): hold a winner's concepts.
% BroadcastContent is the term the workspace publishes each cycle:
%   broadcast_content(CoalitionId, Relation, ContentIds, Salience).
nexus_hold_broadcast(JSpace, broadcast_content(_CId, _Relation, Ids, Salience)) :-
    % Clamp the salience into the [0.0, 1.0] strength band J-Space accepts.
    Strength is max(0.0, min(1.0, Salience)),
    % Hold each content concept in the workspace at the broadcast strength.
    forall(
        % Take each concept id the coalition carried.
        member(Concept, Ids),
        % Implant or refresh it, sourced as a workspace broadcast.
        js_hold(JSpace, Concept, Strength, workspace_broadcast)
    ).

% nexus_bind_workspace(+JSpace): subscribe the J-Space hook to the broadcast bus.
nexus_bind_workspace(JSpace) :-
    % Register nexus_hold_broadcast(JSpace) as a broadcast subscriber; the
    % workspace calls it each cycle as call(Goal, BroadcastContent).
    pai_broadcast_subscribe(nexus:nexus_hold_broadcast(JSpace)).

% nexus_replay_broadcasts(+JSpace, +Broadcasts): apply a reasoning episode.
nexus_replay_broadcasts(JSpace, Broadcasts) :-
    % Hold the concepts of each broadcast in turn, latest strength winning.
    forall(
        % Take each broadcast term in the episode.
        member(Broadcast, Broadcasts),
        % Route it through the same hook the live workspace would call.
        nexus_hold_broadcast(JSpace, Broadcast)
    ).

% nexus_broadcast_reading(+JSpace, -Reading): the live J-Lens readout.
nexus_broadcast_reading(JSpace, Reading) :-
    % The readout is simply the ranked J-Space reading after broadcasts.
    js_reading(JSpace, Reading).

% ===========================================================================
% WIRING TWO — curiosity <- world_model novelty
% ===========================================================================

% nexus_novelty_signal(+KnownStates, +State, -Novelty): world-model novelty.
nexus_novelty_signal(KnownStates, State, Novelty) :-
    % Delegate straight to the world model's novelty measure.
    world_model_novelty(KnownStates, State, Novelty).

% nexus_observe_novelty(+Region, +KnownStates, +State, +Timestamp, -Novelty):
% compute novelty and record it as a curiosity prediction error.
nexus_observe_novelty(Region, KnownStates, State, Timestamp, Novelty) :-
    % Measure how novel the state is against everything seen so far.
    nexus_novelty_signal(KnownStates, State, Novelty),
    % Feed that novelty into curiosity as the region's prediction error.
    curiosity_observe_error(Region, Novelty, Timestamp).

% nexus_curiosity_explore(+Region, +Trajectory, -Progress): a whole trajectory.
% As exploration revisits familiar structure, novelty falls, which curiosity
% reads as positive learning progress for the region.
nexus_curiosity_explore(Region, Trajectory, Progress) :-
    % Walk the trajectory, accumulating the states already seen.
    foldl(nexus_explore_step(Region), Trajectory, 0-[], _),
    % Read back the learning progress the falling novelty produced.
    curiosity_learning_progress(Region, Progress).

% nexus_explore_step(+Region, +State, +Index0-Known0, -Index1-Known1): one step.
nexus_explore_step(Region, State, Index0-Known0, Index1-Known1) :-
    % Record the novelty of this state against the states seen before it.
    nexus_observe_novelty(Region, Known0, State, Index0, _Novelty),
    % Advance the step index used as the curiosity timestamp.
    Index1 is Index0 + 1,
    % Add this state to the known set for the next step's novelty.
    Known1 = [State | Known0].

% ===========================================================================
% WIRING THREE — agency loop + hierarchical planner
% ===========================================================================

% nexus_agency_plan_reason(+Domain, +State, +LoopId, +CurrentGoal, -Thought, -Action):
% the reason-goal an agency loop calls each step. It decomposes the current
% goal with planner_plan and marks the loop done, or escalates to oversight.
nexus_agency_plan_reason(Domain, State, _LoopId, achieve(Task), Thought, Action) :-
    % Commit to the achieve/1 goal shape.
    !,
    % Fetch the decomposition depth bound.
    nexus_plan_depth(Depth),
    % Try to decompose the task into a primitive plan.
    (   planner_plan(Domain, State, [Task], Depth, Plan)
    % Success: the loop is done, carrying the achieved plan.
    ->  Thought = decomposed(Task, Plan),
        % Mark the agency loop done with the plan as its result.
        Action = action_mark_done(achieved(Task, Plan))
    % Failure: no plan exists, so escalate to human oversight.
    ;   Thought = no_decomposition(Task),
        % The agency safety path: hand the impasse to a person.
        Action = action_escalate(no_plan(Task))
    ).
% Any other current goal is outside this reasoner's competence.
nexus_agency_plan_reason(_Domain, _State, _LoopId, CurrentGoal, unknown_goal(CurrentGoal), action_escalate(unknown_goal(CurrentGoal))).

% nexus_plan_and_run(+Domain, +State, +Task, +Budget, -Outcome): run the loop.
nexus_plan_and_run(Domain, State, Task, Budget, Outcome) :-
    % Create a bounded agency loop whose top goal is to achieve the task.
    ag_loop_create(achieve(Task), Budget, LoopId),
    % Run the loop with the planner-backed reasoner until it terminates.
    ag_loop_run(LoopId, nexus:nexus_agency_plan_reason(Domain, State), Outcome).

% nexus_pursue_reason(+Domain, +PlanState, +WorldState, +LoopId, +CurrentGoal, -Thought, -Action):
% a reason-goal that plans against PlanState, checks the plan against the
% possibly-changed WorldState with planner_monitor, and replans on failure.
nexus_pursue_reason(Domain, PlanState, WorldState, _LoopId, achieve(Task), Thought, Action) :-
    % Commit to the achieve/1 goal shape.
    !,
    % Fetch the decomposition depth bound.
    nexus_plan_depth(Depth),
    % First decompose the task against the state the plan was made for.
    (   planner_plan(Domain, PlanState, [Task], Depth, Plan)
    % A plan exists: check whether it still runs in the current world.
    ->  planner_monitor(Domain, WorldState, Plan, Status),
        (   Status == ok
        % The plan survives the changed world: done.
        ->  Thought = plan_valid(Task, Plan),
            % Mark the loop done with the surviving plan.
            Action = action_mark_done(achieved(Task, Plan))
        % The plan broke: try to replan against the current world.
        ;   (   planner_plan(Domain, WorldState, [Task], Depth, Plan2),
                % The recovery plan must actually run in the current world.
                planner_monitor(Domain, WorldState, Plan2, ok)
            % Recovery succeeded: done with the new plan.
            ->  Thought = recovered(Task, Status, Plan2),
                % Mark the loop done with the recovered plan.
                Action = action_mark_done(achieved(Task, Plan2))
            % Recovery failed: escalate the impasse to oversight.
            ;   Thought = unrecoverable(Task, Status),
                % Hand the unrecoverable goal to a person.
                Action = action_escalate(cannot_recover(Task))
            )
        )
    % No plan at all: escalate to oversight.
    ;   Thought = no_decomposition(Task),
        % The agency safety path.
        Action = action_escalate(no_plan(Task))
    ).
% Any other current goal is outside this reasoner's competence.
nexus_pursue_reason(_Domain, _PlanState, _WorldState, _LoopId, CurrentGoal, unknown_goal(CurrentGoal), action_escalate(unknown_goal(CurrentGoal))).

% nexus_pursue_and_run(+Domain, +PlanState, +WorldState, +Task, +Budget, -Outcome).
nexus_pursue_and_run(Domain, PlanState, WorldState, Task, Budget, Outcome) :-
    % Create a bounded agency loop whose top goal is to achieve the task.
    ag_loop_create(achieve(Task), Budget, LoopId),
    % Run the loop with the plan-monitor-recover reasoner until it terminates.
    ag_loop_run(LoopId, nexus:nexus_pursue_reason(Domain, PlanState, WorldState), Outcome).

% ===========================================================================
% WIRING FOUR — evolve + refinery critique
% ===========================================================================

% nexus_refinery_fitness(+Criteria, +Genome, -Score): score by refinery critique.
% Shaped as call(Goal, Genome, Score) so evolve_run_until can use it as fitness.
nexus_refinery_fitness(Criteria, Genome, Score) :-
    % A genome's fitness is the fraction of refinery criteria it passes.
    rn_score(Genome, Criteria, Score).

% nexus_evolve_with_critique(+Criteria, +Params, +Size, +Length, +MaxGens, +Bar,
%                         +Seed, -Best, -Score, -Gens): evolve under critique.
nexus_evolve_with_critique(Criteria, Params, Size, Length, MaxGens, Bar, Seed, Best, Score, Gens) :-
    % Run the evolutionary loop with the refinery-critique fitness, stopping
    % when the quality bar is met or the generation budget is spent.
    evolve_run_until(nexus:nexus_refinery_fitness(Criteria), Params, Size, Length,
                 MaxGens, Bar, Seed, Best, Score, Gens).

% nexus_critique_report(+Criteria, +Genome, -Critique): the remaining issues.
nexus_critique_report(Criteria, Genome, Critique) :-
    % Report which criteria the evolved genome still fails, within budget.
    rn_critique(Genome, Criteria, 30, Critique).
