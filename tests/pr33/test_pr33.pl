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
   atomic_list_concat([ProjectRoot, '/packs/types/prolog'],          TypePath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, TypePath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1,
                                   % Continue the multi-line expression started above.
                                   lattice_node_fact/5]).
% Import [set_default_nexus/1, anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts),[set_default_nexus/1, anchor_node/4]).
% Load the built-in 'types' library so its predicates are available here.
:- use_module(library(types), [
    % Supply 'pai_type_declare/2' as the next argument to the expression above.
    pai_type_declare/2,
    % Supply 'pai_type_of/2' as the next argument to the expression above.
    pai_type_of/2,
    % Supply 'pai_type_check/2' as the next argument to the expression above.
    pai_type_check/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr33, [setup(pr33_setup), cleanup(pr33_cleanup)]).
:- begin_tests(pr33, [setup(pr33_setup), cleanup(pr33_cleanup)]).

% Execute: pr33_setup :-.
pr33_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr33', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr33_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr33_cleanup :-.
pr33_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr33_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR33-001: type violation inscribes ill_typed; system continues
% Define a clause for 'test': succeed when the following conditions hold.
test(ill_typed_on_type_mismatch) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(battery_level, number),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(battery_level, [low_battery_text], [], _),
    % Checker runs on the text argument against declared type
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(low_battery_text, number),
    % ill_typed node_fact must now exist
    % State a fact for 'once' with the arguments listed below.
    once(lattice_node_fact(_, _, ill_typed, [low_battery_text, number], _)),
    % System continues — test can proceed
    % Succeed unconditionally (no-op placeholder).
    true.

%  AC-PR33-002: untyped node_facts are always legal (gradual typing)
% Define a clause for 'test': succeed when the following conditions hold.
test(untyped_node_facts_always_legal) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(untyped_relation33, [foo, bar], [], Id),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(Id),
    % No ill_typed inscribed for untyped relations
    % Succeed only if 'lattice_node_fact(_, _, ill_typed, [foo, _], _' cannot be proved (negation as failure).
    \+ lattice_node_fact(_, _, ill_typed, [foo, _], _).

%  AC-PR33-003: pai_type_declare is idempotent
% Define a clause for 'test': succeed when the following conditions hold.
test(type_declare_idempotent) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(temperature33, number),
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(temperature33, number),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
        % Continue the multi-line expression started above.
        lattice_node_fact(_, _, type_of, [temperature33, number], _),
        % Supply 'Count' as the next argument to the expression above.
        Count),
    % Check that 'Count' is numerically equal to '1'.
    Count =:= 1.

%  AC-PR33-004: pai_type_of/2 queries declared types
% Define a clause for 'test': succeed when the following conditions hold.
test(type_of_queryable) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(pressure33, float),
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(label33, atom),
    % State a fact for 'once' with the arguments listed below.
    once(pai_type_of(pressure33, float)),
    % State the fact: once(pai_type_of(label33, atom)).
    once(pai_type_of(label33, atom)).

%  AC-PR33-005: valid value passes type check with no ill_typed for that value
% Define a clause for 'test': succeed when the following conditions hold.
test(valid_value_no_ill_typed) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(count33, integer),
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(42, integer),
    % Succeed only if 'lattice_node_fact(_, _, ill_typed, [42, integer], _' cannot be proved (negation as failure).
    \+ lattice_node_fact(_, _, ill_typed, [42, integer], _).

%  AC-PR33-006: after violation, offending node_fact stays in the Lattice
% Define a clause for 'test': succeed when the following conditions hold.
test(offending_node_fact_stays) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(speed33, number),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(speed33, [fast_text], [], NodeId),
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(fast_text, number),
    % ill_typed inscribed
    % State a fact for 'once' with the arguments listed below.
    once(lattice_node_fact(_, _, ill_typed, [fast_text, number], _)),
    % original node_fact still present
    % State the fact: lattice node fact(_, NodeId, speed33, [fast_text], _).
    lattice_node_fact(_, NodeId, speed33, [fast_text], _).

%  AC-PR33-007: pai_type_check recognises atom type correctly
% Define a clause for 'test': succeed when the following conditions hold.
test(type_check_atom_type) :-
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(hello, atom),
    % Succeed only if 'lattice_node_fact(_, _, ill_typed, [hello, atom], _' cannot be proved (negation as failure).
    \+ lattice_node_fact(_, _, ill_typed, [hello, atom], _).

%  AC-PR33-008: types themselves can be typed (types-as-atoms in the Lattice)
% Define a clause for 'test': succeed when the following conditions hold.
test(types_are_typed) :-
    % Declare that the values of 'sensor_type33' are atoms
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(sensor_type33, atom),
    % Declare the type declaration itself as a node_fact
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(type_of, [sensor_type33, atom], [], MetaId),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(MetaId),
    % Query it back
    % State the fact: once(pai_type_of(sensor_type33, atom)).
    once(pai_type_of(sensor_type33, atom)).

%  AC-PR33-009: multiple violations produce multiple ill_typed node_facts
% Define a clause for 'test': succeed when the following conditions hold.
test(multiple_violations_separate_ill_typed) :-
    % State a fact for 'pai type declare' with the arguments listed below.
    pai_type_declare(voltage33, number),
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(high_text, number),
    % State a fact for 'pai type check' with the arguments listed below.
    pai_type_check(low_text, number),
    % State a fact for 'once' with the arguments listed below.
    once(lattice_node_fact(_, _, ill_typed, [high_text, number], _)),
    % State the fact: once(lattice_node_fact(_, _, ill_typed, [low_text, number], _)).
    once(lattice_node_fact(_, _, ill_typed, [low_text, number], _)).

% Execute the compile-time directive: end_tests(pr33).
:- end_tests(pr33).
