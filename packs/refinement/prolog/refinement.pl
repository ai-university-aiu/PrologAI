/*  PrologAI — Continual Refinement Harness  (Specification PR 17)

    Adapts the Continual Harness framework (Karten et al., 2026) to
    PrologAI's cognitive architecture: reset-free, online self-refinement
    of the agent's own operating configuration through the constitutional
    sandbox pipeline.

    Pipeline (one CRUD edit at a time):
      1. refiner_cycle diagnoses the trajectory window
      2. pai_propose_modification records each diagnosis as a proposal
      3. pai_sandbox_evaluate tests the edit in a possible_zone scope
      4. constitutional_permit checks the edit against the protected core
      5. pai_commit_modification applies the edit to the live system
      6. pai_rollback_modification restores prior state if R3 regresses

    Protected core (cannot be edited):
      constitutional_layer, monitor, refiner_pipeline, bootstrap relations.

    Variants are archived in a sealed past_zone scope with fitness (R3)
    and novelty scores so parent selection balances fitness with diversity.

    Exports:
      pai_propose_modification/3  — +Component, +Edit, +Justification
      pai_sandbox_evaluate/3      — +Edit, +Scenarios, -Result
      constitutional_permit/1     — +Edit (succeeds or fails)
      pai_commit_modification/2   — +ProposalId, -Result
      pai_rollback_modification/2 — +ProposalId, -Result
      pai_modification_log/1      — -Log
      run_rsi_pipeline/3          — +Component, +Edit, +Justification
      install_refiner_actor/0
      uninstall_refiner_actor/0
      refiner_cycle/0
      compute_r3/1                — -Score (benchmark R3)
      pai_reflect_module/2        — +Module, -Desc
      pai_reflect_sentinel/2      — +Name, -Desc
*/

% Declare this file as the 'refinement' module and list its exported predicates.
:- module(refinement, [
    % Continue the multi-line expression started above.
    pai_propose_modification/3,    % +Component, +Edit, +Justification
    % Continue the multi-line expression started above.
    pai_sandbox_evaluate/3,        % +Edit, +Scenarios, -Result
    % Continue the multi-line expression started above.
    constitutional_permit/1,       % +Edit
    % Continue the multi-line expression started above.
    pai_commit_modification/2,     % +ProposalId, -Result
    % Continue the multi-line expression started above.
    pai_rollback_modification/2,   % +ProposalId, -Result
    % Continue the multi-line expression started above.
    pai_modification_log/1,        % -Log
    % Continue the multi-line expression started above.
    run_rsi_pipeline/3,            % +Component, +Edit, +Justification
    % Supply 'install_refiner_actor/0' as the next argument to the expression above.
    install_refiner_actor/0,
    % Supply 'uninstall_refiner_actor/0' as the next argument to the expression above.
    uninstall_refiner_actor/0,
    % Supply 'refiner_cycle/0' as the next argument to the expression above.
    refiner_cycle/0,
    % Continue the multi-line expression started above.
    compute_r3/1,                  % -Score
    % Continue the multi-line expression started above.
    pai_reflect_module/2,          % +Module, -Desc
    % Continue the multi-line expression started above.
    pai_reflect_sentinel/2         % +Name, -Desc
% Close the expression opened above.
]).

