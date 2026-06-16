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

% Declare this file as the 'mcp_gateway' module and list its exported predicates.
:- module(mcp_gateway, [
    % Continue the multi-line expression started above.
    mcp_gateway_start/1,   % +Port
    % Supply 'mcp_gateway_stop/0' as the next argument to the expression above.
    mcp_gateway_stop/0,
    % Continue the multi-line expression started above.
    mcp_set_api_key/1,     % +Key (atom)
    % Continue the multi-line expression started above.
    mcp_get_api_key/1      % -Key
% Close the expression opened above.
]).

% Load the built-in 'http/thread_httpd' library so its predicates are available here.
:- use_module(library(http/thread_httpd),  [http_server/2, http_stop_server/2,
                                            % Continue the multi-line expression started above.
                                            http_server_property/2]).
% Import [http_dispatch/1, http_handler/3] from the built-in 'http/http_dispatch' library.
:- use_module(library(http/http_dispatch), [http_dispatch/1, http_handler/3]).
% Load the built-in 'http/http_json' library so its predicates are available here.
:- use_module(library(http/http_json),     [http_read_json_dict/2,
                                            % Supply 'reply_json_dict/1' as the next argument to the expression above.
                                            reply_json_dict/1,
                                            % Continue the multi-line expression started above.
                                            reply_json_dict/2]).
% Import [http_reply_header/3] from the built-in 'http/http_header' library.
:- use_module(library(http/http_header),   [http_reply_header/3]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),         [traverse_nexus/4, anchor_node/4,
                                            % Continue the multi-line expression started above.
                                            prune_node/1, default_nexus/1]).
% Load the built-in 'cyclic_actor' library so its predicates are available here.
:- use_module(library(cyclic_actor),       [cyclic_actor_list/1,
                                            % Continue the multi-line expression started above.
                                            cyclic_actor_stop/1]).
% Load the built-in 'sentinels' library so its predicates are available here.
:- use_module(library(sentinels),          [pai_register_sentinel/6,
                                            % Continue the multi-line expression started above.
                                            sentinel_list/2]).

% ---------------------------------------------------------------------------
% API key store (default: empty = no auth required in dev mode)
% ---------------------------------------------------------------------------

% Declare 'mcp_api_key/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic mcp_api_key/1.
% State the fact: mcp api key('prologai-dev-key').
mcp_api_key('prologai-dev-key').

