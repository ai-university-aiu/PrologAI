/*  PrologAI — Nexus: AGI Foundations Integration Layer  (WP-390, Layer 365)

    The seven AGI Foundations packs (causal, actinf, co_wm, planner,
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
                                reasoning. (nx_bind_workspace/1,
                                nx_hold_broadcast/2, nx_replay_broadcasts/2.)

      2. curiosity <- co_wm  wm_novelty feeds the curiosity pack's
                                learning-progress signal: a falling novelty
                                stream over an explored trajectory reads as
                                positive learning progress. (nx_observe_novelty/5,
                                nx_curiosity_explore/3.)

      3. agency + planner        The agency loop decomposes its goal with
                                ht_plan and recovers with ht_monitor/ht_replan,
                                escalating to human oversight when a goal cannot
                                be planned or recovered. (nx_plan_and_run/5,
                                nx_pursue_and_run/6.)

      4. evolve + refinery       ev_run_until evolves candidate reasoning
                                models scored by refinery critique, under a
                                bounded generation budget — evolutionary
                                self-improvement. (nx_evolve_with_critique/10,
                                nx_refinery_fitness/3, nx_critique_report/3.)

    All four wirings call the real predicates of both sides; nothing is
    stubbed. The pack adds no cognition of its own — it is pure plumbing,
    and every junction is a named, inspectable predicate.

    Exported predicates:

    nx_wirings/1                 -Wirings
    nx_hold_broadcast/2          +JSpace, +BroadcastContent
    nx_bind_workspace/1          +JSpace
    nx_replay_broadcasts/2       +JSpace, +Broadcasts
    nx_broadcast_reading/2       +JSpace, -Reading
    nx_novelty_signal/3          +KnownStates, +State, -Novelty
    nx_observe_novelty/5         +Region, +KnownStates, +State, +Timestamp, -Novelty
    nx_curiosity_explore/3       +Region, +Trajectory, -Progress
    nx_agency_plan_reason/6      +Domain, +State, +LoopId, +CurrentGoal, -Thought, -Action
    nx_plan_and_run/5            +Domain, +State, +Task, +Budget, -Outcome
    nx_pursue_reason/7           +Domain, +PlanState, +WorldState, +LoopId, +CurrentGoal, -Thought, -Action
    nx_pursue_and_run/6          +Domain, +PlanState, +WorldState, +Task, +Budget, -Outcome
    nx_refinery_fitness/3        +Criteria, +Genome, -Score
    nx_evolve_with_critique/10   +Criteria, +Params, +Size, +Length, +MaxGens, +Bar, +Seed, -Best, -Score, -Gens
    nx_critique_report/3         +Criteria, +Genome, -Critique
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(nexus, [
    % nx_wirings/1: describe the four integration wirings this pack provides.
    nx_wirings/1,
    % nx_hold_broadcast/2: hold a workspace broadcast's concepts in a J-Space.
    nx_hold_broadcast/2,
    % nx_bind_workspace/1: subscribe the J-Space hook to workspace broadcasts.
    nx_bind_workspace/1,
    % nx_replay_broadcasts/2: apply a sequence of broadcasts into a J-Space.
    nx_replay_broadcasts/2,
    % nx_broadcast_reading/2: the live J-Lens readout after broadcasts.
    nx_broadcast_reading/2,
    % nx_novelty_signal/3: co_wm novelty of a state against known states.
    nx_novelty_signal/3,
    % nx_observe_novelty/5: feed one novelty reading as a curiosity error.
    nx_observe_novelty/5,
    % nx_curiosity_explore/3: feed a trajectory's falling novelty as learning.
    nx_curiosity_explore/3,
    % nx_agency_plan_reason/6: the agency reasoner that decomposes via ht_plan.
    nx_agency_plan_reason/6,
    % nx_plan_and_run/5: run an agency loop that plans its goal.
    nx_plan_and_run/5,
    % nx_pursue_reason/7: the agency reasoner that monitors and recovers.
    nx_pursue_reason/7,
    % nx_pursue_and_run/6: run an agency loop that plans, monitors, and recovers.
    nx_pursue_and_run/6,
    % nx_refinery_fitness/3: score a genome by refinery critique.
    nx_refinery_fitness/3,
    % nx_evolve_with_critique/10: evolve genomes scored by refinery critique.
    nx_evolve_with_critique/10,
    % nx_critique_report/3: the remaining refinery issues of a genome.
    nx_critique_report/3
]).

% Foundation packs (Layers 358-363), each depending only on library(lists).
% Import the J-Space workspace predicates used by wiring one.
:- use_module(library(jspace), [js_hold/4, js_reading/2]).
% Import the world-model novelty predicate used by wiring two.
:- use_module(library(co_wm), [wm_novelty/3]).
% Import the hierarchical planner predicates used by wiring three.
:- use_module(library(planner), [ht_plan/5, ht_monitor/4]).
% Import the evolutionary run predicate used by wiring four.
:- use_module(library(evolve), [ev_run_until/10]).

% Cognitive-core packs (substrate layers below 60).
% Import the workspace broadcast-subscription predicate for wiring one.
:- use_module(library(workspace), [pai_broadcast_subscribe/1]).
% Import the curiosity learning-progress predicates for wiring two.
:- use_module(library(curiosity), [pai_observe_error/3, pai_learning_progress/2]).
% Import the agency loop predicates for wiring three.
:- use_module(library(agency), [ag_loop_create/3, ag_loop_run/3]).
% Import the refinery scoring and critique predicates for wiring four.
:- use_module(library(refinery), [rn_score/3, rn_critique/4]).

% Import the membership helper used throughout.
:- use_module(library(lists), [member/2]).
% Import the fold helper used to thread the exploration accumulator.
:- use_module(library(apply), [foldl/4]).

% The default depth bound for planner decomposition inside the agency loop.
nx_plan_depth(20).

% ===========================================================================
% INTROSPECTION
% ===========================================================================

% nx_wirings(-Wirings): a glass-box description of the four integration wirings.
nx_wirings([
    % Wiring one connects the J-Space workspace to the global workspace.
    wiring(jspace_from_workspace, "workspace broadcast -> J-Space held concepts"),
    % Wiring two connects curiosity to the world model's novelty signal.
    wiring(curiosity_from_co_wm, "wm_novelty -> curiosity learning progress"),
    % Wiring three connects the agency loop to the hierarchical planner.
    wiring(agency_with_planner, "ht_plan / ht_monitor -> agency loop decomposition and recovery"),
    % Wiring four connects evolutionary search to refinery critique.
    wiring(evolve_with_refinery, "rn_score -> ev_run_until fitness, bounded generations")
]).

% ===========================================================================
% WIRING ONE — jspace <- workspace broadcast
% ===========================================================================

% nx_hold_broadcast(+JSpace, +BroadcastContent): hold a winner's concepts.
% BroadcastContent is the term the workspace publishes each cycle:
%   broadcast_content(CoalitionId, Relation, ContentIds, Salience).
nx_hold_broadcast(JSpace, broadcast_content(_CId, _Relation, Ids, Salience)) :-
    % Clamp the salience into the [0.0, 1.0] strength band J-Space accepts.
    Strength is max(0.0, min(1.0, Salience)),
    % Hold each content concept in the workspace at the broadcast strength.
    forall(
        % Take each concept id the coalition carried.
        member(Concept, Ids),
        % Implant or refresh it, sourced as a workspace broadcast.
        js_hold(JSpace, Concept, Strength, workspace_broadcast)
    ).

% nx_bind_workspace(+JSpace): subscribe the J-Space hook to the broadcast bus.
nx_bind_workspace(JSpace) :-
    % Register nx_hold_broadcast(JSpace) as a broadcast subscriber; the
    % workspace calls it each cycle as call(Goal, BroadcastContent).
    pai_broadcast_subscribe(nexus:nx_hold_broadcast(JSpace)).

% nx_replay_broadcasts(+JSpace, +Broadcasts): apply a reasoning episode.
nx_replay_broadcasts(JSpace, Broadcasts) :-
    % Hold the concepts of each broadcast in turn, latest strength winning.
    forall(
        % Take each broadcast term in the episode.
        member(Broadcast, Broadcasts),
        % Route it through the same hook the live workspace would call.
        nx_hold_broadcast(JSpace, Broadcast)
    ).

% nx_broadcast_reading(+JSpace, -Reading): the live J-Lens readout.
nx_broadcast_reading(JSpace, Reading) :-
    % The readout is simply the ranked J-Space reading after broadcasts.
    js_reading(JSpace, Reading).

% ===========================================================================
% WIRING TWO — curiosity <- co_wm novelty
% ===========================================================================

% nx_novelty_signal(+KnownStates, +State, -Novelty): world-model novelty.
nx_novelty_signal(KnownStates, State, Novelty) :-
    % Delegate straight to the world model's novelty measure.
    wm_novelty(KnownStates, State, Novelty).

% nx_observe_novelty(+Region, +KnownStates, +State, +Timestamp, -Novelty):
% compute novelty and record it as a curiosity prediction error.
nx_observe_novelty(Region, KnownStates, State, Timestamp, Novelty) :-
    % Measure how novel the state is against everything seen so far.
    nx_novelty_signal(KnownStates, State, Novelty),
    % Feed that novelty into curiosity as the region's prediction error.
    pai_observe_error(Region, Novelty, Timestamp).

% nx_curiosity_explore(+Region, +Trajectory, -Progress): a whole trajectory.
% As exploration revisits familiar structure, novelty falls, which curiosity
% reads as positive learning progress for the region.
nx_curiosity_explore(Region, Trajectory, Progress) :-
    % Walk the trajectory, accumulating the states already seen.
    foldl(nx_explore_step(Region), Trajectory, 0-[], _),
    % Read back the learning progress the falling novelty produced.
    pai_learning_progress(Region, Progress).

% nx_explore_step(+Region, +State, +Index0-Known0, -Index1-Known1): one step.
nx_explore_step(Region, State, Index0-Known0, Index1-Known1) :-
    % Record the novelty of this state against the states seen before it.
    nx_observe_novelty(Region, Known0, State, Index0, _Novelty),
    % Advance the step index used as the curiosity timestamp.
    Index1 is Index0 + 1,
    % Add this state to the known set for the next step's novelty.
    Known1 = [State | Known0].

% ===========================================================================
% WIRING THREE — agency loop + hierarchical planner
% ===========================================================================

% nx_agency_plan_reason(+Domain, +State, +LoopId, +CurrentGoal, -Thought, -Action):
% the reason-goal an agency loop calls each step. It decomposes the current
% goal with ht_plan and marks the loop done, or escalates to oversight.
nx_agency_plan_reason(Domain, State, _LoopId, achieve(Task), Thought, Action) :-
    % Commit to the achieve/1 goal shape.
    !,
    % Fetch the decomposition depth bound.
    nx_plan_depth(Depth),
    % Try to decompose the task into a primitive plan.
    (   ht_plan(Domain, State, [Task], Depth, Plan)
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
nx_agency_plan_reason(_Domain, _State, _LoopId, CurrentGoal, unknown_goal(CurrentGoal), action_escalate(unknown_goal(CurrentGoal))).

% nx_plan_and_run(+Domain, +State, +Task, +Budget, -Outcome): run the loop.
nx_plan_and_run(Domain, State, Task, Budget, Outcome) :-
    % Create a bounded agency loop whose top goal is to achieve the task.
    ag_loop_create(achieve(Task), Budget, LoopId),
    % Run the loop with the planner-backed reasoner until it terminates.
    ag_loop_run(LoopId, nexus:nx_agency_plan_reason(Domain, State), Outcome).

% nx_pursue_reason(+Domain, +PlanState, +WorldState, +LoopId, +CurrentGoal, -Thought, -Action):
% a reason-goal that plans against PlanState, checks the plan against the
% possibly-changed WorldState with ht_monitor, and replans on failure.
nx_pursue_reason(Domain, PlanState, WorldState, _LoopId, achieve(Task), Thought, Action) :-
    % Commit to the achieve/1 goal shape.
    !,
    % Fetch the decomposition depth bound.
    nx_plan_depth(Depth),
    % First decompose the task against the state the plan was made for.
    (   ht_plan(Domain, PlanState, [Task], Depth, Plan)
    % A plan exists: check whether it still runs in the current world.
    ->  ht_monitor(Domain, WorldState, Plan, Status),
        (   Status == ok
        % The plan survives the changed world: done.
        ->  Thought = plan_valid(Task, Plan),
            % Mark the loop done with the surviving plan.
            Action = action_mark_done(achieved(Task, Plan))
        % The plan broke: try to replan against the current world.
        ;   (   ht_plan(Domain, WorldState, [Task], Depth, Plan2),
                % The recovery plan must actually run in the current world.
                ht_monitor(Domain, WorldState, Plan2, ok)
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
nx_pursue_reason(_Domain, _PlanState, _WorldState, _LoopId, CurrentGoal, unknown_goal(CurrentGoal), action_escalate(unknown_goal(CurrentGoal))).

% nx_pursue_and_run(+Domain, +PlanState, +WorldState, +Task, +Budget, -Outcome).
nx_pursue_and_run(Domain, PlanState, WorldState, Task, Budget, Outcome) :-
    % Create a bounded agency loop whose top goal is to achieve the task.
    ag_loop_create(achieve(Task), Budget, LoopId),
    % Run the loop with the plan-monitor-recover reasoner until it terminates.
    ag_loop_run(LoopId, nexus:nx_pursue_reason(Domain, PlanState, WorldState), Outcome).

% ===========================================================================
% WIRING FOUR — evolve + refinery critique
% ===========================================================================

% nx_refinery_fitness(+Criteria, +Genome, -Score): score by refinery critique.
% Shaped as call(Goal, Genome, Score) so ev_run_until can use it as fitness.
nx_refinery_fitness(Criteria, Genome, Score) :-
    % A genome's fitness is the fraction of refinery criteria it passes.
    rn_score(Genome, Criteria, Score).

% nx_evolve_with_critique(+Criteria, +Params, +Size, +Length, +MaxGens, +Bar,
%                         +Seed, -Best, -Score, -Gens): evolve under critique.
nx_evolve_with_critique(Criteria, Params, Size, Length, MaxGens, Bar, Seed, Best, Score, Gens) :-
    % Run the evolutionary loop with the refinery-critique fitness, stopping
    % when the quality bar is met or the generation budget is spent.
    ev_run_until(nexus:nx_refinery_fitness(Criteria), Params, Size, Length,
                 MaxGens, Bar, Seed, Best, Score, Gens).

% nx_critique_report(+Criteria, +Genome, -Critique): the remaining issues.
nx_critique_report(Criteria, Genome, Critique) :-
    % Report which criteria the evolved genome still fails, within budget.
    rn_critique(Genome, Criteria, 30, Critique).
