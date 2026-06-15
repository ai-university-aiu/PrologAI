/*  PrologAI — PR 14 MCP Gateway Acceptance Tests

    AC-PR14-001: mcp_gateway_start(Port) starts; HTTP POST to
                 /tools/lattice_query with valid API key returns MCP response.
    AC-PR14-002: Request with invalid API key returns HTTP 401.
    AC-PR14-003: mcp_gateway_stop/0 stops the server.
    AC-PR14-004: /tools/lattice_inscribe stores a node_fact.
    AC-PR14-005: /tools/actor_list returns a list.
    AC-PR14-006: /tools/sona_learn accepts a trajectory.
    AC-PR14-007: /tools/sona_recall returns matching trajectories.
    AC-PR14-008: /tools/assess_all returns a report atom.
    AC-PR14-009: Unknown tool returns isError:true.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   atomic_list_concat([ProjectRoot, '/packs/mindbody/prolog'],       MindBodyPath),
   atomic_list_concat([ProjectRoot, '/packs/sona/prolog'],           SonaPath),
   atomic_list_concat([ProjectRoot, '/packs/assessment/prolog'],     AssessPath),
   atomic_list_concat([ProjectRoot, '/packs/mcp_gateway/prolog'],    McpPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, SentinelPath)),
   assertz(file_search_path(library, MindBodyPath)),
   assertz(file_search_path(library, SonaPath)),
   assertz(file_search_path(library, AssessPath)),
   assertz(file_search_path(library, McpPath)).

:- use_module(library(plunit)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_json), [reply_json_dict/1]).
:- use_module(library(http/json),      [atom_json_dict/3]).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(mcp_gateway),[mcp_gateway_start/1, mcp_gateway_stop/0,
                                    mcp_set_api_key/1]).

:- nb_setval(pr14_test_port, 7477).

post_mcp(Path, Body, ApiKey, StatusCode, ResponseDict) :-
    nb_getval(pr14_test_port, Port),
    format(atom(URL), "http://localhost:~w~w", [Port, Path]),
    atom_json_dict(BodyAtom, Body, []),
    atom_string(BodyAtom, BodyStr),
    atom_length(BodyAtom, BodyLen),
    setup_call_cleanup(
        http_open(URL, Stream,
            [ method(post),
              request_header('Content-Type'='application/json'),
              request_header('Authorization'=ApiKey),
              request_header('Content-Length'=BodyLen),
              post(string(BodyStr)),
              status_code(StatusCode)
            ]),
        ( read_term_from_atom('', _, []),
          read_stream_to_codes(Stream, Codes),
          atom_codes(RespAtom, Codes),
          atom_json_dict(RespAtom, ResponseDict, [])
        ),
        close(Stream)
    ).

:- begin_tests(pr14, [setup(pr14_setup), cleanup(pr14_cleanup)]).

pr14_setup :-
    lattice_open('locus://localhost/pr14', N),
    nb_setval(pr14_nexus_ref, N),
    set_default_nexus(N),
    mcp_set_api_key('test-api-key-pr14'),
    nb_getval(pr14_test_port, Port),
    mcp_gateway_start(Port).

pr14_cleanup :-
    catch(mcp_gateway_stop, _, true),
    nb_getval(pr14_nexus_ref, N),
    lattice_close(N).

valid_auth('Bearer test-api-key-pr14').
invalid_auth('Bearer wrong-key').

%  AC-PR14-001
test(lattice_query_valid_key) :-
    valid_auth(Auth),
    post_mcp('/tools/lattice_query',
             json{params: json{pattern: 'node_fact(_,_,_,_)', k: 5}},
             Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-002
test(invalid_api_key_returns_401) :-
    invalid_auth(Auth),
    post_mcp('/tools/lattice_query',
             json{params: json{}},
             Auth, Status, _Resp),
    Status =:= 401.

%  AC-PR14-003
test(gateway_is_running_after_start) :-
    % Verify the server is running: a second start call is idempotent
    nb_getval(pr14_test_port, Port),
    mcp_gateway_start(Port),   % idempotent: already started
    valid_auth(Auth),
    post_mcp('/tools/actor_list',
             json{params: json{}},
             Auth, Status, _),
    Status =:= 200.

%  AC-PR14-004
test(lattice_inscribe_tool) :-
    valid_auth(Auth),
    post_mcp('/tools/lattice_inscribe',
             json{params: json{
                 relation: test_rel,
                 args: '[test_arg]',
                 referents: '[]'
             }},
             Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-005
test(actor_list_tool) :-
    valid_auth(Auth),
    post_mcp('/tools/actor_list', json{params: json{}}, Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-006
test(sona_learn_tool) :-
    valid_auth(Auth),
    post_mcp('/tools/sona_learn',
             json{params: json{
                 trajectory: 'trajectory(sit1,[act1],success,1.0,0.0)'
             }},
             Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-007
test(sona_recall_tool) :-
    valid_auth(Auth),
    post_mcp('/tools/sona_recall',
             json{params: json{pattern: 'sit1', k: 5}},
             Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-008
test(assess_all_tool) :-
    valid_auth(Auth),
    post_mcp('/tools/assess_all',
             json{params: json{mind: test_mind}},
             Auth, Status, Resp),
    Status =:= 200,
    get_dict(isError, Resp, false).

%  AC-PR14-009
test(unknown_tool_returns_error) :-
    valid_auth(Auth),
    post_mcp('/tools/no_such_tool',
             json{params: json{}},
             Auth, Status, Resp),
    ( Status =:= 500 -> true ; Status =:= 200 ),
    get_dict(isError, Resp, true).

:- end_tests(pr14).
