% Test suite for the packaging pack — dependency kinds, faces, a facade, and a record registry.
% These tests confirm that runtime dependencies are distinguishable from structure-only
% (mint-time) ones, that a face pulls only its own kind of dependency, that a facade
% expands (recursively) to its concrete pack set, and that the cross-pack record registry
% looks up records and owners by id.
% Load the packaging module under test.
:- use_module(library(packaging)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% Open the test block for the packaging pack.
:- begin_tests(packaging).

% Clear every registry before a test so declarations do not leak between tests.
packaging_test_clear :-
    retractall(packaging:packaging_dependency_fact(_, _, _)),
    retractall(packaging:packaging_facade_fact(_, _)),
    retractall(packaging:packaging_record_fact(_, _, _)).

% ATOMIC-1: a structure-only (mint-time) dependency is distinguished from a runtime one,
% so the runtime edge set excludes the mint-time edge that would inflate the layer graph.
test(runtime_excludes_structure_only, setup(packaging_test_clear)) :-
    packaging_declare_dependency(region, causal_core, structure_only),
    packaging_declare_dependency(region, lattice, runtime),
    packaging_runtime_dependencies(region, Runtime),
    assertion(Runtime == [lattice]),
    packaging_structure_only_dependencies(region, MintTime),
    assertion(MintTime == [causal_core]).

% ATOMIC-4: loading the STRUCTURE face pulls only structure faces; the runtime substrate
% is not dragged in. Loading the RUNTIME face pulls only runtime faces.
test(a_face_pulls_only_its_own_kind, setup(packaging_test_clear)) :-
    packaging_declare_dependency(region, causal_core, structure_only),
    packaging_declare_dependency(region, lattice, runtime),
    packaging_face_dependencies(region, structure, StructReqs),
    assertion(StructReqs == [causal_core-structure]),
    packaging_face_dependencies(region, runtime, RuntimeReqs),
    assertion(RuntimeReqs == [lattice-runtime]).

% The required-face mapping is explicit: structure_only needs structure, runtime needs runtime.
test(required_face_mapping, setup(packaging_test_clear)) :-
    packaging_required_face(structure_only, F1), assertion(F1 == structure),
    packaging_required_face(runtime, F2), assertion(F2 == runtime).

% An unknown dependency kind is refused at declaration.
test(unknown_kind_is_refused, [setup(packaging_test_clear),
     throws(error(domain_error(packaging_dependency_kind, _), _))]) :-
    packaging_declare_dependency(a, b, sometimes).

% ATOMIC-2: a facade expands to its members, so a consumer names the bundle, not each pack.
test(facade_expands_to_members, setup(packaging_test_clear)) :-
    packaging_declare_facade(perception_bundle, [grid, scene, object]),
    packaging_expand(perception_bundle, Packs),
    assertion(Packs == [grid, object, scene]).

% A facade may nest another facade; expansion is recursive and de-duplicated.
test(nested_facade_expands_recursively, setup(packaging_test_clear)) :-
    packaging_declare_facade(inner, [grid, scene]),
    packaging_declare_facade(outer, [inner, object, grid]),
    packaging_expand(outer, Packs),
    assertion(Packs == [grid, object, scene]).

% A plain pack (not a facade) expands to just itself.
test(plain_pack_expands_to_itself, setup(packaging_test_clear)) :-
    packaging_expand(lonely_pack, Packs),
    assertion(Packs == [lonely_pack]).

% A cyclic facade declaration does not loop; it expands to the reachable packs.
test(cyclic_facade_terminates, setup(packaging_test_clear)) :-
    packaging_declare_facade(ping, [pong, real_pack]),
    packaging_declare_facade(pong, [ping]),
    packaging_expand(ping, Packs),
    assertion(Packs == [real_pack]).

% ATOMIC-3: the cross-pack record registry looks up a record and its owner by content id.
test(record_registry_looks_up_by_id, setup(packaging_test_clear)) :-
    packaging_register_record('sha256:abc', cro(cause, effect), causal_core),
    packaging_record('sha256:abc', Record),
    assertion(Record == cro(cause, effect)),
    packaging_record_owner('sha256:abc', Owner),
    assertion(Owner == causal_core).

% Re-registering an id replaces the prior record, so an id maps to one record.
test(record_registration_is_idempotent_per_id, setup(packaging_test_clear)) :-
    packaging_register_record('sha256:x', v1, pack_a),
    packaging_register_record('sha256:x', v2, pack_b),
    findall(R, packaging_record('sha256:x', R), Records),
    assertion(Records == [v2]),
    packaging_record_owner('sha256:x', Owner),
    assertion(Owner == pack_b).

% Close the test block.
:- end_tests(packaging).
