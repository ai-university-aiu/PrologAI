/*  PrologAI — PR 40 Justified Defeasible Reasoning Acceptance Tests

    AC-PR40-001: Given "birds fly by default" and "penguins are birds that do
                 not fly" with a penguin fact, when flight is queried, then the
                 answer is no with a justification tree naming the exception,
                 rendered readably.
    AC-PR40-002: Default rule applies when no exception is triggered.
    AC-PR40-003: Exception defeats default even when default precondition holds.
    AC-PR40-004: defeasible_justify renders yes-answer readably.
    AC-PR40-005: defeasible_defeasible_rule stores rules as node_facts in the Lattice.
    AC-PR40-006: Chained defaults: A :- fact, B :- fact2, query B.
    AC-PR40-007: No applicable rule → answer no with no_rule justification.
    AC-PR40-008: Multiple exceptions — at least one triggers → defeated.
    AC-PR40-009: defeasible_justify renders no-answer readably (non-empty text).
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/defeasible/prolog'],     DefPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, DefPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    % Continue the multi-line expression started above.
                                    lattice_node_fact/5]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'defeasible' library so its predicates are available here.
:- use_module(library(defeasible), [
    % Supply 'defeasible_defeasible_rule/3' as the next argument to the expression above.
    defeasible_defeasible_rule/3,
    % Supply 'defeasible_defeasible_query/4' as the next argument to the expression above.
    defeasible_defeasible_query/4,
    % Supply 'defeasible_justify/2' as the next argument to the expression above.
    defeasible_justify/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr40, [setup(pr40_setup), cleanup(pr40_cleanup)]).
:- begin_tests(pr40, [setup(pr40_setup), cleanup(pr40_cleanup)]).

% Execute: pr40_setup :-.
pr40_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr40', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr40_nexus, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr40_cleanup :-.
pr40_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr40_nexus, N),
    % State the fact: lattice close(N).
    lattice_close(N).

% Execute: birds_setup :-.
birds_setup :-
    % Define a clause for 'pai defeasible rule': succeed when the following conditions hold.
    defeasible_defeasible_rule(birds40, default,   (flies40(X) :- bird40(X))),
    % State the fact: pai defeasible rule(birds40, exception, exc(flies40(X), penguin40(X))).
    defeasible_defeasible_rule(birds40, exception, exc(flies40(X), penguin40(X))).

%  AC-PR40-001: penguin does not fly (the canonical test)
% Define a clause for 'test': succeed when the following conditions hold.
test(penguin_does_not_fly, [setup((pr40_setup, birds_setup))]) :-
    % Check that 'BG' is unifiable with '[bird40(tweety), penguin40(tweety)]'.
    BG = [bird40(tweety), penguin40(tweety)],
    % State a fact for 'pai defeasible query' with the arguments listed below.
    defeasible_defeasible_query(birds40, flies40(tweety), BG, Answer),
    % Check that 'Answer' is unifiable with 'answer(no, Just)'.
    Answer = answer(no, Just),
    % State a fact for 'pai justify' with the arguments listed below.
    defeasible_justify(Just, Text),
    % Check that 'Text' is not unifiable with '""'.
    Text \= "".

%  AC-PR40-002: non-penguin bird does fly (no exception triggered)
% Define a clause for 'test': succeed when the following conditions hold.
test(bird_does_fly, [setup((pr40_setup, birds_setup))]) :-
    % Check that 'BG' is unifiable with '[bird40(robin)]'.
    BG = [bird40(robin)],
    % State a fact for 'pai defeasible query' with the arguments listed below.
    defeasible_defeasible_query(birds40, flies40(robin), BG, Answer),
    % Check that 'Answer' is unifiable with 'answer(yes, _)'.
    Answer = answer(yes, _).

%  AC-PR40-003: exception explicitly defeats default even when default fires
% Define a clause for 'test': succeed when the following conditions hold.
test(exception_defeats_default, [setup((pr40_setup, birds_setup))]) :-
    % Check that 'BG' is unifiable with '[bird40(tweety), penguin40(tweety)]'.
    BG = [bird40(tweety), penguin40(tweety)],
    % State the fact: pai defeasible query(birds40, flies40(tweety), BG, answer(no, _)).
    defeasible_defeasible_query(birds40, flies40(tweety), BG, answer(no, _)).

%  AC-PR40-004: defeasible_justify renders yes-answer readably
% Define a clause for 'test': succeed when the following conditions hold.
test(justify_yes_readable, [setup((pr40_setup, birds_setup))]) :-
    % Check that 'BG' is unifiable with '[bird40(robin)]'.
    BG = [bird40(robin)],
    % State a fact for 'pai defeasible query' with the arguments listed below.
    defeasible_defeasible_query(birds40, flies40(robin), BG, answer(yes, Just)),
    % State a fact for 'pai justify' with the arguments listed below.
    defeasible_justify(Just, Text),
    % State a fact for 'atom' with the arguments listed below.
    atom(Text),
    % Check that 'Text' is not unifiable with '""'.
    Text \= "".

%  AC-PR40-005: defeasible_defeasible_rule stores node_facts in Lattice
% Define a clause for 'test': succeed when the following conditions hold.
test(rule_in_lattice, [setup(pr40_setup)]) :-
    % Define a clause for 'once': succeed when the following conditions hold.
    once(defeasible_defeasible_rule(rb40, default, (warm_blooded40(X) :- mammal40(X)))),
    % State the fact: once(lattice_node_fact(_, _, defeasible_rule, [rb40 | _], _)).
    once(lattice_node_fact(_, _, defeasible_rule, [rb40 | _], _)).

%  AC-PR40-006: two independent defaults in same rule base
% Define a clause for 'test': succeed when the following conditions hold.
test(two_defaults, [setup(pr40_setup)]) :-
    % Define a clause for 'once': succeed when the following conditions hold.
    once(defeasible_defeasible_rule(rb40b, default, (moves40(X) :- animal40(X)))),
    % Define a clause for 'once': succeed when the following conditions hold.
    once(defeasible_defeasible_rule(rb40b, default, (eats40(X) :- animal40(X)))),
    % Check that 'BG' is unifiable with '[animal40(cat40)]'.
    BG = [animal40(cat40)],
    % State a fact for 'once' with the arguments listed below.
    once(defeasible_defeasible_query(rb40b, moves40(cat40), BG, answer(yes, _))),
    % State the fact: once(defeasible_defeasible_query(rb40b, eats40(cat40),  BG, answer(yes, _))).
    once(defeasible_defeasible_query(rb40b, eats40(cat40),  BG, answer(yes, _))).

%  AC-PR40-007: no applicable rule → answer(no, just(no, no_rule))
% Define a clause for 'test': succeed when the following conditions hold.
test(no_rule_no_answer, [setup(pr40_setup)]) :-
    % State the fact: pai defeasible query(empty_rb40, unknown40(x), [], answer(no, just(no, no_rule))).
    defeasible_defeasible_query(empty_rb40, unknown40(x), [], answer(no, just(no, no_rule))).

%  AC-PR40-008: multiple exceptions — first applicable one triggers defeat
% Define a clause for 'test': succeed when the following conditions hold.
test(multiple_exceptions, [setup(pr40_setup)]) :-
    % Define a clause for 'once': succeed when the following conditions hold.
    once(defeasible_defeasible_rule(rb40c, default,   (active40(X) :- alive40(X)))),
    % State a fact for 'once' with the arguments listed below.
    once(defeasible_defeasible_rule(rb40c, exception, exc(active40(X), sleeping40(X)))),
    % State a fact for 'once' with the arguments listed below.
    once(defeasible_defeasible_rule(rb40c, exception, exc(active40(X), dead40(X)))),
    % Check that 'BG' is unifiable with '[alive40(bear40), sleeping40(bear40)]'.
    BG = [alive40(bear40), sleeping40(bear40)],
    % State the fact: once(defeasible_defeasible_query(rb40c, active40(bear40), BG, answer(no, _))).
    once(defeasible_defeasible_query(rb40c, active40(bear40), BG, answer(no, _))).

%  AC-PR40-009: defeasible_justify renders no-answer as non-empty readable text
% Define a clause for 'test': succeed when the following conditions hold.
test(justify_no_readable, [setup((pr40_setup, birds_setup))]) :-
    % Check that 'BG' is unifiable with '[bird40(tweety), penguin40(tweety)]'.
    BG = [bird40(tweety), penguin40(tweety)],
    % State a fact for 'pai defeasible query' with the arguments listed below.
    defeasible_defeasible_query(birds40, flies40(tweety), BG, answer(no, Just)),
    % State a fact for 'pai justify' with the arguments listed below.
    defeasible_justify(Just, Text),
    % State a fact for 'atom' with the arguments listed below.
    atom(Text),
    % State a fact for 'atom length' with the arguments listed below.
    atom_length(Text, Len),
    % Check that 'Len' is greater than '10'.
    Len > 10.

% Execute the compile-time directive: end_tests(pr40).
:- end_tests(pr40).
