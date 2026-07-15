/*  PrologAI — Justified Defeasible Reasoning Pack Test Suite  (PR 40)

    In-pack PLUnit acceptance tests for the three exported predicates:
      defeasible_defeasible_rule/3, defeasible_defeasible_query/4, defeasible_justify/2.

    Mirrors the canonical birds-fly / penguins-do-not-fly behaviour over a live
    Lattice nexus, asserting on the real query answers and on the rendered
    human-readable justifications.

    Run with:
        swipl -g "run_tests, halt" test_defeasible.pl
*/

% Declare this test file as a private module that exports nothing.
:- module(test_defeasible, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the defeasible pack under test and its three public predicates.
:- use_module(library(defeasible), [ defeasible_defeasible_rule/3, defeasible_defeasible_query/4, defeasible_justify/2 ]).

% Load the Lattice store so the suite can open, inspect, and close a nexus.
:- use_module(library(lattice), [ lattice_open/2, lattice_close/1, lattice_node_fact/5 ]).

% Load the node_facts helper that routes anchored facts to a chosen nexus.
:- use_module(library(node_facts), [ set_default_nexus/1 ]).

% Open a fresh Lattice nexus and make it the default target for anchored rules.
defeasible_test_setup :-
    % Open a test-only Lattice nexus at a local address.
    lattice_open('locus://localhost/test_defeasible', Nexus),
    % Remember the opened nexus handle for later cleanup.
    nb_setval(defeasible_test_nexus, Nexus),
    % Route every anchor_node write from the pack to this nexus.
    set_default_nexus(Nexus).

% Close the Lattice nexus that setup opened.
defeasible_test_cleanup :-
    % Recall the nexus handle stored during setup.
    nb_getval(defeasible_test_nexus, Nexus),
    % Release the nexus and the facts it holds.
    lattice_close(Nexus).

% Declare the canonical birds-fly default together with the penguin exception.
defeasible_birds_rules :-
    % Birds fly by default whenever they are known to be a bird.
    defeasible_defeasible_rule(birds, default, (flies(X) :- bird(X))),
    % Penguins are the exception that defeats the flight conclusion.
    defeasible_defeasible_rule(birds, exception, exc(flies(X), penguin(X))).

% Open the suite with a shared nexus setup and matching teardown.
:- begin_tests(defeasible, [setup(defeasible_test_setup), cleanup(defeasible_test_cleanup)]).

% A stored default rule must land in the Lattice as a defeasible_rule node_fact.
test(default_rule_stored_in_lattice) :-
    % Store a default rule saying mammals are warm-blooded (once: commit the single write).
    once(defeasible_defeasible_rule(mammals, default, (warm_blooded(X) :- mammal(X)))),
    % That rule must now be retrievable, deterministically, as a defeasible_rule fact for the mammals base.
    assertion(once(lattice_node_fact(_, _, defeasible_rule, [mammals, warm_blooded(_), mammal(_)], _))).

% A plain bird with no triggered exception flies by default.
test(bird_flies_by_default, [setup(defeasible_birds_rules)]) :-
    % Query flight for a robin known only to be a bird.
    defeasible_defeasible_query(birds, flies(robin), [bird(robin)], Answer),
    % The answer must be affirmative and carry a supporting proof tree.
    assertion(Answer = answer(yes, _)).

% A penguin triggers the exception, so its flight conclusion is defeated.
test(penguin_defeated_by_exception, [setup(defeasible_birds_rules)]) :-
    % Query flight for tweety, who is both a bird and a penguin.
    defeasible_defeasible_query(birds, flies(tweety), [bird(tweety), penguin(tweety)], Answer),
    % The answer must be negative with a defeated_by justification naming exception and goal.
    assertion(Answer = answer(no, just(no, defeated_by(penguin(tweety), flies(tweety)), _))).

% Querying a goal that no rule matches yields the explicit no_rule answer.
test(no_matching_rule_is_no_rule) :-
    % Query a goal in a rule base that holds no rules at all.
    defeasible_defeasible_query(empty_base, unknown(thing), [], Answer),
    % The answer must be exactly the canonical negative no_rule result.
    assertion(Answer == answer(no, just(no, no_rule))).

% A yes-answer proof tree must render to readable text naming the default rule.
test(justify_yes_is_readable, [setup(defeasible_birds_rules)]) :-
    % Obtain a yes proof for a plain eagle's flight.
    defeasible_defeasible_query(birds, flies(eagle), [bird(eagle)], answer(yes, Just)),
    % Render that proof tree into a human-readable atom.
    defeasible_justify(Just, Text),
    % The rendered justification must be an atom.
    assertion(atom(Text)),
    % The rendered justification must mention the default rule that fired.
    assertion(sub_atom(Text, _, _, _, 'default rule')).

% A no-answer proof tree must render to readable text stating the defeat.
test(justify_no_is_readable, [setup(defeasible_birds_rules)]) :-
    % Obtain a no proof where the penguin exception defeats flight.
    defeasible_defeasible_query(birds, flies(pingu), [bird(pingu), penguin(pingu)], answer(no, Just)),
    % Render that defeat proof tree into a human-readable atom.
    defeasible_justify(Just, Text),
    % The rendered justification must be an atom.
    assertion(atom(Text)),
    % The rendered justification must state that the conclusion was defeated.
    assertion(sub_atom(Text, _, _, _, 'defeated')).

% Close the suite.
:- end_tests(defeasible).
