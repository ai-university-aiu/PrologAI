/*  PrologAI — Perceptual Detector Suite  (Specification PR 30)

    Specialist detectors extract traits from percept references; all
    traits are stored even when detectors disagree; later coordination
    resolves or tolerates them.

    Detectors (each returns a trait list):
        icon_detector    — known-image matching
        geon_detector    — volumetric primitives (block, cylinder, sphere, …)
        shape_detector   — 2D shapes (edge, corner, curve, …)
        object_detector  — named objects
        scene_detector   — four-way background hash + foveal blackout
        image_schema     — spatial arrangements (inside, on, beside, path, …)

    Locator:
        Attaches scenes to venues (groups of co-located scenes) and venues
        to locales.  Merges venues by scene similarity (cosine of shared
        trait overlap) rather than trusting raw odometry — drift guard.

    Mapper:
        Maintains a hierarchy: locale → place → area → region → map.

    Predicates:
        pai_detect/3        — +PerceptRef, +DetectorList, -TraitSets
        pai_locate/2        — +SceneTraits, -VenueId
        pai_map_update/2    — +VenueId, +LocaleHint
        pai_venue_of/2      — +SceneId, -VenueId (query)
        pai_locale_of/2     — +VenueId, -LocaleId (query)
*/

:- module(perception, [
    pai_detect/3,
    pai_locate/2,
    pai_map_update/2,
    pai_venue_of/2,
    pai_locale_of/2
]).

