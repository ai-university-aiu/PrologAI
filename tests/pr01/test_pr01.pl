/*  PrologAI — PR 1 Acceptance-Criterion Tests
    Tests for: AC-PR01-001, AC-PR01-002, AC-PR01-003
               AC-SYS-002, AC-SYS-005, AC-SYS-006

    Run from the project root:
        swipl -p library=packs/sentinels/prolog \
              -p library=syntax/prolog \
              -p library=launcher \
              -g "load_test_files([tests/pr01/test_pr01.pl]), run_tests" \
              -t halt

    Or via the prologai launcher:
        ./launcher/prologai -g run_tests -t halt tests/pr01/test_pr01.pl
*/

% Add pack library paths relative to the project root so the test file is
% self-contained when loaded from any working directory.
:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'], SentinelsPath),
   atomic_list_concat([ProjectRoot, '/syntax/prolog'],          SyntaxPath),
   atomic_list_concat([ProjectRoot, '/launcher'],               LauncherPath),
   assertz(file_search_path(library, SentinelsPath)),
   assertz(file_search_path(library, SyntaxPath)),
   assertz(file_search_path(library, LauncherPath)),
   nb_setval(pr01_project_root, ProjectRoot),
   nb_setval(pr01_test_dir, TestDir).

:- use_module(library(plunit)).
:- use_module(library(sentinels)).
:- use_module(library(prologai_expand)).
:- use_module(library(prologai_main), [print_prologai_banner/0,
                                        install_bootstrap_ontology/0]).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

clean_test_sentinels :-
    sentinel_retract(general).

% ---------------------------------------------------------------------------
% Tests
% ---------------------------------------------------------------------------

:- begin_tests(pr01_launcher).

% AC-SYS-005 / FR-PR01 — prologai_version flag is set to '1.0.0'
test(version_flag,
     [ true(V == '1.0.0') ]) :-
    current_prolog_flag(prologai_version, V).

% AC-SYS-006 / FR-PR01 — dialect flag remains 'swi' (SWI-Prolog compatibility)
test(dialect_flag,
     [ true(D == swi) ]) :-
    current_prolog_flag(dialect, D).

% AC-PR01-001 / AC-SYS-002 — banner starts with "PrologAI" on the first line
test(banner_first_line_prologai) :-
    with_output_to(string(Banner), print_prologai_banner),
    sub_string(Banner, 0, _, _, "PrologAI").

% AC-PR01-001 — banner contains the SWI-Prolog attribution (BSD-2 licence notice)
test(banner_swi_attribution) :-
    with_output_to(string(Banner), print_prologai_banner),
    ( sub_string(Banner, _, _, _, "SWI-Prolog")
    ; sub_string(Banner, _, _, _, "swi-prolog") ), !.

% AC-SYS-002 — start_prologai/0 is defined (interactive top-level predicate present)
test(start_prologai_defined) :-
    predicate_property(prologai_main:start_prologai, defined).

% AC-PR01-002 — full SWI-Prolog standard library still accessible
test(swi_stdlib_compat) :-
    use_module(library(lists)),
    predicate_property(lists:member(_, _), defined).

% AC-PR01-003 — .pai file declares a sentinel; sentinel_list/2 confirms registration
test(sentinel_registration_via_pai,
     [ setup(clean_test_sentinels),
       cleanup(clean_test_sentinels) ]) :-
    nb_getval(pr01_test_dir, TestDir),
    atomic_list_concat([TestDir, '/fixture_sentinel.pai'], PAIFile),
    load_files(PAIFile, []),
    sentinel_list(general, Sentinels),
    Sentinels \= [].

% AC-PR01-003 (detail) — the loaded sentinel matches the declared term
test(sentinel_content_after_pai_load,
     [ setup(clean_test_sentinels),
       cleanup(clean_test_sentinels) ]) :-
    nb_getval(pr01_test_dir, TestDir),
    atomic_list_concat([TestDir, '/fixture_sentinel.pai'], PAIFile),
    load_files(PAIFile, []),
    sentinel_list(general, Sentinels),
    memberchk(sentinel(general, 100, percept([apple|_]), [], pr01_test_action, _),
              Sentinels).

% install_bootstrap_ontology/0 is defined and deterministic (stub for PR 1)
test(bootstrap_ontology_stub) :-
    install_bootstrap_ontology.

:- end_tests(pr01_launcher).
