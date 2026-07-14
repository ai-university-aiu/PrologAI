/*  PrologAI — Causalontology Noun Backbone Test Suite  (WP-391)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/noun_backbone/test/test_co_noun.pl
*/

% Declare this file as a test module.
:- module(test_co_noun, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(noun_backbone)).

:- begin_tests(noun_backbone).

% Continuants register with a category and can be queried.
test(continuant_roundtrip) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % Register a door as an object.
    noun_backbone_continuant_add(door, object),
    % Query it back.
    noun_backbone_continuant(door, object).

% Subsumption is transitive.
test(isa_transitive, [nondet]) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % A small taxonomy: a key is a tool; a tool is an artifact.
    noun_backbone_continuant_add(key, object),
    % The middle class.
    noun_backbone_continuant_add(tool, object),
    % The top class.
    noun_backbone_continuant_add(artifact, object),
    % First edge.
    noun_backbone_isa_add(key, tool),
    % Second edge.
    noun_backbone_isa_add(tool, artifact),
    % Transitivity carries key up to artifact.
    noun_backbone_isa(key, artifact).

% A subsumption cycle is refused, keeping the projection decidable.
test(isa_cycle_refused, [fail]) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % Two classes.
    noun_backbone_continuant_add(a, object),
    % The second.
    noun_backbone_continuant_add(b, object),
    % One direction is fine.
    noun_backbone_isa_add(a, b),
    % The closing edge must be refused.
    noun_backbone_isa_add(b, a).

% Parthood is transitive and refuses cycles too.
test(part_of_transitive_and_acyclic, [nondet]) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % Three parts.
    noun_backbone_continuant_add(bit, object),
    % The middle whole.
    noun_backbone_continuant_add(blade, object),
    % The outer whole.
    noun_backbone_continuant_add(key, object),
    % First edge.
    noun_backbone_part_of_add(bit, blade),
    % Second edge.
    noun_backbone_part_of_add(blade, key),
    % Transitivity carries the bit into the key.
    noun_backbone_part_of(bit, key),
    % The closing edge is refused.
    \+ noun_backbone_part_of_add(key, bit),
    % The backbone remains acyclic — the decidable projection check.
    noun_backbone_acyclic.

% External classes align with confidence and resolve to the best match.
test(alignment_resolves_best) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % Two backbone classes.
    noun_backbone_continuant_add(tool, object),
    % The second.
    noun_backbone_continuant_add(artifact, object),
    % An external ontology's class maps to both, with different confidence.
    noun_backbone_align_add('ext:Instrument', tool, 0.9),
    % The weaker mapping.
    noun_backbone_align_add('ext:Instrument', artifact, 0.6),
    % Resolution picks the strongest.
    noun_backbone_resolve('ext:Instrument', tool, 0.9).

% Alignment to an unregistered backbone class is refused.
test(alignment_needs_backbone, [fail]) :-
    % A fresh noun layer.
    noun_backbone_reset,
    % No such backbone class exists.
    noun_backbone_align_add('ext:Ghost', ghost, 0.9).

:- end_tests(noun_backbone).
