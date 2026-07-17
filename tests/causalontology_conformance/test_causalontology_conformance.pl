% PLUnit wrapper for the Causalontology 2.0.0 conformance suite. It runs all
% 107 vendored vectors (V01-V107) through the conformance runner and asserts a
% clean 107/107 with an empty failure list. This is the merge-gating test.
:- module(test_causalontology_conformance, []).
% Bring in the conformance runner.
:- use_module('run_conformance.pl').
% Bring in the PLUnit test framework.
:- use_module(library(plunit)).

% The one conformance test group.
:- begin_tests(causalontology_conformance).

% test: every one of the 107 vectors passes (the failure list is empty).
test(all_107_vectors_pass) :-
    % Run the whole suite, collecting any failed vector names.
    co_run(Failures),
    % The suite is conformant exactly when nothing failed.
    assertion(Failures == []).

% Close the test group.
:- end_tests(causalontology_conformance).
