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
   atomic_list_concat([ProjectRoot, '/packs/tabling/prolog'],        TablingPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, TablingPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    % Continue the multi-line expression started above.
                                    lattice_node_fact/5]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4,
                                    % Continue the multi-line expression started above.
                                    prune_node/1]).
% Load the built-in 'lattice_tabling' library so its predicates are available here.
:- use_module(library(lattice_tabling), [declare_derived/1, pai_derived/3,
                                         % Supply 'surface_contradictions/0' as the next argument to the expression above.
                                         surface_contradictions/0,
                                         % Supply 'pai_tabling_stats/1' as the next argument to the expression above.
                                         pai_tabling_stats/1,
                                         % Continue the multi-line expression started above.
                                         taxonomy_closure/2]).

% Execute the compile-time directive: begin_tests(pr15, [setup(pr15_setup), cleanup(pr15_cleanup)]).
:- begin_tests(pr15, [setup(pr15_setup), cleanup(pr15_cleanup)]).

% Execute: pr15_setup :-.
pr15_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr15', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr15_nexus_ref, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr15_cleanup :-.
pr15_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr15_nexus_ref, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR15-001: taxonomy closure reflects pruned type link
% Define a clause for 'test': succeed when the following conditions hold.
test(taxonomy_closure_reflects_prune) :-
    % Establish: sparrow instance_of bird
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(instance_of, [sparrow, bird], [], _),
    % Verify closure holds
    % State a fact for 'taxonomy closure' with the arguments listed below.
    taxonomy_closure(sparrow, bird),
    % Find the node_fact Id for this link
    % Execute: lattice:lattice_node_fact(_, Id, instance_of, [sparrow, bird], []),.
    lattice:lattice_node_fact(_, Id, instance_of, [sparrow, bird], []),
    % Prune the link
    % State a fact for 'prune node' with the arguments listed below.
    prune_node(Id),
    % After pruning, closure should NOT hold (no manual invalidation needed)
    % Succeed only if 'taxonomy_closure(sparrow, bird' cannot be proved (negation as failure).
    \+ taxonomy_closure(sparrow, bird).

%  AC-PR15-002: only dependent derivation changes
% Define a clause for 'test': succeed when the following conditions hold.
test(minimal_recomputation) :-
    % Add two independent instance_of facts
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(instance_of, [eagle, bird], [], _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(instance_of, [salmon, fish], [], _),
    % Both close correctly
    % State a fact for 'taxonomy closure' with the arguments listed below.
    taxonomy_closure(eagle, bird),
    % State a fact for 'taxonomy closure' with the arguments listed below.
    taxonomy_closure(salmon, fish),
    % Prune eagle link
    % Execute: lattice:lattice_node_fact(_, EId, instance_of, [eagle, bird], []),.
    lattice:lattice_node_fact(_, EId, instance_of, [eagle, bird], []),
    % State a fact for 'prune node' with the arguments listed below.
    prune_node(EId),
    % Eagle closure gone, salmon closure intact (independent)
    % Succeed only if 'taxonomy_closure(eagle, bird' cannot be proved (negation as failure).
    \+ taxonomy_closure(eagle, bird),
    % State the fact: taxonomy closure(salmon, fish).
    taxonomy_closure(salmon, fish).

%  AC-PR15-003: declare_derived idempotent
% Define a clause for 'test': succeed when the following conditions hold.
test(declare_derived_idempotent) :-
    % State a fact for 'declare derived' with the arguments listed below.
    declare_derived(my_relation),
    % State a fact for 'declare derived' with the arguments listed below.
    declare_derived(my_relation),   % second call: no error, no duplicate
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  lattice_tabling:derived_relation_registered(my_relation),
                  % Supply 'N' as the next argument to the expression above.
                  N),
    % Check that 'N' is numerically equal to '1'.
    N =:= 1.

%  AC-PR15-004: pai_derived returns Lattice facts
% Define a clause for 'test': succeed when the following conditions hold.
test(pai_derived_returns_lattice_facts) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(taxonomy_test, [value_a], [ref_b], _),
    % State the fact: once(pai_derived(taxonomy_test, [value_a], [ref_b])).
    once(pai_derived(taxonomy_test, [value_a], [ref_b])).

%  AC-PR15-005: pai_derived updates after anchor_node
% Define a clause for 'test': succeed when the following conditions hold.
test(pai_derived_updates_after_anchor) :-
    % Before anchor
    % Succeed only if 'pai_derived(new_rel, [new_val], []' cannot be proved (negation as failure).
    \+ pai_derived(new_rel, [new_val], []),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(new_rel, [new_val], [], _),
    % After anchor — tabled result should now hold
    % State the fact: once(pai_derived(new_rel, [new_val], [])).
    once(pai_derived(new_rel, [new_val], [])).

%  AC-PR15-006: pai_derived updates after prune_node
% Define a clause for 'test': succeed when the following conditions hold.
test(pai_derived_updates_after_prune) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(prunable_rel, [px], [], _),
    % State a fact for 'once' with the arguments listed below.
    once(pai_derived(prunable_rel, [px], [])),
    % Prune
    % Execute: lattice:lattice_node_fact(_, PId, prunable_rel, [px], []),.
    lattice:lattice_node_fact(_, PId, prunable_rel, [px], []),
    % State a fact for 'prune node' with the arguments listed below.
    prune_node(PId),
    % After pruning, pai_derived should no longer hold
    % Succeed only if 'pai_derived(prunable_rel, [px], []' cannot be proved (negation as failure).
    \+ pai_derived(prunable_rel, [px], []).

%  AC-PR15-007: tabling stats
% Define a clause for 'test': succeed when the following conditions hold.
test(tabling_stats_pai_derived_tabled) :-
    % State a fact for 'pai tabling stats' with the arguments listed below.
    pai_tabling_stats(Stats),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(pai_derived_tabled, Stats, Tabled),
    % Check that 'Tabled' is structurally identical to 'true'.
    Tabled == true.

%  AC-PR15-008: surface_contradictions inscribes contradiction node_facts
% Define a clause for 'test': succeed when the following conditions hold.
test(surface_contradictions_inscribes) :-
    % Record a contradiction_candidate that no longer holds
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(contradiction_candidate, [x_inst, x_class], [], _),
    % x_inst is NOT an instance_of x_class (no such link in Lattice)
    % So surface_contradictions should inscribe a contradiction
    % Call the goal 'surface_contradictions'.
    surface_contradictions,
    % State the fact: once(lattice:lattice_node_fact(_, _, contradiction, [x_inst, x_class|_], [])).
    once(lattice:lattice_node_fact(_, _, contradiction, [x_inst, x_class|_], [])).

%  AC-PR15-009: transitive taxonomy closure
% Define a clause for 'test': succeed when the following conditions hold.
test(taxonomy_transitive_closure) :-
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(instance_of, [poodle, dog], [], _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(instance_of, [dog, mammal], [], _),
    % State a fact for 'taxonomy closure' with the arguments listed below.
    taxonomy_closure(poodle, dog),
    % State a fact for 'taxonomy closure' with the arguments listed below.
    taxonomy_closure(dog, mammal),
    % Transitive: poodle should close to mammal via dog
    % State the fact: taxonomy closure(poodle, mammal).
    taxonomy_closure(poodle, mammal).

% Execute the compile-time directive: end_tests(pr15).
:- end_tests(pr15).
