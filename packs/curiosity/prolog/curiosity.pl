/*  PrologAI — Curiosity  (WP-398, Layer 372; converged with the intrinsic-motivation curiosity pack)

    One curiosity faculty, unioned from two implementations by the unification
    program (absorb-and-supersede; no sub-faculty is lost).

    HALF ONE — EXPLORATION POLICY (from co_explore). Over an interactive grid
    game: signature a frame, judge novelty, expand and rank the actions worth
    trying, target salient cells, predict which action changes the world, and
    avoid loops - the novelty-seeking, loop-avoiding policy that drives an agent
    through an unseen environment.

    HALF TWO — INTRINSIC MOTIVATION (from the curiosity pack). Learning progress
    as the drive: observe prediction error per region, track whether error is
    falling (progress) rather than merely high, habituate visited regions, and
    self-propose the next task at the frontier where progress is greatest.

    All predicates are pack-qualified curiosity_*.
*/

% Declare this module and its exported predicates (the union of both curiosity faculties).
:- module(curiosity, [
    % curiosity_choose/4: exported curiosity predicate.
    curiosity_choose/4,
    % curiosity_choose/5: exported curiosity predicate.
    curiosity_choose/5,
    % curiosity_choose_change/5: exported curiosity predicate.
    curiosity_choose_change/5,
    % curiosity_click_targets/2: exported curiosity predicate.
    curiosity_click_targets/2,
    % curiosity_expand_actions/3: exported curiosity predicate.
    curiosity_expand_actions/3,
    % curiosity_is_novel/1: exported curiosity predicate.
    curiosity_is_novel/1,
    % curiosity_mark_seen/1: exported curiosity predicate.
    curiosity_mark_seen/1,
    % curiosity_predict_change/1: exported curiosity predicate.
    curiosity_predict_change/1,
    % curiosity_predict_change/2: exported curiosity predicate.
    curiosity_predict_change/2,
    % curiosity_rank/4: exported curiosity predicate.
    curiosity_rank/4,
    % curiosity_rank/5: exported curiosity predicate.
    curiosity_rank/5,
    % curiosity_reset/0: exported curiosity predicate.
    curiosity_reset/0,
    % curiosity_salient_cells/2: exported curiosity predicate.
    curiosity_salient_cells/2,
    % curiosity_seen_count/1: exported curiosity predicate.
    curiosity_seen_count/1,
    % curiosity_signature/2: exported curiosity predicate.
    curiosity_signature/2,
    % curiosity_would_loop/1: exported curiosity predicate.
    curiosity_would_loop/1,
    % curiosity_frontier/1: exported curiosity predicate.
    curiosity_frontier/1,
    % curiosity_update/0: exported curiosity predicate.
    curiosity_update/0,
    % curiosity_urge/2: exported curiosity predicate.
    curiosity_urge/2,
    % curiosity_learning_progress/2: exported curiosity predicate.
    curiosity_learning_progress/2,
    % curiosity_observe_error/3: exported curiosity predicate.
    curiosity_observe_error/3,
    % curiosity_self_propose_task/3: exported curiosity predicate.
    curiosity_self_propose_task/3
]).

% ===========================================================================
% HALF ONE — Exploration policy (from co_explore)
% ===========================================================================

:- use_module(library(causal_core), [causal_core_predict/2]).
% Import the learned avoid-set so hazards are never chosen.
:- use_module(library(causal_learning), [causal_learning_avoid/1]).
% Import grid measurement and colour reading for the signature.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_colors/2, gd_color_count/3]).
% Import object detection so salient click cells are object centroids.
:- use_module(library(gridobj), [gob_all_objects/3]).
% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Seen-state memory
% ---------------------------------------------------------------------------

% curiosity_seen_/1: one fact per distinct state signature the agent has observed.
:- dynamic curiosity_seen_/1.

% Define curiosity_reset: forget every remembered state signature.
curiosity_reset :-
    % Drop all seen-state facts.
    retractall(curiosity_seen_(_)).

