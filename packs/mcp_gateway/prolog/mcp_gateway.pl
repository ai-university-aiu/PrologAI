/*  PrologAI — MCP Gateway  (Specification Section 3.12, PR 14)

    Exposes the entire PrologAI cognitive architecture as an MCP-accessible
    service implementing the Model Context Protocol 1.0 specification.

    mcp_gateway_start/1  — start the HTTP server on Port (default 7474).
    mcp_gateway_stop/0   — stop the HTTP server.

    Authentication: every request must carry a valid API key in the
    "Authorization: Bearer <key>" header.  Requests without a valid key
    receive HTTP 401 Unauthorized.

    Tool endpoints (POST /tools/<name>):
      lattice_query    — wraps traverse_nexus/4
      lattice_inscribe — wraps anchor_node/4
      lattice_excise   — wraps prune_node/1
      actor_list       — wraps cyclic_actor_list/1
      actor_start      — wraps cyclic_actor/3
      actor_stop       — wraps cyclic_actor_stop/1
      sentinel_register — wraps pai_register_sentinel/6
      sentinel_list    — wraps sentinel_list/2
      body_enroll      — wraps manifest_body/3
      body_signal      — wraps relay_percept/2
      body_command     — wraps dispatch_command/2
      sona_learn       — wraps sona_absorb/1
      sona_recall      — wraps sona_retrieve/3
      assess_all       — wraps assess_all/2

    Request body: JSON {"params": {...}} (MCP 1.0 simplified form)
    Response body: JSON {"result": <value>, "isError": false}
               or: JSON {"error": "...", "isError": true}

    Requires SWI-Prolog libraries: http/thread_httpd, http/http_dispatch,
    http/http_json, http/http_parameters.
*/

:- module(mcp_gateway, [
    mcp_gateway_start/1,   % +Port
    mcp_gateway_stop/0,
    mcp_set_api_key/1,     % +Key (atom)
    mcp_get_api_key/1      % -Key
]).

:- use_module(library(http/thread_httpd),  [http_server/2, http_stop_server/2,
                                            http_server_property/2]).
:- use_module(library(http/http_dispatch), [http_dispatch/1, http_handler/3]).
:- use_module(library(http/http_json),     [http_read_json_dict/2,
                                            reply_json_dict/1,
                                            reply_json_dict/2]).
:- use_module(library(http/http_header),   [http_reply_header/3]).
:- use_module(library(node_facts),         [traverse_nexus/4, anchor_node/4,
                                            prune_node/1, default_nexus/1]).
:- use_module(library(cyclic_actor),       [cyclic_actor_list/1,
                                            cyclic_actor_stop/1]).
:- use_module(library(sentinels),          [pai_register_sentinel/6,
                                            sentinel_list/2]).

% ---------------------------------------------------------------------------
% API key store (default: empty = no auth required in dev mode)
% ---------------------------------------------------------------------------

:- dynamic mcp_api_key/1.
mcp_api_key('prologai-dev-key').

mcp_set_api_key(Key) :-
    retractall(mcp_api_key(_)),
    assertz(mcp_api_key(Key)).

mcp_get_api_key(Key) :-
    mcp_api_key(Key).

% ---------------------------------------------------------------------------
% mcp_gateway_start/1
% ---------------------------------------------------------------------------

mcp_gateway_start(Port) :-
    ( mcp_active_port(Port)
    ->  true   % already running on this port
    ;   mcp_gateway_stop,   % stop any previously running server
        http_handler(root(tools), mcp_dispatch_tool, [prefix]),
        http_server(http_dispatch, [port(Port)]),
        retractall(mcp_active_port(_)),
        assertz(mcp_active_port(Port))
    ).

% ---------------------------------------------------------------------------
% Active port tracking
% ---------------------------------------------------------------------------

:- dynamic mcp_active_port/1.

% ---------------------------------------------------------------------------
% mcp_gateway_stop/0
% ---------------------------------------------------------------------------

mcp_gateway_stop :-
    ( mcp_active_port(Port)
    ->  catch(http_stop_server(Port, []), _, true),
        retractall(mcp_active_port(_))
    ;   true
    ).

% ---------------------------------------------------------------------------
% mcp_dispatch_tool/1 — HTTP handler for all /tools/<name> requests
% ---------------------------------------------------------------------------

mcp_dispatch_tool(Request) :-
    % Authenticate
    ( check_auth(Request)
    ->  true
    ;   reply_json_dict(json{error: "Unauthorized", isError: true},
                        [status(401)]),
        !
    ),
    % Extract tool name from path
    memberchk(path(Path), Request),
    atom_concat('/tools/', ToolName, Path),
    % Read request body
    catch(
        http_read_json_dict(Request, Body),
        _,
        Body = json{}
    ),
    Params = Body.get(params, json{}),
    % Dispatch
    catch(
        dispatch_tool(ToolName, Params, Result),
        Err,
        ( term_to_atom(Err, ErrAtom),
          Result = json{error: ErrAtom, isError: true}
        )
    ),
    ( Result = json{error: _, isError: true}
    ->  reply_json_dict(Result, [status(500)])
    ;   reply_json_dict(json{result: Result, isError: false})
    ).

