/*  PrologAI — PR 49 Lattice Cryptographic Privacy Layer Acceptance Tests

    AC-PR49-001: AES-256-GCM symmetric round-trip succeeds.
    AC-PR49-002: RSA hybrid encrypt/decrypt recovers original plaintext.
    AC-PR49-003: RSA decryption with wrong key fails with an error.
    AC-PR49-004: ECDH hybrid encrypt/decrypt recovers original plaintext.
    AC-PR49-005: ECDH decryption with wrong private key fails.
    AC-PR49-006: lattice_cryptography_keygen_ecdh/3 returns distinct public points on each call.
    AC-PR49-007: lattice_cryptography_crypto_available/1 succeeds for lattice_cryptography_algo_rsa and lattice_cryptography_algo_ecdh.
    AC-PR49-008: lattice_cryptography_encrypt/5 and lattice_cryptography_decrypt/5 dispatch correctly for RSA.
    AC-PR49-009: lattice_cryptography_encrypt/5 and lattice_cryptography_decrypt/5 dispatch correctly for ECDH.
    AC-PR49-010: Tampered tag causes authentication error on decrypt.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir).
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice_cryptography/prolog'], CryptoPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, CryptoPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'crypto' library so its predicates are available here.
:- use_module(library(crypto)).
% Load the lattice_crypto module under test.
:- use_module(library(lattice_cryptography)).

% Execute the compile-time directive: begin_tests(pr49).
:- begin_tests(pr49).

% ---------------------------------------------------------------------------
% HELPER: generate a self-consistent RSA key pair into two temp PEM files.
% ---------------------------------------------------------------------------

% Define a clause for 'rsa_test_keys': succeed when the following conditions hold.
rsa_test_keys(PrivKey, PubKey) :-
    % Generate the key pair into temporary PEM files.
    lattice_cryptography_keygen_rsa(2048, PrivFile, PubFile),
    % Load the private key blob from the PEM file.
    lattice_cryptography_pem_load_private(PrivFile, PrivKey),
    % Load the public key blob from the PEM file.
    lattice_cryptography_pem_load_public(PubFile, PubKey),
    % Clean up temporary files.
    catch(delete_file(PrivFile), _, true),
    % Clean up the public key file.
    catch(delete_file(PubFile), _, true).

% ---------------------------------------------------------------------------
% AC-PR49-001 — AES-256-GCM symmetric round-trip
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(aes_gcm_roundtrip) :-
    % Generate a random 256-bit key.
    crypto_n_random_bytes(32, KeyBytes),
    % Convert the key bytes to a binary atom.
    atom_codes(KeyAtom, KeyBytes),
    % Generate a random 96-bit IV.
    crypto_n_random_bytes(12, IVBytes),
    % Convert the IV bytes to a binary atom.
    atom_codes(IVAtom, IVBytes),
    % Encrypt the plaintext atom.
    crypto_data_encrypt('Sensitive data: SSN 999-99-9999',
                        'aes-256-gcm', KeyAtom, IVAtom,
                        Cipher, [tag(TagBytes), encoding(utf8)]),
    % Decrypt the ciphertext; result is a string with encoding(utf8).
    crypto_data_decrypt(Cipher, 'aes-256-gcm', KeyAtom, IVAtom,
                        PlainStr, [tag(TagBytes), encoding(utf8)]),
    % Convert the decrypted string to an atom for comparison.
    atom_string(PlainAtom, PlainStr),
    % Assert that the decrypted atom matches the original.
    PlainAtom = 'Sensitive data: SSN 999-99-9999'.

% ---------------------------------------------------------------------------
% AC-PR49-002 — RSA hybrid round-trip
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(rsa_hybrid_roundtrip) :-
    % Generate a fresh RSA key pair.
    rsa_test_keys(PrivKey, PubKey),
    % Encrypt a sensitive password.
    lattice_cryptography_encrypt_rsa(PubKey, 'CreditCard:4111111111111111', Bundle, Tag),
    % Decrypt the bundle.
    lattice_cryptography_decrypt_rsa(PrivKey, Bundle, Tag, Plain),
    % Assert the plaintext was recovered.
    Plain = 'CreditCard:4111111111111111'.

% ---------------------------------------------------------------------------
% AC-PR49-003 — RSA decryption with mismatched private key fails
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(rsa_wrong_key_fails, [throws(_)]) :-
    % Generate key pair A.
    rsa_test_keys(_PrivA, PubA),
    % Generate key pair B.
    rsa_test_keys(PrivB, _PubB),
    % Encrypt with public key A.
    lattice_cryptography_encrypt_rsa(PubA, 'secret', Bundle, Tag),
    % Attempt to decrypt with private key B — must throw.
    lattice_cryptography_decrypt_rsa(PrivB, Bundle, Tag, _Plain).

% ---------------------------------------------------------------------------
% AC-PR49-004 — ECDH hybrid round-trip
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(ecdh_hybrid_roundtrip) :-
    % Generate a recipient ECDH key pair on prime256v1.
    lattice_cryptography_keygen_ecdh(prime256v1, RecipPriv, RecipPub),
    % Encrypt a secret value.
    lattice_cryptography_encrypt_ecdh(RecipPub, 'Password:hunter2', Bundle, Tag),
    % Decrypt the bundle using the recipient's private scalar.
    lattice_cryptography_decrypt_ecdh(RecipPriv, Bundle, Tag, Plain, prime256v1),
    % Assert the plaintext was recovered.
    Plain = 'Password:hunter2'.

% ---------------------------------------------------------------------------
% AC-PR49-005 — ECDH decryption with wrong private key fails
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(ecdh_wrong_key_fails, [throws(_)]) :-
    % Generate recipient key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, _RecipPriv, RecipPub),
    % Generate a different private scalar (wrong key).
    lattice_cryptography_keygen_ecdh(prime256v1, WrongPriv, _),
    % Encrypt a secret.
    lattice_cryptography_encrypt_ecdh(RecipPub, 'secret', Bundle, Tag),
    % Decrypt with wrong key — AES-GCM authentication must fail.
    lattice_cryptography_decrypt_ecdh(WrongPriv, Bundle, Tag, _Plain, prime256v1).

% ---------------------------------------------------------------------------
% AC-PR49-006 — lattice_cryptography_keygen_ecdh produces distinct public points
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(ecdh_keygen_distinct) :-
    % Generate the first key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, _Priv1, Pub1),
    % Generate the second key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, _Priv2, Pub2),
    % Assert the two public keys are not equal.
    Pub1 \= Pub2.

% ---------------------------------------------------------------------------
% AC-PR49-007 — lattice_cryptography_crypto_available/1 succeeds for RSA and ECDH
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(crypto_available_rsa) :-
    % Assert RSA availability.
    lattice_cryptography_crypto_available(lattice_cryptography_algo_rsa).

% Define a clause for 'test': succeed when the following conditions hold.
test(crypto_available_ecdh) :-
    % Assert ECDH availability.
    lattice_cryptography_crypto_available(lattice_cryptography_algo_ecdh).

% ---------------------------------------------------------------------------
% AC-PR49-008 — Generic dispatch for RSA via lattice_cryptography_encrypt/5
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(generic_dispatch_rsa) :-
    % Generate RSA keys.
    rsa_test_keys(PrivKey, PubKey),
    % Encrypt through the generic interface.
    lattice_cryptography_encrypt(lattice_cryptography_algo_rsa, PubKey, 'generic-rsa-secret', Bundle, Tag),
    % Decrypt through the generic interface.
    lattice_cryptography_decrypt(lattice_cryptography_algo_rsa, PrivKey, Bundle, Tag, Plain),
    % Assert the plaintext.
    Plain = 'generic-rsa-secret'.

% ---------------------------------------------------------------------------
% AC-PR49-009 — Generic dispatch for ECDH via lattice_cryptography_encrypt/5
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(generic_dispatch_ecdh) :-
    % Generate ECDH key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, RecipPriv, RecipPub),
    % Encrypt through the generic interface.
    lattice_cryptography_encrypt(lattice_cryptography_algo_ecdh, RecipPub, 'generic-ecdh-secret', Bundle, Tag),
    % Decrypt through the generic interface.
    lattice_cryptography_decrypt(lattice_cryptography_algo_ecdh, RecipPriv, Bundle, Tag, Plain),
    % Assert the plaintext.
    Plain = 'generic-ecdh-secret'.

% ---------------------------------------------------------------------------
% AC-PR49-010 — Tampered authentication tag causes decrypt failure
% ---------------------------------------------------------------------------

% Define a clause for 'test': succeed when the following conditions hold.
test(tampered_tag_fails, [throws(_)]) :-
    % Generate ECDH key pair.
    lattice_cryptography_keygen_ecdh(prime256v1, RecipPriv, RecipPub),
    % Encrypt a value.
    lattice_cryptography_encrypt_ecdh(RecipPub, 'tamper-test', Bundle, _Tag),
    % Forge a bogus tag (all zeros, 32 hex chars = 16 bytes).
    FakeTag = '00000000000000000000000000000000',
    % Attempt decryption with the forged tag — must throw.
    lattice_cryptography_decrypt_ecdh(RecipPriv, Bundle, FakeTag, _Plain, prime256v1).

% Execute the compile-time directive: end_tests(pr49).
:- end_tests(pr49).

% Execute the compile-time directive: initialization(run_tests(pr49), main).
:- initialization(run_tests(pr49), main).