% Define curiosity_signature: a frame's canonical, order-free signature.
curiosity_signature(Frame, sig(Rows, Cols, Hist)) :-
    % Measure the frame's dimensions.
    gd_size(Frame, Rows, Cols),
    % Find the colours actually present.
    gd_colors(Frame, Colors),
    % Pair each colour with how many cells carry it.
    findall(Colour-N,
        % Enumerate the present colours.
        ( member(Colour, Colors),
          % Count the cells of that colour.
          gd_color_count(Frame, Colour, N) ),
        Hist0),
    % Sort the histogram so the signature is order-free.
    msort(Hist0, Hist).

% Define curiosity_mark_seen: remember a frame's signature once.
curiosity_mark_seen(Frame) :-
    % Compute the signature.
    curiosity_signature(Frame, Sig),
    % Record it only if it is not already remembered.
    ( curiosity_seen_(Sig) -> true ; assertz(curiosity_seen_(Sig)) ).

% Define curiosity_is_novel: succeed when the frame has not been seen.
curiosity_is_novel(Frame) :-
    % Compute the signature.
    curiosity_signature(Frame, Sig),
    % It must be absent from memory.
    \+ curiosity_seen_(Sig).

% Define curiosity_would_loop: succeed when the frame HAS been seen (a loop).
curiosity_would_loop(Frame) :-
    % Compute the signature.
    curiosity_signature(Frame, Sig),
    % It is present in memory.
    curiosity_seen_(Sig).

% Define curiosity_seen_count: how many distinct states are remembered.
curiosity_seen_count(N) :-
    % Count the seen-state facts.
    aggregate_all(count, curiosity_seen_(_), N).

% ---------------------------------------------------------------------------
% Predicting live actions from dead ones
% ---------------------------------------------------------------------------

% Define curiosity_predict_change: the causal graph predicts the action has an effect.
curiosity_predict_change(Action) :-
    % Ask the verb layer to forward-predict the action's effects.
    causal_core_predict(Action, Effects),
    % A live action is one predicted to produce at least one effect.
    Effects \== [].

% ---------------------------------------------------------------------------
% Salient click targets for a cell-select / pointing action
% ---------------------------------------------------------------------------

% Define curiosity_salient_cells: the click-worthy cells of a frame, largest object
% first. The strongest exploration agents try the biggest, most button-like
% candidates before small ones, so the click budget is spent where an
% interactive control is most likely to be; ordering by object size is a simple,
% robust proxy for that salience.
curiosity_salient_cells(Frame, Cells) :-
    % Treat colour zero as the background; every other object is a target.
    gob_all_objects(Frame, 0, Objects),
    % Pair each object's centroid with its size, negated so a keysort puts the
    % largest object first.
    findall(NegSize - cell(R, C),
        % Take each detected object with its member cells.
        ( member(ob(_Colour, ObjCells, _BBox), Objects),
          % Its size in cells.
          length(ObjCells, Size),
          % Negated for descending order.
          NegSize is -Size,
          % Reduce the object's cells to their integer centroid.
          curiosity_centroid(ObjCells, R, C) ),
        Keyed),
    % Order by descending object size (largest, most salient candidate first).
    keysort(Keyed, Sorted),
    % Keep just the ordered centroid cells.
    findall(cell(R, C), member(_ - cell(R, C), Sorted), Cells).

% curiosity_centroid(+Cells, -R, -C): the rounded centroid of a cell list.
curiosity_centroid(Cells, R, C) :-
    % Sum the row coordinates.
    findall(RR, member(r(RR, _), Cells), Rows),
    % Sum the column coordinates.
    findall(CC, member(r(_, CC), Cells), Cols),
    % Count how many cells there are.
    length(Cells, N),
    % Guard against an empty object.
    N > 0,
    % Add up the rows.
    sum_list(Rows, SumR),
    % Add up the columns.
    sum_list(Cols, SumC),
    % Round the mean row to the nearest integer.
    R is round(SumR / N),
    % Round the mean column to the nearest integer.
    C is round(SumC / N).

% Define curiosity_click_targets: salient cells as select(X,Y) actions (x=col, y=row).
curiosity_click_targets(Frame, Targets) :-
    % Find the salient cells.
    curiosity_salient_cells(Frame, Cells),
    % Map each cell to a select(X,Y) click where x is the column and y the row.
    findall(select(X, Y),
        % Take each salient cell.
        ( member(cell(Y, X), Cells) ),
        Targets).

