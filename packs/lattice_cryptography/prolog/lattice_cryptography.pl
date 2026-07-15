/*  PrologAI — Lattice Cryptographic Privacy Layer  (Specification Part 49, PR 49)

    This module protects sensitive data stored in the Lattice (passwords,
    credential tokens, identification numbers, and other private values)
    through hybrid encryption: an asymmetric algorithm wraps a one-time
    symmetric key; AES-256-GCM encrypts the payload with that key.

    Three asymmetric algorithm families are supported:

    RSA Hybrid  (lattice_cryptography_algo_rsa)
        A 2048-bit-or-larger RSA key pair is used.  The sender encrypts
        the 256-bit AES key with the recipient's RSA public key using
        PKCS#1 OAEP padding.  The recipient decrypts the AES key with
        their RSA private key, then decrypts the payload.

    ECDH Hybrid  (lattice_cryptography_algo_ecdh)
        An ephemeral EC key pair is generated on curve prime256v1
        (NIST P-256) for each encryption.  ECDH produces a shared
        secret; HKDF-SHA-256 derives the AES key from that secret.
        Only the ephemeral public key and the ciphertext need travel.

    PQC Hybrid  (lattice_cryptography_algo_pqc)
        ML-KEM-768 (CRYSTALS-Kyber, NIST FIPS 203) is used for key
        encapsulation.  This requires OpenSSL 3.2+ with the OQS provider
        installed (liboqs / openssl-oqs-provider).  If the OQS provider
        is not detected, the predicates raise a descriptive error rather
        than silently falling back to a weaker algorithm.

    Internal byte representation:
        Keys, IVs, and ciphertext are binary atoms (atom_codes gives bytes).
        Authentication tags from AES-GCM are byte lists, converted to hex
        before storage.  All bundle fields are stored as hex-encoded atoms.

    Bundle format (algorithm-specific compound terms):
        rsa_bundle(WrappedKeyHex, IVHex, CipherHex)
        ecdh_bundle(EphPubX, EphPubY, IVHex, CipherHex)
        pqc_bundle(Algorithm, EncapsKeyHex, IVHex, CipherHex)

    Exported predicates:

    Key generation:
        lattice_cryptography_keygen_rsa/3     +Bits, -PrivPEMFile, -PubPEMFile
        lattice_cryptography_keygen_ecdh/3    +Curve, -PrivInt, -PubPoint
        lattice_cryptography_keygen_pqc/2     +Algorithm, -KeyPair

    Encryption / decryption:
        lattice_cryptography_encrypt/5        +Algo, +PublicKey, +Plaintext, -Bundle, -Tag
        lattice_cryptography_decrypt/5        +Algo, +PrivateKey, +Bundle, +Tag, -Plaintext

    Convenience wrappers:
        lattice_cryptography_encrypt_rsa/4    +PubKey, +Plain, -Bundle, -Tag
        lattice_cryptography_decrypt_rsa/4    +PrivKey, +Bundle, +Tag, -Plain
        lattice_cryptography_encrypt_ecdh/5   +RecipPubPoint, +Plain, -Bundle, -Tag
        lattice_cryptography_decrypt_ecdh/5   +RecipPrivInt, +Bundle, +Tag, -Plain, +Curve
        lattice_cryptography_encrypt_pqc/5    +RecipPubKeyFile, +Plain, -Bundle, -Tag
        lattice_cryptography_decrypt_pqc/4    +RecipPrivKeyFile, +Bundle, +Tag, -Plain

    Utility:
        lattice_cryptography_crypto_available/1   ?Algorithm
        lattice_cryptography_pem_load_private/2   +PEMFile, -Key
        lattice_cryptography_pem_load_public/2    +PEMFile, -Key
*/

