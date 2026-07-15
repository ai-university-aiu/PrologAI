/*  PrologAI — Continual Refinement Harness Test Suite  (PR 17)

    Behavioural PLUnit suite for the refinement pack. Exercises the
    constitutional RSI pipeline end to end — propose, permit, sandbox,
    commit, rollback — plus the R3 benchmark and module reflection.
    None of these paths need a live lattice or SONA server: the pack
    guards those with catch/3, so the suite runs standalone.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/refinement/test/test_refinement.pl
*/

% Declare this file as a test module exporting nothing.
:- module(test_refinement, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the refinement module under test.
:- use_module(library(refinement)).

% Reset the modification log and id counter to a clean state before a test.
reset_refinement :-
    % Remove every recorded modification proposal.
    retractall(refinement:modification_proposal(_, _, _, _, _)),
    % Remove every recorded prior-state snapshot.
    retractall(refinement:modification_prior_state(_, _)),
    % Remove the proposal id counter.
    retractall(refinement:modification_id_counter(_)),
    % Re-seed the id counter at zero so proposal ids restart deterministically.
    assertz(refinement:modification_id_counter(0)).

% Open the test block named 'refinement'.
:- begin_tests(refinement).

% A proposed modification is recorded in the log with status 'proposed'.
test(propose_records_proposal, [setup(reset_refinement)]) :-
    % Record a harmless proposal against a non-protected component.
    refinement_propose_modification(garden_actor, noop, tidy_up),
    % Read back the whole modification log.
    refinement_modification_log(Log),
    % The proposal appears exactly as recorded, still in the 'proposed' state.
    assertion(member(proposal(_Id, garden_actor, noop, tidy_up, proposed), Log)).

% The constitution blocks edits to protected components but allows safe ones.
test(constitutional_permit_gate) :-
    % A safe no-op edit is permitted.
    assertion(constitutional_permit(noop)),
    % Deleting the constitutional layer is refused.
    assertion(\+ constitutional_permit(delete(constitutional_layer, all_rules))),
    % Editing the monitor is refused.
    assertion(\+ constitutional_permit(edit(monitor, param, value))),
    % Touching the bootstrap relations is refused.
    assertion(\+ constitutional_permit(delete(bootstrap_relations, rel1))).

% The sandbox passes a safe edit and fails a constitutional violation.
test(sandbox_pass_and_fail) :-
    % A no-op edit clears the sandbox with a 'pass' verdict.
    refinement_sandbox_evaluate(noop, [], SafeResult),
    % The safe verdict is exactly 'pass'.
    assertion(SafeResult == pass),
    % A protected-layer deletion is evaluated in the sandbox.
    refinement_sandbox_evaluate(delete(constitutional_layer, rules), [], BadResult),
    % The sandbox reports a constitutional violation.
    assertion(BadResult == fail(constitutional_violation)).

% A safe edit commits, then rolls back, and both states show in the log.
test(commit_then_rollback, [setup(reset_refinement)]) :-
    % Propose a safe no-op edit against an ordinary component.
    refinement_propose_modification(garden_actor, noop, tune_interval),
    % Find the id assigned to the just-proposed edit.
    refinement_modification_log(Log0),
    % Extract the proposal id from the log, taking the first (deterministic) match.
    once(member(proposal(Id, garden_actor, noop, tune_interval, proposed), Log0)),
    % Commit the proposal; a safe edit should be accepted (first, deterministic solution).
    once(refinement_commit_modification(Id, CommitResult)),
    % The commit result names the committed proposal id.
    assertion(CommitResult == committed(Id)),
    % The log now shows the proposal in the 'committed' state.
    refinement_modification_log(Log1),
    % Confirm the committed entry is present.
    assertion(member(proposal(Id, garden_actor, noop, tune_interval, committed), Log1)),
    % Roll the committed edit back (first, deterministic solution).
    once(refinement_rollback_modification(Id, RollbackResult)),
    % The rollback result names the rolled-back proposal id.
    assertion(RollbackResult == rolled_back(Id)),
    % The log now shows the proposal in the 'rolled_back' state.
    refinement_modification_log(Log2),
    % Confirm the rolled-back entry is present.
    assertion(member(proposal(Id, garden_actor, noop, tune_interval, rolled_back), Log2)).

% Committing an edit to a protected component is rejected, leaving the core untouched.
test(commit_protected_rejected, [setup(reset_refinement)]) :-
    % Propose an edit that deletes the constitutional layer.
    refinement_propose_modification(constitutional_layer, delete(constitutional_layer, all_rules), attack),
    % Find the id assigned to the protected proposal.
    refinement_modification_log(Log0),
    % Extract the proposal id from the log, taking the first (deterministic) match.
    once(member(proposal(Id, constitutional_layer, delete(constitutional_layer, all_rules), attack, proposed), Log0)),
    % Attempt to commit; the constitution must reject it.
    refinement_commit_modification(Id, Result),
    % The commit is rejected for a constitutional violation.
    assertion(Result == rejected(constitutional_violation)),
    % The log shows the proposal rejected, never committed.
    refinement_modification_log(Log1),
    % Confirm the rejected entry is present.
    assertion(member(proposal(Id, constitutional_layer, _, attack, rejected), Log1)),
    % No committed entry exists for this proposal id.
    assertion(\+ member(proposal(Id, _, _, _, committed), Log1)).

% The R3 benchmark returns a numeric self-improvement score in the unit interval.
test(compute_r3_score) :-
    % Compute the R3 self-improvement gain.
    compute_r3(Score),
    % The score is a number.
    assertion(number(Score)),
    % The score lies within the closed unit interval.
    assertion(Score >= 0.0),
    % The upper bound of the unit interval also holds.
    assertion(Score =< 1.0).

% Module reflection returns a dict describing the reflected module.
test(reflect_module_dict) :-
    % Reflect on the refinement module itself.
    refinement_reflect_module(refinement, Desc),
    % The descriptor is a dict.
    assertion(is_dict(Desc)),
    % The dict names the module it describes.
    assertion(get_dict(module, Desc, refinement)),
    % Read the predicate list out of the dict (bindings must survive outside assertion/1).
    get_dict(predicates, Desc, Preds),
    % That predicate list is a proper list.
    assertion(is_list(Preds)).

% Close the test block named 'refinement'.
:- end_tests(refinement).
