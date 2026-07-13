/*  PrologAI — Causalontology World Model  (WP-407, Layer 382)

    A two-mode, glass-box world model. It unifies the two world-model paradigms
    the platform previously kept in separate packs, so there is now ONE canonical
    world model that both LEARNS dynamics from experience and SIMULATES and PLANS
    over an explicit model. (This pack absorbed the former worldmodel pack, WP-385,
    under the Causalontology co_ family; nothing of its functionality was lost.)

    MODE 1 - the learned transition model (the original co_wm).
    A transition is keyed by a state CONTEXT and an ACTION and maps to an EFFECT.
    The model tallies how often each effect followed each (context, action), so
    prediction is the majority effect and confidence is its share; wm_predict falls
    back from the specific context to the action-general rule, and wm_law surfaces
    the actions whose effect is the same everywhere - the transferable core.
      wm_reset/0, wm_observe/4, wm_predict/4, wm_predict/5, wm_known/3,
      wm_verify/5, wm_repair/4, wm_rollout/4, wm_law/3, wm_stats/2,
      wm_snapshot/2, wm_restore/2

    MODE 2 - the structured simulate-and-plan model (absorbed from worldmodel).
    States are sorted lists of ground fluents; actions are STRIPS-style rules
    act(Name, Pre, Add, Del). It simulates actions forward, searches for plans,
    measures novelty, and learns STRIPS action models from observed transitions.
    Two names that collide with Mode 1 are renamed here, so both modes coexist:
      wm_model_predict/4   (was worldmodel's wm_predict/4: apply a learned model)
      wm_enumerate/4       (was worldmodel's wm_rollout/4: enumerate sequences)
    The rest keep their names:
      wm_state/2, wm_action/5, wm_holds/2, wm_goal_holds/2, wm_applicable/2,
      wm_apply/3, wm_step/4, wm_successors/3, wm_simulate/4, wm_plan_bfs/5,
      wm_reachable/4, wm_diff/4, wm_learn/2, wm_novelty/3

    CAUSALONTOLOGY BRIDGE - the model speaks the shared language.
      wm_as_cros/2   -- emit the learned (Mode 1) transitions as reified cro/8
                        terms, so the model can be written into the shared store.
*/

% Declare this module and its full two-mode interface.
:- module(co_wm, [
    % --- Mode 1: the learned transition model ---
    % wm_reset/0: forget the whole learned model.
    wm_reset/0,
    % wm_observe/4: record one observed transition.
    wm_observe/4,
    % wm_predict/4: the predicted effect of an action in a context.
    wm_predict/4,
    % wm_predict/5: the predicted effect and the model's confidence in it.
    wm_predict/5,
    % wm_known/3: whether the model has ever seen this (context, action).
    wm_known/3,
    % wm_verify/5: compare a prediction with what was observed.
    wm_verify/5,
    % wm_repair/4: fold a contradicting observation into the model.
    wm_repair/4,
    % wm_rollout/4: predict the effects of an action sequence (plan-in-model).
    wm_rollout/4,
    % wm_law/3: an action whose effect is context-free — a general law.
    wm_law/3,
    % wm_stats/2: a summary of the learned model.
    wm_stats/2,
    % wm_snapshot/2: the learned transitions, for persistence.
    wm_snapshot/2,
    % wm_restore/2: reload learned transitions from a snapshot.
    wm_restore/2,
    % --- Mode 2: the structured simulate-and-plan model ---
    % wm_state/2: normalize a fluent list into a canonical state.
    wm_state/2,
    % wm_action/5: build a STRIPS-style action term.
    wm_action/5,
    % wm_holds/2: test one fluent against a state.
    wm_holds/2,
    % wm_goal_holds/2: test a whole goal against a state.
    wm_goal_holds/2,
    % wm_applicable/2: preconditions hold, binding parameters.
    wm_applicable/2,
    % wm_apply/3: apply an action's effects to a state.
    wm_apply/3,
    % wm_step/4: take one named action from a repertoire.
    wm_step/4,
    % wm_successors/3: all reachable next states with their action names.
    wm_successors/3,
    % wm_simulate/4: run a plan and return the state trajectory.
    wm_simulate/4,
    % wm_plan_bfs/5: breadth-first search for a shortest plan.
    wm_plan_bfs/5,
    % wm_reachable/4: all states reachable within a depth.
    wm_reachable/4,
    % wm_enumerate/4: all action sequences and final states to a depth.
    wm_enumerate/4,
    % wm_diff/4: fluents added and removed between two states.
    wm_diff/4,
    % wm_learn/2: learn STRIPS action models from observed transitions.
    wm_learn/2,
    % wm_model_predict/4: predict the next state with a learned STRIPS model.
    wm_model_predict/4,
    % wm_novelty/3: fraction of a state never seen before.
    wm_novelty/3,
    % --- Causalontology bridge ---
    % wm_as_cros/2: emit the learned transitions as reified CROs.
    wm_as_cros/2
]).