% Declare this file as the 'lattice_crypto' module and list its exported predicates.
:- module(lattice_cryptography, [
    % Continue the multi-line expression started above.
    lattice_cryptography_keygen_rsa/3,
    % Continue the multi-line expression started above.
    lattice_cryptography_keygen_ecdh/3,
    % Continue the multi-line expression started above.
    lattice_cryptography_keygen_pqc/2,
    % Continue the multi-line expression started above.
    lattice_cryptography_encrypt/5,
    % Continue the multi-line expression started above.
    lattice_cryptography_decrypt/5,
    % Continue the multi-line expression started above.
    lattice_cryptography_encrypt_rsa/4,
    % Continue the multi-line expression started above.
    lattice_cryptography_decrypt_rsa/4,
    % Continue the multi-line expression started above.
    lattice_cryptography_encrypt_ecdh/5,
    % Continue the multi-line expression started above.
    lattice_cryptography_decrypt_ecdh/5,
    % Continue the multi-line expression started above.
    lattice_cryptography_encrypt_pqc/5,
    % Continue the multi-line expression started above.
    lattice_cryptography_decrypt_pqc/4,
    % Continue the multi-line expression started above.
    lattice_cryptography_crypto_available/1,
    % Continue the multi-line expression started above.
    lattice_cryptography_pem_load_private/2,
    % Continue the multi-line expression started above.
    lattice_cryptography_pem_load_public/2
% Close the expression opened above.
]).

% Import the standard crypto predicates used throughout this module.
:- use_module(library(crypto)).
% Import process management for calling openssl.
:- use_module(library(process)).
% Import lists utilities.
:- use_module(library(lists)).
% Import apply utilities for foldl.
:- use_module(library(apply)).

% ---------------------------------------------------------------------------
% SECTION 1 — AVAILABILITY PROBE
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_crypto_available(?Algorithm)
% Succeeds if Algorithm is supported and ready to use.
% ERC
lattice_cryptography_crypto_available(lattice_cryptography_algo_rsa) :-
% ERC
    catch(process_create(path(openssl), [version],
% ERC
                         [stdout(null), stderr(null)]),
% ERC
          _, fail).
% ERC
lattice_cryptography_crypto_available(lattice_cryptography_algo_ecdh) :-
% ERC
    catch(crypto_name_curve(prime256v1, _), _, fail).
% ERC
lattice_cryptography_crypto_available(lattice_cryptography_algo_pqc) :-
% ERC
    lattice_cryptography_pqc_provider_present.

% ERC
% lattice_cryptography_pqc_provider_present/0
% Detects whether OpenSSL with the OQS provider is available.
% ERC
lattice_cryptography_pqc_provider_present :-
% ERC
    catch(
% ERC
        (   process_create(path(openssl),
% ERC
                           ['list', '-key-managers'],
% ERC
                           [stdout(string(Out)), stderr(null)]),
% ERC
            sub_string(Out, _, _, _, "ML-KEM")
% ERC
        ),
% ERC
        _, fail).

% ---------------------------------------------------------------------------
% SECTION 2 — PEM KEY LOADING UTILITIES
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_pem_load_private(+PEMFile, -Key)
% Load an RSA private key from a PEM file path.
% ERC
lattice_cryptography_pem_load_private(PEMFile, Key) :-
% ERC
    setup_call_cleanup(
% ERC
        open(PEMFile, read, Stream, []),
% ERC
        load_private_key(Stream, none, Key),
% ERC
        close(Stream)).

% ERC
% lattice_cryptography_pem_load_public(+PEMFile, -Key)
% Load an RSA public key from a PEM file path.
% ERC
lattice_cryptography_pem_load_public(PEMFile, Key) :-
% ERC
    setup_call_cleanup(
% ERC
        open(PEMFile, read, Stream, []),
% ERC
        load_public_key(Stream, Key),
% ERC
        close(Stream)).

% ---------------------------------------------------------------------------
% SECTION 3 — KEY GENERATION
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_keygen_rsa(+Bits, -PrivPEMFile, -PubPEMFile)
% Generate an RSA key pair; write PEM files; unify their paths.
% The caller is responsible for deleting the files when done.
% ERC
lattice_cryptography_keygen_rsa(Bits, PrivPEMFile, PubPEMFile) :-
% ERC
    integer(Bits), Bits >= 2048,