% ---------------------------------------------------------------------------
% Expanding the action set and ranking it
% ---------------------------------------------------------------------------

% Define curiosity_expand_actions: replace a bare click marker with concrete targets.
curiosity_expand_actions([], _Frame, []).
% A click marker becomes the frame's salient select targets.
curiosity_expand_actions([click | Rest], Frame, Expanded) :-
    % Compute the concrete click targets.
    curiosity_click_targets(Frame, Targets),
    % Expand the tail as well.
    curiosity_expand_actions(Rest, Frame, RestExpanded),
    % Splice the targets in where the marker was.
    append(Targets, RestExpanded, Expanded),
    % Commit to this clause for the marker.
    !.
% Any other action passes through unchanged.
curiosity_expand_actions([Action | Rest], Frame, [Action | RestExpanded]) :-
    % Expand the remaining actions.
    curiosity_expand_actions(Rest, Frame, RestExpanded).

% Define curiosity_rank: order the available actions best-first.
curiosity_rank(Actions, Tried, Frame, Ranked) :-
    % Make the click marker concrete before ranking.
    curiosity_expand_actions(Actions, Frame, Concrete),
    % Score each permissible action by (change-rank, tries).
    findall(key(ChangeRank, Count)-Action,
        % Take each concrete action.
        ( member(Action, Concrete),
          % Never rank a learned hazard.
          \+ causal_learning_avoid(Action),
          % A predicted-change action ranks 0 (first); a dead one ranks 1.
          ( curiosity_predict_change(Action) -> ChangeRank = 0 ; ChangeRank = 1 ),
          % Look up how many times the action has been tried.
          curiosity_tries_of(Action, Tried, Count) ),
        Scored),
    % Order by the composite key: live-and-least-tried first.
    keysort(Scored, Sorted),
    % Drop the keys, keeping just the ordered actions.
    findall(A, member(_-A, Sorted), Ranked).

% curiosity_tries_of(+Action, +Tried, -Count): the try count, zero when untried.
curiosity_tries_of(Action, Tried, Count) :-
    % Read the count from the caller's tally, defaulting to zero.
    ( memberchk(Action-N, Tried) -> Count = N ; Count = 0 ).

% Define curiosity_choose: the single best action to try next.
curiosity_choose(Actions, Tried, Frame, Action) :-
    % Rank the actions.
    curiosity_rank(Actions, Tried, Frame, [Action | _]).

% ---------------------------------------------------------------------------
% Game-scoped policy — the same ranking, but for a caller that keys its learned
% causal relations and hazards by an environment id, as g(Game, Action). Unknown
% environments differ from one another, so an agent that explores many of them
% keeps each environment's learnings under its own id; these predicates let the
% exploration policy read exactly that environment's causal graph and avoid-set
% while never confusing it with another's.
% ---------------------------------------------------------------------------

% Define curiosity_predict_change/2: the game's causal graph predicts the action has
% an effect (its cause is keyed to this game, as g(Game, Action)).
curiosity_predict_change(Game, Action) :-
    % Ask the verb layer to forward-predict the game-keyed action's effects.
    causal_core_predict(g(Game, Action), Effects),
    % A live action is one predicted to produce at least one effect.
    Effects \== [].

% curiosity_change_rank(+Game, +Action, -Rank): 0 when predicted to change, else 1.
curiosity_change_rank(Game, Action, Rank) :-
    % A predicted-change action ranks 0 (first); a dead one ranks 1.
    ( curiosity_predict_change(Game, Action) -> Rank = 0 ; Rank = 1 ).

