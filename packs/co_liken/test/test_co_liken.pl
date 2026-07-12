/*  PrologAI — Causalontology Analogy Test Suite  (WP-419)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_liken/test/test_co_liken.pl
*/

% Declare this file as a test module.
:- module(test_co_liken, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_liken)).

% Open the test block.
:- begin_tests(co_liken).

% The distinct objects of a relation set are gathered and sorted.
test(objects) :-
    co_liken:lk_objects([rel(above, a, b), rel(above, b, c)], Objs),
    assertion(Objs == [a, b, c]).

% A stacking situation maps onto another stacking situation.
test(best_mapping_stack) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    Target = [rel(above, x, y), rel(above, y, z)],
    co_liken:lk_analogy(Source, Target, Map, Score),
    assertion(Score =:= 2),
    assertion(Map == [a-x, b-y, c-z]).

% The count of preserved relations matches the mapping's score.
test(preserved_count) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    Target = [rel(above, x, y), rel(above, y, z)],
    co_liken:lk_preserved([a-x, b-y, c-z], Source, Target, C),
    assertion(C =:= 2).

% The solar-system to atom analogy maps sun->nucleus and planet->electron.
test(solar_system_to_atom) :-
    Source = [rel(orbits, planet, sun), rel(heavier, sun, planet)],
    Target = [rel(orbits, electron, nucleus), rel(heavier, nucleus, electron)],
    co_liken:lk_analogy(Source, Target, Map, Score),
    assertion(Score =:= 2),
    assertion(co_liken:lk_map_object(Map, sun, nucleus)),
    assertion(co_liken:lk_map_object(Map, planet, electron)).

% A known rule about the source transfers to the target objects.
test(transfer_rule) :-
    Source = [rel(orbits, planet, sun), rel(heavier, sun, planet)],
    Target = [rel(orbits, electron, nucleus), rel(heavier, nucleus, electron)],
    co_liken:lk_analogy(Source, Target, Map, _),
    % A source rule "the sun pulls the planet" transfers across the mapping.
    co_liken:lk_transfer(Map, pulls(sun, planet), Transferred),
    assertion(Transferred == pulls(nucleus, electron)).

% A target missing a relation yields a lower best score.
test(partial_match) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    % Same three objects, but only one relation is "above"; the other differs.
    Target = [rel(above, x, y), rel(near, y, z)],
    co_liken:lk_analogy(Source, Target, _, Score),
    assertion(Score =:= 1).

% An atom or number that is not an object passes through transfer unchanged.
test(transfer_passthrough) :-
    Map = [a-x],
    co_liken:lk_transfer(Map, cost(a, 5, fixed), T),
    assertion(T == cost(x, 5, fixed)).

% Close the test block.
:- end_tests(co_liken).
