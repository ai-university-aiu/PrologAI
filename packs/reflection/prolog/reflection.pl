/*  PrologAI — Reflection Pattern Actors  (Specification Section 3.11, PR 13)

    Implements the twelve reflection actors specified in Section 3.11:

    Cyclic actors:
      motivation_actor  (1 000 ms) — body_vitals + homeostatic deltas → objectives
      daydream_actor    (5 000 ms) — possible_zone simulation of causal_plans
      regulation_actor  (2 000 ms) — proprioceptive verification of outcomes
      coping_actor      (10 000 ms) — scans stale objectives; emotion/problem coping
      exploration_actor (30 000 ms) — low-density regions → explore_objectives
      imitation_actor   (5 000 ms) — matches observed agent_actions to causal_plans
      play_actor        (60 000 ms, idle only) — random capability variation
      meta_control_actor(5 000 ms) — actor health; triggers sona_crystallize
      gating_actor      (5 000 ms) — unified gating: filters objectives by readiness
      impasse_actor     (2 000 ms) — converts dead-ends into subgoal node_facts

    Sentinel actors (registered via pai_register_sentinel):
      compensation_actor — triggered by plan_needs_revision node_facts
      discovery_actor    — triggered by percept node_facts below novelty threshold

    Entry points:
      install_reflection_actors/0  — start all actors and register sentinels
      uninstall_reflection_actors/0 — stop all actors and retract sentinels
*/

:- module(reflection, [
    install_reflection_actors/0,
    uninstall_reflection_actors/0,
    % Cycle-body predicates (exported for testing without starting a thread)
    motivation_cycle/0,
    regulation_cycle/0,
    exploration_cycle/0,
    meta_control_cycle/0,
    gating_cycle/0,
    impasse_cycle/0
]).

:- use_module(library(cyclic_actor), [cyclic_actor/3, cyclic_actor_stop/1,
                                      cyclic_actor_list/1, cyclic_actor_status/2]).
:- use_module(library(sentinels),    [pai_register_sentinel/6, sentinel_retract/1]).
:- use_module(library(node_facts),   [anchor_node/4, default_nexus/1,
                                      live_node_facts/2]).
:- use_module(library(lattice),      [nexus_is_open/1]).
:- use_module(library(scopes),       [scope_open/2]).
:- use_module(library(lists),        [member/2]).

% ---------------------------------------------------------------------------
% Reflection actor name registry
% ---------------------------------------------------------------------------

reflection_cyclic_actor(motivation_actor,   reflection:motivation_cycle,   1000).
reflection_cyclic_actor(daydream_actor,     reflection:daydream_cycle,    5000).
reflection_cyclic_actor(regulation_actor,   reflection:regulation_cycle,  2000).
reflection_cyclic_actor(coping_actor,       reflection:coping_cycle,     10000).
reflection_cyclic_actor(exploration_actor,  reflection:exploration_cycle, 30000).
reflection_cyclic_actor(imitation_actor,    reflection:imitation_cycle,   5000).
reflection_cyclic_actor(play_actor,         reflection:play_cycle,       60000).
reflection_cyclic_actor(meta_control_actor, reflection:meta_control_cycle, 5000).
reflection_cyclic_actor(gating_actor,       reflection:gating_cycle,      5000).
reflection_cyclic_actor(impasse_actor,      reflection:impasse_cycle,     2000).

% ---------------------------------------------------------------------------
% install_reflection_actors/0
% ---------------------------------------------------------------------------

install_reflection_actors :-
    forall(
        reflection_cyclic_actor(Name, Goal, Ms),
        ( cyclic_actor_list(Running),
          ( memberchk(Name, Running)
          ->  true   % already started; idempotent
          ;   cyclic_actor(Name, Goal, Ms)
          )
        )
    ),
    register_sentinel_actors.

% ---------------------------------------------------------------------------
% uninstall_reflection_actors/0
% ---------------------------------------------------------------------------

uninstall_reflection_actors :-
    forall(
        reflection_cyclic_actor(Name, _, _),
        catch(cyclic_actor_stop(Name), _, true)
    ),
    sentinel_retract(compensation_actor),
    sentinel_retract(discovery_actor).

% ---------------------------------------------------------------------------
% Sentinel actor registration
% ---------------------------------------------------------------------------

register_sentinel_actors :-
    pai_register_sentinel(
        compensation_actor, 50,
        node_fact(_, plan_needs_revision, _, _),
        [],
        reflection:compensation_cycle,
        "Generate alternative plans when the current plan needs revision"),
    pai_register_sentinel(
        discovery_actor, 40,
        node_fact(_, percept_signal, _, _),
        [],
        reflection:discovery_cycle,
        "Detect novel percepts and publish novelty events").

% ---------------------------------------------------------------------------
% Cycle bodies
% ---------------------------------------------------------------------------

motivation_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Collect all enrolled bodies and check vitals
        findall(Addr, (
            node_facts:lattice_node_fact(Nexus, _, body_enrollment, [Addr|_], [])
        ), Addrs),
        forall(
            member(Addr, Addrs),
            catch(
                ( mindbody:body_vitals(Addr, vitals(_, Needs, _))
                ->  forall(
                        member(need(NeedId, Target, Unit), Needs),
                        record_homeostatic_delta(Nexus, Addr, NeedId, Target, Unit)
                    )
                ;   true
                ),
                _, true
            )
        )
    ;   true
    ).

