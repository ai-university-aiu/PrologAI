/*  PrologAI — Global Workspace Cycle  (Specification PR 18)

    Implements the Global Workspace Theory pattern (Baars, as realized in
    Franklin's LIDA): many parallel processes, one spotlight, one broadcast
    per cognitive cycle, with learning attached to the broadcast.

    Key predicates:

    pai_coalition_form/3   — build coalitions from live node_facts with salience
    pai_salience/2         — compute salience for a coalition
    pai_pin_item/2         — top-down pin an item into candidacy
    pai_broadcast_subscribe/1 — subscribe an actor to the broadcast channel
    workspace_cycle/0      — run one cognitive cycle (200 ms cadence by default)
    install_workspace_actor/0  — start the attention_arbiter_actor
    uninstall_workspace_actor/0

    Salience = novelty + goal_relevance + affect − habituation

    Broadcast channel: broadcast://APEX_MIND/cycle (via pubsub)

    Two experience scopes (standing inputs):
      internal_experience — mind's own derivations, appraisals, self-events
      overall_experience  — merged stream including external percepts
*/

:- module(workspace, [
    pai_coalition_form/3,         % +Nexus, +K, -Coalitions (list of coalition terms)
    pai_salience/2,               % +CoalitionId, -Score
    pai_pin_item/2,               % +CoalitionId, +Priority
    pai_broadcast_subscribe/1,    % +ActorGoal  (called each cycle with broadcast content)
    workspace_cycle/0,
    install_workspace_actor/0,
    uninstall_workspace_actor/0
]).

