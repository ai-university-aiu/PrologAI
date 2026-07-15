/*  In-pack PLUnit suite for the 'tabling' pack (module lattice_tabling).

    Exercises the incremental-tabling truth-maintenance layer over the Lattice:
    declaring derived relations, querying the tabled node_fact interface,
    transitive taxonomy closure, tabling statistics, and contradiction
    surfacing. Each test opens its own Lattice nexus so the tabled derivations
    reflect exactly the base facts asserted in that test.

    Note: the pack's module and file are named lattice_tabling (SWI-Prolog
    ships its own library(tabling)), so this suite imports library(lattice_tabling).
    The base-store predicates come from library(node_facts) and library(lattice),
    both of which live under packs/lattice/prolog on the library path.
*/

% Declare this file as a payload-free test module named 'test_tabling'.
:- module(test_tabling, []).

% Load the PLUnit test framework so begin_tests/end_tests and test/1 are available.
:- use_module(library(plunit)).
% Import the Lattice open/close and base-fact lookup predicates used for setup.
:- use_module(library(lattice),        [lattice_open/2, lattice_close/1, lattice_node_fact/5]).
% Import the node_fact write helpers and default-nexus setter used for setup.
:- use_module(library(node_facts),     [set_default_nexus/1, anchor_node/4, prune_node/1]).
% Import the five exported predicates of the pack under test.
:- use_module(library(lattice_tabling), [declare_derived/1, tabling_derived/3,
                                         % Continue the multi-line import list.
                                         surface_contradictions/0,
                                         % Continue the multi-line import list.
                                         tabling_stats/1,
                                         % Continue the multi-line import list.
                                         taxonomy_closure/2]).

% Open the tabling test group, opening a fresh nexus before and closing it after.
:- begin_tests(tabling, [setup(tabling_test_setup), cleanup(tabling_test_cleanup)]).

% Setup: open a private Lattice nexus and make it the default target for writes.
tabling_test_setup :-
    % Open a nexus at a test-only locus and bind its reference to N.
    lattice_open('locus://localhost/test_tabling', N),
    % Stash the nexus reference so cleanup can close the same nexus.
    nb_setval(test_tabling_nexus_ref, N),
    % Route all node_fact writes in this suite to the freshly opened nexus.
    set_default_nexus(N).

% Cleanup: close the nexus that setup opened, releasing its store.
tabling_test_cleanup :-
    % Recover the nexus reference stashed during setup.
    nb_getval(test_tabling_nexus_ref, N),
    % Close that nexus.
    lattice_close(N).

% declare_derived/1 must be idempotent: registering the same relation twice keeps one entry.
test(declare_derived_is_idempotent) :-
    % Register a derived relation for the first time.
    declare_derived(sample_relation),
    % Register the very same relation again; this must not error or duplicate.
    declare_derived(sample_relation),
    % Count how many registry rows exist for that relation.
    aggregate_all(count,
                  % Look inside the pack module for the private registry fact.
                  lattice_tabling:derived_relation_registered(sample_relation),
                  % Bind the resulting count to Count.
                  Count),
    % Exactly one registry row must remain after two declarations.
    assertion(Count =:= 1).

% taxonomy_closure/2 must compute the transitive instance_of closure.
test(taxonomy_closure_is_transitive) :-
    % Assert that a poodle is an instance of dog.
    anchor_node(instance_of, [poodle, dog], [], _),
    % Assert that a dog is an instance of mammal.
    anchor_node(instance_of, [dog, mammal], [], _),
    % The direct poodle->dog link must close.
    assertion(taxonomy_closure(poodle, dog)),
    % The direct dog->mammal link must close.
    assertion(taxonomy_closure(dog, mammal)),
    % The transitive poodle->mammal link must close through dog.
    assertion(taxonomy_closure(poodle, mammal)),
    % An unrelated class must NOT close from poodle.
    assertion(\+ taxonomy_closure(poodle, fish)).

% tabling_derived/3 must surface a node_fact written to the current nexus.
test(tabling_derived_returns_lattice_facts) :-
    % Anchor a derived-relation fact carrying one referent.
    anchor_node(has_part, [engine], [car], _),
    % The tabled query must find that exact (relation, args, referents) triple once.
    assertion(once(tabling_derived(has_part, [engine], [car]))),
    % A relation never asserted must not be derivable.
    assertion(\+ tabling_derived(has_part, [wing], [car])).

% tabling_derived/3 must reflect a base-fact removal without manual cache invalidation.
test(tabling_derived_updates_after_prune) :-
    % Anchor a prunable derived fact.
    anchor_node(prunable_rel, [alpha], [], _),
    % Before pruning, the tabled query must succeed.
    assertion(once(tabling_derived(prunable_rel, [alpha], []))),
    % Locate the node_fact id for the fact just asserted.
    nb_getval(test_tabling_nexus_ref, Nexus),
    % Read back its id from the base store.
    lattice:lattice_node_fact(Nexus, Id, prunable_rel, [alpha], []),
    % Prune the base fact by id.
    prune_node(Id),
    % After pruning, incremental tabling must make the derived query fail.
    assertion(\+ tabling_derived(prunable_rel, [alpha], [])).

% tabling_stats/1 must report that the core tabled predicates are actually tabled.
test(tabling_stats_reports_tabled) :-
    % Compute the current tabling statistics dict.
    tabling_stats(Stats),
    % The derived-query predicate must be reported as tabled.
    assertion(get_dict(tabling_derived_tabled, Stats, true)),
    % The taxonomy-closure predicate must be reported as tabled.
    assertion(get_dict(taxonomy_closure_tabled, Stats, true)),
    % The declared-relations count must be a non-negative integer.
    get_dict(declared_relations, Stats, DCount),
    % Confirm the reported count is a non-negative integer.
    assertion((integer(DCount), DCount >= 0)).

% surface_contradictions/0 must inscribe a contradiction when a candidate no longer closes.
test(surface_contradictions_inscribes) :-
    % Record a contradiction candidate whose class link was never asserted.
    anchor_node(contradiction_candidate, [ghost_inst, ghost_class], [], _),
    % Run the scan; it should inscribe a contradiction for the broken link.
    surface_contradictions,
    % Recover the current nexus reference.
    nb_getval(test_tabling_nexus_ref, Nexus),
    % A contradiction node_fact naming the offending instance/class must now exist.
    assertion(once(lattice:lattice_node_fact(Nexus, _, contradiction,
                                             % The contradiction args begin with the instance and class.
                                             [ghost_inst, ghost_class|_], []))).

% Close the tabling test group.
:- end_tests(tabling).
