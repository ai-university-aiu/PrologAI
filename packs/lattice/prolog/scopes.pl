/*  PrologAI — Scopes and Zones  (Specification Section 3.4, PR 5)

    Nine zone types, five activation sweep actors, and the six scope predicates.

    Zones and their activation flow directions:
      present_zone   — upward    (percepts → concepts)
      possible_zone  — upward    (mental simulation, hypothesis)
      past_zone      — none      (read-only after sealing)
      desired_zone   — downward  (goals → actions)
      expected_zone  — downward  (predictions → actions)
      imagined_zone  — upward    (free construction)
      recalled_zone  — radial    (spreads to neighbors)
      attained_zone  — none      (achieved objectives, sealed)
      confirmed_zone — none      (expectations verified vs observation)

    Invariant: activation NEVER propagates from present_zone to possible_zone
    except through an explicit scope_merge or deliberate inscription.
*/

% Declare this file as the 'scopes' module and list its exported predicates.
:- module(scopes, [
    % Continue the multi-line expression started above.
    scope_open/2,        % +ScopeName, +Zone
    % Continue the multi-line expression started above.
    scope_activate/1,    % +ScopeName
    % Continue the multi-line expression started above.
    scope_inscribe/5,    % +ScopeName, +Relation, +Args, +Referents, -Id
    % Continue the multi-line expression started above.
    scope_scan/5,        % +ScopeName, +Pattern, +K, +Options, -Results
    % Continue the multi-line expression started above.
    scope_seal/1,        % +ScopeName
    % Continue the multi-line expression started above.
    scope_merge/3,       % +FromScope, +ToScope, +Options
    % Continue the multi-line expression started above.
    current_scope/1,     % -ScopeName
    % Continue the multi-line expression started above.
    scope_zone/2,        % +ScopeName, -Zone
    % Continue the multi-line expression started above.
    valid_zone/1         % +Zone
% Close the expression opened above.
]).

% Import [lattice_node_fact/5, nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5, nexus_is_open/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [anchor_node/4, traverse_nexus/4,
                                    % Continue the multi-line expression started above.
                                    set_default_nexus/1, default_nexus/1]).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, memberchk/2]).
% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply),      [maplist/2]).

% ---------------------------------------------------------------------------
% Zone definitions
% ---------------------------------------------------------------------------

% State the fact: zone flow(present_zone,   upward).
zone_flow(present_zone,   upward).
% State the fact: zone flow(possible_zone,  upward).
zone_flow(possible_zone,  upward).
% State the fact: zone flow(past_zone,      none).
zone_flow(past_zone,      none).
% State the fact: zone flow(desired_zone,   downward).
zone_flow(desired_zone,   downward).
% State the fact: zone flow(expected_zone,  downward).
zone_flow(expected_zone,  downward).
% State the fact: zone flow(imagined_zone,  upward).
zone_flow(imagined_zone,  upward).
% State the fact: zone flow(recalled_zone,  radial).
zone_flow(recalled_zone,  radial).
% State the fact: zone flow(attained_zone,  none).
zone_flow(attained_zone,  none).
% State the fact: zone flow(confirmed_zone, none).
zone_flow(confirmed_zone, none).

% Define a clause for 'valid zone': succeed when the following conditions hold.
valid_zone(Z) :- zone_flow(Z, _).

% ---------------------------------------------------------------------------
% Scope registry
% ---------------------------------------------------------------------------

% Declare 'scope_entry/3.       % ScopeName, Zone, sealed(true|false)' as dynamic — its facts may be added or removed at runtime.
:- dynamic scope_entry/3.       % ScopeName, Zone, sealed(true|false)
% Declare 'scope_node/3.        % ScopeName, Id, Relation' as dynamic — its facts may be added or removed at runtime.
:- dynamic scope_node/3.        % ScopeName, Id, Relation
% Declare 'current_scope_name/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic current_scope_name/1.

% ---------------------------------------------------------------------------
% scope_open/2
% ---------------------------------------------------------------------------

% Define a clause for 'scope open': succeed when the following conditions hold.
scope_open(ScopeName, Zone) :-
    % Execute: ( valid_zone(Zone).
    ( valid_zone(Zone)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(domain_error(zone, Zone), scope_open/2))
    % Close the expression opened above.
    ),
    % Execute: ( scope_entry(ScopeName, _, _).
    ( scope_entry(ScopeName, _, _)
    % If the condition above succeeded, perform the following action.
    ->  true    % already open; idempotent
    % Otherwise (else branch), perform the following action.
    ;   assertz(scope_entry(ScopeName, Zone, false))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% scope_activate/1
% ---------------------------------------------------------------------------

% Define a clause for 'scope activate': succeed when the following conditions hold.
scope_activate(ScopeName) :-
    % Execute: ( scope_entry(ScopeName, _, _).
    ( scope_entry(ScopeName, _, _)
    % If the condition above succeeded, perform the following action.
    ->  retractall(current_scope_name(_)),
        % Continue the multi-line expression started above.
        assertz(current_scope_name(ScopeName))
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(scope, ScopeName), scope_activate/1))
    % Close the expression opened above.
    ).

% Define a clause for 'current scope': succeed when the following conditions hold.
current_scope(ScopeName) :-
    % Execute: ( current_scope_name(ScopeName).
    ( current_scope_name(ScopeName)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(current_scope, none), current_scope/1))
    % Close the expression opened above.
    ).