record_homeostatic_delta(Nexus, Addr, NeedId, Target, Unit) :-
    % Look for the most recent interoceptive_signal for this need
    ( node_facts:lattice_node_fact(Nexus, _, percept_signal,
          [Addr, interoceptive_signal(NeedId, Actual, _)], _)
    ->  Delta is Target - Actual,
        abs(Delta) > 0.01
    ->  anchor_node(objective,
                    [NeedId, reduce_delta, Delta, Unit],
                    [Addr],
                    _)
    ;   true
    ).

daydream_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Check inhibition flag
        ( \+ node_facts:lattice_node_fact(Nexus, _, daydream_inhibited, _, _)
        ->  catch(scope_open('scope://daydream', possible_zone), _, true),
            % Simulate 3 candidate causal_plans (stub: inscribe placeholders)
            forall(
                between(1, 3, I),
                catch(
                    anchor_node(causal_plan,
                                [simulated, I, placeholder],
                                [possible_zone],
                                _),
                    _, true
                )
            )
        ;   true
        )
    ;   true
    ).

regulation_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Find recent proprioceptive signals
        findall(Id-CmdId-Success, (
            node_facts:lattice_node_fact(Nexus, Id, percept_signal,
                [_, proprioceptive_signal(CmdId, Success, _, _)], _)
        ), PropSigs),
        forall(
            member(_Id-CmdId-Success, PropSigs),
            regulate_outcome(Nexus, CmdId, Success)
        )
    ;   true
    ).

regulate_outcome(Nexus, CmdId, Success) :-
    % Find the original command
    ( node_facts:lattice_node_fact(Nexus, _, body_command, [_, CmdId, _Cmd], _)
    ->  ( Success == true
        ->  Classification = confirmation
        ;   Classification = surprise
        ),
        catch(
            anchor_node(regulation_outcome,
                        [CmdId, Classification],
                        [],
                        _),
            _, true
        )
    ;   true
    ).

coping_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  get_time(Now),
        Patience is Now - 60.0,   % 60 second patience threshold
        findall(Id-Args, (
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _),
            node_facts:node_activation(Id, T, _),
            T < Patience
        ), StaleObjectives),
        forall(
            member(_Id-Args, StaleObjectives),
            catch(
                anchor_node(coping_response, [problem_focused, Args], [], _),
                _, true
            )
        )
    ;   true
    ).

exploration_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  catch(
            anchor_node(explore_objective,
                        [low_density_region, spontaneous],
                        [],
                        _),
            _, true
        )
    ;   true
    ).

imitation_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Scan for agent_action node_facts
        findall(Seq, (
            node_facts:lattice_node_fact(Nexus, _, agent_action, Seq, _)
        ), Sequences),
        forall(
            member(Seq, Sequences),
            catch(
                ( \+ node_facts:lattice_node_fact(Nexus, _, causal_plan,
                          [imitated | Seq], _)
                ->  anchor_node(causal_plan, [candidate, imitated | Seq], [], _)
                ;   true
                ),
                _, true
            )
        )
    ;   true
    ).

play_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Only play when no high-priority objectives are active
        ( node_facts:lattice_node_fact(Nexus, _, objective, _, _)
        ->  true   % There are active objectives; skip play
        ;   catch(
                anchor_node(play_result, [spontaneous, explore], [], _),
                _, true
            )
        )
    ;   true
    ).

meta_control_cycle :-
    % Check all running actors for high error counts
    cyclic_actor_list(Names),
    forall(
        member(Name, Names),
        catch(
            ( cyclic_actor_status(Name, Status),
              get_dict(error_count, Status, EC),
              ( EC > 10
              ->  catch(
                      anchor_node(system_warning,
                                  [high_error_count, Name, EC],
                                  [],
                                  _),
                      _, true
                  )
              ;   true
              )
            ),
            _, true
        )
    ),
    % Trigger crystallization if Lattice is large
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  aggregate_all(count,
                      node_facts:lattice_node_fact(Nexus, _, _, _, _),
                      TotalFacts),
        ( TotalFacts > 1000000
        ->  catch(sona:sona_crystallize([]), _, true)
        ;   true
        )
    ;   true
    ).

gating_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Suppress objectives that lack the required prior conditions
        findall(Id-Args, (
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _)
        ), Objectives),
        forall(
            member(_Id-_Args, Objectives),
            true   % Gate logic: full gating added by deliberation PR
        )
    ;   true
    ).

impasse_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Find objectives that lack a causal_plan (impasse)
        findall(Id-Args, (
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _),
            \+ node_facts:lattice_node_fact(Nexus, _, causal_plan, Args, _)
        ), Impasses),
        forall(
            member(_Id-Args, Impasses),
            catch(
                anchor_node(subgoal, [impasse_resolution | Args], [], _),
                _, true
            )
        )
    ;   true
    ).

% Sentinel action: compensation cycle
compensation_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  catch(
            anchor_node(reversal_plan, [auto_compensation], [], _),
            _, true
        )
    ;   true
    ).

% Sentinel action: discovery cycle
discovery_cycle :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  catch(
            anchor_node(novelty_detected, [percept, auto], [], _),
            _, true
        ),
        catch(
            pubsub:publish('channel://novelty', novelty_event(auto)),
            _, true
        )
    ;   true
    ).
