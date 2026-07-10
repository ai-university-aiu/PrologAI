/*  PrologAI — Causalontology ARC-AGI-3 Harness  (WP-396, Layer 371)

    The game-agnostic harness of Causalontology_v5, Section 9: the loop that
    closes perceive -> learn -> plan -> act against an interactive
    environment, with the world model an explicit, reified causal graph.

    The environment is pluggable. An environment is the term

        arc3_env(ResetGoal,    % call(ResetGoal, -Frame0)
                 ActGoal,      % call(ActGoal, +Action, -Frame1)
                 ActionsGoal,  % call(ActionsGoal, -AvailableActions)
                 SolvedGoal)   % call(SolvedGoal, +Frame) — the win test

    so the same loop drives a local test double, a Mentova game body, or the
    live ARC-AGI-3 REST API. Frames are grids in the grid pack's format — a
    list of rows of small integers (ARC-AGI-3: up to 64x64, values 0-15) —
    and perception into occurrents (Section 9.5) abstracts a frame into
    cell_state/3 occurrents while the diff of successive frames yields the
    delta occurrents from which CROs are induced.

    Action selection (Section 9.4): if a plan to the inferred goal exists,
    follow it; else let curiosity choose the least-tried, non-avoided
    action. Learned hazards are enforced: an avoided action is never chosen.

    The live bridge (Section 9.3): co_arc3_http_env/4 builds an environment
    whose goals speak JSON over HTTP to an ARC-AGI-3 endpoint, guarded by
    catch and never load-bearing for any test — exact routes change between
    releases, so the loop structure is the stable part and the base URL and
    key are the caller's.

    Predicates:
      co_arc3_reset/0        -- clear harness state (tries, goals, episodes)
      co_arc3_perceive/2     -- +Frame, -Occurrents
      co_arc3_delta/3        -- +Frame0, +Frame1, -DeltaOccurrents
      co_arc3_goal_set/1     -- +GoalOccurrent (the inferred or given goal)
      co_arc3_goal/1         -- ?GoalOccurrent
      co_arc3_choose/3       -- +Actions, +LastFrame, -Action
      co_arc3_step/4         -- +Env, +Frame, -Action, -Frame1  (one turn)
      co_arc3_play/3         -- +Env, +Budget, -Outcome (won(Steps)|budget_exhausted)
      co_arc3_trace/1        -- -Steps (the episode trace, glass-box)
      co_arc3_tries/2        -- +Action, -Count
      co_arc3_http_env/4     -- +BaseUrl, +ApiKey, +Game, -Env (guarded bridge)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_arc3, [
    % co_arc3_reset/0: clear the harness state.
    co_arc3_reset/0,
    % co_arc3_perceive/2: abstract a frame into occurrents.
    co_arc3_perceive/2,
    % co_arc3_delta/3: the change occurrents between two frames.
    co_arc3_delta/3,
    % co_arc3_goal_set/1: register the goal occurrent to plan toward.
    co_arc3_goal_set/1,
    % co_arc3_goal/1: query the registered goal.
    co_arc3_goal/1,
    % co_arc3_choose/3: plan-first, curiosity-fallback action selection.
    co_arc3_choose/3,
    % co_arc3_step/4: one observe-choose-act-learn turn.
    co_arc3_step/4,
    % co_arc3_play/3: the full episode loop under a step budget.
    co_arc3_play/3,
    % co_arc3_trace/1: the glass-box episode trace.
    co_arc3_trace/1,
    % co_arc3_tries/2: how often each action has been tried.
    co_arc3_tries/2,
    % co_arc3_http_env/4: the guarded live bridge to the REST API.
    co_arc3_http_env/4
]).

% Import the verb layer whose relations the harness induces and reads.
:- use_module(library(co_core), [co_cro/8, co_predict/2]).
% Import the interventional learner that induces the relations.
:- use_module(library(co_learn), [co_learn_causal/2, co_learn_preventive/2, co_avoid/1]).
% Import the planner used when a route to the goal is known.
:- use_module(library(co_plan), [co_plan_chain/3]).
% Import the grid pack for frame perception and diffs.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_diff/3]).
% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, reverse/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% co_tries_/2: (Action, Count) — the curiosity counter.
:- dynamic co_tries_/2.
% co_goal_/1: the goal occurrent the planner aims at.
:- dynamic co_goal_/1.
% co_trace_/1: step(N, Action, Outcome) — the glass-box episode trace.
:- dynamic co_trace_/1.
% co_step_no_/1: the episode step counter.
:- dynamic co_step_no_/1.

% Define co_arc3_reset: clear the harness state for a fresh episode.
co_arc3_reset :-
    % Drop the curiosity counters.
    retractall(co_tries_(_, _)),
    % Drop the registered goal.
    retractall(co_goal_(_)),
    % Drop the trace.
    retractall(co_trace_(_)),
    % Reset the step counter.
    retractall(co_step_no_(_)),
    % Start counting from zero.
    assertz(co_step_no_(0)).

% ---------------------------------------------------------------------------
% PERCEPTION INTO OCCURRENTS (Section 9.5)
% ---------------------------------------------------------------------------

% Define co_arc3_perceive: a frame becomes cell_state occurrents.
co_arc3_perceive(Frame, Occurrents) :-
    % Measure the frame.
    gd_size(Frame, Rows, Cols),
    % Bounds for enumeration.
    MaxR is Rows - 1,
    % Column bound.
    MaxC is Cols - 1,
    % One occurrent per cell.
    findall(cell_state(R, C, V),
        % Enumerate every cell.
        ( between(0, MaxR, R),
          % Every column.
          between(0, MaxC, C),
          % Read the cell value.
          gd_cell(Frame, R, C, V) ),
        Occurrents).

% Define co_arc3_delta: the change occurrents between successive frames.
co_arc3_delta(Frame0, Frame1, Delta) :-
    % The grid pack computes the raw cell differences.
    gd_diff(Frame0, Frame1, Diffs),
    % Each difference becomes a change occurrent.
    findall(changed(R, C, Old, New),
        % Take each raw difference.
        member(r(R, C, Old, New), Diffs),
        Delta).

% ---------------------------------------------------------------------------
% THE GOAL
% ---------------------------------------------------------------------------

% Define co_arc3_goal_set: register the goal occurrent to plan toward.
co_arc3_goal_set(Goal) :-
    % One goal at a time.
    retractall(co_goal_(_)),
    % Record it.
    assertz(co_goal_(Goal)).

% Define co_arc3_goal: query the registered goal.
co_arc3_goal(Goal) :-
    % Read the store.
    co_goal_(Goal).

% ---------------------------------------------------------------------------
% ACTION SELECTION — plan first, curiosity second, hazards never (Section 9.4)
% ---------------------------------------------------------------------------

% Define co_arc3_choose: follow a plan when one exists; else be curious.
co_arc3_choose(Actions, _LastFrame, Action) :-
    % A registered goal with a plan to it takes precedence.
    co_goal_(Goal),
    % Search the causal graph backward from the goal.
    co_plan_chain(Goal, 8, [Action | _]),
    % The chosen step must be among the environment's actions.
    memberchk(Action, Actions),
    % The avoid-set is absolute.
    \+ co_avoid(Action),
    % Commit to the planned action.
    !.
% Otherwise curiosity picks the least-tried, non-avoided action.
co_arc3_choose(Actions, _LastFrame, Action) :-
    % Score every permissible action by how often it has been tried.
    findall(N-A,
        % Take each available action.
        ( member(A, Actions),
          % Never a learned hazard.
          \+ co_avoid(A),
          % Fetch its try count.
          co_arc3_tries(A, N) ),
        Scored),
    % There must be something permissible left to try.
    Scored \== [],
    % Least-tried first.
    msort(Scored, [_-Action | _]).

% Define co_arc3_tries: how often an action has been tried.
co_arc3_tries(Action, Count) :-
    % Read the counter, zero when untried.
    ( co_tries_(Action, C) -> Count = C ; Count = 0 ).

% co_count_try(+Action): bump the curiosity counter.
co_count_try(Action) :-
    % Fetch and bump.
    (   retract(co_tries_(Action, N))
    % Increment an existing counter.
    ->  N1 is N + 1
    % First try.
    ;   N1 = 1
    ),
    % Store it back.
    assertz(co_tries_(Action, N1)).

% ---------------------------------------------------------------------------
% THE LOOP (Section 9.4)
% ---------------------------------------------------------------------------

% Define co_arc3_step: one observe-choose-act-learn turn.
co_arc3_step(arc3_env(_, ActGoal, ActionsGoal, _), Frame, Action, Frame1) :-
    % Ask the environment which actions it affords.
    call(ActionsGoal, Actions),
    % Choose by plan or curiosity, never a hazard.
    co_arc3_choose(Actions, Frame, Action),
    % Count the try for curiosity.
    co_count_try(Action),
    % Doing: perform the action and receive the next frame.
    call(ActGoal, Action, Frame1),
    % The diff between the frames is the observed effect.
    co_arc3_delta(Frame, Frame1, Delta),
    % Learn from what followed.
    (   Delta == []
    % Nothing changed: record the turn without inducing a relation.
    ->  co_record(Action, none)
    % A penalty marker in the delta is a hazard.
    ;   memberchk(changed(_, _, _, 15), Delta)
    ->  co_learn_preventive(Action, penalty),
        % Record the hazard turn.
        co_record(Action, hazard)
    % Otherwise the delta is the effect the action produced.
    ;   co_learn_causal(Action, delta(Delta)),
        % Record the learning turn.
        co_record(Action, learned(delta(Delta)))
    ).

% co_record(+Action, +Outcome): append one step to the glass-box trace.
co_record(Action, Outcome) :-
    % Bump the step counter.
    retract(co_step_no_(N)),
    % The next step number.
    N1 is N + 1,
    % Store the counter back.
    assertz(co_step_no_(N1)),
    % Record the step.
    assertz(co_trace_(step(N1, Action, Outcome))).

% Define co_arc3_play: the full episode under a step budget.
co_arc3_play(Env, Budget, Outcome) :-
    % Start from a fresh harness state.
    co_arc3_reset,
    % Unpack the reset goal.
    Env = arc3_env(ResetGoal, _, _, _),
    % Reset the game and receive the first frame.
    call(ResetGoal, Frame0),
    % Run the episode.
    co_arc3_episode(Env, Frame0, 0, Budget, Outcome).

% co_arc3_episode(+Env, +Frame, +Steps, +Budget, -Outcome): the recursion.
co_arc3_episode(Env, Frame, Steps, Budget, Outcome) :-
    % Unpack the win test.
    Env = arc3_env(_, _, _, SolvedGoal),
    % Decide the state of the episode.
    (   call(SolvedGoal, Frame)
    % The level is won.
    ->  Outcome = won(Steps)
    % The action budget is exhausted.
    ;   Steps >= Budget
    ->  Outcome = budget_exhausted
    % Otherwise take one turn and continue.
    ;   co_arc3_step(Env, Frame, _Action, Frame1),
        % One more step has been spent.
        Steps1 is Steps + 1,
        % Continue the episode.
        co_arc3_episode(Env, Frame1, Steps1, Budget, Outcome)
    ).

% Define co_arc3_trace: the glass-box episode trace, in step order.
co_arc3_trace(Steps) :-
    % Collect the recorded steps.
    findall(step(N, A, O), co_trace_(step(N, A, O)), Unsorted),
    % Order them by step number.
    msort(Unsorted, Steps).

% ---------------------------------------------------------------------------
% THE LIVE BRIDGE (Section 9.3) — guarded, never load-bearing for tests
% ---------------------------------------------------------------------------

% Define co_arc3_http_env: an environment whose goals speak to the REST API.
% Exact routes change between releases (Appendix C), so the caller supplies
% the base URL; every call is guarded and fails honestly when offline.
co_arc3_http_env(BaseUrl, ApiKey, Game, arc3_env(
    % The reset goal opens and resets the game.
    co_arc3:co_http_reset(BaseUrl, ApiKey, Game),
    % The act goal posts one action and reads the next frame.
    co_arc3:co_http_act(BaseUrl, ApiKey, Game),
    % The actions goal reports the numbered ARC-AGI-3 action set.
    co_arc3:co_http_actions(BaseUrl, ApiKey, Game),
    % The solved goal reads the win flag of the last response.
    co_arc3:co_http_solved)).

% co_last_http_state_/1: the last JSON state the bridge received.
:- dynamic co_last_http_state_/1.

% co_http_reset(+BaseUrl, +ApiKey, +Game, -Frame0): reset over HTTP.
co_http_reset(BaseUrl, ApiKey, Game, Frame0) :-
    % Any transport failure makes the bridge fail honestly.
    catch(co_http_json(BaseUrl, ApiKey, Game, reset, _{}, Reply), _, fail),
    % Remember the state for the win test.
    retractall(co_last_http_state_(_)),
    % Store the reply.
    assertz(co_last_http_state_(Reply)),
    % The reply carries the first frame as a grid.
    Frame0 = Reply.frame.

% co_http_act(+BaseUrl, +ApiKey, +Game, +Action, -Frame1): one action.
co_http_act(BaseUrl, ApiKey, Game, Action, Frame1) :-
    % Encode the action term as its number or coordinates.
    co_http_action_payload(Action, Payload),
    % Any transport failure makes the bridge fail honestly.
    catch(co_http_json(BaseUrl, ApiKey, Game, action, Payload, Reply), _, fail),
    % Remember the state for the win test.
    retractall(co_last_http_state_(_)),
    % Store the reply.
    assertz(co_last_http_state_(Reply)),
    % The reply carries the next frame.
    Frame1 = Reply.frame.

% co_http_actions(+BaseUrl, +ApiKey, +Game, -Actions): the numbered set.
co_http_actions(_, _, _, Actions) :-
    % The stable ARC-AGI-3 shape: directional actions, the complex action,
    % and cell selection; per-game subsets are learned by trying.
    Actions = [action(1), action(2), action(3), action(4), action(6)].

% co_http_solved(+_Frame): the last reply carried the win flag.
co_http_solved(_) :-
    % Read the remembered state.
    co_last_http_state_(Reply),
    % The state reports the level as won.
    catch(Reply.state == "WIN", _, fail).

% co_http_action_payload(+Action, -Payload): action term to JSON payload.
co_http_action_payload(action(N), _{action: N}) :- !.
% A cell selection carries its coordinates.
co_http_action_payload(select(X, Y), _{action: 5, x: X, y: Y}) :- !.
% Any other term is passed by number if it is one.
co_http_action_payload(N, _{action: N}) :- integer(N).

% co_http_json(+BaseUrl, +ApiKey, +Game, +Route, +Payload, -Reply): POST JSON.
co_http_json(BaseUrl, ApiKey, Game, Route, Payload, Reply) :-
    % The HTTP client is loaded lazily so the pack works offline.
    use_module(library(http/http_open)),
    % The JSON codec too.
    use_module(library(http/json)),
    % Compose the route.
    format(atom(Url), '~w/~w/~w', [BaseUrl, Game, Route]),
    % Encode the payload.
    with_output_to(string(Body), json_write_dict(current_output, Payload)),
    % Post and read the JSON reply.
    setup_call_cleanup(
        % Open the request with the API key header.
        http_open(Url, Stream,
                  [post(string('application/json', Body)),
                   request_header('X-API-Key' = ApiKey)]),
        % Read the JSON reply as a dict.
        json_read_dict(Stream, Reply),
        % Always close the stream.
        close(Stream)).
