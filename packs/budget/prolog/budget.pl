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

:- module(budget, [
    pai_budget/3,           % attach/query budget: +Task, +(P,D,Q)|-Budget
    pai_budget_set/4,       % +Task, +Priority, +Durability, +Quality
    pai_budget_get/4,       % +Task, -Priority, -Durability, -Quality
    pai_truth_evidence/3,   % +Belief, +PosCount, +TotalCount  OR  +Belief, -Freq, -Conf
    pai_truth_evidence_add/3,% +Belief, +IsPositive (true|false), -NewConf
    pai_best_answer/2,      % +Question, -Answer
    pai_revise/3,           % +Belief, +IsPositive, -NewFreq
    pai_budget_decay/1,     % +Task  (apply one decay step)
    pai_forget_cheapest/1   % +MaxItems (forget lowest-budget items above limit)
]).

:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1]).
:- use_module(library(lists),       [member/2]).
:- use_module(library(apply),       [maplist/3]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Budget store
%
%   task_budget(Task, Priority, Durability, Quality)
% ---------------------------------------------------------------------------

:- dynamic task_budget/4.       % Task, Priority, Durability, Quality
:- dynamic belief_evidence/3.   % Belief, PosCount, TotalCount

% ---------------------------------------------------------------------------
% pai_budget/3  — overloaded:
%   mode 1: pai_budget(+Task, +PriorityDurabilityQuality, -ok)
%           PriorityDurabilityQuality is a term budget(P,D,Q)
%   mode 2: pai_budget(+Task, -Budget, unused) is confusing; use explicit preds
% ---------------------------------------------------------------------------

pai_budget(Task, Budget, TaskId) :-
    ( Budget = budget(Priority, Durability, Quality)
    ->  pai_budget_set(Task, Priority, Durability, Quality),
        TaskId = Task
    ;   pai_budget_get(Task, Priority, Durability, Quality),
        Budget = budget(Priority, Durability, Quality),
        TaskId = Task
    ).

pai_budget_set(Task, Priority, Durability, Quality) :-
    P is max(0.0, min(1.0, float(Priority))),
    D is max(1.0, float(Durability)),
    Q is max(0.0, min(1.0, float(Quality))),
    retractall(task_budget(Task, _, _, _)),
    assertz(task_budget(Task, P, D, Q)).

pai_budget_get(Task, Priority, Durability, Quality) :-
    ( task_budget(Task, Priority, Durability, Quality)
    ->  true
    ;   Priority = 0.5, Durability = 10.0, Quality = 0.0   % defaults
    ).

% ---------------------------------------------------------------------------
% pai_budget_decay/1 — apply one decay step to a task's priority
% ---------------------------------------------------------------------------

pai_budget_decay(Task) :-
    ( task_budget(Task, P, D, Q)
    ->  NewP is max(0.0, P * (1.0 - 1.0 / D)),
        retract(task_budget(Task, P, D, Q)),
        assertz(task_budget(Task, NewP, D, Q))
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_truth_evidence/3 — attach or query evidence for a belief
%
%   pai_truth_evidence(+Belief, +PosCount, +TotalCount)  — set evidence
%   pai_truth_evidence(+Belief, -Frequency, -Confidence) — query (Confidence = TotalCount)
% ---------------------------------------------------------------------------

pai_truth_evidence(Belief, Arg2, Arg3) :-
    ( integer(Arg2), integer(Arg3)
    ->  % Set mode
        retractall(belief_evidence(Belief, _, _)),
        assertz(belief_evidence(Belief, Arg2, Arg3))
    ;   % Query mode
        ( belief_evidence(Belief, Pos, Total)
        ->  ( Total > 0
            ->  Frequency is Pos / Total,
                Confidence = Total
            ;   Frequency = 0.0,
                Confidence = 0
            )
        ;   Frequency = 0.0,
            Confidence = 0
        ),
        Arg2 = Frequency,
        Arg3 = Confidence
    ).

% ---------------------------------------------------------------------------
% pai_truth_evidence_add/3 — update evidence incrementally
% ---------------------------------------------------------------------------

pai_truth_evidence_add(Belief, IsPositive, NewConf) :-
    ( belief_evidence(Belief, Pos, Total)
    ->  true
    ;   Pos = 0, Total = 0
    ),
    NewTotal is Total + 1,
    ( IsPositive == true
    ->  NewPos is Pos + 1
    ;   NewPos = Pos
    ),
    retractall(belief_evidence(Belief, _, _)),
    assertz(belief_evidence(Belief, NewPos, NewTotal)),
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

pai_best_answer(Question, Answer) :-
    findall(Conf-Belief-Freq, (
        belief_evidence(Belief, Pos, Total),
        ( Question = Belief ; \+ atom(Question) ),
        Total > 0,
        Freq is Pos / Total,
        Conf = Total
    ), Candidates),
    ( Candidates = []
    ->  Answer = no_evidence(Question, confidence(0))
    ;   max_confidence(Candidates, MaxConf-BestBelief-BestFreq),
        Answer = answer(BestBelief, frequency(BestFreq), confidence(MaxConf))
    ).

max_confidence([X], X) :- !.
max_confidence([H|T], Max) :-
    max_confidence(T, MaxT),
    H = C1-_-_,
    MaxT = C2-_-_,
    ( C1 >= C2 -> Max = H ; Max = MaxT ).

% ---------------------------------------------------------------------------
% pai_revise/3 — revise a belief with new evidence
%
%   Contradictory evidence merges by revision, never rejection.
% ---------------------------------------------------------------------------

pai_revise(Belief, IsPositive, NewFreq) :-
    pai_truth_evidence_add(Belief, IsPositive, _NewConf),
    belief_evidence(Belief, Pos, Total),
    ( Total > 0
    ->  NewFreq is Pos / Total
    ;   NewFreq = 0.0
    ).

% ---------------------------------------------------------------------------
% pai_forget_cheapest/1
%
%   Under memory pressure, forget the MaxItems lowest-budget items.
%   Starvation check: boost long-waiting high-durability tasks first.
% ---------------------------------------------------------------------------

pai_forget_cheapest(MaxItems) :-
    findall(P-Task, task_budget(Task, P, _, _), Budgets),
    msort(Budgets, Ascending),
    length(Budgets, Total),
    ( Total > MaxItems
    ->  ToForget is Total - MaxItems,
        take_k(ToForget, Ascending, LowBudgets),
        forall(
            member(_P-Task, LowBudgets),
            catch(retractall(task_budget(Task, _, _, _)), _, true)
        )
    ;   true
    ).

take_k(0, _, []) :- !.
take_k(_, [], []) :- !.
take_k(K, [H|T], [H|R]) :- K > 0, K1 is K - 1, take_k(K1, T, R).
