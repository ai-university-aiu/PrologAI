/*  PrologAI — Utility Libraries Test Suite  (libraries pack)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/libraries/test/test_libraries.pl

    The libraries pack is multi-file, so this suite loads the four submodules
    (collections, types, convenience, similarity) that define the predicates
    exercised below.
*/

% Declare this file as a test module.
:- module(test_libraries, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the collections submodule (dicts, enumerations, keyword groups).
:- use_module(library(prologai_collections)).
% Load the types submodule (truth values, UUIDs, constants).
:- use_module(library(prologai_types)).
% Load the convenience submodule (case, step, superpose, collapse, config).
:- use_module(library(prologai_convenience)).
% Load the similarity submodule (hash-projected cosine similarity).
:- use_module(library(prologai_similarity)).

% Open the test block.
:- begin_tests(libraries).

% ---------------------------------------------------------------------------
% Collections: mutable global-store dictionaries
% ---------------------------------------------------------------------------

% A dict round-trips through create/get, and put overwrites a key in place.
test(dict_create_get_put) :-
    % Create a dict with two initial pairs.
    prologai_dict_create([a-1, b-2], D),
    % The value stored under key a is 1.
    prologai_dict_get(D, a, Va),
    % Assert the fetched value equals 1.
    assertion(Va == 1),
    % The value stored under key b is 2.
    prologai_dict_get(D, b, Vb),
    % Assert the fetched value equals 2.
    assertion(Vb == 2),
    % Overwrite key a with a new value.
    prologai_dict_put(D, a, 99),
    % Fetch the overwritten value.
    prologai_dict_get(D, a, Va2),
    % Assert the overwrite took effect.
    assertion(Va2 == 99).

% Keys and values reflect the current dict contents.
test(dict_keys_values) :-
    % Create a dict with three pairs.
    prologai_dict_create([x-10, y-20, z-30], D),
    % Collect the keys of the dict.
    prologai_dict_keys(D, Keys),
    % Assert every original key is present (order-independent).
    assertion((member(x, Keys), member(y, Keys), member(z, Keys))),
    % Collect the values of the dict.
    prologai_dict_values(D, Values),
    % Assert every original value is present.
    assertion((member(10, Values), member(20, Values), member(30, Values))).

% Cutting a key removes it so a later get fails.
test(dict_cut_removes_key) :-
    % Create a dict with two pairs.
    prologai_dict_create([p-1, q-2], D),
    % Remove key p from the dict.
    prologai_dict_cut(D, p),
    % Assert p is now absent (get fails).
    assertion(\+ prologai_dict_get(D, p, _)),
    % Assert q survived the cut.
    prologai_dict_get(D, q, Vq),
    % Assert the surviving value is unchanged.
    assertion(Vq == 2).

% ---------------------------------------------------------------------------
% Collections: enumerations and keyword groups
% ---------------------------------------------------------------------------

% An enumeration assigns zero-based ordinals in declaration order.
test(enumeration_ordinals) :-
    % Create an enumeration named days over three keys.
    prologai_enumeration_create(days, [mon, tue, wed], []),
    % The first key has ordinal 0.
    prologai_enum_value(days, mon, Omon),
    % Assert the first ordinal is 0.
    assertion(Omon == 0),
    % The third key has ordinal 2.
    prologai_enum_value(days, wed, Owed),
    % Assert the third ordinal is 2.
    assertion(Owed == 2),
    % The key list preserves declaration order.
    prologai_enum_keys(days, Keys),
    % Assert the keys came back in order.
    assertion(Keys == [mon, tue, wed]).

% A keyword group reports membership and lists its members.
test(keyword_group_membership) :-
    % Create a keyword group named colors.
    prologai_keyword_group_create(colors, [red, green, blue]),
    % Assert a known member is recognized.
    assertion(prologai_keyword_group_member(colors, green)),
    % Assert a non-member is rejected.
    assertion(\+ prologai_keyword_group_member(colors, purple)),
    % Fetch the full member list.
    prologai_keyword_group_members(colors, Members),
    % Assert the stored members are returned intact.
    assertion(Members == [red, green, blue]).

% ---------------------------------------------------------------------------
% Types: six-valued truth, UUIDs, and constants
% ---------------------------------------------------------------------------

% Truth resolves literal truth atoms and evaluates ground callable goals.
test(truth_evaluation) :-
    % The literal true maps to true.
    prologai_truth(true, T1),
    % Assert the literal true resolves to true.
    assertion(T1 == true),
    % A ground goal that succeeds resolves to true.
    prologai_truth(atom(hello), T2),
    % Assert the succeeding ground goal is true.
    assertion(T2 == true),
    % A ground goal that fails resolves to false.
    prologai_truth(atom(123), T3),
    % Assert the failing ground goal is false.
    assertion(T3 == false).

% A generated UUID is recognized as a UUID; arbitrary atoms are not.
test(uuid_generate_and_recognize) :-
    % Generate a fresh UUID.
    prologai_uuid(U),
    % Assert the generated value is an atom.
    assertion(atom(U)),
    % Assert the generated value is recognized as a UUID.
    assertion(prologai_is_uuid(U)),
    % Assert a plainly non-UUID atom is rejected.
    assertion(\+ prologai_is_uuid(not_a_uuid)).

% A named constant can be defined once and read back.
test(constant_define_and_read) :-
    % Define a constant with a numeric value.
    prologai_constant(golden_ratio, 1.618),
    % Read the constant back.
    prologai_constant_value(golden_ratio, V),
    % Assert the stored value round-trips.
    assertion(V == 1.618).

% ---------------------------------------------------------------------------
% Convenience: case, numeric step, nondeterminism helpers
% ---------------------------------------------------------------------------

% Case selects an exact pattern, else the default, else no_match.
test(case_selection) :-
    % An exact key selects its result.
    prologai_case(foo, [foo -> bar, default -> baz], R1),
    % Assert the exact match wins.
    assertion(R1 == bar),
    % An unlisted key falls through to the default.
    prologai_case(qux, [foo -> bar, default -> baz], R2),
    % Assert the default is used.
    assertion(R2 == baz),
    % With no default, an unlisted key yields no_match.
    prologai_case(qux, [foo -> bar], R3),
    % Assert the sentinel no_match is returned.
    assertion(R3 == no_match).

% Step enumerates a numeric range at a fixed stride.
test(step_enumeration) :-
    % Collect every value from 1 to 5 stepping by 2.
    findall(N, prologai_step(1, 5, 2, N), Ns),
    % Assert the inclusive stepped range is produced.
    assertion(Ns == [1, 3, 5]).

% Superpose enumerates alternatives; collapse takes a bounded prefix.
test(superpose_and_collapse) :-
    % Enumerate every alternative in order.
    findall(X, prologai_superpose([a, b, c], X), Xs),
    % Assert all alternatives are yielded in order.
    assertion(Xs == [a, b, c]),
    % Collapse a four-element generator to a budget of two.
    prologai_collapse([Y]>>member(Y, [w, x, y, z]), 2, Taken),
    % Assert only the first two solutions survive the budget.
    assertion(Taken == [w, x]).

% Confirm succeeds silently on a true goal and throws on a false one.
test(confirm_guards_goal) :-
    % A satisfied guard succeeds without error.
    assertion(prologai_confirm(1 =:= 1, one_is_one)),
    % A violated guard throws, so catching it and failing makes the whole goal fail.
    assertion(\+ catch(prologai_confirm(1 =:= 2, mismatch), _, fail)).

% ---------------------------------------------------------------------------
% Convenience: config store round-trip
% ---------------------------------------------------------------------------

% A config store round-trips a key through open/set/get and is cleared on close.
test(config_store_roundtrip) :-
    % Open a named config store.
    prologai_config_open(test_cfg, '/dev/null', []),
    % Set a key to a value.
    prologai_config_set(test_cfg, host, localhost),
    % Read the key back.
    prologai_config_get(test_cfg, host, Got),
    % Assert the value round-trips.
    assertion(Got == localhost),
    % Close the store, discarding its entries.
    prologai_config_close(test_cfg),
    % Assert the key is gone after close.
    assertion(\+ prologai_config_get(test_cfg, host, _)).

% ---------------------------------------------------------------------------
% Similarity: identical inputs are maximally similar
% ---------------------------------------------------------------------------

% An atom is (near-)maximally similar to itself and the signed score is high.
test(similarity_self) :-
    % Score an atom against itself on the [0,1] scale.
    prologai_similar(apple, apple, S),
    % Assert self-similarity is essentially 1.
    assertion(S > 0.99),
    % Score the same pair on the signed [-1,1] scale.
    prologai_similar_signed(apple, apple, Ss),
    % Assert the signed self-similarity is strongly positive.
    assertion(Ss > 0.5).

% Close the test block.
:- end_tests(libraries).
