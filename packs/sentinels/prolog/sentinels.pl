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

% Declare this file as the 'sentinels' module and list its exported predicates.
:- module(sentinels, [
    % Continue the multi-line expression started above.
    pai_register_sentinel/6,    % +Domain,+Priority,+Pattern,+Objectives,+Action,+Doc
    % Continue the multi-line expression started above.
    sentinel_list/2,            % +Domain, -Sentinels
    % Continue the multi-line expression started above.
    sentinel_retract/1,         % +Domain
    % Continue the multi-line expression started above.
    sentinel_domain_activate/1, % +Domain
    % Continue the multi-line expression started above.
    sentinel_domain_deactivate/1,% +Domain
    % Continue the multi-line expression started above.
    pai_sentinel_entry/6,       % ?Dom,?Pri,?Pat,?Obj,?Act,?Doc  (for engine)
    % Continue the multi-line expression started above.
    pai_sentinel_domain_active/1 % ?Domain (for engine)
% Close the expression opened above.
]).

% ---------------------------------------------------------------------------
% Dynamic sentinel store
% ---------------------------------------------------------------------------

%  pai_sentinel_entry(?Domain, ?Priority, ?Pattern, ?Objectives, ?Action, ?Doc)
% Declare 'pai_sentinel_entry/6' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_sentinel_entry/6.

%  pai_sentinel_domain_active(?Domain)
% Declare 'pai_sentinel_domain_active/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_sentinel_domain_active/1.

% The 'general' domain is active by default (spec Section 3.5).
% Execute the compile-time directive: assertz(pai_sentinel_domain_active(general)).
:- assertz(pai_sentinel_domain_active(general)).

% ---------------------------------------------------------------------------
% Public predicates
% ---------------------------------------------------------------------------

%! pai_register_sentinel(+Domain,+Priority,+Pattern,+Objectives,+Action,+Doc) is det.
%  Register a sentinel in the dynamic store.  Duplicates (same Domain,
%  Priority, Pattern, Action) are silently ignored to keep registration
%  idempotent.  The sentinel's domain is activated if not already active.
% Define a clause for 'pai register sentinel': succeed when the following conditions hold.
pai_register_sentinel(Domain, Priority, Pattern, Objectives, Action, Doc) :-
    % Execute: (   pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, _).
    (   pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, Doc))
    % Close the expression opened above.
    ),
    % Execute: (   pai_sentinel_domain_active(Domain).
    (   pai_sentinel_domain_active(Domain)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(pai_sentinel_domain_active(Domain))
    % Close the expression opened above.
    ).

%! sentinel_list(+Domain, -Sentinels) is det.
%  Unify Sentinels with the list of all sentinel/6 terms currently
%  registered in Domain.  Returns an empty list for an unknown domain.
% Define a clause for 'sentinel list': succeed when the following conditions hold.
sentinel_list(Domain, Sentinels) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(
        % Continue the multi-line expression started above.
        sentinel(Domain, Priority, Pattern, Objectives, Action, Doc),
        % Continue the multi-line expression started above.
        pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, Doc),
        % Supply 'Sentinels' as the next argument to the expression above.
        Sentinels
    % Close the expression opened above.
    ).

%! sentinel_retract(+Domain) is det.
%  Remove all sentinels registered under Domain.
% Define a clause for 'sentinel retract': succeed when the following conditions hold.
sentinel_retract(Domain) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_sentinel_entry(Domain, _, _, _, _, _)).

%! sentinel_domain_activate(+Domain) is det.
%  Make Domain eligible for sentinel evaluation.
% Define a clause for 'sentinel domain activate': succeed when the following conditions hold.
sentinel_domain_activate(Domain) :-
    % Execute: (   pai_sentinel_domain_active(Domain).
    (   pai_sentinel_domain_active(Domain)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(pai_sentinel_domain_active(Domain))
    % Close the expression opened above.
    ).

%! sentinel_domain_deactivate(+Domain) is det.
%  Suspend sentinel evaluation in Domain.
% Define a clause for 'sentinel domain deactivate': succeed when the following conditions hold.
sentinel_domain_deactivate(Domain) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_sentinel_domain_active(Domain)).
