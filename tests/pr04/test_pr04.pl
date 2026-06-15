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

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),      [member/2, numlist/3]).
:- use_module(library(apply),      [maplist/2]).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    lattice_node_fact/5]).
:- use_module(library(node_facts), [anchor_node/4, prune_node/1,
                                    traverse_nexus/4, kindle_node/1,
                                    quench_node/1, live_node_facts/2,
                                    set_default_nexus/1,
                                    node_activation/3]).

:- begin_tests(pr04,
    [ setup(pr04_setup),
      cleanup(pr04_cleanup)
    ]).

pr04_setup :-
    lattice_open('locus://localhost/pr04', N),
    nb_setval(pr04_nexus, N),
    set_default_nexus(N).

pr04_cleanup :-
    nb_getval(pr04_nexus, N),
    lattice_close(N).

test(anchor_returns_nonzero_id) :-
    anchor_node(percept, [apple, red], [visible], Id),
    integer(Id),
    Id \== 0.

test(anchor_retrievable, [setup(anchor_node(percept, [pear, green], [visible], Id)),
                           cleanup(prune_node(Id))]) :-
    nb_getval(pr04_nexus, N),
    traverse_nexus(N, node_fact(percept, [pear, green], [visible]), 5, Rs),
    Rs \= [].

test(prune_removes) :-
    anchor_node(percept, [to_prune], [], Id),
    prune_node(Id),
    nb_getval(pr04_nexus, N),
    traverse_nexus(N, node_fact(percept, [to_prune], []), 5, Rs),
    \+ member(Id-_, Rs),
    \+ member(_-Id, Rs).

test(kindle_updates_activation) :-
    anchor_node(percept, [kindle_me], [], Id),
    sleep(0.01),
    kindle_node(Id),
    node_activation(Id, T, _),
    get_time(Now),
    Diff is Now - T,
    Diff < 1.0.

test(quench_removes_from_live) :-
    anchor_node(percept, [quench_me], [], Id),
    quench_node(Id),
    nb_getval(pr04_nexus, N),
    live_node_facts(N, Live),
    \+ member(Id, Live).

test(live_node_facts_nonempty) :-
    anchor_node(percept, [live_test], [], _Id),
    nb_getval(pr04_nexus, N),
    live_node_facts(N, Live),
    Live \= [].

test(id_positive) :-
    anchor_node(relation, [arg], [ref], Id),
    Id > 0.

test(unique_ids) :-
    anchor_node(rel, [a], [], Id1),
    anchor_node(rel, [b], [], Id2),
    Id1 \== Id2.

test(traverse_perf_100, [true(Elapsed < 0.1)]) :-
    nb_getval(pr04_nexus, N),
    numlist(1, 100, Ns),
    maplist([I]>>(atom_concat(perf_, I, A), anchor_node(perf, [A], [], _)), Ns),
    get_time(T0),
    traverse_nexus(N, node_fact(perf, _, _), 10, _),
    get_time(T1),
    Elapsed is T1 - T0.

:- end_tests(pr04).
