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

:- module(mindbody, [
    manifest_body/3,       % +Address, +Needs, +Capabilities
    relay_percept/2,       % +Address, +Signal
    dispatch_command/2,    % +Address, +Command
    body_vitals/2,         % +Address, -Vitals
    body_enrolled/1        % ?Address  (query helper)
]).

:- use_module(library(node_facts),  [anchor_node/4, live_node_facts/2,
                                     default_nexus/1]).
:- use_module(library(lattice),     [nexus_is_open/1]).
:- use_module(library(lists),       [member/2]).

% ---------------------------------------------------------------------------
% Enrolled body registry — keeps the latest enrollment fact per address
% ---------------------------------------------------------------------------

:- dynamic body_enrollment_id/2.   % Address -> node_fact Id

% ---------------------------------------------------------------------------
% manifest_body/3
%
%   Enroll a body, replacing any prior enrollment at the same address.
%   Persists a body_enrollment node_fact in the current default nexus.
%   Vitals are a snapshot: needs(Needs), capabilities(Capabilities).
% ---------------------------------------------------------------------------

manifest_body(Address, Needs, Capabilities) :-
    % Replace any previous enrollment
    retractall(body_enrollment_id(Address, _)),
    % Persist as a Lattice node_fact
    anchor_node(body_enrollment,
                [Address, Needs, Capabilities],
                [],
                Id),
    assertz(body_enrollment_id(Address, Id)).

% ---------------------------------------------------------------------------
% body_vitals/2
%
%   Returns a vitals/3 term with the enrolled body's address, needs, and
%   capabilities, sourced from the Lattice node_fact recorded at enrollment.
% ---------------------------------------------------------------------------

body_vitals(Address, vitals(Address, Needs, Capabilities)) :-
    body_enrollment_id(Address, _),
    default_nexus(Nexus),
    nexus_is_open(Nexus),
    % Find the most recently asserted enrollment node_fact for Address
    findall(Id-N-C, (
        node_facts:lattice_node_fact(Nexus, Id, body_enrollment,
                                     [Address, N, C], [])
    ), Rows),
    Rows \= [],
    last(Rows, _-Needs-Capabilities).

% ---------------------------------------------------------------------------
% relay_percept/2
%
%   Route Signal to the appropriate channel.  The signal is also anchored
%   as a Lattice node_fact so actors that start after delivery can still
%   retrieve it via traverse_nexus.
% ---------------------------------------------------------------------------

relay_percept(Address, Signal) :-
    percept_channel(Signal, Channel),
    % Store the percept in the Lattice
    anchor_node(percept_signal, [Address, Signal], [Channel], _),
    % Publish to the routing channel (non-fatal if no subscribers yet)
    catch(
        pubsub:publish(Channel, percept(Address, Signal)),
        _,
        true
    ).

percept_channel(perception_signal(_, _, _),    'channel://perceiver').
percept_channel(interoceptive_signal(_, _, _), 'channel://motivation').
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

:- dynamic command_result/3.       % CommandId, Address, Result

dispatch_command(Address, Command) :-
    % Assign a unique command ID
    gensym(cmd_, CommandId),
    % Persist command as a Lattice node_fact
    anchor_node(body_command, [Address, CommandId, Command], [], _),
    % Attempt constitutional gate (non-fatal if constitutional module absent)
    catch(
        constitutional_gate_check(Command),
        _,
        true
    ),
    % Publish command to body's address channel
    catch(
        pubsub:publish(Address, command(CommandId, Command)),
        _,
        true
    ),
    % Await proprioceptive result (up to 200 ms) or synthesise timeout
    await_proprioceptive(CommandId, Address, 0.2).

%  Stub: the full constitutional gate is implemented in a later PR.
constitutional_gate_check(_Command).

await_proprioceptive(CommandId, Address, MaxWait) :-
    get_time(T0),
    await_loop(CommandId, Address, T0, MaxWait).

await_loop(CommandId, Address, T0, MaxWait) :-
    ( command_result(CommandId, Address, _)
    ->  true   % result already recorded
    ;   get_time(Now),
        Elapsed is Now - T0,
        ( Elapsed < MaxWait
        ->  sleep(0.01),
            await_loop(CommandId, Address, T0, MaxWait)
        ;   % Synthesise timeout result
            get_time(T),
            anchor_node(percept_signal,
                        [Address,
                         proprioceptive_signal(CommandId, timeout, [], T)],
                        ['channel://regulation'],
                        _)
        )
    ).

% ---------------------------------------------------------------------------
% body_enrolled/1  — query helper
% ---------------------------------------------------------------------------

body_enrolled(Address) :-
    body_enrollment_id(Address, _).
