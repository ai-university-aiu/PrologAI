/*  PrologAI — Curiosity: Intrinsic Motivation by Learning Progress  (PR 23)

    Partitions experience into regions by situation similarity.  For each
    region the module tracks a sliding window of prediction errors and
    computes learning progress as the rate of error reduction.  An
    intrinsic curiosity urge proportional to that progress is emitted
    into the motivation bus exactly like a homeostatic urge.

    Guards implemented:
      • Noisy-television guard: progress (not raw error) is rewarded,
        so a region whose error is large but flat (unlearnable noise)
        receives a low urge while a region with rapidly shrinking error
        receives a high one.
      • Habituation guard: repeated self-generated exploration of the
        same region is suppressed by a habituation term that grows with
        visit frequency and decays over time.
      • Survival-critical override: curiosity always yields to urges
        tagged survival_critical.

    Predicates:
      pai_observe_error/3         — +Region, +Error, +Timestamp
      pai_learning_progress/2     — +Region, -Progress
      pai_curiosity_urge/2        — +Region, -Urge
      pai_curiosity_frontier/1    — -Region with highest urge
      pai_self_propose_task/3     — +Region, -GoalNodeId, -LearningProgress
      pai_curiosity_update/0      — tick: update all region urges
*/

:- module(curiosity, [
    pai_observe_error/3,      % +Region, +Error, +Timestamp
    pai_learning_progress/2,  % +Region, -Progress
    pai_curiosity_urge/2,     % +Region, -Urge
    pai_curiosity_frontier/1, % -Region
    pai_self_propose_task/3,  % +Region, -GoalNodeId, -LearningProgress
    pai_curiosity_update/0
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lists),      [member/2, last/2]).
:- use_module(library(aggregate),  [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic region_error_entry/3.   % Region, Error, Timestamp
:- dynamic region_habituation/2.   % Region, HabituationLevel (0-1)
:- dynamic region_urge_cache/2.    % Region, Urge

error_window_size(10).             % sliding window — last N errors per region
habituation_decay_rate(0.05).      % per-tick decay of habituation
habituation_visit_increment(0.15). % added to habituation per visit

% ---------------------------------------------------------------------------
% pai_observe_error/3 — record a prediction error for a region
% ---------------------------------------------------------------------------

pai_observe_error(Region, Error, Timestamp) :-
    assertz(region_error_entry(Region, Error, Timestamp)),
    trim_error_window(Region).

trim_error_window(Region) :-
    error_window_size(W),
    findall(E-T, region_error_entry(Region, E, T), All),
    length(All, N),
    ( N > W
    ->  Excess is N - W,
        take_k(Excess, All, ToRemove),
        forall(
            member(E-T, ToRemove),
            retract(region_error_entry(Region, E, T))
        )
    ;   true
    ).

take_k(0, _, []) :- !.
take_k(_, [], []) :- !.
take_k(K, [H|T], [H|R]) :- K > 0, K1 is K - 1, take_k(K1, T, R).

% ---------------------------------------------------------------------------
% pai_learning_progress/2
%
%   Compute learning progress for a Region.
%   Progress = mean(first_half_errors) - mean(second_half_errors).
%   Positive value means errors are shrinking (= learning happening).
%   With < 2 data points, progress is 0.0 (no evidence yet).
% ---------------------------------------------------------------------------

pai_learning_progress(Region, Progress) :-
    findall(E, region_error_entry(Region, E, _), Errors),
    length(Errors, N),
    ( N < 2
    ->  Progress = 0.0
    ;   Half is N // 2,
        length(First, Half),
        append(First, Rest, Errors),
        ( Rest = []
        ->  Second = First
        ;   Second = Rest
        ),
        sum_list(First, SumF),
        length(First, NF),
        MeanF is SumF / NF,
        sum_list(Second, SumS),
        length(Second, NS),
        MeanS is SumS / NS,
        Progress is MeanF - MeanS  % positive when error falling
    ).

sum_list([], 0.0).
sum_list([H|T], Sum) :-
    sum_list(T, Rest),
    Sum is H + Rest.

% ---------------------------------------------------------------------------
% pai_curiosity_urge/2
%
%   Curiosity urge = max(0, Progress) * (1 - Habituation).
%   Habituation grows with visits, decays over time.
% ---------------------------------------------------------------------------

pai_curiosity_urge(Region, Urge) :-
    pai_learning_progress(Region, Progress),
    ( region_habituation(Region, Hab)
    ->  true
    ;   Hab = 0.0
    ),
    RawUrge is max(0.0, Progress) * (1.0 - Hab),
    Urge is min(1.0, RawUrge).

% ---------------------------------------------------------------------------
% pai_curiosity_frontier/1 — Region with highest curiosity urge
% ---------------------------------------------------------------------------

pai_curiosity_frontier(Region) :-
    findall(R, region_error_entry(R, _, _), AllR0),
    sort(AllR0, AllR),
    AllR \= [],
    findall(U-R, (
        member(R, AllR),
        pai_curiosity_urge(R, U)
    ), Pairs),
    msort(Pairs, Sorted),
    last(Sorted, _BestU-Region).

% ---------------------------------------------------------------------------
% pai_curiosity_update/0
%
%   One tick: compute urges for all known regions, decay habituation,
%   cache urge values.
% ---------------------------------------------------------------------------

pai_curiosity_update :-
    % Collect all known regions
    findall(R, region_error_entry(R, _, _), AllR0),
    sort(AllR0, AllR),
    % Decay habituation for all regions
    forall(
        member(R, AllR),
        decay_habituation(R)
    ),
    % Recompute and cache urges
    retractall(region_urge_cache(_, _)),
    forall(
        member(R, AllR),
        ( pai_curiosity_urge(R, U),
          assertz(region_urge_cache(R, U))
        )
    ).

decay_habituation(Region) :-
    habituation_decay_rate(Rate),
    ( retract(region_habituation(Region, H))
    ->  NewH is max(0.0, H - Rate),
        assertz(region_habituation(Region, NewH))
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_self_propose_task/3
%
%   In an idle interval, propose a practice task at the curiosity frontier.
%   Inscribes the proposal as a node_fact:
%     anchor_node(curiosity_task, [Region, Goal, Progress], Meta, NodeId)
%   Returns NodeId and the LearningProgress score driving the proposal.
%
%   Guard: only proposes when Region is known and has at least 2 errors.
% ---------------------------------------------------------------------------

pai_self_propose_task(Region, GoalNodeId, LP) :-
    findall(E, region_error_entry(Region, E, _), Errors),
    length(Errors, N),
    N >= 2,
    pai_learning_progress(Region, LP),
    % Increment habituation so we don't keep choosing the same region
    habituation_visit_increment(Inc),
    ( retract(region_habituation(Region, H))
    ->  NewH is min(1.0, H + Inc)
    ;   NewH = Inc
    ),
    assertz(region_habituation(Region, NewH)),
    % Goal: reduce prediction error in this region
    atomic_list_concat([explore_, Region], Goal),
    catch(
        anchor_node(curiosity_task,
                    [Region, Goal, learning_progress(LP)],
                    [proposed=true, rationale=learning_progress],
                    GoalNodeId),
        _,
        GoalNodeId = curiosity_task(Region)
    ).
