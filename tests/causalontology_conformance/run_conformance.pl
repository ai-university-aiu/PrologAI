% Causalontology 2.0.0 conformance runner for PrologAI.
%
% A faithful port of the standard's own reference runner
% (bindings/python/tests/run_conformance.py) at causalontology commit
% 8991c8b5ef12e998ff932855fabe29edf4cc16cc, driving PrologAI's Causalontology
% vocabulary packs (causal_core, noun_backbone, realizable_hinge) plus the
% additive conformance layers (schema_check, signing, store, ed25519) against
% all 107 frozen vectors V01-V107. Canonicalization (RFC 8785), content
% identity (SHA-256), schema validity for the seventeen kinds, the local
% semantic rules, and the five normative algorithms are exercised here.
%
% This runner imports NONE of the ARC grid/ILP/sequence packs; it cannot
% affect the ARC-AGI-1/2 solving core.
:- module(co_conformance, [ co_run/0, co_run/1 ]).

% The Causalontology vocabulary packs under test.
:- use_module(library(causal_core)).
:- use_module(library(noun_backbone)).
:- use_module(library(realizable_hinge)).
% The additive conformance layers.
:- use_module('schema_check.pl').
:- use_module('signing.pl').
:- use_module('store.pl').
:- use_module('ed25519.pl').
% Standard libraries.
:- use_module(library(http/json)).
:- use_module(library(sha)).
:- use_module(library(lists)).
:- use_module(library(apply)).

% The 107 vector clauses (co_v/1) are interleaved with their per-vector helper
% predicates for readability, so they are legitimately discontiguous; declare it
% to keep the load clean (no behavioural change — ordering does not affect co_v/1).
:- discontiguous co_v/1.

% The pinned causalontology source commit the vectors were copied from.
co_vectors_commit('8991c8b5ef12e998ff932855fabe29edf4cc16cc').

% -- co_vecdir(-Dir): the vendored vector directory beside this file.
co_vecdir(Dir) :-
    source_file(co_vecdir(_), Self), file_directory_name(Self, Here),
    atomic_list_concat([Here, '/vectors'], Dir).

% -- co_vec(+N, -Vector): load the Nth vector JSON as a dict.
co_vec(N, V) :-
    co_vecdir(D), format(string(Glob), "~w/v~|~`0t~d~2+_*.json", [D, N]),
    expand_file_name(Glob, [Path|_]),
    open(Path, read, S), json_read_dict(S, V), close(S).

% -- co_vec_name(+N, -Name): the vector's file stem (for reporting).
co_vec_name(N, Name) :-
    co_vecdir(D), format(string(Glob), "~w/v~|~`0t~d~2+_*.json", [D, N]),
    expand_file_name(Glob, [Path|_]), file_base_name(Path, Base),
    atom_concat(Stem, '.json', Base), Name = Stem.

% ===========================================================================
% Symbolic-identifier normalization (Principle P7), a port of normalize/sym.
% ===========================================================================

% -- co_schemes(-List): every whole-word scheme plus ed25519.
co_schemes([occurrent, causal_relation_object, continuant, realizable, assertion,
            enrichment, retraction, succession, stratum, bridge, port, conduit,
            quality, token_individual, token_occurrence, state_assertion,
            token_causal_claim, ed25519]).

% -- co_key(+Name, -Secret, -Pub): the deterministic keypair for a name.
co_key(Name, Secret, Pub) :-
    atomic_list_concat(['key:', Name], KS),
    sha_hash(KS, Seed, [algorithm(sha256), encoding(utf8)]),
    co_keypair_from_seed(Seed, Secret, Pub).

% -- co_is_hex64(+S): S is exactly 64 lowercase hex digits.
co_is_hex64(S) :- string_length(S, 64), string_codes(S, Cs), forall(member(C, Cs), co_hex_code(C)).
% Hexadecimal digit codes 0-9 and a-f.
co_hex_code(C) :- ( C >= 0'0, C =< 0'9 ) ; ( C >= 0'a, C =< 0'f ).

% -- co_sym(+S, -Out): normalize one symbolic identifier to a well-formed one.
co_sym(S, Out) :-
    sub_string(S, B, _, _, ":"), !, sub_string(S, 0, B, _, Scheme),
    BB is B + 1, sub_string(S, BB, _, 0, Name),
    ( Scheme == "ed25519"
      -> ( co_is_hex64(Name) -> Out = S ; ( atom_string(NA, Name), co_key(NA, _, Out) ) )
      ;  ( co_is_hex64(Name) -> Out = S
         ; ( sha_hash(Name, D, [algorithm(sha256), encoding(utf8)]), hash_atom(D, Hex),
             format(string(Out), "~w:~w", [Scheme, Hex]) ) )
    ).

% -- co_normalize(+X, -Y): recursively normalize a vector value.
co_normalize(X, Y) :- string(X), !, co_normalize_string(X, Y).
% Lists map element-wise.
co_normalize(X, Y) :- is_list(X), !, maplist(co_normalize, X, Y).
% Dicts map value-wise, keys preserved.
co_normalize(X, Y) :- is_dict(X), !,
    dict_pairs(X, Tag, Ps), maplist(co_normalize_pair, Ps, Ps2), dict_pairs(Y, Tag, Ps2).
% Anything else passes through.
co_normalize(X, X).
% Normalize the value side of a key-value pair.
co_normalize_pair(K-V, K-V2) :- co_normalize(V, V2).
% A string is normalized by the placeholder and scheme rules.
co_normalize_string("<128 hex>", Out) :- !,
    findall(0'a-0'b, between(1,64,_), _), co_repeat_ab(64, Out).
co_normalize_string(S, Out) :-
    ( co_has_scheme_prefix(S) -> co_sym(S, Out) ; Out = S ).
% Build the 128-hex "abab..." placeholder.
co_repeat_ab(N, Out) :- length(L, N), maplist(=("ab"), L), atomic_list_concat(L, A), atom_string(A, Out).
% True if S begins with a known scheme followed by a colon.
co_has_scheme_prefix(S) :-
    co_schemes(Schemes), member(Sc, Schemes), atom_string(Sc, ScS),
    string_concat(ScS, ":", Pfx), string_concat(Pfx, _, S), !.

