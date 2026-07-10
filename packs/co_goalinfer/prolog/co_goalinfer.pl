/*  PrologAI — Causalontology Goal Inference  (WP-398, Layer 373)

    ARC-AGI-3 never tells the agent what winning looks like. The environment
    only reports its state after each action — NOT_FINISHED, WIN or GAME_OVER
    — and it is the agent's job to infer the win condition for itself. This
    pack does that inference by watching the frame changes (deltas) that
    immediately precede a reported WIN and accumulating support for the
    features they share. The feature with the most support across observed
    wins becomes the hypothesised goal, which the co_arc3 harness can then
    register with co_arc3_goal_set/1 and plan toward.

    The delta format matches the co_arc3 harness: a list of
    changed(Row, Col, OldColour, NewColour) occurrents. From each winning
    delta this pack extracts the distinct NewColour values that appeared — a
    win most often means "a cell became this colour" (a goal reached, a target
    lit). Repeated wins reinforce the true feature and average out incidental
    ones. A GAME_OVER delta is recorded as a loss so a feature that appears in
    both wins and losses is discounted.

    The hypothesis is glass-box: cgi_feature_support/2 exposes the full tally,
    cgi_confidence/1 reports how strongly the leading hypothesis dominates, and
    cgi_hypothesise_goal/1 yields the abstract goal reach_colour(Colour) while
    cgi_goal_occurrent/1 yields the matching changed(_,_,_,Colour) occurrent.

    Predicates:
      cgi_reset/0            -- forget all recorded outcomes
      cgi_observe/2          -- +Delta, +State  (State: win|game_over|ongoing)
      cgi_win_count/1        -- -N  (how many wins observed)
      cgi_feature_support/2  -- ?Colour, ?Net  (wins minus losses for a colour)
      cgi_hypothesise_goal/1 -- -Goal          (reach_colour(Colour), best net)
      cgi_goal_occurrent/1   -- -Occurrent     (changed(_,_,_,Colour))
      cgi_confidence/1       -- -Confidence     (leading net over total win obs)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_goalinfer, [
    % cgi_reset/0: forget all recorded outcomes.
    cgi_reset/0,
    % cgi_observe/2: record a delta and the state it produced.
    cgi_observe/2,
    % cgi_win_count/1: how many wins have been observed.
    cgi_win_count/1,
    % cgi_feature_support/2: the net support (wins minus losses) per colour.
    cgi_feature_support/2,
    % cgi_hypothesise_goal/1: the best-supported abstract goal.
    cgi_hypothesise_goal/1,
    % cgi_goal_occurrent/1: the goal as a changed/4 occurrent for the planner.
    cgi_goal_occurrent/1,
    % cgi_confidence/1: how strongly the leading hypothesis dominates.
    cgi_confidence/1
]).

% Import list helpers used to extract distinct colours from a delta.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% Recorded outcomes
% ---------------------------------------------------------------------------

% cgi_feat_/2: (Colour, NetSupport) — wins add one, losses subtract one.
:- dynamic cgi_feat_/2.
% cgi_wins_/1: the running count of observed wins.
:- dynamic cgi_wins_/1.

% Define cgi_reset: forget all recorded outcomes and start the win count at zero.
cgi_reset :-
    % Drop every feature tally.
    retractall(cgi_feat_(_, _)),
    % Drop the win count.
    retractall(cgi_wins_(_)),
    % Start counting wins from zero.
    assertz(cgi_wins_(0)).

% Define cgi_observe: record a delta and the state it produced.
% An ongoing state teaches nothing about the win condition.
cgi_observe(_Delta, ongoing) :- !.
% A win reinforces every colour the winning delta introduced.
cgi_observe(Delta, win) :-
    % Extract the distinct new colours the delta introduced.
    cgi_new_colours(Delta, Colours),
    % Add one unit of support to each of them.
    forall(member(Colour, Colours), cgi_bump(Colour, 1)),
    % Increment the win count.
    retract(cgi_wins_(N)),
    % Compute the next win count.
    N1 is N + 1,
    % Store it back.
    assertz(cgi_wins_(N1)),
    % Commit to this clause for a win.
    !.
% A loss discounts every colour the losing delta introduced.
cgi_observe(Delta, game_over) :-
    % Extract the distinct new colours the delta introduced.
    cgi_new_colours(Delta, Colours),
    % Subtract one unit of support from each of them.
    forall(member(Colour, Colours), cgi_bump(Colour, -1)),
    % Commit to this clause for a loss.
    !.

% cgi_new_colours(+Delta, -Colours): the distinct new colours in a delta.
cgi_new_colours(Delta, Colours) :-
    % Collect every NewColour that a changed/4 occurrent introduced.
    findall(New,
        % Take each change occurrent in the delta.
        member(changed(_R, _C, _Old, New), Delta),
        Raw),
    % Reduce to the distinct set.
    sort(Raw, Colours).

% cgi_bump(+Colour, +Amount): add Amount to a colour's net support.
cgi_bump(Colour, Amount) :-
    % Fetch and remove the current tally, defaulting to zero.
    ( retract(cgi_feat_(Colour, Old)) -> true ; Old = 0 ),
    % Apply the increment or decrement.
    New is Old + Amount,
    % Store the updated tally.
    assertz(cgi_feat_(Colour, New)).

% ---------------------------------------------------------------------------
% Reading the hypothesis back
% ---------------------------------------------------------------------------

% Define cgi_win_count: how many wins have been observed.
cgi_win_count(N) :-
    % Read the win counter, defaulting to zero before any reset.
    ( cgi_wins_(N) -> true ; N = 0 ).

% Define cgi_feature_support: the net support for a colour.
cgi_feature_support(Colour, Net) :-
    % Read the colour's tally.
    cgi_feat_(Colour, Net).

% Define cgi_hypothesise_goal: the best-supported abstract goal.
cgi_hypothesise_goal(reach_colour(Colour)) :-
    % There must be at least one win to hypothesise from.
    cgi_win_count(W),
    % Refuse to guess with no evidence.
    W > 0,
    % Find the colour with the greatest net support.
    cgi_best_colour(Colour).

% cgi_best_colour(-Colour): the colour with the greatest net support.
cgi_best_colour(Colour) :-
    % Score every tallied colour by its net support.
    findall(Net-Col, cgi_feat_(Col, Net), Pairs),
    % There must be something to choose from.
    Pairs \== [],
    % Sort ascending by net, then by colour, keeping duplicates.
    keysort(Pairs, Sorted),
    % The greatest net is the last entry; take it.
    last(Sorted, BestNet-_),
    % The leading net must be positive to count as a goal.
    BestNet > 0,
    % Among colours sharing the best net, prefer the smallest colour.
    cgi_smallest_with_net(Pairs, BestNet, Colour).

% cgi_smallest_with_net(+Pairs, +Net, -Colour): smallest colour at a given net.
cgi_smallest_with_net(Pairs, Net, Colour) :-
    % Keep only the colours whose net equals the winning net.
    findall(Col, member(Net-Col, Pairs), Tied),
    % Order them.
    sort(Tied, [Colour | _]).

% Define cgi_goal_occurrent: the goal as a changed/4 occurrent for the planner.
cgi_goal_occurrent(changed(_, _, _, Colour)) :-
    % Reuse the abstract hypothesis and unwrap its colour.
    cgi_hypothesise_goal(reach_colour(Colour)).

% Define cgi_confidence: how strongly the leading hypothesis dominates.
cgi_confidence(Confidence) :-
    % Confidence needs wins to divide by.
    cgi_win_count(W),
    % Guard against division by zero.
    W > 0,
    % Read the leading net support.
    cgi_best_colour(Colour),
    % Its tally.
    cgi_feat_(Colour, Net),
    % Confidence is the leading net as a fraction of the wins observed.
    Confidence is min(1.0, Net / W).

% Import the list utility for taking the last element.
:- use_module(library(lists), [last/2]).
