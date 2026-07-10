/*  PrologAI — Causalontology Noun Backbone Test Suite  (WP-391)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_noun/test/test_co_noun.pl
*/

% Declare this file as a test module.
:- module(test_co_noun, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_noun)).

:- begin_tests(co_noun).

% Continuants register with a category and can be queried.
test(continuant_roundtrip) :-
    % A fresh noun layer.
    co_noun_reset,
    % Register a door as an object.
    co_continuant_add(door, object),
    % Query it back.
    co_continuant(door, object).

% Subsumption is transitive.
test(isa_transitive, [nondet]) :-
    % A fresh noun layer.
    co_noun_reset,
    % A small taxonomy: a key is a tool; a tool is an artifact.
    co_continuant_add(key, object),
    % The middle class.
    co_continuant_add(tool, object),
    % The top class.
    co_continuant_add(artifact, object),
    % First edge.
    co_isa_add(key, tool),
    % Second edge.
    co_isa_add(tool, artifact),
    % Transitivity carries key up to artifact.
    co_isa(key, artifact).

% A subsumption cycle is refused, keeping the projection decidable.
test(isa_cycle_refused, [fail]) :-
    % A fresh noun layer.
    co_noun_reset,
    % Two classes.
    co_continuant_add(a, object),
    % The second.
    co_continuant_add(b, object),
    % One direction is fine.
    co_isa_add(a, b),
    % The closing edge must be refused.
    co_isa_add(b, a).

% Parthood is transitive and refuses cycles too.
test(part_of_transitive_and_acyclic, [nondet]) :-
    % A fresh noun layer.
    co_noun_reset,
    % Three parts.
    co_continuant_add(bit, object),
    % The middle whole.
    co_continuant_add(blade, object),
    % The outer whole.
    co_continuant_add(key, object),
    % First edge.
    co_part_of_add(bit, blade),
    % Second edge.
    co_part_of_add(blade, key),
    % Transitivity carries the bit into the key.
    co_part_of(bit, key),
    % The closing edge is refused.
    \+ co_part_of_add(key, bit),
    % The backbone remains acyclic — the decidable projection check.
    co_backbone_acyclic.

% External classes align with confidence and resolve to the best match.
test(alignment_resolves_best) :-
    % A fresh noun layer.
    co_noun_reset,
    % Two backbone classes.
    co_continuant_add(tool, object),
    % The second.
    co_continuant_add(artifact, object),
    % An external ontology's class maps to both, with different confidence.
    co_align_add('ext:Instrument', tool, 0.9),
    % The weaker mapping.
    co_align_add('ext:Instrument', artifact, 0.6),
    % Resolution picks the strongest.
    co_resolve('ext:Instrument', tool, 0.9).

% Alignment to an unregistered backbone class is refused.
test(alignment_needs_backbone, [fail]) :-
    % A fresh noun layer.
    co_noun_reset,
    % No such backbone class exists.
    co_align_add('ext:Ghost', ghost, 0.9).

:- end_tests(co_noun).