% ERC
    tmp_file(lattice_cryptography_rsa_priv, PrivPEMFile),
% ERC
    tmp_file(lattice_cryptography_rsa_pub, PubPEMFile),
% ERC
    number_string(Bits, BitsStr),
% ERC
    process_create(path(openssl),
% ERC
                   [genrsa, '-out', PrivPEMFile, BitsStr],
% ERC
                   [stdout(null), stderr(null)]),
% ERC
    process_create(path(openssl),
% ERC
                   [rsa, '-in', PrivPEMFile, '-pubout', '-out', PubPEMFile],
% ERC
                   [stdout(null), stderr(null)]).

% ERC
% lattice_cryptography_keygen_ecdh(+Curve, -PrivInt, -PubPoint)
% Generate an ephemeral ECDH key pair on the named curve.
% PrivInt is the private scalar (integer); PubPoint = point(X,Y).
% ERC
lattice_cryptography_keygen_ecdh(Curve, PrivInt, PubPoint) :-
% ERC
    crypto_name_curve(Curve, CurveHandle),
% ERC
    lattice_cryptography_random_scalar(PrivInt),
% ERC
    crypto_curve_generator(CurveHandle, Gen),
% ERC
    crypto_curve_scalar_mult(CurveHandle, PrivInt, Gen, PubPoint).

% ERC
% lattice_cryptography_keygen_pqc(+Algorithm, -KeyPair)
% Generate a PQC key pair via the OQS provider.
% Algorithm is e.g. 'ML-KEM-768'.
% ERC
lattice_cryptography_keygen_pqc(Algorithm, pqc_keypair(PrivPEMFile, PubPEMFile)) :-
% ERC
    (   lattice_cryptography_pqc_provider_present
% ERC
    ->  true
% ERC
    ;   throw(error(
% ERC
            lattice_cryptography_error(pqc_provider_unavailable,
% ERC
                'Install openssl-oqs-provider (liboqs) for PQC support.'),
% ERC
            lattice_cryptography_keygen_pqc/2))
% ERC
    ),
% ERC
    tmp_file(lattice_cryptography_pqc_priv, PrivPEMFile),
% ERC
    tmp_file(lattice_cryptography_pqc_pub, PubPEMFile),
% ERC
    atom_string(Algorithm, AlgoStr),
% ERC
    process_create(path(openssl),
% ERC
                   [genpkey, '-algorithm', AlgoStr, '-out', PrivPEMFile],
% ERC
                   [stdout(null), stderr(null)]),
% ERC
    process_create(path(openssl),
% ERC
                   [pkey, '-in', PrivPEMFile, '-pubout', '-out', PubPEMFile],
% ERC
                   [stdout(null), stderr(null)]).

% ---------------------------------------------------------------------------
% SECTION 4 — GENERIC ENCRYPT / DECRYPT DISPATCH
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_encrypt(+Algo, +PublicKey, +Plaintext, -Bundle, -Tag)
% Encrypt Plaintext using the given algorithm and public key.
% ERC
lattice_cryptography_encrypt(lattice_cryptography_algo_rsa, PubKey, Plaintext, Bundle, Tag) :-
% ERC
    lattice_cryptography_encrypt_rsa(PubKey, Plaintext, Bundle, Tag).
% ERC
lattice_cryptography_encrypt(lattice_cryptography_algo_ecdh, PubPoint, Plaintext, Bundle, Tag) :-
% ERC
    lattice_cryptography_encrypt_ecdh(prime256v1, PubPoint, Plaintext, Bundle, Tag).
% ERC
lattice_cryptography_encrypt(lattice_cryptography_algo_pqc, PubKeyFile, Plaintext, Bundle, Tag) :-
% ERC
    lattice_cryptography_encrypt_pqc('ML-KEM-768', PubKeyFile, Plaintext, Bundle, Tag).

