/*  PrologAI — Sentinel Engine  (Specification Section 3.5, PR 9)

    Wires sentinel evaluation into anchor_node/4 via the post_anchor_node_hook
    multifile predicate defined in node_facts.pl.

    Evaluation phases:
      Phase 1 — logical unification of Change against each sentinel's Pattern.
      Phase 2 — semantic similarity via hash_project + cosine_similarity (>= 0.75).

    Firing order follows Priority descending; higher priority fires first.
    When a sentinel fires: Objectives are kindled, Action is called, and a
    sentinel_fired event is published on sentinel://fired.
*/

:- module(sentinel_engine, [
    evaluate_sentinels/5,        % +Nexus, +Id, +Relation, +Args, +Referents
    sentinel_fire_threshold/1    % -Threshold (default 0.75)
]).

:- use_module(library(sentinels),      [pai_sentinel_entry/6,
                                        pai_sentinel_domain_active/1]).
:- use_module(library(node_facts),     [kindle_node/1]).
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
:- use_module(library(lists),          [member/2]).

% ---------------------------------------------------------------------------
% Default similarity threshold
% ---------------------------------------------------------------------------

:- dynamic sentinel_sim_threshold/1.
sentinel_sim_threshold(0.75).

sentinel_fire_threshold(T) :- sentinel_sim_threshold(T).

% ---------------------------------------------------------------------------
% Hook into anchor_node — multifile clause in node_facts module
% ---------------------------------------------------------------------------

:- multifile node_facts:post_anchor_node_hook/5.

node_facts:post_anchor_node_hook(Nexus, Id, Relation, Args, Referents) :-
    evaluate_sentinels(Nexus, Id, Relation, Args, Referents).

% ---------------------------------------------------------------------------
% evaluate_sentinels/5
% ---------------------------------------------------------------------------

evaluate_sentinels(Nexus, Id, Relation, Args, Referents) :-
    Change = node_fact(Id, Relation, Args, Referents),
    % Collect all sentinels from active domains, sorted by priority desc
    findall(Priority-Domain-Pattern-Objectives-Action, (
        pai_sentinel_entry(Domain, Priority, Pattern, Objectives, Action, _),
        pai_sentinel_domain_active(Domain)
    ), Raw),
    msort(Raw, Asc),
    reverse(Asc, ByPriority),
    evaluate_ordered(Nexus, Change, ByPriority).

evaluate_ordered(_, _, []).
evaluate_ordered(Nexus, Change, [_-_-Pattern-Objectives-Action | Rest]) :-
    ( matches_sentinel(Change, Pattern)
    ->  fire_sentinel(Nexus, Change, Objectives, Action)
    ;   true
    ),
    evaluate_ordered(Nexus, Change, Rest).

% ---------------------------------------------------------------------------
% Phase 1 — logical unification (non-destructive via \+\+)
% Phase 2 — semantic similarity
% ---------------------------------------------------------------------------

matches_sentinel(Change, Pattern) :-
    \+ \+ Change = Pattern.      % Phase 1: logical unification
matches_sentinel(Change, Pattern) :-
    sentinel_sim_threshold(Thresh),
    term_to_atom(Change, CA),
    term_to_atom(Pattern, PA),
    hash_project(CA, 32, VC),
    hash_project(PA, 32, VP),
    cosine_similarity(VC, VP, Score),
    Score >= Thresh.             % Phase 2: semantic similarity

% ---------------------------------------------------------------------------
% fire_sentinel/4
% ---------------------------------------------------------------------------

fire_sentinel(_Nexus, Change, Objectives, Action) :-
    % Kindle each objective node
    maplist_safe(kindle_node, Objectives),
    % Execute the sentinel's action
    catch(call(Action), Err,
        print_message(warning,
            format("sentinel action error: ~w on change ~w", [Err, Change]))
    ),
    % Publish sentinel_fired event (non-fatal if pubsub not loaded)
    catch(
        pubsub:publish('sentinel://fired', Change),
        _,
        true
    ).

maplist_safe(_, []).
maplist_safe(Goal, [H|T]) :-
    catch(call(Goal, H), _, true),
    maplist_safe(Goal, T).
