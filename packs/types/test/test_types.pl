/*  PrologAI — Gradual Lattice Types Test Suite  (PR 33)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/types/test/test_types.pl

    Exercises the three core exports — types_type_declare/2, types_type_of/2,
    and types_type_check/2 — against a live Lattice nexus, checking that
    declarations are queryable and idempotent, that valid values pass silently,
    and that a mismatch inscribes an ill_typed node_fact (gradual typing).
*/

% Declare this file as a test module.
:- module(test_types, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Import aggregate_all/3 for counting Lattice node_facts.
:- use_module(library(aggregate), [aggregate_all/3]).
% Import the Lattice open/close and node_fact query predicates.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1, lattice_node_fact/5]).
% Import the nexus-default setter and node inscriber.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).
% Load the module under test from the library path.
:- use_module(library(types), [types_type_declare/2, types_type_of/2, types_type_check/2]).

% Open the test block for types, opening a nexus before and closing it after.
:- begin_tests(types, [setup(types_test_setup), cleanup(types_test_cleanup)]).

% Set up a fresh Lattice nexus and make it the default target for anchor_node.
types_test_setup :-
    % Open an isolated nexus for this suite.
    lattice_open('locus://localhost/types_test', N),
    % Remember the nexus reference for cleanup.
    nb_setval(types_test_nexus_ref, N),
    % Route all default-nexus writes into this nexus.
    set_default_nexus(N).

% Tear down the suite by closing the nexus opened in setup.
types_test_cleanup :-
    % Recall the nexus reference stored in setup.
    nb_getval(types_test_nexus_ref, N),
    % Close the nexus.
    lattice_close(N).

% AC-TYPES-001: a declared type is queryable via types_type_of/2.
test(declare_then_query) :-
    % Declare that sensor_reading values are numbers.
    types_type_declare(sensor_reading, number),
    % The declaration is now retrievable from the Lattice.
    assertion(types_type_of(sensor_reading, number)).

% AC-TYPES-002: declaring the same type twice stores exactly one node_fact.
test(declare_idempotent) :-
    % Declare the temperature type once.
    types_type_declare(temperature_c, number),
    % Declare the identical type a second time.
    types_type_declare(temperature_c, number),
    % Count the matching type_of node_facts in the Lattice.
    aggregate_all(count, lattice_node_fact(_, _, type_of, [temperature_c, number], _), Count),
    % Only a single declaration should have been stored.
    assertion(Count =:= 1).

% AC-TYPES-003: types_type_of/2 is backtrackable across distinct subjects.
test(type_of_backtrackable) :-
    % Declare a float-typed subject.
    types_type_declare(pressure_kpa, float),
    % Declare an atom-typed subject.
    types_type_declare(mode_label, atom),
    % Both declarations are independently queryable.
    assertion(types_type_of(pressure_kpa, float)),
    % The second subject resolves to its declared type.
    assertion(types_type_of(mode_label, atom)).

% AC-TYPES-004: a value matching its type passes with no ill_typed inscribed.
test(valid_value_passes_silently) :-
    % Check a genuine integer against the integer type.
    types_type_check(42, integer),
    % No ill_typed node_fact should exist for this valid pairing.
    assertion(\+ lattice_node_fact(_, _, ill_typed, [42, integer], _)).

% AC-TYPES-005: a type mismatch inscribes an ill_typed node_fact and continues.
test(mismatch_inscribes_ill_typed) :-
    % Check an atom against the number type, which must fail the must_be guard.
    types_type_check(low_battery_text, number),
    % An ill_typed node_fact naming the offending value and type now exists.
    assertion(once(lattice_node_fact(_, _, ill_typed, [low_battery_text, number], _))).

% AC-TYPES-006: the checker recognises the atom type correctly.
test(atom_type_recognised) :-
    % Check a genuine atom against the atom type.
    types_type_check(hello_there, atom),
    % No ill_typed node_fact should exist for this valid atom.
    assertion(\+ lattice_node_fact(_, _, ill_typed, [hello_there, atom], _)).

% Close the test block for types.
:- end_tests(types).
