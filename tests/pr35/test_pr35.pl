/*  PrologAI — PR 35 Lattice-Resident Rewrite Rules / Minimal Kernel Acceptance Tests

    AC-PR35-001: Given a rewrite rule set defining factorial in the Lattice,
                 when pai_interpret evaluates factorial(5), then 120 is returned
                 and pai_kernel_trace yields a derivation using only kernel
                 transition rules.
    AC-PR35-002: Two independent runs of the same factorial rule set agree on
                 all results from factorial(0) to factorial(5).
    AC-PR35-003: A rule with guard `true` applies unconditionally.
    AC-PR35-004: A recursive rule terminates (base case fires correctly).
    AC-PR35-005: Arithmetic is evaluated once sub-terms are reduced to numbers.
    AC-PR35-006: An unrecognized expression is returned unchanged (gradual).
    AC-PR35-007: Multiple rule bases can coexist; each is queried correctly.
    AC-PR35-008: pai_kernel_trace returns a non-empty list of step/3 terms.
    AC-PR35-009: Guard failure causes the rule to be skipped.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/kernel/prolog'],         KernPath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, KernPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),   [member/2]).
:- use_module(library(apply),   [maplist/2]).
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(kernel), [
    pai_rewrite_rule/4,
    pai_interpret/3,
    pai_kernel_trace/2
]).

:- begin_tests(pr35, [setup(pr35_setup), cleanup(pr35_cleanup)]).

pr35_setup :-
    lattice_open('locus://localhost/pr35', N),
    nb_setval(pr35_nexus_ref, N),
    set_default_nexus(N).

pr35_cleanup :-
    nb_getval(pr35_nexus_ref, N),
    lattice_close(N).

% AC-PR35-001: factorial(5) = 120; trace uses only kernel step/3 terms
test(factorial_five) :-
    % Declare factorial rule base
    pai_rewrite_rule(factorial(0), 1, true, _),
    pai_rewrite_rule(factorial(N), N * factorial(N1),
                     (integer(N), N > 0, N1 is N - 1), _),
    % Evaluate
    pai_interpret(factorial(5), 120, []),
    % Trace
    pai_kernel_trace(factorial(5), Trace),
    Trace \= [],
    maplist(is_kernel_step, Trace).

is_kernel_step(step(rewrite, _, _)).
is_kernel_step(step(arith,   _, _)).
is_kernel_step(step(recurse, _, _)).

% AC-PR35-002: consistency — same rules, all factorial(0..5) agree
test(factorial_consistency) :-
    pai_interpret(factorial(0), 1,   []),
    pai_interpret(factorial(1), 1,   []),
    pai_interpret(factorial(2), 2,   []),
    pai_interpret(factorial(3), 6,   []),
    pai_interpret(factorial(4), 24,  []),
    pai_interpret(factorial(5), 120, []).

% AC-PR35-003: rule with guard `true` applies unconditionally
test(unconditional_rule) :-
    pai_rewrite_rule(meaning_of_life, 42, true, _),
    pai_interpret(meaning_of_life, 42, []).

% AC-PR35-004: recursive rule terminates at base case
test(recursive_terminates_at_base) :-
    pai_interpret(factorial(0), R0, []),
    R0 =:= 1.

% AC-PR35-005: arithmetic evaluates once sub-terms are numbers
test(arithmetic_evaluation) :-
    pai_interpret(3 + 4, 7, []),
    pai_interpret(6 * 7, 42, []).

% AC-PR35-006: unrecognized expression returned as-is (gradual)
test(unknown_expression_unchanged) :-
    pai_interpret(unknown_atom35, unknown_atom35, []).

% AC-PR35-007: pai_rewrite_rule stores rule retrievable via lattice
test(rule_stored_in_lattice) :-
    pai_rewrite_rule(double(X), X + X, (number(X)), RuleId),
    nonvar(RuleId),
    pai_interpret(double(5), 10, []).

% AC-PR35-008: pai_kernel_trace returns non-empty list of step/3 terms
test(trace_non_empty) :-
    pai_kernel_trace(factorial(3), Trace),
    Trace \= [],
    Trace = [step(_, _, _)|_].

% AC-PR35-009: guard failure skips the rule; next matching rule tried
test(guard_failure_skips_rule) :-
    % Rule: only applies for N > 10 (will not fire for our input)
    pai_rewrite_rule(guarded_fn(N), big, (number(N), N > 10), _),
    % Rule: applies for any number
    pai_rewrite_rule(guarded_fn(_), small, true, _),
    pai_interpret(guarded_fn(5), small, []).

:- end_tests(pr35).
