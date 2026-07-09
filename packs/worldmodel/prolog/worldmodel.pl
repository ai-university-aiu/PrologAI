/*  PrologAI — World Model  (WP-385, Layer 360)

    A structured, inspectable model of how the world works: states are
    sorted lists of ground fluent terms, and actions are STRIPS-style
    rules with preconditions, an add list, and a delete list. The pack
    simulates actions forward, rolls out futures, searches for plans,
    measures novelty, and learns action models from observed transitions.

    An action is act(Name, Pre, Add, Del). Name may be a compound term
    carrying parameters, for example move(X, Y); the preconditions bind
    the parameters against the current state. Every variable used in
    Add or Del must appear in Name or Pre.

    Transitions for model learning are tr(Name, Before, After) records
    of a named action observed to turn state Before into state After.

    Exported predicates:

    wm_state/2       +Fluents, -State
    wm_action/5      +Name, +Pre, +Add, +Del, -Action
    wm_holds/2       +State, +Fluent
    wm_goal_holds/2  +State, +Goal
    wm_applicable/2  +State, +Action
    wm_apply/3       +State, +Action, -State2
    wm_step/4        +State, +Actions, ?Name, -State2
    wm_successors/3  +State, +Actions, -Pairs
    wm_simulate/4    +State, +Actions, +Plan, -Trajectory
    wm_plan_bfs/5    +State, +Actions, +Goal, +MaxDepth, -Plan
    wm_reachable/4   +State, +Actions, +Depth, -States
    wm_rollout/4     +State, +Actions, +Depth, -Rollouts
    wm_diff/4        +State1, +State2, -Added, -Removed
    wm_learn/2       +Transitions, -Models
    wm_predict/4     +Models, +State, +Name, -State2
    wm_novelty/3     +KnownStates, +State, -Score
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(worldmodel, [
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
    % wm_rollout/4: all action sequences and final states to a depth.
    wm_rollout/4,
    % wm_diff/4: fluents added and removed between two states.
    wm_diff/4,
    % wm_learn/2: learn action models from observed transitions.
    wm_learn/2,
    % wm_predict/4: predict the next state with a learned model.
    wm_predict/4,
    % wm_novelty/3: fraction of a state never seen before.
    wm_novelty/3
]).

% Use the lists library for member/2, subtract/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% STATES AND ACTIONS
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

% ===========================================================================
% PLANNING SEARCH AND ROLLOUT
% ===========================================================================

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

% wm_rollout(+State, +Actions, +Depth, -Rollouts): sequences and endpoints.
wm_rollout(State0, Actions, Depth, Rollouts) :-
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

% ===========================================================================
% COMPARISON, LEARNING, AND NOVELTY
% ===========================================================================

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

% wm_predict(+Models, +State, +Name, -State2): apply a learned model.
wm_predict(Models, State, Name, State2) :-
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
