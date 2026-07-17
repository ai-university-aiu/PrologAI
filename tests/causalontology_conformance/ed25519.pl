% Module: ed25519_impl — pure SWI-Prolog Ed25519 (RFC 8032, edwards25519, SHA-512).
% A faithful port of the reference pure-Python implementation, using SWI's
% unbounded integers for curve arithmetic and library(sha) for SHA-512.
% Byte strings are represented as Prolog lists of integers in the range 0..255.
% Public interface: ed25519_secret_to_public/2, ed25519_sign/3, ed25519_verify/3.
% Hex helpers ed25519_hex_to_bytes/2 and ed25519_bytes_to_hex/2 are also exported.
% Slow but correct: intended for conformance and small tools, not production speed.

% Declare the module and export exactly the required public predicates plus hex helpers.
:- module(ed25519_impl,
          [ ed25519_secret_to_public/2,
            ed25519_sign/3,
            ed25519_verify/3,
            ed25519_hex_to_bytes/2,
            ed25519_bytes_to_hex/2,
            ed25519_selftest/0
          ]).

% Pull in library(sha) for the SHA-512 hash primitive.
:- use_module(library(sha)).

% ---------------------------------------------------------------------------
% Curve constants
% ---------------------------------------------------------------------------

% The field prime p = 2^255 - 19 for edwards25519.
ed25519_p(P) :-
    % Compute two-to-the-255 minus nineteen.
    P is 2^255 - 19.

% The group order q = 2^252 + 27742317777372353535851937790883648493.
ed25519_q(Q) :-
    % Compute two-to-the-252 plus the RFC 8032 constant.
    Q is 2^252 + 27742317777372353535851937790883648493.

% ---------------------------------------------------------------------------
% Hashing
% ---------------------------------------------------------------------------

% Compute the SHA-512 digest of a byte list, returning a 64-byte list.
ed25519_sha512(Bytes, Digest) :-
    % Delegate to library(sha) requesting sha512 with octet encoding so each list element is one raw byte.
    sha_hash(Bytes, Digest, [algorithm(sha512), encoding(octet)]).

% ---------------------------------------------------------------------------
% Modular field arithmetic
% ---------------------------------------------------------------------------