% ---------------------------------------------------------------------------
% Authentication check
% ---------------------------------------------------------------------------

check_auth(Request) :-
    ( memberchk(authorization(Bearer), Request)
    ->  atom_concat('Bearer ', Key, Bearer),
        mcp_api_key(Key)
    ;   memberchk(x_api_key(Key), Request),
        mcp_api_key(Key)
    ).

% ---------------------------------------------------------------------------
% Tool dispatch table
% ---------------------------------------------------------------------------

dispatch_tool(lattice_query, Params, Results) :-
    Pattern = Params.get(pattern, '_'),
    K       = Params.get(k, 10),
    default_nexus(Nexus),
    term_to_atom(PatTerm, Pattern),
    traverse_nexus(Nexus, PatTerm, K, RawResults),
    maplist([R, S]>>(term_to_atom(R, S)), RawResults, Results).

dispatch_tool(lattice_inscribe, Params, Id) :-
    RelRaw    = Params.get(relation, none),
    ArgsRaw   = Params.get(args, '[]'),
    RefsRaw   = Params.get(referents, '[]'),
    % JSON strings → atoms
    ( string(RelRaw) -> atom_string(Relation, RelRaw) ; Relation = RelRaw ),
    ( string(ArgsRaw) -> atom_string(ArgsAtom, ArgsRaw) ; atom_string(ArgsAtom, ArgsRaw) ),
    ( string(RefsRaw) -> atom_string(RefsAtom, RefsRaw) ; atom_string(RefsAtom, RefsRaw) ),
    term_to_atom(Args, ArgsAtom),
    term_to_atom(Refs, RefsAtom),
    anchor_node(Relation, Args, Refs, Id).

dispatch_tool(lattice_excise, Params, ok) :-
    Id = Params.get(id, 0),
    prune_node(Id).

dispatch_tool(actor_list, _Params, Names) :-
    cyclic_actor_list(Names).

dispatch_tool(actor_stop, Params, ok) :-
    Name = Params.get(name, unknown),
    cyclic_actor_stop(Name).

dispatch_tool(sentinel_list, Params, SentinelTerms) :-
    Domain = Params.get(domain, general),
    sentinel_list(Domain, Sentinels),
    maplist([S, A]>>(term_to_atom(S, A)), Sentinels, SentinelTerms).

dispatch_tool(body_enroll, Params, ok) :-
    Address = Params.get(address, 'herald://unknown'),
    NeedsAtom = Params.get(needs, '[]'),
    CapsAtom  = Params.get(capabilities, '[]'),
    term_to_atom(Needs, NeedsAtom),
    term_to_atom(Caps, CapsAtom),
    catch(
        mindbody:manifest_body(Address, Needs, Caps),
        _, true
    ).

dispatch_tool(body_signal, Params, ok) :-
    Address = Params.get(address, 'herald://unknown'),
    SigAtom = Params.get(signal, 'none'),
    term_to_atom(Signal, SigAtom),
    catch(
        mindbody:relay_percept(Address, Signal),
        _, true
    ).

dispatch_tool(body_command, Params, ok) :-
    Address = Params.get(address, 'herald://unknown'),
    CmdAtom = Params.get(command, 'none'),
    term_to_atom(Cmd, CmdAtom),
    catch(
        mindbody:dispatch_command(Address, Cmd),
        _, true
    ).

dispatch_tool(sona_learn, Params, ok) :-
    TrajAtom = Params.get(trajectory, 'none'),
    term_to_atom(Traj, TrajAtom),
    catch(sona:sona_absorb(Traj), _, true).

dispatch_tool(sona_recall, Params, Results) :-
    PatAtom = Params.get(pattern, 'any'),
    K = Params.get(k, 5),
    term_to_atom(Pat, PatAtom),
    catch(
        ( sona:sona_retrieve(Pat, K, Trajs),
          maplist([T, A]>>(term_to_atom(T, A)), Trajs, Results)
        ),
        _, Results = []
    ).

dispatch_tool(assess_all, Params, ReportAtom) :-
    MindId = Params.get(mind, mind_default),
    catch(
        ( assessment:assess_all(MindId, Report),
          term_to_atom(Report, ReportAtom)
        ),
        _, ReportAtom = error
    ).

dispatch_tool(Unknown, _Params, _Result) :-
    throw(error(unknown_tool(Unknown), dispatch_tool/3)).
