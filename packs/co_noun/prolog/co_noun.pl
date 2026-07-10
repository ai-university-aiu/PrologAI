/*  PrologAI — Causalontology Noun Backbone  (WP-391, Layer 366)

    The NOUN layer of the Causalontology Foundational Ontology (Causalontology_v5,
    Sections 3.3 and 5): a deliberately thin upper-level backbone that hosts
    the continuants — the things that endure — and serves as an alignment
    pivot for external domain ontologies. It defers all domain depth to the
    specialists: Causalontology governs the verbs and defers on the nouns.

    The backbone stores continuants with a category, a subsumption (is-a)
    hierarchy, and a part-of hierarchy. Both hierarchies are kept acyclic —
    the decidable projection of the noun layer — and co_backbone_acyclic/0
    is the consistency check the Completion phase requires.

    External noun classes are aligned to the backbone with confidence-scored
    mappings (co_align_add/3), so that no existing project must abandon its
    own nouns to adopt Causalontology's verbs.

    Notation (Section 12): a continuant is written continuant(Id, Category).

    Predicates:
      co_noun_reset/0        -- clear the noun layer
      co_continuant_add/2    -- +Id, +Category
      co_continuant/2        -- ?Id, ?Category
      co_isa_add/2           -- +Sub, +Super   (refuses cycles)
      co_isa/2               -- ?Sub, ?Super   (transitive)
      co_part_of_add/2       -- +Part, +Whole  (refuses cycles)
      co_part_of/2           -- ?Part, ?Whole  (transitive)
      co_backbone_acyclic/0  -- the decidable projection check
      co_align_add/3         -- +ExternalClass, +BackboneId, +Confidence
      co_alignment/3         -- ?ExternalClass, ?BackboneId, ?Confidence
      co_resolve/3           -- +ExternalClass, -BackboneId, -Confidence
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_noun, [
    % co_noun_reset/0: clear the noun layer.
    co_noun_reset/0,
    % co_continuant_add/2: register a continuant with its category.
    co_continuant_add/2,
    % co_continuant/2: query the continuants.
    co_continuant/2,
    % co_isa_add/2: add a subsumption edge, refusing cycles.
    co_isa_add/2,
    % co_isa/2: transitive subsumption.
    co_isa/2,
    % co_part_of_add/2: add a part-of edge, refusing cycles.
    co_part_of_add/2,
    % co_part_of/2: transitive parthood.
    co_part_of/2,
    % co_backbone_acyclic/0: the decidable projection consistency check.
    co_backbone_acyclic/0,
    % co_align_add/3: align an external class to the backbone with confidence.
    co_align_add/3,
    % co_alignment/3: query the alignments.
    co_alignment/3,
    % co_resolve/3: resolve an external class to its best backbone match.
    co_resolve/3
]).

% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% co_continuant_/2: (Id, Category) — the registered continuants.
:- dynamic co_continuant_/2.
% co_isa_/2: (Sub, Super) — direct subsumption edges.
:- dynamic co_isa_/2.
% co_part_/2: (Part, Whole) — direct parthood edges.
:- dynamic co_part_/2.
% co_align_/3: (ExternalClass, BackboneId, Confidence) — alignment pivot.
:- dynamic co_align_/3.

% Define co_noun_reset: clear every noun-layer store.
co_noun_reset :-
    % Drop the continuants.
    retractall(co_continuant_(_, _)),
    % Drop the subsumption edges.
    retractall(co_isa_(_, _)),
    % Drop the parthood edges.
    retractall(co_part_(_, _)),
    % Drop the alignments.
    retractall(co_align_(_, _, _)).

% ---------------------------------------------------------------------------
% Continuants
% ---------------------------------------------------------------------------

% Define co_continuant_add: register a continuant; re-adding updates category.
co_continuant_add(Id, Category) :-
    % Identifiers and categories are atoms.
    atom(Id),
    % The category too.
    atom(Category),
    % Replace any previous registration.
    retractall(co_continuant_(Id, _)),
    % Record the continuant.
    assertz(co_continuant_(Id, Category)).

% Define co_continuant: query the registered continuants.
co_continuant(Id, Category) :-
    % Enumerate or test the store.
    co_continuant_(Id, Category).

% ---------------------------------------------------------------------------
% Subsumption and parthood — both kept acyclic
% ---------------------------------------------------------------------------

% Define co_isa_add: a subsumption edge that would close a cycle is refused.
co_isa_add(Sub, Super) :-
    % A class never subsumes itself.
    Sub \== Super,
    % The new edge must not make Sub an ancestor of itself.
    \+ co_reach(co_isa_, Super, Sub),
    % Record the edge once.
    (   co_isa_(Sub, Super)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(co_isa_(Sub, Super))
    ).

% Define co_isa: transitive subsumption over the direct edges.
co_isa(Sub, Super) :-
    % Reachability in the subsumption graph.
    co_reach(co_isa_, Sub, Super).

% Define co_part_of_add: a parthood edge that would close a cycle is refused.
co_part_of_add(Part, Whole) :-
    % Nothing is a proper part of itself.
    Part \== Whole,
    % The new edge must not make Part contain itself.
    \+ co_reach(co_part_, Whole, Part),
    % Record the edge once.
    (   co_part_(Part, Whole)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(co_part_(Part, Whole))
    ).

% Define co_part_of: transitive parthood over the direct edges.
co_part_of(Part, Whole) :-
    % Reachability in the parthood graph.
    co_reach(co_part_, Part, Whole).

% co_reach(+EdgePred, ?From, ?To): reachability over one edge relation.
co_reach(Edge, From, To) :-
    % A direct edge reaches.
    call(Edge, From, To).
% A path through an intermediate node reaches.
co_reach(Edge, From, To) :-
    % Take the first hop.
    call(Edge, From, Mid),
    % Continue from the intermediate node.
    co_reach(Edge, Mid, To).

% Define co_backbone_acyclic: the decidable projection consistency check.
co_backbone_acyclic :-
    % No class may subsume itself through any chain.
    \+ ( co_continuant_(Id, _), co_reach(co_isa_, Id, Id) ),
    % No object may contain itself through any chain.
    \+ ( co_continuant_(Id, _), co_reach(co_part_, Id, Id) ).

% ---------------------------------------------------------------------------
% External alignment — the pivot that spares adopters their own nouns
% ---------------------------------------------------------------------------

% Define co_align_add: align an external class with a confidence score.
co_align_add(ExternalClass, BackboneId, Confidence) :-
    % The backbone side must exist.
    co_continuant_(BackboneId, _),
    % Confidence is a fraction.
    number(Confidence),
    % Lower bound.
    Confidence >= 0.0,
    % Upper bound.
    Confidence =< 1.0,
    % Replace any previous mapping of this external class to this target.
    retractall(co_align_(ExternalClass, BackboneId, _)),
    % Record the alignment.
    assertz(co_align_(ExternalClass, BackboneId, Confidence)).

% Define co_alignment: query the alignments.
co_alignment(ExternalClass, BackboneId, Confidence) :-
    % Enumerate or test the store.
    co_align_(ExternalClass, BackboneId, Confidence).

% Define co_resolve: the highest-confidence backbone match for a class.
co_resolve(ExternalClass, BackboneId, Confidence) :-
    % Collect every mapping of the external class.
    findall(C-B, co_align_(ExternalClass, B, C), Pairs),
    % There must be at least one.
    Pairs \== [],
    % Sort ascending by confidence.
    msort(Pairs, Sorted),
    % The last pair carries the highest confidence.
    last(Sorted, Confidence-BackboneId).

% last(+List, -Last): the final element of a list.
last([X], X) :- !.
% Walk to the end.
last([_ | T], X) :- last(T, X).
