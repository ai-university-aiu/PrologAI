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

% Declare this file as the 'curiosity' module and list its exported predicates.
:- module(curiosity, [
    % Continue the multi-line expression started above.
    pai_observe_error/3,      % +Region, +Error, +Timestamp
    % Continue the multi-line expression started above.
    pai_learning_progress/2,  % +Region, -Progress
    % Continue the multi-line expression started above.
    pai_curiosity_urge/2,     % +Region, -Urge
    % Continue the multi-line expression started above.
    pai_curiosity_frontier/1, % -Region
    % Continue the multi-line expression started above.
    pai_self_propose_task/3,  % +Region, -GoalNodeId, -LearningProgress
    % Supply 'pai_curiosity_update/0' as the next argument to the expression above.
    pai_curiosity_update/0
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
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
% pai_observe_error/3 — record a prediction error for a region
% ---------------------------------------------------------------------------

% Define a clause for 'pai observe error': succeed when the following conditions hold.
pai_observe_error(Region, Error, Timestamp) :-
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
% pai_learning_progress/2
%
%   Compute learning progress for a Region.
%   Progress = mean(first_half_errors) - mean(second_half_errors).
%   Positive value means errors are shrinking (= learning happening).
%   With < 2 data points, progress is 0.0 (no evidence yet).
% ---------------------------------------------------------------------------

% Define a clause for 'pai learning progress': succeed when the following conditions hold.
pai_learning_progress(Region, Progress) :-
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
        sum_list(First, SumF),
        % Continue the multi-line expression started above.
        length(First, NF),
        % Continue the multi-line expression started above.
        MeanF is SumF / NF,
        % Continue the multi-line expression started above.
        sum_list(Second, SumS),
        % Continue the multi-line expression started above.
        length(Second, NS),
        % Continue the multi-line expression started above.
        MeanS is SumS / NS,
        % Continue the multi-line expression started above.
        Progress is MeanF - MeanS  % positive when error falling
    % Close the expression opened above.
    ).

% State the fact: sum list([], 0.0).
sum_list([], 0.0).
% Define a clause for 'sum list': succeed when the following conditions hold.
sum_list([H|T], Sum) :-
    % State a fact for 'sum list' with the arguments listed below.
    sum_list(T, Rest),
    % Evaluate the arithmetic expression 'H + Rest' and bind the result to 'Sum'.
    Sum is H + Rest.

% ---------------------------------------------------------------------------
% pai_curiosity_urge/2
%
%   Curiosity urge = max(0, Progress) * (1 - Habituation).
%   Habituation grows with visits, decays over time.
% ---------------------------------------------------------------------------

% Define a clause for 'pai curiosity urge': succeed when the following conditions hold.
pai_curiosity_urge(Region, Urge) :-
    % State a fact for 'pai learning progress' with the arguments listed below.
    pai_learning_progress(Region, Progress),
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
% pai_curiosity_frontier/1 — Region with highest curiosity urge
% ---------------------------------------------------------------------------

% Define a clause for 'pai curiosity frontier': succeed when the following conditions hold.
pai_curiosity_frontier(Region) :-
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
        pai_curiosity_urge(R, U)
    % Continue the multi-line expression started above.
    ), Pairs),
    % Sort list 'Pairs' into 'Sorted', keeping duplicates.
    msort(Pairs, Sorted),
    % Unify the second argument with the last element of list 'Sorted'.
    last(Sorted, _BestU-Region).

% ---------------------------------------------------------------------------
% pai_curiosity_update/0
%
%   One tick: compute urges for all known regions, decay habituation,
%   cache urge values.
% ---------------------------------------------------------------------------

% Execute: pai_curiosity_update :-.
pai_curiosity_update :-
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
        ( pai_curiosity_urge(R, U),
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
% pai_self_propose_task/3
%
%   In an idle interval, propose a practice task at the curiosity frontier.
%   Inscribes the proposal as a node_fact:
%     anchor_node(curiosity_task, [Region, Goal, Progress], Meta, NodeId)
%   Returns NodeId and the LearningProgress score driving the proposal.
%
%   Guard: only proposes when Region is known and has at least 2 errors.
% ---------------------------------------------------------------------------

% Define a clause for 'pai self propose task': succeed when the following conditions hold.
pai_self_propose_task(Region, GoalNodeId, LP) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(E, region_error_entry(Region, E, _), Errors),
    % Unify 'N' with the number of elements in list 'Errors'.
    length(Errors, N),
    % Check that 'N' is greater than or equal to '2'.
    N >= 2,
    % State a fact for 'pai learning progress' with the arguments listed below.
    pai_learning_progress(Region, LP),
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
