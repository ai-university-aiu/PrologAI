/*  Tests for node_facts fact-existence / assert-if-new  (dedup facility)

    Proves the lattice will not be cluttered with duplicate node-facts:
    anchor_node_unique reuses an existing node-fact, node_fact_find locates it, and
    node_facts_dedup cleans a store that already has duplicates.

    Run:
      swipl -p library=packs/lattice/prolog -p library=packs/vector_backend/prolog \
            -p library=packs/backend_prolog/prolog \
            -g run_tests -t halt packs/lattice/test/test_node_facts_dedup.pl
*/

% Load the modules under test.
:- use_module(library(lattice)).
:- use_module(library(node_facts)).
% Aggregation for counting.
:- use_module(library(aggregate), [aggregate_all/3]).

% report(+Id, +Goal): print PASS or FAIL for one criterion.
report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% count_fact(+Relation, +Args, -N): how many node-facts match this content.
count_fact(Relation, Args, N) :-
    aggregate_all(count, lattice_node_fact(_, _, Relation, Args, _), N).

% run_tests: exercise the assert-if-new node-fact facility.
run_tests :-
    format("~n=== node_facts — fact existence / assert-if-new ===~n~n", []),
    % Open a nexus and make it the anchoring target.
    lattice_open('locus://test/dedup', N),
    set_default_nexus(N),

    % AC-NF-001: the first unique anchor creates the node-fact.
    report('AC-NF-001',
        ( anchor_node_unique(likes, [alice, tea], [], Id1), ground(Id1) )),

    % AC-NF-002: a second identical anchor returns the SAME id and adds nothing.
    report('AC-NF-002',
        ( anchor_node_unique(likes, [alice, tea], [], Id2),
          node_fact_find(likes, [alice, tea], [], Id0),
          Id2 == Id0,
          count_fact(likes, [alice, tea], 1) )),

    % AC-NF-003: a genuinely different node-fact still anchors.
    report('AC-NF-003',
        ( anchor_node_unique(likes, [bob, coffee], [], _),
          count_fact(likes, [bob, coffee], 1) )),

    % AC-NF-004: node_facts_dedup cleans duplicates made through the RAW door.
    % Anchor two identical facts with the raw anchor_node, then dedup removes one.
    report('AC-NF-004',
        ( anchor_node(likes, [carol, water], [], _),
          anchor_node(likes, [carol, water], [], _),
          count_fact(likes, [carol, water], 2),
          node_facts_dedup(Removed), Removed >= 1,
          count_fact(likes, [carol, water], 1) )),

    format("~n", []).
