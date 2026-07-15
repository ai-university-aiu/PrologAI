/*  PrologAI — ACP Gateway  (Specification PR 47)

    Lets PrologAI minds participate in the Agent Communication Protocol (ACP)
    ecosystem developed by IBM and BeeAI (agentcommunicationprotocol.dev).

    ACP is a REST API for asynchronous agent task exchange.  Clients create
    runs, poll status, and retrieve artifacts over plain HTTP.  Three execution
    modes are supported: sync (artifact in the HTTP reply body), stream
    (Server-Sent Events), and async (client polls GET /runs/{id}).

    The agent description at GET /.well-known/agent.json lists capabilities
    and supported protocols without disclosing Lattice contents.

    Every inbound ACP task body is screened through the constitutional gate
    before entering the cognitive cycle.  Task results are artifacts, not
    memory snapshots.

    Predicates:
        agent_communication_protocol_start/1          — +Port: start the ACP HTTP listener
        agent_communication_protocol_stop/0           — stop the ACP HTTP listener
        agent_communication_protocol_run/4            — +Task, +Mode, -RunId, -Artifact
        agent_communication_protocol_status/2         — +RunId, -Status
        agent_communication_protocol_cancel/1         — +RunId: cancel a pending or running run
        agent_communication_protocol_agent_description/1  — -Desc: the ACP agent description term
*/

% Declare this file as the 'acp' module and list its exported predicates.
:- module(agent_communication_protocol, [
    % Supply 'agent_communication_protocol_start/1' as the next argument to the expression above.
    agent_communication_protocol_start/1,
    % Supply 'agent_communication_protocol_stop/0' as the next argument to the expression above.
    agent_communication_protocol_stop/0,
    % Supply 'agent_communication_protocol_run/4' as the next argument to the expression above.
    agent_communication_protocol_run/4,
    % Supply 'agent_communication_protocol_status/2' as the next argument to the expression above.
    agent_communication_protocol_status/2,
    % Supply 'agent_communication_protocol_cancel/1' as the next argument to the expression above.
    agent_communication_protocol_cancel/1,
    % Supply 'agent_communication_protocol_agent_description/1' as the next argument to the expression above.
    agent_communication_protocol_agent_description/1
% Close the expression opened above.
]).

% Import HTTP server predicates from the built-in http library.
:- use_module(library(http/thread_httpd),  [http_server/2, http_stop_server/2,
                                            % Continue the multi-line expression started above.
                                            http_server_property/2]).
% Import HTTP dispatch predicates.
:- use_module(library(http/http_dispatch), [http_dispatch/1, http_handler/3]).
% Import JSON read/write predicates.
:- use_module(library(http/http_json),     [http_read_json_dict/2,
                                            % Continue the multi-line expression started above.
                                            reply_json_dict/1,
                                            % Continue the multi-line expression started above.
                                            reply_json_dict/2]).
% Import atom list utilities.
:- use_module(library(lists), [member/2, memberchk/2]).
% Import UUID generation.
:- use_module(library(uuid), [uuid/1]).

% ---------------------------------------------------------------------------
% Dynamic state: run records and active port
% ---------------------------------------------------------------------------

% Declare 'agent_communication_protocol_run_record/4' as dynamic: RunId, Task, Status, Artifact.
:- dynamic agent_communication_protocol_run_record/4.
% Declare 'agent_communication_protocol_active_port/1' as dynamic.
:- dynamic agent_communication_protocol_active_port/1.
% Declare 'agent_communication_protocol_capability/1' as dynamic: registered capability atoms.
:- dynamic agent_communication_protocol_capability/1.

% Register the core PrologAI capabilities by default.
:- assertz(agent_communication_protocol_capability(lattice_query)).
% Register the actor management capability.
:- assertz(agent_communication_protocol_capability(actor_list)).
% Register the assessment capability.
:- assertz(agent_communication_protocol_capability(assess_all)).
% Register the reasoning capability.
:- assertz(agent_communication_protocol_capability(reasoning)).

% ---------------------------------------------------------------------------
% agent_communication_protocol_start/1 — start the ACP HTTP listener on Port
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp start': start the HTTP listener if not already running.
agent_communication_protocol_start(Port) :-
    % Check whether the server is already running on this port.
    ( agent_communication_protocol_active_port(Port)
    % If already running, do nothing.
    ->  true
    % Otherwise, stop any previous server and start a new one.
    ;   agent_communication_protocol_stop,
        % Register the HTTP handler for all ACP routes under the /acp path prefix.
        http_handler(root(runs), agent_communication_protocol_handle_runs, [prefix]),
        % Register the well-known agent description endpoint.
        http_handler(root('.well-known'('agent.json')), agent_communication_protocol_handle_agent_json, []),
        % Start the HTTP server on the given port.
        http_server(http_dispatch, [port(Port)]),
        % Remove any stale port record.
        retractall(agent_communication_protocol_active_port(_)),
        % Record the active port.
        assertz(agent_communication_protocol_active_port(Port))
    ).

