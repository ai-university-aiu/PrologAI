/*  PrologAI — Lattice Cryptography Test Suite

    In-pack acceptance tests for the lattice_cryptography pack, so it enters the
    per-pack regression (the pack previously had NO in-pack test and was not in
    the regression, which let six self-recursive encrypt/decrypt stub clauses -
    head :- head - rot undetected until they overflowed the stack). These tests
    exercise the real RSA and ECDH hybrid round-trips (openssl-backed) and the
    generic dispatch, and stand as a regression guard for the recursion bug.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" test_lattice_cryptography.pl
*/

% Declare this file as a test module.
:- module(test_lattice_cryptography, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the pack under test.
:- use_module(library(lattice_cryptography)).

% Open the lattice_cryptography acceptance test block.
:- begin_tests(lattice_cryptography).

% Helper: generate an RSA key pair and load both keys from their PEM files.
rsa_keys(PrivKey, PubKey) :-
    % Generate a 2048-bit RSA key pair into temporary PEM files.
    lattice_cryptography_keygen_rsa(2048, PrivFile, PubFile),
    % Load the private key blob from its PEM file.
    lattice_cryptography_pem_load_private(PrivFile, PrivKey),
    % Load the public key blob from its PEM file.
    lattice_cryptography_pem_load_public(PubFile, PubKey),
    % Remove the temporary private-key file.
    catch(delete_file(PrivFile), _, true),
    % Remove the temporary public-key file.
    catch(delete_file(PubFile), _, true).

% RSA availability: crypto_available/1 must succeed for the RSA algorithm.
test(crypto_available_rsa) :-
    % Assert RSA is reported available (openssl present).
    lattice_cryptography_crypto_available(lattice_cryptography_algo_rsa).

% ECDH availability: crypto_available/1 must succeed for the ECDH algorithm.
test(crypto_available_ecdh) :-
    % Assert ECDH is reported available (openssl present).
    lattice_cryptography_crypto_available(lattice_cryptography_algo_ecdh).

% RSA hybrid round-trip: encrypt then decrypt recovers the plaintext.
% This is the direct regression guard for the removed self-recursive stub:
% if encrypt_rsa/4 or decrypt_rsa/4 called itself, this would stack-overflow.
test(rsa_hybrid_roundtrip) :-
    % Generate and load an RSA key pair.
    rsa_keys(PrivKey, PubKey),
    % Encrypt a sensitive plaintext with the public key.
    lattice_cryptography_encrypt_rsa(PubKey, 'CreditCard:4111111111111111', Bundle, Tag),
    % Decrypt the bundle with the private key.
    lattice_cryptography_decrypt_rsa(PrivKey, Bundle, Tag, Plain),
    % Assert the original plaintext was recovered.
    assertion(Plain == 'CreditCard:4111111111111111').

% RSA decryption with a mismatched private key must fail (AES-GCM auth).
test(rsa_wrong_key_fails, [throws(_)]) :-
    % Generate the real recipient key pair.
    rsa_keys(_RealPriv, PubKey),
    % Generate a different, wrong private key.
    rsa_keys(WrongPriv, _),
    % Encrypt to the real public key.
    lattice_cryptography_encrypt_rsa(PubKey, 'top-secret', Bundle, Tag),
    % Decrypting with the wrong private key must raise an error.
    lattice_cryptography_decrypt_rsa(WrongPriv, Bundle, Tag, _Plain).

% ECDH hybrid round-trip via the generic dispatch (the clean public interface).
test(ecdh_hybrid_roundtrip) :-
    % Generate a recipient ECDH key pair on the prime256v1 curve.
    lattice_cryptography_keygen_ecdh(prime256v1, RecipPriv, RecipPub),
    % Encrypt a secret through the generic five-argument interface.
    lattice_cryptography_encrypt(lattice_cryptography_algo_ecdh, RecipPub, 'Password:hunter2', Bundle, Tag),
    % Decrypt through the generic five-argument interface.
    lattice_cryptography_decrypt(lattice_cryptography_algo_ecdh, RecipPriv, Bundle, Tag, Plain),
    % Assert the original plaintext was recovered.
    assertion(Plain == 'Password:hunter2').

% ECDH keygen must produce distinct public points on successive calls.
test(ecdh_keygen_distinct) :-
    % Generate the first ECDH key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, _P1, Pub1),
    % Generate the second ECDH key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, _P2, Pub2),
    % Assert the two public points differ.
    assertion(Pub1 \== Pub2).

% Generic dispatch: encrypt/5 and decrypt/5 route RSA correctly.
test(generic_dispatch_rsa) :-
    % Generate and load an RSA key pair.
    rsa_keys(PrivKey, PubKey),
    % Encrypt through the generic five-argument interface.
    lattice_cryptography_encrypt(lattice_cryptography_algo_rsa, PubKey, 'generic-rsa', Bundle, Tag),
    % Decrypt through the generic five-argument interface.
    lattice_cryptography_decrypt(lattice_cryptography_algo_rsa, PrivKey, Bundle, Tag, Plain),
    % Assert the plaintext round-tripped through dispatch.
    assertion(Plain == 'generic-rsa').

% Post-quantum path is optional (needs the oqs tool); test it only if available.
test(pqc_roundtrip_if_available) :-
    % Branch on whether the PQC algorithm is available in this environment.
    ( lattice_cryptography_crypto_available(lattice_cryptography_algo_pqc)
    % If available, run a real keygen/encrypt/decrypt round-trip.
    ->  lattice_cryptography_keygen_pqc(_Algo, pqc_keypair(PrivFile, PubFile)),
        % Encrypt through the generic interface (routes to the PQC path).
        lattice_cryptography_encrypt(lattice_cryptography_algo_pqc, PubFile, 'pqc-secret', Bundle, Tag),
        % Decrypt through the generic interface.
        lattice_cryptography_decrypt(lattice_cryptography_algo_pqc, PrivFile, Bundle, Tag, Plain),
        % Assert the plaintext was recovered.
        assertion(Plain == 'pqc-secret')
    % If unavailable, the pack must simply report it unavailable (no crash).
    ;   assertion(true) ).

% Close the lattice_cryptography acceptance test block.
:- end_tests(lattice_cryptography).
