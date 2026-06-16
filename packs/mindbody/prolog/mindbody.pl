/*  PrologAI — Mind-Body Interface  (Specification Section 3.6, PR 10)

    manifest_body/3   — enroll a physical or simulated body, recording its
                        address, homeostatic needs, and capabilities as
                        node_facts in the Lattice.
    relay_percept/2   — route an incoming sensory percept from a body to the
                        correct PrologAI handler by signal type:
                          perception_signal    -> perceiver receptor channel
                          interoceptive_signal -> motivation actor channel
                          proprioceptive_signal-> regulation actor channel
    dispatch_command/2 — send a command from the mind to an enrolled body;
                         awaits a proprioceptive result or synthesises a
                         timeout result (every command resolves).
    body_vitals/2     — return current vital indicators for an enrolled body.

    Signal types (FR-PR10):
      perception_signal(Modality, Data, Timestamp)
          Modality in {visual, auditory, haptic, kinesthetic, odometric,
                       phonological, sonar}
      interoceptive_signal(NeedId, ActualValue, Timestamp)
      proprioceptive_signal(CommandId, Success, ResultData, Timestamp)

    Body state is persisted as node_facts so all actors can read it.
    Routing uses pubsub/publish; if the destination topic has no subscribers
    the percept is still stored as a Lattice node_fact for later retrieval.
*/

% Declare this file as the 'mindbody' module and list its exported predicates.
:- module(mindbody, [
    % Continue the multi-line expression started above.
    manifest_body/3,       % +Address, +Needs, +Capabilities
    % Continue the multi-line expression started above.
    relay_percept/2,       % +Address, +Signal
    % Continue the multi-line expression started above.
    dispatch_command/2,    % +Address, +Command
    % Continue the multi-line expression started above.
    body_vitals/2,         % +Address, -Vitals
    % Continue the multi-line expression started above.
    body_enrolled/1        % ?Address  (query helper)
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [anchor_node/4, live_node_facts/2,
                                     % Continue the multi-line expression started above.
                                     default_nexus/1]).
% Import [nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [nexus_is_open/1]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).

% ---------------------------------------------------------------------------
% Enrolled body registry — keeps the latest enrollment fact per address
% ---------------------------------------------------------------------------

% Declare 'body_enrollment_id/2.   % Address -> node_fact Id' as dynamic — its facts may be added or removed at runtime.
:- dynamic body_enrollment_id/2.   % Address -> node_fact Id

% ---------------------------------------------------------------------------
% manifest_body/3
%
%   Enroll a body, replacing any prior enrollment at the same address.
%   Persists a body_enrollment node_fact in the current default nexus.
%   Vitals are a snapshot: needs(Needs), capabilities(Capabilities).
% ---------------------------------------------------------------------------

% Define a clause for 'manifest body': succeed when the following conditions hold.
manifest_body(Address, Needs, Capabilities) :-
    % Replace any previous enrollment
    % Remove all matching facts from the runtime knowledge base.
    retractall(body_enrollment_id(Address, _)),
    % Persist as a Lattice node_fact
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(body_enrollment,
                % Continue the multi-line expression started above.
                [Address, Needs, Capabilities],
                % Continue the multi-line expression started above.
                [],
                % Supply 'Id' as the next argument to the expression above.
                Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(body_enrollment_id(Address, Id)).

% ---------------------------------------------------------------------------
% body_vitals/2
%
%   Returns a vitals/3 term with the enrolled body's address, needs, and
%   capabilities, sourced from the Lattice node_fact recorded at enrollment.
% ---------------------------------------------------------------------------

% Define a clause for 'body vitals': succeed when the following conditions hold.
body_vitals(Address, vitals(Address, Needs, Capabilities)) :-
    % State a fact for 'body enrollment id' with the arguments listed below.
    body_enrollment_id(Address, _),
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nexus),
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % Find the most recently asserted enrollment node_fact for Address
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-N-C, (
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, Id, body_enrollment,
                                     % Continue the multi-line expression started above.
                                     [Address, N, C], [])
    % Continue the multi-line expression started above.
    ), Rows),
    % Check that 'Rows' is not unifiable with '[]'.
    Rows \= [],
    % Unify the second argument with the last element of list 'Rows'.
    last(Rows, _-Needs-Capabilities).

% ---------------------------------------------------------------------------
% relay_percept/2
%
%   Route Signal to the appropriate channel.  The signal is also anchored
%   as a Lattice node_fact so actors that start after delivery can still
%   retrieve it via traverse_nexus.
% ---------------------------------------------------------------------------

