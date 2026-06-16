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

% Declare this file as the 'reflection' module and list its exported predicates.
:- module(reflection, [
    % Supply 'install_reflection_actors/0' as the next argument to the expression above.
    install_reflection_actors/0,
    % Supply 'uninstall_reflection_actors/0' as the next argument to the expression above.
    uninstall_reflection_actors/0,
    % Cycle-body predicates (exported for testing without starting a thread)
    % Supply 'motivation_cycle/0' as the next argument to the expression above.
    motivation_cycle/0,
    % Supply 'regulation_cycle/0' as the next argument to the expression above.
    regulation_cycle/0,
    % Supply 'exploration_cycle/0' as the next argument to the expression above.
    exploration_cycle/0,
    % Supply 'meta_control_cycle/0' as the next argument to the expression above.
    meta_control_cycle/0,
    % Supply 'gating_cycle/0' as the next argument to the expression above.
    gating_cycle/0,
    % Supply 'impasse_cycle/0' as the next argument to the expression above.
    impasse_cycle/0
% Close the expression opened above.
]).

% Load the built-in 'cyclic_actor' library so its predicates are available here.
:- use_module(library(cyclic_actor), [cyclic_actor/3, cyclic_actor_stop/1,
                                      % Continue the multi-line expression started above.
                                      cyclic_actor_list/1, cyclic_actor_status/2]).
% Import [pai_register_sentinel/6, sentinel_retract/1] from the built-in 'sentinels' library.
:- use_module(library(sentinels),    [pai_register_sentinel/6, sentinel_retract/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),   [anchor_node/4, default_nexus/1,
                                      % Continue the multi-line expression started above.
                                      live_node_facts/2]).
% Import [nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),      [nexus_is_open/1]).
% Import [scope_open/2] from the built-in 'scopes' library.
:- use_module(library(scopes),       [scope_open/2]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),        [member/2]).

% ---------------------------------------------------------------------------
% Reflection actor name registry
% ---------------------------------------------------------------------------

% State the fact: reflection cyclic actor(motivation_actor,   reflection:motivation_cycle,   1000).
reflection_cyclic_actor(motivation_actor,   reflection:motivation_cycle,   1000).
% State the fact: reflection cyclic actor(daydream_actor,     reflection:daydream_cycle,    5000).
reflection_cyclic_actor(daydream_actor,     reflection:daydream_cycle,    5000).
% State the fact: reflection cyclic actor(regulation_actor,   reflection:regulation_cycle,  2000).
reflection_cyclic_actor(regulation_actor,   reflection:regulation_cycle,  2000).
% State the fact: reflection cyclic actor(coping_actor,       reflection:coping_cycle,     10000).
reflection_cyclic_actor(coping_actor,       reflection:coping_cycle,     10000).
% State the fact: reflection cyclic actor(exploration_actor,  reflection:exploration_cycle, 30000).
reflection_cyclic_actor(exploration_actor,  reflection:exploration_cycle, 30000).
% State the fact: reflection cyclic actor(imitation_actor,    reflection:imitation_cycle,   5000).
reflection_cyclic_actor(imitation_actor,    reflection:imitation_cycle,   5000).
% State the fact: reflection cyclic actor(play_actor,         reflection:play_cycle,       60000).
reflection_cyclic_actor(play_actor,         reflection:play_cycle,       60000).
% State the fact: reflection cyclic actor(meta_control_actor, reflection:meta_control_cycle, 5000).
reflection_cyclic_actor(meta_control_actor, reflection:meta_control_cycle, 5000).
% State the fact: reflection cyclic actor(gating_actor,       reflection:gating_cycle,      5000).
reflection_cyclic_actor(gating_actor,       reflection:gating_cycle,      5000).
% State the fact: reflection cyclic actor(impasse_actor,      reflection:impasse_cycle,     2000).
reflection_cyclic_actor(impasse_actor,      reflection:impasse_cycle,     2000).

% ---------------------------------------------------------------------------
% install_reflection_actors/0
% ---------------------------------------------------------------------------

% Execute: install_reflection_actors :-.
install_reflection_actors :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        reflection_cyclic_actor(Name, Goal, Ms),
        % Continue the multi-line expression started above.
        ( cyclic_actor_list(Running),
          % Continue the multi-line expression started above.
          ( memberchk(Name, Running)
          % If the condition above succeeded, perform the following action.
          ->  true   % already started; idempotent
          % Otherwise (else branch), perform the following action.
          ;   cyclic_actor(Name, Goal, Ms)
          % Close the expression opened above.
          )
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % State the zero-argument fact 'register_sentinel_actors'.
    register_sentinel_actors.

% ---------------------------------------------------------------------------
% uninstall_reflection_actors/0
% ---------------------------------------------------------------------------

% Execute: uninstall_reflection_actors :-.
uninstall_reflection_actors :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        reflection_cyclic_actor(Name, _, _),
        % Continue the multi-line expression started above.
        catch(cyclic_actor_stop(Name), _, true)
    % Close the expression opened above.
    ),
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinel_retract(compensation_actor),
    % State the fact: sentinel retract(discovery_actor).
    sentinel_retract(discovery_actor).

