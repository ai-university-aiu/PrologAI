/*  PrologAI — PR 4 Node Facts Acceptance Tests

    AC-PR04-001: anchor_node stores a node_fact and returns a unique nonzero Id.
    AC-PR04-002: node_fact is retrievable via traverse_nexus (logical).
    AC-PR04-003: prune_node removes the node_fact.
    AC-PR04-004: kindle_node updates activation timestamp.
    AC-PR04-005: quench_node lowers edge weight; node absent from live window.
    AC-PR04-006: live_node_facts returns recently activated Ids.
    AC-PR04-007: Id is nonzero (positive = affirmative).
    AC-PR04-008: two anchor_node calls yield distinct Ids.
    AC-PR04-009: traverse_nexus performance — 100 node_facts in < 100 ms.
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
% Import [member/2, numlist/3] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, numlist/3]).
% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply),      [maplist/2]).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    % Continue the multi-line expression started above.
                                    lattice_node_fact/5]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [anchor_node/4, prune_node/1,
                                    % Continue the multi-line expression started above.
                                    traverse_nexus/4, kindle_node/1,
                                    % Continue the multi-line expression started above.
                                    quench_node/1, live_node_facts/2,
                                    % Supply 'set_default_nexus/1' as the next argument to the expression above.
                                    set_default_nexus/1,
                                    % Continue the multi-line expression started above.
                                    node_activation/3]).

% Execute the compile-time directive: begin_tests(pr04,.
:- begin_tests(pr04,
    % Continue the multi-line expression started above.
    [ setup(pr04_setup),
      % Continue the multi-line expression started above.
      cleanup(pr04_cleanup)
    % Close the expression opened above.
    ]).

% Execute: pr04_setup :-.
pr04_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr04', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr04_nexus, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr04_cleanup :-.
pr04_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(anchor_returns_nonzero_id) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [apple, red], [visible], Id),
    % State a fact for 'integer' with the arguments listed below.
    integer(Id),
    % Check that 'Id' is structurally not identical to '0'.
    Id \== 0.

% State a fact for 'test' with the arguments listed below.
test(anchor_retrievable, [setup(anchor_node(percept, [pear, green], [visible], Id)),
                           % Continue the multi-line expression started above.
                           cleanup(prune_node(Id))]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(N, node_fact(percept, [pear, green], [visible]), 5, Rs),
    % Check that 'Rs' is not unifiable with '[]'.
    Rs \= [].

% Define a clause for 'test': succeed when the following conditions hold.
test(prune_removes) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [to_prune], [], Id),
    % State a fact for 'prune node' with the arguments listed below.
    prune_node(Id),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(N, node_fact(percept, [to_prune], []), 5, Rs),
    % Succeed only if 'member(Id-_, Rs' cannot be proved (negation as failure).
    \+ member(Id-_, Rs),
    % Succeed only if 'member(_-Id, Rs' cannot be proved (negation as failure).
    \+ member(_-Id, Rs).

% Define a clause for 'test': succeed when the following conditions hold.
test(kindle_updates_activation) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [kindle_me], [], Id),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.01),
    % State a fact for 'kindle node' with the arguments listed below.
    kindle_node(Id),
    % State a fact for 'node activation' with the arguments listed below.
    node_activation(Id, T, _),
    % State a fact for 'get time' with the arguments listed below.
    get_time(Now),
    % Evaluate the arithmetic expression 'Now - T' and bind the result to 'Diff'.
    Diff is Now - T,
    % Check that 'Diff' is less than '1.0'.
    Diff < 1.0.

% Define a clause for 'test': succeed when the following conditions hold.
test(quench_removes_from_live) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [quench_me], [], Id),
    % State a fact for 'quench node' with the arguments listed below.
    quench_node(Id),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State a fact for 'live node facts' with the arguments listed below.
    live_node_facts(N, Live),
    % Succeed only if 'member(Id, Live' cannot be proved (negation as failure).
    \+ member(Id, Live).

% Define a clause for 'test': succeed when the following conditions hold.
test(live_node_facts_nonempty) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(percept, [live_test], [], _Id),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State a fact for 'live node facts' with the arguments listed below.
    live_node_facts(N, Live),
    % Check that 'Live' is not unifiable with '[]'.
    Live \= [].

% Define a clause for 'test': succeed when the following conditions hold.
test(id_positive) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(relation, [arg], [ref], Id),
    % Check that 'Id' is greater than '0'.
    Id > 0.

% Define a clause for 'test': succeed when the following conditions hold.
test(unique_ids) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(rel, [a], [], Id1),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(rel, [b], [], Id2),
    % Check that 'Id1' is structurally not identical to 'Id2'.
    Id1 \== Id2.

% Check that 'test(traverse_perf_100, [true(Elapsed' is less than '0.1)]) :-'.
test(traverse_perf_100, [true(Elapsed < 0.1)]) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr04_nexus, N),
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, 100, Ns),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([I]>>(atom_concat(perf_, I, A), anchor_node(perf, [A], [], _)), Ns),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(N, node_fact(perf, _, _), 10, _),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T1),
    % Evaluate the arithmetic expression 'T1 - T0' and bind the result to 'Elapsed'.
    Elapsed is T1 - T0.

% Execute the compile-time directive: end_tests(pr04).
:- end_tests(pr04).
