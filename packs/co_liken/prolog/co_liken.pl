/*  PrologAI — Causalontology Analogy  (WP-419, Layer 394)

    THE_BUILDING_FILES name analogy as one of the core modes of inference — the
    ability to see that one situation has the same shape as another and to carry
    a lesson across. The co_ family could describe a situation as a set of
    relations (object_relations) but had no way to line two such descriptions up. This pack
    is that structure-mapping, kept small and glass-box.

    A situation is a list of relations, each written rel(Type, ObjectA, ObjectB),
    exactly the shape object_relations produces. An ANALOGY is an injective mapping from the
    objects of a source situation onto the objects of a target situation that
    makes as many relations line up as possible: a source rel(Type, A, B) is
    PRESERVED when rel(Type, map(A), map(B)) is present in the target. The best
    mapping is the one that preserves the most relations, and once found it can
    TRANSFER a known fact — a rule, a goal, a disposition — from the source
    objects to their target counterparts.

    Because finding the best mapping searches over object assignments, the source
    is capped at a small number of objects (the situations that arise in practice
    are small); a larger source should be matched the other way around.

    Predicates:
      lk_objects/2          -- +Relations, -Objects        (the distinct objects)
      lk_map_object/3       -- +Mapping, +Object, -Image     (apply a mapping to one object)
      lk_preserved/4        -- +Mapping, +Source, +Target, -Count  (relations lined up)
      lk_analogy/4          -- +Source, +Target, -Mapping, -Score   (the best mapping)
      lk_transfer/3         -- +Mapping, +Term, -Image        (carry a term across)
*/

% Declare this module and its exported predicates.
:- module(co_liken, [
    % lk_objects/2: the distinct objects mentioned by a relation set.
    lk_objects/2,
    % lk_map_object/3: apply a mapping to a single object.
    lk_map_object/3,
    % lk_preserved/4: how many source relations line up under a mapping.
    lk_preserved/4,
    % lk_analogy/4: the object mapping that preserves the most relations.
    lk_analogy/4,
    % lk_transfer/3: carry a fact from source objects to their target images.
    lk_transfer/3
]).

% Use the list library for member, select, and friends.
:- use_module(library(lists)).

% lk_objects/2: gather the distinct objects that appear in a relation set.
lk_objects(Relations, Objects) :-
    % Collect both argument positions of every relation.
    findall(O, ( member(rel(_, A, B), Relations), ( O = A ; O = B ) ), Raw),
    % Sort to a distinct, ordered set.
    sort(Raw, Objects).

% lk_map_object/3: an object's image under a mapping (a list of Src-Tgt pairs).
lk_map_object(Mapping, Object, Image) :-
    % Look the object up in the mapping.
    memberchk(Object-Image, Mapping).

% lk_preserved/4: count the source relations that line up in the target.
lk_preserved(Mapping, Source, Target, Count) :-
    % A source relation is preserved when its mapped image is a target relation.
    findall(1,
            ( member(rel(Type, A, B), Source),
              lk_map_object(Mapping, A, TA),
              lk_map_object(Mapping, B, TB),
              memberchk(rel(Type, TA, TB), Target) ),
            Hits),
    % The count is how many lined up.
    length(Hits, Count).

% lk_analogy/4: the injective object mapping that preserves the most relations.
lk_analogy(Source, Target, Mapping, Score) :-
    % Enumerate the objects on each side.
    lk_objects(Source, SrcObjs),
    lk_objects(Target, TgtObjs),
    % Keep the search tractable: the source must be small and no larger than the target.
    length(SrcObjs, NS),
    NS =< 7,
    length(TgtObjs, NT),
    NS =< NT,
    % Score every injective mapping of source objects onto target objects.
    findall(S-M,
            ( lk_injective(SrcObjs, TgtObjs, M),
              lk_preserved(M, Source, Target, S) ),
            Pairs),
    % There must be at least one mapping.
    Pairs = [_|_],
    % Take the highest-scoring mapping (ties broken by enumeration order).
    sort(1, @>=, Pairs, [Score-Mapping|_]).

% lk_transfer/3: carry a term from source objects to their target images.
lk_transfer(Mapping, Term, Image) :-
    % A mapped object becomes its image directly.
    ( memberchk(Term-Image, Mapping)
      -> true
    % A compound term is transferred argument by argument.
    ; compound(Term)
      -> Term =.. [Functor | Args],
         maplist(lk_transfer(Mapping), Args, MappedArgs),
         Image =.. [Functor | MappedArgs]
    % Anything else (an unmapped atom or number) passes through unchanged.
    ; Image = Term ).

% ---- internal --------------------------------------------------------------

% lk_injective/3: assign each source object a distinct target object.
lk_injective([], _, []).
% Pick a still-unused target for the head, then map the rest from the remainder.
lk_injective([S | Ss], Targets, [S-T | Mapping]) :-
    select(T, Targets, Remaining),
    lk_injective(Ss, Remaining, Mapping).
