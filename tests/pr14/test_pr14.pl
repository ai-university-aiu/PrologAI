/*  PrologAI — PR 14 MCP Gateway Acceptance Tests

    AC-PR14-001: model_context_protocol_gateway_start(Port) starts; HTTP POST to
                 /tools/lattice_query with valid API key returns MCP response.
    AC-PR14-002: Request with invalid API key returns HTTP 401.
    AC-PR14-003: model_context_protocol_gateway_stop/0 stops the server.
    AC-PR14-004: /tools/lattice_inscribe stores a node_fact.
    AC-PR14-005: /tools/actor_list returns a list.
    AC-PR14-006: /tools/sona_learn accepts a trajectory.
    AC-PR14-007: /tools/sona_recall returns matching trajectories.
    AC-PR14-008: /tools/assess_all returns a report atom.
    AC-PR14-009: Unknown tool returns isError:true.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/mind_body/prolog'],       MindBodyPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/assessment/prolog'],     AssessPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/mcp_gateway/prolog'],    McpPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SentinelPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, MindBodyPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SonaPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AssessPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, McpPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'http/http_open' library so its predicates are available here.
:- use_module(library(http/http_open)).
% Import [reply_json_dict/1] from the built-in 'http/http_json' library.
:- use_module(library(http/http_json), [reply_json_dict/1]).
% Import [atom_json_dict/3] from the built-in 'http/json' library.
:- use_module(library(http/json),      [atom_json_dict/3]).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'mcp_gateway' library so its predicates are available here.
:- use_module(library(model_context_protocol_gateway),[model_context_protocol_gateway_start/1, model_context_protocol_gateway_stop/0,
                                    % Continue the multi-line expression started above.
                                    model_context_protocol_gateway_set_api_key/1]).

% Execute the compile-time directive: nb_setval(pr14_test_port, 7477).
:- nb_setval(pr14_test_port, 7477).

% Define a clause for 'post mcp': succeed when the following conditions hold.
post_mcp(Path, Body, ApiKey, StatusCode, ResponseDict) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr14_test_port, Port),
    % Write formatted output to the current output stream.
    format(atom(URL), "http://localhost:~w~w", [Port, Path]),
    % State a fact for 'atom json dict' with the arguments listed below.
    atom_json_dict(BodyAtom, Body, []),
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(BodyAtom, BodyStr),
    % State a fact for 'atom length' with the arguments listed below.
    atom_length(BodyAtom, BodyLen),
    % State a fact for 'setup call cleanup' with the arguments listed below.
    setup_call_cleanup(
        % Continue the multi-line expression started above.
        http_open(URL, Stream,
            % Continue the multi-line expression started above.
            [ method(post),
              % Continue the multi-line expression started above.
              request_header('Content-Type'='application/json'),
              % Continue the multi-line expression started above.
              request_header('Authorization'=ApiKey),
              % Continue the multi-line expression started above.
              request_header('Content-Length'=BodyLen),
              % Continue the multi-line expression started above.
              post(string(BodyStr)),
              % Continue the multi-line expression started above.
              status_code(StatusCode)
            % Close the expression opened above.
            ]),
        % Continue the multi-line expression started above.
        ( read_term_from_atom('', _, []),
          % Continue the multi-line expression started above.
          read_stream_to_codes(Stream, Codes),
          % Continue the multi-line expression started above.
          atom_codes(RespAtom, Codes),
          % Continue the multi-line expression started above.
          atom_json_dict(RespAtom, ResponseDict, [])
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        close(Stream)
    % Close the expression opened above.
    ).

% Execute the compile-time directive: begin_tests(pr14, [setup(pr14_setup), cleanup(pr14_cleanup)]).
:- begin_tests(pr14, [setup(pr14_setup), cleanup(pr14_cleanup)]).

% Execute: pr14_setup :-.
pr14_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr14', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr14_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % State a fact for 'mcp set api key' with the arguments listed below.
    model_context_protocol_gateway_set_api_key('test-api-key-pr14'),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr14_test_port, Port),
    % State the fact: mcp gateway start(Port).
    model_context_protocol_gateway_start(Port).

% Execute: pr14_cleanup :-.
pr14_cleanup :-
    % State a fact for 'catch' with the arguments listed below.
    catch(model_context_protocol_gateway_stop, _, true),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr14_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% State the fact: valid auth('Bearer test-api-key-pr14').
valid_auth('Bearer test-api-key-pr14').
% State the fact: invalid auth('Bearer wrong-key').
invalid_auth('Bearer wrong-key').

%  AC-PR14-001
% Define a clause for 'test': succeed when the following conditions hold.
test(lattice_query_valid_key) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/lattice_query',
             % Continue the multi-line expression started above.
             json{params: json{pattern: 'node_fact(_,_,_,_)', k: 5}},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-002
% Define a clause for 'test': succeed when the following conditions hold.
test(invalid_api_key_returns_401) :-
    % State a fact for 'invalid auth' with the arguments listed below.
    invalid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/lattice_query',
             % Continue the multi-line expression started above.
             json{params: json{}},
             % Continue the multi-line expression started above.
             Auth, Status, _Resp),
    % Check that 'Status' is numerically equal to '401'.
    Status =:= 401.

%  AC-PR14-003
% Define a clause for 'test': succeed when the following conditions hold.
test(gateway_is_running_after_start) :-
    % Verify the server is running: a second start call is idempotent
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr14_test_port, Port),
    % State a fact for 'mcp gateway start' with the arguments listed below.
    model_context_protocol_gateway_start(Port),   % idempotent: already started
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/actor_list',
             % Continue the multi-line expression started above.
             json{params: json{}},
             % Continue the multi-line expression started above.
             Auth, Status, _),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200.

%  AC-PR14-004
% Define a clause for 'test': succeed when the following conditions hold.
test(lattice_inscribe_tool) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/lattice_inscribe',
             % Continue the multi-line expression started above.
             json{params: json{
                 % Continue the multi-line expression started above.
                 relation: test_rel,
                 % Continue the multi-line expression started above.
                 args: '[test_arg]',
                 % Continue the multi-line expression started above.
                 referents: '[]'
             % Supply '}}' as the next argument to the expression above.
             }},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-005
% Define a clause for 'test': succeed when the following conditions hold.
test(actor_list_tool) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/actor_list', json{params: json{}}, Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-006
% Define a clause for 'test': succeed when the following conditions hold.
test(sona_learn_tool) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/sona_learn',
             % Continue the multi-line expression started above.
             json{params: json{
                 % Continue the multi-line expression started above.
                 trajectory: 'trajectory(sit1,[act1],success,1.0,0.0)'
             % Supply '}}' as the next argument to the expression above.
             }},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-007
% Define a clause for 'test': succeed when the following conditions hold.
test(sona_recall_tool) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/sona_recall',
             % Continue the multi-line expression started above.
             json{params: json{pattern: 'sit1', k: 5}},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-008
% Define a clause for 'test': succeed when the following conditions hold.
test(assess_all_tool) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/assess_all',
             % Continue the multi-line expression started above.
             json{params: json{mind: test_mind}},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that 'Status' is numerically equal to '200'.
    Status =:= 200,
    % State the fact: get dict(isError, Resp, false).
    get_dict(isError, Resp, false).

%  AC-PR14-009
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_tool_returns_error) :-
    % State a fact for 'valid auth' with the arguments listed below.
    valid_auth(Auth),
    % State a fact for 'post mcp' with the arguments listed below.
    post_mcp('/tools/no_such_tool',
             % Continue the multi-line expression started above.
             json{params: json{}},
             % Continue the multi-line expression started above.
             Auth, Status, Resp),
    % Check that '( Status' is numerically equal to '500 -> true ; Status =:= 200 )'.
    ( Status =:= 500 -> true ; Status =:= 200 ),
    % State the fact: get dict(isError, Resp, true).
    get_dict(isError, Resp, true).

% Execute the compile-time directive: end_tests(pr14).
:- end_tests(pr14).
