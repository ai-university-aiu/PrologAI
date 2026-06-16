/*  PrologAI — Resource-Bounded Reasoning: Budgets and Evidence Truth  (PR 21)

    Implements the Assumption of Insufficient Knowledge and Resources (AIKR):
    every task carries a budget, every belief carries revisable evidence,
    and answers are anytime (best available, never fabricated certainty).

    Budget = (Priority, Durability, Quality)
      Priority  — current importance [0,1]; decays at rate 1/Durability
      Durability— how slowly priority decays (higher = slower)
      Quality   — output quality achieved so far [0,1]

    Evidence Truth = (Frequency, Confidence)
      Frequency  — proportion of positive evidence [0,1]
      Confidence — total evidence count; higher = more trusted

    pai_best_answer/2 returns the highest-confidence belief immediately
    (anytime semantics).  Zero-evidence questions answer `no_evidence`.

    Predicates:
      pai_budget/3         — +Task, +Budget, -TaskId  |  +Task, -Budget
      pai_truth_evidence/3 — +Belief, +Pos, +Total     |  +Belief, -Freq, -Conf
      pai_best_answer/2    — +Question, -Answer
      pai_revise/3         — +Belief, +IsPositive, -NewFreq
*/

% Declare this file as the 'budget' module and list its exported predicates.
:- module(budget, [
    % Continue the multi-line expression started above.
    pai_budget/3,           % attach/query budget: +Task, +(P,D,Q)|-Budget
    % Continue the multi-line expression started above.
    pai_budget_set/4,       % +Task, +Priority, +Durability, +Quality
    % Continue the multi-line expression started above.
    pai_budget_get/4,       % +Task, -Priority, -Durability, -Quality
    % Continue the multi-line expression started above.
    pai_truth_evidence/3,   % +Belief, +PosCount, +TotalCount  OR  +Belief, -Freq, -Conf
    % Continue the multi-line expression started above.
    pai_truth_evidence_add/3,% +Belief, +IsPositive (true|false), -NewConf
    % Continue the multi-line expression started above.
    pai_best_answer/2,      % +Question, -Answer
    % Continue the multi-line expression started above.
    pai_revise/3,           % +Belief, +IsPositive, -NewFreq
    % Continue the multi-line expression started above.
    pai_budget_decay/1,     % +Task  (apply one decay step)
    % Continue the multi-line expression started above.
    pai_forget_cheapest/1   % +MaxItems (forget lowest-budget items above limit)
% Close the expression opened above.
]).

