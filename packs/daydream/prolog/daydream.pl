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

% Declare this file as the 'daydream' module and list its exported predicates.
:- module(daydream, [
    % Continue the multi-line expression started above.
    pai_control_goal/2,         % +Trigger, -ControlGoal
    % Continue the multi-line expression started above.
    pai_daydream_steer/2,       % +Episode, -DaydreamProduct
    % Continue the multi-line expression started above.
    pai_daydream_terminate/1,   % +DaydreamId
    % Continue the multi-line expression started above.
    pai_daydream_product/2      % +DaydreamId, -Product
% Close the expression opened above.
]).

% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'active_daydream/3.   % DaydreamId, ControlGoal, Valence' as dynamic — its facts may be added or removed at runtime.
:- dynamic active_daydream/3.   % DaydreamId, ControlGoal, Valence
% Declare 'daydream_product/3.  % DaydreamId, Product, Tag(imagined|validated)' as dynamic — its facts may be added or removed at runtime.
:- dynamic daydream_product/3.  % DaydreamId, Product, Tag(imagined|validated)
% Declare 'daydream_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic daydream_id_counter/1.
% State the fact: daydream id counter(0).
daydream_id_counter(0).

% Define a clause for 'next daydream id': succeed when the following conditions hold.
next_daydream_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(daydream_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_id_counter(N1)),
    % State the fact: atomic list concat([daydream_, N1], Id).
    atomic_list_concat([daydream_, N1], Id).

% ---------------------------------------------------------------------------
% Control-goal trigger mapping
%
%   Episode = episode(Valence, Arousal, Cause, Outcome)
%     Cause   = self | other(Agent) | unknown
%     Outcome = failure | success | planned
% ---------------------------------------------------------------------------

% Define a clause for 'pai control goal': succeed when the following conditions hold.
pai_control_goal(episode(V, _A, Cause, Outcome), ControlGoal) :-
    % State the fact: select control goal(V, Cause, Outcome, ControlGoal).
    select_control_goal(V, Cause, Outcome, ControlGoal).

% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(V, _Cause, failure, rationalization) :-
    % Check that 'V' is less than '-0.3, !'.
    V < -0.3, !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(V, other(_), failure, reprisal_fantasy) :-
    % Check that 'V' is less than '0.0, !'.
    V < 0.0, !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, failure, reversal) :- !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, success, reversal) :- !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, planned, preparation) :- !.
% State a fact for 'select control goal' with the arguments listed below.
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

% Define a clause for 'pai daydream steer': succeed when the following conditions hold.
pai_daydream_steer(Episode, DaydreamProduct) :-
    % State a fact for 'pai control goal' with the arguments listed below.
    pai_control_goal(Episode, ControlGoal),
    % Check that 'Episode' is unifiable with 'episode(Valence, Arousal, _Cause, _Outcome)'.
    Episode = episode(Valence, Arousal, _Cause, _Outcome),
    % State a fact for 'next daydream id' with the arguments listed below.
    next_daydream_id(DId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(active_daydream(DId, ControlGoal, Valence)),
    % State a fact for 'run daydream' with the arguments listed below.
    run_daydream(DId, ControlGoal, Valence, Arousal, Product),
    % Check that 'Product' is unifiable with 'product(_, NewValence, _)'.
    Product = product(_, NewValence, _),
    % Worsen-emotion guard: only keep the product if emotion improves
    % Check that '( NewValence' is greater than or equal to 'Valence'.
    ( NewValence >= Valence
    % If the condition above succeeded, perform the following action.
    ->  tag_product(DId, ControlGoal, Product),
        % Continue the multi-line expression started above.
        DaydreamProduct = product(DId, ControlGoal, Product)
    % Otherwise (else branch), perform the following action.
    ;   retract(active_daydream(DId, ControlGoal, Valence)),
        % Continue the multi-line expression started above.
        pai_daydream_terminate(DId),
        % Continue the multi-line expression started above.
        DaydreamProduct = terminated(DId, worsened_emotion)
    % Close the expression opened above.
    ).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, rationalization, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(strategy(reframe_outcome), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'min(0.0, Valence + 0.3)' and bind the result to 'NewValence'.
    NewValence is min(0.0, Valence + 0.3),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            strategy(reframe_outcome, from(Valence), to(NewValence)),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, reprisal_fantasy, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(fantasy(imagined_redress), NewValence, never_execute)) :-
    % Evaluate the arithmetic expression 'Valence + 0.4' and bind the result to 'NewValence'.
    NewValence is Valence + 0.4,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            fantasy(imagined_redress, never_execute),
            % Supply 'never_execute' as the next argument to the expression above.
            never_execute)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, reversal, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(strategy(learn_from_reversal), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'Valence + 0.2' and bind the result to 'NewValence'.
    NewValence is Valence + 0.2,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            strategy(learn_from_reversal),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, preparation, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(scenario(rehearsal), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'Valence + 0.1' and bind the result to 'NewValence'.
    NewValence is Valence + 0.1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            scenario(rehearsal),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% Define a clause for 'tag product': succeed when the following conditions hold.
tag_product(_DId, reprisal_fantasy, _Product) :- !.   % never_execute, no extra action
% State the fact: tag product(_DId, _ControlGoal, _Product).
tag_product(_DId, _ControlGoal, _Product).

% ---------------------------------------------------------------------------
% pai_daydream_terminate/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream terminate': succeed when the following conditions hold.
pai_daydream_terminate(DaydreamId) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(active_daydream(DaydreamId, _, _)).

% ---------------------------------------------------------------------------
% pai_daydream_product/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream product': succeed when the following conditions hold.
pai_daydream_product(DaydreamId, Product) :-
    % State the fact: daydream product(DaydreamId, Product, _Tag).
    daydream_product(DaydreamId, Product, _Tag).