% List helpers (member, max_member, subtract, append, intersection, reverse, last).
:- use_module(library(lists)).
% Apply helpers (foldl for the STRIPS learner).
:- use_module(library(apply)).
% Aggregate helpers (counting and summing over the store).
:- use_module(library(aggregate), [aggregate_all/3]).

% ===========================================================================
% MODE 1 — THE LEARNED TRANSITION MODEL
% ===========================================================================

% wm_obs_/5: (Model, Context, Action, Effect, Count) — how often Effect followed
% Action in Context.
:- dynamic wm_obs_/5.

% wm_reset: forget the whole model.
wm_reset :- retractall(wm_obs_(_, _, _, _, _)).

% wm_observe(+Model, +Context, +Action, +Effect): record one observed transition,
% incrementing its tally.
wm_observe(Model, Context, Action, Effect) :-
    % Take the current tally for this transition, or start from zero.
    ( retract(wm_obs_(Model, Context, Action, Effect, N)) -> true ; N = 0 ),
    % Add one to the tally.
    N1 is N + 1,
    % Store the raised tally back.
    assertz(wm_obs_(Model, Context, Action, Effect, N1)).

% wm_predict(+Model, +Context, +Action, -Effect): the predicted effect.
wm_predict(Model, Context, Action, Effect) :-
    % Defer to the confidence-bearing predictor and drop the confidence.
    wm_predict(Model, Context, Action, Effect, _Conf).

% wm_predict(+Model, +Context, +Action, -Effect, -Confidence): the effect the model
% expects and how strongly. It first uses transitions seen in exactly this context;
% if the context has never been observed with this action, it falls back to the
% action-general rule aggregated over every context (the simplicity bias — a law
% that holds regardless of context is preferred and is what transfers).
wm_predict(Model, Context, Action, Effect, Confidence) :-
    % Choose the prediction scope: this exact context, or the general rule.
    (   wm_obs_(Model, Context, Action, _, _)
    % Context-specific prediction.
    ->  wm_majority(Model, Context, Action, Effect, Confidence)
    % No data for this context: the action-general rule over all contexts.
    ;   wm_majority(Model, any_context, Action, Effect, Confidence)
    ).

% wm_majority(+Model, +Scope, +Action, -Effect, -Confidence): the most-frequent
% effect and its share. Scope is a specific context, or any_context to aggregate
% across every context the action was seen in.
wm_majority(Model, Scope, Action, Effect, Confidence) :-
    % Total effect-counts for the scope.
    findall(Count - Eff, wm_scope_count(Model, Scope, Action, Eff, Count), Pairs),
    % There must be at least one observed effect.
    Pairs \== [],
    % The total number of observations.
    aggregate_all(sum(N), member(N - _, Pairs), Total),
    % Guard against dividing by an empty total.
    Total > 0,
    % The most frequent effect.
    max_member(Best - Effect, Pairs),
    % Its share of the observations.
    Confidence is Best / Total.

% wm_scope_count(+Model, +Scope, +Action, -Effect, -Count): effect counts within a
% scope. A specific context reads its own tallies; any_context sums across contexts.
wm_scope_count(Model, any_context, Action, Effect, Count) :-
    % Commit to the any_context aggregation clause.
    !,
    % Distinct effects for the action anywhere.
    setof(E, Cx^N^wm_obs_(Model, Cx, Action, E, N), Effects),
    % Take each distinct effect in turn.
    member(Effect, Effects),
    % Sum its counts across every context.
    aggregate_all(sum(N), wm_obs_(Model, _, Action, Effect, N), Count).
% A specific context reads its own stored tallies directly.
wm_scope_count(Model, Context, Action, Effect, Count) :-
    % Read the tally for exactly this context.
    wm_obs_(Model, Context, Action, Effect, Count).