:- use_module(library(node_facts),  [live_node_facts/2, kindle_node/1,
                                     default_nexus/1]).
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
:- use_module(library(pubsub),      [publish/2]).
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
:- use_module(library(lists),       [member/2, last/2]).
:- use_module(library(apply),       [maplist/3]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic coalition_salience/2.      % CoalitionId, Score
:- dynamic coalition_content/2.       % CoalitionId, Content (list of node_fact Ids)
:- dynamic coalition_broadcast_count/2.% CoalitionId, Count  (for habituation)
:- dynamic pinned_item/2.             % CoalitionId, Priority (top-down pin)
:- dynamic broadcast_subscriber/1.    % Goal (called each cycle)
:- dynamic salience_floor/1.
salience_floor(0.3).

:- dynamic coalition_id_counter/1.
coalition_id_counter(0).

next_coalition_id(Id) :-
    retract(coalition_id_counter(N)),
    N1 is N + 1,
    assertz(coalition_id_counter(N1)),
    atomic_list_concat([coalition_, N1], Id).

% ---------------------------------------------------------------------------
% Experience scopes (standing input buffers)
% ---------------------------------------------------------------------------

ensure_experience_scopes :-
    catch(
        ( use_module(library(scopes), [scope_open/2]),
          scopes:scope_open(internal_experience, present_zone),
          scopes:scope_open(overall_experience,  present_zone)
        ),
        _, true
    ).

:- initialization(ensure_experience_scopes, now).

% ---------------------------------------------------------------------------
% pai_coalition_form/3
%
%   Build coalitions from the current live node_facts in Nexus.
%   Each coalition is a group of thematically related live facts.
%   Returns list of coalition(Id, Content, Salience) terms, sorted
%   descending by salience.
%
%   K: maximum number of coalitions to return.
% ---------------------------------------------------------------------------

pai_coalition_form(Nexus, K, Coalitions) :-
    nexus_is_open(Nexus),
    live_node_facts(Nexus, LiveIds),
    ( LiveIds = []
    ->  Coalitions = []
    ;   group_into_coalitions(Nexus, LiveIds, RawCoalitions),
        maplist(score_coalition(Nexus), RawCoalitions, ScoredCoalitions),
        msort(ScoredCoalitions, Asc),
        reverse(Asc, Desc),
        take_k(K, Desc, Coalitions)
    ).

group_into_coalitions(Nexus, Ids, Coalitions) :-
    % Simple grouping by relation type
    findall(Relation, (
        member(Id, Ids),
        lattice:lattice_node_fact(Nexus, Id, Relation, _, _)
    ), AllRels),
    sort(AllRels, UniqueRels),
    findall(Coalition, (
        member(Relation, UniqueRels),
        findall(Id, (
            member(Id, Ids),
            lattice:lattice_node_fact(Nexus, Id, Relation, _, _)
        ), RelIds),
        RelIds \= [],
        next_coalition_id(CId),
        retractall(coalition_content(CId, _)),
        assertz(coalition_content(CId, RelIds)),
        Coalition = coalition(CId, Relation, RelIds)
    ), Coalitions).

score_coalition(Nexus, coalition(CId, Relation, Ids),
                Salience-coalition(CId, Relation, Ids)) :-
    compute_salience(Nexus, CId, Relation, Ids, Salience),
    retractall(coalition_salience(CId, _)),
    assertz(coalition_salience(CId, Salience)).

compute_salience(Nexus, CId, _Relation, Ids, Salience) :-
    % novelty: how recently inscribed (newer = more novel)
    novelty_score(Ids, NoveltyS),
    % goal relevance: how many Ids match a current objective
    goal_relevance_score(Nexus, Ids, GoalS),
    % affect: presence of emotion stamps
    affect_score(Nexus, Ids, AffectS),
    % habituation: decay for repeatedly broadcast content
    habituation_penalty(CId, HabitPenalty),
    % top-down pin boost
    pin_boost(CId, PinBoost),
    RawS is NoveltyS * 0.4 + GoalS * 0.3 + AffectS * 0.2 - HabitPenalty + PinBoost,
    Salience is max(0.0, min(1.0, RawS)).

novelty_score(Ids, Score) :-
    length(Ids, N),
    ( N > 0
    ->  get_time(Now),
        aggregate_all(bag(Age), (
            member(Id, Ids),
            ( node_facts:node_activation(Id, T, _)
            ->  Age is Now - T
            ;   Age = 3600.0
            )
        ), Ages),
        sumlist(Ages, TotalAge),
        MeanAge is TotalAge / N,
        Score is max(0.0, 1.0 - MeanAge / 3600.0)
    ;   Score = 0.0
    ).

sumlist([], 0.0).
sumlist([H|T], S) :- sumlist(T, S1), S is S1 + H.

goal_relevance_score(Nexus, Ids, Score) :-
    ( catch(
          aggregate_all(count, (
              member(Id, Ids),
              lattice:lattice_node_fact(Nexus, Id, objective, _, _)
          ), Matches),
          _, Matches = 0 ),
      length(Ids, Total),
      ( Total > 0 -> Score is Matches / Total ; Score = 0.0 )
    ).

affect_score(Nexus, Ids, Score) :-
    ( catch(
          aggregate_all(count, (
              member(Id, Ids),
              lattice:lattice_node_fact(Nexus, Id, emotion, _, _)
          ), ECount),
          _, ECount = 0 ),
      length(Ids, Total),
      ( Total > 0 -> Score is ECount / Total ; Score = 0.0 )
    ).

habituation_penalty(CId, Penalty) :-
    ( coalition_broadcast_count(CId, Count)
    ->  Penalty is min(0.5, Count * 0.1)
    ;   Penalty = 0.0
    ).

pin_boost(CId, Boost) :-
    ( pinned_item(CId, Priority)
    ->  Boost is Priority / 200.0  % normalise to 0–0.5 range for priority 0–100
    ;   Boost = 0.0
    ).

take_k(K, List, Result) :-
    length(List, N),
    Take is min(K, N),
    length(Result, Take),
    append(Result, _, List).

% ---------------------------------------------------------------------------
% pai_salience/2 — query the salience of a coalition by Id
% ---------------------------------------------------------------------------

pai_salience(CoalitionId, Score) :-
    ( coalition_salience(CoalitionId, Score)
    ->  true
    ;   Score = 0.0
    ).

% ---------------------------------------------------------------------------
% pai_pin_item/2 — top-down pin a coalition into candidacy
% ---------------------------------------------------------------------------

pai_pin_item(CoalitionId, Priority) :-
    retractall(pinned_item(CoalitionId, _)),
    assertz(pinned_item(CoalitionId, Priority)).

% ---------------------------------------------------------------------------
% pai_broadcast_subscribe/1 — subscribe a goal to receive broadcast content
% ---------------------------------------------------------------------------

pai_broadcast_subscribe(Goal) :-
    ( broadcast_subscriber(Goal)
    ->  true
    ;   assertz(broadcast_subscriber(Goal))
    ).

% ---------------------------------------------------------------------------
% workspace_cycle/0 — one cognitive cycle
%
%   1. Collect coalitions with salience scores
%   2. Select winner (highest salience above floor, with bottom-up capture)
%   3. Broadcast winner on broadcast://APEX_MIND/cycle
%   4. Kindle winner's content across zones
%   5. Attach learning: sona_absorb
%   6. Habituate winner
%   7. Decay salience floor if no winner
% ---------------------------------------------------------------------------

workspace_cycle :-
    ( catch(default_nexus(Nexus), _, fail),
      nexus_is_open(Nexus)
    ->  pai_coalition_form(Nexus, 10, Coalitions),
        ( Coalitions = []
        ->  decay_salience_floor
        ;   select_winner(Nexus, Coalitions, Winner),
            ( Winner = none
            ->  decay_salience_floor
            ;   Winner = Salience-coalition(CId, Relation, Ids),
                broadcast_winner(Salience, CId, Relation, Ids),
                kindle_coalition(Ids),
                attach_learning(CId, Relation, Ids),
                habituate(CId)
            )
        )
    ;   true
    ).

select_winner(_Nexus, Coalitions, Winner) :-
    salience_floor(Floor),
    % Check for bottom-up urgent percept
    ( catch(
          find_urgent_percept(Coalitions, UrgentWinner),
          _, fail
      )
    ->  Winner = UrgentWinner
    ;   % Normal: pick highest salience above floor
        Coalitions = [Best|_],
        Best = Score-_,
        ( Score >= Floor
        ->  Winner = Best
        ;   Winner = none
        )
    ).

find_urgent_percept(Coalitions, Winner) :-
    member(Score-coalition(CId, percept_urgent, Ids), Coalitions),
    !,
    Winner = Score-coalition(CId, percept_urgent, Ids).

broadcast_winner(Salience, CId, Relation, Ids) :-
    Content = broadcast_content(CId, Relation, Ids, Salience),
    catch(publish('broadcast://APEX_MIND/cycle', Content), _, true),
    % Notify subscribers
    forall(
        broadcast_subscriber(Goal),
        catch(call(Goal, Content), _, true)
    ).

kindle_coalition(Ids) :-
    forall(
        member(Id, Ids),
        catch(kindle_node(Id), _, true)
    ).

attach_learning(CId, Relation, Ids) :-
    catch(
        ( use_module(library(sona), [sona_absorb/1]),
          get_time(T),
          sona:sona_absorb(trajectory(CId, [broadcast, Relation, Ids],
                                       broadcast_cycle, 0.5, T))
        ),
        _, true
    ).

habituate(CId) :-
    ( coalition_broadcast_count(CId, Count)
    ->  retract(coalition_broadcast_count(CId, Count)),
        Count1 is Count + 1,
        assertz(coalition_broadcast_count(CId, Count1))
    ;   assertz(coalition_broadcast_count(CId, 1))
    ),
    % Update the salience with habituation penalty applied
    ( coalition_content(CId, Ids)
    ->  catch(
            ( default_nexus(Nexus),
              score_coalition(Nexus, coalition(CId, habituated, Ids), _)
            ),
            _, true
        )
    ;   true
    ).

decay_salience_floor :-
    salience_floor(CurrentFloor),
    ( CurrentFloor > 0.05
    ->  NewFloor is CurrentFloor * 0.9,
        retract(salience_floor(CurrentFloor)),
        assertz(salience_floor(NewFloor))
    ;   true
    ).

% ---------------------------------------------------------------------------
% Workspace actor management
% ---------------------------------------------------------------------------

install_workspace_actor :-
    catch(
        cyclic_actor(attention_arbiter_actor, workspace:workspace_cycle, 200),
        _, true
    ).

uninstall_workspace_actor :-
    catch(cyclic_actor_stop(attention_arbiter_actor), _, true).
