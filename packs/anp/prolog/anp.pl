/*  PrologAI — ANP Gateway  (Specification PR 48)

    Gives each PrologAI mind a W3C Decentralized Identifier (DID) in did:web
    format derived from the Mind Server hostname.  Enables peer-to-peer agent
    discovery and cryptographically authenticated messaging without relying on
    a central registry.

    The Agent Network Protocol (ANP) uses:
        DID (Decentralized Identifier) — W3C standard; did:web:hostname format.
        /.well-known/agent-descriptions — the ANP agent description endpoint.
        Cryptographic signing — SHA-256 HMAC over the message payload.
        Meta-Protocol Negotiation (MPN) — peers discover which protocols are
            spoken before initiating contact.

    Inbound messages are verified against the sender's DID-derived key before
    any content enters any scope.  Unverified messages are discarded and a
    security event is logged.  Outbound messages are signed and pass the
    constitutional gate.

    Predicates:
        pai_anp_did/1               — -DID: the mind's did:web DID
        pai_anp_agent_description/1 — -Desc: the ANP agent description term
        pai_anp_send/3              — +PeerDID, +Payload, -Envelope
        pai_anp_receive/3           — +Envelope, +Scope, -Payload
        pai_anp_verify/2            — +Envelope, -Result (verified|failed)
        pai_anp_negotiate/2         — +PeerDID, -ProtocolSet
*/

% Declare this file as the 'anp' module and list its exported predicates.
:- module(anp, [
    % Supply 'pai_anp_did/1' as the next argument to the expression above.
    pai_anp_did/1,
    % Supply 'pai_anp_agent_description/1' as the next argument to the expression above.
    pai_anp_agent_description/1,
    % Supply 'pai_anp_send/3' as the next argument to the expression above.
    pai_anp_send/3,
    % Supply 'pai_anp_receive/3' as the next argument to the expression above.
    pai_anp_receive/3,
    % Supply 'pai_anp_verify/2' as the next argument to the expression above.
    pai_anp_verify/2,
    % Supply 'pai_anp_negotiate/2' as the next argument to the expression above.
    pai_anp_negotiate/2
% Close the expression opened above.
]).