% wm_known(+Model, +Context, +Action): the model has seen this action in this exact
% context, or (fall-back) anywhere.
wm_known(Model, Context, Action) :-
    % True if the action was seen in this exact context.
    ( wm_obs_(Model, Context, Action, _, _) -> true
    % Otherwise fall back to having seen the action in any context.
    ; wm_obs_(Model, _, Action, _, _) ).

% wm_verify(+Model, +Context, +Action, +Observed, -Result): compare what the model
% predicted with what actually happened. Result is match, mismatch(Predicted,
% Observed), or novel when the model had no prediction to test.
wm_verify(Model, Context, Action, Observed, Result) :-
    % Try to obtain the model's prediction for this context and action.
    (   wm_predict(Model, Context, Action, Predicted, _)
    % When the prediction agrees with reality the result is a match.
    ->  ( Predicted == Observed -> Result = match
        % When it disagrees the result names both effects — the repair signal.
        ; Result = mismatch(Predicted, Observed) )
    % With no prediction to test, the observation is novel.
    ;   Result = novel
    ).

% wm_repair(+Model, +Context, +Action, +Observed): fold a (possibly contradicting)
% observation into the model. Prediction self-corrects as the majority shifts, so
% repair is simply recording the truth — the model is never argued with, only
% shown more evidence.
wm_repair(Model, Context, Action, Observed) :-
    % Repair is simply recording the observed truth as one more observation.
    wm_observe(Model, Context, Action, Observed).

% wm_rollout(+Model, +Context, +ActionSeq, -PredictedEffects): predict the effect of
% each action in a sequence, so a caller can score a plan inside the model without
% spending real actions. The context is held fixed across the rollout unless the
% caller threads a changing one; each step predicts under the current context.
% An empty action sequence predicts no effects.
wm_rollout(_, _, [], []).
% A non-empty sequence predicts the head action, then rolls the rest forward.
wm_rollout(Model, Context, [Action | As], [Effect | Es]) :-
    % Predict this action's effect, or mark it unknown when the model cannot.
    ( wm_predict(Model, Context, Action, Effect, _) -> true ; Effect = unknown ),
    % Roll the remaining actions forward under the same context.
    wm_rollout(Model, Context, As, Es).

% wm_law(+Model, ?Action, ?Effect): an action whose effect is context-free — the
% SAME majority effect was observed in every context it appeared in, with no
% contradicting effect. These are the general laws worth transferring to a new
% level or a new game, the minimum-description-length core of the model.
wm_law(Model, Action, Effect) :-
    % An action the model has seen.
    setof(A, Cx^E^N^wm_obs_(Model, Cx, A, E, N), Actions),
    % Take each seen action in turn.
    member(Action, Actions),
    % The distinct effects ever seen for it.
    setof(E, Cx^N^wm_obs_(Model, Cx, Action, E, N), Effects),
    % A law holds only when exactly one effect was ever observed.
    Effects = [Effect].

% wm_stats(+Model, -stats(Contexts, Transitions)): how many distinct contexts and
% (context, action, effect) transitions the model holds.
wm_stats(Model, stats(Contexts, Transitions)) :-
    % Count the distinct contexts, or zero when the model is empty.
    ( setof(Cx, A^E^N^wm_obs_(Model, Cx, A, E, N), Cs) -> length(Cs, Contexts) ; Contexts = 0 ),
    % Count every stored transition.
    aggregate_all(count, wm_obs_(Model, _, _, _, _), Transitions).

% wm_snapshot(+Model, -Obs): the model's learned transitions as a ground list of
% obs(Context, Action, Effect, Count) terms — a serialisable copy of everything the
% model has learned for this Model, so a caller can write it to disk and later
% restore it. Empty list when the model holds nothing.
wm_snapshot(Model, Obs) :-
    % Collect every stored transition of this model as an obs/4 term.
    findall(obs(Context, Action, Effect, Count),
        wm_obs_(Model, Context, Action, Effect, Count),
        Obs).

% wm_restore(+Model, +Obs): replace this Model's transitions with the snapshot. The
% Model's existing observations are dropped first so restore is idempotent (loading
% the same snapshot twice yields the same model, not doubled counts).
wm_restore(Model, Obs) :-
    % Drop this model's existing transitions so restore is idempotent.
    retractall(wm_obs_(Model, _, _, _, _)),
    % Assert each transition from the snapshot back into the store.
    forall(member(obs(Context, Action, Effect, Count), Obs),
        assertz(wm_obs_(Model, Context, Action, Effect, Count))).

