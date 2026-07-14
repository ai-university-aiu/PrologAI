/*  PrologAI — Causalontology Noun Backbone  (WP-391, Layer 366)

    The NOUN layer of the Causalontology Foundational Ontology (Causalontology_v5,
    Sections 3.3 and 5): a deliberately thin upper-level backbone that hosts
    the continuants — the things that endure — and serves as an alignment
    pivot for external domain ontologies. It defers all domain depth to the
    specialists: Causalontology governs the verbs and defers on the nouns.

    The backbone stores continuants with a category, a subsumption (is-a)
    hierarchy, and a part-of hierarchy. Both hierarchies are kept acyclic —
    the decidable projection of the noun layer — and noun_backbone_acyclic/0
    is the consistency check the Completion phase requires.

    External noun classes are aligned to the backbone with confidence-scored
    mappings (noun_backbone_align_add/3), so that no existing project must abandon its
    own nouns to adopt Causalontology's verbs.

    Notation (Section 12): a continuant is written continuant(Id, Category).

    Predicates:
      noun_backbone_reset/0        -- clear the noun layer
      noun_backbone_continuant_add/2    -- +Id, +Category
      noun_backbone_continuant/2        -- ?Id, ?Category
      noun_backbone_isa_add/2           -- +Sub, +Super   (refuses cycles)
      noun_backbone_isa/2               -- ?Sub, ?Super   (transitive)
      noun_backbone_part_of_add/2       -- +Part, +Whole  (refuses cycles)
      noun_backbone_part_of/2           -- ?Part, ?Whole  (transitive)
      noun_backbone_acyclic/0  -- the decidable projection check
      noun_backbone_align_add/3         -- +ExternalClass, +BackboneId, +Confidence
      noun_backbone_alignment/3         -- ?ExternalClass, ?BackboneId, ?Confidence
      noun_backbone_resolve/3           -- +ExternalClass, -BackboneId, -Confidence
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(noun_backbone, [
    % noun_backbone_reset/0: clear the noun layer.
    noun_backbone_reset/0,
    % noun_backbone_continuant_add/2: register a continuant with its category.
    noun_backbone_continuant_add/2,
    % noun_backbone_continuant/2: query the continuants.
    noun_backbone_continuant/2,
    % noun_backbone_isa_add/2: add a subsumption edge, refusing cycles.
    noun_backbone_isa_add/2,
    % noun_backbone_isa/2: transitive subsumption.
    noun_backbone_isa/2,
    % noun_backbone_part_of_add/2: add a part-of edge, refusing cycles.
    noun_backbone_part_of_add/2,
    % noun_backbone_part_of/2: transitive parthood.
    noun_backbone_part_of/2,
    % noun_backbone_acyclic/0: the decidable projection consistency check.
    noun_backbone_acyclic/0,
    % noun_backbone_align_add/3: align an external class to the backbone with confidence.
    noun_backbone_align_add/3,
    % noun_backbone_alignment/3: query the alignments.
    noun_backbone_alignment/3,
    % noun_backbone_resolve/3: resolve an external class to its best backbone match.
    noun_backbone_resolve/3
]).

% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% noun_backbone_continuant_/2: (Id, Category) — the registered continuants.
:- dynamic noun_backbone_continuant_/2.
% noun_backbone_isa_/2: (Sub, Super) — direct subsumption edges.
:- dynamic noun_backbone_isa_/2.
% noun_backbone_part_/2: (Part, Whole) — direct parthood edges.
:- dynamic noun_backbone_part_/2.
% noun_backbone_align_/3: (ExternalClass, BackboneId, Confidence) — alignment pivot.
:- dynamic noun_backbone_align_/3.

% Define noun_backbone_reset: clear every noun-layer store.
noun_backbone_reset :-
    % Drop the continuants.
    retractall(noun_backbone_continuant_(_, _)),
    % Drop the subsumption edges.
    retractall(noun_backbone_isa_(_, _)),
    % Drop the parthood edges.
    retractall(noun_backbone_part_(_, _)),
    % Drop the alignments.
    retractall(noun_backbone_align_(_, _, _)).

% ---------------------------------------------------------------------------
% Continuants
% ---------------------------------------------------------------------------

% Define noun_backbone_continuant_add: register a continuant; re-adding updates category.
noun_backbone_continuant_add(Id, Category) :-
    % Identifiers and categories are atoms.
    atom(Id),
    % The category too.
    atom(Category),
    % Replace any previous registration.
    retractall(noun_backbone_continuant_(Id, _)),
    % Record the continuant.
    assertz(noun_backbone_continuant_(Id, Category)).

% Define noun_backbone_continuant: query the registered continuants.
noun_backbone_continuant(Id, Category) :-
    % Enumerate or test the store.
    noun_backbone_continuant_(Id, Category).

% ---------------------------------------------------------------------------
% Subsumption and parthood — both kept acyclic
% ---------------------------------------------------------------------------

% Define noun_backbone_isa_add: a subsumption edge that would close a cycle is refused.
noun_backbone_isa_add(Sub, Super) :-
    % A class never subsumes itself.
    Sub \== Super,
    % The new edge must not make Sub an ancestor of itself.
    \+ noun_backbone_reach(noun_backbone_isa_, Super, Sub),
    % Record the edge once.
    (   noun_backbone_isa_(Sub, Super)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(noun_backbone_isa_(Sub, Super))
    ).

% Define noun_backbone_isa: transitive subsumption over the direct edges.
noun_backbone_isa(Sub, Super) :-
    % Reachability in the subsumption graph.
    noun_backbone_reach(noun_backbone_isa_, Sub, Super).

% Define noun_backbone_part_of_add: a parthood edge that would close a cycle is refused.
noun_backbone_part_of_add(Part, Whole) :-
    % Nothing is a proper part of itself.
    Part \== Whole,
    % The new edge must not make Part contain itself.
    \+ noun_backbone_reach(noun_backbone_part_, Whole, Part),
    % Record the edge once.
    (   noun_backbone_part_(Part, Whole)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(noun_backbone_part_(Part, Whole))
    ).

% Define noun_backbone_part_of: transitive parthood over the direct edges.
noun_backbone_part_of(Part, Whole) :-
    % Reachability in the parthood graph.
    noun_backbone_reach(noun_backbone_part_, Part, Whole).

% noun_backbone_reach(+EdgePred, ?From, ?To): reachability over one edge relation.
noun_backbone_reach(Edge, From, To) :-
    % A direct edge reaches.
    call(Edge, From, To).
% A path through an intermediate node reaches.
noun_backbone_reach(Edge, From, To) :-
    % Take the first hop.
    call(Edge, From, Mid),
    % Continue from the intermediate node.
    noun_backbone_reach(Edge, Mid, To).

% Define noun_backbone_acyclic: the decidable projection consistency check.
noun_backbone_acyclic :-
    % No class may subsume itself through any chain.
    \+ ( noun_backbone_continuant_(Id, _), noun_backbone_reach(noun_backbone_isa_, Id, Id) ),
    % No object may contain itself through any chain.
    \+ ( noun_backbone_continuant_(Id, _), noun_backbone_reach(noun_backbone_part_, Id, Id) ).

% ---------------------------------------------------------------------------
% External alignment — the pivot that spares adopters their own nouns
% ---------------------------------------------------------------------------

% Define noun_backbone_align_add: align an external class with a confidence score.
noun_backbone_align_add(ExternalClass, BackboneId, Confidence) :-
    % The backbone side must exist.
    noun_backbone_continuant_(BackboneId, _),
    % Confidence is a fraction.
    number(Confidence),
    % Lower bound.
    Confidence >= 0.0,
    % Upper bound.
    Confidence =< 1.0,
    % Replace any previous mapping of this external class to this target.
    retractall(noun_backbone_align_(ExternalClass, BackboneId, _)),
    % Record the alignment.
    assertz(noun_backbone_align_(ExternalClass, BackboneId, Confidence)).

% Define noun_backbone_alignment: query the alignments.
noun_backbone_alignment(ExternalClass, BackboneId, Confidence) :-
    % Enumerate or test the store.
    noun_backbone_align_(ExternalClass, BackboneId, Confidence).

% Define noun_backbone_resolve: the highest-confidence backbone match for a class.
noun_backbone_resolve(ExternalClass, BackboneId, Confidence) :-
    % Collect every mapping of the external class.
    findall(C-B, noun_backbone_align_(ExternalClass, B, C), Pairs),
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