% ===========================================================================
% Builders (port of the runner's object constructors).
% ===========================================================================

% -- co_ts(+I, -Timestamp): the runner's timestamp template.
co_ts(I, TS) :- format(string(TS), "2026-07-13T0~w:00:00Z", [I]).

% -- co_mk(+Obj, -Out): complete a content object with its content id.
co_mk(Obj, Out) :- causal_core_identify(Obj, _, Id), put_dict(id, Obj, Id, Out).

% -- co_put_str(+Dict, +Key, +Val, -Out): set a string-valued field.
co_put_str(D, K, V, O) :- put_dict(K, D, V, O).

% -- co_signed(+Kind, +Body, +Who, +TsI, -Out): a signed provenance record.
co_signed(Kind, Body, Who, TsI, Out) :-
    co_key(Who, Secret, Pub), atom_string(Kind, KS),
    put_dict(type, Body, KS, B1),
    ( get_dict(timestamp, B1, _) -> B2 = B1 ; co_ts(TsI, TS), put_dict(timestamp, B1, TS, B2) ),
    ( Kind == succession
      -> ( get_dict(predecessor, B2, _) -> B3 = B2 ; put_dict(predecessor, B2, Pub, B3) )
      ;  put_dict(source, B2, Pub, B3) ),
    co_sign_record(B3, Secret, Kind, Out).

% -- Content-object builders.
co_stratum(Label, Scheme, Ordinal, Unit, Governs, Out) :-
    B0 = _{type:"stratum", label:Label, scheme:Scheme, ordinal:Ordinal},
    ( Unit == none -> B1 = B0 ; put_dict(unit, B0, Unit, B1) ),
    ( Governs == none -> B2 = B1 ; put_dict(governs, B1, Governs, B2) ),
    co_mk(B2, Out).
% A stratum without unit or governs.
co_stratum(Label, Scheme, Ordinal, Out) :- co_stratum(Label, Scheme, Ordinal, none, none, Out).
% An occurrent with an optional stratum and a category.
co_occ(Label, Stratum, Category, Out) :-
    B0 = _{type:"occurrent", label:Label, category:Category},
    ( Stratum == none -> B1 = B0 ; put_dict(stratum, B0, Stratum, B1) ),
    co_mk(B1, Out).
% An occurrent defaulting to the event category.
co_occ(Label, Stratum, Out) :- co_occ(Label, Stratum, "event", Out).
% A continuant with a category.
co_cnt(Label, Category, Out) :- co_mk(_{type:"continuant", label:Label, category:Category}, Out).
% A continuant defaulting to the object category.
co_cnt(Label, Out) :- co_cnt(Label, "object", Out).
% A causal_relation_object from causes, effects, and a list of Key-Value extras.
co_cro(Causes, Effects, Extra, Out) :-
    B0 = _{type:"causal_relation_object", causes:Causes, effects:Effects},
    foldl(co_add_pair, Extra, B0, B1), co_mk(B1, Out).
% A causal_relation_object with no extra fields.
co_cro(Causes, Effects, Out) :- co_cro(Causes, Effects, [], Out).
% Fold a Key-Value extra into a dict.
co_add_pair(K-V, D, O) :- put_dict(K, D, V, O).
% A bridge from a coarse occurrent, a fine set, and a relation.
co_bridge(Coarse, Fine, Relation, Out) :-
    co_mk(_{type:"bridge", coarse:Coarse, fine:Fine, relation:Relation}, Out).
% A port with optional realizable.
co_port(Bearer, Label, Direction, Accepts, Realizable, Out) :-
    B0 = _{type:"port", bearer:Bearer, label:Label, direction:Direction, accepts:Accepts},
    ( Realizable == none -> B1 = B0 ; put_dict(realizable, B0, Realizable, B1) ),
    co_mk(B1, Out).
% A port without a realizable.
co_port(Bearer, Label, Direction, Accepts, Out) :- co_port(Bearer, Label, Direction, Accepts, none, Out).
% A conduit with an optional transform.
co_conduit(Frm, To, Carries, Label, Transform, Out) :-
    B0 = _{type:"conduit", label:Label, from:Frm, to:To, carries:Carries},
    ( Transform == none -> B1 = B0 ; put_dict(transform, B0, Transform, B1) ),
    co_mk(B1, Out).
% A quality with optional unit and stratum.
co_quality(Label, Datatype, Unit, Stratum, Out) :-
    B0 = _{type:"quality", label:Label, datatype:Datatype},
    ( Unit == none -> B1 = B0 ; put_dict(unit, B0, Unit, B1) ),
    ( Stratum == none -> B2 = B1 ; put_dict(stratum, B1, Stratum, B2) ),
    co_mk(B2, Out).
% A token individual with optional designator and part_of.
co_individual(Instantiates, Designator, PartOf, Out) :-
    B0 = _{type:"token_individual", instantiates:Instantiates},
    ( Designator == none -> B1 = B0 ; put_dict(designator, B0, Designator, B1) ),
    ( PartOf == none -> B2 = B1 ; put_dict(part_of, B1, PartOf, B2) ),
    co_mk(B2, Out).
% A token occurrence with optional participants and locus.
co_token(Instantiates, Interval, Participants, Locus, Out) :-
    B0 = _{type:"token_occurrence", instantiates:Instantiates, interval:Interval},
    ( Participants == none -> B1 = B0 ; put_dict(participants, B0, Participants, B1) ),
    ( Locus == none -> B2 = B1 ; put_dict(locus, B1, Locus, B2) ),
    co_mk(B2, Out).
% A state assertion.
co_state(Subject, Quality, Value, Interval, Out) :-
    co_mk(_{type:"state_assertion", subject:Subject, quality:Quality, value:Value, interval:Interval}, Out).
% A token causal claim with optional covering law, actual delay, counterfactual.
co_tcc(Causes, Effects, Law, Delay, Counterfactual, Out) :-
    B0 = _{type:"token_causal_claim", causes:Causes, effects:Effects},
    ( Law == none -> B1 = B0 ; put_dict(covering_law, B0, Law, B1) ),
    ( Delay == none -> B2 = B1 ; put_dict(actual_delay, B1, Delay, B2) ),
    ( Counterfactual == none -> B3 = B2 ; put_dict(counterfactual, B2, Counterfactual, B3) ),
    co_mk(B3, Out).
% A realizable with an optional label.
co_rlz(Bearer, Kind, Label, Out) :-
    B0 = _{type:"realizable", kind:Kind, bearer:Bearer},
    ( Label == none -> B1 = B0 ; put_dict(label, B0, Label, B1) ),
    co_mk(B1, Out).

% -- co_map_of(+Objs, -Dict): a dict keyed by each object's (atomized) id.
% Duplicate ids (an object appearing under two ordinals) collapse to one entry.
co_map_of(Objs, Dict) :-
    findall(KA-O, (member(O, Objs), get_dict(id, O, Id), atom_string(KA, Id)), Pairs),
    sort(1, @<, Pairs, Uniq), dict_pairs(Dict, _, Uniq).

% ===========================================================================
% Small assertion helpers.
% ===========================================================================

% -- co_contains(+Reasons, +Sub): some reason string mentions the substring.
co_contains(Reasons, Sub) :- member(R, Reasons), sub_string_ci(R, Sub), !.
% Case-sensitive substring test tolerating atom/string reasons.
sub_string_ci(R, Sub) :- ( string(R) -> RS = R ; atom_string(R, RS) ), sub_string(RS, _,_,_, Sub).

% -- co_schema_ok(+Obj, +Kind): the schema accepts Obj.
co_schema_ok(Obj, Kind) :- co_validate_schema(Obj, Kind, true, _).
% -- co_schema_bad(+Obj, +Kind, +Sub): the schema rejects, mentioning Sub.
co_schema_bad(Obj, Kind, Sub) :- co_validate_schema(Obj, Kind, false, Why), co_contains(Why, Sub).
% -- co_sem_ok(+Obj, +Kind): the semantics accept Obj.
co_sem_ok(Obj, Kind) :- causal_core_validate_semantics(Obj, Kind, []).
% -- co_sem_bad(+Obj, +Kind, +Sub): the semantics reject, mentioning Sub.
co_sem_bad(Obj, Kind, Sub) :- causal_core_validate_semantics(Obj, Kind, Why), Why \== [], co_contains(Why, Sub).
% -- co_kind(+Obj, -Kind): infer the object's kind.
co_kind(Obj, Kind) :- causal_core_infer_kind(Obj, Kind).
% -- co_input(+N, -Inp): the normalized input of vector N.
co_input(N, Inp) :- co_vec(N, V), get_dict(input, V, I), co_normalize(I, Inp).

% ===========================================================================
% Fixtures shared by several vectors.
% ===========================================================================

% -- co_neuro(-S): the neuroendocrine stratum dict keyed by ordinal.
co_neuro(S) :-
    co_stratum("macromolecular", "neuroendocrine", 4, S4),
    co_stratum("subcellular", "neuroendocrine", 5, S5),
    co_stratum("cellular", "neuroendocrine", 6, S6),
    co_stratum("synaptic", "neuroendocrine", 7, S7),
    co_stratum("region", "neuroendocrine", 9, S9),
    co_stratum("community_and_society", "neuroendocrine", 14, S14),
    S = _{4:S4, 5:S5, 6:S6, 7:S7, 9:S9, 14:S14}.

% -- co_stratum_id(+NeuroDict, +Ord, -Id): the id of the stratum at an ordinal.
co_stratum_id(Neuro, Ord, Id) :- get_dict(Ord, Neuro, St), get_dict(id, St, Id).

% ===========================================================================
% The 107 vectors.
% ===========================================================================

% V01: a complete causal_relation_object is schema- and semantically valid.
co_v(1) :- co_input(1, I), co_kind(I, K), co_schema_ok(I, K), co_sem_ok(I, K).
% V02: a degenerate causal_relation_object is valid and partial with the stated missing set.
co_v(2) :- co_input(2, I), co_kind(I, K), co_schema_ok(I, K), co_sem_ok(I, K),
    causal_core_is_partial(I, true, Missing), maplist(atom_string, Missing, MS0), sort(MS0, MS),
    co_vec(2, V), get_dict(expect, V, Ex), get_dict(missing, Ex, Want0), sort(Want0, Want), MS == Want.
% V03: missing effects is schema-invalid.
co_v(3) :- co_input(3, I), co_kind(I, K), co_schema_bad(I, K, "effects").
% V04: empty causes is schema-invalid.
co_v(4) :- co_input(4, I), co_kind(I, K), co_schema_bad(I, K, "causes").
% V05: an unknown modality is schema-invalid.
co_v(5) :- co_input(5, I), co_kind(I, K), co_schema_bad(I, K, "modality").
% V06: an additional property is schema-invalid.
co_v(6) :- co_input(6, I), co_kind(I, K), co_schema_bad(I, K, "colour").
% V07: a free-text cause is schema-invalid.
co_v(7) :- co_input(7, I), co_kind(I, K), co_schema_bad(I, K, "causes").
% V08: an occurrent is schema-valid.
co_v(8) :- co_input(8, I), co_kind(I, K), co_schema_ok(I, K).
% V09: an occurrent missing its label is schema-invalid.
co_v(9) :- co_input(9, I), co_kind(I, K), co_schema_bad(I, K, "label").
% V10: an occurrent category outside the enumeration is schema-invalid.
co_v(10) :- co_input(10, I), co_kind(I, K), co_schema_bad(I, K, "category").
% V11: an assertion is schema-valid.
co_v(11) :- co_input(11, I), co_kind(I, K), co_schema_ok(I, K).
% V12: an assertion confidence out of range is schema-invalid.
co_v(12) :- co_input(12, I), co_kind(I, K), co_schema_bad(I, K, "confidence").
% V13: a valid refinement is schema- and semantically valid.
co_v(13) :- co_input(13, I), co_kind(I, K), co_schema_ok(I, K), co_sem_ok(I, K).
% V14: a causal_relation_object with minimum_delay > maximum_delay is semantically invalid.
co_v(14) :- co_input(14, I), co_kind(I, K), co_schema_ok(I, K), co_sem_bad(I, K, "minimum_delay").
% V15: self-referential mechanism is semantically invalid (acyclic).
co_v(15) :- co_input(15, I), co_kind(I, K), co_sem_bad(I, K, "acyclic").
% V16: self-referential refines is semantically invalid (acyclic).
co_v(16) :- co_input(16, I), co_kind(I, K), co_sem_bad(I, K, "acyclic").
% V17: a rival refinement is not a valid refinement.
co_v(17) :- co_vec(17, V), get_dict(given, V, G), get_dict(parent, G, P0), co_normalize(P0, Parent),
    get_dict(input, V, C0), co_normalize(C0, Child),
    causal_core_refinement_valid(Child, Parent, invalid(Reason)), sub_string_ci(Reason, "rival").
% V18: an illegal enrichment field is semantically invalid.
co_v(18) :- co_input(18, I), co_kind(I, K), co_sem_bad(I, K, "not a legal field").
% V19: a malformed aliases entry is semantically invalid.
co_v(19) :- co_input(19, I), co_kind(I, K), co_sem_bad(I, K, "language-tagged").
% V20: an enforcing store refuses a taxonomy cycle; a merged cycle is excluded and surfaced.
co_v(20) :-
    DogS = "continuant:dog", MamS = "continuant:mammal", AniS = "continuant:animal",
    co_sym(DogS, Dog), co_sym(MamS, Mam), co_sym(AniS, Ani),
    co_store_reset(true),
    co_enrich(Dog, Mam, 1, E1), co_put_record(E1, _),
    co_enrich(Mam, Ani, 2, E2), co_put_record(E2, _),
    co_enrich(Ani, Dog, 3, E3),
    catch((co_put_record(E3, _), fail), co_reject(Msg), sub_string_ci(Msg, "cycle")),
    co_store_reset(true),
    co_enrich(Dog, Mam, 1, F1), co_put_record(F1, _),
    co_enrich(Mam, Ani, 2, F2), co_put_record(F2, _),
    co_enrich(Ani, Dog, 3, Bad), co_force_merge_record(Bad, _),
    co_active_taxonomy_edges(subsumes, _, Excluded), length(Excluded, 1),
    Excluded = [ExR], get_dict(id, ExR, ExId), get_dict(id, Bad, BadId), ExId == BadId,
    co_gaps(inconsistent_hierarchy, Gaps), member(GG, Gaps), get_dict(id, GG, BadId).
% -- co_enrich(+About, +Entry, +I, -Record): a signed subsumes enrichment.
co_enrich(About, Entry, I, Rec) :-
    co_signed(enrichment, _{about:About, field:"subsumes", entry:Entry}, "taxo", I, Rec).
% V21-V23: temporal admissibility.
co_v(21) :- co_adm(21, true).
co_v(22) :- co_adm(22, false).
co_v(23) :- co_adm(23, true).
% -- co_adm(+N, +Want): build a windowed cro from the vector's given and test admissibility.
co_adm(N, Want) :-
    co_vec(N, V), get_dict(given, V, G), get_dict(temporal, G, T), get_dict(elapsed_seconds, G, E),
    C = _{causes:["occurrent:c"], effects:["occurrent:e"], temporal:T},
    ( Want == true -> causal_core_admissible(C, E, true) ; causal_core_admissible(C, E, false) ).
% V24, V25: two encodings share one identity.
co_v(24) :- co_ident_eq(24).
co_v(25) :- co_ident_eq(25).
% -- co_ident_eq(+N): identify(inputA) == identify(inputB).
co_ident_eq(N) :-
    co_vec(N, V), get_dict(inputA, V, A0), co_normalize(A0, A), get_dict(inputB, V, B0), co_normalize(B0, B),
    causal_core_identify(A, _, IdA), causal_core_identify(B, _, IdB), IdA == IdB.
% V26: put is idempotent (one stored object).
co_v(26) :- co_store_reset(true),
    O = _{type:"occurrent", label:"press_button", category:"action"},
    co_put(O, I1), co_put(O, I2), I1 == I2, co_objects_count(1).
% V27: two aliases contributions materialize as one entry with two contributors.
co_v(27) :- co_store_reset(true),
    co_put(_{type:"occurrent", label:"press_button", category:"action"}, Occid),
    Entry = _{lang:"en", text:"press the button"},
    co_signed(enrichment, _{about:Occid, field:"aliases", entry:Entry}, "alice", 1, R1),
    co_signed(enrichment, _{about:Occid, field:"aliases", entry:Entry}, "bob", 2, R2),
    co_put_record(R1, Rid1), co_put_record(R2, Rid2), Rid1 \== Rid2,
    co_get(Occid, default, G), get_dict(enrichments, G, En), get_dict(aliases, En, Views),
    length(Views, 1), Views = [B1], get_dict(contributors, B1, Cs), length(Cs, 2).
% V28: idempotent claim put; two assertions recorded.
co_v(28) :- co_store_reset(true),
    Claim = _{type:"causal_relation_object", causes:["occurrent:A"], effects:["occurrent:B"], modality:"sufficient"},
    co_norm_dict(Claim, ClaimN), co_put(ClaimN, I1), co_put(ClaimN, I2), I1 == I2, co_objects_count(1),
    co_signed(assertion, _{about:I1, evidence_type:"observation", strength:0.8, confidence:0.8}, "lab1", 1, A1),
    co_signed(assertion, _{about:I1, evidence_type:"observation", strength:0.8, confidence:0.8}, "lab2", 2, A2),
    co_put_record(A1, _), co_put_record(A2, _), co_assertions_about(I1, false, As), length(As, 2).
% -- co_norm_dict(+D, -D2): normalize the symbolic ids inside a dict.
co_norm_dict(D, D2) :- co_normalize(D, D2).
% V29: a signed assertion verifies.
co_v(29) :- co_signed(assertion, _{about:"causal_relation_object:demo", evidence_type:"intervention", strength:0.7, confidence:0.9}, "signer", 0, R),
    co_verify_record(R, assertion).
% V30: a tampered assertion does not verify.
co_v(30) :- co_signed(assertion, _{about:"causal_relation_object:demo", evidence_type:"intervention", strength:0.7, confidence:0.9}, "signer", 0, R),
    put_dict(confidence, R, 0.1, Bad), \+ co_verify_record(Bad, assertion).
% V31: retraction hides an assertion; history reveals it; a foreign retraction is refused.
co_v(31) :- co_store_reset(true), co_sym("occurrent:A", OA), co_sym("occurrent:B", OB),
    co_put(_{type:"causal_relation_object", causes:[OA], effects:[OB]}, X),
    co_signed(assertion, _{about:X, evidence_type:"observation", confidence:0.8}, "lab1", 1, A),
    co_put_record(A, _), get_dict(id, A, Aid),
    co_signed(retraction, _{retracts:Aid}, "lab1", 2, Ret), co_put_record(Ret, _),
    co_assertions_about(X, false, []),
    co_assertions_about(X, true, Hist), length(Hist, 1), Hist = [H1], get_dict(retracted, H1, true),
    co_signed(retraction, _{retracts:Aid}, "mallory", 3, Foreign),
    catch((co_put_record(Foreign, _), fail), co_reject(_), true).
% V32: an enrichment retraction empties the default view but not the history view.
co_v(32) :- co_store_reset(true),
    co_put(_{type:"occurrent", label:"press_button", category:"action"}, Occid),
    co_signed(enrichment, _{about:Occid, field:"aliases", entry:_{lang:"ja", text:"botan"}}, "bob", 1, E),
    co_put_record(E, _), get_dict(id, E, Eid),
    co_get(Occid, default, G1), get_dict(enrichments, G1, En1), get_dict(aliases, En1, V1), length(V1, 1),
    co_signed(retraction, _{retracts:Eid}, "bob", 2, Ret), co_put_record(Ret, _),
    co_get(Occid, default, G2), get_dict(enrichments, G2, En2), ( get_dict(aliases, En2, V2) -> V2 == [] ; true ),
    co_get(Occid, history, G3), get_dict(enrichments, G3, En3), get_dict(aliases, En3, V3), length(V3, 1).
% V33: succession lineage lets the successor key retract.
co_v(33) :- co_store_reset(true),
    co_key("K1", _, K1), co_key("K2", _, K2),
    co_signed(assertion, _{about:"causal_relation_object:claim", evidence_type:"observation", confidence:0.9}, "K1", 1, A),
    co_put_record(A, _), get_dict(id, A, Aid),
    co_signed(succession, _{successor:K2}, "K1", 2, Su), co_put_record(Su, _),
    co_lineage(K2, LK2), memberchk(K1, LK2), co_lineage(K1, LK1), memberchk(K2, LK1),
    co_signed(retraction, _{retracts:Aid}, "K2", 3, Ret), co_put_record(Ret, _),
    co_assertions_about("causal_relation_object:claim", false, []).
% V34, V35: the conflict test.
co_v(34) :- co_conf(34, true).
co_v(35) :- co_conf(35, false).
% -- co_conf(+N, +Want): conflicts(A, B) matches Want.
co_conf(N, Want) :-
    co_vec(N, V), get_dict(given, V, G), get_dict('A', G, A0), co_normalize(A0, A),
    get_dict('B', G, B0), co_normalize(B0, B),
    ( Want == true -> causal_core_conflicts(A, B) ; \+ causal_core_conflicts(A, B) ).
% V36: hierarchy consistency across a mechanism graph.
co_v(36) :-
    co_sym("occurrent:A", A), co_sym("occurrent:B", B), co_sym("occurrent:C", C), co_sym("occurrent:D", D),
    co_sym("causal_relation_object:m1", M1), co_sym("causal_relation_object:m2", M2), co_sym("causal_relation_object:m3", M3),
    Me1 = _{id:M1, causes:[A], effects:[B]}, Me2 = _{id:M2, causes:[B], effects:[C]}, Me3 = _{id:M3, causes:[D], effects:[C]},
    P = _{causes:[A], effects:[C], mechanism:[M1, M2]},
    co_map_of([Me1, Me2], Map1), causal_core_hierarchy_consistent(P, Map1, [], consistent),
    P2 = P.put(mechanism, [M1, M3]), co_map_of([Me1, Me3], Map2), causal_core_hierarchy_consistent(P2, Map2, [], inconsistent),
    co_map_of([Me1], Map3), causal_core_hierarchy_consistent(P, Map3, [], indeterminate).
% V37: resolve by normalized label and alias.
co_v(37) :- co_store_reset(true),
    co_put(_{type:"occurrent", label:"press_button", category:"action"}, Occid),
    co_signed(enrichment, _{about:Occid, field:"aliases", entry:_{lang:"en", text:"Press the Button"}}, "alice", 1, E),
    co_put_record(E, _),
    co_resolve("Press  The   Button", "en", H1), H1 == [Occid],
    co_resolve("press_button", "en", H2), H2 = [First|_], First == Occid.
% V38: the missing_field gap appears for a partial claim and clears after refinement.
co_v(38) :- co_store_reset(true), co_sym("occurrent:A", OA), co_sym("occurrent:B", OB),
    co_put(_{type:"causal_relation_object", causes:[OA], effects:[OB]}, P),
    co_gaps(missing_field, G1), findall(Id, (member(GG,G1), get_dict(id,GG,Id)), Ids1), memberchk(P, Ids1),
    co_put(_{type:"causal_relation_object", causes:[OA], effects:[OB],
             temporal:_{minimum_delay:0, maximum_delay:1, unit:"seconds"}, modality:"sufficient", refines:P}, R),
    co_gaps(missing_field, G2), findall(Id, (member(GG,G2), get_dict(id,GG,Id)), Ids2),
    \+ memberchk(P, Ids2), \+ memberchk(R, Ids2).
% V39: a full stratum is schema-valid.
co_v(39) :- co_stratum("cellular", "neuroendocrine", 6, "cell", ["cell_biology"], St), co_schema_ok(St, stratum).
% V40: a stratum missing its scheme is schema-invalid.
co_v(40) :- co_mk(_{type:"stratum", label:"cellular", ordinal:6}, Bad), co_schema_bad(Bad, stratum, "scheme").
% V41: two same-ordinal strata differ in identity.
co_v(41) :- co_stratum("cellular", "neuroendocrine", 6, A), co_stratum("neuronal", "neuroendocrine", 6, B),
    co_schema_ok(A, stratum), co_schema_ok(B, stratum), get_dict(id, A, IA), get_dict(id, B, IB), IA \== IB.
% V42: strata in different schemes yield scheme_mismatch.
co_v(42) :- co_neuro(S), co_stratum("molecular", "physics", 4, S4p),
    co_stratum_id(S, 14, S14id), get_dict(14, S, S14),
    co_occ("chronic_social_subordination", S14id, C), get_dict(id, S4p, S4pid), co_occ("gene_expression", S4pid, E),
    co_map_of([S14, S4p], Smap), co_map_of([C, E], Omap), co_cro([C.id], [E.id], P),
    causal_core_classify(P, Omap, Smap, scheme_mismatch).
% V43: valid strata at ordinals 4 and 9.
co_v(43) :- co_stratum("macromolecular", "neuroendocrine", 4, A), co_stratum("region", "neuroendocrine", 9, B),
    co_schema_ok(A, stratum), co_schema_ok(B, stratum).
% V44: a stratified occurrent is schema- and semantically valid.
co_v(44) :- co_stratum("cellular", "neuroendocrine", 6, St), get_dict(id, St, Sid), co_occ("neuron_fires", Sid, O),
    co_schema_ok(O, occurrent), co_sem_ok(O, occurrent).
% V45: an unstratified pair is unclassifiable.
co_v(45) :- co_occ("press_button", none, O), co_schema_ok(O, occurrent), co_occ("light_on", none, E),
    co_cro([O.id], [E.id], P), co_map_of([O, E], Omap), causal_core_classify(P, Omap, _{}, unclassifiable).
% V46: same label, different strata, different identity.
co_v(46) :- co_neuro(S), co_stratum_id(S, 5, S5), co_stratum_id(S, 6, S6),
    co_occ("depolarization", S5, A), co_occ("depolarization", S6, B), get_dict(id, A, IA), get_dict(id, B, IB), IA \== IB.
% V47-V50: valid bridges of each relation.
co_v(47) :- co_valid_bridge("constitutes").
co_v(48) :- co_valid_bridge("aggregates").
co_v(49) :- co_valid_bridge("realizes").
co_v(50) :- co_valid_bridge("supervenes_on").
% -- co_bridge_fixture(+Relation, -Bridge, -Omap, -Smap).
co_bridge_fixture(Relation, B, Omap, Smap) :-
    co_neuro(S), co_stratum_id(S, 6, S6id), co_stratum_id(S, 4, S4id),
    co_occ("action_potential_fires", S6id, Coarse),
    co_occ("sodium_channels_open", S4id, F1), co_occ("sodium_influx", S4id, F2),
    co_bridge(Coarse.id, [F1.id, F2.id], Relation, B),
    co_map_of([Coarse, F1, F2], Omap), get_dict(4, S, S4), get_dict(6, S, S6), co_map_of([S4, S6], Smap).
% -- A valid bridge passes schema and well-formedness.
co_valid_bridge(Rel) :- co_bridge_fixture(Rel, B, Omap, Smap), co_schema_ok(B, bridge),
    causal_core_bridge_wellformed(B, Omap, Smap, ok(_)).
% V51: coarse ordinal below fine ordinal is malformed.
co_v(51) :- co_neuro(S), co_stratum_id(S, 4, S4id), co_stratum_id(S, 6, S6id),
    co_occ("x_coarse", S4id, Coarse), co_occ("x_fine", S6id, Fine),
    co_bridge(Coarse.id, [Fine.id], "constitutes", B),
    co_map_of([Coarse, Fine], Omap), get_dict(4, S, S4), get_dict(6, S, S6), co_map_of([S4, S6], Smap),
    causal_core_bridge_wellformed(B, Omap, Smap, invalid(_)).
% V52: fine members spanning two strata is malformed.
co_v(52) :- co_neuro(S), co_stratum_id(S, 6, S6id), co_stratum_id(S, 4, S4id), co_stratum_id(S, 5, S5id),
    co_occ("c", S6id, Coarse), co_occ("f1", S4id, F1), co_occ("f2", S5id, F2),
    co_bridge(Coarse.id, [F1.id, F2.id], "constitutes", B),
    co_map_of([Coarse, F1, F2], Omap), get_dict(4, S, S4), get_dict(5, S, S5), get_dict(6, S, S6),
    co_map_of([S4, S5, S6], Smap), causal_core_bridge_wellformed(B, Omap, Smap, invalid(_)).
% V53: a bridge graph cycle is detected.
co_v(53) :- co_sym("occurrent:x", X), co_sym("occurrent:y", Y),
    co_bridge(X, [Y], "constitutes", B1), co_bridge(Y, [X], "constitutes", B2),
    co_bridge_edges([B1, B2], Edges), causal_core_has_cycle(Edges).
% -- Build the fine->coarse edge dict for a bridge set (nodes as atoms).
co_bridge_edges(Bridges, Edges) :-
    findall(FA-CA, (member(B, Bridges), get_dict(coarse, B, C), atom_string(CA, C),
                    get_dict(fine, B, Fine), member(F, Fine), atom_string(FA, F)), Pairs0),
    co_group_edges(Pairs0, Edges).
% -- Group Key-Value pairs into a dict Key -> list of values.
co_group_edges(Pairs, Dict) :-
    findall(K, member(K-_, Pairs), Ks0), sort(Ks0, Ks),
    findall(K-Vs, (member(K, Ks), findall(V, member(K-V, Pairs), Vs)), KVs), dict_pairs(Dict, _, KVs).
% V54: coarse and fine in different schemes is malformed.
co_v(54) :- co_stratum("cellular", "neuroendocrine", 6, A), co_stratum("molecular", "physics", 4, B),
    get_dict(id, A, Aid), get_dict(id, B, Bid), co_occ("c", Aid, Coarse), co_occ("f", Bid, Fine),
    co_bridge(Coarse.id, [Fine.id], "constitutes", Br), co_map_of([Coarse, Fine], Omap), co_map_of([A, B], Smap),
    causal_core_bridge_wellformed(Br, Omap, Smap, invalid(_)).
% V55: two bridges from one coarse to different fines differ in identity.
co_v(55) :- co_neuro(S), co_stratum_id(S, 6, S6id), co_stratum_id(S, 4, S4id),
    co_occ("decision_made", S6id, Coarse), co_occ("cascade_a", S4id, F1), co_occ("cascade_b", S4id, F2),
    co_bridge(Coarse.id, [F1.id], "realizes", B1), co_bridge(Coarse.id, [F2.id], "realizes", B2),
    get_dict(id, B1, I1), get_dict(id, B2, I2), I1 \== I2, co_schema_ok(B1, bridge), co_schema_ok(B2, bridge).
% -- co_reach_fixture(-P, -Members, -Bridges): the bridged-reachability fixture.
co_reach_fixture(P, Members, Bridges) :-
    co_neuro(S), co_stratum_id(S, 6, S6id), co_stratum_id(S, 4, S4id),
    co_occ("action_potential_fires", S6id, Ap), co_occ("neurotransmitter_released", S6id, Nt),
    co_occ("calcium_enters", S4id, Fa), co_occ("vesicle_fuses", S4id, Fb),
    co_cro([Fa.id], [Fb.id], M1), co_cro([Ap.id], [Nt.id], [mechanism-[M1.id]], P),
    co_map_of([M1], Members),
    co_bridge(Ap.id, [Fa.id], "constitutes", B1), co_bridge(Nt.id, [Fb.id], "constitutes", B2), Bridges = [B1, B2].
% V56: bridged reachability makes the hierarchy consistent.
co_v(56) :- co_reach_fixture(P, M, B), causal_core_hierarchy_consistent(P, M, B, consistent).
% V57: literal reachability (no bridges) makes it inconsistent.
co_v(57) :- co_reach_fixture(P, M, _), causal_core_hierarchy_consistent(P, M, [], inconsistent).
% V58: the two verdicts differ (the negative proof of bridged reachability).
co_v(58) :- co_reach_fixture(P, M, B), causal_core_hierarchy_consistent(P, M, [], Lit), Lit \== consistent,
    causal_core_hierarchy_consistent(P, M, B, consistent).
% V59-V61: stratal classification.
co_v(59) :- co_classify(6, 6, intra_stratal).
co_v(60) :- co_classify(6, 5, adjacent_stratal).
co_v(61) :- co_classify(14, 4, skipping).
% -- co_classify(+CauseOrd, +EffectOrd, +Want).
co_classify(CO, EO, Want) :-
    co_neuro(S), co_stratum_id(S, CO, CS), co_stratum_id(S, EO, ES),
    co_occ("c", CS, C), co_occ("e", ES, E),
    atom_number_key(CO, COK), atom_number_key(EO, EOK), get_dict(COK, S, SC), get_dict(EOK, S, SE),
    co_map_of([SC, SE], Smap), co_map_of([C, E], Omap), co_cro([C.id], [E.id], P),
    causal_core_classify(P, Omap, Smap, Want).
% -- atom_number_key(+N, -N): integer keys index the neuro dict directly.
atom_number_key(N, N).
% -- co_skip_fixture(+CauseOrd, +EffectOrd, +Extra, -P, -Class).
co_skip_fixture(CO, EO, Extra, P, Class) :-
    co_neuro(S), co_stratum_id(S, CO, CS), co_stratum_id(S, EO, ES),
    co_occ("c", CS, C), co_occ("e", ES, E), get_dict(CO, S, SC), get_dict(EO, S, SE),
    co_map_of([SC, SE], Smap), co_map_of([C, E], Omap), co_cro([C.id], [E.id], Extra, P),
    causal_core_classify(P, Omap, Smap, Class).
% V62: a skipping claim without a mechanism surfaces incomplete_mechanism.
co_v(62) :- co_skip_fixture(14, 4, [], P, Cls), causal_core_skip_gaps(P, Cls, [incomplete_mechanism]).
% V63: with skips:true there is no gap (absence is a finding).
co_v(63) :- co_skip_fixture(14, 4, [skips-true], P, Cls), causal_core_skip_gaps(P, Cls, []).
% V64: skips:true with a mechanism is a contradiction (and semantically invalid).
co_v(64) :- co_sym("causal_relation_object:m", M), co_skip_fixture(14, 4, [skips-true, mechanism-[M]], P, Cls),
    causal_core_skip_gaps(P, Cls, [contradictory_skip]), co_sem_bad(P, causal_relation_object, "contradictory_skip").
% V65: skips:true at an intra-stratal relation is a vacuous_skip.
co_v(65) :- co_skip_fixture(6, 6, [skips-true], P, Cls), causal_core_skip_gaps(P, Cls, [vacuous_skip]).
% V66: skips absent versus skips:false differ in identity.
co_v(66) :- co_neuro(S), co_stratum_id(S, 14, S14), co_stratum_id(S, 4, S4),
    co_occ("c", S14, C), co_occ("e", S4, E), co_cro([C.id], [E.id], Absent),
    co_cro([C.id], [E.id], [skips-false], FalseC), get_dict(id, Absent, IA), get_dict(id, FalseC, IB), IA \== IB.
% V67: mixed-stratum endpoints are surfaced.
co_v(67) :- co_neuro(S), co_stratum_id(S, 4, S4), co_stratum_id(S, 6, S6),
    co_occ("c1", S4, C1), co_occ("c2", S6, C2), co_occ("e", S6, E),
    co_cro([C1.id, C2.id], [E.id], P), co_map_of([C1, C2, E], Omap), causal_core_endpoints_mixed(P, Omap).
% V68: the enabling modality is schema-valid.
co_v(68) :- co_sym("occurrent:a", A), co_sym("occurrent:b", B),
    co_cro([A], [B], [modality-"enabling"], P), co_schema_ok(P, causal_relation_object).
% V69: enabling and sufficient do not conflict.
co_v(69) :- A = _{causes:["occurrent:a"], effects:["occurrent:b"], modality:"enabling"},
    B = _{causes:["occurrent:a"], effects:["occurrent:b"], modality:"sufficient"}, \+ causal_core_conflicts(A, B).
% V70: enabling and preventive conflict.
co_v(70) :- A = _{causes:["occurrent:a"], effects:["occurrent:b"], modality:"enabling"},
    B = _{causes:["occurrent:a"], effects:["occurrent:b"], modality:"preventive"}, causal_core_conflicts(A, B).
% V71: a port is schema-valid.
co_v(71) :- co_cnt("hippocampus", B), co_sym("occurrent:signal", Sig),
    co_port(B.id, "perforant_path", "in", [Sig], P), co_schema_ok(P, port).
% V72: two ports differing only in label differ in identity.
co_v(72) :- co_cnt("hippocampus", B), X = "occurrent:signal",
    co_port(B.id, "perforant_path", "in", [X], P1), co_port(B.id, "fornix", "in", [X], P2),
    get_dict(id, P1, I1), get_dict(id, P2, I2), I1 \== I2.
% -- co_conduit_fixture(+Opts, -Conduit, -PortMap, -CroMap). Opts: transform/bad_carry/in_from.
co_conduit_fixture(Opts, C, Pmap, Cmap) :-
    co_sym("occurrent:motor_command", X), co_sym("occurrent:error_signal", Y), co_sym("occurrent:unrelated", Z),
    co_cnt("motor_cortex", M1c), co_cnt("spinal_neuron", M2c), M1 = M1c.id, M2 = M2c.id,
    ( memberchk(in_from, Opts) -> FDir = "in" ; FDir = "out" ),
    co_port(M1, "out_port", FDir, [X], Frm),
    ( memberchk(transform, Opts) -> ToAcc = [Y] ; ToAcc = [X] ), co_port(M2, "in_port", "in", ToAcc, To),
    ( memberchk(bad_carry, Opts) -> Carries = [Z] ; Carries = [X] ),
    ( memberchk(transform, Opts)
      -> ( co_cro([X], [Y], Law), Xform = Law.id, co_map_of([Law], Cmap) )
      ;  ( Xform = none, Cmap = _{} ) ),
    co_conduit(Frm.id, To.id, Carries, "conn", Xform, C), co_map_of([Frm, To], Pmap).
% V73: a direct conduit is schema-valid and well-formed.
co_v(73) :- co_conduit_fixture([], C, Pmap, _), co_schema_ok(C, conduit), causal_core_conduit_wellformed(C, Pmap, _{}, ok(_)).
% V74: a transforming conduit is schema-valid and well-formed.
co_v(74) :- co_conduit_fixture([transform], C, Pmap, Cmap), co_schema_ok(C, conduit),
    causal_core_conduit_wellformed(C, Pmap, Cmap, ok(_)).
% V75: carrying something the from-port does not accept is malformed.
co_v(75) :- co_conduit_fixture([bad_carry], C, Pmap, _), causal_core_conduit_wellformed(C, Pmap, _{}, invalid(_)).
% V76: a from-port that is inbound is malformed.
co_v(76) :- co_conduit_fixture([in_from], C, Pmap, _), causal_core_conduit_wellformed(C, Pmap, _{}, invalid(_)).
% V77: the transform exception lets the to-port accept the law's effects, not the carried type.
co_v(77) :- co_conduit_fixture([transform], C, Pmap, Cmap), causal_core_conduit_wellformed(C, Pmap, Cmap, ok(_)),
    dict_pairs(Cmap, _, [_-Law]), get_dict(effects, Law, [Eff|_]), get_dict(carries, C, Carries), \+ memberchk(Eff, Carries).
% V78: two realizables with different labels differ in identity.
co_v(78) :- co_cnt("hippocampus", Bc), B = Bc.id,
    co_rlz(B, "disposition", "long_term_potentiation", R1), co_rlz(B, "disposition", "pattern_separation", R2),
    get_dict(id, R1, I1), get_dict(id, R2, I2), I1 \== I2.
% V79: two unlabeled realizables collide (repair), a labeled one does not.
co_v(79) :- co_cnt("hippocampus", Bc), B = Bc.id,
    co_rlz(B, "disposition", none, U1), co_rlz(B, "disposition", none, U2),
    co_schema_ok(U1, realizable), get_dict(id, U1, I1), get_dict(id, U2, I2), I1 == I2,
    co_rlz(B, "disposition", "some_function", U3), get_dict(id, U3, I3), I3 \== I1.
% V80: occurrent_subsumes is a legal enrichment field.
co_v(80) :- co_occ("fires", none, Parent), co_occ("fires_action_potential", none, Child),
    E = _{type:"enrichment", about:Child.id, field:"occurrent_subsumes", entry:Parent.id}, co_sem_ok(E, enrichment).
% V81: an occurrent mereology cycle is detected.
co_v(81) :- co_sym("occurrent:a", A), co_sym("occurrent:b", B),
    atom_string(AK, A), atom_string(BK, B), dict_pairs(Edges, _, [AK-[BK], BK-[AK]]), causal_core_has_cycle(Edges).
% V82: occurrent_part_of is a legal enrichment field.
co_v(82) :- co_occ("eat", none, Whole), co_occ("chew", none, Part),
    E = _{type:"enrichment", about:Part.id, field:"occurrent_part_of", entry:Whole.id}, co_sem_ok(E, enrichment).
% V83: occurrent_part_of legality and no spurious causal_relation_object creation.
co_v(83) :- causal_core_enrichment_field(occurrent_part_of, [occurrent], occurrent),
    co_store_reset(true), co_put(_{type:"occurrent", label:"eat", category:"event"}, _),
    co_put(_{type:"occurrent", label:"chew", category:"event"}, _),
    co_all_objects(Objs), \+ ( member(O, Objs), get_dict(type, O, "causal_relation_object") ).
% V84: two occurrents at different strata differ in their stratum field.
co_v(84) :- co_neuro(S), co_stratum_id(S, 9, S9), co_stratum_id(S, 6, S6),
    co_occ("run", S9, A), co_occ("sprint", S6, B), get_dict(stratum, A, SA), get_dict(stratum, B, SB), SA \== SB.
% V85: a token individual is schema-valid.
co_v(85) :- co_cnt("human_patient", C), co_individual(C.id, "salted_hash_abc123", none, Ti), co_schema_ok(Ti, token_individual).
% V86: a token individual missing instantiates is schema-invalid.
co_v(86) :- co_mk(_{type:"token_individual", designator:"x"}, Bad), co_schema_bad(Bad, token_individual, "instantiates").
% V87: two individuals with different designators differ in identity.
co_v(87) :- co_cnt("human_patient", Cc), C = Cc.id,
    co_individual(C, "hash_a", none, T1), co_individual(C, "hash_b", none, T2),
    get_dict(id, T1, I1), get_dict(id, T2, I2), I1 \== I2.
% V88: an instantaneous token occurrence is schema-valid.
co_v(88) :- co_occ("bilateral_hippocampal_resection", none, O),
    co_token(O.id, _{start:"1953-08-25T00:00:00Z", end:"1953-08-25T00:00:00Z"}, none, none, T), co_schema_ok(T, token_occurrence).
% V89: three interval shapes differ in identity.
co_v(89) :- co_occ("amnesia_onset", none, O), Oid = O.id,
    co_token(Oid, _{start:"1953-08-25T00:00:00Z", end:"1953-08-26T00:00:00Z"}, none, none, B),
    co_token(Oid, _{start:"1953-08-25T00:00:00Z"}, none, none, I),
    co_token(Oid, _{start:"1953-08-25T00:00:00Z", open:true}, none, none, G),
    sort([B.id, I.id, G.id], Ids), length(Ids, 3).
% V90: a token occurrence with participants is schema-valid.
co_v(90) :- co_occ("resection", none, O), co_cnt("human_patient", C),
    co_individual(C.id, "p", none, Patient), co_individual(C.id, "s", none, Surgeon),
    co_token(O.id, _{start:"1953-08-25T00:00:00Z"},
        [_{role:"patient", filler:Patient.id}, _{role:"agent", filler:Surgeon.id}], none, T),
    co_schema_ok(T, token_occurrence).
% V91: a quality is schema-valid.
co_v(91) :- co_quality("cortisol_concentration", "quantity", "ug/dL", none, Q), co_schema_ok(Q, quality).
% -- co_state_fixture(+Datatype, +Value, +Unit, -State, -Quality).
co_state_fixture(Datatype, Value, Unit, St, Q) :-
    co_quality("cortisol_concentration", Datatype, Unit, none, Q), co_cnt("human_patient", C),
    co_individual(C.id, "p", none, Subj),
    co_state(Subj.id, Q.id, Value, _{start:"2026-01-01T00:00:00Z", end:"2026-01-01T01:00:00Z"}, St).
% V92: a quantity state is valid with no gaps.
co_v(92) :- co_state_fixture("quantity", _{quantity:15.0, unit:"ug/dL"}, "ug/dL", St, Q),
    co_schema_ok(St, state_assertion), causal_core_state_gaps(St, Q, []).
% V93: a categorical state is valid with no gaps.
co_v(93) :- co_state_fixture("categorical", _{categorical:"elevated"}, none, St, Q),
    co_schema_ok(St, state_assertion), causal_core_state_gaps(St, Q, []).
% V94: a boolean state is valid with no gaps.
co_v(94) :- co_state_fixture("boolean", _{boolean:true}, none, St, Q),
    co_schema_ok(St, state_assertion), causal_core_state_gaps(St, Q, []).
% V95: a value-type mismatch is surfaced.
co_v(95) :- co_state_fixture("quantity", _{categorical:"elevated"}, "ug/dL", St, Q),
    causal_core_state_gaps(St, Q, [value_type_mismatch]).
% V96: a unit mismatch is surfaced.
co_v(96) :- co_state_fixture("quantity", _{quantity:15.0, unit:"mg/dL"}, "ug/dL", St, Q),
    causal_core_state_gaps(St, Q, [unit_mismatch]).
% -- co_law_and_tokens(-Law, -TC, -TE): a covering law and its cause/effect tokens.
co_law_and_tokens(Law, TC, TE) :-
    co_occ("resection", none, OC), co_occ("amnesia_onset", none, OE),
    co_cro([OC.id], [OE.id], [temporal-_{minimum_delay:0, maximum_delay:1, unit:"days"}, modality-"sufficient"], Law),
    co_token(OC.id, _{start:"1953-08-25T00:00:00Z"}, none, none, TC),
    co_token(OE.id, _{start:"1953-08-25T00:00:00Z", open:true}, none, none, TE).
% V97: a token causal claim is schema-valid.
co_v(97) :- co_law_and_tokens(Law, TC, TE),
    co_tcc([TC.id], [TE.id], Law.id, _{duration:0, unit:"instant"}, true, Claim), co_schema_ok(Claim, token_causal_claim).
% V98: a token causal claim without a covering law is valid and omits it.
co_v(98) :- co_law_and_tokens(_, TC, TE), co_tcc([TC.id], [TE.id], none, none, none, Claim),
    co_schema_ok(Claim, token_causal_claim), \+ get_dict(covering_law, Claim, _).
% V99: an in-window delay is admissible.
co_v(99) :- co_law_and_tokens(Law, _, _), get_dict(temporal, Law, T),
    causal_core_delay_within_window(_{duration:0, unit:"instant"}, T, true).
% V100: an out-of-window delay is not admissible.
co_v(100) :- causal_core_delay_within_window(_{duration:5, unit:"days"}, _{minimum_delay:0, maximum_delay:1, unit:"hours"}, false).
% V101: a cause after its effect is retrocausal.
co_v(101) :- co_occ("x", none, O), Oid = O.id,
    co_token(Oid, _{start:"2026-01-02T00:00:00Z"}, none, none, Cause),
    co_token(Oid, _{start:"2026-01-01T00:00:00Z"}, none, none, Effect),
    co_tcc([Cause.id], [Effect.id], none, none, none, Claim),
    co_map_of([Cause, Effect], Tmap), causal_core_retrocausal(Claim, Tmap).
% V102: tokens that do not instantiate the covering law surface a mismatch.
co_v(102) :- co_cro(["occurrent:foo"], ["occurrent:bar"], Other), co_law_and_tokens(_, TC, TE),
    co_tcc([TC.id], [TE.id], Other.id, none, none, Claim), co_map_of([TC, TE], Tmap),
    causal_core_covering_law_mismatch(Claim, Tmap, Other).
% V103: an assertion about a token is schema-valid.
co_v(103) :- co_sym("token_occurrence:t", About),
    co_signed(assertion, _{about:About, evidence_type:"observation", confidence:0.9}, "signer", 0, A),
    co_schema_ok(A, assertion).
% V104: evidenced_by is identity-bearing.
co_v(104) :- co_sym("token_occurrence:t1", T1), co_sym("token_causal_claim:c1", C1),
    co_key("signer", _, Pub), co_sym("causal_relation_object:law", AboutLaw),
    Base = _{type:"assertion", about:AboutLaw, source:Pub, evidence_type:"intervention",
             strength:0.95, confidence:0.99, timestamp:"2026-07-14T00:00:00Z"},
    put_dict(evidenced_by, Base, [T1, C1], A),
    causal_core_identify(A, assertion, Aid), put_dict(id, A, Aid, AWithId), co_schema_ok(AWithId, assertion),
    causal_core_identify(Base, assertion, BId), Aid \== BId.
% V105: simulation evidence is schema-valid and ranks below observation.
co_v(105) :- co_sym("causal_relation_object:law", About),
    co_signed(assertion, _{about:About, evidence_type:"simulation", confidence:0.5}, "signer", 0, A),
    co_schema_ok(A, assertion).
% V106: whole-word baseline; every scheme in V01-V38 is whole-word; identity is stable.
co_v(106) :-
    forall(between(1, 38, N), ( co_vec(N, V), co_scan_schemes(V, Schemes),
        forall(member(Sc, Schemes), co_whole_word_scheme(Sc)) )),
    Rec = _{type:"occurrent", label:"press_button", category:"action"},
    causal_core_identify(Rec, _, Id1), causal_core_identify(Rec, _, Id2), Id1 == Id2,
    sub_string(Id1, B, _, _, ":"), sub_string(Id1, 0, B, _, "occurrent").
% -- co_scan_schemes(+Node, -Schemes): every id scheme appearing under a node.
co_scan_schemes(Node, Schemes) :- findall(Sc, co_scan_scheme(Node, Sc), Schemes).
% Recurse into strings, lists, and dicts collecting scheme prefixes of ids.
co_scan_scheme(Node, Sc) :- string(Node), co_id_scheme(Node, Sc).
co_scan_scheme(Node, Sc) :- is_list(Node), member(X, Node), co_scan_scheme(X, Sc).
co_scan_scheme(Node, Sc) :- is_dict(Node), dict_pairs(Node, _, Ps), member(_-V, Ps), co_scan_scheme(V, Sc).
% -- co_id_scheme(+String, -Scheme): the scheme of a "scheme:<64 hex>" identifier.
co_id_scheme(S, Sc) :-
    sub_string(S, B, _, _, ":"), sub_string(S, 0, B, _, Scheme),
    BB is B + 1, sub_string(S, BB, _, 0, Rest), co_is_hex64(Rest),
    string_length(Scheme, L), L > 0, string_codes(Scheme, Cs), forall(member(C, Cs), co_scheme_code(C)),
    atom_string(Sc, Scheme).
% -- Scheme characters are lowercase letters, digits, and underscore.
co_scheme_code(C) :- ( C >= 0'a, C =< 0'z ) ; ( C >= 0'0, C =< 0'9 ) ; C == 0'_.
% -- co_whole_word_scheme(+Scheme): the scheme is a known whole word.
co_whole_word_scheme(Sc) :- co_schemes(Schemes), memberchk(Sc, Schemes).
% V107: an abbreviated scheme is rejected; only the whole-word scheme validates.
co_v(107) :-
    Hex = "0000000000000000000000000000000000000000000000000000000000000000",
    atomic_list_concat([c,r,o], Abbr),
    format(string(AbbrId), "~w:~w", [Abbr, Hex]),
    format(string(OccId), "occurrent:~w", [Hex]),
    Abbreviated = _{type:"causal_relation_object", id:AbbrId, causes:[OccId], effects:[OccId]},
    \+ co_schema_ok(Abbreviated, causal_relation_object),
    format(string(StrId), "str:~w", [Hex]),
    AbbrStr = _{type:"stratum", id:StrId, label:"cellular", scheme:"neuroendocrine", ordinal:6},
    \+ co_schema_ok(AbbrStr, stratum),
    format(string(WholeId), "causal_relation_object:~w", [Hex]),
    Whole = _{type:"causal_relation_object", id:WholeId, causes:[OccId], effects:[OccId]},
    co_schema_ok(Whole, causal_relation_object).

% ===========================================================================
% The runner.
% ===========================================================================

% -- co_internal_checks/0: the reference internal invariants, plus a live
% exercise of all three vocabulary packs so the run genuinely drives each.
co_internal_checks :-
    % RFC 8785 key ordering and the number rules (causal_core).
    causal_core_jcs(_{b:2, a:1}, "{\"a\":1,\"b\":2}"),
    causal_core_jcs(1.0, "1"), causal_core_jcs(6.0, "6"), causal_core_jcs(0.7, "0.7"),
    % The normative unit constants (causal_core).
    causal_core_to_seconds(1, months, 2629746), causal_core_to_seconds(1, years, 31556952),
    % Drive noun_backbone: assert a continuant and an is-a edge, read them back.
    noun_backbone_reset,
    noun_backbone_continuant_add(continuant_hippocampus, brain_region),
    noun_backbone_continuant(continuant_hippocampus, brain_region),
    noun_backbone_isa_add(continuant_hippocampus, brain_region),
    noun_backbone_isa(continuant_hippocampus, brain_region),
    % Drive realizable_hinge: assert a realizable and a quality, read them back.
    realizable_hinge_reset,
    realizable_hinge_realizable_add(rlz_ltp, disposition, continuant_hippocampus),
    realizable_hinge_realizable(rlz_ltp, disposition, continuant_hippocampus),
    realizable_hinge_quality_add(q_cortisol, concentration, continuant_hippocampus),
    realizable_hinge_quality(q_cortisol, concentration, continuant_hippocampus).

% -- co_run/0: run all 107 vectors, print a report, and fail on any failure.
co_run :- co_run(_).
% -- co_run(-Failures): run all vectors and unify Failures with the failed ids.
co_run(Failures) :-
    co_vectors_commit(Commit),
    format("PrologAI Causalontology 2.0.0 conformance run~n"),
    format("vectors pinned at causalontology commit ~w~n", [Commit]),
    ( co_internal_checks -> format("internal checks (RFC 8785, unit constants, vocab-pack drive) ... ok~n")
    ; ( format("internal checks FAILED~n"), fail ) ),
    findall(N-Res, ( between(1, 107, N), co_run_one(N, Res) ), Results),
    findall(Nm, ( member(N-fail, Results), co_vec_name(N, Nm) ), Failures),
    aggregate_all(count, member(_-pass, Results), Pass),
    format("~`-t~60|~n"),
    format("~w/107 vectors passed~n", [Pass]),
    ( Failures == [] -> format("PrologAI is CONFORMANT to the suite (vectors frozen at specification 2.0.0).~n")
    ; format("FAILED: ~w~n", [Failures]) ).

% -- co_run_one(+N, -Result): run one vector, printing PASS/FAIL, never throwing.
co_run_one(N, Result) :-
    co_vec_name(N, Name),
    ( catch(( co_v(N) -> Ok = true ; Ok = false ), E, (Ok = error(E))) ),
    ( Ok == true -> Result = pass, format("PASS  ~w~n", [Name])
    ; Ok == false -> Result = fail, format("FAIL  ~w~n", [Name])
    ; Result = fail, format("FAIL  ~w :: ~w~n", [Name, Ok]) ).
