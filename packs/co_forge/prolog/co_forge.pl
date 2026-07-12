/*  PrologAI — Causalontology Concept Formation  (WP-420, Layer 395)

    THE_BUILDING_FILES describe a mind that grows its own ontology: it watches a
    stream of things, notices which of them share enough features to be worth a
    common name, and coins a category. The co_ family had a hand-built noun
    backbone (co_noun) but nothing that induced a new concept from experience.
    This pack is that inducer, kept small and glass-box.

    Each observed item is a bundle of feature atoms:

        item(Id, Features)

    Concept induction is a transparent seed clustering. Taking items in order,
    each still-ungrouped item seeds a group and pulls in every later item that
    keeps the group's shared-feature set at or above a floor (MinShared). A group
    of two or more items whose shared core is still at least MinShared features
    becomes a concept:

        concept(ConceptId, SharedFeatures, Members)

    The SharedFeatures are the concept's defining core — the intension — and the
    Members are its examples — the extension. A new item is classified into a
    concept when the concept's defining core is a subset of the item's features.

    Predicates:
      fg_reset/0            -- forget all items and concept identifiers
      fg_observe/2          -- +ItemId, +Features   (record or replace an item)
      fg_item/2             -- ?ItemId, ?Features
      fg_shared/3           -- +IdA, +IdB, -SharedFeatures
      fg_induce/2           -- +MinShared, -Concepts        (seed-cluster the items)
      fg_classify/3         -- +Features, +Concepts, -ConceptId  (which concept fits?)
      fg_count/1            -- -N                            (how many items observed)
*/

% Declare this module and its exported predicates.
:- module(co_forge, [
    % fg_reset/0: forget all items and reset concept ids.
    fg_reset/0,
    % fg_observe/2: record or replace an observed item.
    fg_observe/2,
    % fg_item/2: query observed items.
    fg_item/2,
    % fg_shared/3: the features two items share.
    fg_shared/3,
    % fg_induce/2: induce concepts by seed clustering.
    fg_induce/2,
    % fg_classify/3: which induced concept a feature bundle fits.
    fg_classify/3,
    % fg_count/1: how many items are observed.
    fg_count/1
]).

% Use the ordered-set library for intersection and subset over sorted lists.
:- use_module(library(ordsets)).
% Use the list library.
:- use_module(library(lists)).
% Use gensym to mint fresh concept identifiers.
:- use_module(library(gensym)).

% item/2 is one observed feature bundle; it changes at runtime, so it is dynamic.
:- dynamic item/2.

% fg_reset/0: forget every item and restart the concept-id counter.
fg_reset :-
    % Remove all items.
    retractall(item(_,_)),
    % Restart the concept identifier sequence.
    reset_gensym(con_).

% fg_observe/2: record an item, replacing any earlier bundle for the same id.
fg_observe(ItemId, Features) :-
    % Normalise the features into a sorted set.
    sort(Features, Sorted),
    % Drop any previous bundle for this id.
    retractall(item(ItemId, _)),
    % Store the item.
    assertz(item(ItemId, Sorted)).

% fg_item/2: expose the observed items.
fg_item(ItemId, Features) :-
    % Read the stored item.
    item(ItemId, Features).

% fg_shared/3: the features two items have in common.
fg_shared(IdA, IdB, Shared) :-
    % Fetch both bundles.
    item(IdA, FA),
    item(IdB, FB),
    % Intersect their sorted feature sets.
    ord_intersection(FA, FB, Shared).

% fg_induce/2: induce concepts from the items by seed clustering.
fg_induce(MinShared, Concepts) :-
    % Take the item ids in a stable sorted order.
    findall(Id, item(Id, _), Ids0),
    sort(Ids0, Ids),
    % Cluster them.
    fg_cluster(Ids, MinShared, Concepts).

% fg_classify/3: the first concept whose defining core fits the given features.
fg_classify(Features, Concepts, ConceptId) :-
    % Normalise the features into a sorted set.
    sort(Features, FeatSet),
    % Find a concept whose shared core is a subset of the item's features.
    member(concept(ConceptId, Shared, _), Concepts),
    ord_subset(Shared, FeatSet),
    % Commit to the first such concept.
    !.

% fg_count/1: how many items have been observed.
fg_count(N) :-
    % Count the item facts.
    aggregate_all(count, item(_,_), N).

% ---- internal --------------------------------------------------------------

% fg_cluster/3: seed-cluster a list of item ids into concepts.
% No items left means no concepts.
fg_cluster([], _, []).
% Otherwise the head seeds a group and pulls in compatible later items.
fg_cluster([Seed | Rest], MinShared, Concepts) :-
    % The seed's own features start the group's shared core.
    item(Seed, SeedFeats),
    % Grow the group over the remaining items, tracking what stays shared.
    fg_grow(Rest, SeedFeats, MinShared, Members, SharedCore, Leftover),
    % A concept needs two or more members and a core of at least MinShared.
    length([Seed | Members], Size),
    length(SharedCore, CoreSize),
    ( Size >= 2, CoreSize >= MinShared
      -> % Coin a concept from the seed and the members it gathered.
         gensym(con_, ConceptId),
         sort([Seed | Members], Group),
         Concepts = [concept(ConceptId, SharedCore, Group) | More],
         % Continue clustering whatever was left over.
         fg_cluster(Leftover, MinShared, More)
      ;  % The seed formed no concept; drop it and continue with the rest.
         fg_cluster(Rest, MinShared, Concepts) ).

% fg_grow/6: pull later items into a group while the shared core holds.
% No candidates left: the members and the core are settled, nothing left over.
fg_grow([], Core, _, [], Core, []).
% Otherwise test the next candidate against the running shared core.
fg_grow([C | Cs], Core, MinShared, Members, FinalCore, Leftover) :-
    % What would the item share with the group so far?
    item(C, CF),
    ord_intersection(Core, CF, NewCore),
    length(NewCore, NL),
    ( NL >= MinShared
      -> % It keeps the core big enough: take it into the group.
         Members = [C | Ms],
         fg_grow(Cs, NewCore, MinShared, Ms, FinalCore, Leftover)
      ;  % It would dilute the core: leave it for a later seed.
         Leftover = [C | Lo],
         fg_grow(Cs, Core, MinShared, Members, FinalCore, Lo) ).