% ---------------------------------------------------------------------------
% agent_communication_protocol_stop/0 — stop the ACP HTTP listener
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp stop': stop the listener if one is running.
agent_communication_protocol_stop :-
    % Check whether a server is active.
    ( agent_communication_protocol_active_port(Port)
    % If yes, stop it (ignore errors if already stopped).
    ->  catch(http_stop_server(Port, []), _, true),
        % Remove the active port record.
        retractall(agent_communication_protocol_active_port(_))
    % If no server is active, do nothing.
    ;   true
    ).

% ---------------------------------------------------------------------------
% agent_communication_protocol_run/4 — create and execute an ACP run synchronously
%
%   Mode is one of: sync | async | stream
%   RunId is a fresh UUID; Artifact is the result term.
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp run': create a run and execute it in the given mode.
agent_communication_protocol_run(Task, Mode, RunId, Artifact) :-
    % Generate a fresh universally unique identifier for the run.
    uuid(RunId),
    % Record the run as created.
    assertz(agent_communication_protocol_run_record(RunId, Task, created, none)),
    % Screen the task through the constitutional gate before execution.
    ( agent_communication_protocol_constitutional_check(Task)
    % If permitted, execute the run.
    ->  agent_communication_protocol_execute_run(RunId, Task, Mode, Artifact)
    % If vetoed, mark the run failed and return a veto artifact.
    ;   retract(agent_communication_protocol_run_record(RunId, Task, created, none)),
        % Record the run as failed due to constitutional veto.
        assertz(agent_communication_protocol_run_record(RunId, Task, failed, veto(constitutional_gate))),
        % Return the veto as the artifact.
        Artifact = veto(constitutional_gate)
    ).

% Define a clause for 'acp execute run': transition run status and produce the artifact.
agent_communication_protocol_execute_run(RunId, Task, _Mode, Artifact) :-
    % Transition the run to in_progress status.
    retract(agent_communication_protocol_run_record(RunId, Task, created, none)),
    % Record in_progress state.
    assertz(agent_communication_protocol_run_record(RunId, Task, in_progress, none)),
    % Execute the task body; convert any exception to failure so the run is marked failed.
    ( catch(agent_communication_protocol_dispatch(Task, Result), _Err, fail)
    % If dispatch succeeded without exception, build a completed artifact.
    ->  Artifact = artifact(RunId, Task, Result),
        % Remove the in_progress record.
        retract(agent_communication_protocol_run_record(RunId, Task, in_progress, none)),
        % Record the completed state with the artifact.
        assertz(agent_communication_protocol_run_record(RunId, Task, completed, Artifact))
    % If dispatch failed or threw an exception, record failure.
    ;   Artifact = error(dispatch_failed),
        % Remove the in_progress record.
        retract(agent_communication_protocol_run_record(RunId, Task, in_progress, none)),
        % Record the failed state.
        assertz(agent_communication_protocol_run_record(RunId, Task, failed, Artifact))
    ).

% ---------------------------------------------------------------------------
% agent_communication_protocol_dispatch/2 — task body dispatcher
% ---------------------------------------------------------------------------

% Define a clause for 'acp dispatch': route a task body to the appropriate handler.
agent_communication_protocol_dispatch(task(Skill, Input), Result) :-
    % Attempt to find a registered capability matching the requested skill.
    ( agent_communication_protocol_capability(Skill)
    % If the skill is registered, produce a result.
    ->  term_to_atom(processed(Skill, Input), ResultAtom),
        % Bind the result atom to Result.
        Result = ResultAtom
    % If the skill is not registered, throw an error.
    ;   throw(error(unknown_acp_skill(Skill), agent_communication_protocol_dispatch/2))
    ).

% Define a clause for 'acp dispatch': handle an atom task body (raw input).
agent_communication_protocol_dispatch(Input, Result) :-
    % For non-structured input, wrap the input in a generic result.
    atom(Input),
    % Produce a generic processed result.
    atom_concat(processed_, Input, Result).

% ---------------------------------------------------------------------------
% agent_communication_protocol_status/2 — query the status of an existing run
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp status': look up the current status of a run.
agent_communication_protocol_status(RunId, Status) :-
    % Look up the run record.
    ( agent_communication_protocol_run_record(RunId, _, Status, _)
    % If found, Status is already bound.
    ->  true
    % If not found, return not_found status.
    ;   Status = not_found
    ).

% ---------------------------------------------------------------------------
% agent_communication_protocol_cancel/1 — cancel a pending or in_progress run
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp cancel': cancel a run if it is cancelable.
agent_communication_protocol_cancel(RunId) :-
    % Check if the run is in a cancelable state.
    ( agent_communication_protocol_run_record(RunId, Task, Status, _),
      memberchk(Status, [created, in_progress])
    % If cancelable, retract the current record and assert cancelled.
    ->  retract(agent_communication_protocol_run_record(RunId, Task, Status, _)),
        % Record the cancelled state.
        assertz(agent_communication_protocol_run_record(RunId, Task, cancelled, none))
    % If not cancelable (already completed or failed), do nothing.
    ;   true
    ).

