/*  PrologAI — PR 33 Gradual Lattice Types Acceptance Tests

    AC-PR33-001: Given type_of(battery_level, number) declared, when a node_fact
                 asserts battery_level with a text argument and the checker runs,
                 then an ill_typed node_fact exists naming the violation, and the
                 system continues running.
    AC-PR33-002: Untyped node_facts are always legal (gradual typing).
    AC-PR33-003: pai_type_declare is idempotent — declaring twice stores once.
    AC-PR33-004: pai_type_of/2 is backtrackable and queryable.
    AC-PR33-005: Valid value against correct type succeeds with no ill_typed.
    AC-PR33-006: After a violation, the offending node_fact stays in the Lattice.
    AC-PR33-007: pai_type_check recognises atom type correctly.
    AC-PR33-008: Types themselves can be typed (types-as-atoms in the Lattice).
    AC-PR33-009: Multiple distinct violations each produce a separate ill_typed.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/types/prolog'],          TypePath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, TypePath)).

:- use_module(library(plunit)).
:- use_module(library(aggregate), [aggregate_all/3]).
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1,
                                   lattice_node_fact/5]).
:- use_module(library(node_facts),[set_default_nexus/1, anchor_node/4]).
:- use_module(library(types), [
    pai_type_declare/2,
    pai_type_of/2,
    pai_type_check/2
]).

:- begin_tests(pr33, [setup(pr33_setup), cleanup(pr33_cleanup)]).

pr33_setup :-
    lattice_open('locus://localhost/pr33', N),
    nb_setval(pr33_nexus_ref, N),
    set_default_nexus(N).

pr33_cleanup :-
    nb_getval(pr33_nexus_ref, N),
    lattice_close(N).

%  AC-PR33-001: type violation inscribes ill_typed; system continues
test(ill_typed_on_type_mismatch) :-
    pai_type_declare(battery_level, number),
    anchor_node(battery_level, [low_battery_text], [], _),
    % Checker runs on the text argument against declared type
    pai_type_check(low_battery_text, number),
    % ill_typed node_fact must now exist
    once(lattice_node_fact(_, _, ill_typed, [low_battery_text, number], _)),
    % System continues — test can proceed
    true.

%  AC-PR33-002: untyped node_facts are always legal (gradual typing)
test(untyped_node_facts_always_legal) :-
    anchor_node(untyped_relation33, [foo, bar], [], Id),
    nonvar(Id),
    % No ill_typed inscribed for untyped relations
    \+ lattice_node_fact(_, _, ill_typed, [foo, _], _).

%  AC-PR33-003: pai_type_declare is idempotent
test(type_declare_idempotent) :-
    pai_type_declare(temperature33, number),
    pai_type_declare(temperature33, number),
    aggregate_all(count,
        lattice_node_fact(_, _, type_of, [temperature33, number], _),
        Count),
    Count =:= 1.

%  AC-PR33-004: pai_type_of/2 queries declared types
test(type_of_queryable) :-
    pai_type_declare(pressure33, float),
    pai_type_declare(label33, atom),
    once(pai_type_of(pressure33, float)),
    once(pai_type_of(label33, atom)).

%  AC-PR33-005: valid value passes type check with no ill_typed for that value
test(valid_value_no_ill_typed) :-
    pai_type_declare(count33, integer),
    pai_type_check(42, integer),
    \+ lattice_node_fact(_, _, ill_typed, [42, integer], _).

%  AC-PR33-006: after violation, offending node_fact stays in the Lattice
test(offending_node_fact_stays) :-
    pai_type_declare(speed33, number),
    anchor_node(speed33, [fast_text], [], NodeId),
    pai_type_check(fast_text, number),
    % ill_typed inscribed
    once(lattice_node_fact(_, _, ill_typed, [fast_text, number], _)),
    % original node_fact still present
    lattice_node_fact(_, NodeId, speed33, [fast_text], _).

%  AC-PR33-007: pai_type_check recognises atom type correctly
test(type_check_atom_type) :-
    pai_type_check(hello, atom),
    \+ lattice_node_fact(_, _, ill_typed, [hello, atom], _).

%  AC-PR33-008: types themselves can be typed (types-as-atoms in the Lattice)
test(types_are_typed) :-
    % Declare that the values of 'sensor_type33' are atoms
    pai_type_declare(sensor_type33, atom),
    % Declare the type declaration itself as a node_fact
    anchor_node(type_of, [sensor_type33, atom], [], MetaId),
    nonvar(MetaId),
    % Query it back
    once(pai_type_of(sensor_type33, atom)).

%  AC-PR33-009: multiple violations produce multiple ill_typed node_facts
test(multiple_violations_separate_ill_typed) :-
    pai_type_declare(voltage33, number),
    pai_type_check(high_text, number),
    pai_type_check(low_text, number),
    once(lattice_node_fact(_, _, ill_typed, [high_text, number], _)),
    once(lattice_node_fact(_, _, ill_typed, [low_text, number], _)).

:- end_tests(pr33).
