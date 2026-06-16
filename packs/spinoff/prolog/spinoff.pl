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

% Declare this file as the 'spinoff' module and list its exported predicates.
:- module(spinoff, [
    % Continue the multi-line expression started above.
    pai_spinoff_mine/2,         % +Command, -Spinoffs
    % Continue the multi-line expression started above.
    pai_spinoff_stats/2,        % +Command, -Stats
    % Continue the multi-line expression started above.
    record_trial/4,             % +Command, +ContextBefore, +ContextAfter, +Outcome
    % Supply 'install_attribution_miner/0' as the next argument to the expression above.
    install_attribution_miner/0,
    % Supply 'uninstall_attribution_miner/0' as the next argument to the expression above.
    uninstall_attribution_miner/0
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1,
                                     % Continue the multi-line expression started above.
                                     live_node_facts/2]).
% Import [lattice_node_fact/5, nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
% Import [cyclic_actor/3, cyclic_actor_stop/1] from the built-in 'cyclic_actor' library.
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
% Import [member/2, subtract/3] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2, subtract/3]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),       [maplist/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal trial log
%
%   trial_record(Id, Command, ContextBefore, ContextAfter, Outcome, Timestamp)
%   ContextBefore/ContextAfter: lists of active relation atoms
% ---------------------------------------------------------------------------

% Declare 'trial_record/6.         % Id, Command, CtxBefore, CtxAfter, Outcome, Ts' as dynamic — its facts may be added or removed at runtime.
:- dynamic trial_record/6.         % Id, Command, CtxBefore, CtxAfter, Outcome, Ts
% Declare 'trial_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic trial_id_counter/1.
% State the fact: trial id counter(0).
trial_id_counter(0).

% Declare 'spinoff_plan/5.         % Id, Command, Context, Result, Reliability' as dynamic — its facts may be added or removed at runtime.
:- dynamic spinoff_plan/5.         % Id, Command, Context, Result, Reliability
% Declare 'spinoff_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic spinoff_id_counter/1.
% State the fact: spinoff id counter(0).
spinoff_id_counter(0).

% Reliability thresholds
% State the fact: reliability threshold(0.7).
reliability_threshold(0.7).
% Check that 'marginal_significance(0.3).       % minimum lift: P(R|C) - P(R|¬C)' is greater than '0.3'.
marginal_significance(0.3).       % minimum lift: P(R|C) - P(R|¬C) > 0.3

% Define a clause for 'next trial id': succeed when the following conditions hold.
next_trial_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(trial_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(trial_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% Define a clause for 'next spinoff id': succeed when the following conditions hold.
next_spinoff_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(spinoff_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(spinoff_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% ---------------------------------------------------------------------------
% record_trial/4
%
%   Log a before/after snapshot for one command attempt.
%   ContextBefore/After are lists of relation atoms from live node_facts.
%   Outcome: success | failure | noise
% ---------------------------------------------------------------------------

% Define a clause for 'record trial': succeed when the following conditions hold.
record_trial(Command, ContextBefore, ContextAfter, Outcome) :-
    % State a fact for 'next trial id' with the arguments listed below.
    next_trial_id(Id),
    % State a fact for 'get time' with the arguments listed below.
    get_time(Ts),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(trial_record(Id, Command, ContextBefore, ContextAfter, Outcome, Ts)).

% ---------------------------------------------------------------------------
% pai_spinoff_stats/2 — statistics for a command
% ---------------------------------------------------------------------------

% Define a clause for 'pai spinoff stats': succeed when the following conditions hold.
pai_spinoff_stats(Command, Stats) :-
    % Total trials with this command
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  trial_record(_, Command, _, _, _, _),
                  % Supply 'Total' as the next argument to the expression above.
                  Total),
    % Trials without this command (proxy: all other commands)
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  trial_record(_, _, _, _, _, _),
                  % Supply 'TotalAll' as the next argument to the expression above.
                  TotalAll),
    % Evaluate the arithmetic expression 'max(1, TotalAll - Total)' and bind the result to 'WithoutCount'.
    WithoutCount is max(1, TotalAll - Total),
    % Collect all distinct result patterns (changes = AfterRels - BeforeRels)
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Change, (
        % Continue the multi-line expression started above.
        trial_record(_, Command, Before, After, _, _),
        % Continue the multi-line expression started above.
        subtract(After, Before, Change),
        % Continue the multi-line expression started above.
        Change \= []
    % Continue the multi-line expression started above.
    ), Changes),
    % Sort list 'Changes' into 'UniqueChanges', removing duplicates.
    sort(Changes, UniqueChanges),
    % Unify 'UniqueChangeCount' with the number of elements in list 'UniqueChanges'.
    length(UniqueChanges, UniqueChangeCount),
    % Check that 'Stats' is unifiable with 'spinoff_stats{'.
    Stats = spinoff_stats{
        % Execute: command:        Command,.
        command:        Command,
        % Execute: trial_count:    Total,.
        trial_count:    Total,
        % Execute: without_count:  WithoutCount,.
        without_count:  WithoutCount,
        % Execute: unique_results: UniqueChangeCount.
        unique_results: UniqueChangeCount
    % Execute: }..
    }.

% ---------------------------------------------------------------------------
% pai_spinoff_mine/2 — run marginal attribution for a command
%
%   Returns a list of spinoff terms:
%     result_spinoff(Command, Result, Reliability)   — unconditional
%     context_spinoff(Command, Context, Result, Reliability) — conditioned
% ---------------------------------------------------------------------------

% Define a clause for 'pai spinoff mine': succeed when the following conditions hold.
pai_spinoff_mine(Command, Spinoffs) :-
    % Gather all result patterns from trials
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Change, (
        % Continue the multi-line expression started above.
        trial_record(_, Command, Before, After, _, _),
        % Continue the multi-line expression started above.
        subtract(After, Before, Change),
        % Continue the multi-line expression started above.
        Change \= []
    % Continue the multi-line expression started above.
    ), AllChanges),
    % Sort list 'AllChanges' into 'UniqueChanges', removing duplicates.
    sort(AllChanges, UniqueChanges),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Spinoff, (
        % Continue the multi-line expression started above.
        member(Change, UniqueChanges),
        % Continue the multi-line expression started above.
        compute_marginal(Command, Change, WithP, WithoutP),
        % Continue the multi-line expression started above.
        Lift is WithP - WithoutP,
        % Continue the multi-line expression started above.
        Lift > 0,
        % Continue the multi-line expression started above.
        ( reliability_threshold(T),
          % Continue the multi-line expression started above.
          WithP >= T
        % If the condition above succeeded, perform the following action.
        ->  % High reliability unconditional spinoff
            % Continue the multi-line expression started above.
            Spinoff = result_spinoff(Command, Change, WithP),
            % Continue the multi-line expression started above.
            maybe_forge_spinoff(Command, [], Change, WithP)
        % Otherwise (else branch), perform the following action.
        ;   % Search for context conditions that lift reliability
            % Continue the multi-line expression started above.
            marginal_significance(MinLift),
            % Continue the multi-line expression started above.
            Lift >= MinLift,
            % Continue the multi-line expression started above.
            find_context_conditions(Command, Change, Context, CondP),
            % Continue the multi-line expression started above.
            Spinoff = context_spinoff(Command, Context, Change, CondP),
            % Continue the multi-line expression started above.
            maybe_forge_spinoff(Command, Context, Change, CondP)
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Spinoffs).

% ---------------------------------------------------------------------------
% compute_marginal/4 — P(result | command) and P(result | ¬command)
% ---------------------------------------------------------------------------

% Define a clause for 'compute marginal': succeed when the following conditions hold.
compute_marginal(Command, Change, WithP, WithoutP) :-
    % Trials WITH this command
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  trial_record(_, Command, _, _, _, _),
                  % Supply 'WithTotal' as the next argument to the expression above.
                  WithTotal),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, (
        % Continue the multi-line expression started above.
        trial_record(_, Command, Before, After, _, _),
        % Continue the multi-line expression started above.
        subtract(After, Before, ActualChange),
        % Continue the multi-line expression started above.
        ActualChange = Change
    % Continue the multi-line expression started above.
    ), WithMatches),
    % Check that '( WithTotal' is greater than '0'.
    ( WithTotal > 0
    % If the condition above succeeded, perform the following action.
    ->  WithP is WithMatches / WithTotal
    % Otherwise (else branch), perform the following action.
    ;   WithP = 0.0
    % Close the expression opened above.
    ),
    % Trials WITHOUT this command (other commands)
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, (
        % Continue the multi-line expression started above.
        trial_record(_, OtherCmd, _, _, _, _),
        % Continue the multi-line expression started above.
        OtherCmd \= Command
    % Continue the multi-line expression started above.
    ), WithoutTotal),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, (
        % Continue the multi-line expression started above.
        trial_record(_, OtherCmd, Before, After, _, _),
        % Continue the multi-line expression started above.
        OtherCmd \= Command,
        % Continue the multi-line expression started above.
        subtract(After, Before, ActualChange),
        % Continue the multi-line expression started above.
        ActualChange = Change
    % Continue the multi-line expression started above.
    ), WithoutMatches),
    % Check that '( WithoutTotal' is greater than '0'.
    ( WithoutTotal > 0
    % If the condition above succeeded, perform the following action.
    ->  WithoutP is WithoutMatches / WithoutTotal
    % Otherwise (else branch), perform the following action.
    ;   WithoutP = 0.0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% find_context_conditions/4 — find context atoms that lift reliability
% ---------------------------------------------------------------------------

% Define a clause for 'find context conditions': succeed when the following conditions hold.
find_context_conditions(Command, Change, BestContext, BestP) :-
    % Find all condition atoms that appear in any trial context
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Cond, (
        % Continue the multi-line expression started above.
        trial_record(_, Command, Before, _, _, _),
        % Continue the multi-line expression started above.
        member(Cond, Before)
    % Continue the multi-line expression started above.
    ), AllConds),
    % Sort list 'AllConds' into 'UniqConds', removing duplicates.
    sort(AllConds, UniqConds),
    % Find which condition best lifts reliability
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(P-Cond, (
        % Continue the multi-line expression started above.
        member(Cond, UniqConds),
        % Continue the multi-line expression started above.
        aggregate_all(count, (
            % Continue the multi-line expression started above.
            trial_record(_, Command, Before, After, _, _),
            % Continue the multi-line expression started above.
            member(Cond, Before),
            % Continue the multi-line expression started above.
            subtract(After, Before, ActualChange),
            % Continue the multi-line expression started above.
            ActualChange = Change
        % Continue the multi-line expression started above.
        ), WithCondMatches),
        % Continue the multi-line expression started above.
        aggregate_all(count, (
            % Continue the multi-line expression started above.
            trial_record(_, Command, Before, _, _, _),
            % Continue the multi-line expression started above.
            member(Cond, Before)
        % Continue the multi-line expression started above.
        ), WithCondTotal),
        % Continue the multi-line expression started above.
        WithCondTotal > 0,
        % Continue the multi-line expression started above.
        P is WithCondMatches / WithCondTotal
    % Continue the multi-line expression started above.
    ), CondScores),
    % Check that '( CondScores' is not unifiable with '[]'.
    ( CondScores \= []
    % If the condition above succeeded, perform the following action.
    ->  max_p(CondScores, BestP-BestCond),
        % Continue the multi-line expression started above.
        BestContext = [BestCond]
    % Otherwise (else branch), perform the following action.
    ;   BestContext = [],
        % Continue the multi-line expression started above.
        BestP = 0.0
    % Close the expression opened above.
    ).

