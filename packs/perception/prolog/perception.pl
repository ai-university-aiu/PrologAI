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

% Declare this file as the 'perception' module and list its exported predicates.
:- module(perception, [
    % Supply 'pai_detect/3' as the next argument to the expression above.
    pai_detect/3,
    % Supply 'pai_locate/2' as the next argument to the expression above.
    pai_locate/2,
    % Supply 'pai_map_update/2' as the next argument to the expression above.
    pai_map_update/2,
    % Supply 'pai_venue_of/2' as the next argument to the expression above.
    pai_venue_of/2,
    % Supply 'pai_locale_of/2' as the next argument to the expression above.
    pai_locale_of/2
% Close the expression opened above.
]).

% Import [member/2, intersection/3, union/3] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2, intersection/3, union/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Storage
% ---------------------------------------------------------------------------

% Declare 'percept_traits/3.   % PercId, Detector, TraitList' as dynamic — its facts may be added or removed at runtime.
:- dynamic percept_traits/3.   % PercId, Detector, TraitList
% Declare 'scene_record/3.     % SceneId, TraitSet, Timestamp' as dynamic — its facts may be added or removed at runtime.
:- dynamic scene_record/3.     % SceneId, TraitSet, Timestamp
% Declare 'venue_record/3.     % VenueId, CentroidTraits, SceneIds' as dynamic — its facts may be added or removed at runtime.
:- dynamic venue_record/3.     % VenueId, CentroidTraits, SceneIds
% Declare 'venue_locale/2.     % VenueId, LocaleId' as dynamic — its facts may be added or removed at runtime.
:- dynamic venue_locale/2.     % VenueId, LocaleId
% Declare 'locale_place/2.     % LocaleId, PlaceId' as dynamic — its facts may be added or removed at runtime.
:- dynamic locale_place/2.     % LocaleId, PlaceId
% Declare 'venue_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic venue_id_counter/1.
% Declare 'locale_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic locale_id_counter/1.
% Declare 'scene_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic scene_id_counter/1.

% State the fact: venue id counter(0).
venue_id_counter(0).
% State the fact: locale id counter(0).
locale_id_counter(0).
% State the fact: scene id counter(0).
scene_id_counter(0).

