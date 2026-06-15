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

:- module(scopes, [
    scope_open/2,        % +ScopeName, +Zone
    scope_activate/1,    % +ScopeName
    scope_inscribe/5,    % +ScopeName, +Relation, +Args, +Referents, -Id
    scope_scan/5,        % +ScopeName, +Pattern, +K, +Options, -Results
    scope_seal/1,        % +ScopeName
    scope_merge/3,       % +FromScope, +ToScope, +Options
    current_scope/1,     % -ScopeName
    scope_zone/2,        % +ScopeName, -Zone
    valid_zone/1         % +Zone
]).

:- use_module(library(lattice),    [lattice_node_fact/5, nexus_is_open/1]).
:- use_module(library(node_facts), [anchor_node/4, traverse_nexus/4,
                                    set_default_nexus/1, default_nexus/1]).
:- use_module(library(lists),      [member/2, memberchk/2]).
:- use_module(library(apply),      [maplist/2]).

% ---------------------------------------------------------------------------
% Zone definitions
% ---------------------------------------------------------------------------

zone_flow(present_zone,   upward).
zone_flow(possible_zone,  upward).
zone_flow(past_zone,      none).
zone_flow(desired_zone,   downward).
zone_flow(expected_zone,  downward).
zone_flow(imagined_zone,  upward).
zone_flow(recalled_zone,  radial).
zone_flow(attained_zone,  none).
zone_flow(confirmed_zone, none).

valid_zone(Z) :- zone_flow(Z, _).

% ---------------------------------------------------------------------------
% Scope registry
% ---------------------------------------------------------------------------

:- dynamic scope_entry/3.       % ScopeName, Zone, sealed(true|false)
:- dynamic scope_node/3.        % ScopeName, Id, Relation
:- dynamic current_scope_name/1.

% ---------------------------------------------------------------------------
% scope_open/2
% ---------------------------------------------------------------------------

scope_open(ScopeName, Zone) :-
    ( valid_zone(Zone)
    ->  true
    ;   throw(error(domain_error(zone, Zone), scope_open/2))
    ),
    ( scope_entry(ScopeName, _, _)
    ->  true    % already open; idempotent
    ;   assertz(scope_entry(ScopeName, Zone, false))
    ).

% ---------------------------------------------------------------------------
% scope_activate/1
% ---------------------------------------------------------------------------

scope_activate(ScopeName) :-
    ( scope_entry(ScopeName, _, _)
    ->  retractall(current_scope_name(_)),
        assertz(current_scope_name(ScopeName))
    ;   throw(error(existence_error(scope, ScopeName), scope_activate/1))
    ).

current_scope(ScopeName) :-
    ( current_scope_name(ScopeName)
    ->  true
    ;   throw(error(existence_error(current_scope, none), current_scope/1))
    ).

scope_zone(ScopeName, Zone) :-
    scope_entry(ScopeName, Zone, _).

% ---------------------------------------------------------------------------
% scope_inscribe/5  — store a node_fact in a specific scope
% ---------------------------------------------------------------------------

scope_inscribe(ScopeName, Relation, Args, Referents, Id) :-
    scope_entry(ScopeName, _Zone, Sealed),
    ( Sealed == true
    ->  throw(error(permission_error(inscribe, sealed_scope, ScopeName),
                    scope_inscribe/5))
    ;   true
    ),
    anchor_node(Relation, Args, Referents, Id),
    assertz(scope_node(ScopeName, Id, Relation)).

% ---------------------------------------------------------------------------
% scope_scan/5  — search only within a specific scope
% ---------------------------------------------------------------------------

scope_scan(ScopeName, Pattern, K, _Options, Results) :-
    scope_entry(ScopeName, _, _),
    findall(Id, scope_node(ScopeName, Id, _), ScopeIds),
    default_nexus(Nexus),
    findall(Score-Id, (
        member(Id, ScopeIds),
        lattice_node_fact(Nexus, Id, Rel, Args, Refs),
        ( node_fact(Rel, Args, Refs) = Pattern
        ->  Score = 1.0
        ;   Score = 0.0
        ),
        Score > 0.0
    ), Scored),
    msort(Scored, Asc),
    reverse(Asc, Desc),
    take_k(K, Desc, Results).

take_k(K, List, Result) :-
    length(List, N),
    Take is min(K, N),
    length(Result, Take),
    append(Result, _, List).

% ---------------------------------------------------------------------------
% scope_seal/1  — make a scope read-only
% ---------------------------------------------------------------------------

scope_seal(ScopeName) :-
    ( retract(scope_entry(ScopeName, Zone, _))
    ->  assertz(scope_entry(ScopeName, Zone, true))
    ;   throw(error(existence_error(scope, ScopeName), scope_seal/1))
    ).

% ---------------------------------------------------------------------------
% scope_merge/3  — copy node_facts from one scope to another
%
%  Invariant: merging FROM possible_zone INTO present_zone is allowed
%  (that is the deliberate crossing that requires scope_merge).
%  Merging FROM present_zone INTO possible_zone is blocked.
% ---------------------------------------------------------------------------

scope_merge(FromScope, ToScope, _Options) :-
    scope_entry(FromScope, FromZone, _),
    scope_entry(ToScope, ToZone, ToSealed),
    check_merge_direction(FromZone, ToZone),
    ( ToSealed == true
    ->  throw(error(permission_error(merge_into, sealed_scope, ToScope),
                    scope_merge/3))
    ;   true
    ),
    findall(Id, scope_node(FromScope, Id, _), Ids),
    default_nexus(Nexus),
    maplist([Id]>>(
        ( lattice_node_fact(Nexus, Id, Rel, Args, Refs)
        ->  scope_inscribe(ToScope, Rel, Args, Refs, _)
        ;   true
        )
    ), Ids).

check_merge_direction(present_zone, possible_zone) :-
    !,
    throw(error(permission_error(merge, present_to_possible, scope_merge/3),
                scope_merge/3)).
check_merge_direction(_, _).
