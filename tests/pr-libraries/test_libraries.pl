/*  PrologAI — Utility Libraries Tests  */

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/libraries/prolog'],     LibPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   assertz(file_search_path(library, LibPath)),
   assertz(file_search_path(library, VBPath)).

:- use_module(library(plunit)).
:- use_module(library(pai_similarity)).
:- use_module(library(pai_types)).
:- use_module(library(pai_collections)).
:- use_module(library(pai_convenience)).

:- begin_tests(libraries).

% Similarity
test(similar_identical, [true(S > 0.99)]) :-
    pai_similar(apple, apple, S).

test(similar_signed) :-
    pai_similar_signed(a, a, S), S > 0.5.

test(closest_match) :-
    pai_closest_match(apple, [apple, pear, carburetor], 2, Ranked),
    Ranked = [_-apple | _].

% Types
test(truth_atom) :-
    pai_truth(true, true).

test(uuid_generated) :-
    pai_uuid(U), atom(U).

% Collections
test(dict_roundtrip) :-
    pai_dict_create([a-1, b-2], D),
    pai_dict_get(D, a, 1),
    pai_dict_get(D, b, 2).

test(dict_put) :-
    pai_dict_create([x-10], D),
    pai_dict_put(D, x, 20),
    pai_dict_get(D, x, 20).

test(keyword_group) :-
    pai_keyword_group_create(colors, [red, green, blue]),
    pai_keyword_group_member(colors, red).

% Convenience
test(superpose) :-
    findall(X, pai_superpose([a, b, c], X), Xs),
    Xs == [a, b, c].

test(case_match) :-
    pai_case(foo, [foo -> bar, default -> baz], bar).

test(critical_section) :-
    pai_critical(test_mutex, true).

test(config_store) :-
    pai_config_open(test_cfg, '/dev/null', []),
    pai_config_set(test_cfg, key1, value1),
    pai_config_get(test_cfg, key1, value1),
    pai_config_close(test_cfg).

:- end_tests(libraries).