% Define a clause for 'relay percept': succeed when the following conditions hold.
relay_percept(Address, Signal) :-
    % State a fact for 'percept channel' with the arguments listed below.
    percept_channel(Signal, Channel),
    % Store the percept in the Lattice
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept_signal, [Address, Signal], [Channel], _),
    % Publish to the routing channel (non-fatal if no subscribers yet)
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        pubsub:publish(Channel, percept(Address, Signal)),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% State the fact: percept channel(perception_signal(_, _, _),    'channel://perceiver').
percept_channel(perception_signal(_, _, _),    'channel://perceiver').
% State the fact: percept channel(interoceptive_signal(_, _, _), 'channel://motivation').
percept_channel(interoceptive_signal(_, _, _), 'channel://motivation').
% State the fact: percept channel(proprioceptive_signal(_, _, _, _), 'channel://regulation').
percept_channel(proprioceptive_signal(_, _, _, _), 'channel://regulation').

% ---------------------------------------------------------------------------
% dispatch_command/2
%
%   Send Command to Address.  The command is stored as a node_fact so it
%   forms part of the body's action history.  A proprioceptive result is
%   awaited via a subscription; if none arrives within the timeout window
%   a synthesised timeout result is produced (100% of commands resolve).
%
%   Constitutional guard: irreversible commands publish to
%   'channel://constitutional_gate' first and block until permit is received.
%   This stub trusts all commands until the constitutional pack (later PR)
%   is installed.
% ---------------------------------------------------------------------------

% Declare 'command_result/3.       % CommandId, Address, Result' as dynamic — its facts may be added or removed at runtime.
:- dynamic command_result/3.       % CommandId, Address, Result

% Define a clause for 'dispatch command': succeed when the following conditions hold.
dispatch_command(Address, Command) :-
    % Assign a unique command ID
    % State a fact for 'gensym' with the arguments listed below.
    gensym(cmd_, CommandId),
    % Persist command as a Lattice node_fact
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(body_command, [Address, CommandId, Command], [], _),
    % Attempt constitutional gate (non-fatal if constitutional module absent)
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        constitutional_gate_check(Command),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ),
    % Publish command to body's address channel
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        pubsub:publish(Address, command(CommandId, Command)),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ),
    % Await proprioceptive result (up to 200 ms) or synthesise timeout
    % State the fact: await proprioceptive(CommandId, Address, 0.2).
    await_proprioceptive(CommandId, Address, 0.2).

%  Stub: the full constitutional gate is implemented in a later PR.
% State the fact: constitutional gate check(_Command).
constitutional_gate_check(_Command).

% Define a clause for 'await proprioceptive': succeed when the following conditions hold.
await_proprioceptive(CommandId, Address, MaxWait) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State the fact: await loop(CommandId, Address, T0, MaxWait).
    await_loop(CommandId, Address, T0, MaxWait).

% Define a clause for 'await loop': succeed when the following conditions hold.
await_loop(CommandId, Address, T0, MaxWait) :-
    % Execute: ( command_result(CommandId, Address, _).
    ( command_result(CommandId, Address, _)
    % If the condition above succeeded, perform the following action.
    ->  true   % result already recorded
    % Otherwise (else branch), perform the following action.
    ;   get_time(Now),
        % Continue the multi-line expression started above.
        Elapsed is Now - T0,
        % Continue the multi-line expression started above.
        ( Elapsed < MaxWait
        % If the condition above succeeded, perform the following action.
        ->  sleep(0.01),
            % Continue the multi-line expression started above.
            await_loop(CommandId, Address, T0, MaxWait)
        % Otherwise (else branch), perform the following action.
        ;   % Synthesise timeout result
            % Continue the multi-line expression started above.
            get_time(T),
            % Continue the multi-line expression started above.
            anchor_node(percept_signal,
                        % Continue the multi-line expression started above.
                        [Address,
                         % Continue the multi-line expression started above.
                         proprioceptive_signal(CommandId, timeout, [], T)],
                        % Continue the multi-line expression started above.
                        ['channel://regulation'],
                        % Supply '_' as the next argument to the expression above.
                        _)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% body_enrolled/1  — query helper
% ---------------------------------------------------------------------------

% Define a clause for 'body enrolled': succeed when the following conditions hold.
body_enrolled(Address) :-
    % State the fact: body enrollment id(Address, _).
    body_enrollment_id(Address, _).
