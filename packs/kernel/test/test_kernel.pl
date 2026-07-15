%% Declare this file as the 'test_kernel' module with no exported predicates.
:- module(test_kernel, []).

%% Load the built-in 'plunit' library so its test predicates are available here.
:- use_module(library(plunit)).
%% Import [maplist/2] from the built-in 'apply' library for per-element checks.
:- use_module(library(apply), [maplist/2]).
%% Import [lattice_open/2, lattice_close/1] from the 'lattice' library.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1]).
%% Import [set_default_nexus/1] from the 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
%% Load the 'kernel' library under test with its three exported predicates.
:- use_module(library(kernel), [
    %% Supply 'kernel_rewrite_rule/4' as an imported predicate.
    kernel_rewrite_rule/4,
    %% Supply 'kernel_interpret/3' as an imported predicate.
    kernel_interpret/3,
    %% Supply 'kernel_kernel_trace/2' as an imported predicate.
    kernel_kernel_trace/2
%% Close the import list opened above.
]).

%% Open the test block named 'kernel' with a shared setup and cleanup.
:- begin_tests(kernel, [setup(kernel_setup), cleanup(kernel_cleanup)]).

%% Define the setup step run before each test in this block.
kernel_setup :-
    %% Open an in-memory Lattice nexus at a test-local address, binding it to N.
    lattice_open('locus://localhost/test_kernel', N),
    %% Store the nexus reference so cleanup can close the same nexus later.
    nb_setval(test_kernel_nexus_ref, N),
    %% Make N the default nexus so kernel_rewrite_rule/4 writes rules into it.
    set_default_nexus(N).

%% Define the cleanup step run after each test in this block.
kernel_cleanup :-
    %% Retrieve the nexus reference stored during setup.
    nb_getval(test_kernel_nexus_ref, N),
    %% Close the test nexus, releasing its stored rewrite-rule node_facts.
    lattice_close(N).

%% Recognise a valid rewrite-transition step in a derivation trace.
is_kernel_step(step(rewrite, _, _)).
%% Recognise a valid arithmetic-transition step in a derivation trace.
is_kernel_step(step(arith,   _, _)).
%% Recognise a valid recursion-transition step in a derivation trace.
is_kernel_step(step(recurse, _, _)).

%% Test that a factorial rule base evaluates to the correct product via rewriting.
test(factorial_five, [setup(kernel_setup)]) :-
    %% Inscribe the base case that factorial of zero is one.
    kernel_rewrite_rule(factorial(0), 1, true, _),
    %% Inscribe the recursive case gated by a positive-integer guard.
    kernel_rewrite_rule(factorial(N), N * factorial(N1),
                        %% Guard requires a positive integer and computes the predecessor.
                        (integer(N), N > 0, N1 is N - 1), _),
    %% Evaluate factorial of five against the rule base in the Lattice.
    kernel_interpret(factorial(5), Result, []),
    %% Assert the interpreter reduces the expression to one hundred twenty.
    assertion(Result =:= 120).

%% Test that the derivation trace is non-empty and uses only kernel transitions.
test(trace_only_kernel_steps, [setup(kernel_setup)]) :-
    %% Inscribe the factorial base case for this fresh nexus.
    kernel_rewrite_rule(factorial(0), 1, true, _),
    %% Inscribe the factorial recursive case with its positive-integer guard.
    kernel_rewrite_rule(factorial(N), N * factorial(N1),
                        %% Guard requires a positive integer and computes the predecessor.
                        (integer(N), N > 0, N1 is N - 1), _),
    %% Request a forward-order derivation trace for factorial of three.
    kernel_kernel_trace(factorial(3), Trace),
    %% Assert the trace records at least one transition step.
    assertion(Trace \= []),
    %% Assert the first element is a well-formed step/3 term.
    assertion(Trace = [step(_, _, _)|_]),
    %% Assert every element is one of the three named kernel transitions.
    assertion(maplist(is_kernel_step, Trace)).

%% Test that arithmetic sub-expressions are evaluated once their terms are numbers.
test(arithmetic_evaluation, [setup(kernel_setup)]) :-
    %% Evaluate a bare addition with no rewrite rules in scope.
    kernel_interpret(3 + 4, Sum, []),
    %% Assert the addition reduces to seven.
    assertion(Sum =:= 7),
    %% Evaluate a bare multiplication with no rewrite rules in scope.
    kernel_interpret(6 * 7, Product, []),
    %% Assert the multiplication reduces to forty-two.
    assertion(Product =:= 42).

%% Test that an unrecognised expression is returned unchanged (gradual evaluation).
test(unknown_expression_unchanged, [setup(kernel_setup)]) :-
    %% Evaluate an atom for which no rewrite rule exists.
    kernel_interpret(unknown_atom_k, Result, []),
    %% Assert the interpreter echoes the unrecognised atom back verbatim.
    assertion(Result == unknown_atom_k).

%% Test that kernel_rewrite_rule/4 stores a rule and binds a non-var identifier.
test(rule_stored_and_applied, [setup(kernel_setup)]) :-
    %% Inscribe a doubling rule guarded to fire only on numbers.
    kernel_rewrite_rule(double(X), X + X, number(X), RuleId),
    %% Assert the stored rule was given a concrete identifier.
    assertion(nonvar(RuleId)),
    %% Evaluate the doubling of five against the freshly stored rule.
    kernel_interpret(double(5), Result, []),
    %% Assert the rule rewrote and the arithmetic reduced to ten.
    assertion(Result =:= 10).

%% Test that a rule whose guard fails is skipped so a later matching rule fires.
test(guard_failure_skips_rule, [setup(kernel_setup)]) :-
    %% Inscribe a rule that only applies when its argument exceeds ten.
    kernel_rewrite_rule(guarded_fn(G), big, (number(G), G > 10), _),
    %% Inscribe an unconditional fallback rule for any argument.
    kernel_rewrite_rule(guarded_fn(_), small, true, _),
    %% Evaluate with an argument of five, below the first rule's threshold.
    kernel_interpret(guarded_fn(5), Result, []),
    %% Assert the guarded rule was skipped and the fallback rule fired.
    assertion(Result == small).

%% Close the test block named 'kernel'.
:- end_tests(kernel).