% Compute Base^Exp mod Mod by square-and-multiply (SWI's ^ would otherwise fully expand the power).
ed25519_modpow(Base, Exp, Mod, Result) :-
    % Reduce the base modulo Mod before starting the ladder.
    B0 is Base mod Mod,
    % Begin the accumulator at one and iterate over the exponent bits.
    ed25519_modpow_(Exp, B0, Mod, 1, Result).

% Base case: when the exponent is exhausted, the accumulator is the answer.
ed25519_modpow_(0, _, _, Acc, Acc) :- !.
% Inductive case: fold in the current base when the low exponent bit is set, then square.
ed25519_modpow_(Exp, Base, Mod, Acc0, Result) :-
    % Multiply the accumulator by the base when the lowest exponent bit is one.
    ( (Exp /\ 1) =:= 1 -> Acc1 is Acc0 * Base mod Mod ; Acc1 = Acc0 ),
    % Square the base modulo Mod for the next bit position.
    Base2 is Base * Base mod Mod,
    % Shift the exponent right by one bit.
    Exp1 is Exp >> 1,
    % Recurse over the remaining exponent bits.
    ed25519_modpow_(Exp1, Base2, Mod, Acc1, Result).

% Compute the modular inverse of X modulo p via Fermat: X^(p-2) mod p.
ed25519_modp_inv(X, Inv) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Compute the exponent p-2.
    E is P - 2,
    % Raise X to the (p-2) power modulo p using square-and-multiply.
    ed25519_modpow(X, E, P, Inv).

% The curve constant d = -121665 * inverse(121666) mod p.
ed25519_d(D) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Invert 121666 modulo p.
    ed25519_modp_inv(121666, Inv),
    % Multiply by -121665 and reduce modulo p (Prolog mod yields a non-negative result).
    D is (-121665 * Inv) mod P.

% The square root of -1 modulo p, namely 2^((p-1)/4) mod p.
ed25519_modp_sqrt_m1(R) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Compute the exponent (p-1)/4.
    E is (P - 1) // 4,
    % Raise 2 to that power modulo p using square-and-multiply.
    ed25519_modpow(2, E, P, R).

% ---------------------------------------------------------------------------
% Extended (X,Y,Z,T) point arithmetic
% ---------------------------------------------------------------------------

% Add two extended points P and Q on edwards25519, yielding their sum.
ed25519_point_add(point(PX, PY, PZ, PT), point(QX, QY, QZ, QT), point(RX, RY, RZ, RT)) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Fetch the curve constant d.
    ed25519_d(D),
    % A = (PY - PX) * (QY - QX) mod p.
    A is (PY - PX) * (QY - QX) mod P,
    % B = (PY + PX) * (QY + QX) mod p.
    B is (PY + PX) * (QY + QX) mod P,
    % C = 2 * PT * QT * d mod p.
    C is 2 * PT * QT * D mod P,
    % Dd = 2 * PZ * QZ mod p.
    Dd is 2 * PZ * QZ mod P,
    % E = B - A.
    E is B - A,
    % F = Dd - C.
    F is Dd - C,
    % G = Dd + C.
    G is Dd + C,
    % H = B + A.
    H is B + A,
    % The result X-coordinate is E * F mod p.
    RX is E * F mod P,
    % The result Y-coordinate is G * H mod p.
    RY is G * H mod P,
    % The result Z-coordinate is F * G mod p.
    RZ is F * G mod P,
    % The result T-coordinate is E * H mod p.
    RT is E * H mod P.

% Multiply point P by scalar S using the double-and-add ladder.
ed25519_point_mul(S, P, Q) :-
    % Start the accumulator at the neutral element (0,1,1,0).
    ed25519_point_mul_(S, P, point(0, 1, 1, 0), Q).

% Base case: when the scalar has been exhausted, the accumulator is the answer.
ed25519_point_mul_(0, _, Acc, Acc) :- !.
% Inductive case: process the lowest bit of the scalar, then halve it.
ed25519_point_mul_(S, P, Acc0, Q) :-
    % Extract the least-significant bit of the scalar.
    Bit is S /\ 1,
    % Conditionally add P into the accumulator when the bit is set.
    ed25519_cond_add(Bit, Acc0, P, Acc1),
    % Double the running point P for the next bit position.
    ed25519_point_add(P, P, P2),
    % Shift the scalar right by one bit.
    S1 is S >> 1,
    % Recurse on the remaining higher bits.
    ed25519_point_mul_(S1, P2, Acc1, Q).

% When the current bit is zero, leave the accumulator unchanged.
ed25519_cond_add(0, Acc, _, Acc) :- !.
% When the current bit is one, add the point into the accumulator.
ed25519_cond_add(1, Acc0, P, Acc1) :-
    % Perform the point addition.
    ed25519_point_add(Acc0, P, Acc1).

% Test projective equality of two extended points P and Q.
ed25519_point_equal(point(PX, PY, PZ, _), point(QX, QY, QZ, _)) :-
    % Fetch the field prime.
    ed25519_p(P),
    % The cross-multiplied X-coordinates must agree modulo p.
    0 =:= (PX * QZ - QX * PZ) mod P,
    % The cross-multiplied Y-coordinates must agree modulo p.
    0 =:= (PY * QZ - QY * PZ) mod P.

% ---------------------------------------------------------------------------
% x-coordinate recovery
% ---------------------------------------------------------------------------

% Recover the x-coordinate for a given y and sign bit, or fail if none exists.
ed25519_recover_x(Y, _, _) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Reject any y that is not a canonical field element.
    Y >= P,
    % Signal failure for an out-of-range y.
    !,
    fail.
ed25519_recover_x(Y, Sign, X) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Fetch the curve constant d.
    ed25519_d(D),
    % Compute x^2 = (y*y - 1) * inverse(d*y*y + 1) mod p.
    ed25519_modp_inv(D * Y * Y + 1, Denom),
    % Form the candidate squared x value.
    X2 is (Y * Y - 1) * Denom mod P,
    % Dispatch on whether the squared value is zero.
    ed25519_recover_x_from_x2(X2, Sign, P, X).

% When x^2 is zero, x is zero unless the sign bit demands a non-zero root (then fail).
ed25519_recover_x_from_x2(0, Sign, _, X) :-
    % Guard this clause to the zero case.
    !,
    % A sign bit of zero admits x = 0; a sign bit of one has no such root.
    Sign =:= 0,
    % Bind the recovered x to zero.
    X = 0.
% When x^2 is non-zero, take the square root and fix its sign.
ed25519_recover_x_from_x2(X2, Sign, P, X) :-
    % Compute the tentative root x = x2^((p+3)/8) mod p via square-and-multiply.
    ed25519_modpow(X2, (P + 3) // 8, P, X0),
    % If x0 squared does not match x2, multiply by sqrt(-1) to get the other root.
    ed25519_fix_sqrt(X0, X2, P, X1),
    % Verify that the (possibly corrected) root squares back to x2.
    0 =:= (X1 * X1 - X2) mod P,
    % Adjust the root so its low bit matches the requested sign.
    ed25519_fix_sign(X1, Sign, P, X).

% When the candidate root already squares to x2, keep it unchanged.
ed25519_fix_sqrt(X0, X2, P, X0) :-
    % Test whether x0*x0 equals x2 modulo p.
    0 =:= (X0 * X0 - X2) mod P,
    % Commit to this clause when the test passes.
    !.
% Otherwise multiply the candidate by the modular square root of -1.
ed25519_fix_sqrt(X0, _, P, X1) :-
    % Fetch the sqrt(-1) constant.
    ed25519_modp_sqrt_m1(SqrtM1),
    % Produce the alternate square root candidate.
    X1 is X0 * SqrtM1 mod P.

% When the root's parity already matches the sign bit, keep it.
ed25519_fix_sign(X, Sign, _, X) :-
    % Test whether the low bit of x equals the requested sign.
    (X /\ 1) =:= Sign,
    % Commit to this clause when the parity matches.
    !.
% Otherwise negate the root modulo p to flip its parity.
ed25519_fix_sign(X0, _, P, X1) :-
    % Compute p - x0 as the parity-flipped root.
    X1 is P - X0.

% ---------------------------------------------------------------------------
% The base point G
% ---------------------------------------------------------------------------

% Construct the standard base point G = (Gx, Gy, 1, Gx*Gy mod p).
ed25519_base_point(point(GX, GY, 1, GT)) :-
    % Fetch the field prime.
    ed25519_p(P),
    % The base y-coordinate is 4 * inverse(5) mod p.
    ed25519_modp_inv(5, Inv5),
    % Form Gy from four fifths.
    GY is 4 * Inv5 mod P,
    % Recover Gx from Gy with sign bit zero.
    ed25519_recover_x(GY, 0, GX),
    % The extended T-coordinate is Gx * Gy mod p.
    GT is GX * GY mod P.

% ---------------------------------------------------------------------------
% Point compression and decompression
% ---------------------------------------------------------------------------

% Compress an extended point to its 32-byte little-endian encoding.
ed25519_point_compress(point(PX, PY, PZ, _), Bytes) :-
    % Fetch the field prime.
    ed25519_p(P),
    % Invert the Z-coordinate to move to affine form.
    ed25519_modp_inv(PZ, ZInv),
    % Recover the affine x-coordinate.
    X is PX * ZInv mod P,
    % Recover the affine y-coordinate.
    Y is PY * ZInv mod P,
    % Encode y with the low bit of x folded into bit 255.
    Enc is Y \/ ((X /\ 1) << 255),
    % Convert the 256-bit integer to 32 little-endian bytes.
    ed25519_int_to_bytes_le(Enc, 32, Bytes).

% Decompress a 32-byte encoding into an extended point, or fail if invalid.
ed25519_point_decompress(Bytes, point(X, Y, 1, T)) :-
    % Require exactly 32 input bytes.
    length(Bytes, 32),
    % Fetch the field prime.
    ed25519_p(P),
    % Interpret the bytes as a little-endian integer.
    ed25519_bytes_to_int_le(Bytes, Enc),
    % The sign bit is the top (bit 255) of the encoding.
    Sign is Enc >> 255,
    % Mask off the sign bit to obtain the y-coordinate.
    Y is Enc /\ ((1 << 255) - 1),
    % Recover x from y and the sign bit (fails if no valid root).
    ed25519_recover_x(Y, Sign, X),
    % Reconstruct the extended T-coordinate as x*y mod p.
    T is X * Y mod P.

% ---------------------------------------------------------------------------
% Secret-key expansion and hash-to-scalar
% ---------------------------------------------------------------------------

% Expand a 32-byte secret into a clamped scalar A and a 32-byte prefix.
ed25519_secret_expand(Secret, A, Prefix) :-
    % Require exactly 32 secret bytes.
    length(Secret, 32),
    % Hash the secret with SHA-512 into 64 bytes.
    ed25519_sha512(Secret, H),
    % Split the digest into the low 32 bytes and the high 32 bytes.
    length(Low, 32),
    % Append the two halves to expose Low (scalar source) and Prefix.
    append(Low, Prefix, H),
    % Interpret the low half as a little-endian integer.
    ed25519_bytes_to_int_le(Low, A0),
    % Clamp: clear the low three bits and the top bit region per RFC 8032.
    A1 is A0 /\ ((1 << 254) - 8),
    % Set bit 254 to fix the scalar's high bit.
    A is A1 \/ (1 << 254).

% Hash a byte list with SHA-512 and reduce the result modulo the group order.
ed25519_sha512_modq(Bytes, R) :-
    % Fetch the group order.
    ed25519_q(Q),
    % Compute the SHA-512 digest of the input.
    ed25519_sha512(Bytes, H),
    % Interpret the 64-byte digest as a little-endian integer.
    ed25519_bytes_to_int_le(H, N),
    % Reduce that integer modulo q.
    R is N mod Q.

% ---------------------------------------------------------------------------
% Public interface
% ---------------------------------------------------------------------------

% Derive the 32-byte public key from a 32-byte secret seed.
ed25519_secret_to_public(Seed32, Public32) :-
    % Expand the seed into a clamped scalar (the prefix is unused here).
    ed25519_secret_expand(Seed32, A, _),
    % Fetch the base point G.
    ed25519_base_point(G),
    % Multiply G by the scalar to obtain the public point.
    ed25519_point_mul(A, G, Pub),
    % Compress the public point to 32 bytes.
    ed25519_point_compress(Pub, Public32).

% Produce the deterministic 64-byte Ed25519 signature of a message.
ed25519_sign(Seed32, Message, Signature64) :-
    % Expand the seed into the clamped scalar and the prefix.
    ed25519_secret_expand(Seed32, A, Prefix),
    % Fetch the base point G.
    ed25519_base_point(G),
    % Compute the public point and compress it to bytes A_bytes.
    ed25519_point_mul(A, G, PubPoint),
    % Encode the public key for use in the challenge hash.
    ed25519_point_compress(PubPoint, ABytes),
    % Form the deterministic nonce r = H(prefix || message) mod q.
    append(Prefix, Message, PrefixMsg),
    % Reduce the nonce hash modulo the group order.
    ed25519_sha512_modq(PrefixMsg, R),
    % Compute the commitment point R = r*G and compress it.
    ed25519_point_mul(R, G, RPoint),
    % Encode the commitment as Rs bytes.
    ed25519_point_compress(RPoint, Rs),
    % Build the challenge input Rs || A_bytes || message.
    append(Rs, ABytes, RsA),
    % Append the message to complete the challenge input.
    append(RsA, Message, ChallengeInput),
    % Compute the challenge scalar h = H(Rs || A || M) mod q.
    ed25519_sha512_modq(ChallengeInput, HScalar),
    % Fetch the group order for the final reduction.
    ed25519_q(Q),
    % Compute s = (r + h*a) mod q.
    S is (R + HScalar * A) mod Q,
    % Encode s as 32 little-endian bytes.
    ed25519_int_to_bytes_le(S, 32, SBytes),
    % Concatenate Rs and the s-bytes into the 64-byte signature.
    append(Rs, SBytes, Signature64).

% Verify a 64-byte signature of a message under a 32-byte public key (semidet).
ed25519_verify(Public32, Message, Signature64) :-
    % The public key must be exactly 32 bytes.
    length(Public32, 32),
    % The signature must be exactly 64 bytes.
    length(Signature64, 64),
    % Decompress the public key into a point (fails if malformed).
    ed25519_point_decompress(Public32, A),
    % Split the signature into the 32-byte Rs and the 32-byte s parts.
    length(Rs, 32),
    % Append yields Rs (commitment bytes) and SBytes (scalar bytes).
    append(Rs, SBytes, Signature64),
    % Decompress the commitment bytes into a point R (fails if malformed).
    ed25519_point_decompress(Rs, R),
    % Interpret the scalar bytes as a little-endian integer s.
    ed25519_bytes_to_int_le(SBytes, S),
    % Fetch the group order.
    ed25519_q(Q),
    % Reject any s that is not less than the group order.
    S < Q,
    % Build the challenge input Rs || public || message.
    append(Rs, Public32, RsPub),
    % Append the message to complete the challenge input.
    append(RsPub, Message, ChallengeInput),
    % Compute the challenge scalar h = H(Rs || A || M) mod q.
    ed25519_sha512_modq(ChallengeInput, HScalar),
    % Fetch the base point G.
    ed25519_base_point(G),
    % Compute sB = s*G.
    ed25519_point_mul(S, G, SB),
    % Compute hA = h*A.
    ed25519_point_mul(HScalar, A, HA),
    % Compute R + hA.
    ed25519_point_add(R, HA, RHA),
    % The signature is valid iff sB equals R + hA projectively.
    ed25519_point_equal(SB, RHA).

% ---------------------------------------------------------------------------
% Little-endian integer <-> byte-list conversion
% ---------------------------------------------------------------------------

% Convert a non-negative integer to a fixed-length little-endian byte list.
ed25519_int_to_bytes_le(_, 0, []) :- !.
% Peel off the low byte and recurse on the remaining higher bytes.
ed25519_int_to_bytes_le(N, Len, [Byte | Rest]) :-
    % Insist on a positive remaining length.
    Len > 0,
    % Extract the least-significant byte.
    Byte is N /\ 0xff,
    % Shift the integer right by eight bits.
    N1 is N >> 8,
    % Decrement the remaining length.
    Len1 is Len - 1,
    % Recurse to emit the next byte.
    ed25519_int_to_bytes_le(N1, Len1, Rest).

% Convert a little-endian byte list to a non-negative integer.
ed25519_bytes_to_int_le(Bytes, N) :-
    % Fold the bytes from most-significant (list tail) to least, starting at zero.
    ed25519_bytes_to_int_le_(Bytes, 0, 1, N).

% Base case: an empty byte list contributes nothing further to the accumulator.
ed25519_bytes_to_int_le_([], Acc, _, Acc).
% Inductive case: add the current byte times its positional weight.
ed25519_bytes_to_int_le_([B | Bs], Acc0, Weight, N) :-
    % Accumulate this byte scaled by its little-endian weight.
    Acc1 is Acc0 + B * Weight,
    % Advance the weight by one byte (multiply by 256).
    Weight1 is Weight << 8,
    % Recurse over the remaining bytes.
    ed25519_bytes_to_int_le_(Bs, Acc1, Weight1, N).

% ---------------------------------------------------------------------------
% Hex helpers
% ---------------------------------------------------------------------------

% Convert a lowercase hex atom or string to a byte list.
ed25519_hex_to_bytes(Hex, Bytes) :-
    % Normalize the input into a list of character codes.
    ed25519_text_codes(Hex, Codes),
    % Pair up successive hex-digit codes into bytes.
    ed25519_hex_codes_to_bytes(Codes, Bytes).

% Turn an atom, string, or code list into a list of character codes.
ed25519_text_codes(Text, Codes) :-
    % An atom is converted with atom_codes.
    ( atom(Text) -> atom_codes(Text, Codes)
    % A string is converted with string_codes.
    ; string(Text) -> string_codes(Text, Codes)
    % Anything else is assumed to already be a code list.
    ; Codes = Text
    ).

% Base case: no hex digits remain, so no bytes remain.
ed25519_hex_codes_to_bytes([], []) :- !.
% Inductive case: consume two hex-digit codes to form one byte.
ed25519_hex_codes_to_bytes([HiCode, LoCode | Rest], [Byte | Bytes]) :-
    % Decode the high nibble digit.
    ed25519_hex_digit(HiCode, Hi),
    % Decode the low nibble digit.
    ed25519_hex_digit(LoCode, Lo),
    % Combine the two nibbles into a byte value.
    Byte is Hi * 16 + Lo,
    % Recurse over the remaining digit pairs.
    ed25519_hex_codes_to_bytes(Rest, Bytes).

% Map a single hex-digit character code to its 0..15 nibble value.
ed25519_hex_digit(Code, Value) :-
    % Digits 0..9 map directly by subtracting the code of '0'.
    ( Code >= 0'0, Code =< 0'9 -> Value is Code - 0'0
    % Lowercase a..f map by subtracting the code of 'a' and adding ten.
    ; Code >= 0'a, Code =< 0'f -> Value is Code - 0'a + 10
    % Uppercase A..F map by subtracting the code of 'A' and adding ten.
    ; Code >= 0'A, Code =< 0'F -> Value is Code - 0'A + 10
    ).

% Convert a byte list to a lowercase hex atom.
ed25519_bytes_to_hex(Bytes, Hex) :-
    % Expand each byte into its two lowercase hex-digit codes.
    ed25519_bytes_to_hex_codes(Bytes, Codes),
    % Assemble the digit codes into a single atom.
    atom_codes(Hex, Codes).

% Base case: no bytes remain, so no hex-digit codes remain.
ed25519_bytes_to_hex_codes([], []) :- !.
% Inductive case: expand one byte into its high and low nibble codes.
ed25519_bytes_to_hex_codes([Byte | Bytes], [HiCode, LoCode | Rest]) :-
    % Extract the high nibble.
    Hi is (Byte >> 4) /\ 0xf,
    % Extract the low nibble.
    Lo is Byte /\ 0xf,
    % Encode the high nibble as a lowercase hex-digit code.
    ed25519_nibble_code(Hi, HiCode),
    % Encode the low nibble as a lowercase hex-digit code.
    ed25519_nibble_code(Lo, LoCode),
    % Recurse over the remaining bytes.
    ed25519_bytes_to_hex_codes(Bytes, Rest).

% Map a 0..15 nibble value to its lowercase hex-digit character code.
ed25519_nibble_code(N, Code) :-
    % Values 0..9 map to the codes of '0'..'9'.
    ( N < 10 -> Code is 0'0 + N
    % Values 10..15 map to the codes of 'a'..'f'.
    ; Code is 0'a + N - 10
    ).

% ---------------------------------------------------------------------------
% Self-test against RFC 8032 test vectors
% ---------------------------------------------------------------------------

% Run the two RFC 8032 test vectors plus a negative check, printing PASS/FAIL.
ed25519_selftest :-
    % Announce the start of the self-test.
    format("Ed25519 RFC 8032 self-test~n", []),
    % Run test vector one and capture whether it passed.
    ( ed25519_selftest_vector(1,
        "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
        "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
        "",
        "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b")
      -> Ok1 = true ; Ok1 = false ),
    % Run test vector two and capture whether it passed.
    ( ed25519_selftest_vector(2,
        "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
        "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
        "72",
        "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00")
      -> Ok2 = true ; Ok2 = false ),
    % Succeed overall only if both vectors passed.
    ( Ok1 == true, Ok2 == true
      -> format("OVERALL: PASS~n", [])
      ;  format("OVERALL: FAIL~n", []), fail
    ).

% Check one RFC 8032 vector: derive the public key, sign, verify, and negative-verify.
ed25519_selftest_vector(N, SeedHex, PubHex, MsgHex, SigHex) :-
    % Decode the secret seed hex into bytes.
    ed25519_hex_to_bytes(SeedHex, Seed),
    % Decode the expected public key hex into bytes.
    ed25519_hex_to_bytes(PubHex, ExpectedPub),
    % Decode the message hex into bytes (empty hex yields an empty list).
    ed25519_hex_to_bytes(MsgHex, Message),
    % Decode the expected signature hex into bytes.
    ed25519_hex_to_bytes(SigHex, ExpectedSig),
    % Derive the public key from the seed.
    ed25519_secret_to_public(Seed, GotPub),
    % Sign the message deterministically.
    ed25519_sign(Seed, Message, GotSig),
    % Check the derived public key against the expected value.
    ( GotPub == ExpectedPub -> PubOk = true ; PubOk = false ),
    % Check the produced signature against the expected value.
    ( GotSig == ExpectedSig -> SigOk = true ; SigOk = false ),
    % Verify the produced signature (should succeed).
    ( ed25519_verify(ExpectedPub, Message, ExpectedSig) -> VerOk = true ; VerOk = false ),
    % Tamper with the message by flipping the first byte (or using [0] when empty).
    ed25519_tamper_message(Message, BadMessage),
    % Confirm that verification of the tampered message fails as expected.
    ( ed25519_verify(ExpectedPub, BadMessage, ExpectedSig) -> NegOk = false ; NegOk = true ),
    % Report each sub-result for this vector.
    format("  vector ~w: public=~w sign=~w verify=~w negative=~w~n",
           [N, PubOk, SigOk, VerOk, NegOk]),
    % The vector passes only if all four sub-checks passed.
    PubOk == true, SigOk == true, VerOk == true, NegOk == true.

% Produce a tampered copy of a message that must fail verification.
ed25519_tamper_message([], [0]) :- !.
% Flip the low bit of the first byte for a non-empty message.
ed25519_tamper_message([B | Bs], [B1 | Bs]) :-
    % Compute the altered first byte by toggling its lowest bit.
    B1 is B xor 1.
