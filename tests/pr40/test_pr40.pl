/*  PrologAI — PR 40 Justified Defeasible Reasoning Acceptance Tests

    AC-PR40-001: Given "birds fly by default" and "penguins are birds that do
                 not fly" with a penguin fact, when flight is queried, then the
                 answer is no with a justification tree naming the exception,
                 rendered readably.
    AC-PR40-002: Default rule applies when no exception is triggered.
    AC-PR40-003: Exception defeats default even when default precondition holds.
    AC-PR40-004: pai_justify renders yes-answer readably.
    AC-PR40-005: pai_defeasible_rule stores rules as node_facts in the Lattice.
    AC-PR40-006: Chained defaults: A :- fact, B :- fact2, query B.
    AC-PR40-007: No applicable rule → answer no with no_rule justification.
    AC-PR40-008: Multiple exceptions — at least one triggers → defeated.
    AC-PR40-009: pai_justify renders no-answer readably (non-empty text).
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/defeasible/prolog'],     DefPath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, DefPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    lattice_node_fact/5]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(defeasible), [
    pai_defeasible_rule/3,
    pai_defeasible_query/4,
    pai_justify/2
]).

:- begin_tests(pr40, [setup(pr40_setup), cleanup(pr40_cleanup)]).

pr40_setup :-
    lattice_open('locus://localhost/pr40', N),
    nb_setval(pr40_nexus, N),
    set_default_nexus(N).

pr40_cleanup :-
    nb_getval(pr40_nexus, N),
    lattice_close(N).

birds_setup :-
    pai_defeasible_rule(birds40, default,   (flies40(X) :- bird40(X))),
    pai_defeasible_rule(birds40, exception, exc(flies40(X), penguin40(X))).

%  AC-PR40-001: penguin does not fly (the canonical test)
test(penguin_does_not_fly, [setup((pr40_setup, birds_setup))]) :-
    BG = [bird40(tweety), penguin40(tweety)],
    pai_defeasible_query(birds40, flies40(tweety), BG, Answer),
    Answer = answer(no, Just),
    pai_justify(Just, Text),
    Text \= "".

%  AC-PR40-002: non-penguin bird does fly (no exception triggered)
test(bird_does_fly, [setup((pr40_setup, birds_setup))]) :-
    BG = [bird40(robin)],
    pai_defeasible_query(birds40, flies40(robin), BG, Answer),
    Answer = answer(yes, _).

%  AC-PR40-003: exception explicitly defeats default even when default fires
test(exception_defeats_default, [setup((pr40_setup, birds_setup))]) :-
    BG = [bird40(tweety), penguin40(tweety)],
    pai_defeasible_query(birds40, flies40(tweety), BG, answer(no, _)).

%  AC-PR40-004: pai_justify renders yes-answer readably
test(justify_yes_readable, [setup((pr40_setup, birds_setup))]) :-
    BG = [bird40(robin)],
    pai_defeasible_query(birds40, flies40(robin), BG, answer(yes, Just)),
    pai_justify(Just, Text),
    atom(Text),
    Text \= "".

%  AC-PR40-005: pai_defeasible_rule stores node_facts in Lattice
test(rule_in_lattice, [setup(pr40_setup)]) :-
    once(pai_defeasible_rule(rb40, default, (warm_blooded40(X) :- mammal40(X)))),
    once(lattice_node_fact(_, _, defeasible_rule, [rb40 | _], _)).

%  AC-PR40-006: two independent defaults in same rule base
test(two_defaults, [setup(pr40_setup)]) :-
    once(pai_defeasible_rule(rb40b, default, (moves40(X) :- animal40(X)))),
    once(pai_defeasible_rule(rb40b, default, (eats40(X) :- animal40(X)))),
    BG = [animal40(cat40)],
    once(pai_defeasible_query(rb40b, moves40(cat40), BG, answer(yes, _))),
    once(pai_defeasible_query(rb40b, eats40(cat40),  BG, answer(yes, _))).

%  AC-PR40-007: no applicable rule → answer(no, just(no, no_rule))
test(no_rule_no_answer, [setup(pr40_setup)]) :-
    pai_defeasible_query(empty_rb40, unknown40(x), [], answer(no, just(no, no_rule))).

%  AC-PR40-008: multiple exceptions — first applicable one triggers defeat
test(multiple_exceptions, [setup(pr40_setup)]) :-
    once(pai_defeasible_rule(rb40c, default,   (active40(X) :- alive40(X)))),
    once(pai_defeasible_rule(rb40c, exception, exc(active40(X), sleeping40(X)))),
    once(pai_defeasible_rule(rb40c, exception, exc(active40(X), dead40(X)))),
    BG = [alive40(bear40), sleeping40(bear40)],
    once(pai_defeasible_query(rb40c, active40(bear40), BG, answer(no, _))).

%  AC-PR40-009: pai_justify renders no-answer as non-empty readable text
test(justify_no_readable, [setup((pr40_setup, birds_setup))]) :-
    BG = [bird40(tweety), penguin40(tweety)],
    pai_defeasible_query(birds40, flies40(tweety), BG, answer(no, Just)),
    pai_justify(Just, Text),
    atom(Text),
    atom_length(Text, Len),
    Len > 10.

:- end_tests(pr40).
