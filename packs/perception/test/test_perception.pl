/*  PrologAI — Perceptual Detector Suite Test Suite  (PR 30)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/perception/test/test_perception.pl

    Exercises the six specialist detectors, the Jaccard-based locator, the
    map hierarchy, and the two query predicates with real assertions on
    their outputs.
*/

% Declare this file as a test module.
:- module(test_perception, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(perception)).

% Reset the perception module's private dynamic state to a clean slate.
perception_test_reset :-
    % Clear all stored per-detector traits.
    retractall(perception:percept_traits(_, _, _)),
    % Clear all recorded scenes.
    retractall(perception:scene_record(_, _, _)),
    % Clear all recorded venues.
    retractall(perception:venue_record(_, _, _)),
    % Clear all venue-to-locale attachments.
    retractall(perception:venue_locale(_, _)),
    % Clear all locale-to-place attachments.
    retractall(perception:locale_place(_, _)),
    % Clear the shared venue/scene id counter.
    retractall(perception:perception_id_counter(_)),
    % Clear the locale id counter.
    retractall(perception:locale_id_counter(_)),
    % Seed the shared venue/scene id counter at zero.
    assertz(perception:perception_id_counter(0)),
    % Seed the locale id counter at zero.
    assertz(perception:locale_id_counter(0)).

% Open the test block for perception, resetting state once up front.
:- begin_tests(perception, [setup(perception_test_reset)]).

% AC-PERC-001: perception_detect returns one trait_set per requested detector.
test(detect_returns_trait_sets, [setup(perception_test_reset)]) :-
    % Run the icon and shape detectors on a percept reference.
    perception_detect(office_clip, [icon, shape], TraitSets),
    % Exactly two trait sets come back, one per requested detector.
    assertion(length(TraitSets, 2)),
    % The icon detector's trait set is present.
    assertion(memberchk(trait_set(icon, _), TraitSets)),
    % The shape detector's trait set is present.
    assertion(memberchk(trait_set(shape, _), TraitSets)).

% AC-PERC-002: the scene detector yields four background hashes plus a foveal blackout.
test(scene_detector_four_hashes, [setup(perception_test_reset)]) :-
    % Run just the scene detector on a percept reference.
    perception_detect(hall_clip, [scene], TraitSets),
    % Pull out the scene detector's trait list.
    memberchk(trait_set(scene, Traits), TraitSets),
    % The average-hash trait is present.
    assertion(memberchk(hash_avg(_), Traits)),
    % The perceptual-hash trait is present.
    assertion(memberchk(hash_perc(_), Traits)),
    % The difference-hash trait is present.
    assertion(memberchk(hash_diff(_), Traits)),
    % The wavelet-hash trait is present.
    assertion(memberchk(hash_wav(_), Traits)),
    % The foveal blackout marker is present.
    assertion(memberchk(foveal(blackout), Traits)).

% AC-PERC-003: repeated detection on the same reference returns identical traits.
test(detect_idempotent, [setup(perception_test_reset)]) :-
    % Detect shape traits on a reference the first time.
    perception_detect(repeat_clip, [shape], TS1),
    % Detect shape traits on the same reference a second time.
    perception_detect(repeat_clip, [shape], TS2),
    % Read the shape traits from the first run.
    memberchk(trait_set(shape, T1), TS1),
    % Read the shape traits from the second run.
    memberchk(trait_set(shape, T2), TS2),
    % Both runs produce the same trait list.
    assertion(T1 == T2).

% AC-PERC-004: traits from every requested detector are stored, disagreements preserved.
test(all_detector_traits_stored, [setup(perception_test_reset)]) :-
    % Run the geon and object detectors on a reference.
    perception_detect(lab_clip, [geon, object], _),
    % The geon detector's traits were persisted.
    assertion(perception:percept_traits(lab_clip, geon, _)),
    % The object detector's traits were persisted.
    assertion(perception:percept_traits(lab_clip, object, _)).

% AC-PERC-005: two scenes with identical traits merge into one venue.
test(identical_traits_same_venue, [setup(perception_test_reset)]) :-
    % Locate a scene with a fixed trait list, creating the first venue.
    perception_locate([edge, corner], V1),
    % Locate a second scene with the same traits (Jaccard 1.0 >= threshold).
    perception_locate([edge, corner], V2),
    % Both scenes attach to the same venue.
    assertion(V1 == V2).

% AC-PERC-006: a located scene is retrievable by its scene id, and locales attach on demand.
test(venue_of_and_locale_lifecycle, [setup(perception_test_reset)]) :-
    % Locate a scene, creating a venue for it.
    perception_locate([bright, large], V),
    % Read the scene id the locator recorded for that venue.
    perception:venue_record(V, _, [SId|_]),
    % Querying the venue by that scene id returns the same venue.
    perception_venue_of(SId, VBack),
    % The round-trip lands on the original venue.
    assertion(VBack == V),
    % A fresh venue has no locale, so the query reports it unassigned.
    perception_locale_of(V, LBefore),
    % Confirm the unmapped venue reads as unassigned.
    assertion(LBefore == unassigned),
    % Attach the venue to a named locale in the map hierarchy.
    perception_map_update(V, locale(kitchen)),
    % Query the locale again now that a mapping exists.
    perception_locale_of(V, LAfter),
    % The venue now reports the locale it was attached to.
    assertion(LAfter == kitchen).

% Close the test block for perception.
:- end_tests(perception).