% ===========================================================================
% MODE 2 — THE STRUCTURED SIMULATE-AND-PLAN MODEL (absorbed from worldmodel)
% ===========================================================================

% wm_state(+Fluents, -State): sort and de-duplicate into canonical form.
wm_state(Fluents, State) :-
    % Canonical states are sorted and duplicate-free.
    sort(Fluents, State).

% wm_action(+Name, +Pre, +Add, +Del, -Action): build an action term.
wm_action(Name, Pre, Add, Del, act(Name, Pre, Add, Del)) :-
    % The preconditions must be a list.
    is_list(Pre),
    % The add list must be a list.
    is_list(Add),
    % The delete list must be a list.
    is_list(Del).

% wm_holds(+State, +Fluent): the fluent is present in the state.
wm_holds(State, Fluent) :-
    % Ground membership test.
    memberchk(Fluent, State).

% wm_goal_holds(+State, +Goal): every goal fluent is present.
wm_goal_holds(State, Goal) :-
    % Check each goal fluent in turn.
    forall(member(G, Goal), memberchk(G, State)).

% wm_applicable(+State, +Action): preconditions hold, binding parameters.
wm_applicable(State, act(_, Pre, _, _)) :-
    % Match every precondition against the state.
    wm_match_pre(Pre, State).

% wm_match_pre(+Pre, +State): unify each precondition with a state fluent.
wm_match_pre([], _).
% Match the first precondition, keeping its bindings for the rest.
wm_match_pre([P | Ps], State) :-
    % Unification here binds the action parameters.
    member(P, State),
    % The remaining preconditions must also hold under those bindings.
    wm_match_pre(Ps, State).

% wm_apply(+State, +Action, -State2): apply the effects of a bound action.
wm_apply(State, act(_, _, Add, Del), State2) :-
    % Remove the deleted fluents.
    subtract(State, Del, Kept),
    % Insert the added fluents.
    append(Kept, Add, Raw),
    % Restore the canonical form.
    sort(Raw, State2).

% wm_step(+State, +Actions, ?Name, -State2): take one action by name.
wm_step(State, Actions, Name, State2) :-
    % Choose an action schema from the repertoire.
    member(Schema, Actions),
    % Work on a fresh copy so the schema stays reusable.
    copy_term(Schema, act(Name, Pre, Add, Del)),
    % The preconditions must hold, binding the parameters.
    wm_applicable(State, act(Name, Pre, Add, Del)),
    % Apply the bound effects.
    wm_apply(State, act(Name, Pre, Add, Del), State2).

% wm_successors(+State, +Actions, -Pairs): every Name-State2 successor.
wm_successors(State, Actions, Pairs) :-
    % Collect each grounded step.
    findall(Name-State2,
        % One step per action binding.
        wm_step(State, Actions, Name, State2),
        Raw),
    % Sort and de-duplicate the successor pairs.
    sort(Raw, Pairs).

% wm_simulate(+State, +Actions, +Plan, -Trajectory): run a plan.
wm_simulate(State, _, [], [State]).
% Execute the first plan step and recurse over the rest.
wm_simulate(State, Actions, [Name | Rest], [State | Trajectory]) :-
    % Take the named step; fails if the action is inapplicable.
    wm_step(State, Actions, Name, State2),
    % Commit to the first binding of the named action.
    !,
    % Continue the simulation from the new state.
    wm_simulate(State2, Actions, Rest, Trajectory).

% wm_plan_bfs(+State, +Actions, +Goal, +MaxDepth, -Plan): shortest plan.
wm_plan_bfs(State0, Actions, Goal, MaxDepth, Plan) :-
    % Canonicalize the start state.
    wm_state(State0, State),
    % Search breadth-first from the single-node frontier.
    wm_bfs([node(State, [], 0)], [State], Actions, Goal, MaxDepth, RevPlan),
    % The plan was accumulated newest-first.
    reverse(RevPlan, Plan).

% wm_bfs(+Queue, +Visited, +Actions, +Goal, +MaxDepth, -RevPlan): the search.
wm_bfs([node(State, RevPlan, _) | _], _, _, Goal, _, RevPlan) :-
    % Stop as soon as the dequeued state satisfies the goal.
    wm_goal_holds(State, Goal),
    % Commit to the first, therefore shortest, solution.
    !.
