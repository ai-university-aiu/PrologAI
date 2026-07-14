/*  PrologAI — Causalontology Concept Formation Test Suite  (WP-420)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/concept_formation/test/test_concept_formation.pl
*/

% Declare this file as a test module.
:- module(test_concept_formation, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(concept_formation)).

% A small helper library for the fixture.
:- use_module(library(lists)).

% Open the test block.
:- begin_tests(concept_formation).

% Load a fixture of four items: three fruits and one brick.
setup_fixture :-
    concept_formation:concept_formation_reset,
    concept_formation:concept_formation_observe(apple,  [fruit, red, round, sweet]),
    concept_formation:concept_formation_observe(cherry, [fruit, red, round, sweet, small]),
    concept_formation:concept_formation_observe(banana, [fruit, long, sweet, yellow]),
    concept_formation:concept_formation_observe(brick,  [red, heavy, hard]).

% Observed features are stored as a sorted set.
test(observe_sorts) :-
    concept_formation:concept_formation_reset,
    concept_formation:concept_formation_observe(x, [sweet, fruit, red]),
    concept_formation:concept_formation_item(x, F),
    assertion(F == [fruit, red, sweet]).

% Two items share exactly their common features.
test(shared_features) :-
    setup_fixture,
    concept_formation:concept_formation_shared(apple, cherry, S),
    assertion(S == [fruit, red, round, sweet]).

% With a high floor, only the tightly-similar apple and cherry form a concept.
test(induce_tight) :-
    setup_fixture,
    concept_formation:concept_formation_induce(3, Concepts),
    % Bind the fields directly (assertion/1 would not propagate bindings).
    Concepts = [concept(_, Shared, Members)],
    assertion(Shared == [fruit, red, round, sweet]),
    assertion(Members == [apple, cherry]).

% With a lower floor, all three fruits cluster on their shared core.
test(induce_loose) :-
    setup_fixture,
    concept_formation:concept_formation_induce(2, Concepts),
    % Bind via a plain member/2 call (assertion/1 would not propagate bindings).
    member(concept(_, Core, Fruits), Concepts),
    assertion(Core == [fruit, sweet]),
    assertion(Fruits == [apple, banana, cherry]).

% The brick shares too little with the fruits to join a concept.
test(brick_excluded) :-
    setup_fixture,
    concept_formation:concept_formation_induce(2, Concepts),
    forall(member(concept(_, _, Members), Concepts),
           \+ memberchk(brick, Members)).

% A new item is classified into a concept whose core it contains.
test(classify_new_item) :-
    setup_fixture,
    concept_formation:concept_formation_induce(3, Concepts),
    % A shiny red round sweet fruit contains the concept's defining core.
    concept_formation:concept_formation_classify([fruit, red, round, sweet, shiny], Concepts, Cid),
    assertion(Concepts = [concept(Cid, _, _)]).

% An item that lacks the core is not classified.
test(classify_reject) :-
    setup_fixture,
    concept_formation:concept_formation_induce(3, Concepts),
    assertion(\+ concept_formation:concept_formation_classify([heavy, hard, grey], Concepts, _)).

% The item count reflects observations.
test(count) :-
    setup_fixture,
    concept_formation:concept_formation_count(N),
    assertion(N =:= 4).

% Close the test block.
:- end_tests(concept_formation).