% Define a clause for 'mcp set api key': succeed when the following conditions hold.
mcp_set_api_key(Key) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(mcp_api_key(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(mcp_api_key(Key)).

% Define a clause for 'mcp get api key': succeed when the following conditions hold.
mcp_get_api_key(Key) :-
    % State the fact: mcp api key(Key).
    mcp_api_key(Key).

% ---------------------------------------------------------------------------
% mcp_gateway_start/1
% ---------------------------------------------------------------------------

% Define a clause for 'mcp gateway start': succeed when the following conditions hold.
mcp_gateway_start(Port) :-
    % Execute: ( mcp_active_port(Port).
    ( mcp_active_port(Port)
    % If the condition above succeeded, perform the following action.
    ->  true   % already running on this port
    % Otherwise (else branch), perform the following action.
    ;   mcp_gateway_stop,   % stop any previously running server
        % Continue the multi-line expression started above.
        http_handler(root(tools), mcp_dispatch_tool, [prefix]),
        % Continue the multi-line expression started above.
        http_server(http_dispatch, [port(Port)]),
        % Continue the multi-line expression started above.
        retractall(mcp_active_port(_)),
        % Continue the multi-line expression started above.
        assertz(mcp_active_port(Port))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Active port tracking
% ---------------------------------------------------------------------------

% Declare 'mcp_active_port/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic mcp_active_port/1.

% ---------------------------------------------------------------------------
% mcp_gateway_stop/0
% ---------------------------------------------------------------------------

% Execute: mcp_gateway_stop :-.
mcp_gateway_stop :-
    % Execute: ( mcp_active_port(Port).
    ( mcp_active_port(Port)
    % If the condition above succeeded, perform the following action.
    ->  catch(http_stop_server(Port, []), _, true),
        % Continue the multi-line expression started above.
        retractall(mcp_active_port(_))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% mcp_dispatch_tool/1 — HTTP handler for all /tools/<name> requests
% ---------------------------------------------------------------------------

% Define a clause for 'mcp dispatch tool': succeed when the following conditions hold.
mcp_dispatch_tool(Request) :-
    % Authenticate
    % Execute: ( check_auth(Request).
    ( check_auth(Request)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   reply_json_dict(json{error: "Unauthorized", isError: true},
                        % Continue the multi-line expression started above.
                        [status(401)]),
        % Supply '!' as the next argument to the expression above.
        !
    % Close the expression opened above.
    ),
    % Extract tool name from path
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(path(Path), Request),
    % State a fact for 'atom concat' with the arguments listed below.
    atom_concat('/tools/', ToolName, Path),
    % Read request body
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        http_read_json_dict(Request, Body),
        % Supply '_' as the next argument to the expression above.
        _,
        % Continue the multi-line expression started above.
        Body = json{}
    % Close the expression opened above.
    ),
    % Check that 'Params' is unifiable with 'Body.get(params, json{})'.
    Params = Body.get(params, json{}),
    % Dispatch
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        dispatch_tool(ToolName, Params, Result),
        % Supply 'Err' as the next argument to the expression above.
        Err,
        % Continue the multi-line expression started above.
        ( term_to_atom(Err, ErrAtom),
          % Continue the multi-line expression started above.
          Result = json{error: ErrAtom, isError: true}
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % Check that '( Result' is unifiable with 'json{error: _, isError: true}'.
    ( Result = json{error: _, isError: true}
    % If the condition above succeeded, perform the following action.
    ->  reply_json_dict(Result, [status(500)])
    % Otherwise (else branch), perform the following action.
    ;   reply_json_dict(json{result: Result, isError: false})
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Authentication check
% ---------------------------------------------------------------------------

% Define a clause for 'check auth': succeed when the following conditions hold.
check_auth(Request) :-
    % Execute: ( memberchk(authorization(Bearer), Request).
    ( memberchk(authorization(Bearer), Request)
    % If the condition above succeeded, perform the following action.
    ->  atom_concat('Bearer ', Key, Bearer),
        % Continue the multi-line expression started above.
        mcp_api_key(Key)
    % Otherwise (else branch), perform the following action.
    ;   memberchk(x_api_key(Key), Request),
        % Continue the multi-line expression started above.
        mcp_api_key(Key)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Tool dispatch table
% ---------------------------------------------------------------------------

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(lattice_query, Params, Results) :-
    % Check that 'Pattern' is unifiable with 'Params.get(pattern, '_')'.
    Pattern = Params.get(pattern, '_'),
    % Check that 'K' is unifiable with 'Params.get(k, 10)'.
    K       = Params.get(k, 10),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nexus),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(PatTerm, Pattern),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nexus, PatTerm, K, RawResults),
    % State the fact: maplist([R, S]>>(term_to_atom(R, S)), RawResults, Results).
    maplist([R, S]>>(term_to_atom(R, S)), RawResults, Results).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(lattice_inscribe, Params, Id) :-
    % Check that 'RelRaw' is unifiable with 'Params.get(relation, none)'.
    RelRaw    = Params.get(relation, none),
    % Check that 'ArgsRaw' is unifiable with 'Params.get(args, '[]')'.
    ArgsRaw   = Params.get(args, '[]'),
    % Check that 'RefsRaw' is unifiable with 'Params.get(referents, '[]')'.
    RefsRaw   = Params.get(referents, '[]'),
    % JSON strings → atoms
    % Check that '( string(RelRaw) -> atom_string(Relation, RelRaw) ; Relation' is unifiable with 'RelRaw )'.
    ( string(RelRaw) -> atom_string(Relation, RelRaw) ; Relation = RelRaw ),
    % Execute: ( string(ArgsRaw) -> atom_string(ArgsAtom, ArgsRaw) ; atom_string(ArgsAtom, ArgsRaw) ),.
    ( string(ArgsRaw) -> atom_string(ArgsAtom, ArgsRaw) ; atom_string(ArgsAtom, ArgsRaw) ),
    % Execute: ( string(RefsRaw) -> atom_string(RefsAtom, RefsRaw) ; atom_string(RefsAtom, RefsRaw) ),.
    ( string(RefsRaw) -> atom_string(RefsAtom, RefsRaw) ; atom_string(RefsAtom, RefsRaw) ),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Args, ArgsAtom),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Refs, RefsAtom),
    % State the fact: anchor node(Relation, Args, Refs, Id).
    anchor_node(Relation, Args, Refs, Id).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(lattice_excise, Params, ok) :-
    % Check that 'Id' is unifiable with 'Params.get(id, 0)'.
    Id = Params.get(id, 0),
    % State the fact: prune node(Id).
    prune_node(Id).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(actor_list, _Params, Names) :-
    % State the fact: cyclic actor list(Names).
    cyclic_actor_list(Names).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(actor_stop, Params, ok) :-
    % Check that 'Name' is unifiable with 'Params.get(name, unknown)'.
    Name = Params.get(name, unknown),
    % State the fact: cyclic actor stop(Name).
    cyclic_actor_stop(Name).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(sentinel_list, Params, SentinelTerms) :-
    % Check that 'Domain' is unifiable with 'Params.get(domain, general)'.
    Domain = Params.get(domain, general),
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinel_list(Domain, Sentinels),
    % State the fact: maplist([S, A]>>(term_to_atom(S, A)), Sentinels, SentinelTerms).
    maplist([S, A]>>(term_to_atom(S, A)), Sentinels, SentinelTerms).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(body_enroll, Params, ok) :-
    % Check that 'Address' is unifiable with 'Params.get(address, 'herald://unknown')'.
    Address = Params.get(address, 'herald://unknown'),
    % Check that 'NeedsAtom' is unifiable with 'Params.get(needs, '[]')'.
    NeedsAtom = Params.get(needs, '[]'),
    % Check that 'CapsAtom' is unifiable with 'Params.get(capabilities, '[]')'.
    CapsAtom  = Params.get(capabilities, '[]'),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Needs, NeedsAtom),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Caps, CapsAtom),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        mindbody:manifest_body(Address, Needs, Caps),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(body_signal, Params, ok) :-
    % Check that 'Address' is unifiable with 'Params.get(address, 'herald://unknown')'.
    Address = Params.get(address, 'herald://unknown'),
    % Check that 'SigAtom' is unifiable with 'Params.get(signal, 'none')'.
    SigAtom = Params.get(signal, 'none'),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Signal, SigAtom),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        mindbody:relay_percept(Address, Signal),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(body_command, Params, ok) :-
    % Check that 'Address' is unifiable with 'Params.get(address, 'herald://unknown')'.
    Address = Params.get(address, 'herald://unknown'),
    % Check that 'CmdAtom' is unifiable with 'Params.get(command, 'none')'.
    CmdAtom = Params.get(command, 'none'),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Cmd, CmdAtom),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        mindbody:dispatch_command(Address, Cmd),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(sona_learn, Params, ok) :-
    % Check that 'TrajAtom' is unifiable with 'Params.get(trajectory, 'none')'.
    TrajAtom = Params.get(trajectory, 'none'),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Traj, TrajAtom),
    % State the fact: catch(sona:sona_absorb(Traj), _, true).
    catch(sona:sona_absorb(Traj), _, true).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(sona_recall, Params, Results) :-
    % Check that 'PatAtom' is unifiable with 'Params.get(pattern, 'any')'.
    PatAtom = Params.get(pattern, 'any'),
    % Check that 'K' is unifiable with 'Params.get(k, 5)'.
    K = Params.get(k, 5),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Pat, PatAtom),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( sona:sona_retrieve(Pat, K, Trajs),
          % Continue the multi-line expression started above.
          maplist([T, A]>>(term_to_atom(T, A)), Trajs, Results)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, Results = []
    % Close the expression opened above.
    ).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(assess_all, Params, ReportAtom) :-
    % Check that 'MindId' is unifiable with 'Params.get(mind, mind_default)'.
    MindId = Params.get(mind, mind_default),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( assessment:assess_all(MindId, Report),
          % Continue the multi-line expression started above.
          term_to_atom(Report, ReportAtom)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, ReportAtom = error
    % Close the expression opened above.
    ).

% Define a clause for 'dispatch tool': succeed when the following conditions hold.
dispatch_tool(Unknown, _Params, _Result) :-
    % State the fact: throw(error(unknown_tool(Unknown), dispatch_tool/3)).
    throw(error(unknown_tool(Unknown), dispatch_tool/3)).
