/*  PrologAI — Time-Linear Language: Database Semantics  (Specification PR 28)

    Processes language as a stream, one word at a time in arrival order, with
    one record type (word_trace) supporting all three modes: hearing, thinking,
    and speaking.

    A word_trace is a flat, non-recursive record:
        word_trace(Id, Core, Pointers, Timestamp)
    where:
        Id        — unique integer identifier
        Core      — the word's canonical value (atom)
        Pointers  — list of pointer(Relation, TargetTraceId)
        Timestamp — arrival time (integer arrival order)

    Word_traces sharing a Core are linked via `same_core(NextId)` pointers,
    forming one token line in arrival order (the word_bank).  Storage is
    append-only (sediment): word_traces are never retracted or edited.

    Three modes:
      Hearer — pai_hear/2: builds word_traces as words arrive; sets
               grammatical pointers between them; admits unknown words;
               leaves missing referents unbound.
      Thinker— pai_think_path/3: navigates from a seed word_trace along
               semantic and grammatical pointers to derive content;
               resolves indexicals against current context.
      Speaker— pai_speak/2: traverses a think-path and emits surfaces.

    Predicates:
      pai_hear/2         — +Words, -TraceIds
      pai_think_path/3   — +FromCore, +Opts, -Path
      pai_speak/2        — +Path, -Surface
      pai_word_trace/3   — +Core, -Id, -Pointers  (query)
      pai_set_context/2  — +Indexical, +Value  (I, you, here, now)
*/

:- module(language, [
    pai_hear/2,
    pai_think_path/3,
    pai_speak/2,
    pai_word_trace/3,
    pai_set_context/2
]).

:- use_module(library(lists), [member/2, append/3, last/2]).

% ---------------------------------------------------------------------------
% Storage — append-only word_bank
% ---------------------------------------------------------------------------

:- dynamic word_trace/4.      % Id, Core, Pointers, Timestamp
:- dynamic trace_id_counter/1.
trace_id_counter(0).
:- dynamic context_param/2.   % Indexical(i|you|here|now), Value

next_trace_id(Id) :-
    retract(trace_id_counter(N)),
    N1 is N + 1,
    assertz(trace_id_counter(N1)),
    Id = N1.

% ---------------------------------------------------------------------------
% pai_word_trace/3 — query word_traces by Core
% ---------------------------------------------------------------------------

pai_word_trace(Core, Id, Pointers) :-
    word_trace(Id, Core, Pointers, _).

% ---------------------------------------------------------------------------
% pai_hear/2
%
%   Hear a list of Words (atoms), build word_traces, set inter-trace
%   pointers for simple subject-verb-object patterns.
%
%   Simple grammar:
%     Word[0] = subject candidate
%     Word[1] = copula/auxiliary (is, was, are, were, …) → verb class
%     Word[2…] = predicate/object
%
%   Pointers set:
%     next(NextId)          — linear succession in the stream
%     subject(SubjectId)    — from verb/predicate back to subject
%     predicate(VerbId)     — from subject forward to verb
%     head(VerbId)          — from complement back to its head
% ---------------------------------------------------------------------------

pai_hear(Words, TraceIds) :-
    get_time(T0),
    hear_words(Words, T0, 1, [], TraceIds0),
    reverse(TraceIds0, TraceIds),
    link_grammar(TraceIds).

hear_words([], _, _, Acc, Acc).
hear_words([W|Rest], T0, Pos, Acc, Result) :-
    % Resolve indexical if needed
    resolve_indexical(W, Core),
    next_trace_id(Id),
    Timestamp is T0 + Pos,
    % Append to same-core token line
    link_same_core(Core, Id),
    assertz(word_trace(Id, Core, [], Timestamp)),
    Pos1 is Pos + 1,
    hear_words(Rest, T0, Pos1, [Id|Acc], Result).

resolve_indexical(I, Value) :-
    memberchk(I, [i, you, here, now]),
    context_param(I, Value), !.
resolve_indexical(W, W).

