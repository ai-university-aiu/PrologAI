% Module: co_signing — record-level Ed25519 signing and verification, a port
% of the reference signing.py. A signature is computed over a record's RFC 8785
% identity-bearing bytes (signature and id removed), so verification needs only
% the record itself. Additive harness code; drives causal_core canonicalization
% and the pure-Prolog ed25519 module.
:- module(co_signing, [
    % co_keypair_from_seed/3: a keypair from a 32-byte seed.
    co_keypair_from_seed/3,
    % co_sign_record/4: complete a record with its id and signature.
    co_sign_record/4,
    % co_verify_record/2: verify a record's signature against its key field.
    co_verify_record/2
   ]).

% The Causalontology core supplies canonicalization and identity.
:- use_module(library(causal_core)).
% The pure-Prolog Ed25519 primitive.
:- use_module('ed25519.pl').
% String and list helpers.
:- use_module(library(lists)).

% -- co_utf8_bytes(+String, -Bytes): the UTF-8 byte list of a string.
% The canonical strings are ASCII, so code points are the UTF-8 bytes.
co_utf8_bytes(String, Bytes) :-
    % Take the string's character codes as the byte list.
    string_codes(String, Bytes).

% -- co_keypair_from_seed(+Seed32, -Secret, -PubId): derive a keypair.
co_keypair_from_seed(Seed32, Seed32, PubId) :-
    % The secret is the seed itself; derive the public key bytes.
    ed25519_secret_to_public(Seed32, Pub),
    % Render the public key as lowercase hex.
    ed25519_bytes_to_hex(Pub, Hex),
    % The public identifier carries the whole-word ed25519 scheme.
    atomic_list_concat(['ed25519:', Hex], PubIdA),
    % Return it as a string to match the JSON string values.
    atom_string(PubIdA, PubId).

% -- co_sign_record(+Record, +Secret, +Kind, -Out): sign and complete a record.
co_sign_record(Record, Secret, Kind, Out) :-
    % Remove any existing signature to form the body.
    ( del_dict(signature, Record, _, Body0) -> true ; Body0 = Record ),
    % Canonicalize the body's identity-bearing bytes for this kind.
    causal_core_canonicalize(Body0, Kind, Canon),
    % Convert to a UTF-8 byte list.
    co_utf8_bytes(Canon, Msg),
    % Sign deterministically with Ed25519.
    ed25519_sign(Secret, Msg, Sig),
    % Render the signature as hex.
    ed25519_bytes_to_hex(Sig, SigHex),
    % Compute the record identity over the same body.
    causal_core_identify(Body0, Kind, Id),
    % Attach the id.
    put_dict(id, Body0, Id, Body1),
    % Attach the signature (as a string) to finish the record.
    atom_string(SigHex, SigStr),
    put_dict(signature, Body1, SigStr, Out).

% -- co_verify_record(+Record, +Kind): true iff the signature verifies.
co_verify_record(Record, Kind) :-
    % Read the signature field.
    get_dict(signature, Record, SigStr),
    % Read the signer's key field (predecessor for succession, else source).
    co_signer_key_hex(Record, Kind, KeyHex),
    % Decode key and signature from hex to bytes.
    ed25519_hex_to_bytes(KeyHex, Pub),
    ed25519_hex_to_bytes(SigStr, Sig),
    % Strip the signature to recover the signed body.
    del_dict(signature, Record, _, Body),
    % Canonicalize and encode the body bytes.
    causal_core_canonicalize(Body, Kind, Canon), co_utf8_bytes(Canon, Msg),
    % Verify.
    ed25519_verify(Pub, Msg, Sig).

% -- co_signer_key_hex(+Record, +Kind, -Hex): the hex of the signer's key.
% A succession is signed by the predecessor key.
co_signer_key_hex(Record, succession, Hex) :- !,
    get_dict(predecessor, Record, V), co_ed_hex(V, Hex).
% Every other record is signed by its source key.
co_signer_key_hex(Record, _Kind, Hex) :-
    get_dict(source, Record, V), co_ed_hex(V, Hex).

% -- co_ed_hex(+Value, -Hex): the hex tail of an "ed25519:<hex>" identifier.
co_ed_hex(V, Hex) :-
    % Normalise to a string.
    ( string(V) -> S = V ; atom_string(V, S) ),
    % It must carry the ed25519 scheme.
    string_concat("ed25519:", Hex, S).
