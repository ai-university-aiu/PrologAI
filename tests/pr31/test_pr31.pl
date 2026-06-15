/*  PrologAI — PR 31 Developmental Language Acquisition Acceptance Tests

    AC-PR31-001: Given repeated phoneme series for one word co-occurring with
                 one percept, when the pipeline runs, then a grounded word
                 node_fact links the series to the percept.
    AC-PR31-002: After 3 observations of the same phoneme series, a word
                 candidate is promoted.
    AC-PR31-003: Fewer than 3 observations → no word candidate yet.
    AC-PR31-004: pai_ground links a word form to a percept reference.
    AC-PR31-005: Words heard before referents persist ungrounded; later
                 grounding succeeds.
    AC-PR31-006: pai_symbolize records a signifier→signified link.
    AC-PR31-007: Repeated symbolization increments the count.
    AC-PR31-008: pai_chain_promote combines units into a next-tier composite.
    AC-PR31-009: pai_word_of queries by phoneme sequence.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/acquisition/prolog'], AcqPath),
   assertz(file_search_path(library, AcqPath)).

:- use_module(library(plunit)).
:- use_module(library(acquisition), [
    pai_chain_phonemes/2,
    pai_ground/3,
    pai_symbolize/3,
    pai_chain_promote/2,
    pai_word_of/2,
    pai_grounding_of/2
]).

:- begin_tests(pr31, [setup(pr31_setup), cleanup(pr31_cleanup)]).

pr31_setup :-
    retractall(acquisition:phoneme_chain(_, _, _)),
    retractall(acquisition:word_form(_, _, _)),
    retractall(acquisition:word_grounding(_, _, _)),
    retractall(acquisition:symbolism(_, _, _, _)),
    retractall(acquisition:tier_unit(_, _, _)),
    retractall(acquisition:acquisition_id_counter(_)),
    assertz(acquisition:acquisition_id_counter(0)).

pr31_cleanup :-
    retractall(acquisition:phoneme_chain(_, _, _)),
    retractall(acquisition:word_form(_, _, _)),
    retractall(acquisition:word_grounding(_, _, _)),
    retractall(acquisition:symbolism(_, _, _, _)),
    retractall(acquisition:tier_unit(_, _, _)).

%  AC-PR31-001: repeated phoneme series + grounding = grounded word node
test(grounded_word_from_repeated_series) :-
    % Hear the word "cat" (k-ae-t) 3 times co-occurring with a percept
    forall(
        between(1, 3, _),
        once(pai_chain_phonemes([k, ae, t], _))
    ),
    % Ground to percept
    once(pai_ground('k-ae-t', cat_percept_001, GId)),
    nonvar(GId),
    once(pai_grounding_of('k-ae-t', cat_percept_001)).

%  AC-PR31-002: 3 observations → word candidate promoted
test(word_promoted_at_threshold) :-
    forall(
        between(1, 3, _),
        once(pai_chain_phonemes([d, ae, g], _))
    ),
    once(pai_chain_phonemes([d, ae, g], Candidates)),  % 4th call returns candidate
    memberchk(word('d-ae-g', _), Candidates).

%  AC-PR31-003: fewer than 3 → no word candidate
test(no_word_before_threshold) :-
    once(pai_chain_phonemes([b, ir, d], C1)),
    C1 = [],
    once(pai_chain_phonemes([b, ir, d], C2)),
    C2 = [].

%  AC-PR31-004: pai_ground links word to percept
test(ground_links_to_percept) :-
    once(pai_ground(apple, apple_image_42, GId)),
    nonvar(GId),
    once(pai_grounding_of(apple, apple_image_42)).

%  AC-PR31-005: word persists ungrounded, later grounding succeeds
test(ungrounded_word_grounds_later) :-
    % "Hear" the word before seeing the referent
    forall(
        between(1, 3, _),
        once(pai_chain_phonemes([tr, ii], _))
    ),
    % No grounding yet — that's fine
    \+ acquisition:word_grounding('tr-ii', _, _),
    % Later, percept arrives
    once(pai_ground('tr-ii', tree_percept_007, _)),
    once(acquisition:word_grounding('tr-ii', tree_percept_007, _)).

%  AC-PR31-006: pai_symbolize records signifier → signified
test(symbolize_records_link) :-
    once(pai_symbolize(sunrise, hope, SId)),
    nonvar(SId),
    once(acquisition:symbolism(SId, sunrise, hope, 1)).

%  AC-PR31-007: repeated symbolization increments count
test(symbolize_increments_count) :-
    once(pai_symbolize(storm, danger, SId1)),
    once(pai_symbolize(storm, danger, SId2)),
    SId1 = SId2,
    once(acquisition:symbolism(SId1, storm, danger, Count)),
    Count =:= 2.

%  AC-PR31-008: pai_chain_promote builds next-tier composite
test(chain_promote_builds_composite) :-
    Units = [unit(the, 5), unit(big, 3), unit(cat, 7)],
    once(pai_chain_promote(Units, NextTier)),
    NextTier = [unit('the+big+cat', 1)].

%  AC-PR31-009: pai_word_of queries by phoneme sequence
test(word_of_queries_sequence) :-
    forall(
        between(1, 3, _),
        once(pai_chain_phonemes([f, au, ks], _))
    ),
    once(pai_word_of([f, au, ks], Form)),
    Form = 'f-au-ks'.

:- end_tests(pr31).
