/*  PrologAI — Developmental Language Acquisition Test Suite  (PR 31)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/acquisition/test/test_acquisition.pl

    Exercises the core exported predicates of the acquisition pack:
      acquisition_chain_phonemes/2, acquisition_ground/3,
      acquisition_grounding_of/2, acquisition_symbolize/3,
      acquisition_chain_promote/2, acquisition_word_of/2.
*/

% Declare this file as a test module.
:- module(test_acquisition, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(acquisition)).

% Reset the acquisition module's internal dynamic state to a clean slate.
test_acquisition_reset :-
    % Clear any recorded phoneme chains.
    retractall(acquisition:phoneme_chain(_, _, _)),
    % Clear any promoted word forms.
    retractall(acquisition:word_form(_, _, _)),
    % Clear any word-to-percept groundings.
    retractall(acquisition:word_grounding(_, _, _)),
    % Clear any signifier-to-signified symbolisms.
    retractall(acquisition:symbolism(_, _, _, _)),
    % Clear any promoted higher-tier units.
    retractall(acquisition:tier_unit(_, _, _)),
    % Remove the current id counter.
    retractall(acquisition:acquisition_id_counter(_)),
    % Reinstate the id counter at zero.
    assertz(acquisition:acquisition_id_counter(0)).

% Open the test block for acquisition.
:- begin_tests(acquisition).

% AC-001: fewer than three observations yield no word candidate.
test(no_word_before_threshold, [setup(test_acquisition_reset)]) :-
    % Hear the phoneme series once.
    acquisition_chain_phonemes([b, ir, d], First),
    % The first hearing promotes nothing.
    assertion(First == []),
    % Hear the same series a second time.
    acquisition_chain_phonemes([b, ir, d], Second),
    % The second hearing still promotes nothing.
    assertion(Second == []).

% AC-002: the third observation promotes a word candidate with its count.
test(word_promoted_at_threshold, [setup(test_acquisition_reset)]) :-
    % Hear the series a first time.
    acquisition_chain_phonemes([d, ae, g], _),
    % Hear the series a second time.
    acquisition_chain_phonemes([d, ae, g], _),
    % Hear the series a third time, reaching the promotion threshold.
    acquisition_chain_phonemes([d, ae, g], Candidates),
    % The third hearing emits exactly the promoted word with count three.
    assertion(Candidates == [word('d-ae-g', 3)]).

% AC-003: grounding a word to a percept is recoverable by query.
test(ground_and_query, [setup(test_acquisition_reset)]) :-
    % Ground the word "apple" to a percept reference.
    acquisition_ground(apple, apple_image_42, GId),
    % The grounding returns a concrete identifier.
    assertion(integer(GId)),
    % Querying the word returns the grounded percept.
    findall(P, acquisition_grounding_of(apple, P), Percepts),
    % The only grounded percept is the one just asserted.
    assertion(Percepts == [apple_image_42]).

% AC-004: repeated symbolization keeps one link and increments its count.
test(symbolize_records_and_increments, [setup(test_acquisition_reset)]) :-
    % Record the signifier "storm" evoking the signified "danger".
    acquisition_symbolize(storm, danger, SId1),
    % A first symbolization stores the link with count one.
    assertion(acquisition:symbolism(SId1, storm, danger, 1)),
    % Record the same evocation again.
    acquisition_symbolize(storm, danger, SId2),
    % The second symbolization reuses the same link identifier.
    assertion(SId1 == SId2),
    % The stored link now carries a count of two.
    assertion(acquisition:symbolism(SId1, storm, danger, 2)).

% AC-005: chain promotion combines units into one next-tier composite.
test(chain_promote_builds_composite, [setup(test_acquisition_reset)]) :-
    % Promote three current-tier units into the next tier.
    acquisition_chain_promote([unit(the, 5), unit(big, 3), unit(cat, 7)], NextTier),
    % The promotion yields a single composite of the joined forms.
    assertion(NextTier == [unit('the+big+cat', 1)]).

% AC-006: a promoted word is queryable by its phoneme sequence.
test(word_of_queries_sequence, [setup(test_acquisition_reset)]) :-
    % Hear the series three times so it is promoted to a word form.
    forall(between(1, 3, _), acquisition_chain_phonemes([f, au, ks], _)),
    % Query the stored word form by its phoneme sequence.
    acquisition_word_of([f, au, ks], Form),
    % The canonical word form joins the phonemes with dashes.
    assertion(Form == 'f-au-ks').

% Close the test block for acquisition.
:- end_tests(acquisition).
