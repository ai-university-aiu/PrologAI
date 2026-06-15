/*  PrologAI — Sentinels Bootstrap Module
    PR 1: Launcher, Distribution, and Dialect (bootstrap storage layer)
    PR 9: Full sentinel evaluation/firing logic (to be added later)

    This module provides the minimal sentinel data-store needed for the
    PR 1 acceptance criterion AC-PR01-003: .pai files can declare sentinels
    and sentinel_list/2 confirms their registration.

    The full neuro-symbolic firing machinery (pattern evaluation, semantic
    similarity routing, priority ordering, action execution, and domain
    management) is specified in PR 9 and built on top of this store.
*/

:- module(sentinels, [
    pai_register_sentinel/6,    % +Domain,+Priority,+Pattern,+Objectives,+Action,+Doc
    sentinel_list/2,            % +Domain, -Sentinels
    sentinel_retract/1,         % +Domain
    sentinel_domain_activate/1, % +Domain
    sentinel_domain_deactivate/1% +Domain
]).

% ---------------------------------------------------------------------------
% Dynamic sentinel store
% ---------------------------------------------------------------------------

%  pai_sentinel_entry(?Domain, ?Priority, ?Pattern, ?Objectives, ?Action, ?Doc)
:- dynamic pai_sentinel_entry/6.

%  pai_sentinel_domain_active(?Domain)
:- dynamic pai_sentinel_domain_active/1.

% The 'general' domain is active by default (spec Section 3.5).
:- assertz(pai_sentinel_domain_active(general)).

% ---------------------------------------------------------------------------
% Public predicates
% ---------------------------------------------------------------------------

%! pai_register_sentinel(+Domain,+Priority,+Pattern,+Objectives,+Action,+Doc) is det.
%  Register a sentinel in the dynamic store.  Duplicates (same Domain,
%  Priority, Pattern, Action) are silently ignored to keep registration
%  idempotent.  The sentinel's domain is activated if not already active.
pai_register_sentinel(Domain, Priority, Pattern, Objectives, Action, Doc) :-
    (   pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, _)
    ->  true
    ;   assertz(pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, Doc))
    ),
    (   pai_sentinel_domain_active(Domain)
    ->  true
    ;   assertz(pai_sentinel_domain_active(Domain))
    ).

%! sentinel_list(+Domain, -Sentinels) is det.
%  Unify Sentinels with the list of all sentinel/6 terms currently
%  registered in Domain.  Returns an empty list for an unknown domain.
sentinel_list(Domain, Sentinels) :-
    findall(
        sentinel(Domain, Priority, Pattern, Objectives, Action, Doc),
        pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, Doc),
        Sentinels
    ).

%! sentinel_retract(+Domain) is det.
%  Remove all sentinels registered under Domain.
sentinel_retract(Domain) :-
    retractall(pai_sentinel_entry(Domain, _, _, _, _, _)).

%! sentinel_domain_activate(+Domain) is det.
%  Make Domain eligible for sentinel evaluation.
sentinel_domain_activate(Domain) :-
    (   pai_sentinel_domain_active(Domain)
    ->  true
    ;   assertz(pai_sentinel_domain_active(Domain))
    ).

%! sentinel_domain_deactivate(+Domain) is det.
%  Suspend sentinel evaluation in Domain.
sentinel_domain_deactivate(Domain) :-
    retractall(pai_sentinel_domain_active(Domain)).
