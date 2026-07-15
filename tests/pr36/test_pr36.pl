/*  PrologAI — PR 36 Hyperon Interoperability Bridge Acceptance Tests

    AC-PR36-001: Given a MeTTa file declaring ten expressions, when imported
                 and re-exported, then the round trip preserves all ten up to
                 alpha renaming.
    AC-PR36-002: interop_atomese_import accepts a list of metta_expr/2 terms.
    AC-PR36-003: Imported node_facts carry the atomese_scope tag in Referents.
    AC-PR36-004: interop_atomese_export produces one line per imported expression.
    AC-PR36-005: interop_atomese_export serializes head and args correctly.
    AC-PR36-006: Import is scoped: different scopes do not contaminate each other.
    AC-PR36-007: interop_space_mount records a named space binding (idempotent).
    AC-PR36-008: interop_atomese_import with MeTTa source text works correctly.
    AC-PR36-009: Zero-arg expressions (facts) round-trip as (Head).
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
   atomic_list_concat([ProjectRoot, '/packs/interop/prolog'],        IntPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, IntPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),    [member/2, memberchk/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),[aggregate_all/3]).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),  [lattice_open/2, lattice_close/1,
                                   % Continue the multi-line expression started above.
                                   lattice_node_fact/5]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),[set_default_nexus/1]).
% Load the built-in 'interop' library so its predicates are available here.
:- use_module(library(interop),  [
    % Supply 'interop_atomese_import/3' as the next argument to the expression above.
    interop_atomese_import/3,
    % Supply 'interop_atomese_export/3' as the next argument to the expression above.
    interop_atomese_export/3,
    % Supply 'interop_space_mount/3' as the next argument to the expression above.
    interop_space_mount/3
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr36, [setup(pr36_setup), cleanup(pr36_cleanup)]).
:- begin_tests(pr36, [setup(pr36_setup), cleanup(pr36_cleanup)]).

% Execute: pr36_setup :-.
pr36_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr36', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr36_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(interop:mounted_space(_, _, _)).

% Execute: pr36_cleanup :-.
pr36_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr36_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(interop:mounted_space(_, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

% State a fact for 'ten exprs' with the arguments listed below.
ten_exprs([
    % Continue the multi-line expression started above.
    metta_expr(type_of,    [battery_level, number]),
    % Continue the multi-line expression started above.
    metta_expr(type_of,    [temperature,   number]),
    % Continue the multi-line expression started above.
    metta_expr(type_of,    [status,        atom]),
    % Continue the multi-line expression started above.
    metta_expr(fact,       [is_raining]),
    % Continue the multi-line expression started above.
    metta_expr(fact,       [is_cold]),
    % Continue the multi-line expression started above.
    metta_expr(rule,       [is_raining, wet_ground]),
    % Continue the multi-line expression started above.
    metta_expr(rule,       [wet_ground,  slippery]),
    % Continue the multi-line expression started above.
    metta_expr(agent,      [robot_x]),
    % Continue the multi-line expression started above.
    metta_expr(knows,      [robot_x, is_raining]),
    % Continue the multi-line expression started above.
    metta_expr(goal,       [robot_x, stay_indoors])
% Close the expression opened above.
]).

%  AC-PR36-001: ten expressions — round trip preserves all ten
% Define a clause for 'test': succeed when the following conditions hold.
test(round_trip_ten, [setup(pr36_setup)]) :-
    % State a fact for 'ten exprs' with the arguments listed below.
    ten_exprs(Exprs),
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import(Exprs, scope_rt, Ids),
    % Unify '10' with the number of elements in list 'Ids'.
    length(Ids, 10),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_rt, _, Lines),
    % Unify '10' with the number of elements in list 'Lines'.
    length(Lines, 10).

%  AC-PR36-002: import from list of metta_expr/2
% Define a clause for 'test': succeed when the following conditions hold.
test(import_from_list, [setup(pr36_setup)]) :-
    % Check that 'Exprs' is unifiable with '[metta_expr(agent, [alice]), metta_expr(agent, [bob])]'.
    Exprs = [metta_expr(agent, [alice]), metta_expr(agent, [bob])],
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import(Exprs, scope_list, Ids),
    % Unify '2' with the number of elements in list 'Ids'.
    length(Ids, 2),
    % State the fact: maplist(nonvar, Ids).
    maplist(nonvar, Ids).

%  AC-PR36-003: imported node_facts carry atomese_scope tag in Referents
% Define a clause for 'test': succeed when the following conditions hold.
test(import_tags_scope, [setup(pr36_setup)]) :-
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import([metta_expr(color, [red])], scope_tag36, [Id]),
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, Id, color, [red], Refs),
    % State the fact: memberchk(atomese_scope(scope_tag36), Refs).
    memberchk(atomese_scope(scope_tag36), Refs).

%  AC-PR36-004: export produces one line per imported expression
% Define a clause for 'test': succeed when the following conditions hold.
test(export_count_matches_import, [setup(pr36_setup)]) :-
    % Check that 'Exprs' is unifiable with '[metta_expr(x36, [a36]), metta_expr(y36, [b36]), metta_expr(z36, [c36])]'.
    Exprs = [metta_expr(x36, [a36]), metta_expr(y36, [b36]), metta_expr(z36, [c36])],
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import(Exprs, scope_cnt, _),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_cnt, _, Lines),
    % Unify '3' with the number of elements in list 'Lines'.
    length(Lines, 3).

%  AC-PR36-005: export serializes head and args correctly
% Define a clause for 'test': succeed when the following conditions hold.
test(export_serialization, [setup(pr36_setup)]) :-
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import([metta_expr(rule36, [rain36, wet36])], scope_ser, _),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_ser, _, Lines),
    % Check that 'Lines' is unifiable with '['(rule36 rain36 wet36)']'.
    Lines = ['(rule36 rain36 wet36)'].

%  AC-PR36-006: scopes are isolated — different scopes don't contaminate
% Define a clause for 'test': succeed when the following conditions hold.
test(scope_isolation, [setup(pr36_setup)]) :-
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import([metta_expr(fact36, [alpha])], scope_a36, _),
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import([metta_expr(fact36, [beta])],  scope_b36, _),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_a36, _, LinesA),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_b36, _, LinesB),
    % Unify '1' with the number of elements in list 'LinesA'.
    length(LinesA, 1),
    % Unify '1' with the number of elements in list 'LinesB'.
    length(LinesB, 1),
    % Check that 'LinesA' is not unifiable with 'LinesB'.
    LinesA \= LinesB.

%  AC-PR36-007: interop_space_mount registers a space binding (idempotent)
% Define a clause for 'test': succeed when the following conditions hold.
test(space_mount_idempotent, [setup(pr36_setup)]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr36_nexus_ref, N),
    % State a fact for 'pai space mount' with the arguments listed below.
    interop_space_mount(metta_space_36, N, [access(read)]),
    % State a fact for 'pai space mount' with the arguments listed below.
    interop_space_mount(metta_space_36, N, [access(read)]),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, interop:mounted_space(metta_space_36, _, _), Count),
    % Check that 'Count' is numerically equal to '1'.
    Count =:= 1.

%  AC-PR36-008: import from MeTTa source text
% Define a clause for 'test': succeed when the following conditions hold.
test(import_from_text, [setup(pr36_setup)]) :-
    % Check that 'Source' is unifiable with ''(agent robot36)\n(knows robot36 weather)''.
    Source = '(agent robot36)\n(knows robot36 weather)',
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import(Source, scope_txt, Ids),
    % Unify '2' with the number of elements in list 'Ids'.
    length(Ids, 2).

%  AC-PR36-009: zero-arg expressions (facts) round-trip as (Head)
% Define a clause for 'test': succeed when the following conditions hold.
test(zero_arg_round_trip, [setup(pr36_setup)]) :-
    % State a fact for 'pai atomese import' with the arguments listed below.
    interop_atomese_import([metta_expr(raining36, [])], scope_zero, _),
    % State a fact for 'pai atomese export' with the arguments listed below.
    interop_atomese_export(scope_zero, _, Lines),
    % Check that 'Lines' is unifiable with '['(raining36)']'.
    Lines = ['(raining36)'].

% Execute the compile-time directive: end_tests(pr36).
:- end_tests(pr36).
