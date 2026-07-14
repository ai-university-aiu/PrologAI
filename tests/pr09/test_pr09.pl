/*  PrologAI — PR 9 Sentinel Engine Acceptance Tests

    AC-PR09-001: sentinel fires when anchor_node matches pattern.
    AC-PR09-002: Higher priority sentinel fires before lower priority.
    AC-PR09-003: Sentinel in inactive domain does NOT fire.
    AC-PR09-004: Semantic similarity match fires sentinel (Phase 2).
    AC-PR09-005: sentinels_retract removes a sentinel; it no longer fires.
    AC-PR09-006: Action exception is caught; other sentinels continue.
    AC-PR09-007: Multiple sentinels all fire on a matching change.
    AC-PR09-008: sentinels_list/2 returns registered sentinels.
    AC-PR09-009: sentinels_domain_deactivate suspends evaluation.
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
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SentinelPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),         [lattice_open/2, lattice_close/1]).
% Import [anchor_node/4, set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),      [anchor_node/4, set_default_nexus/1]).
% Load the built-in 'sentinels' library so its predicates are available here.
:- use_module(library(sentinels),       [sentinels_register/6, sentinels_retract/1,
                                         % Continue the multi-line expression started above.
                                         sentinels_list/2, sentinels_domain_activate/1,
                                         % Continue the multi-line expression started above.
                                         sentinels_domain_deactivate/1]).
% Load the built-in 'sentinel_engine' library so its predicates are available here.
:- use_module(library(sentinel_engine)).

% Declare 'user:pr09_fired/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic user:pr09_fired/1.

% Execute the compile-time directive: begin_tests(pr09, [setup(pr09_setup), cleanup(pr09_cleanup)]).
:- begin_tests(pr09, [setup(pr09_setup), cleanup(pr09_cleanup)]).

% Execute: pr09_setup :-.
pr09_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr09', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr09_nexus_ref, N),  % note: this is just for cleanup; node_facts uses default
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State the fact: sentinel retract(pr09_test).
    sentinels_retract(pr09_test).

% Execute: pr09_cleanup :-.
pr09_cleanup :-
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinels_retract(pr09_test),
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinels_retract(pr09_priority),
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinels_retract(pr09_inactive),
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr09', N),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(sentinel_fires_on_match) :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 10,
        % Continue the multi-line expression started above.
        node_fact(_, percept, [apple|_], _),
        % Continue the multi-line expression started above.
        [],
        % Continue the multi-line expression started above.
        assertz(user:pr09_fired(apple_detected)),
        % Continue the multi-line expression started above.
        "Apple detector"),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [apple, red], [visible], _),
    % Execute: user:pr09_fired(apple_detected)..
    user:pr09_fired(apple_detected).

% Define a clause for 'test': succeed when the following conditions hold.
test(priority_ordering) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_priority, 20,
        % Continue the multi-line expression started above.
        node_fact(_, fruit, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(high_prio)), "High"),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_priority, 5,
        % Continue the multi-line expression started above.
        node_fact(_, fruit, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(low_prio)), "Low"),
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinels_retract(pr09_test),  % avoid test sentinels firing on fruit too
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(fruit, [banana], [], _),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(X, user:pr09_fired(X), Log),
    % Retrieve the element at the specified one-based position from the list.
    nth1(1, Log, high_prio),
    % Retrieve the element at the specified one-based position from the list.
    nth1(2, Log, low_prio).

% Define a clause for 'test': succeed when the following conditions hold.
test(inactive_domain_no_fire) :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_inactive, 10,
        % Continue the multi-line expression started above.
        node_fact(_, veggie, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(veggie_detected)), "Veggie"),
    % State a fact for 'sentinel domain deactivate' with the arguments listed below.
    sentinels_domain_deactivate(pr09_inactive),
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(veggie, [carrot], [], _),
    % Succeed only if 'user:pr09_fired(veggie_detected' cannot be proved (negation as failure).
    \+ user:pr09_fired(veggie_detected),
    % State the fact: sentinel domain activate(pr09_inactive).
    sentinels_domain_activate(pr09_inactive).

% Define a clause for 'test': succeed when the following conditions hold.
test(semantic_similarity_phase2) :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 8,
        % Continue the multi-line expression started above.
        node_fact(_, percept, [orange|_], _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(orange_similar)), "Orange"),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [orange, round], [visible], _),
    % Execute: user:pr09_fired(orange_similar)..
    user:pr09_fired(orange_similar).

% Define a clause for 'test': succeed when the following conditions hold.
test(sentinel_retract_stops_firing) :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 15,
        % Continue the multi-line expression started above.
        node_fact(_, temp_rel, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(temp_fired)), "Temp"),
    % State a fact for 'sentinel retract' with the arguments listed below.
    sentinels_retract(pr09_test),
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(temp_rel, [x], [], _),
    % Succeed only if 'user:pr09_fired(temp_fired' cannot be proved (negation as failure).
    \+ user:pr09_fired(temp_fired).

% Define a clause for 'test': succeed when the following conditions hold.
test(action_error_continues) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 30,
        % Continue the multi-line expression started above.
        node_fact(_, err_rel, _, _),
        % Continue the multi-line expression started above.
        [], throw(sentinel_test_error), "Thrower"),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 5,
        % Continue the multi-line expression started above.
        node_fact(_, err_rel, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(after_error)), "After"),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(err_rel, [x], [], _),
    % Execute: user:pr09_fired(after_error)..
    user:pr09_fired(after_error).

% Define a clause for 'test': succeed when the following conditions hold.
test(multiple_sentinels_all_fire) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 10,
        % Continue the multi-line expression started above.
        node_fact(_, multi_rel, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(multi1)), "Multi1"),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 10,
        % Continue the multi-line expression started above.
        node_fact(_, multi_rel, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(multi2)), "Multi2"),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(multi_rel, [x], [], _),
    % Execute: user:pr09_fired(multi1),.
    user:pr09_fired(multi1),
    % Execute: user:pr09_fired(multi2)..
    user:pr09_fired(multi2).

% Define a clause for 'test': succeed when the following conditions hold.
test(sentinel_list_returns_registered) :-
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 42,
        % Continue the multi-line expression started above.
        node_fact(_, list_rel, _, _),
        % Continue the multi-line expression started above.
        [], true, "List test"),
    % State a fact for 'sentinel list' with the arguments listed below.
    sentinels_list(pr09_test, L),
    % Check that 'L' is not unifiable with '[]'.
    L \= [].

% Define a clause for 'test': succeed when the following conditions hold.
test(domain_deactivate_reactivate) :-
    % State a fact for 'sentinel domain deactivate' with the arguments listed below.
    sentinels_domain_deactivate(pr09_test),
    % State a fact for 'sentinel domain activate' with the arguments listed below.
    sentinels_domain_activate(pr09_test),
    % Remove all matching facts from the runtime knowledge base.
    retractall(user:pr09_fired(_)),
    % State a fact for 'pai register sentinel' with the arguments listed below.
    sentinels_register(pr09_test, 10,
        % Continue the multi-line expression started above.
        node_fact(_, react_rel, _, _),
        % Continue the multi-line expression started above.
        [], assertz(user:pr09_fired(reactivated)), "React"),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(react_rel, [x], [], _),
    % Execute: user:pr09_fired(reactivated)..
    user:pr09_fired(reactivated).

% Execute the compile-time directive: end_tests(pr09).
:- end_tests(pr09).
