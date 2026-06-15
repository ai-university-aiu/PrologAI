/*  PrologAI — PR 15 Incremental Tabling Truth Maintenance Acceptance Tests

    AC-PR15-001: Given a tabled taxonomy closure over instance_of node_facts,
                 when a type link is pruned, a subsequent closure query
                 reflects the removal without manual cache invalidation.
    AC-PR15-002: Minimal recomputation: only the affected derivation changes.
    AC-PR15-003: declare_derived/1 is idempotent.
    AC-PR15-004: pai_derived/3 returns results consistent with current Lattice.
    AC-PR15-005: pai_derived/3 updates automatically after anchor_node.
    AC-PR15-006: pai_derived/3 updates automatically after prune_node.
    AC-PR15-007: pai_tabling_stats/1 reports pai_derived as tabled.
    AC-PR15-008: surface_contradictions/0 inscribes contradiction node_facts.
    AC-PR15-009: taxonomy_closure/2 computes transitive closure correctly.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/tabling/prolog'],        TablingPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, TablingPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    lattice_node_fact/5]).
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4,
                                    prune_node/1]).
:- use_module(library(lattice_tabling), [declare_derived/1, pai_derived/3,
                                         surface_contradictions/0,
                                         pai_tabling_stats/1,
                                         taxonomy_closure/2]).

:- begin_tests(pr15, [setup(pr15_setup), cleanup(pr15_cleanup)]).

pr15_setup :-
    lattice_open('locus://localhost/pr15', N),
    nb_setval(pr15_nexus_ref, N),
    set_default_nexus(N).

pr15_cleanup :-
    nb_getval(pr15_nexus_ref, N),
    lattice_close(N).

%  AC-PR15-001: taxonomy closure reflects pruned type link
test(taxonomy_closure_reflects_prune) :-
    % Establish: sparrow instance_of bird
    anchor_node(instance_of, [sparrow, bird], [], _),
    % Verify closure holds
    taxonomy_closure(sparrow, bird),
    % Find the node_fact Id for this link
    lattice:lattice_node_fact(_, Id, instance_of, [sparrow, bird], []),
    % Prune the link
    prune_node(Id),
    % After pruning, closure should NOT hold (no manual invalidation needed)
    \+ taxonomy_closure(sparrow, bird).

%  AC-PR15-002: only dependent derivation changes
test(minimal_recomputation) :-
    % Add two independent instance_of facts
    anchor_node(instance_of, [eagle, bird], [], _),
    anchor_node(instance_of, [salmon, fish], [], _),
    % Both close correctly
    taxonomy_closure(eagle, bird),
    taxonomy_closure(salmon, fish),
    % Prune eagle link
    lattice:lattice_node_fact(_, EId, instance_of, [eagle, bird], []),
    prune_node(EId),
    % Eagle closure gone, salmon closure intact (independent)
    \+ taxonomy_closure(eagle, bird),
    taxonomy_closure(salmon, fish).

%  AC-PR15-003: declare_derived idempotent
test(declare_derived_idempotent) :-
    declare_derived(my_relation),
    declare_derived(my_relation),   % second call: no error, no duplicate
    aggregate_all(count,
                  lattice_tabling:derived_relation_registered(my_relation),
                  N),
    N =:= 1.

%  AC-PR15-004: pai_derived returns Lattice facts
test(pai_derived_returns_lattice_facts) :-
    anchor_node(taxonomy_test, [value_a], [ref_b], _),
    once(pai_derived(taxonomy_test, [value_a], [ref_b])).

%  AC-PR15-005: pai_derived updates after anchor_node
test(pai_derived_updates_after_anchor) :-
    % Before anchor
    \+ pai_derived(new_rel, [new_val], []),
    anchor_node(new_rel, [new_val], [], _),
    % After anchor — tabled result should now hold
    once(pai_derived(new_rel, [new_val], [])).

%  AC-PR15-006: pai_derived updates after prune_node
test(pai_derived_updates_after_prune) :-
    anchor_node(prunable_rel, [px], [], _),
    once(pai_derived(prunable_rel, [px], [])),
    % Prune
    lattice:lattice_node_fact(_, PId, prunable_rel, [px], []),
    prune_node(PId),
    % After pruning, pai_derived should no longer hold
    \+ pai_derived(prunable_rel, [px], []).

%  AC-PR15-007: tabling stats
test(tabling_stats_pai_derived_tabled) :-
    pai_tabling_stats(Stats),
    get_dict(pai_derived_tabled, Stats, Tabled),
    Tabled == true.

%  AC-PR15-008: surface_contradictions inscribes contradiction node_facts
test(surface_contradictions_inscribes) :-
    % Record a contradiction_candidate that no longer holds
    anchor_node(contradiction_candidate, [x_inst, x_class], [], _),
    % x_inst is NOT an instance_of x_class (no such link in Lattice)
    % So surface_contradictions should inscribe a contradiction
    surface_contradictions,
    once(lattice:lattice_node_fact(_, _, contradiction, [x_inst, x_class|_], [])).

%  AC-PR15-009: transitive taxonomy closure
test(taxonomy_transitive_closure) :-
    anchor_node(instance_of, [poodle, dog], [], _),
    anchor_node(instance_of, [dog, mammal], [], _),
    taxonomy_closure(poodle, dog),
    taxonomy_closure(dog, mammal),
    % Transitive: poodle should close to mammal via dog
    taxonomy_closure(poodle, mammal).

:- end_tests(pr15).