% Define a clause for 'next id': succeed when the following conditions hold.
next_id(Counter, Id) :-
    % State a fact for 'functor' with the arguments listed below.
    functor(Counter, _,_),
    % Execute: ( retract(Counter).
    ( retract(Counter)
    % If the condition above succeeded, perform the following action.
    ->  Counter =.. [F, N]
    % Otherwise (else branch), perform the following action.
    ;   N = 0, functor(Counter, F, _)
    % Close the expression opened above.
    ),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Execute: NC =.. [F, N1],.
    NC =.. [F, N1],
    % Add a new fact or rule to the runtime knowledge base.
    assertz(NC),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% Define a clause for 'next venue id': succeed when the following conditions hold.
next_venue_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(venue_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(venue_id_counter(N1)),
    % State the fact: atomic list concat([venue_, N1], Id).
    atomic_list_concat([venue_, N1], Id).

% Define a clause for 'next locale id': succeed when the following conditions hold.
next_locale_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(locale_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(locale_id_counter(N1)),
    % State the fact: atomic list concat([locale_, N1], Id).
    atomic_list_concat([locale_, N1], Id).

% Define a clause for 'next scene id': succeed when the following conditions hold.
next_scene_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(scene_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(scene_id_counter(N1)),
    % State the fact: atomic list concat([scene_, N1], Id).
    atomic_list_concat([scene_, N1], Id).

% Similarity threshold for venue merging
% Check that 'venue_merge_threshold(0.3).  % Jaccard similarity' is greater than or equal to 'this → same venue'.
venue_merge_threshold(0.3).  % Jaccard similarity >= this → same venue

% ---------------------------------------------------------------------------
% pai_detect/3
%
%   PerceptRef: an atom identifying a percept (e.g. clip_001)
%   DetectorList: list of detector names to apply; [] = all detectors
%   TraitSets: list of trait_set(Detector, Traits) terms
% ---------------------------------------------------------------------------

% Define a clause for 'pai detect': succeed when the following conditions hold.
pai_detect(PerceptRef, DetectorList, TraitSets) :-
    % Check that '( DetectorList' is unifiable with '[]'.
    ( DetectorList = []
    % If the condition above succeeded, perform the following action.
    ->  Detectors = [icon, geon, shape, object, scene, image_schema]
    % Otherwise (else branch), perform the following action.
    ;   Detectors = DetectorList
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(trait_set(Det, Traits), (
        % Continue the multi-line expression started above.
        member(Det, Detectors),
        % Continue the multi-line expression started above.
        run_detector(Det, PerceptRef, Traits),
        % Store traits (append-only; all disagreements preserved)
        % Continue the multi-line expression started above.
        assertz(percept_traits(PerceptRef, Det, Traits))
    % Continue the multi-line expression started above.
    ), TraitSets).

% Each detector applies feature extraction rules to the percept reference.
% In the absence of actual sensor input, we simulate by hashing the
% percept ref atom to derive deterministic pseudo-features.

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(icon, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, icon, OldTraits).
    ( percept_traits(Ref, icon, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits  % idempotent
    % Otherwise (else branch), perform the following action.
    ;   hash_features(Ref, icon, Traits)
    % Close the expression opened above.
    ).

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(geon, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, geon, OldTraits).
    ( percept_traits(Ref, geon, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits
    % Otherwise (else branch), perform the following action.
    ;   hash_features(Ref, geon, Traits)
    % Close the expression opened above.
    ).

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(shape, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, shape, OldTraits).
    ( percept_traits(Ref, shape, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits
    % Otherwise (else branch), perform the following action.
    ;   hash_features(Ref, shape, Traits)
    % Close the expression opened above.
    ).

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(object, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, object, OldTraits).
    ( percept_traits(Ref, object, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits
    % Otherwise (else branch), perform the following action.
    ;   hash_features(Ref, object, Traits)
    % Close the expression opened above.
    ).

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(scene, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, scene, OldTraits).
    ( percept_traits(Ref, scene, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits
    % Otherwise (else branch), perform the following action.
    ;   % Scene detector: four background hashes + foveal blackout
        % Continue the multi-line expression started above.
        term_hash(Ref, H),
        % Continue the multi-line expression started above.
        H1 is H mod 1000,
        % Continue the multi-line expression started above.
        H2 is (H div 7) mod 1000,
        % Continue the multi-line expression started above.
        H3 is (H div 13) mod 1000,
        % Continue the multi-line expression started above.
        H4 is (H div 17) mod 1000,
        % Continue the multi-line expression started above.
        Traits = [hash_avg(H1), hash_perc(H2), hash_diff(H3), hash_wav(H4),
                  % Continue the multi-line expression started above.
                  foveal(blackout)]
    % Close the expression opened above.
    ).

% Define a clause for 'run detector': succeed when the following conditions hold.
run_detector(image_schema, Ref, Traits) :-
    % Execute: ( percept_traits(Ref, image_schema, OldTraits).
    ( percept_traits(Ref, image_schema, OldTraits)
    % If the condition above succeeded, perform the following action.
    ->  Traits = OldTraits
    % Otherwise (else branch), perform the following action.
    ;   hash_features(Ref, image_schema, Traits)
    % Close the expression opened above.
    ).

% Simulate features by hashing percept ref + detector name
% Define a clause for 'hash features': succeed when the following conditions hold.
hash_features(Ref, Det, Traits) :-
    % State a fact for 'term hash' with the arguments listed below.
    term_hash(Ref-Det, H),
    % Check that 'Vocab' is unifiable with '[edge, corner, curve, cylinder, block, sphere'.
    Vocab = [edge, corner, curve, cylinder, block, sphere,
             % Continue the multi-line expression started above.
             inside, on, beside, path, up, down, near, far,
             % Continue the multi-line expression started above.
             small, large, bright, dark, textured, smooth],
    % Unify 'VLen' with the number of elements in list 'Vocab'.
    length(Vocab, VLen),
    % Evaluate the arithmetic expression '(H mod VLen) + 1' and bind the result to 'Idx1'.
    Idx1 is (H mod VLen) + 1,
    % Evaluate the arithmetic expression '((H div 7) mod VLen) + 1' and bind the result to 'Idx2'.
    Idx2 is ((H div 7) mod VLen) + 1,
    % Evaluate the arithmetic expression '((H div 13) mod VLen) + 1' and bind the result to 'Idx3'.
    Idx3 is ((H div 13) mod VLen) + 1,
    % Retrieve the element at the specified one-based position from the list.
    nth1(Idx1, Vocab, F1),
    % Retrieve the element at the specified one-based position from the list.
    nth1(Idx2, Vocab, F2),
    % Retrieve the element at the specified one-based position from the list.
    nth1(Idx3, Vocab, F3),
    % State the fact: sort([F1, F2, F3], Traits).
    sort([F1, F2, F3], Traits).

% Retrieve the element at the specified one-based position from the list.
nth1(1, [H|_], H) :- !.
% Check that 'nth1(N, [_|T], E) :- N' is greater than '1, N1 is N - 1, nth1(N1, T, E)'.
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

% Define a clause for 'pai locate': succeed when the following conditions hold.
pai_locate(SceneTraits, VenueId) :-
    % Assign a scene ID for this observation
    % State a fact for 'next scene id' with the arguments listed below.
    next_scene_id(SId),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(scene_record(SId, SceneTraits, T)),
    % Find best-matching venue
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Sim-Vid, (
        % Continue the multi-line expression started above.
        venue_record(Vid, Centroid, _),
        % Continue the multi-line expression started above.
        jaccard(SceneTraits, Centroid, Sim)
    % Continue the multi-line expression started above.
    ), Candidates),
    % State a fact for 'venue merge threshold' with the arguments listed below.
    venue_merge_threshold(Thresh),
    % Check that '( Candidates' is not unifiable with '[]'.
    ( Candidates \= [],
      % Continue the multi-line expression started above.
      msort(Candidates, Sorted),
      % Continue the multi-line expression started above.
      last(Sorted, BestSim-BestVid),
      % Continue the multi-line expression started above.
      BestSim >= Thresh
    % If the condition above succeeded, perform the following action.
    ->  % Merge into existing venue: update centroid (union of traits)
        % Continue the multi-line expression started above.
        VenueId = BestVid,
        % Continue the multi-line expression started above.
        retract(venue_record(BestVid, OldCentroid, OldScenes)),
        % Continue the multi-line expression started above.
        union(OldCentroid, SceneTraits, NewCentroid),
        % Continue the multi-line expression started above.
        assertz(venue_record(BestVid, NewCentroid, [SId|OldScenes]))
    % Otherwise (else branch), perform the following action.
    ;   % New venue
        % Continue the multi-line expression started above.
        next_venue_id(VenueId),
        % Continue the multi-line expression started above.
        assertz(venue_record(VenueId, SceneTraits, [SId]))
    % Close the expression opened above.
    ).

% Define a clause for 'jaccard': succeed when the following conditions hold.
jaccard(A, B, Sim) :-
    % State a fact for 'intersection' with the arguments listed below.
    intersection(A, B, Inter),
    % State a fact for 'union' with the arguments listed below.
    union(A, B, Uni),
    % Unify 'NI' with the number of elements in list 'Inter'.
    length(Inter, NI),
    % Unify 'NU' with the number of elements in list 'Uni'.
    length(Uni, NU),
    % Check that '( NU' is greater than '0 -> Sim is NI / NU ; Sim = 0.0 )'.
    ( NU > 0 -> Sim is NI / NU ; Sim = 0.0 ).

% Define a clause for 'last': succeed when the following conditions hold.
last([X], X) :- !.
% Define a clause for 'last': succeed when the following conditions hold.
last([_|T], X) :- last(T, X).

% ---------------------------------------------------------------------------
% pai_map_update/2
%
%   Attach a venue to a locale, and locale to a place in the map hierarchy.
% ---------------------------------------------------------------------------

% Define a clause for 'pai map update': succeed when the following conditions hold.
pai_map_update(VenueId, LocaleHint) :-
    % Check that '( LocaleHint' is unifiable with 'locale(LId)'.
    ( LocaleHint = locale(LId)
    % If the condition above succeeded, perform the following action.
    ->  ( venue_locale(VenueId, LId) -> true
        % Otherwise (else branch), perform the following action.
        ; assertz(venue_locale(VenueId, LId))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   % No explicit locale: create one or reuse if venue already has one
        % Continue the multi-line expression started above.
        ( venue_locale(VenueId, _)
        % If the condition above succeeded, perform the following action.
        ->  true
        % Otherwise (else branch), perform the following action.
        ;   next_locale_id(NewLId),
            % Continue the multi-line expression started above.
            assertz(venue_locale(VenueId, NewLId))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_venue_of/2 and pai_locale_of/2 — queries
% ---------------------------------------------------------------------------

% Define a clause for 'pai venue of': succeed when the following conditions hold.
pai_venue_of(SceneId, VenueId) :-
    % State a fact for 'venue record' with the arguments listed below.
    venue_record(VenueId, _, Scenes),
    % State the fact: memberchk(SceneId, Scenes).
    memberchk(SceneId, Scenes).

% Define a clause for 'pai locale of': succeed when the following conditions hold.
pai_locale_of(VenueId, LocaleId) :-
    % Execute: ( venue_locale(VenueId, LocaleId).
    ( venue_locale(VenueId, LocaleId)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   LocaleId = unassigned
    % Close the expression opened above.
    ).
