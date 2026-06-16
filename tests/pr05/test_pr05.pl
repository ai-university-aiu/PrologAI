/*  PrologAI — PR 5 Scopes and Zones Acceptance Tests

    AC-PR05-001: node_fact in scope_alice NOT found in scope_bob scan.
    AC-PR05-002: scope_open with invalid zone throws.
    AC-PR05-003: scope_seal makes a scope read-only.
    AC-PR05-004: scope_merge copies node_facts from possible to present.
    AC-PR05-005: present_zone → possible_zone merge is blocked.
    AC-PR05-006: scope_scan returns node_facts only from the named scope.
    AC-PR05-007: all nine zone types are valid.
    AC-PR05-008: scope_activate sets the current scope.
    AC-PR05-009: scope_inscribe returns a nonzero Id.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'scopes' library so its predicates are available here.
:- use_module(library(scopes)).

% Execute the compile-time directive: begin_tests(pr05,.
:- begin_tests(pr05,
    % Continue the multi-line expression started above.
    [ setup(pr05_setup),
      % Continue the multi-line expression started above.
      cleanup(pr05_cleanup)
    % Close the expression opened above.
    ]).

% Execute: pr05_setup :-.
pr05_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr05', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr05_nexus, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr05_cleanup :-.
pr05_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr05_nexus, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(scope_isolation) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(scope_alice, present_zone),
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(scope_bob, present_zone),
    % State a fact for 'scope inscribe' with the arguments listed below.
    scope_inscribe(scope_alice, percept, [apple], [visible], Id),
    % State a fact for 'scope scan' with the arguments listed below.
    scope_scan(scope_bob, node_fact(percept, [apple], [visible]), 10, [], Rs),
    % Succeed only if 'member(_-Id, Rs' cannot be proved (negation as failure).
    \+ member(_-Id, Rs),
    % Succeed only if 'member(Id-_, Rs' cannot be proved (negation as failure).
    \+ member(Id-_, Rs).

% State a fact for 'test' with the arguments listed below.
test(invalid_zone_throws,
     % Continue the multi-line expression started above.
     [throws(error(domain_error(zone, nonexistent_zone), _))]) :-
    % State the fact: scope open(bad_scope, nonexistent_zone).
    scope_open(bad_scope, nonexistent_zone).

% State a fact for 'test' with the arguments listed below.
test(sealed_scope_blocks_inscribe,
     % Continue the multi-line expression started above.
     [throws(error(permission_error(inscribe, sealed_scope, seal_test), _))]) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(seal_test, present_zone),
    % State a fact for 'scope seal' with the arguments listed below.
    scope_seal(seal_test),
    % State the fact: scope inscribe(seal_test, percept, [x], [], _).
    scope_inscribe(seal_test, percept, [x], [], _).

% Define a clause for 'test': succeed when the following conditions hold.
test(scope_merge_possible_to_present) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(src_scope, possible_zone),
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(dst_scope, present_zone),
    % State a fact for 'scope inscribe' with the arguments listed below.
    scope_inscribe(src_scope, percept, [merged_item], [], _OrigId),
    % State a fact for 'scope merge' with the arguments listed below.
    scope_merge(src_scope, dst_scope, []),
    % State a fact for 'scope scan' with the arguments listed below.
    scope_scan(dst_scope, node_fact(percept, [merged_item], []), 5, [], Rs),
    % Check that 'Rs' is not unifiable with '[]'.
    Rs \= [].

% State a fact for 'test' with the arguments listed below.
test(merge_present_to_possible_blocked,
     % Continue the multi-line expression started above.
     [throws(error(permission_error(merge, present_to_possible, _), _))]) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(from_present, present_zone),
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(to_possible, possible_zone),
    % State the fact: scope merge(from_present, to_possible, []).
    scope_merge(from_present, to_possible, []).

% Define a clause for 'test': succeed when the following conditions hold.
test(scope_scan_isolation) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(scan_a, present_zone),
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(scan_b, present_zone),
    % State a fact for 'scope inscribe' with the arguments listed below.
    scope_inscribe(scan_a, concept, [unique_to_a], [], Id),
    % State a fact for 'scope scan' with the arguments listed below.
    scope_scan(scan_b, node_fact(concept, [unique_to_a], []), 10, [], Rs),
    % Succeed only if 'member(_-Id, Rs' cannot be proved (negation as failure).
    \+ member(_-Id, Rs).

% Define a clause for 'test': succeed when the following conditions hold.
test(all_nine_zones) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(member(Z, [present_zone, possible_zone, past_zone,
                      % Continue the multi-line expression started above.
                      desired_zone, expected_zone, imagined_zone,
                      % Continue the multi-line expression started above.
                      recalled_zone, attained_zone, confirmed_zone]),
           % Continue the multi-line expression started above.
           valid_zone(Z)).

% Define a clause for 'test': succeed when the following conditions hold.
test(scope_activate_sets_current) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(active_scope, present_zone),
    % State a fact for 'scope activate' with the arguments listed below.
    scope_activate(active_scope),
    % State the fact: current scope(active_scope).
    current_scope(active_scope).

% Define a clause for 'test': succeed when the following conditions hold.
test(scope_inscribe_returns_id) :-
    % State a fact for 'scope open' with the arguments listed below.
    scope_open(id_test, present_zone),
    % State a fact for 'scope inscribe' with the arguments listed below.
    scope_inscribe(id_test, rel, [a], [b], Id),
    % State a fact for 'integer' with the arguments listed below.
    integer(Id),
    % Check that 'Id' is greater than '0'.
    Id > 0.

% Execute the compile-time directive: end_tests(pr05).
:- end_tests(pr05).