% Otherwise expand the dequeued state when depth remains.
wm_bfs([node(State, RevPlan, D) | Queue], Visited, Actions, Goal, MaxDepth, Plan) :-
    % Expansion is only allowed below the depth bound.
    (   D < MaxDepth
    % Expand: compute the successor states.
    ->  wm_successors(State, Actions, Pairs),
        % Keep only states never visited before.
        wm_fresh(Pairs, Visited, RevPlan, D, Fresh, Visited2),
        % Enqueue the fresh nodes at the back for breadth-first order.
        append(Queue, Fresh, Queue2),
        % Continue the search.
        wm_bfs(Queue2, Visited2, Actions, Goal, MaxDepth, Plan)
    % At the depth bound, drop this node and continue.
    ;   wm_bfs(Queue, Visited, Actions, Goal, MaxDepth, Plan)
    ).

% wm_fresh(+Pairs, +Visited, +RevPlan, +D, -Nodes, -Visited2): filter novel.
wm_fresh([], Visited, _, _, [], Visited).
% Keep the successor when its state is new.
wm_fresh([Name-S | Rest], Visited, RevPlan, D, Nodes, Visited2) :-
    % Already-seen states are dropped.
    (   memberchk(S, Visited)
    % Skip the duplicate and continue.
    ->  wm_fresh(Rest, Visited, RevPlan, D, Nodes, Visited2)
    % Otherwise wrap it as a search node.
    ;   D2 is D + 1,
        % The node records the extended plan.
        Nodes = [node(S, [Name | RevPlan], D2) | More],
        % Mark the state visited and continue.
        wm_fresh(Rest, [S | Visited], RevPlan, D, More, Visited2)
    ).

% wm_reachable(+State, +Actions, +Depth, -States): all states within Depth.
wm_reachable(State0, Actions, Depth, States) :-
    % Canonicalize the start state.
    wm_state(State0, State),
    % Expand layer by layer, accumulating every visited state.
    wm_reach([State], [State], Actions, Depth, All),
    % Sort the accumulated states.
    sort(All, States).

% wm_reach(+Frontier, +Visited, +Actions, +Depth, -All): layered expansion.
wm_reach(_, Visited, _, 0, Visited).
% Expand the whole frontier one layer when depth remains.
wm_reach(Frontier, Visited, Actions, Depth, All) :-
    % Depth is positive here.
    Depth > 0,
    % Collect every successor of the frontier not yet visited.
    findall(S2,
        % Expand each frontier state.
        ( member(S, Frontier),
          % One grounded step at a time.
          wm_step(S, Actions, _, S2),
          % Keep only unseen states.
          \+ memberchk(S2, Visited) ),
        Raw),
    % De-duplicate the new layer.
    sort(Raw, Layer),
    % Stop early when the layer is empty.
    (   Layer == []
    % Nothing new: the visited set is complete.
    ->  All = Visited
    % Otherwise absorb the layer and continue one level deeper.
    ;   append(Visited, Layer, Visited2),
        % Count the level down.
        Depth2 is Depth - 1,
        % Recurse with the new frontier.
        wm_reach(Layer, Visited2, Actions, Depth2, All)
    ).

% wm_enumerate(+State, +Actions, +Depth, -Rollouts): sequences and endpoints
% (formerly worldmodel's wm_rollout/4; renamed so it does not collide with Mode 1's
% wm_rollout/4, which predicts the effects of a given sequence).
wm_enumerate(State0, Actions, Depth, Rollouts) :-
    % Canonicalize the start state.
    wm_state(State0, State),
    % Collect every action sequence up to the depth with its final state.
    findall(Names-Final,
        % Enumerate one rollout at a time.
        wm_roll(State, Actions, Depth, Names, Final),
        Rollouts).

% wm_roll(+State, +Actions, +Depth, -Names, -Final): one rollout.
wm_roll(State, _, _, [], State).
% Extend the rollout by one step while depth remains.
wm_roll(State, Actions, Depth, [Name | Names], Final) :-
    % Depth must remain to take a step.
    Depth > 0,
    % Take one grounded step.
    wm_step(State, Actions, Name, State2),
    % Count the level down.
    Depth2 is Depth - 1,
    % Continue the rollout from the new state.
    wm_roll(State2, Actions, Depth2, Names, Final).

% wm_diff(+State1, +State2, -Added, -Removed): fluent-level difference.
wm_diff(State1, State2, Added, Removed) :-
    % Fluents present after but not before.
    subtract(State2, State1, Added),
    % Fluents present before but not after.
    subtract(State1, State2, Removed).

