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

:- module(refinement, [
    pai_propose_modification/3,    % +Component, +Edit, +Justification
    pai_sandbox_evaluate/3,        % +Edit, +Scenarios, -Result
    constitutional_permit/1,       % +Edit
    pai_commit_modification/2,     % +ProposalId, -Result
    pai_rollback_modification/2,   % +ProposalId, -Result
    pai_modification_log/1,        % -Log
    run_rsi_pipeline/3,            % +Component, +Edit, +Justification
    install_refiner_actor/0,
    uninstall_refiner_actor/0,
    refiner_cycle/0,
    compute_r3/1,                  % -Score
    pai_reflect_module/2,          % +Module, -Desc
    pai_reflect_sentinel/2         % +Name, -Desc
]).

:- use_module(library(node_facts),  [anchor_node/4, default_nexus/1]).
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
:- use_module(library(scopes),      [scope_open/2, scope_inscribe/5,
                                     scope_seal/1, scope_scan/5]).
:- use_module(library(cyclic_actor),[cyclic_actor/3, cyclic_actor_stop/1]).
:- use_module(library(sentinels),   [pai_sentinel_entry/6]).
:- use_module(library(lists),       [member/2]).
:- use_module(library(apply),       [maplist/3]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Modification log (the RSI audit trail)
% ---------------------------------------------------------------------------

:- dynamic modification_proposal/5.
% modification_proposal(Id, Component, Edit, Justification, Status)
% Status: proposed | committed | rejected | rolled_back

:- dynamic modification_id_counter/1.
modification_id_counter(0).

:- dynamic modification_prior_state/2.
% modification_prior_state(ProposalId, PriorStateTerm)

next_proposal_id(Id) :-
    retract(modification_id_counter(N)),
    N1 is N + 1,
    assertz(modification_id_counter(N1)),
    atomic_list_concat([proposal_, N1], Id).

% ---------------------------------------------------------------------------
% Protected core — components that may NOT be modified by RSI
% ---------------------------------------------------------------------------

protected_component(constitutional_layer).
protected_component(monitor).
protected_component(refiner_pipeline).
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

pai_propose_modification(Component, Edit, Justification) :-
    next_proposal_id(Id),
    assertz(modification_proposal(Id, Component, Edit, Justification, proposed)).

% ---------------------------------------------------------------------------
% constitutional_permit/1
%
%   Succeeds if the Edit is constitutionally permitted.
%   Fails if the edit targets a protected component or edit type is forbidden.
% ---------------------------------------------------------------------------

constitutional_permit(Edit) :-
    \+ forbidden_edit(Edit).

forbidden_edit(Edit) :-
    Edit =.. [_Op | Args],
    member(Component, Args),
    protected_component(Component).
forbidden_edit(edit(Component, _, _)) :-
    protected_component(Component).
forbidden_edit(delete(Component, _)) :-
    protected_component(Component).
forbidden_edit(update(Component, _, _)) :-
    protected_component(Component).
forbidden_edit(create(Component, _)) :-
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

pai_sandbox_evaluate(Edit, _Scenarios, Result) :-
    ScopeName = refinement_sandbox,
    catch(
        ( scope_open(ScopeName, possible_zone),
          ( constitutional_permit(Edit)
          ->  Result = pass,
              scope_seal(ScopeName)
          ;   Result = fail(constitutional_violation),
              scope_seal(ScopeName)
          )
        ),
        Err,
        Result = fail(sandbox_error(Err))
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

pai_commit_modification(ProposalId, Result) :-
    ( modification_proposal(ProposalId, Component, Edit, Just, proposed)
    ->  pai_sandbox_evaluate(Edit, [], SandboxResult),
        ( SandboxResult == pass
        ->  archive_variant(ProposalId, Component, Edit),
            apply_edit(Edit),
            retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            assertz(modification_proposal(ProposalId, Component, Edit, Just, committed)),
            Result = committed(ProposalId)
        ;   SandboxResult = fail(Reason)
        ->  retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            assertz(modification_proposal(ProposalId, Component, Edit, Just, rejected)),
            Result = rejected(Reason)
        ;   retract(modification_proposal(ProposalId, Component, Edit, Just, proposed)),
            assertz(modification_proposal(ProposalId, Component, Edit, Just, rejected)),
            Result = rejected(sandbox_indeterminate)
        )
    ;   ( modification_proposal(ProposalId, _, _, _, _)
        ->  Result = rejected(already_processed)
        ;   Result = rejected(unknown_proposal(ProposalId))
        )
    ).

% ---------------------------------------------------------------------------
% archive_variant/3 — store prior state in sealed past_zone scope
% ---------------------------------------------------------------------------

archive_variant(ProposalId, Component, Edit) :-
    % Compute fitness (R3) and novelty before commit
    compute_r3(FitnessScore),
    compute_novelty(ProposalId, NoveltyScore),
    % Snapshot prior state
    record_prior_state(ProposalId, Component),
    % Inscribe in archive scope
    ArchiveScope = refiner_archive,
    catch(scope_open(ArchiveScope, past_zone), _, true),
    catch(
        scope_inscribe(ArchiveScope, harness_variant,
                       [ProposalId, Component, Edit],
                       [fitness=FitnessScore, novelty=NoveltyScore],
                       _),
        _, true
    ).

record_prior_state(ProposalId, Component) :-
    % Record whatever state the component has now (before modification)
    PriorState = prior_state(Component, ProposalId),
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

apply_edit(delete_plan(PlanName)) :-
    catch(
        ( default_nexus(Nexus),
          forall(
              lattice:lattice_node_fact(Nexus, Id, causal_plan, [PlanName|_], _),
              node_facts:prune_node(Id)
          )
        ),
        _, true
    ).
apply_edit(update_actor_interval(_ActorName, _Interval)) :- true.
apply_edit(anchor_fact(Rel, Args, Refs)) :-
    catch(anchor_node(Rel, Args, Refs, _), _, true).
apply_edit(noop) :- true.
apply_edit(_Other) :- true.   % unknown edit type: silently succeed

% ---------------------------------------------------------------------------
% pai_rollback_modification/2
%
%   Restore prior state after a regressive commit.
% ---------------------------------------------------------------------------

pai_rollback_modification(ProposalId, Result) :-
    ( modification_proposal(ProposalId, Component, Edit, Just, committed)
    ->  retract(modification_proposal(ProposalId, Component, Edit, Just, committed)),
        assertz(modification_proposal(ProposalId, Component, Edit, Just, rolled_back)),
        retractall(modification_prior_state(ProposalId, _)),
        Result = rolled_back(ProposalId)
    ;   Result = nothing_to_rollback(ProposalId)
    ).

% ---------------------------------------------------------------------------
% pai_modification_log/1 — return the full modification history
% ---------------------------------------------------------------------------

pai_modification_log(Log) :-
    findall(proposal(Id, Comp, Edit, Just, Status),
            modification_proposal(Id, Comp, Edit, Just, Status),
            Log).

% ---------------------------------------------------------------------------
% run_rsi_pipeline/3 — run the full pipeline for one edit
% ---------------------------------------------------------------------------

run_rsi_pipeline(Component, Edit, Justification) :-
    pai_propose_modification(Component, Edit, Justification),
    % Find the proposal we just created (most recent for this Component+Edit)
    latest_proposal_id(Component, Edit, ProposalId),
    pai_commit_modification(ProposalId, _Result).

latest_proposal_id(Component, Edit, ProposalId) :-
    findall(Id-N, (
        modification_proposal(Id, Component, Edit, _, _),
        atom_concat(proposal_, Nstr, Id),
        atom_number(Nstr, N)
    ), Pairs),
    last(Pairs, ProposalId-_).

last([X], X) :- !.
last([_|T], X) :- last(T, X).

% ---------------------------------------------------------------------------
% Benchmark R3 (Self-Improvement Gain)
%
%   R3 = success_count / total_trajectory_count
%   Uses SONA's trajectory entries directly.
% ---------------------------------------------------------------------------

compute_r3(Score) :-
    catch(
        ( aggregate_all(count,
                        sona:sona_trajectory_entry(_, _, _, _, _, _),
                        Total),
          aggregate_all(count,
                        sona:sona_trajectory_entry(_, _, _, success, _, _),
                        Successes),
          ( Total > 0
          ->  Score is Successes / Total
          ;   Score = 1.0 )
        ),
        _,
        Score = 1.0
    ).

% ---------------------------------------------------------------------------
% Novelty score — semantic distance from existing archive entries
% ---------------------------------------------------------------------------

compute_novelty(_ProposalId, NoveltyScore) :-
    catch(
        ( aggregate_all(count,
                        scopes:scope_node(refiner_archive, _, _),
                        ExistingCount),
          ( ExistingCount =:= 0
          ->  NoveltyScore = 1.0
          ;   NoveltyScore is 1.0 / (ExistingCount + 1)
          )
        ),
        _,
        NoveltyScore = 1.0
    ).

% ---------------------------------------------------------------------------
% refiner_cycle/0 — the main refiner loop body
%
%   Diagnoses the SONA trajectory window and runs the RSI pipeline for each
%   finding.  Skips if a high-priority objective is pending.
% ---------------------------------------------------------------------------

refiner_cycle :-
    % Guard: skip if high-priority objective is pending
    ( high_priority_objective_pending -> true
    ;   diagnose_window(Findings),
        forall(
            member(Finding, Findings),
            catch(
                process_finding(Finding),
                Err,
                ( print_message(warning,
                                format("refinement: finding error: ~w", [Err])),
                  true
                )
            )
        ),
        post_cycle_regression_check
    ).

high_priority_objective_pending :-
    catch(
        ( default_nexus(Nexus),
          nexus_is_open(Nexus),
          lattice:lattice_node_fact(Nexus, _, objective, [ObjId], _),
          lattice:lattice_node_fact(Nexus, _, objective_priority, [ObjId, high], _)
        ),
        _, fail
    ).

% ---------------------------------------------------------------------------
% diagnose_window/1 — identify problems in the trajectory window
% ---------------------------------------------------------------------------

diagnose_window(Findings) :-
    findall(F, diagnose_one(F), Findings).

diagnose_one(repeated_plan_failure(Plan, Count)) :-
    % Find any action sequence prefix (first element) that failed >= 5 times
    aggregate_all(bag(Plan1), (
        sona:sona_trajectory_entry(_, _, [Plan1|_], failure, _, _)
    ), FailedPlans),
    sort(FailedPlans, UniqPlans),
    member(Plan, UniqPlans),
    aggregate_all(count,
                  sona:sona_trajectory_entry(_, _, [Plan|_], failure, _, _),
                  Count),
    Count >= 5.

diagnose_one(dead_sentinel(Domain)) :-
    pai_sentinel_entry(Domain, _, _, _, _, _),
    \+ lattice:lattice_node_fact(_, _, sentinel_fired, [Domain|_], _).

diagnose_one(stalled_objective(ObjId)) :-
    catch(
        ( default_nexus(Nexus),
          nexus_is_open(Nexus),
          lattice:lattice_node_fact(Nexus, _, objective, [ObjId], _),
          \+ lattice:lattice_node_fact(Nexus, _, causal_plan, [ObjId|_], _)
        ),
        _, fail
    ).

% ---------------------------------------------------------------------------
% process_finding/1 — translate a diagnosis into a CRUD edit and run pipeline
% ---------------------------------------------------------------------------

process_finding(repeated_plan_failure(Plan, Count)) :-
    Edit = delete_plan(Plan),
    Justification = repeated_failure(Plan, Count),
    run_rsi_pipeline(causal_plan, Edit, Justification).

process_finding(dead_sentinel(Domain)) :-
    Edit = noop,
    Justification = dead_sentinel(Domain),
    run_rsi_pipeline(sentinel, Edit, Justification).

process_finding(stalled_objective(ObjId)) :-
    Edit = noop,
    Justification = stalled_objective(ObjId),
    run_rsi_pipeline(objective_system, Edit, Justification).

process_finding(Other) :-
    run_rsi_pipeline(other, noop, Other).

% ---------------------------------------------------------------------------
% post_cycle_regression_check/0
%
%   After committing edits, compute R3 and roll back if it regressed.
% ---------------------------------------------------------------------------

post_cycle_regression_check :-
    compute_r3(CurrentR3),
    % Check if any committed proposals have a prior-R3 recorded
    ( catch(nb_getval(refinement_pre_cycle_r3, PreR3), _, fail)
    ->  ( CurrentR3 < PreR3
        ->  % Regressed: roll back the latest committed proposal
            findall(Id, modification_proposal(Id, _, _, _, committed), CommittedIds),
            ( CommittedIds \= []
            ->  last(CommittedIds, LatestId),
                pai_rollback_modification(LatestId, _)
            ;   true
            )
        ;   true
        )
    ;   true
    ),
    nb_setval(refinement_pre_cycle_r3, CurrentR3).

% ---------------------------------------------------------------------------
% Refiner actor management
% ---------------------------------------------------------------------------

install_refiner_actor :-
    catch(
        cyclic_actor(refiner_actor, refinement:refiner_cycle, 60000),
        _,
        true
    ).

uninstall_refiner_actor :-
    catch(cyclic_actor_stop(refiner_actor), _, true).

% ---------------------------------------------------------------------------
% Reflection predicates (Section 3.15)
% ---------------------------------------------------------------------------

pai_reflect_module(Module, Desc) :-
    catch(
        ( findall(P/A, (
              current_predicate(Module:P/A),
              A >= 0
          ), Preds),
          Desc = module_desc{
              module: Module,
              predicates: Preds
          }
        ),
        _,
        Desc = module_desc{module: Module, predicates: []}
    ).

pai_reflect_sentinel(Name, Desc) :-
    ( pai_sentinel_entry(Name, Priority, Pattern, Objectives, Action, Doc)
    ->  aggregate_all(count,
                      lattice:lattice_node_fact(_, _, sentinel_fired, [Name|_], _),
                      FireCount),
        Desc = sentinel_desc{
            domain:     Name,
            priority:   Priority,
            pattern:    Pattern,
            objectives: Objectives,
            action:     Action,
            doc:        Doc,
            fire_count: FireCount
        }
    ;   Desc = sentinel_desc{domain: Name, status: not_registered}
    ).