% ERC
% lattice_cryptography_decrypt(+Algo, +PrivateKey, +Bundle, +Tag, -Plaintext)
% Decrypt Bundle using the given algorithm and private key.
% ERC
lattice_cryptography_decrypt(lattice_cryptography_algo_rsa, PrivKey, Bundle, Tag, Plaintext) :-
% ERC
    lattice_cryptography_decrypt_rsa(PrivKey, Bundle, Tag, Plaintext).
% ERC
lattice_cryptography_decrypt(lattice_cryptography_algo_ecdh, PrivInt, Bundle, Tag, Plaintext) :-
% ERC
    lattice_cryptography_decrypt_ecdh(prime256v1, PrivInt, Bundle, Tag, Plaintext).
% ERC
lattice_cryptography_decrypt(lattice_cryptography_algo_pqc, PrivKeyFile, Bundle, Tag, Plaintext) :-
% ERC
    lattice_cryptography_decrypt_pqc(PrivKeyFile, Bundle, Tag, Plaintext).

% ---------------------------------------------------------------------------
% SECTION 5 — RSA HYBRID ENCRYPTION
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_encrypt_rsa(+PubKey, +Plaintext, -Bundle, -Tag)
% ERC

% ERC
% lattice_cryptography_decrypt_rsa(+PrivKey, +Bundle, +Tag, -Plaintext)
% ERC

% ERC
% lattice_cryptography_encrypt_rsa(+PubKey, +Plaintext, -Bundle, -Tag)
% Hybrid encrypt:
%   1. Generate 256-bit AES key and 96-bit IV as byte atoms.
%   2. Encrypt Plaintext (as UTF-8) with AES-256-GCM; capture Tag bytes.
%   3. RSA-OAEP wrap the AES key atom with PubKey.
%   4. Encode all binary fields as hex; Tag bytes to hex.
% ERC
lattice_cryptography_encrypt_rsa(PubKey, Plaintext, Bundle, TagHex) :-
% ERC
    lattice_cryptography_random_bytes_atom(32, AesKeyAtom),
% ERC
    lattice_cryptography_random_bytes_atom(12, IVAtom),
% ERC
    atom_string(Plaintext, PlainStr),
% ERC
    crypto_data_encrypt(PlainStr, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        CipherAtom, [tag(TagBytes), encoding(utf8)]),
% ERC
    rsa_public_encrypt(PubKey, AesKeyAtom, WrappedKeyAtom, [padding(pkcs1_oaep)]),
% ERC
    lattice_cryptography_atom_to_hex(WrappedKeyAtom, WrappedKeyHex),
% ERC
    lattice_cryptography_atom_to_hex(IVAtom, IVHex),
% ERC
    lattice_cryptography_atom_to_hex(CipherAtom, CipherHex),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    Bundle = rsa_bundle(WrappedKeyHex, IVHex, CipherHex).

% ERC
% lattice_cryptography_decrypt_rsa(+PrivKey, +Bundle, +TagHex, -Plaintext)
% ERC
lattice_cryptography_decrypt_rsa(PrivKey,
% ERC
               rsa_bundle(WrappedKeyHex, IVHex, CipherHex),
% ERC
               TagHex, Plaintext) :-
% ERC
    lattice_cryptography_hex_to_atom(WrappedKeyHex, WrappedKeyAtom),
% ERC
    rsa_private_decrypt(PrivKey, WrappedKeyAtom, AesKeyAtom, [padding(pkcs1_oaep)]),
% ERC
    lattice_cryptography_hex_to_atom(IVHex, IVAtom),
% ERC
    lattice_cryptography_hex_to_atom(CipherHex, CipherAtom),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    crypto_data_decrypt(CipherAtom, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        PlainStr, [tag(TagBytes), encoding(utf8)]),
% ERC
    atom_string(Plaintext, PlainStr).