% wm_learn(+Transitions, -Models): induce one action model per name.
wm_learn(Transitions, Models) :-
    % Collect the distinct action names observed.
    findall(Name, member(tr(Name, _, _), Transitions), RawNames),
    % De-duplicate the names.
    sort(RawNames, Names),
    % Induce one model per name.
    findall(Model,
        % Take each name in turn.
        ( member(Name, Names),
          % Generalize over all its observed transitions.
          wm_learn_one(Name, Transitions, Model) ),
        Models).

% wm_learn_one(+Name, +Transitions, -Model): generalize one action.
wm_learn_one(Name, Transitions, act(Name, Pre, Add, Del)) :-
    % Gather every observation of this action.
    findall(B-A, member(tr(Name, B, A), Transitions), Obs),
    % Preconditions: fluents present before every observed application.
    findall(B, member(B-_, Obs), Befores),
    % Intersect the before-states.
    wm_intersect_all(Befores, Pre),
    % Add effects: fluents gained in every observed application.
    findall(Gained, ( member(B-A, Obs), subtract(A, B, Gained) ), Gains),
    % Intersect the gains.
    wm_intersect_all(Gains, Add),
    % Delete effects: fluents lost in every observed application.
    findall(Lost, ( member(B-A, Obs), subtract(B, A, Lost) ), Losses),
    % Intersect the losses.
    wm_intersect_all(Losses, Del).

% wm_intersect_all(+Lists, -Common): intersection of every list.
wm_intersect_all([], []).
% Fold the intersection over the remaining lists.
wm_intersect_all([First | Rest], Common) :-
    % Start from the first list and narrow it down.
    foldl(wm_intersect_step, Rest, First, Raw),
    % Sort the surviving fluents.
    sort(Raw, Common).

% wm_intersect_step(+List, +Acc, -Acc2): one narrowing step.
wm_intersect_step(List, Acc, Acc2) :-
    % Keep only the accumulator members also present in the list.
    intersection(Acc, List, Acc2).

% wm_model_predict(+Models, +State, +Name, -State2): apply a learned STRIPS model
% (formerly worldmodel's wm_predict/4; renamed so it does not collide with Mode 1's
% frequency predictor wm_predict/4).
wm_model_predict(Models, State, Name, State2) :-
    % Fetch the learned model for the named action.
    memberchk(act(Name, Pre, Add, Del), Models),
    % Its learned preconditions must hold.
    wm_applicable(State, act(Name, Pre, Add, Del)),
    % Apply the learned effects.
    wm_apply(State, act(Name, Pre, Add, Del), State2).

% wm_novelty(+KnownStates, +State, -Score): fraction of unseen fluents.
wm_novelty(KnownStates, State, Score) :-
    % Pool every fluent ever seen.
    append(KnownStates, RawKnown),
    % De-duplicate the pool.
    sort(RawKnown, Known),
    % Count the fluents of the state absent from the pool.
    findall(F, ( member(F, State), \+ memberchk(F, Known) ), Fresh),
    % Length of the novel part.
    length(Fresh, NFresh),
    % Length of the whole state.
    length(State, NAll),
    % An empty state carries no novelty.
    (   NAll =:= 0
    % Guard against division by zero.
    ->  Score = 0.0
    % Otherwise report the novel fraction.
    ;   Score is NFresh / NAll
    ).

% ===========================================================================
% CAUSALONTOLOGY BRIDGE — the learned model, spoken as reified CROs
% ===========================================================================

% wm_as_cros(+Model, -CROs): emit each learned (Mode 1) transition as a reified
% Causal Relation Object of the co_core shape, so the model can be written into the
% shared store and read by the rest of the family. The cause is the action, the
% effect is the observed effect, the strength is the effect's share of the
% observations in its context, and the provenance records that co_wm learned it.
wm_as_cros(Model, CROs) :-
    % Turn every stored transition into a CRO term.
    findall(
        cro(cro_wm(Context, Action, Effect),
            [do(Action)], [Effect],
            temporal(0, 0, instant), sufficient, Strength,
            [context(Context)],
            prov(co_wm, learned_by_observation, Strength)),
        % For each stored transition, compute its strength as a share.
        ( wm_obs_(Model, Context, Action, Effect, Count),
          % The total observations of this (context, action).
          aggregate_all(sum(N), wm_obs_(Model, Context, Action, _, N), Total),
          % Strength is this effect's share of them.
          Strength is Count / Total ),
        CROs).