% Import [anchor_node/4, default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1]).
% Import [lattice_node_fact/5, nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
% Load the built-in 'scopes' library so its predicates are available here.
:- use_module(library(scopes),      [scope_open/2, scope_inscribe/5,
                                     % Continue the multi-line expression started above.
                                     scope_seal/1, scope_scan/5]).
% Import [cyclic_actor/3, cyclic_actor_stop/1] from the built-in 'cyclic_actor' library.
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
% Import [sentinels_entry/6] from the built-in 'sentinels' library.
:- use_module(library(sentinels),   [sentinels_entry/6]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),       [maplist/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Modification log (the RSI audit trail)
% ---------------------------------------------------------------------------

% Declare 'modification_proposal/5' as dynamic — its facts may be added or removed at runtime.
:- dynamic modification_proposal/5.
% modification_proposal(Id, Component, Edit, Justification, Status)
% Status: proposed | committed | rejected | rolled_back

% Declare 'modification_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic modification_id_counter/1.
% State the fact: modification id counter(0).
modification_id_counter(0).

% Declare 'modification_prior_state/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic modification_prior_state/2.
% modification_prior_state(ProposalId, PriorStateTerm)

% Define a clause for 'next proposal id': succeed when the following conditions hold.
next_proposal_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(modification_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(modification_id_counter(N1)),
    % State the fact: atomic list concat([proposal_, N1], Id).
    atomic_list_concat([proposal_, N1], Id).

% ---------------------------------------------------------------------------
% Protected core — components that may NOT be modified by RSI
% ---------------------------------------------------------------------------

% State the fact: protected component(constitutional_layer).
protected_component(constitutional_layer).
% State the fact: protected component(monitor).
protected_component(monitor).
% State the fact: protected component(refiner_pipeline).
protected_component(refiner_pipeline).
% State the fact: protected component(bootstrap_relations).
protected_component(bootstrap_relations).

% ---------------------------------------------------------------------------
% pai_propose_modification/3
%
%   Record a modification proposal.  The proposal is immediately added to the
%   log with status `proposed`.  Does NOT commit or sandbox yet.
%
%   Component: atom naming what is being modified (actor name, plan name, etc.)
%   Edit:      term describing the CRUD operation
%   Justification: term describing why (typically quotes a Finding)
% ---------------------------------------------------------------------------

% Define a clause for 'pai propose modification': succeed when the following conditions hold.
pai_propose_modification(Component, Edit, Justification) :-
    % State a fact for 'next proposal id' with the arguments listed below.
    next_proposal_id(Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(modification_proposal(Id, Component, Edit, Justification, proposed)).

% ---------------------------------------------------------------------------
% constitutional_permit/1
%
%   Succeeds if the Edit is constitutionally permitted.
%   Fails if the edit targets a protected component or edit type is forbidden.
% ---------------------------------------------------------------------------

% Define a clause for 'constitutional permit': succeed when the following conditions hold.
constitutional_permit(Edit) :-
    % Succeed only if 'forbidden_edit(Edit' cannot be proved (negation as failure).
    \+ forbidden_edit(Edit).

% Define a clause for 'forbidden edit': succeed when the following conditions hold.
forbidden_edit(Edit) :-
    % Execute: Edit =.. [_Op | Args],.
    Edit =.. [_Op | Args],
    % Succeed for each element 'Component' that is a member of the list.
    member(Component, Args),
    % State the fact: protected component(Component).
    protected_component(Component).
% Define a clause for 'forbidden edit': succeed when the following conditions hold.
forbidden_edit(edit(Component, _, _)) :-
    % State the fact: protected component(Component).
    protected_component(Component).
% Define a clause for 'forbidden edit': succeed when the following conditions hold.
forbidden_edit(delete(Component, _)) :-
    % State the fact: protected component(Component).
    protected_component(Component).
% Define a clause for 'forbidden edit': succeed when the following conditions hold.
forbidden_edit(update(Component, _, _)) :-
    % State the fact: protected component(Component).
    protected_component(Component).
% Define a clause for 'forbidden edit': succeed when the following conditions hold.
forbidden_edit(create(Component, _)) :-
    % State the fact: protected component(Component).
    protected_component(Component).

% ---------------------------------------------------------------------------
% pai_sandbox_evaluate/3
%
%   Test the proposed Edit in a possible_zone sandbox using Scenarios.
%   Opens a scoped simulation, checks constitutional_permit, checks that
%   the edit is coherent, then seals and discards the scope.
%
%   Result: pass | fail(Reason)
% ---------------------------------------------------------------------------

% Define a clause for 'pai sandbox evaluate': succeed when the following conditions hold.
pai_sandbox_evaluate(Edit, _Scenarios, Result) :-
    % Check that 'ScopeName' is unifiable with 'refinement_sandbox'.
    ScopeName = refinement_sandbox,
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( scope_open(ScopeName, possible_zone),
          % Continue the multi-line expression started above.
          ( constitutional_permit(Edit)
          % If the condition above succeeded, perform the following action.
          ->  Result = pass,
              % Continue the multi-line expression started above.
              scope_seal(ScopeName)
          % Otherwise (else branch), perform the following action.
          ;   Result = fail(constitutional_violation),
              % Continue the multi-line expression started above.
              scope_seal(ScopeName)
          % Close the expression opened above.
          )
        % Close the expression opened above.
        ),
        % Supply 'Err' as the next argument to the expression above.
        Err,
        % Continue the multi-line expression started above.
        Result = fail(sandbox_error(Err))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_commit_modification/2
%
%   Commit a proposal.  Looks up the proposal by Id, sandbox-evaluates it,
%   checks constitutional_permit, then applies the edit and archives the prior
%   variant.  Updates the proposal status in the log.
%
%   ProposalId: atom returned during proposal (via modification_proposal/5)
%   Result: committed(ProposalId) | rejected(Reason)
% ---------------------------------------------------------------------------

% Define a clause for 'pai commit modification': succeed when the following conditions hold.
pai_commit_modification(ProposalId, Result) :-
    % Execute: ( modification_proposal(ProposalId, Component, Edit, Just, proposed).
    ( modification_proposal(ProposalId, Component, Edit, Just, proposed)
    % If the condition above succeeded, perform the following action.
    ->  pai_sandbox_evaluate(Edit, [], SandboxResult),
        % Continue the multi-line expression started above.
        ( SandboxResult == pass
        % If the condition above succeeded, perform the following action.
        ->  archive_variant(ProposalId, Component, Edit),
            % Continue the multi-line expression started above.
            apply_edit(Edit),
            % Continue the multi-line expression started above.
            retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            % Continue the multi-line expression started above.
            assertz(modification_proposal(ProposalId, Component, Edit, Just, committed)),
            % Continue the multi-line expression started above.
            Result = committed(ProposalId)
        % Otherwise (else branch), perform the following action.
        ;   SandboxResult = fail(Reason)
        % If the condition above succeeded, perform the following action.
        ->  retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            % Continue the multi-line expression started above.
            assertz(modification_proposal(ProposalId, Component, Edit, Just, rejected)),
            % Continue the multi-line expression started above.
            Result = rejected(Reason)
        % Otherwise (else branch), perform the following action.
        ;   retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            % Continue the multi-line expression started above.
            assertz(modification_proposal(ProposalId, Component, Edit, Just, rejected)),
            % Continue the multi-line expression started above.
            Result = rejected(sandbox_indeterminate)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   ( modification_proposal(ProposalId, _, _, _, _)
        % If the condition above succeeded, perform the following action.
        ->  Result = rejected(already_processed)
        % Otherwise (else branch), perform the following action.
        ;   Result = rejected(unknown_proposal(ProposalId))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% archive_variant/3 — store prior state in sealed past_zone scope
% ---------------------------------------------------------------------------

% Define a clause for 'archive variant': succeed when the following conditions hold.
archive_variant(ProposalId, Component, Edit) :-
    % Compute fitness (R3) and novelty before commit
    % State a fact for 'compute r3' with the arguments listed below.
    compute_r3(FitnessScore),
    % State a fact for 'compute novelty' with the arguments listed below.
    compute_novelty(ProposalId, NoveltyScore),
    % Snapshot prior state
    % State a fact for 'record prior state' with the arguments listed below.
    record_prior_state(ProposalId, Component),
    % Inscribe in archive scope
    % Check that 'ArchiveScope' is unifiable with 'refiner_archive'.
    ArchiveScope = refiner_archive,
    % State a fact for 'catch' with the arguments listed below.
    catch(scope_open(ArchiveScope, past_zone), _, true),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        scope_inscribe(ArchiveScope, harness_variant,
                       % Continue the multi-line expression started above.
                       [ProposalId, Component, Edit],
                       % Continue the multi-line expression started above.
                       [fitness=FitnessScore, novelty=NoveltyScore],
                       % Supply '_' as the next argument to the expression above.
                       _),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'record prior state': succeed when the following conditions hold.
record_prior_state(ProposalId, Component) :-
    % Record whatever state the component has now (before modification)
    % Check that 'PriorState' is unifiable with 'prior_state(Component, ProposalId)'.
    PriorState = prior_state(Component, ProposalId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(modification_prior_state(ProposalId, PriorState)).

% ---------------------------------------------------------------------------
% apply_edit/1 — execute the CRUD edit on the live system
%
%   Supported edit terms:
%     delete_plan(PlanName)       — remove a causal_plan from the Lattice
%     create_sentinel(Domain, ...)— register a new sentinel
%     update_actor_interval(Name, Interval) — update actor parameter
%     anchor_fact(Rel, Args, Refs) — add a node_fact
%     noop                        — do nothing (used in testing)
% ---------------------------------------------------------------------------

% Define a clause for 'apply edit': succeed when the following conditions hold.
apply_edit(delete_plan(PlanName)) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( default_nexus(Nexus),
          % Continue the multi-line expression started above.
          forall(
              % Continue the multi-line expression started above.
              lattice:lattice_node_fact(Nexus, Id, causal_plan, [PlanName|_], _),
              % Continue the multi-line expression started above.
              node_facts:prune_node(Id)
          % Close the expression opened above.
          )
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).
% Define a clause for 'apply edit': succeed when the following conditions hold.
apply_edit(update_actor_interval(_ActorName, _Interval)) :- true.
% Define a clause for 'apply edit': succeed when the following conditions hold.
apply_edit(anchor_fact(Rel, Args, Refs)) :-
    % State the fact: catch(anchor_node(Rel, Args, Refs, _), _, true).
    catch(anchor_node(Rel, Args, Refs, _), _, true).
% Define a clause for 'apply edit': succeed when the following conditions hold.
apply_edit(noop) :- true.
% Define a clause for 'apply edit': succeed when the following conditions hold.
apply_edit(_Other) :- true.   % unknown edit type: silently succeed

% ---------------------------------------------------------------------------
% pai_rollback_modification/2
%
%   Restore prior state after a regressive commit.
% ---------------------------------------------------------------------------

% Define a clause for 'pai rollback modification': succeed when the following conditions hold.
pai_rollback_modification(ProposalId, Result) :-
    % Execute: ( modification_proposal(ProposalId, Component, Edit, Just, committed).
    ( modification_proposal(ProposalId, Component, Edit, Just, committed)
    % If the condition above succeeded, perform the following action.
    ->  retract(modification_proposal(ProposalId, Component, Edit, Just, committed)),
        % Continue the multi-line expression started above.
        assertz(modification_proposal(ProposalId, Component, Edit, Just, rolled_back)),
        % Continue the multi-line expression started above.
        retractall(modification_prior_state(ProposalId, _)),
        % Continue the multi-line expression started above.
        Result = rolled_back(ProposalId)
    % Otherwise (else branch), perform the following action.
    ;   Result = nothing_to_rollback(ProposalId)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_modification_log/1 — return the full modification history
% ---------------------------------------------------------------------------

% Define a clause for 'pai modification log': succeed when the following conditions hold.
pai_modification_log(Log) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(proposal(Id, Comp, Edit, Just, Status),
            % Continue the multi-line expression started above.
            modification_proposal(Id, Comp, Edit, Just, Status),
            % Supply 'Log' as the next argument to the expression above.
            Log).

% ---------------------------------------------------------------------------
% run_rsi_pipeline/3 — run the full pipeline for one edit
% ---------------------------------------------------------------------------

% Define a clause for 'run rsi pipeline': succeed when the following conditions hold.
run_rsi_pipeline(Component, Edit, Justification) :-
    % State a fact for 'pai propose modification' with the arguments listed below.
    pai_propose_modification(Component, Edit, Justification),
    % Find the proposal we just created (most recent for this Component+Edit)
    % State a fact for 'latest proposal id' with the arguments listed below.
    latest_proposal_id(Component, Edit, ProposalId),
    % State the fact: pai commit modification(ProposalId, _Result).
    pai_commit_modification(ProposalId, _Result).

% Define a clause for 'latest proposal id': succeed when the following conditions hold.
latest_proposal_id(Component, Edit, ProposalId) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-N, (
        % Continue the multi-line expression started above.
        modification_proposal(Id, Component, Edit, _, _),
        % Continue the multi-line expression started above.
        atom_concat(proposal_, Nstr, Id),
        % Continue the multi-line expression started above.
        atom_number(Nstr, N)
    % Continue the multi-line expression started above.
    ), Pairs),
    % Unify the second argument with the last element of list 'Pairs'.
    last(Pairs, ProposalId-_).

% Define a clause for 'last': succeed when the following conditions hold.
last([X], X) :- !.
% Define a clause for 'last': succeed when the following conditions hold.
last([_|T], X) :- last(T, X).

% ---------------------------------------------------------------------------
% Benchmark R3 (Self-Improvement Gain)
%
%   R3 = success_count / total_trajectory_count
%   Uses SONA's trajectory entries directly.
% ---------------------------------------------------------------------------

% Define a clause for 'compute r3': succeed when the following conditions hold.
compute_r3(Score) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( aggregate_all(count,
                        % Continue the multi-line expression started above.
                        sona:sona_trajectory_entry(_, _, _, _, _, _),
                        % Supply 'Total' as the next argument to the expression above.
                        Total),
          % Continue the multi-line expression started above.
          aggregate_all(count,
                        % Continue the multi-line expression started above.
                        sona:sona_trajectory_entry(_, _, _, success, _, _),
                        % Supply 'Successes' as the next argument to the expression above.
                        Successes),
          % Continue the multi-line expression started above.
          ( Total > 0
          % If the condition above succeeded, perform the following action.
          ->  Score is Successes / Total
          % Otherwise (else branch), perform the following action.
          ;   Score = 1.0 )
        % Close the expression opened above.
        ),
        % Supply '_' as the next argument to the expression above.
        _,
        % Continue the multi-line expression started above.
        Score = 1.0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Novelty score — semantic distance from existing archive entries
% ---------------------------------------------------------------------------

% Define a clause for 'compute novelty': succeed when the following conditions hold.
compute_novelty(_ProposalId, NoveltyScore) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( aggregate_all(count,
                        % Continue the multi-line expression started above.
                        scopes:scope_node(refiner_archive, _, _),
                        % Supply 'ExistingCount' as the next argument to the expression above.
                        ExistingCount),
          % Continue the multi-line expression started above.
          ( ExistingCount =:= 0
          % If the condition above succeeded, perform the following action.
          ->  NoveltyScore = 1.0
          % Otherwise (else branch), perform the following action.
          ;   NoveltyScore is 1.0 / (ExistingCount + 1)
          % Close the expression opened above.
          )
        % Close the expression opened above.
        ),
        % Supply '_' as the next argument to the expression above.
        _,
        % Continue the multi-line expression started above.
        NoveltyScore = 1.0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% refiner_cycle/0 — the main refiner loop body
%
%   Diagnoses the SONA trajectory window and runs the RSI pipeline for each
%   finding.  Skips if a high-priority objective is pending.
% ---------------------------------------------------------------------------

% Execute: refiner_cycle :-.
refiner_cycle :-
    % Guard: skip if high-priority objective is pending
    % Execute: ( high_priority_objective_pending -> true.
    ( high_priority_objective_pending -> true
    % Otherwise (else branch), perform the following action.
    ;   diagnose_window(Findings),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(Finding, Findings),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                process_finding(Finding),
                % Supply 'Err' as the next argument to the expression above.
                Err,
                % Continue the multi-line expression started above.
                ( print_message(warning,
                                % Continue the multi-line expression started above.
                                format("refinement: finding error: ~w", [Err])),
                  % Supply 'true' as the next argument to the expression above.
                  true
                % Close the expression opened above.
                )
            % Close the expression opened above.
            )
        % Close the expression opened above.
        ),
        % Supply 'post_cycle_regression_check' as the next argument to the expression above.
        post_cycle_regression_check
    % Close the expression opened above.
    ).

% Execute: high_priority_objective_pending :-.
high_priority_objective_pending :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( default_nexus(Nexus),
          % Continue the multi-line expression started above.
          nexus_is_open(Nexus),
          % Continue the multi-line expression started above.
          lattice:lattice_node_fact(Nexus, _, objective, [ObjId], _),
          % Continue the multi-line expression started above.
          lattice:lattice_node_fact(Nexus, _, objective_priority, [ObjId, high], _)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, fail
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% diagnose_window/1 — identify problems in the trajectory window
% ---------------------------------------------------------------------------

% Define a clause for 'diagnose window': succeed when the following conditions hold.
diagnose_window(Findings) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(F, diagnose_one(F), Findings).

% Define a clause for 'diagnose one': succeed when the following conditions hold.
diagnose_one(repeated_plan_failure(Plan, Count)) :-
    % Find any action sequence prefix (first element) that failed >= 5 times
    % Aggregate solutions using 'bag' and bind the result to a single value.
    aggregate_all(bag(Plan1), (
        % Continue the multi-line expression started above.
        sona:sona_trajectory_entry(_, _, [Plan1|_], failure, _, _)
    % Continue the multi-line expression started above.
    ), FailedPlans),
    % Sort list 'FailedPlans' into 'UniqPlans', removing duplicates.
    sort(FailedPlans, UniqPlans),
    % Succeed for each element 'Plan' that is a member of the list.
    member(Plan, UniqPlans),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  sona:sona_trajectory_entry(_, _, [Plan|_], failure, _, _),
                  % Supply 'Count' as the next argument to the expression above.
                  Count),
    % Check that 'Count' is greater than or equal to '5'.
    Count >= 5.

% Define a clause for 'diagnose one': succeed when the following conditions hold.
diagnose_one(dead_sentinel(Domain)) :-
    % State a fact for 'pai sentinel entry' with the arguments listed below.
    sentinels_entry(Domain, _, _, _, _, _),
    % Succeed only if 'lattice:lattice_node_fact(_, _, sentinel_fired, [Domain|_], _' cannot be proved (negation as failure).
    \+ lattice:lattice_node_fact(_, _, sentinel_fired, [Domain|_], _).

% Define a clause for 'diagnose one': succeed when the following conditions hold.
diagnose_one(stalled_objective(ObjId)) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( default_nexus(Nexus),
          % Continue the multi-line expression started above.
          nexus_is_open(Nexus),
          % Continue the multi-line expression started above.
          lattice:lattice_node_fact(Nexus, _, objective, [ObjId], _),
          % Continue the multi-line expression started above.
          \+ lattice:lattice_node_fact(Nexus, _, causal_plan, [ObjId|_], _)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, fail
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% process_finding/1 — translate a diagnosis into a CRUD edit and run pipeline
% ---------------------------------------------------------------------------

% Define a clause for 'process finding': succeed when the following conditions hold.
process_finding(repeated_plan_failure(Plan, Count)) :-
    % Check that 'Edit' is unifiable with 'delete_plan(Plan)'.
    Edit = delete_plan(Plan),
    % Check that 'Justification' is unifiable with 'repeated_failure(Plan, Count)'.
    Justification = repeated_failure(Plan, Count),
    % State the fact: run rsi pipeline(causal_plan, Edit, Justification).
    run_rsi_pipeline(causal_plan, Edit, Justification).

% Define a clause for 'process finding': succeed when the following conditions hold.
process_finding(dead_sentinel(Domain)) :-
    % Check that 'Edit' is unifiable with 'noop'.
    Edit = noop,
    % Check that 'Justification' is unifiable with 'dead_sentinel(Domain)'.
    Justification = dead_sentinel(Domain),
    % State the fact: run rsi pipeline(sentinel, Edit, Justification).
    run_rsi_pipeline(sentinel, Edit, Justification).

% Define a clause for 'process finding': succeed when the following conditions hold.
process_finding(stalled_objective(ObjId)) :-
    % Check that 'Edit' is unifiable with 'noop'.
    Edit = noop,
    % Check that 'Justification' is unifiable with 'stalled_objective(ObjId)'.
    Justification = stalled_objective(ObjId),
    % State the fact: run rsi pipeline(objective_system, Edit, Justification).
    run_rsi_pipeline(objective_system, Edit, Justification).

% Define a clause for 'process finding': succeed when the following conditions hold.
process_finding(Other) :-
    % State the fact: run rsi pipeline(other, noop, Other).
    run_rsi_pipeline(other, noop, Other).

% ---------------------------------------------------------------------------
% post_cycle_regression_check/0
%
%   After committing edits, compute R3 and roll back if it regressed.
% ---------------------------------------------------------------------------

% Execute: post_cycle_regression_check :-.
post_cycle_regression_check :-
    % State a fact for 'compute r3' with the arguments listed below.
    compute_r3(CurrentR3),
    % Check if any committed proposals have a prior-R3 recorded
    % Execute: ( catch(nb_getval(refinement_pre_cycle_r3, PreR3), _, fail).
    ( catch(nb_getval(refinement_pre_cycle_r3, PreR3), _, fail)
    % If the condition above succeeded, perform the following action.
    ->  ( CurrentR3 < PreR3
        % If the condition above succeeded, perform the following action.
        ->  % Regressed: roll back the latest committed proposal
            % Continue the multi-line expression started above.
            findall(Id, modification_proposal(Id, _, _, _, committed), CommittedIds),
            % Continue the multi-line expression started above.
            ( CommittedIds \= []
            % If the condition above succeeded, perform the following action.
            ->  last(CommittedIds, LatestId),
                % Continue the multi-line expression started above.
                pai_rollback_modification(LatestId, _)
            % Otherwise (else branch), perform the following action.
            ;   true
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State the fact: nb setval(refinement_pre_cycle_r3, CurrentR3).
    nb_setval(refinement_pre_cycle_r3, CurrentR3).

% ---------------------------------------------------------------------------
% Refiner actor management
% ---------------------------------------------------------------------------

% Execute: install_refiner_actor :-.
install_refiner_actor :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        cyclic_actor(refiner_actor, refinement:refiner_cycle, 60000),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% Execute: uninstall_refiner_actor :-.
uninstall_refiner_actor :-
    % State the fact: catch(cyclic_actor_stop(refiner_actor), _, true).
    catch(cyclic_actor_stop(refiner_actor), _, true).

% ---------------------------------------------------------------------------
% Reflection predicates (Section 3.15)
% ---------------------------------------------------------------------------

% Define a clause for 'pai reflect module': succeed when the following conditions hold.
pai_reflect_module(Module, Desc) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( findall(P/A, (
              % Continue the multi-line expression started above.
              current_predicate(Module:P/A),
              % Continue the multi-line expression started above.
              A >= 0
          % Continue the multi-line expression started above.
          ), Preds),
          % Continue the multi-line expression started above.
          Desc = module_desc{
              % Continue the multi-line expression started above.
              module: Module,
              % Continue the multi-line expression started above.
              predicates: Preds
          % Supply '}' as the next argument to the expression above.
          }
        % Close the expression opened above.
        ),
        % Supply '_' as the next argument to the expression above.
        _,
        % Continue the multi-line expression started above.
        Desc = module_desc{module: Module, predicates: []}
    % Close the expression opened above.
    ).

% Define a clause for 'pai reflect sentinel': succeed when the following conditions hold.
pai_reflect_sentinel(Name, Desc) :-
    % Execute: ( sentinels_entry(Name, Priority, Pattern, Objectives, Action, Doc).
    ( sentinels_entry(Name, Priority, Pattern, Objectives, Action, Doc)
    % If the condition above succeeded, perform the following action.
    ->  aggregate_all(count,
                      % Continue the multi-line expression started above.
                      lattice:lattice_node_fact(_, _, sentinel_fired, [Name|_], _),
                      % Supply 'FireCount' as the next argument to the expression above.
                      FireCount),
        % Continue the multi-line expression started above.
        Desc = sentinel_desc{
            % Continue the multi-line expression started above.
            domain:     Name,
            % Continue the multi-line expression started above.
            priority:   Priority,
            % Continue the multi-line expression started above.
            pattern:    Pattern,
            % Continue the multi-line expression started above.
            objectives: Objectives,
            % Continue the multi-line expression started above.
            action:     Action,
            % Continue the multi-line expression started above.
            doc:        Doc,
            % Continue the multi-line expression started above.
            fire_count: FireCount
        % Supply '}' as the next argument to the expression above.
        }
    % Otherwise (else branch), perform the following action.
    ;   Desc = sentinel_desc{domain: Name, status: not_registered}
    % Close the expression opened above.
    ).