% ---------------------------------------------------------------------------
% SECTION 6 — ECDH HYBRID ENCRYPTION
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_encrypt_ecdh(+RecipPubPoint, +Plaintext, -Bundle, -Tag)
% ERC

% ERC
% lattice_cryptography_decrypt_ecdh(+RecipPrivInt, +Bundle, +Tag, -Plaintext, +Curve)
% ERC

% ERC
% lattice_cryptography_encrypt_ecdh(+Curve, +RecipPub, +Plaintext, -Bundle, -Tag)
% ECDH hybrid encrypt:
%   1. Generate ephemeral (EphPriv, EphPub) on Curve.
%   2. Compute shared point = EphPriv * RecipPub via ECDH.
%   3. Derive 256-bit AES key from shared point X via HKDF-SHA-256.
%   4. Encrypt with AES-256-GCM; capture Tag bytes.
%   5. Bundle = ecdh_bundle(EphPubX, EphPubY, IVHex, CipherHex).
% ERC
lattice_cryptography_encrypt_ecdh(Curve, RecipPub, Plaintext, Bundle, TagHex) :-
% ERC
    crypto_name_curve(Curve, CurveHandle),
% ERC
    crypto_curve_generator(CurveHandle, Gen),
% ERC
    lattice_cryptography_random_scalar(EphPriv),
% ERC
    crypto_curve_scalar_mult(CurveHandle, EphPriv, Gen, EphPub),
% ERC
    EphPub = point(EphPubX, EphPubY),
% ERC
    crypto_curve_scalar_mult(CurveHandle, EphPriv, RecipPub, SharedPoint),
% ERC
    SharedPoint = point(SharedX, _),
% ERC
    lattice_cryptography_derive_aes_key_atom(SharedX, AesKeyAtom),
% ERC
    lattice_cryptography_random_bytes_atom(12, IVAtom),
% ERC
    atom_string(Plaintext, PlainStr),
% ERC
    crypto_data_encrypt(PlainStr, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        CipherAtom, [tag(TagBytes), encoding(utf8)]),
% ERC
    lattice_cryptography_atom_to_hex(IVAtom, IVHex),
% ERC
    lattice_cryptography_atom_to_hex(CipherAtom, CipherHex),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    Bundle = ecdh_bundle(EphPubX, EphPubY, IVHex, CipherHex).

% ERC
% lattice_cryptography_decrypt_ecdh(+Curve, +RecipPriv, +Bundle, +TagHex, -Plaintext)
% ERC
lattice_cryptography_decrypt_ecdh(Curve, RecipPriv,
% ERC
                ecdh_bundle(EphPubX, EphPubY, IVHex, CipherHex),
% ERC
                TagHex, Plaintext) :-
% ERC
    crypto_name_curve(Curve, CurveHandle),
% ERC
    EphPub = point(EphPubX, EphPubY),
% ERC
    crypto_curve_scalar_mult(CurveHandle, RecipPriv, EphPub, SharedPoint),
% ERC
    SharedPoint = point(SharedX, _),
% ERC
    lattice_cryptography_derive_aes_key_atom(SharedX, AesKeyAtom),
% ERC
    lattice_cryptography_hex_to_atom(IVHex, IVAtom),
% ERC
    lattice_cryptography_hex_to_atom(CipherHex, CipherAtom),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    crypto_data_decrypt(CipherAtom, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        PlainStr, [tag(TagBytes), encoding(utf8)]),
% ERC
    atom_string(Plaintext, PlainStr).

% ---------------------------------------------------------------------------
% SECTION 7 — PQC HYBRID ENCRYPTION  (requires OQS provider)
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_encrypt_pqc(+RecipPubKeyFile, +Plaintext, -Bundle, -Tag)
% ERC

% ERC
% lattice_cryptography_decrypt_pqc(+RecipPrivKeyFile, +Bundle, +Tag, -Plaintext)
% ERC