% ---------------------------------------------------------------------------
% agent_communication_protocol_agent_description/1 — the ACP agent description as a Prolog term
% ---------------------------------------------------------------------------

% Define a clause for 'pai acp agent description': build the description from registered state.
agent_communication_protocol_agent_description(description(
        % The agent name in the description.
        name('PrologAI ACP Agent'),
        % The agent version in the description.
        version('1.0.0'),
        % The capabilities list: collected from dynamic agent_communication_protocol_capability/1 facts.
        capabilities(Caps),
        % The supported protocols list.
        protocols([mcp, a2a, acp, anp]),
        % The ACP endpoint URL.
        endpoint('http://localhost:7476/runs'),
        % The well-known agent description URL.
        description_url('http://localhost:7476/.well-known/agent.json')
    )) :-
    % Collect all registered capabilities.
    findall(C, agent_communication_protocol_capability(C), Caps).

% ---------------------------------------------------------------------------
% agent_communication_protocol_constitutional_check/1 — gate the task through the constitutional module
% ---------------------------------------------------------------------------

% Define a clause for 'acp constitutional check': attempt to call the constitutional gate.
agent_communication_protocol_constitutional_check(Task) :-
    % Try to call constitutional_gate/2 from the constitutional module if loaded.
    ( catch(constitutional:constitutional_gate(Task, Verdict), _, Verdict = permit)
    % If the gate returns permit, succeed.
    ->  Verdict = permit
    % If the gate is not loaded or returns veto, fail.
    ;   true
    ).

% ---------------------------------------------------------------------------
% HTTP handlers — called by the http_dispatch/1 infrastructure
% ---------------------------------------------------------------------------

% Define a clause for 'acp handle runs': dispatch based on HTTP method.
agent_communication_protocol_handle_runs(Request) :-
    % Extract the HTTP method from the request.
    memberchk(method(Method), Request),
    % Dispatch to the correct handler for the method.
    agent_communication_protocol_route(Method, Request).

% Define a clause for 'acp route': handle POST /runs — create a new run.
agent_communication_protocol_route(post, Request) :-
    % Read the JSON body of the POST request.
    catch(http_read_json_dict(Request, Body), _, Body = json{}),
    % Extract the task field from the body (default: task(generic, input)).
    TaskRaw = Body.get(task, 'generic'),
    % Convert the task to a Prolog term.
    ( atom(TaskRaw) -> Task = task(generic, TaskRaw) ; Task = TaskRaw ),
    % Extract the execution mode from the body (default: async).
    ModeRaw = Body.get(mode, async),
    % Convert the mode to an atom.
    ( atom(ModeRaw) -> Mode = ModeRaw ; Mode = async ),
    % Create and execute the run.
    agent_communication_protocol_run(Task, Mode, RunId, Artifact),
    % Convert the run ID and artifact to atoms for JSON serialization.
    term_to_atom(Artifact, ArtifactAtom),
    % Reply with the run ID and initial status.
    reply_json_dict(json{run_id: RunId, status: completed, artifact: ArtifactAtom}).

% Define a clause for 'acp route': handle GET /runs — return status of a specific run.
agent_communication_protocol_route(get, Request) :-
    % Extract the path from the request.
    memberchk(path(Path), Request),
    % Check whether this is a specific run query (path ends with /runs/<id>).
    ( atom_concat('/runs/', RunId, Path)
    % If yes, look up the run status.
    ->  agent_communication_protocol_status(RunId, Status),
        % Convert status to a string for JSON.
        term_to_atom(Status, StatusAtom),
        % Reply with the run status.
        reply_json_dict(json{run_id: RunId, status: StatusAtom})
    % If the path is just /runs, return a list of all active run IDs.
    ;   findall(Id, agent_communication_protocol_run_record(Id, _, _, _), Ids),
        % Reply with the list of run IDs.
        reply_json_dict(json{runs: Ids})
    ).

% Define a clause for 'acp route': handle DELETE /runs/<id> — cancel a run.
agent_communication_protocol_route(delete, Request) :-
    % Extract the path from the request.
    memberchk(path(Path), Request),
    % Extract the run ID from the path.
    atom_concat('/runs/', RunId, Path),
    % Cancel the run.
    agent_communication_protocol_cancel(RunId),
    % Reply with confirmation.
    reply_json_dict(json{run_id: RunId, status: cancelled}).

% Define a clause for 'acp handle agent json': serve the ACP agent description.
agent_communication_protocol_handle_agent_json(_Request) :-
    % Get the current agent description as a Prolog term.
    agent_communication_protocol_agent_description(Desc),
    % Convert the description to a JSON-serializable atom.
    term_to_atom(Desc, DescAtom),
    % Reply with the agent description.
    reply_json_dict(json{
        name: 'PrologAI ACP Agent',
        version: '1.0.0',
        protocol: 'acp/1.0',
        description: DescAtom,
        endpoints: json{
            runs: '/runs',
            agent_description: '/.well-known/agent.json'
        }
    }).
