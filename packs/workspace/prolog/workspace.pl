/*  PrologAI — Global Workspace Cycle  (Specification PR 18)

    Implements the Global Workspace Theory pattern (Baars, as realized in
    Franklin's LIDA): many parallel processes, one spotlight, one broadcast
    per cognitive cycle, with learning attached to the broadcast.

    Key predicates:

    workspace_coalition_form/3   — build coalitions from live node_facts with salience
    workspace_salience/2         — compute salience for a coalition
    workspace_pin_item/2         — top-down pin an item into candidacy
    workspace_broadcast_subscribe/1 — subscribe an actor to the broadcast channel
    workspace_cycle/0      — run one cognitive cycle (200 ms cadence by default)
    install_workspace_actor/0  — start the attention_arbiter_actor
    uninstall_workspace_actor/0

    Salience = novelty + goal_relevance + affect − habituation

    Broadcast channel: broadcast://APEX_MIND/cycle (via pubsub)

    Two experience scopes (standing inputs):
      internal_experience — mind's own derivations, appraisals, self-events
      overall_experience  — merged stream including external percepts
*/

% Declare this file as the 'workspace' module and list its exported predicates.
:- module(workspace, [
    % Continue the multi-line expression started above.
    workspace_coalition_form/3,         % +Nexus, +K, -Coalitions (list of coalition terms)
    % Continue the multi-line expression started above.
    workspace_salience/2,               % +CoalitionId, -Score
    % Continue the multi-line expression started above.
    workspace_pin_item/2,               % +CoalitionId, +Priority
    % Continue the multi-line expression started above.
    workspace_broadcast_subscribe/1,    % +ActorGoal  (called each cycle with broadcast content)
    % Supply 'workspace_cycle/0' as the next argument to the expression above.
    workspace_cycle/0,
    % Supply 'install_workspace_actor/0' as the next argument to the expression above.
    install_workspace_actor/0,
    % Supply 'uninstall_workspace_actor/0' as the next argument to the expression above.
    uninstall_workspace_actor/0
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [live_node_facts/2, kindle_node/1,
                                     % Continue the multi-line expression started above.
                                     default_nexus/1]).
% Import [lattice_node_fact/5, nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
% Import [publish/2] from the built-in 'pubsub' library.
:- use_module(library(pubsub),      [publish/2]).
% Import [cyclic_actor/3, cyclic_actor_stop/1] from the built-in 'cyclic_actor' library.
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
% Import [member/2, last/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2, last/2]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),       [maplist/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'coalition_salience/2.      % CoalitionId, Score' as dynamic — its facts may be added or removed at runtime.
:- dynamic coalition_salience/2.      % CoalitionId, Score
% Declare 'coalition_content/2.       % CoalitionId, Content (list of node_fact Ids)' as dynamic — its facts may be added or removed at runtime.
:- dynamic coalition_content/2.       % CoalitionId, Content (list of node_fact Ids)
% Declare 'coalition_broadcast_count/2.% CoalitionId, Count  (for habituation)' as dynamic — its facts may be added or removed at runtime.
:- dynamic coalition_broadcast_count/2.% CoalitionId, Count  (for habituation)
% Declare 'pinned_item/2.             % CoalitionId, Priority (top-down pin)' as dynamic — its facts may be added or removed at runtime.
:- dynamic pinned_item/2.             % CoalitionId, Priority (top-down pin)
% Declare 'broadcast_subscriber/1.    % Goal (called each cycle)' as dynamic — its facts may be added or removed at runtime.
:- dynamic broadcast_subscriber/1.    % Goal (called each cycle)
% Declare 'salience_floor/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic salience_floor/1.
% State the fact: salience floor(0.3).
salience_floor(0.3).

% Declare 'coalition_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic coalition_id_counter/1.
% State the fact: coalition id counter(0).
coalition_id_counter(0).

% Define a clause for 'next coalition id': succeed when the following conditions hold.
next_coalition_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(coalition_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(coalition_id_counter(N1)),
    % State the fact: atomic list concat([coalition_, N1], Id).
    atomic_list_concat([coalition_, N1], Id).

% ---------------------------------------------------------------------------
% Experience scopes (standing input buffers)
% ---------------------------------------------------------------------------

% Execute: ensure_experience_scopes :-.
ensure_experience_scopes :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( use_module(library(scopes), [scope_open/2]),
          % Continue the multi-line expression started above.
          scopes:scope_open(internal_experience, present_zone),
          % Continue the multi-line expression started above.
          scopes:scope_open(overall_experience,  present_zone)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Register the following goal to run automatically at load time.
:- initialization(ensure_experience_scopes, now).

% ---------------------------------------------------------------------------
% workspace_coalition_form/3
%
%   Build coalitions from the current live node_facts in Nexus.
%   Each coalition is a group of thematically related live facts.
%   Returns list of coalition(Id, Content, Salience) terms, sorted
%   descending by salience.
%
%   K: maximum number of coalitions to return.
% ---------------------------------------------------------------------------

% Define a clause for 'pai coalition form': succeed when the following conditions hold.
workspace_coalition_form(Nexus, K, Coalitions) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % State a fact for 'live node facts' with the arguments listed below.
    live_node_facts(Nexus, LiveIds),
    % Check that '( LiveIds' is unifiable with '[]'.
    ( LiveIds = []
    % If the condition above succeeded, perform the following action.
    ->  Coalitions = []
    % Otherwise (else branch), perform the following action.
    ;   group_into_coalitions(Nexus, LiveIds, RawCoalitions),
        % Continue the multi-line expression started above.
        maplist(score_coalition(Nexus), RawCoalitions, ScoredCoalitions),
        % Continue the multi-line expression started above.
        msort(ScoredCoalitions, Asc),
        % Continue the multi-line expression started above.
        reverse(Asc, Desc),
        % Continue the multi-line expression started above.
        take_k(K, Desc, Coalitions)
    % Close the expression opened above.
    ).

% Define a clause for 'group into coalitions': succeed when the following conditions hold.
group_into_coalitions(Nexus, Ids, Coalitions) :-
    % Simple grouping by relation type
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Relation, (
        % Continue the multi-line expression started above.
        member(Id, Ids),
        % Continue the multi-line expression started above.
        lattice:lattice_node_fact(Nexus, Id, Relation, _, _)
    % Continue the multi-line expression started above.
    ), AllRels),
    % Sort list 'AllRels' into 'UniqueRels', removing duplicates.
    sort(AllRels, UniqueRels),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Coalition, (
        % Continue the multi-line expression started above.
        member(Relation, UniqueRels),
        % Continue the multi-line expression started above.
        findall(Id, (
            % Continue the multi-line expression started above.
            member(Id, Ids),
            % Continue the multi-line expression started above.
            lattice:lattice_node_fact(Nexus, Id, Relation, _, _)
        % Continue the multi-line expression started above.
        ), RelIds),
        % Continue the multi-line expression started above.
        RelIds \= [],
        % Continue the multi-line expression started above.
        next_coalition_id(CId),
        % Continue the multi-line expression started above.
        retractall(coalition_content(CId, _)),
        % Continue the multi-line expression started above.
        assertz(coalition_content(CId, RelIds)),
        % Continue the multi-line expression started above.
        Coalition = coalition(CId, Relation, RelIds)
    % Continue the multi-line expression started above.
    ), Coalitions).

% State a fact for 'score coalition' with the arguments listed below.
score_coalition(Nexus, coalition(CId, Relation, Ids),
                % Continue the multi-line expression started above.
                Salience-coalition(CId, Relation, Ids)) :-
    % State a fact for 'compute salience' with the arguments listed below.
    compute_salience(Nexus, CId, Relation, Ids, Salience),
    % Remove all matching facts from the runtime knowledge base.
    retractall(coalition_salience(CId, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(coalition_salience(CId, Salience)).

% Define a clause for 'compute salience': succeed when the following conditions hold.
compute_salience(Nexus, CId, _Relation, Ids, Salience) :-
    % novelty: how recently inscribed (newer = more novel)
    % State a fact for 'novelty score' with the arguments listed below.
    novelty_score(Ids, NoveltyS),
    % goal relevance: how many Ids match a current objective
    % State a fact for 'goal relevance score' with the arguments listed below.
    goal_relevance_score(Nexus, Ids, GoalS),
    % affect: presence of emotion stamps
    % State a fact for 'affect score' with the arguments listed below.
    affect_score(Nexus, Ids, AffectS),
    % habituation: decay for repeatedly broadcast content
    % State a fact for 'habituation penalty' with the arguments listed below.
    habituation_penalty(CId, HabitPenalty),
    % top-down pin boost
    % State a fact for 'pin boost' with the arguments listed below.
    pin_boost(CId, PinBoost),
    % Evaluate the arithmetic expression 'NoveltyS * 0.4 + GoalS * 0.3 + AffectS * 0.2 - HabitPenalty + PinBoost' and bind the result to 'RawS'.
    RawS is NoveltyS * 0.4 + GoalS * 0.3 + AffectS * 0.2 - HabitPenalty + PinBoost,
    % Evaluate the arithmetic expression 'max(0.0, min(1.0, RawS))' and bind the result to 'Salience'.
    Salience is max(0.0, min(1.0, RawS)).

% Define a clause for 'novelty score': succeed when the following conditions hold.
novelty_score(Ids, Score) :-
    % Unify 'N' with the number of elements in list 'Ids'.
    length(Ids, N),
    % Check that '( N' is greater than '0'.
    ( N > 0
    % If the condition above succeeded, perform the following action.
    ->  get_time(Now),
        % Continue the multi-line expression started above.
        aggregate_all(bag(Age), (
            % Continue the multi-line expression started above.
            member(Id, Ids),
            % Continue the multi-line expression started above.
            ( node_facts:node_activation(Id, T, _)
            % If the condition above succeeded, perform the following action.
            ->  Age is Now - T
            % Otherwise (else branch), perform the following action.
            ;   Age = 3600.0
            % Close the expression opened above.
            )
        % Continue the multi-line expression started above.
        ), Ages),
        % Continue the multi-line expression started above.
        sumlist(Ages, TotalAge),
        % Continue the multi-line expression started above.
        MeanAge is TotalAge / N,
        % Continue the multi-line expression started above.
        Score is max(0.0, 1.0 - MeanAge / 3600.0)
    % Otherwise (else branch), perform the following action.
    ;   Score = 0.0
    % Close the expression opened above.
    ).

% State the fact: sumlist([], 0.0).
sumlist([], 0.0).
% Define a clause for 'sumlist': succeed when the following conditions hold.
sumlist([H|T], S) :- sumlist(T, S1), S is S1 + H.

% Define a clause for 'goal relevance score': succeed when the following conditions hold.
goal_relevance_score(Nexus, Ids, Score) :-
    % Execute: ( catch(.
    ( catch(
          % Continue the multi-line expression started above.
          aggregate_all(count, (
              % Continue the multi-line expression started above.
              member(Id, Ids),
              % Continue the multi-line expression started above.
              lattice:lattice_node_fact(Nexus, Id, objective, _, _)
          % Continue the multi-line expression started above.
          ), Matches),
          % Continue the multi-line expression started above.
          _, Matches = 0 ),
      % Continue the multi-line expression started above.
      length(Ids, Total),
      % Continue the multi-line expression started above.
      ( Total > 0 -> Score is Matches / Total ; Score = 0.0 )
    % Close the expression opened above.
    ).

% Define a clause for 'affect score': succeed when the following conditions hold.
affect_score(Nexus, Ids, Score) :-
    % Execute: ( catch(.
    ( catch(
          % Continue the multi-line expression started above.
          aggregate_all(count, (
              % Continue the multi-line expression started above.
              member(Id, Ids),
              % Continue the multi-line expression started above.
              lattice:lattice_node_fact(Nexus, Id, emotion, _, _)
          % Continue the multi-line expression started above.
          ), ECount),
          % Continue the multi-line expression started above.
          _, ECount = 0 ),
      % Continue the multi-line expression started above.
      length(Ids, Total),
      % Continue the multi-line expression started above.
      ( Total > 0 -> Score is ECount / Total ; Score = 0.0 )
    % Close the expression opened above.
    ).

% Define a clause for 'habituation penalty': succeed when the following conditions hold.
habituation_penalty(CId, Penalty) :-
    % Execute: ( coalition_broadcast_count(CId, Count).
    ( coalition_broadcast_count(CId, Count)
    % If the condition above succeeded, perform the following action.
    ->  Penalty is min(0.5, Count * 0.1)
    % Otherwise (else branch), perform the following action.
    ;   Penalty = 0.0
    % Close the expression opened above.
    ).

% Define a clause for 'pin boost': succeed when the following conditions hold.
pin_boost(CId, Boost) :-
    % Execute: ( pinned_item(CId, Priority).
    ( pinned_item(CId, Priority)
    % If the condition above succeeded, perform the following action.
    ->  Boost is Priority / 200.0  % normalise to 0–0.5 range for priority 0–100
    % Otherwise (else branch), perform the following action.
    ;   Boost = 0.0
    % Close the expression opened above.
    ).

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
% workspace_salience/2 — query the salience of a coalition by Id
% ---------------------------------------------------------------------------

% Define a clause for 'pai salience': succeed when the following conditions hold.
workspace_salience(CoalitionId, Score) :-
    % Execute: ( coalition_salience(CoalitionId, Score).
    ( coalition_salience(CoalitionId, Score)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   Score = 0.0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% workspace_pin_item/2 — top-down pin a coalition into candidacy
% ---------------------------------------------------------------------------

% Define a clause for 'pai pin item': succeed when the following conditions hold.
workspace_pin_item(CoalitionId, Priority) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pinned_item(CoalitionId, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pinned_item(CoalitionId, Priority)).

% ---------------------------------------------------------------------------
% workspace_broadcast_subscribe/1 — subscribe a goal to receive broadcast content
% ---------------------------------------------------------------------------

% Define a clause for 'pai broadcast subscribe': succeed when the following conditions hold.
workspace_broadcast_subscribe(Goal) :-
    % Execute: ( broadcast_subscriber(Goal).
    ( broadcast_subscriber(Goal)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(broadcast_subscriber(Goal))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% workspace_cycle/0 — one cognitive cycle
%
%   1. Collect coalitions with salience scores
%   2. Select winner (highest salience above floor, with bottom-up capture)
%   3. Broadcast winner on broadcast://APEX_MIND/cycle
%   4. Kindle winner's content across zones
%   5. Attach learning: synaptic_ontological_neural_aggregator_absorb
%   6. Habituate winner
%   7. Decay salience floor if no winner
% ---------------------------------------------------------------------------

% Execute: workspace_cycle :-.
workspace_cycle :-
    % Execute: ( catch(default_nexus(Nexus), _, fail),.
    ( catch(default_nexus(Nexus), _, fail),
      % Continue the multi-line expression started above.
      nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  workspace_coalition_form(Nexus, 10, Coalitions),
        % Continue the multi-line expression started above.
        ( Coalitions = []
        % If the condition above succeeded, perform the following action.
        ->  decay_salience_floor
        % Otherwise (else branch), perform the following action.
        ;   select_winner(Nexus, Coalitions, Winner),
            % Continue the multi-line expression started above.
            ( Winner = none
            % If the condition above succeeded, perform the following action.
            ->  decay_salience_floor
            % Otherwise (else branch), perform the following action.
            ;   Winner = Salience-coalition(CId, Relation, Ids),
                % Continue the multi-line expression started above.
                broadcast_winner(Salience, CId, Relation, Ids),
                % Continue the multi-line expression started above.
                kindle_coalition(Ids),
                % Continue the multi-line expression started above.
                attach_learning(CId, Relation, Ids),
                % Continue the multi-line expression started above.
                habituate(CId)
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'select winner': succeed when the following conditions hold.
select_winner(_Nexus, Coalitions, Winner) :-
    % State a fact for 'salience floor' with the arguments listed below.
    salience_floor(Floor),
    % Check for bottom-up urgent percept
    % Execute: ( catch(.
    ( catch(
          % Continue the multi-line expression started above.
          find_urgent_percept(Coalitions, UrgentWinner),
          % Continue the multi-line expression started above.
          _, fail
      % Close the expression opened above.
      )
    % If the condition above succeeded, perform the following action.
    ->  Winner = UrgentWinner
    % Otherwise (else branch), perform the following action.
    ;   % Normal: pick highest salience above floor
        % Continue the multi-line expression started above.
        Coalitions = [Best|_],
        % Continue the multi-line expression started above.
        Best = Score-_,
        % Continue the multi-line expression started above.
        ( Score >= Floor
        % If the condition above succeeded, perform the following action.
        ->  Winner = Best
        % Otherwise (else branch), perform the following action.
        ;   Winner = none
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% Define a clause for 'find urgent percept': succeed when the following conditions hold.
find_urgent_percept(Coalitions, Winner) :-
    % Succeed for each element 'Score-coalition(CId, percept_urgent, Ids)' that is a member of the list.
    member(Score-coalition(CId, percept_urgent, Ids), Coalitions),
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % Check that 'Winner' is unifiable with 'Score-coalition(CId, percept_urgent, Ids)'.
    Winner = Score-coalition(CId, percept_urgent, Ids).

% Define a clause for 'broadcast winner': succeed when the following conditions hold.
broadcast_winner(Salience, CId, Relation, Ids) :-
    % Check that 'Content' is unifiable with 'broadcast_content(CId, Relation, Ids, Salience)'.
    Content = broadcast_content(CId, Relation, Ids, Salience),
    % State a fact for 'catch' with the arguments listed below.
    catch(publish('broadcast://APEX_MIND/cycle', Content), _, true),
    % Notify subscribers
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        broadcast_subscriber(Goal),
        % Continue the multi-line expression started above.
        catch(call(Goal, Content), _, true)
    % Close the expression opened above.
    ).

% Define a clause for 'kindle coalition': succeed when the following conditions hold.
kindle_coalition(Ids) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Id, Ids),
        % Continue the multi-line expression started above.
        catch(kindle_node(Id), _, true)
    % Close the expression opened above.
    ).

% Define a clause for 'attach learning': succeed when the following conditions hold.
attach_learning(CId, Relation, Ids) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( use_module(library(synaptic_ontological_neural_aggregator), [synaptic_ontological_neural_aggregator_absorb/1]),
          % Continue the multi-line expression started above.
          get_time(T),
          % Continue the multi-line expression started above.
          sona:synaptic_ontological_neural_aggregator_absorb(trajectory(CId, [broadcast, Relation, Ids],
                                       % Continue the multi-line expression started above.
                                       broadcast_cycle, 0.5, T))
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'habituate': succeed when the following conditions hold.
habituate(CId) :-
    % Execute: ( coalition_broadcast_count(CId, Count).
    ( coalition_broadcast_count(CId, Count)
    % If the condition above succeeded, perform the following action.
    ->  retract(coalition_broadcast_count(CId, Count)),
        % Continue the multi-line expression started above.
        Count1 is Count + 1,
        % Continue the multi-line expression started above.
        assertz(coalition_broadcast_count(CId, Count1))
    % Otherwise (else branch), perform the following action.
    ;   assertz(coalition_broadcast_count(CId, 1))
    % Close the expression opened above.
    ),
    % Update the salience with habituation penalty applied
    % Execute: ( coalition_content(CId, Ids).
    ( coalition_content(CId, Ids)
    % If the condition above succeeded, perform the following action.
    ->  catch(
            % Continue the multi-line expression started above.
            ( default_nexus(Nexus),
              % Continue the multi-line expression started above.
              score_coalition(Nexus, coalition(CId, habituated, Ids), _)
            % Close the expression opened above.
            ),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: decay_salience_floor :-.
decay_salience_floor :-
    % State a fact for 'salience floor' with the arguments listed below.
    salience_floor(CurrentFloor),
    % Check that '( CurrentFloor' is greater than '0.05'.
    ( CurrentFloor > 0.05
    % If the condition above succeeded, perform the following action.
    ->  NewFloor is CurrentFloor * 0.9,
        % Continue the multi-line expression started above.
        retract(salience_floor(CurrentFloor)),
        % Continue the multi-line expression started above.
        assertz(salience_floor(NewFloor))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Workspace actor management
% ---------------------------------------------------------------------------

% Execute: install_workspace_actor :-.
install_workspace_actor :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        cyclic_actor(attention_arbiter_actor, workspace:workspace_cycle, 200),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Execute: uninstall_workspace_actor :-.
uninstall_workspace_actor :-
    % State the fact: catch(cyclic_actor_stop(attention_arbiter_actor), _, true).
    catch(cyclic_actor_stop(attention_arbiter_actor), _, true).
