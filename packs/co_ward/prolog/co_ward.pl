/*  PrologAI — Causalontology Safety Governor  (WP-414, Layer 389)

    THE_BUILDING_FILES require a conscience that sits apart from the mind's own
    learning: a guard holding a human-set constitution, checking every risky
    action before it is taken, able always to veto with a reason, keeping an
    immutable record of what it stopped, and unmodifiable by the system it
    guards. Causalontology already marks a relation "preventive" inside co_core
    and predicts fatal moves in co_verify, but there was no separate governor
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
      wd_reset/0            -- clear the constitution, the hazards, and the log
      wd_forbid/2           -- +Pattern, +Reason   (add a constitutional constraint)
      wd_avoid_add/1        -- +Action             (mirror in a learned hazard)
      wd_constraint/2       -- ?Pattern, ?Reason
      wd_forbidden/1        -- +Action             (does any prohibition match?)
      wd_check/2            -- +Action, -Verdict   (allow | veto(Reason); logs vetoes)
      wd_permit/1           -- +Action             (true iff the action is allowed)
      wd_veto_log/1         -- -Entries            (append-only veto(Seq,Action,Reason))
      wd_veto_count/1       -- -N
      wd_constraint_count/1 -- -N
*/

% Declare this module and its exported predicates.
:- module(co_ward, [
    % wd_reset/0: clear the constitution, hazards, and log.
    wd_reset/0,
    % wd_forbid/2: add a constitutional constraint.
    wd_forbid/2,
    % wd_avoid_add/1: mirror in a learned hazard.
    wd_avoid_add/1,
    % wd_constraint/2: query the constitution.
    wd_constraint/2,
    % wd_forbidden/1: does any prohibition match this action?
    wd_forbidden/1,
    % wd_check/2: allow or veto a proposed action, logging vetoes.
    wd_check/2,
    % wd_permit/1: succeeds only when the action is allowed.
    wd_permit/1,
    % wd_veto_log/1: the append-only veto log.
    wd_veto_log/1,
    % wd_veto_count/1: how many vetoes have been logged.
    wd_veto_count/1,
    % wd_constraint_count/1: how many constraints are in force.
    wd_constraint_count/1
]).

% Use the list library.
:- use_module(library(lists)).

% constraint/2 is a constitutional rule; add-only within a session, so dynamic.
:- dynamic constraint/2.
% avoid/1 is a learned hazard mirrored from co_core; dynamic.
:- dynamic avoid/1.
% veto/3 is one append-only log entry: Seq, Action, Reason.
:- dynamic veto/3.
% wd_vseq/1 is the rising counter that orders the veto log.
:- dynamic wd_vseq/1.

% wd_reset/0: an explicit operator reset clears everything (learning cannot).
wd_reset :-
    % Remove the constitution.
    retractall(constraint(_,_)),
    % Remove the learned hazards.
    retractall(avoid(_)),
    % Remove the veto log.
    retractall(veto(_,_,_)),
    % Restart the veto counter.
    retractall(wd_vseq(_)),
    assertz(wd_vseq(0)).

% wd_forbid/2: add one constitutional constraint (there is no matching remove).
wd_forbid(Pattern, Reason) :-
    % A duplicate pattern-and-reason is not stored twice.
    ( constraint(Pattern, Reason) -> true ; assertz(constraint(Pattern, Reason)) ).

% wd_avoid_add/1: mirror in a learned hazard from co_core's preventive relations.
wd_avoid_add(Action) :-
    % Do not store the same hazard twice.
    ( avoid(Action) -> true ; assertz(avoid(Action)) ).

% wd_constraint/2: expose the constitution.
wd_constraint(Pattern, Reason) :-
    % Read the stored constraints.
    constraint(Pattern, Reason).

% wd_forbidden/1: true if any prohibition matches the action.
wd_forbidden(Action) :-
    % A prohibition matches if a violation reason can be found.
    wd_violation(Action, _), !.

% wd_check/2: allow the action, or veto it with a reason and log the veto.
wd_check(Action, Verdict) :-
    % Look for the first prohibition the action violates.
    ( wd_violation(Action, Reason)
      -> % Record the veto immutably, then report it.
         wd_log_veto(Action, Reason),
         Verdict = veto(Reason)
      ;  % No prohibition matched: the action is allowed.
         Verdict = allow ).

% wd_permit/1: succeeds only when the governor allows the action.
wd_permit(Action) :-
    % Allowed means the verdict is exactly allow.
    wd_check(Action, allow).

% wd_veto_log/1: the append-only log, oldest entry first.
wd_veto_log(Entries) :-
    % Collect the log entries.
    findall(Seq-veto(Seq, Action, Reason), veto(Seq, Action, Reason), Raw),
    % Order them by sequence stamp ascending.
    keysort(Raw, Sorted),
    % Drop the sort keys, keeping the entries.
    findall(E, member(_-E, Sorted), Entries).

% wd_veto_count/1: how many vetoes have been logged.
wd_veto_count(N) :-
    % Count the log entries.
    aggregate_all(count, veto(_,_,_), N).

% wd_constraint_count/1: how many constraints are in force.
wd_constraint_count(N) :-
    % Count the constraints.
    aggregate_all(count, constraint(_,_), N).

% ---- internal ---------------------------------------------------------------

% wd_violation/2: the reason (if any) the action is prohibited.
wd_violation(Action, Reason) :-
    % A constitutional constraint whose pattern unifies the action fires first.
    ( constraint(Pattern, R), \+ \+ (Pattern = Action)
      -> Reason = R
    % Otherwise a learned hazard that unifies the action fires.
    ; avoid(A), \+ \+ (A = Action)
      -> Reason = learned_hazard
    % Otherwise there is no violation.
    ; fail ).

% wd_log_veto/2: append one veto entry to the immutable log.
wd_log_veto(Action, Reason) :-
    % Consume the next sequence stamp.
    retract(wd_vseq(Now)),
    Next is Now + 1,
    assertz(wd_vseq(Next)),
    % Append the entry.
    assertz(veto(Next, Action, Reason)).
