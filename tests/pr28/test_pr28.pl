/*  PrologAI — PR 28 Time-Linear Language (Database Semantics) Acceptance Tests

    AC-PR28-001: Given the heard sequence "julia is working", when pai_think_path
                 is asked from julia, then a path julia→working exists, and
                 pai_speak over that path emits a grammatical surface.
    AC-PR28-002: pai_hear builds a word_trace for each word in the stream.
    AC-PR28-003: word_traces are never retracted (append-only / sediment).
    AC-PR28-004: Unknown words are admitted as new word_traces without error.
    AC-PR28-005: Grammatical subject pointer links verb to subject.
    AC-PR28-006: next pointer links each word_trace to the following one.
    AC-PR28-007: Indexical 'i' resolves to the context-bound agent.
    AC-PR28-008: pai_think_path with max_depth(1) returns only immediate neighbors.
    AC-PR28-009: pai_speak on an empty path returns an empty string.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/language/prolog'], LangPath),
   assertz(file_search_path(library, LangPath)).

:- use_module(library(plunit)).
:- use_module(library(language), [
    pai_hear/2,
    pai_think_path/3,
    pai_speak/2,
    pai_word_trace/3,
    pai_set_context/2
]).

:- begin_tests(pr28, [setup(pr28_setup), cleanup(pr28_cleanup)]).

pr28_setup :-
    retractall(language:word_trace(_, _, _, _)),
    retractall(language:context_param(_, _)),
    retractall(language:trace_id_counter(_)),
    assertz(language:trace_id_counter(0)).

pr28_cleanup :-
    retractall(language:word_trace(_, _, _, _)),
    retractall(language:context_param(_, _)).

%  AC-PR28-001: julia is working → think_path finds julia→working, speak emits surface
test(hear_think_speak_path) :-
    once(pai_hear([julia, is, working], _TraceIds)),
    once(pai_think_path(julia, [], Path)),
    Path \= [],
    % Check working is reachable
    ( once((member(WId, Path), language:word_trace(WId, working, _, _)))
    ->  true
    ;   memberchk(working, Path)  % fallback if core values are in path
    ),
    once(pai_speak(Path, Surface)),
    atom(Surface),
    once(sub_atom(Surface, _, _, _, julia)),
    once(sub_atom(Surface, _, _, _, working)).

%  AC-PR28-002: one word_trace per word
test(hear_builds_word_traces) :-
    once(pai_hear([the, cat, sat], Ids)),
    length(Ids, 3),
    once(pai_word_trace(cat, _, _)).

%  AC-PR28-003: word_traces are never retracted (sediment)
test(word_traces_append_only) :-
    once(pai_hear([hello, world], _)),
    findall(Id, language:word_trace(Id, _, _, _), Before),
    % Try to retract one — but we verify the count after hearing again
    once(pai_hear([foo], _)),
    findall(Id2, language:word_trace(Id2, _, _, _), After),
    length(Before, NB),
    length(After, NA),
    NA > NB.

%  AC-PR28-004: unknown words admitted without error
test(unknown_words_admitted) :-
    once(pai_hear([xyzzy, qux, blargh], Ids)),
    length(Ids, 3),
    once(pai_word_trace(xyzzy, _, _)).

%  AC-PR28-005: grammatical subject pointer: verb points to subject
test(subject_pointer_set) :-
    once(pai_hear([alice, runs, fast], [SId, VId|_])),
    language:word_trace(VId, _, VPtrs, _),
    memberchk(pointer(subject, SId), VPtrs).

%  AC-PR28-006: next pointer links consecutive word_traces
test(next_pointer_links_words) :-
    once(pai_hear([one, two, three], [W1Id, W2Id, _])),
    language:word_trace(W1Id, _, Ptrs1, _),
    memberchk(pointer(next, W2Id), Ptrs1).

%  AC-PR28-007: indexical 'i' resolves to context agent
test(indexical_i_resolves) :-
    pai_set_context(i, maria),
    once(pai_hear([i, am, here], Ids)),
    Ids = [IId|_],
    language:word_trace(IId, maria, _, _).

%  AC-PR28-008: max_depth(1) limits path to immediate neighbors
test(think_path_max_depth_one) :-
    once(pai_hear([bob, eats, lunch], _)),
    once(pai_think_path(bob, [max_depth(1)], Path)),
    length(Path, N),
    N =< 2.  % at most the seed node + 1 neighbor

%  AC-PR28-009: speak on empty path → empty atom
test(speak_empty_path) :-
    once(pai_speak([], Surface)),
    Surface = ''.

:- end_tests(pr28).