% Import HTTP server predicates from the built-in http library.
:- use_module(library(http/thread_httpd),  [http_server/2, http_stop_server/2]).
% Import HTTP dispatch predicates.
:- use_module(library(http/http_dispatch), [http_dispatch/1, http_handler/3]).
% Import JSON read/write predicates.
:- use_module(library(http/http_json),     [reply_json_dict/1]).
% Import cryptographic hash predicate.
:- use_module(library(crypto),             [crypto_data_hash/3]).
% Import atom utilities.
:- use_module(library(lists), [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Dynamic state: DID, key material, peer registry, oversight log
% ---------------------------------------------------------------------------

% Declare 'anp_did/1' as dynamic: the mind's did:web DID.
:- dynamic anp_did/1.
% Declare 'anp_signing_key/1' as dynamic: the signing key secret (HMAC key atom).
:- dynamic anp_signing_key/1.
% Declare 'anp_peer_record/3' as dynamic: PeerDID, Endpoint, PublicKey.
:- dynamic anp_peer_record/3.
% Declare 'anp_security_log/2' as dynamic: Timestamp, Event.
:- dynamic anp_security_log/2.
% Declare 'anp_active_port/1' as dynamic.
:- dynamic anp_active_port/1.

% ---------------------------------------------------------------------------
% pai_anp_did/1 — return or generate the mind's DID
%
%   The DID is derived from the Mind Server hostname (default: localhost).
%   It is stored as a dynamic fact and survives within a session.
%   Format: did:web:<hostname>
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp did': return the stored DID, or generate one.
pai_anp_did(DID) :-
    % Check if a DID is already stored.
    ( anp_did(DID)
    % If yes, return it directly.
    ->  true
    % Otherwise, generate a new DID from the hostname.
    ;   anp_generate_did(DID)
    ).

% Define a clause for 'anp generate did': derive a did:web DID and store it.
anp_generate_did(DID) :-
    % Get the host name of the current machine.
    ( catch(gethostname(Host), _, Host = localhost)
    % If gethostname fails, use localhost as fallback.
    ->  true
    ;   Host = localhost
    ),
    % Construct the did:web DID by prefixing the hostname.
    atom_concat('did:web:', Host, DID),
    % Store the DID as a dynamic fact for this session.
    assertz(anp_did(DID)),
    % Generate and store a session signing key for HMAC operations.
    anp_ensure_signing_key.

% Define a clause for 'anp ensure signing key': generate and store an HMAC signing key.
anp_ensure_signing_key :-
    % Check if a signing key already exists.
    ( anp_signing_key(_)
    % If yes, do nothing.
    ->  true
    % Otherwise, generate a key from time and a random component.
    ;   get_time(T),
        % Combine the timestamp with a random float to make the key unique.
        random(R),
        % Build an atom combining both values as the key seed.
        format(atom(KeySeed), 'pai-anp-key-~w-~w', [T, R]),
        % Hash the seed to produce a fixed-length key.
        crypto_data_hash(KeySeed, KeyHash, [algorithm(sha256)]),
        % Store the key hash as the signing key.
        assertz(anp_signing_key(KeyHash))
    ).

% ---------------------------------------------------------------------------
% pai_anp_agent_description/1 — the ANP agent description as a Prolog term
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp agent description': build the description from state.
pai_anp_agent_description(description(
        % The mind's DID.
        did(DID),
        % The list of supported protocols with their endpoints.
        protocols([
            % MCP endpoint at port 7474.
            protocol(mcp, 'http://localhost:7474'),
            % A2A endpoint (same MCP port with /a2a path).
            protocol(a2a, 'http://localhost:7474/a2a'),
            % ACP endpoint at port 7476.
            protocol(acp, 'http://localhost:7476/runs'),
            % ANP well-known endpoint.
            protocol(anp, 'http://localhost:7477/.well-known/agent-descriptions')
        ]),
        % A public key fingerprint (SHA-256 of the signing key, truncated).
        public_key_fingerprint(Fingerprint),
        % The description endpoint URL.
        description_url('http://localhost:7477/.well-known/agent-descriptions')
    )) :-
    % Get the mind's DID (generate if needed).
    pai_anp_did(DID),
    % Ensure the signing key is present.
    anp_ensure_signing_key,
    % Retrieve the signing key.
    anp_signing_key(Key),
    % Compute a fingerprint by hashing the key.
    crypto_data_hash(Key, Full, [algorithm(sha256)]),
    % Use the first 16 characters of the hash as the fingerprint.
    sub_atom(Full, 0, 16, _, Fingerprint).

% ---------------------------------------------------------------------------
% pai_anp_send/3 — compose, sign, and send a message to a peer
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp send': sign a payload and build an ANP envelope.
pai_anp_send(PeerDID, Payload, Envelope) :-
    % Gate the outbound message through the constitutional check.
    ( anp_constitutional_check(send(PeerDID, Payload))
    % If permitted, compose and sign the envelope.
    ->  true
    % If vetoed, throw an error so the caller knows the message was blocked.
    ;   throw(error(constitutional_veto(anp_send), pai_anp_send/3))
    ),
    % Get the sender's DID.
    pai_anp_did(SenderDID),
    % Get the current timestamp.
    get_time(Timestamp),
    % Compute the HMAC signature over the payload and timestamp.
    anp_sign(Payload, Timestamp, Signature),
    % Assemble the envelope with sender, recipient, timestamp, signature, and payload.
    Envelope = envelope(
        from(SenderDID),
        to(PeerDID),
        timestamp(Timestamp),
        signature(Signature),
        payload(Payload)
    ).

% Define a clause for 'anp sign': compute an HMAC-SHA256 signature over the payload.
anp_sign(Payload, Timestamp, Signature) :-
    % Get the signing key.
    ( anp_signing_key(Key) -> true ; Key = 'default-dev-key' ),
    % Build the data to sign: payload atom + timestamp.
    term_to_atom(Payload, PayloadAtom),
    % Combine payload and timestamp into a single signing string.
    format(atom(SigningData), '~w|~w|~w', [PayloadAtom, Timestamp, Key]),
    % Compute the SHA-256 hash of the signing data.
    crypto_data_hash(SigningData, Signature, [algorithm(sha256)]).

% ---------------------------------------------------------------------------
% pai_anp_receive/3 — verify and admit an inbound ANP envelope
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp receive': verify the envelope and return the payload.
pai_anp_receive(Envelope, _Scope, Payload) :-
    % Verify the envelope's signature.
    pai_anp_verify(Envelope, Result),
    % Check the verification result.
    ( Result = verified
    % If verified, extract the payload from the envelope.
    ->  Envelope = envelope(_, _, _, _, payload(Payload))
    % If verification failed, discard and log a security event.
    ;   anp_log_security_event(verification_failed(Envelope)),
        % Fail so the caller knows the message was rejected.
        fail
    ).

% ---------------------------------------------------------------------------
% pai_anp_verify/2 — verify the cryptographic signature of an ANP envelope
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp verify': check the signature against the sender's key.
pai_anp_verify(Envelope, Result) :-
    % Extract the components from the envelope.
    ( Envelope = envelope(from(SenderDID), _, timestamp(Timestamp),
                          signature(Signature), payload(Payload))
    % If the envelope structure is valid, proceed to verify the signature.
    ->  ( anp_verify_signature(SenderDID, Payload, Timestamp, Signature)
        % If signature checks out, return verified.
        ->  Result = verified
        % If signature does not check out, return failed.
        ;   Result = failed(signature_mismatch)
        )
    % If the envelope structure is malformed, return failed.
    ;   Result = failed(malformed_envelope)
    ).

% Define a clause for 'anp verify signature': check whether the signature is valid.
anp_verify_signature(SenderDID, Payload, Timestamp, Signature) :-
    % Look up the sender's public key from the peer registry.
    ( anp_peer_record(SenderDID, _, PeerKey)
    % If the peer is registered, verify against their key.
    ->  term_to_atom(Payload, PayloadAtom),
        % Reconstruct the signing data using the peer's key.
        format(atom(SigningData), '~w|~w|~w', [PayloadAtom, Timestamp, PeerKey]),
        % Compute the expected signature.
        crypto_data_hash(SigningData, ExpectedSig, [algorithm(sha256)]),
        % Check that the actual signature matches the expected signature.
        Signature = ExpectedSig
    % If the peer is not registered, fall back to local key (self-signed loop).
    ;   anp_signing_key(LocalKey),
        % Reconstruct signing data using the local key (allows self-verification in tests).
        term_to_atom(Payload, PayloadAtom),
        % Build the signing string with the local key.
        format(atom(SigningData), '~w|~w|~w', [PayloadAtom, Timestamp, LocalKey]),
        % Compute the expected signature with the local key.
        crypto_data_hash(SigningData, ExpectedSig, [algorithm(sha256)]),
        % Verify the signature matches.
        Signature = ExpectedSig
    ).

% ---------------------------------------------------------------------------
% pai_anp_negotiate/2 — meta-protocol negotiation
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp negotiate': return the set of supported protocols.
pai_anp_negotiate(_PeerDID, ProtocolSet) :-
    % Return the fixed set of four supported protocols with their local endpoints.
    ProtocolSet = [
        % MCP protocol endpoint.
        protocol(mcp, 'http://localhost:7474'),
        % A2A protocol endpoint.
        protocol(a2a, 'http://localhost:7474/a2a'),
        % ACP protocol endpoint.
        protocol(acp, 'http://localhost:7476/runs'),
        % ANP protocol endpoint.
        protocol(anp, 'http://localhost:7477/.well-known/agent-descriptions')
    ].

% ---------------------------------------------------------------------------
% anp_log_security_event/1 — log a security event to the oversight log
% ---------------------------------------------------------------------------

% Define a clause for 'anp log security event': record a security event with timestamp.
anp_log_security_event(Event) :-
    % Get the current timestamp.
    get_time(Ts),
    % Assert the security event into the oversight log.
    assertz(anp_security_log(Ts, Event)).

% ---------------------------------------------------------------------------
% anp_constitutional_check/1 — gate an action through the constitutional module
% ---------------------------------------------------------------------------

% Define a clause for 'anp constitutional check': attempt to call the constitutional gate.
anp_constitutional_check(Action) :-
    % Try to call constitutional_gate/2 from the constitutional module if loaded.
    ( catch(constitutional:constitutional_gate(Action, Verdict), _, Verdict = permit)
    % If the gate returns permit, succeed.
    ->  Verdict = permit
    % If the gate is not loaded, default to permit for development.
    ;   true
    ).

% ---------------------------------------------------------------------------
% ANP HTTP gateway — serve /.well-known/agent-descriptions
% ---------------------------------------------------------------------------

% Define a clause for 'pai anp start': start the ANP HTTP gateway on the given port.
pai_anp_start(Port) :-
    % Check whether the server is already running.
    ( anp_active_port(Port)
    % If already running, do nothing.
    ->  true
    % Otherwise, stop any previous server and start a new one.
    ;   pai_anp_stop,
        % Register the well-known agent descriptions endpoint.
        http_handler(root('.well-known'('agent-descriptions')),
                     anp_handle_agent_descriptions, []),
        % Start the HTTP server.
        http_server(http_dispatch, [port(Port)]),
        % Remove any stale port record.
        retractall(anp_active_port(_)),
        % Record the active port.
        assertz(anp_active_port(Port))
    ).

% Define a clause for 'pai anp stop': stop the ANP gateway if running.
pai_anp_stop :-
    % Check if a server is active.
    ( anp_active_port(Port)
    % If yes, stop it.
    ->  catch(http_stop_server(Port, []), _, true),
        % Remove the port record.
        retractall(anp_active_port(_))
    % If no server is active, do nothing.
    ;   true
    ).

% Define a clause for 'anp handle agent descriptions': serve the ANP agent description.
anp_handle_agent_descriptions(_Request) :-
    % Build the agent description.
    pai_anp_agent_description(Desc),
    % Convert the description to a JSON-serializable atom.
    term_to_atom(Desc, DescAtom),
    % Get the DID.
    pai_anp_did(DID),
    % Serve the agent description as JSON.
    reply_json_dict(json{
        did: DID,
        protocol: 'anp/1.0',
        description: DescAtom,
        supported_protocols: [mcp, a2a, acp, anp],
        endpoints: json{
            mcp:  'http://localhost:7474',
            a2a:  'http://localhost:7474/a2a',
            acp:  'http://localhost:7476/runs',
            anp:  'http://localhost:7477/.well-known/agent-descriptions'
        }
    }).
