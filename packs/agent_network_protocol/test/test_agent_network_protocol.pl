/*  PrologAI — Agent Network Protocol Test Suite  (WP; ANP Gateway, PR 48)

    Exercises the six exported ANP predicates as real behaviour, with no HTTP
    server: the mind derives a did:web Decentralized Identifier, meta-protocol
    negotiation returns the four-protocol set, the agent description carries the
    DID and a public-key fingerprint, and an outbound envelope is signed so that
    it verifies and its payload is admitted on receipt — while a tampered
    signature and a malformed envelope are both rejected.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/agent_network_protocol/test/test_agent_network_protocol.pl
*/

% Declare this file as a test module.
:- module(test_agent_network_protocol, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(agent_network_protocol)).

% Open the ANP behaviour test block.
:- begin_tests(agent_network_protocol).

% The mind's identifier is a W3C did:web Decentralized Identifier atom.
test(did_is_did_web) :-
    % Ask the pack for the mind's DID (generating one on first call).
    agent_network_protocol:agent_network_protocol_did(DID),
    % The DID must be a bound atom.
    assertion(atom(DID)),
    % The DID must carry the did:web scheme prefix.
    assertion(atom_concat('did:web:', _Host, DID)).

% Meta-protocol negotiation reports the four supported protocols with endpoints.
test(negotiate_returns_four_protocols) :-
    % Negotiate the protocol set against an arbitrary peer DID.
    agent_network_protocol:agent_network_protocol_negotiate('did:web:peer.example', Set),
    % Exactly four protocols are offered.
    assertion(length(Set, 4)),
    % The Model Context Protocol is present with an endpoint.
    assertion(memberchk(protocol(mcp, _), Set)),
    % The Agent-to-Agent protocol is present with an endpoint.
    assertion(memberchk(protocol(a2a, _), Set)),
    % The Agent Communication Protocol is present with an endpoint.
    assertion(memberchk(protocol(acp, _), Set)),
    % The Agent Network Protocol itself is present with an endpoint.
    assertion(memberchk(protocol(anp, _), Set)).

% The agent description carries the mind's DID and a 16-character key fingerprint.
test(agent_description_has_did_and_fingerprint) :-
    % Build the ANP agent description term.
    agent_network_protocol:agent_network_protocol_agent_description(Desc),
    % Destructure the description into its four fields.
    Desc = description(did(DID), protocols(Protocols),
                       public_key_fingerprint(Fingerprint), description_url(_Url)),
    % The embedded DID uses the did:web scheme.
    assertion(atom_concat('did:web:', _, DID)),
    % The description advertises the four-protocol list.
    assertion(length(Protocols, 4)),
    % The public-key fingerprint is a 16-character atom (a truncated SHA-256).
    assertion(atom_length(Fingerprint, 16)).

% A freshly sent envelope is self-signed and verifies as authentic.
test(send_produces_verifiable_envelope) :-
    % Compose and sign an outbound envelope to a peer.
    agent_network_protocol:agent_network_protocol_send('did:web:peer.example', hello_world, Envelope),
    % The envelope is the expected five-field structure.
    assertion(Envelope = envelope(from(_), to('did:web:peer.example'), timestamp(_),
                                  signature(_), payload(hello_world))),
    % Verifying the envelope yields the verified verdict.
    agent_network_protocol:agent_network_protocol_verify(Envelope, Result),
    % The signature checks out against the mind's own key.
    assertion(Result == verified).

% Receiving a verified envelope admits its original payload unchanged.
test(receive_returns_original_payload) :-
    % Sign an outbound envelope carrying a structured payload.
    agent_network_protocol:agent_network_protocol_send('did:web:peer.example',
        request(status, [urgent]), Envelope),
    % Receive the envelope into an arbitrary scope.
    agent_network_protocol:agent_network_protocol_receive(Envelope, inbox, Payload),
    % The admitted payload is exactly what was sent.
    assertion(Payload == request(status, [urgent])).

% Tampering with the signature makes verification fail.
test(tampered_signature_is_rejected) :-
    % Produce a genuine signed envelope.
    agent_network_protocol:agent_network_protocol_send('did:web:peer.example', payday, Genuine),
    % Split out the envelope fields so the signature can be swapped.
    Genuine = envelope(From, To, Stamp, signature(_Good), Body),
    % Rebuild the envelope with a forged signature.
    Forged = envelope(From, To, Stamp, signature('0000forgedf00d'), Body),
    % Verify the forged envelope.
    agent_network_protocol:agent_network_protocol_verify(Forged, Result),
    % The verdict reports a signature mismatch, not verified.
    assertion(Result = failed(signature_mismatch)).

% A structurally malformed envelope is reported as malformed, never verified.
test(malformed_envelope_is_reported) :-
    % Verify a term that is not an envelope at all.
    agent_network_protocol:agent_network_protocol_verify(not_an_envelope, Result),
    % The verdict names the malformed structure.
    assertion(Result == failed(malformed_envelope)).

% Close the ANP behaviour test block.
:- end_tests(agent_network_protocol).
