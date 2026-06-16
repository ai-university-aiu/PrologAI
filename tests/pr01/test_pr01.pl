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
% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'], SentinelsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/syntax/prolog'],          SyntaxPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/launcher'],               LauncherPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SentinelsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SyntaxPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LauncherPath)),
   % State a fact for 'nb setval' with the arguments listed below.
   nb_setval(pr01_project_root, ProjectRoot),
   % State the fact: nb setval(pr01_test_dir, TestDir).
   nb_setval(pr01_test_dir, TestDir).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'sentinels' library so its predicates are available here.
:- use_module(library(sentinels)).
% Load the built-in 'prologai_expand' library so its predicates are available here.
:- use_module(library(prologai_expand)).
% Load the built-in 'prologai_main' library so its predicates are available here.
:- use_module(library(prologai_main), [print_prologai_banner/0,
                                        % Continue the multi-line expression started above.
                                        install_bootstrap_ontology/0]).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

% Execute: clean_test_sentinels :-.
clean_test_sentinels :-
    % State the fact: sentinel retract(general).
    sentinel_retract(general).

% ---------------------------------------------------------------------------
% Tests
% ---------------------------------------------------------------------------

% Execute the compile-time directive: begin_tests(pr01_launcher).
:- begin_tests(pr01_launcher).

% AC-SYS-005 / FR-PR01 — prologai_version flag is set to '1.0.0'
% State a fact for 'test' with the arguments listed below.
test(version_flag,
     % Continue the multi-line expression started above.
     [ true(V == '1.0.0') ]) :-
    % State the fact: current prolog flag(prologai_version, V).
    current_prolog_flag(prologai_version, V).

% AC-SYS-006 / FR-PR01 — dialect flag remains 'swi' (SWI-Prolog compatibility)
% State a fact for 'test' with the arguments listed below.
test(dialect_flag,
     % Continue the multi-line expression started above.
     [ true(D == swi) ]) :-
    % State the fact: current prolog flag(dialect, D).
    current_prolog_flag(dialect, D).

% AC-PR01-001 / AC-SYS-002 — banner starts with "PrologAI" on the first line
% Define a clause for 'test': succeed when the following conditions hold.
test(banner_first_line_prologai) :-
    % State a fact for 'with output to' with the arguments listed below.
    with_output_to(string(Banner), print_prologai_banner),
    % State the fact: sub string(Banner, 0, _, _, "PrologAI").
    sub_string(Banner, 0, _, _, "PrologAI").

% AC-PR01-001 — banner contains the SWI-Prolog attribution (BSD-2 licence notice)
% Define a clause for 'test': succeed when the following conditions hold.
test(banner_swi_attribution) :-
    % State a fact for 'with output to' with the arguments listed below.
    with_output_to(string(Banner), print_prologai_banner),
    % Execute: ( sub_string(Banner, _, _, _, "SWI-Prolog").
    ( sub_string(Banner, _, _, _, "SWI-Prolog")
    % Otherwise (else branch), perform the following action.
    ; sub_string(Banner, _, _, _, "swi-prolog") ), !.

% AC-SYS-002 — start_prologai/0 is defined (interactive top-level predicate present)
% Define a clause for 'test': succeed when the following conditions hold.
test(start_prologai_defined) :-
    % State the fact: predicate property(prologai_main:start_prologai, defined).
    predicate_property(prologai_main:start_prologai, defined).

% AC-PR01-002 — full SWI-Prolog standard library still accessible
% Define a clause for 'test': succeed when the following conditions hold.
test(swi_stdlib_compat) :-
    % State a fact for 'use module' with the arguments listed below.
    use_module(library(lists)),
    % State the fact: predicate property(lists:member(_, _), defined).
    predicate_property(lists:member(_, _), defined).

% AC-PR01-003 — .pai file declares a sentinel; sentinel_list/2 confirms registration
% State a fact for 'test' with the arguments listed below.
test(sentinel_registration_via_pai,
     % Continue the multi-line expression started above.
     [ setup(clean_test_sentinels),
       % Continue the multi-line expression started above.
       cleanup(clean_test_sentinels) ]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr01_test_dir, TestDir),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat([TestDir, '/fixture_sentinel.pai'], PAIFile),
    % State a fact for 'load files' with the arguments listed below.
    load_files(PAIFile, []),
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinel_list(general, Sentinels),
    % Check that 'Sentinels' is not unifiable with '[]'.
    Sentinels \= [].

% AC-PR01-003 (detail) — the loaded sentinel matches the declared term
% State a fact for 'test' with the arguments listed below.
test(sentinel_content_after_pai_load,
     % Continue the multi-line expression started above.
     [ setup(clean_test_sentinels),
       % Continue the multi-line expression started above.
       cleanup(clean_test_sentinels) ]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr01_test_dir, TestDir),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat([TestDir, '/fixture_sentinel.pai'], PAIFile),
    % State a fact for 'load files' with the arguments listed below.
    load_files(PAIFile, []),
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinel_list(general, Sentinels),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(sentinel(general, 100, percept([apple|_]), [], pr01_test_action, _),
              % Supply 'Sentinels' as the next argument to the expression above.
              Sentinels).

% install_bootstrap_ontology/0 is defined and deterministic (stub for PR 1)
% Define a clause for 'test': succeed when the following conditions hold.
test(bootstrap_ontology_stub) :-
    % State the zero-argument fact 'install_bootstrap_ontology'.
    install_bootstrap_ontology.

% Execute the compile-time directive: end_tests(pr01_launcher).
:- end_tests(pr01_launcher).
