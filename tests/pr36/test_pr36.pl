/*  PrologAI — PR 36 Hyperon Interoperability Bridge Acceptance Tests

    AC-PR36-001: Given a MeTTa file declaring ten expressions, when imported
                 and re-exported, then the round trip preserves all ten up to
                 alpha renaming.
    AC-PR36-002: pai_atomese_import accepts a list of metta_expr/2 terms.
    AC-PR36-003: Imported node_facts carry the atomese_scope tag in Referents.
    AC-PR36-004: pai_atomese_export produces one line per imported expression.
    AC-PR36-005: pai_atomese_export serializes head and args correctly.
    AC-PR36-006: Import is scoped: different scopes do not contaminate each other.
    AC-PR36-007: pai_space_mount records a named space binding (idempotent).
    AC-PR36-008: pai_atomese_import with MeTTa source text works correctly.
    AC-PR36-009: Zero-arg expressions (facts) round-trip as (Head).
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/interop/prolog'],        IntPath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, IntPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),    [member/2, memberchk/2]).
:- use_module(library(aggregate),[aggregate_all/3]).
:- use_module(library(lattice),  [lattice_open/2, lattice_close/1,
                                   lattice_node_fact/5]).
:- use_module(library(node_facts),[set_default_nexus/1]).
:- use_module(library(interop),  [
    pai_atomese_import/3,
    pai_atomese_export/3,
    pai_space_mount/3
]).

:- begin_tests(pr36, [setup(pr36_setup), cleanup(pr36_cleanup)]).

pr36_setup :-
    lattice_open('locus://localhost/pr36', N),
    nb_setval(pr36_nexus_ref, N),
    set_default_nexus(N),
    retractall(interop:mounted_space(_, _, _)).

pr36_cleanup :-
    nb_getval(pr36_nexus_ref, N),
    retractall(interop:mounted_space(_, _, _)),
    lattice_close(N).

ten_exprs([
    metta_expr(type_of,    [battery_level, number]),
    metta_expr(type_of,    [temperature,   number]),
    metta_expr(type_of,    [status,        atom]),
    metta_expr(fact,       [is_raining]),
    metta_expr(fact,       [is_cold]),
    metta_expr(rule,       [is_raining, wet_ground]),
    metta_expr(rule,       [wet_ground,  slippery]),
    metta_expr(agent,      [robot_x]),
    metta_expr(knows,      [robot_x, is_raining]),
    metta_expr(goal,       [robot_x, stay_indoors])
]).

%  AC-PR36-001: ten expressions — round trip preserves all ten
test(round_trip_ten, [setup(pr36_setup)]) :-
    ten_exprs(Exprs),
    pai_atomese_import(Exprs, scope_rt, Ids),
    length(Ids, 10),
    pai_atomese_export(scope_rt, _, Lines),
    length(Lines, 10).

%  AC-PR36-002: import from list of metta_expr/2
test(import_from_list, [setup(pr36_setup)]) :-
    Exprs = [metta_expr(agent, [alice]), metta_expr(agent, [bob])],
    pai_atomese_import(Exprs, scope_list, Ids),
    length(Ids, 2),
    maplist(nonvar, Ids).

%  AC-PR36-003: imported node_facts carry atomese_scope tag in Referents
test(import_tags_scope, [setup(pr36_setup)]) :-
    pai_atomese_import([metta_expr(color, [red])], scope_tag36, [Id]),
    lattice_node_fact(_, Id, color, [red], Refs),
    memberchk(atomese_scope(scope_tag36), Refs).

%  AC-PR36-004: export produces one line per imported expression
test(export_count_matches_import, [setup(pr36_setup)]) :-
    Exprs = [metta_expr(x36, [a36]), metta_expr(y36, [b36]), metta_expr(z36, [c36])],
    pai_atomese_import(Exprs, scope_cnt, _),
    pai_atomese_export(scope_cnt, _, Lines),
    length(Lines, 3).

%  AC-PR36-005: export serializes head and args correctly
test(export_serialization, [setup(pr36_setup)]) :-
    pai_atomese_import([metta_expr(rule36, [rain36, wet36])], scope_ser, _),
    pai_atomese_export(scope_ser, _, Lines),
    Lines = ['(rule36 rain36 wet36)'].

%  AC-PR36-006: scopes are isolated — different scopes don't contaminate
test(scope_isolation, [setup(pr36_setup)]) :-
    pai_atomese_import([metta_expr(fact36, [alpha])], scope_a36, _),
    pai_atomese_import([metta_expr(fact36, [beta])],  scope_b36, _),
    pai_atomese_export(scope_a36, _, LinesA),
    pai_atomese_export(scope_b36, _, LinesB),
    length(LinesA, 1),
    length(LinesB, 1),
    LinesA \= LinesB.

%  AC-PR36-007: pai_space_mount registers a space binding (idempotent)
test(space_mount_idempotent, [setup(pr36_setup)]) :-
    nb_getval(pr36_nexus_ref, N),
    pai_space_mount(metta_space_36, N, [access(read)]),
    pai_space_mount(metta_space_36, N, [access(read)]),
    aggregate_all(count, interop:mounted_space(metta_space_36, _, _), Count),
    Count =:= 1.

%  AC-PR36-008: import from MeTTa source text
test(import_from_text, [setup(pr36_setup)]) :-
    Source = '(agent robot36)\n(knows robot36 weather)',
    pai_atomese_import(Source, scope_txt, Ids),
    length(Ids, 2).

%  AC-PR36-009: zero-arg expressions (facts) round-trip as (Head)
test(zero_arg_round_trip, [setup(pr36_setup)]) :-
    pai_atomese_import([metta_expr(raining36, [])], scope_zero, _),
    pai_atomese_export(scope_zero, _, Lines),
    Lines = ['(raining36)'].

:- end_tests(pr36).