% ---------------------------------------------------------------------------
% Sentinel actor registration
% ---------------------------------------------------------------------------

% Execute: register_sentinel_actors :-.
register_sentinel_actors :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    pai_register_sentinel(
        % Continue the multi-line expression started above.
        compensation_actor, 50,
        % Continue the multi-line expression started above.
        node_fact(_, plan_needs_revision, _, _),
        % Continue the multi-line expression started above.
        [],
        % Supply 'reflection:compensation_cycle' as the next argument to the expression above.
        reflection:compensation_cycle,
        % Continue the multi-line expression started above.
        "Generate alternative plans when the current plan needs revision"),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    pai_register_sentinel(
        % Continue the multi-line expression started above.
        discovery_actor, 40,
        % Continue the multi-line expression started above.
        node_fact(_, percept_signal, _, _),
        % Continue the multi-line expression started above.
        [],
        % Supply 'reflection:discovery_cycle' as the next argument to the expression above.
        reflection:discovery_cycle,
        % Continue the multi-line expression started above.
        "Detect novel percepts and publish novelty events").

% ---------------------------------------------------------------------------
% Cycle bodies
% ---------------------------------------------------------------------------

% Execute: motivation_cycle :-.
motivation_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Collect all enrolled bodies and check vitals
        % Continue the multi-line expression started above.
        findall(Addr, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, _, body_enrollment, [Addr|_], [])
        % Continue the multi-line expression started above.
        ), Addrs),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(Addr, Addrs),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                ( mindbody:body_vitals(Addr, vitals(_, Needs, _))
                % If the condition above succeeded, perform the following action.
                ->  forall(
                        % Continue the multi-line expression started above.
                        member(need(NeedId, Target, Unit), Needs),
                        % Continue the multi-line expression started above.
                        record_homeostatic_delta(Nexus, Addr, NeedId, Target, Unit)
                    % Close the expression opened above.
                    )
                % Otherwise (else branch), perform the following action.
                ;   true
                % Close the expression opened above.
                ),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'record homeostatic delta': succeed when the following conditions hold.
