/*  PrologAI — PR 2 Acceptance-Criterion Tests
    AC-PR02-002: bake-off runs; results file exists; default backend = winner.
    Additional unit tests for the six-predicate interface and the Prolog backend.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   assertz(file_search_path(library, VBPath)),
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'], SentPath),
   assertz(file_search_path(library, SentPath)),
   atomic_list_concat([ProjectRoot, '/syntax/prolog'], SynPath),
   assertz(file_search_path(library, SynPath)),
   atomic_list_concat([ProjectRoot, '/launcher'], LauncherPath),
   assertz(file_search_path(library, LauncherPath)),
   nb_setval(pr02_project_root, ProjectRoot).

:- use_module(library(plunit)).
:- use_module(library(vector_backend)).
:- use_module(library(backend_prolog)).
:- use_module(library(bakeoff)).

% ---------------------------------------------------------------------------

:- begin_tests(pr02_vector_backend).

% --- Six-predicate interface ---

test(vb_create_and_close) :-
    vb_create(test_idx, 4, [], Ref),
    vb_close(Ref).

test(vb_insert_and_search) :-
    vb_create(test_search, 4, [], Ref),
    vb_insert(Ref, id1, [1.0, 0.0, 0.0, 0.0], meta(a)),
    vb_insert(Ref, id2, [0.0, 1.0, 0.0, 0.0], meta(b)),
    vb_insert(Ref, id3, [0.0, 0.0, 1.0, 0.0], meta(c)),
    vb_search(Ref, [1.0, 0.0, 0.0, 0.0], 2, Results),
    Results = [_Score1-id1 | _],
    vb_close(Ref).

test(vb_delete) :-
    vb_create(test_delete, 4, [], Ref),
    vb_insert(Ref, del1, [1.0, 0.0, 0.0, 0.0], meta(x)),
    vb_delete(Ref, del1),
    vb_search(Ref, [1.0, 0.0, 0.0, 0.0], 5, Results),
    \+ member(_-del1, Results),
    vb_close(Ref).

test(vb_update_weights) :-
    vb_create(test_weights, 4, [], Ref),
    vb_insert(Ref, w1, [1.0, 0.0, 0.0, 0.0], meta(w)),
    vb_update_weights(Ref, w1, 0.05),
    vb_close(Ref).

% --- Cosine similarity ---

test(cosine_identical, [ true(S =:= 1.0) ]) :-
    backend_prolog:cosine_similarity([1.0,0.0,0.0], [1.0,0.0,0.0], S).

test(cosine_orthogonal, [ true(S =:= 0.0) ]) :-
    backend_prolog:cosine_similarity([1.0,0.0,0.0], [0.0,1.0,0.0], S).

% --- Hash projection ---

test(hash_project_unit_length) :-
    backend_prolog:hash_project(hello_world, 32, Vec),
    backend_prolog:magnitude(Vec, Mag),
    abs(Mag - 1.0) < 0.0001.

% --- Bake-off (AC-PR02-002) ---

test(bakeoff_produces_results_file,
     [ setup( ( nb_getval(pr02_project_root, Root),
                atomic_list_concat([Root,'/docs/bakeoff_results.md'], F),
                ( exists_file(F) -> delete_file(F) ; true ) ) ) ]) :-
    nb_getval(pr02_project_root, Root),
    working_directory(Old, Root),
    run_bakeoff([prolog], [100, 1000]),
    working_directory(_, Old),
    atomic_list_concat([Root, '/docs/bakeoff_results.md'], ResultsFile),
    exists_file(ResultsFile).

test(bakeoff_winner_is_set) :-
    vb_current_backend(Winner),
    atom(Winner).

:- end_tests(pr02_vector_backend).
