/*  PrologAI — Marginal Attribution: Spinoff Learning  (Specification PR 20)

    Discovers rare-but-reliable action effects as new causal_plans, using
    Drescher's marginal-attribution algorithm.

    For every command attempt, the attribution_miner_actor logs the live
    node_facts before and after execution (a trial record).  Periodically, for
    each command it computes P(result | command) vs P(result | ¬command).
    When the ratio is statistically significant, a result-spinoff causal_plan
    is forged.  For each unreliable spinoff, the miner searches contexts that
    lift reliability past a threshold and forges context-spinoff plans.

    Spinoffs never overwrite parents (pai_accommodate semantics).

    Predicates:
      pai_spinoff_mine/2    — +Command, -SpinoffList
      pai_spinoff_stats/2   — +Command, -Stats
      record_trial/4        — log before/after for one command attempt
      install_attribution_miner/0
      uninstall_attribution_miner/0
*/

:- module(spinoff, [
    pai_spinoff_mine/2,         % +Command, -Spinoffs
    pai_spinoff_stats/2,        % +Command, -Stats
    record_trial/4,             % +Command, +ContextBefore, +ContextAfter, +Outcome
    install_attribution_miner/0,
    uninstall_attribution_miner/0
]).

:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1,
                                     live_node_facts/2]).
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
:- use_module(library(lists),       [member/2, subtract/3]).
:- use_module(library(apply),       [maplist/3]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal trial log
%
%   trial_record(Id, Command, ContextBefore, ContextAfter, Outcome, Timestamp)
%   ContextBefore/ContextAfter: lists of active relation atoms
% ---------------------------------------------------------------------------

:- dynamic trial_record/6.         % Id, Command, CtxBefore, CtxAfter, Outcome, Ts
:- dynamic trial_id_counter/1.
trial_id_counter(0).

:- dynamic spinoff_plan/5.         % Id, Command, Context, Result, Reliability
:- dynamic spinoff_id_counter/1.
spinoff_id_counter(0).

% Reliability thresholds
reliability_threshold(0.7).
marginal_significance(0.3).       % minimum lift: P(R|C) - P(R|¬C) > 0.3

next_trial_id(Id) :-
    retract(trial_id_counter(N)),
    N1 is N + 1,
    assertz(trial_id_counter(N1)),
    Id = N1.

next_spinoff_id(Id) :-
    retract(spinoff_id_counter(N)),
    N1 is N + 1,
    assertz(spinoff_id_counter(N1)),
    Id = N1.

% ---------------------------------------------------------------------------
% record_trial/4
%
%   Log a before/after snapshot for one command attempt.
%   ContextBefore/After are lists of relation atoms from live node_facts.
%   Outcome: success | failure | noise
% ---------------------------------------------------------------------------

record_trial(Command, ContextBefore, ContextAfter, Outcome) :-
    next_trial_id(Id),
    get_time(Ts),
    assertz(trial_record(Id, Command, ContextBefore, ContextAfter, Outcome, Ts)).

% ---------------------------------------------------------------------------
% pai_spinoff_stats/2 — statistics for a command
% ---------------------------------------------------------------------------

pai_spinoff_stats(Command, Stats) :-
    % Total trials with this command
    aggregate_all(count,
                  trial_record(_, Command, _, _, _, _),
                  Total),
    % Trials without this command (proxy: all other commands)
    aggregate_all(count,
                  trial_record(_, _, _, _, _, _),
                  TotalAll),
    WithoutCount is max(1, TotalAll - Total),
    % Collect all distinct result patterns (changes = AfterRels - BeforeRels)
    findall(Change, (
        trial_record(_, Command, Before, After, _, _),
        subtract(After, Before, Change),
        Change \= []
    ), Changes),
    sort(Changes, UniqueChanges),
    length(UniqueChanges, UniqueChangeCount),
    Stats = spinoff_stats{
        command:        Command,
        trial_count:    Total,
        without_count:  WithoutCount,
        unique_results: UniqueChangeCount
    }.

% ---------------------------------------------------------------------------
% pai_spinoff_mine/2 — run marginal attribution for a command
%
%   Returns a list of spinoff terms:
%     result_spinoff(Command, Result, Reliability)   — unconditional
%     context_spinoff(Command, Context, Result, Reliability) — conditioned
% ---------------------------------------------------------------------------

pai_spinoff_mine(Command, Spinoffs) :-
    % Gather all result patterns from trials
    findall(Change, (
        trial_record(_, Command, Before, After, _, _),
        subtract(After, Before, Change),
        Change \= []
    ), AllChanges),
    sort(AllChanges, UniqueChanges),
    findall(Spinoff, (
        member(Change, UniqueChanges),
        compute_marginal(Command, Change, WithP, WithoutP),
        Lift is WithP - WithoutP,
        Lift > 0,
        ( reliability_threshold(T),
          WithP >= T
        ->  % High reliability unconditional spinoff
            Spinoff = result_spinoff(Command, Change, WithP),
            maybe_forge_spinoff(Command, [], Change, WithP)
        ;   % Search for context conditions that lift reliability
            marginal_significance(MinLift),
            Lift >= MinLift,
            find_context_conditions(Command, Change, Context, CondP),
            Spinoff = context_spinoff(Command, Context, Change, CondP),
            maybe_forge_spinoff(Command, Context, Change, CondP)
        )
    ), Spinoffs).

% ---------------------------------------------------------------------------
% compute_marginal/4 — P(result | command) and P(result | ¬command)
% ---------------------------------------------------------------------------

compute_marginal(Command, Change, WithP, WithoutP) :-
    % Trials WITH this command
    aggregate_all(count,
                  trial_record(_, Command, _, _, _, _),
                  WithTotal),
    aggregate_all(count, (
        trial_record(_, Command, Before, After, _, _),
        subtract(After, Before, ActualChange),
        ActualChange = Change
    ), WithMatches),
    ( WithTotal > 0
    ->  WithP is WithMatches / WithTotal
    ;   WithP = 0.0
    ),
    % Trials WITHOUT this command (other commands)
    aggregate_all(count, (
        trial_record(_, OtherCmd, _, _, _, _),
        OtherCmd \= Command
    ), WithoutTotal),
    aggregate_all(count, (
        trial_record(_, OtherCmd, Before, After, _, _),
        OtherCmd \= Command,
        subtract(After, Before, ActualChange),
        ActualChange = Change
    ), WithoutMatches),
    ( WithoutTotal > 0
    ->  WithoutP is WithoutMatches / WithoutTotal
    ;   WithoutP = 0.0
    ).

% ---------------------------------------------------------------------------
% find_context_conditions/4 — find context atoms that lift reliability
% ---------------------------------------------------------------------------

find_context_conditions(Command, Change, BestContext, BestP) :-
    % Find all condition atoms that appear in any trial context
    findall(Cond, (
        trial_record(_, Command, Before, _, _, _),
        member(Cond, Before)
    ), AllConds),
    sort(AllConds, UniqConds),
    % Find which condition best lifts reliability
    findall(P-Cond, (
        member(Cond, UniqConds),
        aggregate_all(count, (
            trial_record(_, Command, Before, After, _, _),
            member(Cond, Before),
            subtract(After, Before, ActualChange),
            ActualChange = Change
        ), WithCondMatches),
        aggregate_all(count, (
            trial_record(_, Command, Before, _, _, _),
            member(Cond, Before)
        ), WithCondTotal),
        WithCondTotal > 0,
        P is WithCondMatches / WithCondTotal
    ), CondScores),
    ( CondScores \= []
    ->  max_p(CondScores, BestP-BestCond),
        BestContext = [BestCond]
    ;   BestContext = [],
        BestP = 0.0
    ).

max_p([X], X) :- !.
max_p([H|T], Max) :-
    max_p(T, MaxT),
    H = P-_,
    MaxT = Q-_,
    ( P >= Q -> Max = H ; Max = MaxT ).

% ---------------------------------------------------------------------------
% maybe_forge_spinoff/4 — inscribe a new causal_plan if novel
% ---------------------------------------------------------------------------

maybe_forge_spinoff(Command, Context, Result, Reliability) :-
    % Do not overwrite existing spinoff for this Command+Context+Result
    ( spinoff_plan(_, Command, Context, Result, _)
    ->  true   % already exists (pai_accommodate semantics)
    ;   next_spinoff_id(SpId),
        assertz(spinoff_plan(SpId, Command, Context, Result, Reliability)),
        % Inscribe as a node_fact in the Lattice
        catch(
            anchor_node(causal_plan,
                        [spinoff(SpId), Command, Context, Result],
                        [reliability=Reliability],
                        _),
            _, true
        )
    ).

% ---------------------------------------------------------------------------
% Attribution miner actor cycle
% ---------------------------------------------------------------------------

attribution_miner_cycle :-
    catch(
        ( default_nexus(Nexus),
          nexus_is_open(Nexus),
          % Find all commands that have enough trials
          findall(C, trial_record(_, C, _, _, _, _), AllCmds),
          sort(AllCmds, UniqCmds),
          forall(
              member(Cmd, UniqCmds),
              ( aggregate_all(count, trial_record(_, Cmd, _, _, _, _), N),
                ( N >= 5
                ->  catch(pai_spinoff_mine(Cmd, _), _, true)
                ;   true
                )
              )
          )
        ),
        _, true
    ).

install_attribution_miner :-
    catch(
        cyclic_actor(attribution_miner_actor,
                     spinoff:attribution_miner_cycle,
                     30000),
        _, true
    ).

uninstall_attribution_miner :-
    catch(cyclic_actor_stop(attribution_miner_actor), _, true).
