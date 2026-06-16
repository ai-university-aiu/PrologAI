/*  PrologAI — Utility Libraries Tests  */

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/libraries/prolog'],     LibPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LibPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'pai_similarity' library so its predicates are available here.
:- use_module(library(pai_similarity)).
% Load the built-in 'pai_types' library so its predicates are available here.
:- use_module(library(pai_types)).
% Load the built-in 'pai_collections' library so its predicates are available here.
:- use_module(library(pai_collections)).
% Load the built-in 'pai_convenience' library so its predicates are available here.
:- use_module(library(pai_convenience)).

% Execute the compile-time directive: begin_tests(libraries).
:- begin_tests(libraries).

% Similarity
% Check that 'test(similar_identical, [true(S' is greater than '0.99)]) :-'.
test(similar_identical, [true(S > 0.99)]) :-
    % State the fact: pai similar(apple, apple, S).
    pai_similar(apple, apple, S).

% Define a clause for 'test': succeed when the following conditions hold.
test(similar_signed) :-
    % Check that 'pai_similar_signed(a, a, S), S' is greater than '0.5'.
    pai_similar_signed(a, a, S), S > 0.5.

% Define a clause for 'test': succeed when the following conditions hold.
test(closest_match) :-
    % State a fact for 'pai closest match' with the arguments listed below.
    pai_closest_match(apple, [apple, pear, carburetor], 2, Ranked),
    % Check that 'Ranked' is unifiable with '[_-apple | _]'.
    Ranked = [_-apple | _].

% Types
% Define a clause for 'test': succeed when the following conditions hold.
test(truth_atom) :-
    % State the fact: pai truth(true, true).
    pai_truth(true, true).

% Define a clause for 'test': succeed when the following conditions hold.
test(uuid_generated) :-
    % State the fact: pai uuid(U), atom(U).
    pai_uuid(U), atom(U).

% Collections
% Define a clause for 'test': succeed when the following conditions hold.
test(dict_roundtrip) :-
    % State a fact for 'pai dict create' with the arguments listed below.
    pai_dict_create([a-1, b-2], D),
    % State a fact for 'pai dict get' with the arguments listed below.
    pai_dict_get(D, a, 1),
    % State the fact: pai dict get(D, b, 2).
    pai_dict_get(D, b, 2).

% Define a clause for 'test': succeed when the following conditions hold.
test(dict_put) :-
    % State a fact for 'pai dict create' with the arguments listed below.
    pai_dict_create([x-10], D),
    % State a fact for 'pai dict put' with the arguments listed below.
    pai_dict_put(D, x, 20),
    % State the fact: pai dict get(D, x, 20).
    pai_dict_get(D, x, 20).

% Define a clause for 'test': succeed when the following conditions hold.
test(keyword_group) :-
    % State a fact for 'pai keyword group create' with the arguments listed below.
    pai_keyword_group_create(colors, [red, green, blue]),
    % State the fact: pai keyword group member(colors, red).
    pai_keyword_group_member(colors, red).

% Convenience
% Define a clause for 'test': succeed when the following conditions hold.
test(superpose) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(X, pai_superpose([a, b, c], X), Xs),
    % Check that 'Xs' is structurally identical to '[a, b, c]'.
    Xs == [a, b, c].

% Define a clause for 'test': succeed when the following conditions hold.
test(case_match) :-
    % State the fact: pai case(foo, [foo -> bar, default -> baz], bar).
    pai_case(foo, [foo -> bar, default -> baz], bar).

% Define a clause for 'test': succeed when the following conditions hold.
test(critical_section) :-
    % State the fact: pai critical(test_mutex, true).
    pai_critical(test_mutex, true).

% Define a clause for 'test': succeed when the following conditions hold.
test(config_store) :-
    % State a fact for 'pai config open' with the arguments listed below.
    pai_config_open(test_cfg, '/dev/null', []),
    % State a fact for 'pai config set' with the arguments listed below.
    pai_config_set(test_cfg, key1, value1),
    % State a fact for 'pai config get' with the arguments listed below.
    pai_config_get(test_cfg, key1, value1),
    % State the fact: pai config close(test_cfg).
    pai_config_close(test_cfg).

% Execute the compile-time directive: end_tests(libraries).
:- end_tests(libraries).
