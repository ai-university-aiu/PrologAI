/*  PrologAI — Causalontology Exploration Policy  (WP-397, Layer 372)

    ARC-AGI-3 gives an agent no instructions, no rules and no goal: it must
    explore an unknown interactive environment, discover which actions change
    the world, and avoid wasting turns re-visiting states it has already seen.
    The two strongest ARC-AGI-3 developer-preview agents both won on exactly
    this behaviour — one learned to predict which actions cause a frame to
    change, the other built a state graph and pruned actions that create loops.
    This pack packages that behaviour as a reusable, glass-box policy that
    plugs into the co_arc3 harness alongside its plan-first action selection.

    The policy ranks the environment's available actions by, in order:
      1. whether the learned causal graph predicts the action changes state
         (a predicted-change action is always preferred to a dead one);
      2. how few times the action has already been tried (curiosity).
    Actions on the learned avoid-set are never chosen. The ACTION6 cell-select
    action (a click at some (x,y) on a grid up to 64x64) is not enumerated
    blindly over 4096 cells: it is expanded only to the salient cells — the
    centroids of the perceived objects — so the click space stays small.

    Frames seen so far are remembered by a canonical signature (dimensions
    plus colour histogram) so that a returned-to state is recognised as a loop.

    Predicates:
      cox_reset/0            -- forget every seen-state signature
      cox_signature/2        -- +Frame, -Signature  (canonical, order-free)
      cox_mark_seen/1        -- +Frame  (remember its signature)
      cox_is_novel/1         -- +Frame  (its signature has not been seen)
      cox_would_loop/1       -- +Frame  (its signature HAS been seen)
      cox_seen_count/1       -- -N      (how many distinct states remembered)
      cox_predict_change/1   -- +Action (the causal graph predicts an effect)
      cox_salient_cells/2    -- +Frame, -Cells   (cell(R,C) click candidates)
      cox_click_targets/2    -- +Frame, -Targets (select(X,Y) actions, x=col)
      cox_expand_actions/3   -- +Actions, +Frame, -Expanded (clicks made concrete)
      cox_rank/4             -- +Actions, +Tried, +Frame, -Ranked (best first)
      cox_choose/4           -- +Actions, +Tried, +Frame, -Action (the best one)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_explore, [
    % cox_reset/0: forget every remembered state signature.
    cox_reset/0,
    % cox_signature/2: the canonical, order-free signature of a frame.
    cox_signature/2,
    % cox_mark_seen/1: remember a frame's signature.
    cox_mark_seen/1,
    % cox_is_novel/1: the frame has not been seen before.
    cox_is_novel/1,
    % cox_would_loop/1: the frame has been seen before (a loop).
    cox_would_loop/1,
    % cox_seen_count/1: how many distinct states are remembered.
    cox_seen_count/1,
    % cox_predict_change/1: the causal graph predicts the action has an effect.
    cox_predict_change/1,
    % cox_salient_cells/2: the click-worthy cells of a frame.
    cox_salient_cells/2,
    % cox_click_targets/2: salient cells as select(X,Y) actions.
    cox_click_targets/2,
    % cox_expand_actions/3: replace a bare click marker with concrete targets.
    cox_expand_actions/3,
    % cox_rank/4: order the available actions best-first.
    cox_rank/4,
    % cox_choose/4: the single best action to try next.
    cox_choose/4
]).

% Import the verb layer's forward predictor to tell live actions from dead ones.
:- use_module(library(co_core), [co_predict/2]).
% Import the learned avoid-set so hazards are never chosen.
:- use_module(library(co_learn), [co_avoid/1]).
% Import grid measurement and colour reading for the signature.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_colors/2, gd_color_count/3]).
% Import object detection so salient click cells are object centroids.
:- use_module(library(gridobj), [gob_all_objects/3]).
% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Seen-state memory
% ---------------------------------------------------------------------------

% cox_seen_/1: one fact per distinct state signature the agent has observed.
:- dynamic cox_seen_/1.

% Define cox_reset: forget every remembered state signature.
cox_reset :-
    % Drop all seen-state facts.
    retractall(cox_seen_(_)).

% Define cox_signature: a frame's canonical, order-free signature.
cox_signature(Frame, sig(Rows, Cols, Hist)) :-
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

% Define cox_mark_seen: remember a frame's signature once.
cox_mark_seen(Frame) :-
    % Compute the signature.
    cox_signature(Frame, Sig),
    % Record it only if it is not already remembered.
    ( cox_seen_(Sig) -> true ; assertz(cox_seen_(Sig)) ).

% Define cox_is_novel: succeed when the frame has not been seen.
cox_is_novel(Frame) :-
    % Compute the signature.
    cox_signature(Frame, Sig),
    % It must be absent from memory.
    \+ cox_seen_(Sig).

% Define cox_would_loop: succeed when the frame HAS been seen (a loop).
cox_would_loop(Frame) :-
    % Compute the signature.
    cox_signature(Frame, Sig),
    % It is present in memory.
    cox_seen_(Sig).

% Define cox_seen_count: how many distinct states are remembered.
cox_seen_count(N) :-
    % Count the seen-state facts.
    aggregate_all(count, cox_seen_(_), N).

% ---------------------------------------------------------------------------
% Predicting live actions from dead ones
% ---------------------------------------------------------------------------

% Define cox_predict_change: the causal graph predicts the action has an effect.
cox_predict_change(Action) :-
    % Ask the verb layer to forward-predict the action's effects.
    co_predict(Action, Effects),
    % A live action is one predicted to produce at least one effect.
    Effects \== [].

% ---------------------------------------------------------------------------
% Salient click targets for the ACTION6 cell-select action
% ---------------------------------------------------------------------------

% Define cox_salient_cells: the click-worthy cells of a frame.
cox_salient_cells(Frame, Cells) :-
    % Treat colour zero as the background; every other object is a target.
    gob_all_objects(Frame, 0, Objects),
    % The centroid of each object is one salient cell.
    findall(cell(R, C),
        % Take each detected object with its member cells.
        ( member(ob(_Colour, ObjCells, _BBox), Objects),
          % Reduce the object's cells to their integer centroid.
          cox_centroid(ObjCells, R, C) ),
        Cells).

% cox_centroid(+Cells, -R, -C): the rounded centroid of a cell list.
cox_centroid(Cells, R, C) :-
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

% Define cox_click_targets: salient cells as select(X,Y) actions (x=col, y=row).
cox_click_targets(Frame, Targets) :-
    % Find the salient cells.
    cox_salient_cells(Frame, Cells),
    % Map each cell to an ARC-AGI-3 click where x is the column and y the row.
    findall(select(X, Y),
        % Take each salient cell.
        ( member(cell(Y, X), Cells) ),
        Targets).

% ---------------------------------------------------------------------------
% Expanding the action set and ranking it
% ---------------------------------------------------------------------------

% Define cox_expand_actions: replace a bare click marker with concrete targets.
cox_expand_actions([], _Frame, []).
% A click marker becomes the frame's salient select targets.
cox_expand_actions([click | Rest], Frame, Expanded) :-
    % Compute the concrete click targets.
    cox_click_targets(Frame, Targets),
    % Expand the tail as well.
    cox_expand_actions(Rest, Frame, RestExpanded),
    % Splice the targets in where the marker was.
    append(Targets, RestExpanded, Expanded),
    % Commit to this clause for the marker.
    !.
% Any other action passes through unchanged.
cox_expand_actions([Action | Rest], Frame, [Action | RestExpanded]) :-
    % Expand the remaining actions.
    cox_expand_actions(Rest, Frame, RestExpanded).

% Define cox_rank: order the available actions best-first.
cox_rank(Actions, Tried, Frame, Ranked) :-
    % Make the click marker concrete before ranking.
    cox_expand_actions(Actions, Frame, Concrete),
    % Score each permissible action by (change-rank, tries).
    findall(key(ChangeRank, Count)-Action,
        % Take each concrete action.
        ( member(Action, Concrete),
          % Never rank a learned hazard.
          \+ co_avoid(Action),
          % A predicted-change action ranks 0 (first); a dead one ranks 1.
          ( cox_predict_change(Action) -> ChangeRank = 0 ; ChangeRank = 1 ),
          % Look up how many times the action has been tried.
          cox_tries_of(Action, Tried, Count) ),
        Scored),
    % Order by the composite key: live-and-least-tried first.
    keysort(Scored, Sorted),
    % Drop the keys, keeping just the ordered actions.
    findall(A, member(_-A, Sorted), Ranked).

% cox_tries_of(+Action, +Tried, -Count): the try count, zero when untried.
cox_tries_of(Action, Tried, Count) :-
    % Read the count from the caller's tally, defaulting to zero.
    ( memberchk(Action-N, Tried) -> Count = N ; Count = 0 ).

% Define cox_choose: the single best action to try next.
cox_choose(Actions, Tried, Frame, Action) :-
    % Rank the actions.
    cox_rank(Actions, Tried, Frame, [Action | _]).

% Import the aggregate library for the seen-state count.
:- use_module(library(aggregate), [aggregate_all/3]).
% Import list arithmetic and concatenation helpers.
:- use_module(library(lists), [sum_list/2, append/3]).