% Define a clause for 'scope zone': succeed when the following conditions hold.
scope_zone(ScopeName, Zone) :-
    % State the fact: scope entry(ScopeName, Zone, _).
    scope_entry(ScopeName, Zone, _).

% ---------------------------------------------------------------------------
% scope_inscribe/5  — store a node_fact in a specific scope
% ---------------------------------------------------------------------------

% Define a clause for 'scope inscribe': succeed when the following conditions hold.
scope_inscribe(ScopeName, Relation, Args, Referents, Id) :-
    % State a fact for 'scope entry' with the arguments listed below.
    scope_entry(ScopeName, _Zone, Sealed),
    % Check that '( Sealed' is structurally identical to 'true'.
    ( Sealed == true
    % If the condition above succeeded, perform the following action.
    ->  throw(error(permission_error(inscribe, sealed_scope, ScopeName),
                    % Supply 'scope_inscribe/5' as the next argument to the expression above.
                    scope_inscribe/5))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(Relation, Args, Referents, Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(scope_node(ScopeName, Id, Relation)).

% ---------------------------------------------------------------------------
% scope_scan/5  — search only within a specific scope
% ---------------------------------------------------------------------------

% Define a clause for 'scope scan': succeed when the following conditions hold.
scope_scan(ScopeName, Pattern, K, _Options, Results) :-
    % State a fact for 'scope entry' with the arguments listed below.
    scope_entry(ScopeName, _, _),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, scope_node(ScopeName, Id, _), ScopeIds),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nexus),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-Id, (
        % Continue the multi-line expression started above.
        member(Id, ScopeIds),
        % Continue the multi-line expression started above.
        lattice_node_fact(Nexus, Id, Rel, Args, Refs),
        % Continue the multi-line expression started above.
        ( node_fact(Rel, Args, Refs) = Pattern
        % If the condition above succeeded, perform the following action.
        ->  Score = 1.0
        % Otherwise (else branch), perform the following action.
        ;   Score = 0.0
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        Score > 0.0
    % Continue the multi-line expression started above.
    ), Scored),
    % Sort list 'Scored' into 'Asc', keeping duplicates.
    msort(Scored, Asc),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Asc, Desc),
    % State the fact: take k(K, Desc, Results).
    take_k(K, Desc, Results).

% Define a clause for 'take k': succeed when the following conditions hold.
take_k(K, List, Result) :-
    % Unify 'N' with the number of elements in list 'List'.
    length(List, N),
    % Evaluate the arithmetic expression 'min(K, N)' and bind the result to 'Take'.
    Take is min(K, N),
    % Unify 'Take' with the number of elements in list 'Result'.
    length(Result, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(Result, _, List).

% ---------------------------------------------------------------------------
% scope_seal/1  — make a scope read-only
% ---------------------------------------------------------------------------

% Define a clause for 'scope seal': succeed when the following conditions hold.
scope_seal(ScopeName) :-
    % Execute: ( retract(scope_entry(ScopeName, Zone, _)).
    ( retract(scope_entry(ScopeName, Zone, _))
    % If the condition above succeeded, perform the following action.
    ->  assertz(scope_entry(ScopeName, Zone, true))
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(scope, ScopeName), scope_seal/1))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% scope_merge/3  — copy node_facts from one scope to another
%
%  Invariant: merging FROM possible_zone INTO present_zone is allowed
%  (that is the deliberate crossing that requires scope_merge).
%  Merging FROM present_zone INTO possible_zone is blocked.
% ---------------------------------------------------------------------------

% Define a clause for 'scope merge': succeed when the following conditions hold.
scope_merge(FromScope, ToScope, _Options) :-
    % State a fact for 'scope entry' with the arguments listed below.
    scope_entry(FromScope, FromZone, _),
    % State a fact for 'scope entry' with the arguments listed below.
    scope_entry(ToScope, ToZone, ToSealed),
    % State a fact for 'check merge direction' with the arguments listed below.
    check_merge_direction(FromZone, ToZone),
    % Check that '( ToSealed' is structurally identical to 'true'.
    ( ToSealed == true
    % If the condition above succeeded, perform the following action.
    ->  throw(error(permission_error(merge_into, sealed_scope, ToScope),
                    % Supply 'scope_merge/3' as the next argument to the expression above.
                    scope_merge/3))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, scope_node(FromScope, Id, _), Ids),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nexus),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([Id]>>(
        % Continue the multi-line expression started above.
        ( lattice_node_fact(Nexus, Id, Rel, Args, Refs)
        % If the condition above succeeded, perform the following action.
        ->  scope_inscribe(ToScope, Rel, Args, Refs, _)
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Ids).

% Define a clause for 'check merge direction': succeed when the following conditions hold.
check_merge_direction(present_zone, possible_zone) :-
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % State a fact for 'throw' with the arguments listed below.
    throw(error(permission_error(merge, present_to_possible, scope_merge/3),
                % Supply 'scope_merge/3' as the next argument to the expression above.
                scope_merge/3)).
% State the fact: check merge direction(_, _).
check_merge_direction(_, _).
