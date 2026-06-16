/*  PrologAI — PR 2 Acceptance-Criterion Tests
    AC-PR02-002: bake-off runs; results file exists; default backend = winner.
    Additional unit tests for the six-predicate interface and the Prolog backend.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'], SentPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SentPath)),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/syntax/prolog'], SynPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SynPath)),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/launcher'], LauncherPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LauncherPath)),
   % State the fact: nb setval(pr02_project_root, ProjectRoot).
   nb_setval(pr02_project_root, ProjectRoot).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'vector_backend' library so its predicates are available here.
:- use_module(library(vector_backend)).
% Load the built-in 'backend_prolog' library so its predicates are available here.
:- use_module(library(backend_prolog)).
% Load the built-in 'bakeoff' library so its predicates are available here.
:- use_module(library(bakeoff)).

% ---------------------------------------------------------------------------

% Execute the compile-time directive: begin_tests(pr02_vector_backend).
:- begin_tests(pr02_vector_backend).

% --- Six-predicate interface ---

% Define a clause for 'test': succeed when the following conditions hold.
test(vb_create_and_close) :-
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(test_idx, 4, [], Ref),
    % State the fact: vb close(Ref).
    vb_close(Ref).

% Define a clause for 'test': succeed when the following conditions hold.
test(vb_insert_and_search) :-
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(test_search, 4, [], Ref),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(Ref, id1, [1.0, 0.0, 0.0, 0.0], meta(a)),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(Ref, id2, [0.0, 1.0, 0.0, 0.0], meta(b)),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(Ref, id3, [0.0, 0.0, 1.0, 0.0], meta(c)),
    % State a fact for 'vb search' with the arguments listed below.
    vb_search(Ref, [1.0, 0.0, 0.0, 0.0], 2, Results),
    % Check that 'Results' is unifiable with '[_Score1-id1 | _]'.
    Results = [_Score1-id1 | _],
    % State the fact: vb close(Ref).
    vb_close(Ref).

% Define a clause for 'test': succeed when the following conditions hold.
test(vb_delete) :-
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(test_delete, 4, [], Ref),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(Ref, del1, [1.0, 0.0, 0.0, 0.0], meta(x)),
    % State a fact for 'vb delete' with the arguments listed below.
    vb_delete(Ref, del1),
    % State a fact for 'vb search' with the arguments listed below.
    vb_search(Ref, [1.0, 0.0, 0.0, 0.0], 5, Results),
    % Succeed only if 'member(_-del1, Results' cannot be proved (negation as failure).
    \+ member(_-del1, Results),
    % State the fact: vb close(Ref).
    vb_close(Ref).

% Define a clause for 'test': succeed when the following conditions hold.
test(vb_update_weights) :-
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(test_weights, 4, [], Ref),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(Ref, w1, [1.0, 0.0, 0.0, 0.0], meta(w)),
    % State a fact for 'vb update weights' with the arguments listed below.
    vb_update_weights(Ref, w1, 0.05),
    % State the fact: vb close(Ref).
    vb_close(Ref).

% --- Cosine similarity ---

% Check that 'test(cosine_identical, [ true(S' is numerically equal to '1.0) ]) :-'.
test(cosine_identical, [ true(S =:= 1.0) ]) :-
    % Execute: backend_prolog:cosine_similarity([1.0,0.0,0.0], [1.0,0.0,0.0], S)..
    backend_prolog:cosine_similarity([1.0,0.0,0.0], [1.0,0.0,0.0], S).

% Check that 'test(cosine_orthogonal, [ true(S' is numerically equal to '0.0) ]) :-'.
test(cosine_orthogonal, [ true(S =:= 0.0) ]) :-
    % Execute: backend_prolog:cosine_similarity([1.0,0.0,0.0], [0.0,1.0,0.0], S)..
    backend_prolog:cosine_similarity([1.0,0.0,0.0], [0.0,1.0,0.0], S).

% --- Hash projection ---

% Define a clause for 'test': succeed when the following conditions hold.
test(hash_project_unit_length) :-
    % Execute: backend_prolog:hash_project(hello_world, 32, Vec),.
    backend_prolog:hash_project(hello_world, 32, Vec),
    % Execute: backend_prolog:magnitude(Vec, Mag),.
    backend_prolog:magnitude(Vec, Mag),
    % Check that 'abs(Mag - 1.0)' is less than '0.0001'.
    abs(Mag - 1.0) < 0.0001.

% --- Bake-off (AC-PR02-002) ---

% State a fact for 'test' with the arguments listed below.
test(bakeoff_produces_results_file,
     % Continue the multi-line expression started above.
     [ setup( ( nb_getval(pr02_project_root, Root),
                % Continue the multi-line expression started above.
                atomic_list_concat([Root,'/docs/bakeoff_results.md'], F),
                % Continue the multi-line expression started above.
                ( exists_file(F) -> delete_file(F) ; true ) ) ) ]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr02_project_root, Root),
    % State a fact for 'working directory' with the arguments listed below.
    working_directory(Old, Root),
    % State a fact for 'run bakeoff' with the arguments listed below.
    run_bakeoff([prolog], [100, 1000]),
    % State a fact for 'working directory' with the arguments listed below.
    working_directory(_, Old),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat([Root, '/docs/bakeoff_results.md'], ResultsFile),
    % State the fact: exists file(ResultsFile).
    exists_file(ResultsFile).

% Define a clause for 'test': succeed when the following conditions hold.
test(bakeoff_winner_is_set) :-
    % State a fact for 'vb current backend' with the arguments listed below.
    vb_current_backend(Winner),
    % State the fact: atom(Winner).
    atom(Winner).

% Execute the compile-time directive: end_tests(pr02_vector_backend).
:- end_tests(pr02_vector_backend).
