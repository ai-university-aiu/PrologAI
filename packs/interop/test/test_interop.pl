/*  PrologAI — interop pack in-pack PLUnit suite

    Behavioural tests for the Hyperon Interoperability Bridge.
    Exercises the three exported predicates against a live lattice nexus:
        interop_atomese_import/3  — inscribe MeTTa/Atomese expressions as node-facts
        interop_atomese_export/3  — serialize scoped node-facts back to MeTTa lines
        interop_space_mount/3     — record a named MeTTa space binding (idempotent)

    Run (from the repository root, with every pack's prolog dir on the library path):
      LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
      swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/interop/test/test_interop.pl
*/

% Declare this file as the test_interop module with no exported predicates.
:- module(test_interop, []).

% Load the PLUnit test framework so begin_tests/test/end_tests are available.
:- use_module(library(plunit)).
% Load the interop pack under test, importing its three public predicates.
:- use_module(library(interop), [
    % The Atomese/MeTTa import predicate.
    interop_atomese_import/3,
    % The Atomese/MeTTa export predicate.
    interop_atomese_export/3,
    % The MeTTa space-mount predicate.
    interop_space_mount/3
% Close the import list opened above.
]).
% Load the lattice so a nexus can be opened, closed, and its node-facts inspected.
:- use_module(library(lattice), [lattice_open/2, lattice_close/1, lattice_node_fact/5]).
% Import set_default_nexus so imported facts anchor to our test nexus.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Import list membership check used by the scope-tag assertion.
:- use_module(library(lists), [memberchk/2]).
% Import aggregate_all for counting mounted-space bindings.
:- use_module(library(aggregate), [aggregate_all/3]).

% Open a fresh lattice nexus and make it the anchoring target for imports.
setup_interop :-
    % Open a nexus at a test-specific locus.
    lattice_open('locus://localhost/test_interop', N),
    % Remember the nexus reference so cleanup can close it.
    nb_setval(test_interop_nexus, N),
    % Route all anchored node-facts to this nexus.
    set_default_nexus(N),
    % Clear any leftover mounted-space facts from a prior run.
    retractall(interop:mounted_space(_, _, _)).

% Tear down the nexus opened in setup and clear asserted space bindings.
cleanup_interop :-
    % Recover the nexus reference saved during setup.
    nb_getval(test_interop_nexus, N),
    % Clear mounted-space facts asserted during the tests.
    retractall(interop:mounted_space(_, _, _)),
    % Close the test nexus.
    lattice_close(N).

% Open the interop test block, opening one nexus for the whole suite and closing it after.
:- begin_tests(interop, [setup(setup_interop), cleanup(cleanup_interop)]).

% Importing three expressions and re-exporting them yields three ground ids and three lines.
test(import_export_round_trip) :-
    % Build three distinct Atomese expressions.
    Exprs = [metta_expr(type_of, [battery, number]),
             % A rule expression relating two symbols.
             metta_expr(rule, [raining, wet_ground]),
             % A zero-argument fact expression.
             metta_expr(fact, [is_cold])],
    % Import the expressions under a dedicated scope, collecting their ids.
    interop_atomese_import(Exprs, scope_round_trip, Ids),
    % There must be exactly three imported ids.
    assertion(length(Ids, 3)),
    % Every returned id must be fully instantiated.
    assertion(ground(Ids)),
    % Export everything tagged with that scope back to MeTTa lines.
    interop_atomese_export(scope_round_trip, _, Lines),
    % The export must produce one line per imported expression.
    assertion(length(Lines, 3)).

% Importing a list of metta_expr/2 terms returns one ground id per expression.
test(import_from_list_returns_ground_ids) :-
    % Two agent-declaration expressions.
    Exprs = [metta_expr(agent, [alice]), metta_expr(agent, [bob])],
    % Import both under a list-specific scope.
    interop_atomese_import(Exprs, scope_list, Ids),
    % Two expressions must yield two ids.
    assertion(length(Ids, 2)),
    % Both ids must be ground node-fact identifiers.
    assertion(ground(Ids)).

% An imported node-fact carries the atomese_scope tag in its Referents.
test(import_tags_atomese_scope) :-
    % Import a single coloured-object expression under a tag scope.
    interop_atomese_import([metta_expr(color, [red])], scope_tag, [Id]),
    % Locate the anchored node-fact by its id and read back its content and referents.
    lattice_node_fact(_, Id, color, [red], Refs),
    % The referents must include the atomese_scope tag for this scope.
    assertion(memberchk(atomese_scope(scope_tag), Refs)).

% Export serializes a head and its arguments into the canonical (head arg1 arg2) form.
test(export_serializes_head_and_args) :-
    % Import a two-argument rule expression under a serialization scope.
    interop_atomese_import([metta_expr(rule, [rain, wet])], scope_serialize, _),
    % Export that scope back to MeTTa source lines.
    interop_atomese_export(scope_serialize, _, Lines),
    % The single line must reproduce head and arguments exactly.
    assertion(Lines == ['(rule rain wet)']).

% A zero-argument expression round-trips as a bare (head) line.
test(zero_arg_expression_round_trips) :-
    % Import a fact with no arguments under a zero-arg scope.
    interop_atomese_import([metta_expr(raining, [])], scope_zero, _),
    % Export that scope back to MeTTa source lines.
    interop_atomese_export(scope_zero, _, Lines),
    % The line must be the head alone, wrapped in parentheses.
    assertion(Lines == ['(raining)']).

% Importing MeTTa source text (one expression per line) parses into one id per line.
test(import_from_metta_source_text) :-
    % A two-line MeTTa source atom.
    Source = '(agent robot)\n(knows robot weather)',
    % Import the source text under a text scope.
    interop_atomese_import(Source, scope_text, Ids),
    % Two source lines must yield two imported ids.
    assertion(length(Ids, 2)).

% Distinct scopes stay isolated — one scope's export never leaks into another's.
test(scopes_are_isolated) :-
    % Import one fact into scope A.
    interop_atomese_import([metta_expr(marker, [alpha])], scope_iso_a, _),
    % Import a different fact into scope B.
    interop_atomese_import([metta_expr(marker, [beta])], scope_iso_b, _),
    % Export scope A on its own.
    interop_atomese_export(scope_iso_a, _, LinesA),
    % Export scope B on its own.
    interop_atomese_export(scope_iso_b, _, LinesB),
    % Scope A must expose exactly its single line.
    assertion(LinesA == ['(marker alpha)']),
    % Scope B must expose exactly its single line.
    assertion(LinesB == ['(marker beta)']).

% Mounting the same named space twice records exactly one binding (idempotent).
test(space_mount_is_idempotent) :-
    % Recover the nexus opened for the suite.
    nb_getval(test_interop_nexus, N),
    % Mount a named MeTTa space in read mode.
    interop_space_mount(metta_space_test, N, [access(read)]),
    % Mount the identical space a second time.
    interop_space_mount(metta_space_test, N, [access(read)]),
    % Count how many bindings exist for that space id.
    aggregate_all(count, interop:mounted_space(metta_space_test, _, _), Count),
    % The repeated mount must not create a duplicate binding.
    assertion(Count =:= 1).

% Close the interop test block.
:- end_tests(interop).