% Define curiosity_rank/5: order a game's available actions best-first, reading that
% game's causal graph and avoid-set. Clicks are made concrete first.
curiosity_rank(Game, Actions, Tried, Frame, Ranked) :-
    % Make the click marker concrete before ranking.
    curiosity_expand_actions(Actions, Frame, Concrete),
    % Score each permissible action by (change-rank, tries).
    findall(key(ChangeRank, Count)-Action,
        % Take each concrete action.
        ( member(Action, Concrete),
          % Never rank a hazard this game has learned to avoid.
          \+ causal_learning_avoid(g(Game, Action)),
          % Rank predicted-change actions ahead of dead ones.
          curiosity_change_rank(Game, Action, ChangeRank),
          % Look up how many times the action has been tried.
          curiosity_tries_of(Action, Tried, Count) ),
        Scored),
    % Order by the composite key: live-and-least-tried first.
    keysort(Scored, Sorted),
    % Drop the keys, keeping just the ordered actions.
    findall(A, member(_-A, Sorted), Ranked).

% Define curiosity_choose/5: the single best action to try next for this game.
curiosity_choose(Game, Actions, Tried, Frame, Action) :-
    % Rank this game's actions and take the head.
    curiosity_rank(Game, Actions, Tried, Frame, [Action | _]).

% Define curiosity_choose_change/5: the best action ONLY when at least one action is
% predicted to change the world; fails when none is, so a caller can then fall
% back to a graph-frontier search. This is the causal-first half of the policy.
curiosity_choose_change(Game, Actions, Tried, Frame, Action) :-
    % Make the click marker concrete before ranking.
    curiosity_expand_actions(Actions, Frame, Concrete),
    % Keep only predicted-change, non-avoided actions, scored by tries.
    findall(Count-A,
        % Take each concrete action.
        ( member(A, Concrete),
          % Never a learned hazard.
          \+ causal_learning_avoid(g(Game, A)),
          % Only actions this game's causal graph predicts will change the world.
          curiosity_predict_change(Game, A),
          % How many times it has been tried.
          curiosity_tries_of(A, Tried, Count) ),
        Scored),
    % There must be at least one predicted-change action.
    Scored \== [],
    % Take the least-tried predicted-change action.
    keysort(Scored, [_-Action | _]).

% Import the aggregate library for the seen-state count.
:- use_module(library(aggregate), [aggregate_all/3]).
% Import list arithmetic and concatenation helpers.
:- use_module(library(lists), [sum_list/2, append/3]).

% ===========================================================================
% HALF TWO — Intrinsic motivation: learning progress (from the curiosity pack)
% ===========================================================================