% Define a clause for 'max p': succeed when the following conditions hold.
max_p([X], X) :- !.
% Define a clause for 'max p': succeed when the following conditions hold.
max_p([H|T], Max) :-
    % State a fact for 'max p' with the arguments listed below.
    max_p(T, MaxT),
    % Check that 'H' is unifiable with 'P-_'.
    H = P-_,
    % Check that 'MaxT' is unifiable with 'Q-_'.
    MaxT = Q-_,
    % Check that '( P' is greater than or equal to 'Q -> Max = H ; Max = MaxT )'.
    ( P >= Q -> Max = H ; Max = MaxT ).

% ---------------------------------------------------------------------------
% maybe_forge_spinoff/4 — inscribe a new causal_plan if novel
% ---------------------------------------------------------------------------

% Define a clause for 'maybe forge spinoff': succeed when the following conditions hold.
maybe_forge_spinoff(Command, Context, Result, Reliability) :-
    % Do not overwrite existing spinoff for this Command+Context+Result
    % Execute: ( spinoff_plan(_, Command, Context, Result, _).
    ( spinoff_plan(_, Command, Context, Result, _)
    % If the condition above succeeded, perform the following action.
    ->  true   % already exists (pai_accommodate semantics)
    % Otherwise (else branch), perform the following action.
    ;   next_spinoff_id(SpId),
        % Continue the multi-line expression started above.
        assertz(spinoff_plan(SpId, Command, Context, Result, Reliability)),
        % Inscribe as a node_fact in the Lattice
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            anchor_node(causal_plan,
                        % Continue the multi-line expression started above.
                        [spinoff(SpId), Command, Context, Result],
                        % Continue the multi-line expression started above.
                        [reliability=Reliability],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Attribution miner actor cycle
% ---------------------------------------------------------------------------

% Execute: attribution_miner_cycle :-.
attribution_miner_cycle :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( default_nexus(Nexus),
          % Continue the multi-line expression started above.
          nexus_is_open(Nexus),
          % Find all commands that have enough trials
          % Continue the multi-line expression started above.
          findall(C, trial_record(_, C, _, _, _, _), AllCmds),
          % Continue the multi-line expression started above.
          sort(AllCmds, UniqCmds),
          % Continue the multi-line expression started above.
          forall(
              % Continue the multi-line expression started above.
              member(Cmd, UniqCmds),
              % Continue the multi-line expression started above.
              ( aggregate_all(count, trial_record(_, Cmd, _, _, _, _), N),
                % Continue the multi-line expression started above.
                ( N >= 5
                % If the condition above succeeded, perform the following action.
                ->  catch(pai_spinoff_mine(Cmd, _), _, true)
                % Otherwise (else branch), perform the following action.
                ;   true
                % Close the expression opened above.
                )
              % Close the expression opened above.
              )
          % Close the expression opened above.
          )
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Execute: install_attribution_miner :-.
install_attribution_miner :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        cyclic_actor(attribution_miner_actor,
                     % Supply 'spinoff:attribution_miner_cycle' as the next argument to the expression above.
                     spinoff:attribution_miner_cycle,
                     % Supply '30000' as the next argument to the expression above.
                     30000),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Execute: uninstall_attribution_miner :-.
uninstall_attribution_miner :-
    % State the fact: catch(cyclic_actor_stop(attribution_miner_actor), _, true).
    catch(cyclic_actor_stop(attribution_miner_actor), _, true).