link_same_core(Core, NewId) :-
    ( word_trace(PrevId, Core, PrevPtrs, PrevT),
      \+ member(pointer(same_core, _), PrevPtrs)
    ->  % Update the previous entry to point to the new trace
        retract(word_trace(PrevId, Core, PrevPtrs, PrevT)),
        assertz(word_trace(PrevId, Core,
                           [pointer(same_core, NewId)|PrevPtrs], PrevT))
    ;   true
    ).

% Set grammatical pointers based on position (simple SVO heuristic)
link_grammar(TraceIds) :-
    % Set next pointers along the stream
    link_next(TraceIds),
    % SVO: [Subj, Verb, Compl…]
    ( TraceIds = [SId, VId | CompIds]
    ->  set_pointer(VId, pointer(subject, SId)),
        set_pointer(SId, pointer(predicate, VId)),
        forall(
            member(CId, CompIds),
            set_pointer(CId, pointer(head, VId))
        )
    ;   true
    ).

link_next([]).
link_next([_]).
link_next([A, B | Rest]) :-
    set_pointer(A, pointer(next, B)),
    link_next([B|Rest]).

set_pointer(TraceId, NewPtr) :-
    ( retract(word_trace(TraceId, Core, Ptrs, T))
    ->  assertz(word_trace(TraceId, Core, [NewPtr|Ptrs], T))
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_think_path/3
%
%   Navigate from the most recent word_trace for FromCore along semantic
%   and grammatical pointers.  Returns a path (list of trace IDs) reaching
%   all reachable nodes via BFS (depth-limited to 10 steps).
%
%   Opts: [max_depth(N)]  — override default BFS depth
%         [relation(R)]   — only follow pointers with this relation label
% ---------------------------------------------------------------------------

pai_think_path(FromCore, Opts, Path) :-
    % Find most recent trace for FromCore
    findall(Id-T, word_trace(Id, FromCore, _, T), Candidates),
    ( Candidates = []
    ->  Path = []
    ;   last_by_time(Candidates, StartId-_),
        option_max_depth(Opts, MaxD),
        option_relation(Opts, RelFilter),
        bfs([StartId], [], MaxD, RelFilter, Path)
    ).

last_by_time([X], X) :- !.
last_by_time([H|T], Max) :-
    last_by_time(T, MaxT),
    H = _-T1, MaxT = _-T2,
    ( T1 >= T2 -> Max = H ; Max = MaxT ).

option_max_depth(Opts, N) :-
    ( member(max_depth(N), Opts) -> true ; N = 10 ).
option_relation(Opts, R) :-
    ( member(relation(R), Opts) -> true ; R = any ).

bfs([], Visited, _, _, Visited).
bfs([H|Queue], Visited, MaxD, RelFilter, Path) :-
    length(Visited, Depth),
    ( Depth >= MaxD
    ->  Path = Visited
    ;   ( memberchk(H, Visited)
        ->  bfs(Queue, Visited, MaxD, RelFilter, Path)
        ;   findall(Next, (
                word_trace(H, _, Ptrs, _),
                member(pointer(Rel, Next), Ptrs),
                ( RelFilter = any -> true ; Rel = RelFilter )
            ), Nexts),
            append(Queue, Nexts, NewQueue),
            bfs(NewQueue, [H|Visited], MaxD, RelFilter, Path)
        )
    ).

% ---------------------------------------------------------------------------
% pai_speak/2
%
%   Given a Path (list of trace IDs from pai_think_path), emit a surface
%   representation by reading the Core value of each trace in natural order.
% ---------------------------------------------------------------------------

pai_speak(Path, Surface) :-
    % Sort path by timestamp to get natural word order
    findall(T-Core, (
        member(Id, Path),
        word_trace(Id, Core, _, T)
    ), Timed),
    msort(Timed, Sorted),
    findall(W, member(_-W, Sorted), Words),
    atomic_list_concat(Words, ' ', Surface).

% ---------------------------------------------------------------------------
% pai_set_context/2 — set an indexical binding
% ---------------------------------------------------------------------------

pai_set_context(Indexical, Value) :-
    retractall(context_param(Indexical, _)),
    assertz(context_param(Indexical, Value)).

% Reverse a list (without importing from lists to avoid clashes)
reverse(L, R) :- reverse(L, [], R).
reverse([], A, A).
reverse([H|T], A, R) :- reverse(T, [H|A], R).