:- use_module(library(node_facts), [anchor_node/4]).
% Import [member/2, last/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, last/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),  [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'region_error_entry/3.   % Region, Error, Timestamp' as dynamic — its facts may be added or removed at runtime.
:- dynamic region_error_entry/3.   % Region, Error, Timestamp
% Declare 'region_habituation/2.   % Region, HabituationLevel (0-1)' as dynamic — its facts may be added or removed at runtime.
:- dynamic region_habituation/2.   % Region, HabituationLevel (0-1)
% Declare 'region_urge_cache/2.    % Region, Urge' as dynamic — its facts may be added or removed at runtime.
:- dynamic region_urge_cache/2.    % Region, Urge

% State a fact for 'error window size' with the arguments listed below.
error_window_size(10).             % sliding window — last N errors per region
% State a fact for 'habituation decay rate' with the arguments listed below.
habituation_decay_rate(0.05).      % per-tick decay of habituation
% State a fact for 'habituation visit increment' with the arguments listed below.
habituation_visit_increment(0.15). % added to habituation per visit

% ---------------------------------------------------------------------------
% curiosity_observe_error/3 — record a prediction error for a region
% ---------------------------------------------------------------------------

% Define a clause for 'pai observe error': succeed when the following conditions hold.
curiosity_observe_error(Region, Error, Timestamp) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(region_error_entry(Region, Error, Timestamp)),
    % State the fact: trim error window(Region).
    trim_error_window(Region).

% Define a clause for 'trim error window': succeed when the following conditions hold.
trim_error_window(Region) :-
    % State a fact for 'error window size' with the arguments listed below.
    error_window_size(W),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(E-T, region_error_entry(Region, E, T), All),
    % Unify 'N' with the number of elements in list 'All'.
    length(All, N),
    % Check that '( N' is greater than 'W'.
    ( N > W
    % If the condition above succeeded, perform the following action.
    ->  Excess is N - W,
        % Continue the multi-line expression started above.
        take_k(Excess, All, ToRemove),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(E-T, ToRemove),
            % Continue the multi-line expression started above.
            retract(region_error_entry(Region, E, T))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'take k': succeed when the following conditions hold.
take_k(0, _, []) :- !.
% Define a clause for 'take k': succeed when the following conditions hold.
take_k(_, [], []) :- !.
% Check that 'take_k(K, [H|T], [H|R]) :- K' is greater than '0, K1 is K - 1, take_k(K1, T, R)'.
take_k(K, [H|T], [H|R]) :- K > 0, K1 is K - 1, take_k(K1, T, R).

% ---------------------------------------------------------------------------
% curiosity_learning_progress/2
%
%   Compute learning progress for a Region.
%   Progress = mean(first_half_errors) - mean(second_half_errors).
%   Positive value means errors are shrinking (= learning happening).
%   With < 2 data points, progress is 0.0 (no evidence yet).
% ---------------------------------------------------------------------------

% Define a clause for 'pai learning progress': succeed when the following conditions hold.
curiosity_learning_progress(Region, Progress) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(E, region_error_entry(Region, E, _), Errors),
    % Unify 'N' with the number of elements in list 'Errors'.
    length(Errors, N),
    % Check that '( N' is less than '2'.
    ( N < 2
    % If the condition above succeeded, perform the following action.
    ->  Progress = 0.0
    % Otherwise (else branch), perform the following action.
    ;   Half is N // 2,
        % Continue the multi-line expression started above.
        length(First, Half),
        % Continue the multi-line expression started above.
        append(First, Rest, Errors),
        % Continue the multi-line expression started above.
        ( Rest = []
        % If the condition above succeeded, perform the following action.
        ->  Second = First
        % Otherwise (else branch), perform the following action.
        ;   Second = Rest
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        curiosity_sum_list(First, SumF),
        % Continue the multi-line expression started above.
        length(First, NF),
        % Continue the multi-line expression started above.
        MeanF is SumF / NF,
        % Continue the multi-line expression started above.
        curiosity_sum_list(Second, SumS),
        % Continue the multi-line expression started above.
        length(Second, NS),
        % Continue the multi-line expression started above.
        MeanS is SumS / NS,
        % Continue the multi-line expression started above.
        Progress is MeanF - MeanS  % positive when error falling
    % Close the expression opened above.
    ).

% State the fact: sum list([], 0.0).
curiosity_sum_list([], 0.0).
% Define a clause for 'sum list': succeed when the following conditions hold.
curiosity_sum_list([H|T], Sum) :-
    % State a fact for 'sum list' with the arguments listed below.
    curiosity_sum_list(T, Rest),
    % Evaluate the arithmetic expression 'H + Rest' and bind the result to 'Sum'.
    Sum is H + Rest.

% ---------------------------------------------------------------------------
% curiosity_urge/2
%
%   Curiosity urge = max(0, Progress) * (1 - Habituation).
%   Habituation grows with visits, decays over time.
% ---------------------------------------------------------------------------

% Define a clause for 'pai curiosity urge': succeed when the following conditions hold.
curiosity_urge(Region, Urge) :-
    % State a fact for 'pai learning progress' with the arguments listed below.
    curiosity_learning_progress(Region, Progress),
    % Execute: ( region_habituation(Region, Hab).
    ( region_habituation(Region, Hab)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   Hab = 0.0
    % Close the expression opened above.
    ),
    % Evaluate the arithmetic expression 'max(0.0, Progress) * (1.0 - Hab)' and bind the result to 'RawUrge'.
    RawUrge is max(0.0, Progress) * (1.0 - Hab),
    % Evaluate the arithmetic expression 'min(1.0, RawUrge)' and bind the result to 'Urge'.
    Urge is min(1.0, RawUrge).

% ---------------------------------------------------------------------------
% curiosity_frontier/1 — Region with highest curiosity urge
% ---------------------------------------------------------------------------

% Define a clause for 'pai curiosity frontier': succeed when the following conditions hold.
curiosity_frontier(Region) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(R, region_error_entry(R, _, _), AllR0),
    % Sort list 'AllR0' into 'AllR', removing duplicates.
    sort(AllR0, AllR),
    % Check that 'AllR' is not unifiable with '[]'.
    AllR \= [],
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(U-R, (
        % Continue the multi-line expression started above.
        member(R, AllR),
        % Continue the multi-line expression started above.
        curiosity_urge(R, U)
    % Continue the multi-line expression started above.
    ), Pairs),
    % Sort list 'Pairs' into 'Sorted', keeping duplicates.
    msort(Pairs, Sorted),
    % Unify the second argument with the last element of list 'Sorted'.
    last(Sorted, _BestU-Region).

% ---------------------------------------------------------------------------
% curiosity_update/0
%
%   One tick: compute urges for all known regions, decay habituation,
%   cache urge values.
% ---------------------------------------------------------------------------

% Execute: curiosity_update :-.
curiosity_update :-
    % Collect all known regions
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(R, region_error_entry(R, _, _), AllR0),
    % Sort list 'AllR0' into 'AllR', removing duplicates.
    sort(AllR0, AllR),
    % Decay habituation for all regions
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(R, AllR),
        % Continue the multi-line expression started above.
        decay_habituation(R)
    % Close the expression opened above.
    ),
    % Recompute and cache urges
    % Remove all matching facts from the runtime knowledge base.
    retractall(region_urge_cache(_, _)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(R, AllR),
        % Continue the multi-line expression started above.
        ( curiosity_urge(R, U),
          % Continue the multi-line expression started above.
          assertz(region_urge_cache(R, U))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% Define a clause for 'decay habituation': succeed when the following conditions hold.
decay_habituation(Region) :-
    % State a fact for 'habituation decay rate' with the arguments listed below.
    habituation_decay_rate(Rate),
    % Execute: ( retract(region_habituation(Region, H)).
    ( retract(region_habituation(Region, H))
    % If the condition above succeeded, perform the following action.
    ->  NewH is max(0.0, H - Rate),
        % Continue the multi-line expression started above.
        assertz(region_habituation(Region, NewH))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% curiosity_self_propose_task/3
%
%   In an idle interval, propose a practice task at the curiosity frontier.
%   Inscribes the proposal as a node_fact:
%     anchor_node(curiosity_task, [Region, Goal, Progress], Meta, NodeId)
%   Returns NodeId and the LearningProgress score driving the proposal.
%
%   Guard: only proposes when Region is known and has at least 2 errors.
% ---------------------------------------------------------------------------

% Define a clause for 'pai self propose task': succeed when the following conditions hold.
curiosity_self_propose_task(Region, GoalNodeId, LP) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(E, region_error_entry(Region, E, _), Errors),
    % Unify 'N' with the number of elements in list 'Errors'.
    length(Errors, N),
    % Check that 'N' is greater than or equal to '2'.
    N >= 2,
    % State a fact for 'pai learning progress' with the arguments listed below.
    curiosity_learning_progress(Region, LP),
    % Increment habituation so we don't keep choosing the same region
    % State a fact for 'habituation visit increment' with the arguments listed below.
    habituation_visit_increment(Inc),
    % Execute: ( retract(region_habituation(Region, H)).
    ( retract(region_habituation(Region, H))
    % If the condition above succeeded, perform the following action.
    ->  NewH is min(1.0, H + Inc)
    % Otherwise (else branch), perform the following action.
    ;   NewH = Inc
    % Close the expression opened above.
    ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(region_habituation(Region, NewH)),
    % Goal: reduce prediction error in this region
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat([explore_, Region], Goal),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        anchor_node(curiosity_task,
                    % Continue the multi-line expression started above.
                    [Region, Goal, learning_progress(LP)],
                    % Continue the multi-line expression started above.
                    [proposed=true, rationale=learning_progress],
                    % Supply 'GoalNodeId' as the next argument to the expression above.
                    GoalNodeId),
        % Supply '_' as the next argument to the expression above.
        _,
        % Continue the multi-line expression started above.
        GoalNodeId = curiosity_task(Region)
    % Close the expression opened above.
    ).
