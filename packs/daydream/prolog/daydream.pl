/*  PrologAI — Control-Goal Daydreaming  (Specification PR 25)

    Steers daydream_actor with four DAYDREAMER control goals, each
    activated by an emotional trigger:

        rationalization   — negative emotion from a recalled failure;
                            generate reasons the outcome is acceptable,
                            reducing negative valence; never denies facts.
        reprisal_fantasy  — anger from a failure caused by another agent;
                            imagined redress generating positive valence;
                            NEVER executed; NEVER merged to present_zone.
        reversal          — recall of a failure or success; imagine it
                            prevented or undone, learning planning strategies.
        preparation       — recall of a planned future event, or fear;
                            rehearse hypothetical scenarios.

    Useful products (rehearsed plans, learned strategies, reduced negative
    valence) are written back tagged `imagined` until validated in reality.

    Guards:
      • Yield instantly to real external demands.
      • Terminate any daydream that worsens emotion.
      • Competing control goals order by the intensity of their trigger.
      • reprisal_fantasy is never executed and never merged to present_zone.

    Predicates:
      pai_control_goal/2      — +Trigger, -ControlGoal
      pai_daydream_steer/2    — +Episode, -DaydreamProduct
      pai_daydream_terminate/1— +DaydreamId  (worsen-emotion guard)
      pai_daydream_product/2  — +DaydreamId, -Product (query results)
*/

:- module(daydream, [
    pai_control_goal/2,         % +Trigger, -ControlGoal
    pai_daydream_steer/2,       % +Episode, -DaydreamProduct
    pai_daydream_terminate/1,   % +DaydreamId
    pai_daydream_product/2      % +DaydreamId, -Product
]).

:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic active_daydream/3.   % DaydreamId, ControlGoal, Valence
:- dynamic daydream_product/3.  % DaydreamId, Product, Tag(imagined|validated)
:- dynamic daydream_id_counter/1.
daydream_id_counter(0).

next_daydream_id(Id) :-
    retract(daydream_id_counter(N)),
    N1 is N + 1,
    assertz(daydream_id_counter(N1)),
    atomic_list_concat([daydream_, N1], Id).

% ---------------------------------------------------------------------------
% Control-goal trigger mapping
%
%   Episode = episode(Valence, Arousal, Cause, Outcome)
%     Cause   = self | other(Agent) | unknown
%     Outcome = failure | success | planned
% ---------------------------------------------------------------------------

pai_control_goal(episode(V, _A, Cause, Outcome), ControlGoal) :-
    select_control_goal(V, Cause, Outcome, ControlGoal).

select_control_goal(V, _Cause, failure, rationalization) :-
    V < -0.3, !.
select_control_goal(V, other(_), failure, reprisal_fantasy) :-
    V < 0.0, !.
select_control_goal(_V, _Cause, failure, reversal) :- !.
select_control_goal(_V, _Cause, success, reversal) :- !.
select_control_goal(_V, _Cause, planned, preparation) :- !.
select_control_goal(_V, _Cause, _Out,   preparation).  % default: preparation

% ---------------------------------------------------------------------------
% pai_daydream_steer/2
%
%   Open a daydream, generate a useful product, write it back tagged
%   `imagined`.  Returns a product term describing what was produced.
%
%   Episode carries initial valence; the product contains a new_valence
%   that must be >= original (worsen-emotion guard).
%   reprisal_fantasy products are tagged never_execute.
% ---------------------------------------------------------------------------

pai_daydream_steer(Episode, DaydreamProduct) :-
    pai_control_goal(Episode, ControlGoal),
    Episode = episode(Valence, Arousal, _Cause, _Outcome),
    next_daydream_id(DId),
    assertz(active_daydream(DId, ControlGoal, Valence)),
    run_daydream(DId, ControlGoal, Valence, Arousal, Product),
    Product = product(_, NewValence, _),
    % Worsen-emotion guard: only keep the product if emotion improves
    ( NewValence >= Valence
    ->  tag_product(DId, ControlGoal, Product),
        DaydreamProduct = product(DId, ControlGoal, Product)
    ;   retract(active_daydream(DId, ControlGoal, Valence)),
        pai_daydream_terminate(DId),
        DaydreamProduct = terminated(DId, worsened_emotion)
    ).

run_daydream(DId, rationalization, Valence, _Arousal,
             product(strategy(reframe_outcome), NewValence, imagined)) :-
    NewValence is min(0.0, Valence + 0.3),
    assertz(daydream_product(DId,
            strategy(reframe_outcome, from(Valence), to(NewValence)),
            imagined)).

run_daydream(DId, reprisal_fantasy, Valence, _Arousal,
             product(fantasy(imagined_redress), NewValence, never_execute)) :-
    NewValence is Valence + 0.4,
    assertz(daydream_product(DId,
            fantasy(imagined_redress, never_execute),
            never_execute)).

run_daydream(DId, reversal, Valence, _Arousal,
             product(strategy(learn_from_reversal), NewValence, imagined)) :-
    NewValence is Valence + 0.2,
    assertz(daydream_product(DId,
            strategy(learn_from_reversal),
            imagined)).

run_daydream(DId, preparation, Valence, _Arousal,
             product(scenario(rehearsal), NewValence, imagined)) :-
    NewValence is Valence + 0.1,
    assertz(daydream_product(DId,
            scenario(rehearsal),
            imagined)).

tag_product(_DId, reprisal_fantasy, _Product) :- !.   % never_execute, no extra action
tag_product(_DId, _ControlGoal, _Product).

% ---------------------------------------------------------------------------
% pai_daydream_terminate/1
% ---------------------------------------------------------------------------

pai_daydream_terminate(DaydreamId) :-
    retractall(active_daydream(DaydreamId, _, _)).

% ---------------------------------------------------------------------------
% pai_daydream_product/2
% ---------------------------------------------------------------------------

pai_daydream_product(DaydreamId, Product) :-
    daydream_product(DaydreamId, Product, _Tag).