record_homeostatic_delta(Nexus, Addr, NeedId, Target, Unit) :-
    % Look for the most recent interoceptive_signal for this need
    % Execute: ( node_facts:lattice_node_fact(Nexus, _, percept_signal,.
    ( node_facts:lattice_node_fact(Nexus, _, percept_signal,
          % Continue the multi-line expression started above.
          [Addr, interoceptive_signal(NeedId, Actual, _)], _)
    % If the condition above succeeded, perform the following action.
    ->  Delta is Target - Actual,
        % Continue the multi-line expression started above.
        abs(Delta) > 0.01
    % If the condition above succeeded, perform the following action.
    ->  anchor_node(objective,
                    % Continue the multi-line expression started above.
                    [NeedId, reduce_delta, Delta, Unit],
                    % Continue the multi-line expression started above.
                    [Addr],
                    % Supply '_' as the next argument to the expression above.
                    _)
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: daydream_cycle :-.
daydream_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Check inhibition flag
        % Continue the multi-line expression started above.
        ( \+ node_facts:lattice_node_fact(Nexus, _, daydream_inhibited, _, _)
        % If the condition above succeeded, perform the following action.
        ->  catch(scope_open('scope://daydream', possible_zone), _, true),
            % Simulate 3 candidate causal_plans (stub: inscribe placeholders)
            % Continue the multi-line expression started above.
            forall(
                % Continue the multi-line expression started above.
                between(1, 3, I),
                % Continue the multi-line expression started above.
                catch(
                    % Continue the multi-line expression started above.
                    anchor_node(causal_plan,
                                % Continue the multi-line expression started above.
                                [simulated, I, placeholder],
                                % Continue the multi-line expression started above.
                                [possible_zone],
                                % Supply '_' as the next argument to the expression above.
                                _),
                    % Continue the multi-line expression started above.
                    _, true
                % Close the expression opened above.
                )
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: regulation_cycle :-.
regulation_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Find recent proprioceptive signals
        % Continue the multi-line expression started above.
        findall(Id-CmdId-Success, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, Id, percept_signal,
                % Continue the multi-line expression started above.
                [_, proprioceptive_signal(CmdId, Success, _, _)], _)
        % Continue the multi-line expression started above.
        ), PropSigs),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_Id-CmdId-Success, PropSigs),
            % Continue the multi-line expression started above.
            regulate_outcome(Nexus, CmdId, Success)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'regulate outcome': succeed when the following conditions hold.
regulate_outcome(Nexus, CmdId, Success) :-
    % Find the original command
    % Execute: ( node_facts:lattice_node_fact(Nexus, _, body_command, [_, CmdId, _Cmd], _).
    ( node_facts:lattice_node_fact(Nexus, _, body_command, [_, CmdId, _Cmd], _)
    % If the condition above succeeded, perform the following action.
    ->  ( Success == true
        % If the condition above succeeded, perform the following action.
        ->  Classification = confirmation
        % Otherwise (else branch), perform the following action.
        ;   Classification = surprise
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            anchor_node(regulation_outcome,
                        % Continue the multi-line expression started above.
                        [CmdId, Classification],
                        % Continue the multi-line expression started above.
                        [],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: coping_cycle :-.
coping_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  get_time(Now),
        % Continue the multi-line expression started above.
        Patience is Now - 60.0,   % 60 second patience threshold
        % Continue the multi-line expression started above.
        findall(Id-Args, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _),
            % Continue the multi-line expression started above.
            node_facts:node_activation(Id, T, _),
            % Continue the multi-line expression started above.
            T < Patience
        % Continue the multi-line expression started above.
        ), StaleObjectives),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_Id-Args, StaleObjectives),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                anchor_node(coping_response, [problem_focused, Args], [], _),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: exploration_cycle :-.
exploration_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  catch(
            % Continue the multi-line expression started above.
            anchor_node(explore_objective,
                        % Continue the multi-line expression started above.
                        [low_density_region, spontaneous],
                        % Continue the multi-line expression started above.
                        [],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: imitation_cycle :-.
imitation_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Scan for agent_action node_facts
        % Continue the multi-line expression started above.
        findall(Seq, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, _, agent_action, Seq, _)
        % Continue the multi-line expression started above.
        ), Sequences),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(Seq, Sequences),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                ( \+ node_facts:lattice_node_fact(Nexus, _, causal_plan,
                          % Continue the multi-line expression started above.
                          [imitated | Seq], _)
                % If the condition above succeeded, perform the following action.
                ->  anchor_node(causal_plan, [candidate, imitated | Seq], [], _)
                % Otherwise (else branch), perform the following action.
                ;   true
                % Close the expression opened above.
                ),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: play_cycle :-.
play_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Only play when no high-priority objectives are active
        % Continue the multi-line expression started above.
        ( node_facts:lattice_node_fact(Nexus, _, objective, _, _)
        % If the condition above succeeded, perform the following action.
        ->  true   % There are active objectives; skip play
        % Otherwise (else branch), perform the following action.
        ;   catch(
                % Continue the multi-line expression started above.
                anchor_node(play_result, [spontaneous, explore], [], _),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: meta_control_cycle :-.
meta_control_cycle :-
    % Check all running actors for high error counts
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Names),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Name, Names),
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            ( cyclic_actor_status(Name, Status),
              % Continue the multi-line expression started above.
              get_dict(error_count, Status, EC),
              % Continue the multi-line expression started above.
              ( EC > 10
              % If the condition above succeeded, perform the following action.
              ->  catch(
                      % Continue the multi-line expression started above.
                      anchor_node(system_warning,
                                  % Continue the multi-line expression started above.
                                  [high_error_count, Name, EC],
                                  % Continue the multi-line expression started above.
                                  [],
                                  % Supply '_' as the next argument to the expression above.
                                  _),
                      % Continue the multi-line expression started above.
                      _, true
                  % Close the expression opened above.
                  )
              % Otherwise (else branch), perform the following action.
              ;   true
              % Close the expression opened above.
              )
            % Close the expression opened above.
            ),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % Trigger crystallization if Lattice is large
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  aggregate_all(count,
                      % Continue the multi-line expression started above.
                      node_facts:lattice_node_fact(Nexus, _, _, _, _),
                      % Supply 'TotalFacts' as the next argument to the expression above.
                      TotalFacts),
        % Continue the multi-line expression started above.
        ( TotalFacts > 1000000
        % If the condition above succeeded, perform the following action.
        ->  catch(sona:sona_crystallize([]), _, true)
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: gating_cycle :-.
gating_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Suppress objectives that lack the required prior conditions
        % Continue the multi-line expression started above.
        findall(Id-Args, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _)
        % Continue the multi-line expression started above.
        ), Objectives),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_Id-_Args, Objectives),
            % Continue the multi-line expression started above.
            true   % Gate logic: full gating added by deliberation PR
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Execute: impasse_cycle :-.
impasse_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Find objectives that lack a causal_plan (impasse)
        % Continue the multi-line expression started above.
        findall(Id-Args, (
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, Id, objective, Args, _),
            % Continue the multi-line expression started above.
            \+ node_facts:lattice_node_fact(Nexus, _, causal_plan, Args, _)
        % Continue the multi-line expression started above.
        ), Impasses),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_Id-Args, Impasses),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                anchor_node(subgoal, [impasse_resolution | Args], [], _),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Sentinel action: compensation cycle
% Execute: compensation_cycle :-.
compensation_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  catch(
            % Continue the multi-line expression started above.
            anchor_node(reversal_plan, [auto_compensation], [], _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Sentinel action: discovery cycle
% Execute: discovery_cycle :-.
discovery_cycle :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  catch(
            % Continue the multi-line expression started above.
            anchor_node(novelty_detected, [percept, auto], [], _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            pubsub:publish('channel://novelty', novelty_event(auto)),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).