% ERC
% lattice_cryptography_encrypt_pqc(+Algorithm, +RecipPubKeyFile, +Plaintext, -Bundle, -Tag)
% PQC hybrid encrypt using ML-KEM key encapsulation.
% Requires OQS provider; throws lattice_cryptography_error if absent.
% ERC
lattice_cryptography_encrypt_pqc(Algorithm, RecipPubKeyFile, Plaintext, Bundle, TagHex) :-
% ERC
    lattice_cryptography_require_pqc_provider(lattice_cryptography_encrypt_pqc/5),
% ERC
    tmp_file(lattice_cryptography_pqc_encap, EncapFile),
% ERC
    tmp_file(lattice_cryptography_pqc_secret, SecretFile),
% ERC
    process_create(path(openssl),
% ERC
                   [pkeyutl, '-encap',
% ERC
                    '-pubin', '-inkey', RecipPubKeyFile,
% ERC
                    '-secret', SecretFile,
% ERC
                    '-out', EncapFile],
% ERC
                   [stdout(null), stderr(null)]),
% ERC
    read_file_to_codes(EncapFile, EncapCodes, [encoding(octet)]),
% ERC
    read_file_to_codes(SecretFile, SecretCodes, [encoding(octet)]),
% ERC
    catch(delete_file(EncapFile), _, true),
% ERC
    catch(delete_file(SecretFile), _, true),
% ERC
    hex_bytes(EncapHex, EncapCodes),
% ERC
    atom_codes(SecretAtom, SecretCodes),
% ERC
    crypto_data_hkdf(SecretAtom, 32, AesKeyBytes,
% ERC
                     [algorithm(sha256), info('pai-pqc-aes-key')]),
% ERC
    atom_codes(AesKeyAtom, AesKeyBytes),
% ERC
    lattice_cryptography_random_bytes_atom(12, IVAtom),
% ERC
    atom_string(Plaintext, PlainStr),
% ERC
    crypto_data_encrypt(PlainStr, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        CipherAtom, [tag(TagBytes), encoding(utf8)]),
% ERC
    lattice_cryptography_atom_to_hex(IVAtom, IVHex),
% ERC
    lattice_cryptography_atom_to_hex(CipherAtom, CipherHex),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    Bundle = pqc_bundle(Algorithm, EncapHex, IVHex, CipherHex).

% ERC
% lattice_cryptography_decrypt_pqc(+RecipPrivKeyFile, +Bundle, +TagHex, -Plaintext)
% ERC
lattice_cryptography_decrypt_pqc(RecipPrivKeyFile,
% ERC
               pqc_bundle(_Algo, EncapHex, IVHex, CipherHex),
% ERC
               TagHex, Plaintext) :-
% ERC
    lattice_cryptography_require_pqc_provider(lattice_cryptography_decrypt_pqc/4),
% ERC
    hex_bytes(EncapHex, EncapBytes),
% ERC
    tmp_file(lattice_cryptography_pqc_decap_in, EncapInFile),
% ERC
    tmp_file(lattice_cryptography_pqc_decap_secret, SecretOutFile),
% ERC
    lattice_cryptography_write_bytes_to_file(EncapInFile, EncapBytes),
% ERC
    process_create(path(openssl),
% ERC
                   [pkeyutl, '-decap',
% ERC
                    '-inkey', RecipPrivKeyFile,
% ERC
                    '-in', EncapInFile,
% ERC
                    '-secret', SecretOutFile],
% ERC
                   [stdout(null), stderr(null)]),
% ERC
    read_file_to_codes(SecretOutFile, SecretCodes, [encoding(octet)]),
% ERC
    catch(delete_file(EncapInFile), _, true),
% ERC
    catch(delete_file(SecretOutFile), _, true),
% ERC
    atom_codes(SecretAtom, SecretCodes),
% ERC
    crypto_data_hkdf(SecretAtom, 32, AesKeyBytes,
% ERC
                     [algorithm(sha256), info('pai-pqc-aes-key')]),
% ERC
    atom_codes(AesKeyAtom, AesKeyBytes),