:- use_module(library(lists),     [member/2, intersection/3, union/3]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Storage
% ---------------------------------------------------------------------------

:- dynamic percept_traits/3.   % PercId, Detector, TraitList
:- dynamic scene_record/3.     % SceneId, TraitSet, Timestamp
:- dynamic venue_record/3.     % VenueId, CentroidTraits, SceneIds
:- dynamic venue_locale/2.     % VenueId, LocaleId
:- dynamic locale_place/2.     % LocaleId, PlaceId
:- dynamic venue_id_counter/1.
:- dynamic locale_id_counter/1.
:- dynamic scene_id_counter/1.

venue_id_counter(0).
locale_id_counter(0).
scene_id_counter(0).

next_id(Counter, Id) :-
    functor(Counter, _,_),
    ( retract(Counter)
    ->  Counter =.. [F, N]
    ;   N = 0, functor(Counter, F, _)
    ),
    N1 is N + 1,
    NC =.. [F, N1],
    assertz(NC),
    Id = N1.

next_venue_id(Id) :-
    retract(venue_id_counter(N)),
    N1 is N + 1,
    assertz(venue_id_counter(N1)),
    atomic_list_concat([venue_, N1], Id).

next_locale_id(Id) :-
    retract(locale_id_counter(N)),
    N1 is N + 1,
    assertz(locale_id_counter(N1)),
    atomic_list_concat([locale_, N1], Id).

next_scene_id(Id) :-
    retract(scene_id_counter(N)),
    N1 is N + 1,
    assertz(scene_id_counter(N1)),
    atomic_list_concat([scene_, N1], Id).

% Similarity threshold for venue merging
venue_merge_threshold(0.3).  % Jaccard similarity >= this → same venue

% ---------------------------------------------------------------------------
% pai_detect/3
%
%   PerceptRef: an atom identifying a percept (e.g. clip_001)
%   DetectorList: list of detector names to apply; [] = all detectors
%   TraitSets: list of trait_set(Detector, Traits) terms
% ---------------------------------------------------------------------------

pai_detect(PerceptRef, DetectorList, TraitSets) :-
    ( DetectorList = []
    ->  Detectors = [icon, geon, shape, object, scene, image_schema]
    ;   Detectors = DetectorList
    ),
    findall(trait_set(Det, Traits), (
        member(Det, Detectors),
        run_detector(Det, PerceptRef, Traits),
        % Store traits (append-only; all disagreements preserved)
        assertz(percept_traits(PerceptRef, Det, Traits))
    ), TraitSets).

% Each detector applies feature extraction rules to the percept reference.
% In the absence of actual sensor input, we simulate by hashing the
% percept ref atom to derive deterministic pseudo-features.

run_detector(icon, Ref, Traits) :-
    ( percept_traits(Ref, icon, OldTraits)
    ->  Traits = OldTraits  % idempotent
    ;   hash_features(Ref, icon, Traits)
    ).

run_detector(geon, Ref, Traits) :-
    ( percept_traits(Ref, geon, OldTraits)
    ->  Traits = OldTraits
    ;   hash_features(Ref, geon, Traits)
    ).

run_detector(shape, Ref, Traits) :-
    ( percept_traits(Ref, shape, OldTraits)
    ->  Traits = OldTraits
    ;   hash_features(Ref, shape, Traits)
    ).

run_detector(object, Ref, Traits) :-
    ( percept_traits(Ref, object, OldTraits)
    ->  Traits = OldTraits
    ;   hash_features(Ref, object, Traits)
    ).

run_detector(scene, Ref, Traits) :-
    ( percept_traits(Ref, scene, OldTraits)
    ->  Traits = OldTraits
    ;   % Scene detector: four background hashes + foveal blackout
        term_hash(Ref, H),
        H1 is H mod 1000,
        H2 is (H div 7) mod 1000,
        H3 is (H div 13) mod 1000,
        H4 is (H div 17) mod 1000,
        Traits = [hash_avg(H1), hash_perc(H2), hash_diff(H3), hash_wav(H4),
                  foveal(blackout)]
    ).

run_detector(image_schema, Ref, Traits) :-
    ( percept_traits(Ref, image_schema, OldTraits)
    ->  Traits = OldTraits
    ;   hash_features(Ref, image_schema, Traits)
    ).

% Simulate features by hashing percept ref + detector name
hash_features(Ref, Det, Traits) :-
    term_hash(Ref-Det, H),
    Vocab = [edge, corner, curve, cylinder, block, sphere,
             inside, on, beside, path, up, down, near, far,
             small, large, bright, dark, textured, smooth],
    length(Vocab, VLen),
    Idx1 is (H mod VLen) + 1,
    Idx2 is ((H div 7) mod VLen) + 1,
    Idx3 is ((H div 13) mod VLen) + 1,
    nth1(Idx1, Vocab, F1),
    nth1(Idx2, Vocab, F2),
    nth1(Idx3, Vocab, F3),
    sort([F1, F2, F3], Traits).

nth1(1, [H|_], H) :- !.
nth1(N, [_|T], E) :- N > 1, N1 is N - 1, nth1(N1, T, E).

% ---------------------------------------------------------------------------
% pai_locate/2
%
%   SceneTraits: flat list of trait atoms (the union across all detectors)
%   VenueId:     atom identifying the venue this scene belongs to.
%
%   Algorithm:
%     1. Compute Jaccard similarity of SceneTraits against each existing venue.
%     2. If best match >= venue_merge_threshold → assign to that venue.
%     3. Otherwise → create a new venue.
% ---------------------------------------------------------------------------

pai_locate(SceneTraits, VenueId) :-
    % Assign a scene ID for this observation
    next_scene_id(SId),
    get_time(T),
    assertz(scene_record(SId, SceneTraits, T)),
    % Find best-matching venue
    findall(Sim-Vid, (
        venue_record(Vid, Centroid, _),
        jaccard(SceneTraits, Centroid, Sim)
    ), Candidates),
    venue_merge_threshold(Thresh),
    ( Candidates \= [],
      msort(Candidates, Sorted),
      last(Sorted, BestSim-BestVid),
      BestSim >= Thresh
    ->  % Merge into existing venue: update centroid (union of traits)
        VenueId = BestVid,
        retract(venue_record(BestVid, OldCentroid, OldScenes)),
        union(OldCentroid, SceneTraits, NewCentroid),
        assertz(venue_record(BestVid, NewCentroid, [SId|OldScenes]))
    ;   % New venue
        next_venue_id(VenueId),
        assertz(venue_record(VenueId, SceneTraits, [SId]))
    ).

jaccard(A, B, Sim) :-
    intersection(A, B, Inter),
    union(A, B, Uni),
    length(Inter, NI),
    length(Uni, NU),
    ( NU > 0 -> Sim is NI / NU ; Sim = 0.0 ).

last([X], X) :- !.
last([_|T], X) :- last(T, X).

% ---------------------------------------------------------------------------
% pai_map_update/2
%
%   Attach a venue to a locale, and locale to a place in the map hierarchy.
% ---------------------------------------------------------------------------

pai_map_update(VenueId, LocaleHint) :-
    ( LocaleHint = locale(LId)
    ->  ( venue_locale(VenueId, LId) -> true
        ; assertz(venue_locale(VenueId, LId))
        )
    ;   % No explicit locale: create one or reuse if venue already has one
        ( venue_locale(VenueId, _)
        ->  true
        ;   next_locale_id(NewLId),
            assertz(venue_locale(VenueId, NewLId))
        )
    ).

% ---------------------------------------------------------------------------
% pai_venue_of/2 and pai_locale_of/2 — queries
% ---------------------------------------------------------------------------

pai_venue_of(SceneId, VenueId) :-
    venue_record(VenueId, _, Scenes),
    memberchk(SceneId, Scenes).

pai_locale_of(VenueId, LocaleId) :-
    ( venue_locale(VenueId, LocaleId)
    ->  true
    ;   LocaleId = unassigned
    ).
