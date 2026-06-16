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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/acquisition/prolog'], AcqPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AcqPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'acquisition' library so its predicates are available here.
:- use_module(library(acquisition), [
    % Supply 'pai_chain_phonemes/2' as the next argument to the expression above.
    pai_chain_phonemes/2,
    % Supply 'pai_ground/3' as the next argument to the expression above.
    pai_ground/3,
    % Supply 'pai_symbolize/3' as the next argument to the expression above.
    pai_symbolize/3,
    % Supply 'pai_chain_promote/2' as the next argument to the expression above.
    pai_chain_promote/2,
    % Supply 'pai_word_of/2' as the next argument to the expression above.
    pai_word_of/2,
    % Supply 'pai_grounding_of/2' as the next argument to the expression above.
    pai_grounding_of/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr31, [setup(pr31_setup), cleanup(pr31_cleanup)]).
:- begin_tests(pr31, [setup(pr31_setup), cleanup(pr31_cleanup)]).

% Execute: pr31_setup :-.
pr31_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:phoneme_chain(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:word_form(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:word_grounding(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:symbolism(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:tier_unit(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:acquisition_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(acquisition:acquisition_id_counter(0)).

% Execute: pr31_cleanup :-.
pr31_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:phoneme_chain(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:word_form(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:word_grounding(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:symbolism(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(acquisition:tier_unit(_, _, _)).

%  AC-PR31-001: repeated phoneme series + grounding = grounded word node
% Define a clause for 'test': succeed when the following conditions hold.
test(grounded_word_from_repeated_series) :-
    % Hear the word "cat" (k-ae-t) 3 times co-occurring with a percept
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        once(pai_chain_phonemes([k, ae, t], _))
    % Close the expression opened above.
    ),
    % Ground to percept
    % State a fact for 'once' with the arguments listed below.
    once(pai_ground('k-ae-t', cat_percept_001, GId)),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(GId),
    % State the fact: once(pai_grounding_of('k-ae-t', cat_percept_001)).
    once(pai_grounding_of('k-ae-t', cat_percept_001)).

%  AC-PR31-002: 3 observations → word candidate promoted
% Define a clause for 'test': succeed when the following conditions hold.
test(word_promoted_at_threshold) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        once(pai_chain_phonemes([d, ae, g], _))
    % Close the expression opened above.
    ),
    % State a fact for 'once' with the arguments listed below.
    once(pai_chain_phonemes([d, ae, g], Candidates)),  % 4th call returns candidate
    % State the fact: memberchk(word('d-ae-g', _), Candidates).
    memberchk(word('d-ae-g', _), Candidates).

%  AC-PR31-003: fewer than 3 → no word candidate
% Define a clause for 'test': succeed when the following conditions hold.
test(no_word_before_threshold) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_chain_phonemes([b, ir, d], C1)),
    % Check that 'C1' is unifiable with '[]'.
    C1 = [],
    % State a fact for 'once' with the arguments listed below.
    once(pai_chain_phonemes([b, ir, d], C2)),
    % Check that 'C2' is unifiable with '[]'.
    C2 = [].

%  AC-PR31-004: pai_ground links word to percept
% Define a clause for 'test': succeed when the following conditions hold.
test(ground_links_to_percept) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_ground(apple, apple_image_42, GId)),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(GId),
    % State the fact: once(pai_grounding_of(apple, apple_image_42)).
    once(pai_grounding_of(apple, apple_image_42)).

%  AC-PR31-005: word persists ungrounded, later grounding succeeds
% Define a clause for 'test': succeed when the following conditions hold.
test(ungrounded_word_grounds_later) :-
    % "Hear" the word before seeing the referent
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        once(pai_chain_phonemes([tr, ii], _))
    % Close the expression opened above.
    ),
    % No grounding yet — that's fine
    % Succeed only if 'acquisition:word_grounding('tr-ii', _, _' cannot be proved (negation as failure).
    \+ acquisition:word_grounding('tr-ii', _, _),
    % Later, percept arrives
    % State a fact for 'once' with the arguments listed below.
    once(pai_ground('tr-ii', tree_percept_007, _)),
    % State the fact: once(acquisition:word_grounding('tr-ii', tree_percept_007, _)).
    once(acquisition:word_grounding('tr-ii', tree_percept_007, _)).

%  AC-PR31-006: pai_symbolize records signifier → signified
% Define a clause for 'test': succeed when the following conditions hold.
test(symbolize_records_link) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_symbolize(sunrise, hope, SId)),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(SId),
    % State the fact: once(acquisition:symbolism(SId, sunrise, hope, 1)).
    once(acquisition:symbolism(SId, sunrise, hope, 1)).

%  AC-PR31-007: repeated symbolization increments count
% Define a clause for 'test': succeed when the following conditions hold.
test(symbolize_increments_count) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_symbolize(storm, danger, SId1)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_symbolize(storm, danger, SId2)),
    % Check that 'SId1' is unifiable with 'SId2'.
    SId1 = SId2,
    % State a fact for 'once' with the arguments listed below.
    once(acquisition:symbolism(SId1, storm, danger, Count)),
    % Check that 'Count' is numerically equal to '2'.
    Count =:= 2.

%  AC-PR31-008: pai_chain_promote builds next-tier composite
% Define a clause for 'test': succeed when the following conditions hold.
test(chain_promote_builds_composite) :-
    % Check that 'Units' is unifiable with '[unit(the, 5), unit(big, 3), unit(cat, 7)]'.
    Units = [unit(the, 5), unit(big, 3), unit(cat, 7)],
    % State a fact for 'once' with the arguments listed below.
    once(pai_chain_promote(Units, NextTier)),
    % Check that 'NextTier' is unifiable with '[unit('the+big+cat', 1)]'.
    NextTier = [unit('the+big+cat', 1)].

%  AC-PR31-009: pai_word_of queries by phoneme sequence
% Define a clause for 'test': succeed when the following conditions hold.
test(word_of_queries_sequence) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        once(pai_chain_phonemes([f, au, ks], _))
    % Close the expression opened above.
    ),
    % State a fact for 'once' with the arguments listed below.
    once(pai_word_of([f, au, ks], Form)),
    % Check that 'Form' is unifiable with ''f-au-ks''.
    Form = 'f-au-ks'.

% Execute the compile-time directive: end_tests(pr31).
:- end_tests(pr31).