% Import [anchor_node/4, default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),       [maplist/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Budget store
%
%   task_budget(Task, Priority, Durability, Quality)
% ---------------------------------------------------------------------------

% Declare 'task_budget/4.       % Task, Priority, Durability, Quality' as dynamic — its facts may be added or removed at runtime.
:- dynamic task_budget/4.       % Task, Priority, Durability, Quality
% Declare 'belief_evidence/3.   % Belief, PosCount, TotalCount' as dynamic — its facts may be added or removed at runtime.
:- dynamic belief_evidence/3.   % Belief, PosCount, TotalCount

% ---------------------------------------------------------------------------
% pai_budget/3  — overloaded:
%   mode 1: pai_budget(+Task, +PriorityDurabilityQuality, -ok)
%           PriorityDurabilityQuality is a term budget(P,D,Q)
%   mode 2: pai_budget(+Task, -Budget, unused) is confusing; use explicit preds
% ---------------------------------------------------------------------------

% Define a clause for 'pai budget': succeed when the following conditions hold.
pai_budget(Task, Budget, TaskId) :-
    % Check that '( Budget' is unifiable with 'budget(Priority, Durability, Quality)'.
    ( Budget = budget(Priority, Durability, Quality)
    % If the condition above succeeded, perform the following action.
    ->  pai_budget_set(Task, Priority, Durability, Quality),
        % Continue the multi-line expression started above.
        TaskId = Task
    % Otherwise (else branch), perform the following action.
    ;   pai_budget_get(Task, Priority, Durability, Quality),
        % Continue the multi-line expression started above.
        Budget = budget(Priority, Durability, Quality),
        % Continue the multi-line expression started above.
        TaskId = Task
    % Close the expression opened above.
    ).

% Define a clause for 'pai budget set': succeed when the following conditions hold.
pai_budget_set(Task, Priority, Durability, Quality) :-
    % Evaluate the arithmetic expression 'max(0.0, min(1.0, float(Priority)))' and bind the result to 'P'.
    P is max(0.0, min(1.0, float(Priority))),
    % Evaluate the arithmetic expression 'max(1.0, float(Durability))' and bind the result to 'D'.
    D is max(1.0, float(Durability)),
    % Evaluate the arithmetic expression 'max(0.0, min(1.0, float(Quality)))' and bind the result to 'Q'.
    Q is max(0.0, min(1.0, float(Quality))),
    % Remove all matching facts from the runtime knowledge base.
    retractall(task_budget(Task, _, _, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(task_budget(Task, P, D, Q)).

% Define a clause for 'pai budget get': succeed when the following conditions hold.
pai_budget_get(Task, Priority, Durability, Quality) :-
    % Execute: ( task_budget(Task, Priority, Durability, Quality).
    ( task_budget(Task, Priority, Durability, Quality)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   Priority = 0.5, Durability = 10.0, Quality = 0.0   % defaults
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_budget_decay/1 — apply one decay step to a task's priority
% ---------------------------------------------------------------------------

% Define a clause for 'pai budget decay': succeed when the following conditions hold.
pai_budget_decay(Task) :-
    % Execute: ( task_budget(Task, P, D, Q).
    ( task_budget(Task, P, D, Q)
    % If the condition above succeeded, perform the following action.
    ->  NewP is max(0.0, P * (1.0 - 1.0 / D)),
        % Continue the multi-line expression started above.
        retract(task_budget(Task, P, D, Q)),
        % Continue the multi-line expression started above.
        assertz(task_budget(Task, NewP, D, Q))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_truth_evidence/3 — attach or query evidence for a belief
%
%   pai_truth_evidence(+Belief, +PosCount, +TotalCount)  — set evidence
%   pai_truth_evidence(+Belief, -Frequency, -Confidence) — query (Confidence = TotalCount)
% ---------------------------------------------------------------------------

% Define a clause for 'pai truth evidence': succeed when the following conditions hold.
pai_truth_evidence(Belief, Arg2, Arg3) :-
    % Execute: ( integer(Arg2), integer(Arg3).
    ( integer(Arg2), integer(Arg3)
    % If the condition above succeeded, perform the following action.
    ->  % Set mode
        % Continue the multi-line expression started above.
        retractall(belief_evidence(Belief, _, _)),
        % Continue the multi-line expression started above.
        assertz(belief_evidence(Belief, Arg2, Arg3))
    % Otherwise (else branch), perform the following action.
    ;   % Query mode
        % Continue the multi-line expression started above.
        ( belief_evidence(Belief, Pos, Total)
        % If the condition above succeeded, perform the following action.
        ->  ( Total > 0
            % If the condition above succeeded, perform the following action.
            ->  Frequency is Pos / Total,
                % Continue the multi-line expression started above.
                Confidence = Total
            % Otherwise (else branch), perform the following action.
            ;   Frequency = 0.0,
                % Continue the multi-line expression started above.
                Confidence = 0
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   Frequency = 0.0,
            % Continue the multi-line expression started above.
            Confidence = 0
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        Arg2 = Frequency,
        % Continue the multi-line expression started above.
        Arg3 = Confidence
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_truth_evidence_add/3 — update evidence incrementally
% ---------------------------------------------------------------------------

% Define a clause for 'pai truth evidence add': succeed when the following conditions hold.
pai_truth_evidence_add(Belief, IsPositive, NewConf) :-
    % Execute: ( belief_evidence(Belief, Pos, Total).
    ( belief_evidence(Belief, Pos, Total)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   Pos = 0, Total = 0
    % Close the expression opened above.
    ),
    % Evaluate the arithmetic expression 'Total + 1' and bind the result to 'NewTotal'.
    NewTotal is Total + 1,
    % Check that '( IsPositive' is structurally identical to 'true'.
    ( IsPositive == true
    % If the condition above succeeded, perform the following action.
    ->  NewPos is Pos + 1
    % Otherwise (else branch), perform the following action.
    ;   NewPos = Pos
    % Close the expression opened above.
    ),
    % Remove all matching facts from the runtime knowledge base.
    retractall(belief_evidence(Belief, _, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(belief_evidence(Belief, NewPos, NewTotal)),
    % Check that 'NewConf' is unifiable with 'NewTotal'.
    NewConf = NewTotal.

% ---------------------------------------------------------------------------
% pai_best_answer/2 — anytime answering
%
%   Returns the highest-confidence belief matching Question.
%   If no beliefs exist, returns no_evidence.
%
%   Question can be:
%     atom   — literal belief name
%     _      — wildcard (any belief)
% ---------------------------------------------------------------------------

% Define a clause for 'pai best answer': succeed when the following conditions hold.
pai_best_answer(Question, Answer) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Conf-Belief-Freq, (
        % Continue the multi-line expression started above.
        belief_evidence(Belief, Pos, Total),
        % Continue the multi-line expression started above.
        ( Question = Belief ; \+ atom(Question) ),
        % Continue the multi-line expression started above.
        Total > 0,
        % Continue the multi-line expression started above.
        Freq is Pos / Total,
        % Continue the multi-line expression started above.
        Conf = Total
    % Continue the multi-line expression started above.
    ), Candidates),
    % Check that '( Candidates' is unifiable with '[]'.
    ( Candidates = []
    % If the condition above succeeded, perform the following action.
    ->  Answer = no_evidence(Question, confidence(0))
    % Otherwise (else branch), perform the following action.
    ;   max_confidence(Candidates, MaxConf-BestBelief-BestFreq),
        % Continue the multi-line expression started above.
        Answer = answer(BestBelief, frequency(BestFreq), confidence(MaxConf))
    % Close the expression opened above.
    ).

% Define a clause for 'max confidence': succeed when the following conditions hold.
max_confidence([X], X) :- !.
% Define a clause for 'max confidence': succeed when the following conditions hold.
max_confidence([H|T], Max) :-
    % State a fact for 'max confidence' with the arguments listed below.
    max_confidence(T, MaxT),
    % Check that 'H' is unifiable with 'C1-_-_'.
    H = C1-_-_,
    % Check that 'MaxT' is unifiable with 'C2-_-_'.
    MaxT = C2-_-_,
    % Check that '( C1' is greater than or equal to 'C2 -> Max = H ; Max = MaxT )'.
    ( C1 >= C2 -> Max = H ; Max = MaxT ).

% ---------------------------------------------------------------------------
% pai_revise/3 — revise a belief with new evidence
%
%   Contradictory evidence merges by revision, never rejection.
% ---------------------------------------------------------------------------

% Define a clause for 'pai revise': succeed when the following conditions hold.
pai_revise(Belief, IsPositive, NewFreq) :-
    % State a fact for 'pai truth evidence add' with the arguments listed below.
    pai_truth_evidence_add(Belief, IsPositive, _NewConf),
    % State a fact for 'belief evidence' with the arguments listed below.
    belief_evidence(Belief, Pos, Total),
    % Check that '( Total' is greater than '0'.
    ( Total > 0
    % If the condition above succeeded, perform the following action.
    ->  NewFreq is Pos / Total
    % Otherwise (else branch), perform the following action.
    ;   NewFreq = 0.0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_forget_cheapest/1
%
%   Under memory pressure, forget the MaxItems lowest-budget items.
%   Starvation check: boost long-waiting high-durability tasks first.
% ---------------------------------------------------------------------------

% Define a clause for 'pai forget cheapest': succeed when the following conditions hold.
pai_forget_cheapest(MaxItems) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(P-Task, task_budget(Task, P, _, _), Budgets),
    % Sort list 'Budgets' into 'Ascending', keeping duplicates.
    msort(Budgets, Ascending),
    % Unify 'Total' with the number of elements in list 'Budgets'.
    length(Budgets, Total),
    % Check that '( Total' is greater than 'MaxItems'.
    ( Total > MaxItems
    % If the condition above succeeded, perform the following action.
    ->  ToForget is Total - MaxItems,
        % Continue the multi-line expression started above.
        take_k(ToForget, Ascending, LowBudgets),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_P-Task, LowBudgets),
            % Continue the multi-line expression started above.
            catch(retractall(task_budget(Task, _, _, _)), _, true)
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