% ERC
    lattice_cryptography_hex_to_atom(IVHex, IVAtom),
% ERC
    lattice_cryptography_hex_to_atom(CipherHex, CipherAtom),
% ERC
    hex_bytes(TagHex, TagBytes),
% ERC
    crypto_data_decrypt(CipherAtom, 'aes-256-gcm', AesKeyAtom, IVAtom,
% ERC
                        PlainStr, [tag(TagBytes), encoding(utf8)]),
% ERC
    atom_string(Plaintext, PlainStr).

% ERC
% lattice_cryptography_require_pqc_provider(+Caller)
% Throws an informative error if the OQS provider is not available.
% ERC
lattice_cryptography_require_pqc_provider(Caller) :-
% ERC
    (   lattice_cryptography_pqc_provider_present
% ERC
    ->  true
% ERC
    ;   throw(error(
% ERC
            lattice_cryptography_error(pqc_provider_unavailable,
% ERC
                'Install openssl-oqs-provider (liboqs) to enable PQC operations.'),
% ERC
            Caller))
% ERC
    ).

% ---------------------------------------------------------------------------
% SECTION 8 — INTERNAL UTILITY PREDICATES
% ---------------------------------------------------------------------------

% ERC
% lattice_cryptography_random_scalar(-PrivInt)
% Generate a cryptographically random 256-bit integer (private scalar).
% ERC
lattice_cryptography_random_scalar(PrivInt) :-
% ERC
    crypto_n_random_bytes(32, Bytes),
% ERC
    foldl([B, Acc, NAcc]>>(NAcc is Acc * 256 + B), Bytes, 0, PrivInt).

% ERC
% lattice_cryptography_random_bytes_atom(+N, -Atom)
% Generate N cryptographically random bytes and pack them into a binary atom.
% ERC
lattice_cryptography_random_bytes_atom(N, Atom) :-
% ERC
    crypto_n_random_bytes(N, Bytes),
% ERC
    atom_codes(Atom, Bytes).

% ERC
% lattice_cryptography_atom_to_hex(+BinaryAtom, -HexAtom)
% Encode a binary atom as a lowercase hexadecimal atom.
% ERC
lattice_cryptography_atom_to_hex(BinaryAtom, HexAtom) :-
% ERC
    atom_codes(BinaryAtom, Bytes),
% ERC
    hex_bytes(HexAtom, Bytes).

% ERC
% lattice_cryptography_hex_to_atom(+HexAtom, -BinaryAtom)
% Decode a hexadecimal atom to a binary atom.
% ERC
lattice_cryptography_hex_to_atom(HexAtom, BinaryAtom) :-
% ERC
    hex_bytes(HexAtom, Bytes),
% ERC
    atom_codes(BinaryAtom, Bytes).

% ERC
% lattice_cryptography_derive_aes_key_atom(+SharedX, -AesKeyAtom)
% Derive a 256-bit AES key atom from an ECDH shared secret X-coordinate
% using HKDF-SHA-256 with the fixed info label 'pai-ecdh-aes-key'.
% ERC
lattice_cryptography_derive_aes_key_atom(SharedX, AesKeyAtom) :-
% ERC
    number_codes(SharedX, XCodes),
% ERC
    atom_codes(XAtom, XCodes),
% ERC
    crypto_data_hkdf(XAtom, 32, AesKeyBytes,
% ERC
                     [algorithm(sha256), info('pai-ecdh-aes-key')]),
% ERC
    atom_codes(AesKeyAtom, AesKeyBytes).

% ERC
% lattice_cryptography_write_bytes_to_file(+File, +ByteList)
% Write a list of byte integers to a file in octet mode.
% ERC
lattice_cryptography_write_bytes_to_file(File, ByteList) :-
% ERC
    setup_call_cleanup(
% ERC
        open(File, write, Stream, [encoding(octet)]),
% ERC
        maplist(put_byte(Stream), ByteList),
% ERC
        close(Stream)).
