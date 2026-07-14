/*  PrologAI — Causalontology Safety Governor  (WP-414, Layer 389)

    THE_BUILDING_FILES require a conscience that sits apart from the mind's own
    learning: a guard holding a human-set constitution, checking every risky
    action before it is taken, able always to veto with a reason, keeping an
    immutable record of what it stopped, and unmodifiable by the system it
    guards. Causalontology already marks a relation "preventive" inside co_core
    and predicts fatal moves in verification, but there was no separate governor
    that owns the last word. This pack is that governor.

    It holds two kinds of prohibition:

      constraint(Pattern, Reason)  a constitutional rule — an action pattern that
                                   must never be taken, with the reason why. A
                                   pattern may contain variables, so forbid
                                   touch(_) bans touching anything.
      avoid(Action)                a learned hazard mirrored in from co_core's
                                   preventive relations, so the governor enforces
                                   what the model learned to fear.

    Checking a proposed action returns allow, or veto(Reason); every veto is
    appended to an append-only log. There is no predicate to delete a constraint
    or a log entry — the constitution is add-only within a session and can be
    cleared only by an explicit operator reset, never by the mind's learning.

    Predicates:
      safety_governor_reset/0            -- clear the constitution, the hazards, and the log
      safety_governor_forbid/2           -- +Pattern, +Reason   (add a constitutional constraint)
      safety_governor_avoid_add/1        -- +Action             (mirror in a learned hazard)
      safety_governor_constraint/2       -- ?Pattern, ?Reason
      safety_governor_forbidden/1        -- +Action             (does any prohibition match?)
      safety_governor_check/2            -- +Action, -Verdict   (allow | veto(Reason); logs vetoes)
      safety_governor_permit/1           -- +Action             (true iff the action is allowed)
      safety_governor_veto_log/1         -- -Entries            (append-only veto(Seq,Action,Reason))
      safety_governor_veto_count/1       -- -N
      safety_governor_constraint_count/1 -- -N
*/

% Declare this module and its exported predicates.
:- module(safety_governor, [
    % safety_governor_reset/0: clear the constitution, hazards, and log.
    safety_governor_reset/0,
    % safety_governor_forbid/2: add a constitutional constraint.
    safety_governor_forbid/2,
    % safety_governor_avoid_add/1: mirror in a learned hazard.
    safety_governor_avoid_add/1,
    % safety_governor_constraint/2: query the constitution.
    safety_governor_constraint/2,
    % safety_governor_forbidden/1: does any prohibition match this action?
    safety_governor_forbidden/1,
    % safety_governor_check/2: allow or veto a proposed action, logging vetoes.
    safety_governor_check/2,
    % safety_governor_permit/1: succeeds only when the action is allowed.
    safety_governor_permit/1,
    % safety_governor_veto_log/1: the append-only veto log.
    safety_governor_veto_log/1,
    % safety_governor_veto_count/1: how many vetoes have been logged.
    safety_governor_veto_count/1,
    % safety_governor_constraint_count/1: how many constraints are in force.
    safety_governor_constraint_count/1
]).

% Use the list library.
:- use_module(library(lists)).

% constraint/2 is a constitutional rule; add-only within a session, so dynamic.
:- dynamic constraint/2.
% avoid/1 is a learned hazard mirrored from co_core; dynamic.
:- dynamic avoid/1.
% veto/3 is one append-only log entry: Seq, Action, Reason.
:- dynamic veto/3.
% safety_governor_vseq/1 is the rising counter that orders the veto log.
:- dynamic safety_governor_vseq/1.

% safety_governor_reset/0: an explicit operator reset clears everything (learning cannot).
safety_governor_reset :-
    % Remove the constitution.
    retractall(constraint(_,_)),
    % Remove the learned hazards.
    retractall(avoid(_)),
    % Remove the veto log.
    retractall(veto(_,_,_)),
    % Restart the veto counter.
    retractall(safety_governor_vseq(_)),
    assertz(safety_governor_vseq(0)).

% safety_governor_forbid/2: add one constitutional constraint (there is no matching remove).
safety_governor_forbid(Pattern, Reason) :-
    % A duplicate pattern-and-reason is not stored twice.
    ( constraint(Pattern, Reason) -> true ; assertz(constraint(Pattern, Reason)) ).

% safety_governor_avoid_add/1: mirror in a learned hazard from co_core's preventive relations.
safety_governor_avoid_add(Action) :-
    % Do not store the same hazard twice.
    ( avoid(Action) -> true ; assertz(avoid(Action)) ).

% safety_governor_constraint/2: expose the constitution.
safety_governor_constraint(Pattern, Reason) :-
    % Read the stored constraints.
    constraint(Pattern, Reason).

% safety_governor_forbidden/1: true if any prohibition matches the action.
safety_governor_forbidden(Action) :-
    % A prohibition matches if a violation reason can be found.
    safety_governor_violation(Action, _), !.

% safety_governor_check/2: allow the action, or veto it with a reason and log the veto.
safety_governor_check(Action, Verdict) :-
    % Look for the first prohibition the action violates.
    ( safety_governor_violation(Action, Reason)
      -> % Record the veto immutably, then report it.
         safety_governor_log_veto(Action, Reason),
         Verdict = veto(Reason)
      ;  % No prohibition matched: the action is allowed.
         Verdict = allow ).

% safety_governor_permit/1: succeeds only when the governor allows the action.
safety_governor_permit(Action) :-
    % Allowed means the verdict is exactly allow.
    safety_governor_check(Action, allow).

% safety_governor_veto_log/1: the append-only log, oldest entry first.
safety_governor_veto_log(Entries) :-
    % Collect the log entries.
    findall(Seq-veto(Seq, Action, Reason), veto(Seq, Action, Reason), Raw),
    % Order them by sequence stamp ascending.
    keysort(Raw, Sorted),
    % Drop the sort keys, keeping the entries.
    findall(E, member(_-E, Sorted), Entries).

% safety_governor_veto_count/1: how many vetoes have been logged.
safety_governor_veto_count(N) :-
    % Count the log entries.
    aggregate_all(count, veto(_,_,_), N).

% safety_governor_constraint_count/1: how many constraints are in force.
safety_governor_constraint_count(N) :-
    % Count the constraints.
    aggregate_all(count, constraint(_,_), N).

% ---- internal ---------------------------------------------------------------

% safety_governor_violation/2: the reason (if any) the action is prohibited.
safety_governor_violation(Action, Reason) :-
    % A constitutional constraint whose pattern unifies the action fires first.
    ( constraint(Pattern, R), \+ \+ (Pattern = Action)
      -> Reason = R
    % Otherwise a learned hazard that unifies the action fires.
    ; avoid(A), \+ \+ (A = Action)
      -> Reason = learned_hazard
    % Otherwise there is no violation.
    ; fail ).

% safety_governor_log_veto/2: append one veto entry to the immutable log.
safety_governor_log_veto(Action, Reason) :-
    % Consume the next sequence stamp.
    retract(safety_governor_vseq(Now)),
    Next is Now + 1,
    assertz(safety_governor_vseq(Next)),
    % Append the entry.
    assertz(veto(Next, Action, Reason)).
