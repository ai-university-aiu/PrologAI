/*  PrologAI — Time-Linear Language Test Suite  (PR 28)

    Exercises the five exported predicates of the language pack — a stream
    processor that hears words into append-only word_traces, threads
    grammatical pointers, navigates think-paths, and speaks surfaces.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/language/test/test_language.pl
*/

% Declare this file as a test module with no exports.
:- module(test_language, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(language)).

% Open the test block for language, resetting the word_bank before and after each test.
:- begin_tests(language, [setup(reset_language), cleanup(reset_language)]).

% Wipe the append-only word_bank and reset the id counter to a clean slate.
reset_language :-
    % Remove every stored word_trace fact.
    retractall(language:word_trace(_, _, _, _)),
    % Remove every indexical context binding.
    retractall(language:context_param(_, _)),
    % Remove the current id counter value.
    retractall(language:trace_id_counter(_)),
    % Reinstall the counter at zero so ids start fresh.
    assertz(language:trace_id_counter(0)).

% AC-LANG-001: hearing a stream builds one word_trace per word, queryable by core.
test(hear_builds_one_trace_per_word) :-
    % Hear a three-word stream and collect the trace ids.
    once(language_hear([the, cat, sat], Ids)),
    % There is exactly one id per heard word.
    assertion(length(Ids, 3)),
    % The middle word is queryable back out of the word_bank by its core.
    assertion(language_word_trace(cat, _, _)).

% AC-LANG-002: unknown words are admitted as new traces without error.
test(unknown_words_admitted) :-
    % Hear three nonsense words that no grammar recognises.
    once(language_hear([xyzzy, qux, blargh], Ids)),
    % Each still becomes a trace, so three ids come back.
    assertion(length(Ids, 3)),
    % The first nonsense word is retrievable by its core.
    assertion(language_word_trace(xyzzy, _, _)).

% AC-LANG-003: the SVO heuristic links the verb back to its subject.
test(subject_pointer_set) :-
    % Hear a subject-verb-object sentence, capturing subject and verb ids.
    once(language_hear([alice, runs, fast], [SId, VId|_])),
    % Read the pointer list stored on the verb trace.
    once(language:word_trace(VId, _, VPtrs, _)),
    % The verb carries a subject pointer aimed back at the subject trace.
    assertion(memberchk(pointer(subject, SId), VPtrs)).

% AC-LANG-004: consecutive words are threaded by a next pointer.
test(next_pointer_links_words) :-
    % Hear three ordered words, capturing the first two ids.
    once(language_hear([one, two, three], [W1Id, W2Id, _])),
    % Read the pointer list stored on the first word.
    once(language:word_trace(W1Id, _, Ptrs1, _)),
    % The first word points forward to the second via a next pointer.
    assertion(memberchk(pointer(next, W2Id), Ptrs1)).

% AC-LANG-005: an indexical resolves to its context-bound value while hearing.
test(indexical_resolves_to_context) :-
    % Bind the indexical 'i' to the agent maria.
    language_set_context(i, maria),
    % Hear a stream that opens with the indexical 'i'.
    once(language_hear([i, am, here], [IId|_])),
    % The first trace stores maria, not the literal 'i'.
    assertion(language:word_trace(IId, maria, _, _)).

% AC-LANG-006: hear then think-path then speak yields a grammatical surface.
test(hear_think_speak_roundtrip) :-
    % Hear the sentence "julia is working".
    once(language_hear([julia, is, working], _)),
    % Navigate a think-path outward from the seed word julia.
    once(language_think_path(julia, [], Path)),
    % The path is non-empty, so navigation reached something.
    assertion(Path \== []),
    % Speak the path back into a surface string.
    once(language_speak(Path, Surface)),
    % The surface is an atom.
    assertion(atom(Surface)),
    % The subject julia appears in the spoken surface.
    assertion(sub_atom(Surface, _, _, _, julia)),
    % The predicate working appears in the spoken surface.
    assertion(sub_atom(Surface, _, _, _, working)).

% AC-LANG-007: speaking an empty path returns the empty atom.
test(speak_empty_path) :-
    % Speak with no trace ids at all.
    language_speak([], Surface),
    % The surface is the empty atom.
    assertion(Surface == '').

% Close the test block for language.
:- end_tests(language).
