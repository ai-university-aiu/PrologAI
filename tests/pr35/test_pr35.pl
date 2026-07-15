/*  PrologAI — PR 35 Lattice-Resident Rewrite Rules / Minimal Kernel Acceptance Tests

    AC-PR35-001: Given a rewrite rule set defining factorial in the Lattice,
                 when kernel_interpret evaluates factorial(5), then 120 is returned
                 and kernel_kernel_trace yields a derivation using only kernel
                 transition rules.
    AC-PR35-002: Two independent runs of the same factorial rule set agree on
                 all results from factorial(0) to factorial(5).
    AC-PR35-003: A rule with guard `true` applies unconditionally.
    AC-PR35-004: A recursive rule terminates (base case fires correctly).
    AC-PR35-005: Arithmetic is evaluated once sub-terms are reduced to numbers.
    AC-PR35-006: An unrecognized expression is returned unchanged (gradual).
    AC-PR35-007: Multiple rule bases can coexist; each is queried correctly.
    AC-PR35-008: kernel_kernel_trace returns a non-empty list of step/3 terms.
    AC-PR35-009: Guard failure causes the rule to be skipped.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/kernel/prolog'],         KernPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, KernPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),   [member/2]).
% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply),   [maplist/2]).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'kernel' library so its predicates are available here.
:- use_module(library(kernel), [
    % Supply 'kernel_rewrite_rule/4' as the next argument to the expression above.
    kernel_rewrite_rule/4,
    % Supply 'kernel_interpret/3' as the next argument to the expression above.
    kernel_interpret/3,
    % Supply 'kernel_kernel_trace/2' as the next argument to the expression above.
    kernel_kernel_trace/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr35, [setup(pr35_setup), cleanup(pr35_cleanup)]).
:- begin_tests(pr35, [setup(pr35_setup), cleanup(pr35_cleanup)]).

% Execute: pr35_setup :-.
pr35_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr35', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr35_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr35_cleanup :-.
pr35_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr35_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% AC-PR35-001: factorial(5) = 120; trace uses only kernel step/3 terms
% Define a clause for 'test': succeed when the following conditions hold.
test(factorial_five) :-
    % Declare factorial rule base
    % State a fact for 'pai rewrite rule' with the arguments listed below.
    kernel_rewrite_rule(factorial(0), 1, true, _),
    % State a fact for 'pai rewrite rule' with the arguments listed below.
    kernel_rewrite_rule(factorial(N), N * factorial(N1),
                     % Continue the multi-line expression started above.
                     (integer(N), N > 0, N1 is N - 1), _),
    % Evaluate
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(5), 120, []),
    % Trace
    % State a fact for 'pai kernel trace' with the arguments listed below.
    kernel_kernel_trace(factorial(5), Trace),
    % Check that 'Trace' is not unifiable with '[]'.
    Trace \= [],
    % State the fact: maplist(is_kernel_step, Trace).
    maplist(is_kernel_step, Trace).

% State the fact: is kernel step(step(rewrite, _, _)).
is_kernel_step(step(rewrite, _, _)).
% State the fact: is kernel step(step(arith,   _, _)).
is_kernel_step(step(arith,   _, _)).
% State the fact: is kernel step(step(recurse, _, _)).
is_kernel_step(step(recurse, _, _)).

% AC-PR35-002: consistency — same rules, all factorial(0..5) agree
% Define a clause for 'test': succeed when the following conditions hold.
test(factorial_consistency) :-
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(0), 1,   []),
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(1), 1,   []),
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(2), 2,   []),
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(3), 6,   []),
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(4), 24,  []),
    % State the fact: pai interpret(factorial(5), 120, []).
    kernel_interpret(factorial(5), 120, []).

% AC-PR35-003: rule with guard `true` applies unconditionally
% Define a clause for 'test': succeed when the following conditions hold.
test(unconditional_rule) :-
    % State a fact for 'pai rewrite rule' with the arguments listed below.
    kernel_rewrite_rule(meaning_of_life, 42, true, _),
    % State the fact: pai interpret(meaning_of_life, 42, []).
    kernel_interpret(meaning_of_life, 42, []).

% AC-PR35-004: recursive rule terminates at base case
% Define a clause for 'test': succeed when the following conditions hold.
test(recursive_terminates_at_base) :-
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(factorial(0), R0, []),
    % Check that 'R0' is numerically equal to '1'.
    R0 =:= 1.

% AC-PR35-005: arithmetic evaluates once sub-terms are numbers
% Define a clause for 'test': succeed when the following conditions hold.
test(arithmetic_evaluation) :-
    % State a fact for 'pai interpret' with the arguments listed below.
    kernel_interpret(3 + 4, 7, []),
    % State the fact: pai interpret(6 * 7, 42, []).
    kernel_interpret(6 * 7, 42, []).

% AC-PR35-006: unrecognized expression returned as-is (gradual)
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_expression_unchanged) :-
    % State the fact: pai interpret(unknown_atom35, unknown_atom35, []).
    kernel_interpret(unknown_atom35, unknown_atom35, []).

% AC-PR35-007: kernel_rewrite_rule stores rule retrievable via lattice
% Define a clause for 'test': succeed when the following conditions hold.
test(rule_stored_in_lattice) :-
    % State a fact for 'pai rewrite rule' with the arguments listed below.
    kernel_rewrite_rule(double(X), X + X, (number(X)), RuleId),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(RuleId),
    % State the fact: pai interpret(double(5), 10, []).
    kernel_interpret(double(5), 10, []).

% AC-PR35-008: kernel_kernel_trace returns non-empty list of step/3 terms
% Define a clause for 'test': succeed when the following conditions hold.
test(trace_non_empty) :-
    % State a fact for 'pai kernel trace' with the arguments listed below.
    kernel_kernel_trace(factorial(3), Trace),
    % Check that 'Trace' is not unifiable with '[]'.
    Trace \= [],
    % Check that 'Trace' is unifiable with '[step(_, _, _)|_]'.
    Trace = [step(_, _, _)|_].

% AC-PR35-009: guard failure skips the rule; next matching rule tried
% Define a clause for 'test': succeed when the following conditions hold.
test(guard_failure_skips_rule) :-
    % Rule: only applies for N > 10 (will not fire for our input)
    % Check that 'kernel_rewrite_rule(guarded_fn(N), big, (number(N), N' is greater than '10), _)'.
    kernel_rewrite_rule(guarded_fn(N), big, (number(N), N > 10), _),
    % Rule: applies for any number
    % State a fact for 'pai rewrite rule' with the arguments listed below.
    kernel_rewrite_rule(guarded_fn(_), small, true, _),
    % State the fact: pai interpret(guarded_fn(5), small, []).
    kernel_interpret(guarded_fn(5), small, []).

% Execute the compile-time directive: end_tests(pr35).
:- end_tests(pr35).
