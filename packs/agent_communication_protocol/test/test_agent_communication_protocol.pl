/*  PrologAI — ACP Gateway (Agent Communication Protocol) Test Suite  (PR 47)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/agent_communication_protocol/test/test_agent_communication_protocol.pl
*/

% Declare this file as a test module.
:- module(test_agent_communication_protocol, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(agent_communication_protocol)).

% Reset the run-record store so each test starts from a clean slate.
reset_agent_communication_protocol :-
    % Clear every recorded run (RunId, Task, Status, Artifact).
    retractall(agent_communication_protocol:agent_communication_protocol_run_record(_, _, _, _)).

% Open the test block for agent_communication_protocol.
:- begin_tests(agent_communication_protocol).

% ACP-001: the agent description reports the ACP identity, protocols, and default capabilities.
test(agent_description_reports_identity_and_capabilities, [setup(reset_agent_communication_protocol)]) :-
    % Build the agent description term from registered state.
    agent_communication_protocol_agent_description(Desc),
    % The description carries the six expected slots in order.
    Desc = description(name(Name), version(_), capabilities(Caps), protocols(Protocols), endpoint(_), description_url(_)),
    % The advertised name is the ACP agent name.
    assertion(Name == 'PrologAI ACP Agent'),
    % The ACP protocol is among the supported protocols.
    assertion(memberchk(acp, Protocols)),
    % The lattice_query capability is registered by default.
    assertion(memberchk(lattice_query, Caps)),
    % The reasoning capability is registered by default.
    assertion(memberchk(reasoning, Caps)).

% ACP-002: a run for a registered skill produces a completed artifact tagged with its run id and task.
test(run_with_known_skill_completes, [setup(reset_agent_communication_protocol)]) :-
    % Create and execute a synchronous run for the registered lattice_query skill.
    agent_communication_protocol_run(task(lattice_query, hello), sync, RunId, Artifact),
    % A fresh run id is bound to an atom.
    assertion(atom(RunId)),
    % The artifact carries the run id, the original task, and a processed result.
    Artifact = artifact(ArtRunId, task(lattice_query, hello), Result),
    % The artifact's run id matches the returned run id.
    assertion(ArtRunId == RunId),
    % The result names the processed skill and input.
    assertion(Result == 'processed(lattice_query,hello)'),
    % The run's recorded status is completed.
    agent_communication_protocol_status(RunId, Status),
    % The status reflects successful completion.
    assertion(Status == completed).

% ACP-003: a run whose task is a bare atom is processed through the raw-input dispatch clause.
test(run_with_atom_task_processes_raw_input, [setup(reset_agent_communication_protocol)]) :-
    % Create and execute a run whose task body is a plain atom.
    agent_communication_protocol_run(diagnose_self, sync, RunId, Artifact),
    % The artifact wraps the atom task with a processed_-prefixed result.
    assertion(Artifact == artifact(RunId, diagnose_self, processed_diagnose_self)),
    % The run completes.
    agent_communication_protocol_status(RunId, Status),
    % The recorded status is completed.
    assertion(Status == completed).

% ACP-004: a run for an unregistered skill fails without throwing, and is recorded as failed.
test(run_with_unknown_skill_fails, [setup(reset_agent_communication_protocol)]) :-
    % Create and execute a run for a skill that was never registered.
    agent_communication_protocol_run(task(no_such_skill, x), sync, RunId, Artifact),
    % The dispatch failure surfaces as an error artifact rather than an exception.
    assertion(Artifact == error(dispatch_failed)),
    % Look up the run's recorded status.
    agent_communication_protocol_status(RunId, Status),
    % The run is recorded as failed.
    assertion(Status == failed).

% ACP-005: the status of an unknown run id is not_found.
test(status_of_unknown_run_is_not_found, [setup(reset_agent_communication_protocol)]) :-
    % Query the status of a run id that was never created.
    agent_communication_protocol_status('no-such-run-id', Status),
    % The store reports the run as not found.
    assertion(Status == not_found).

% ACP-006: cancelling an already-completed run is a no-op that leaves it completed.
test(cancel_completed_run_is_noop, [setup(reset_agent_communication_protocol)]) :-
    % Create and execute a run that completes successfully.
    agent_communication_protocol_run(task(reasoning, why), sync, RunId, _Artifact),
    % Confirm the run reached the completed state.
    agent_communication_protocol_status(RunId, Before),
    % The run is completed before the cancel attempt.
    assertion(Before == completed),
    % Attempt to cancel the already-completed run.
    agent_communication_protocol_cancel(RunId),
    % Query the status again after the cancel attempt.
    agent_communication_protocol_status(RunId, After),
    % A completed run is not cancelable, so it stays completed.
    assertion(After == completed).

% Close the test block for agent_communication_protocol.
:- end_tests(agent_communication_protocol).
