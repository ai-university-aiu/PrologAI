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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/language/prolog'], LangPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LangPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'language' library so its predicates are available here.
:- use_module(library(language), [
    % Supply 'pai_hear/2' as the next argument to the expression above.
    pai_hear/2,
    % Supply 'pai_think_path/3' as the next argument to the expression above.
    pai_think_path/3,
    % Supply 'pai_speak/2' as the next argument to the expression above.
    pai_speak/2,
    % Supply 'pai_word_trace/3' as the next argument to the expression above.
    pai_word_trace/3,
    % Supply 'pai_set_context/2' as the next argument to the expression above.
    pai_set_context/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr28, [setup(pr28_setup), cleanup(pr28_cleanup)]).
:- begin_tests(pr28, [setup(pr28_setup), cleanup(pr28_cleanup)]).

% Execute: pr28_setup :-.
pr28_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(language:word_trace(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(language:context_param(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(language:trace_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(language:trace_id_counter(0)).

% Execute: pr28_cleanup :-.
pr28_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(language:word_trace(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(language:context_param(_, _)).

%  AC-PR28-001: julia is working → think_path finds julia→working, speak emits surface
% Define a clause for 'test': succeed when the following conditions hold.
test(hear_think_speak_path) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([julia, is, working], _TraceIds)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_think_path(julia, [], Path)),
    % Check that 'Path' is not unifiable with '[]'.
    Path \= [],
    % Check working is reachable
    % Execute: ( once((member(WId, Path), language:word_trace(WId, working, _, _))).
    ( once((member(WId, Path), language:word_trace(WId, working, _, _)))
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   memberchk(working, Path)  % fallback if core values are in path
    % Close the expression opened above.
    ),
    % State a fact for 'once' with the arguments listed below.
    once(pai_speak(Path, Surface)),
    % State a fact for 'atom' with the arguments listed below.
    atom(Surface),
    % State a fact for 'once' with the arguments listed below.
    once(sub_atom(Surface, _, _, _, julia)),
    % State the fact: once(sub_atom(Surface, _, _, _, working)).
    once(sub_atom(Surface, _, _, _, working)).

%  AC-PR28-002: one word_trace per word
% Define a clause for 'test': succeed when the following conditions hold.
test(hear_builds_word_traces) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([the, cat, sat], Ids)),
    % Unify '3' with the number of elements in list 'Ids'.
    length(Ids, 3),
    % State the fact: once(pai_word_trace(cat, _, _)).
    once(pai_word_trace(cat, _, _)).

%  AC-PR28-003: word_traces are never retracted (sediment)
% Define a clause for 'test': succeed when the following conditions hold.
test(word_traces_append_only) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([hello, world], _)),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, language:word_trace(Id, _, _, _), Before),
    % Try to retract one — but we verify the count after hearing again
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([foo], _)),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id2, language:word_trace(Id2, _, _, _), After),
    % Unify 'NB' with the number of elements in list 'Before'.
    length(Before, NB),
    % Unify 'NA' with the number of elements in list 'After'.
    length(After, NA),
    % Check that 'NA' is greater than 'NB'.
    NA > NB.

%  AC-PR28-004: unknown words admitted without error
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_words_admitted) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([xyzzy, qux, blargh], Ids)),
    % Unify '3' with the number of elements in list 'Ids'.
    length(Ids, 3),
    % State the fact: once(pai_word_trace(xyzzy, _, _)).
    once(pai_word_trace(xyzzy, _, _)).

%  AC-PR28-005: grammatical subject pointer: verb points to subject
% Define a clause for 'test': succeed when the following conditions hold.
test(subject_pointer_set) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([alice, runs, fast], [SId, VId|_])),
    % Execute: language:word_trace(VId, _, VPtrs, _),.
    language:word_trace(VId, _, VPtrs, _),
    % State the fact: memberchk(pointer(subject, SId), VPtrs).
    memberchk(pointer(subject, SId), VPtrs).

%  AC-PR28-006: next pointer links consecutive word_traces
% Define a clause for 'test': succeed when the following conditions hold.
test(next_pointer_links_words) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([one, two, three], [W1Id, W2Id, _])),
    % Execute: language:word_trace(W1Id, _, Ptrs1, _),.
    language:word_trace(W1Id, _, Ptrs1, _),
    % State the fact: memberchk(pointer(next, W2Id), Ptrs1).
    memberchk(pointer(next, W2Id), Ptrs1).

%  AC-PR28-007: indexical 'i' resolves to context agent
% Define a clause for 'test': succeed when the following conditions hold.
test(indexical_i_resolves) :-
    % State a fact for 'pai set context' with the arguments listed below.
    pai_set_context(i, maria),
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([i, am, here], Ids)),
    % Check that 'Ids' is unifiable with '[IId|_]'.
    Ids = [IId|_],
    % Execute: language:word_trace(IId, maria, _, _)..
    language:word_trace(IId, maria, _, _).

%  AC-PR28-008: max_depth(1) limits path to immediate neighbors
% Define a clause for 'test': succeed when the following conditions hold.
test(think_path_max_depth_one) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_hear([bob, eats, lunch], _)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_think_path(bob, [max_depth(1)], Path)),
    % Unify 'N' with the number of elements in list 'Path'.
    length(Path, N),
    % Check that 'N' is less than or equal to '2.  % at most the seed node + 1 neighbor'.
    N =< 2.  % at most the seed node + 1 neighbor

%  AC-PR28-009: speak on empty path → empty atom
% Define a clause for 'test': succeed when the following conditions hold.
test(speak_empty_path) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_speak([], Surface)),
    % Check that 'Surface' is unifiable with ''''.
    Surface = ''.

% Execute the compile-time directive: end_tests(pr28).
:- end_tests(pr28).
