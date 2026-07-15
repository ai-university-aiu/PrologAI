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
      Hearer — language_hear/2: builds word_traces as words arrive; sets
               grammatical pointers between them; admits unknown words;
               leaves missing referents unbound.
      Thinker— language_think_path/3: navigates from a seed word_trace along
               semantic and grammatical pointers to derive content;
               resolves indexicals against current context.
      Speaker— language_speak/2: traverses a think-path and emits surfaces.

    Predicates:
      language_hear/2         — +Words, -TraceIds
      language_think_path/3   — +FromCore, +Opts, -Path
      language_speak/2        — +Path, -Surface
      language_word_trace/3   — +Core, -Id, -Pointers  (query)
      language_set_context/2  — +Indexical, +Value  (I, you, here, now)
*/

% Declare this file as the 'language' module and list its exported predicates.
:- module(language, [
    % Supply 'language_hear/2' as the next argument to the expression above.
    language_hear/2,
    % Supply 'language_think_path/3' as the next argument to the expression above.
    language_think_path/3,
    % Supply 'language_speak/2' as the next argument to the expression above.
    language_speak/2,
    % Supply 'language_word_trace/3' as the next argument to the expression above.
    language_word_trace/3,
    % Supply 'language_set_context/2' as the next argument to the expression above.
    language_set_context/2
% Close the expression opened above.
]).

% Import [member/2, append/3, last/2] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, append/3, last/2]).

% ---------------------------------------------------------------------------
% Storage — append-only word_bank
% ---------------------------------------------------------------------------

% Declare 'word_trace/4.      % Id, Core, Pointers, Timestamp' as dynamic — its facts may be added or removed at runtime.
:- dynamic word_trace/4.      % Id, Core, Pointers, Timestamp
% Declare 'trace_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic trace_id_counter/1.
% State the fact: trace id counter(0).
trace_id_counter(0).
% Declare 'context_param/2.   % Indexical(i|you|here|now), Value' as dynamic — its facts may be added or removed at runtime.
:- dynamic context_param/2.   % Indexical(i|you|here|now), Value

% Define a clause for 'next trace id': succeed when the following conditions hold.
next_trace_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(trace_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(trace_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% ---------------------------------------------------------------------------
% language_word_trace/3 — query word_traces by Core
% ---------------------------------------------------------------------------

% Define a clause for 'pai word trace': succeed when the following conditions hold.
language_word_trace(Core, Id, Pointers) :-
    % State the fact: word trace(Id, Core, Pointers, _).
    word_trace(Id, Core, Pointers, _).

% ---------------------------------------------------------------------------
% language_hear/2
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

% Define a clause for 'pai hear': succeed when the following conditions hold.
language_hear(Words, TraceIds) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'hear words' with the arguments listed below.
    hear_words(Words, T0, 1, [], TraceIds0),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(TraceIds0, TraceIds),
    % State the fact: link grammar(TraceIds).
    language_grammar(TraceIds).

% State the fact: hear words([], _, _, Acc, Acc).
hear_words([], _, _, Acc, Acc).
% Define a clause for 'hear words': succeed when the following conditions hold.
hear_words([W|Rest], T0, Pos, Acc, Result) :-
    % Resolve indexical if needed
    % State a fact for 'resolve indexical' with the arguments listed below.
    resolve_indexical(W, Core),
    % State a fact for 'next trace id' with the arguments listed below.
    next_trace_id(Id),
    % Evaluate the arithmetic expression 'T0 + Pos' and bind the result to 'Timestamp'.
    Timestamp is T0 + Pos,
    % Append to same-core token line
    % State a fact for 'link same core' with the arguments listed below.
    language_same_core(Core, Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(word_trace(Id, Core, [], Timestamp)),
    % Evaluate the arithmetic expression 'Pos + 1' and bind the result to 'Pos1'.
    Pos1 is Pos + 1,
    % State the fact: hear words(Rest, T0, Pos1, [Id|Acc], Result).
    hear_words(Rest, T0, Pos1, [Id|Acc], Result).

% Define a clause for 'resolve indexical': succeed when the following conditions hold.
resolve_indexical(I, Value) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(I, [i, you, here, now]),
    % State a fact for 'context param' with the arguments listed below.
    context_param(I, Value), !.
% State the fact: resolve indexical(W, W).
resolve_indexical(W, W).

% Define a clause for 'link same core': succeed when the following conditions hold.
language_same_core(Core, NewId) :-
    % Execute: ( word_trace(PrevId, Core, PrevPtrs, PrevT),.
    ( word_trace(PrevId, Core, PrevPtrs, PrevT),
      % Continue the multi-line expression started above.
      \+ member(pointer(same_core, _), PrevPtrs)
    % If the condition above succeeded, perform the following action.
    ->  % Update the previous entry to point to the new trace
        % Continue the multi-line expression started above.
        retract(word_trace(PrevId, Core, PrevPtrs, PrevT)),
        % Continue the multi-line expression started above.
        assertz(word_trace(PrevId, Core,
                           % Continue the multi-line expression started above.
                           [pointer(same_core, NewId)|PrevPtrs], PrevT))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Set grammatical pointers based on position (simple SVO heuristic)
% Define a clause for 'link grammar': succeed when the following conditions hold.
language_grammar(TraceIds) :-
    % Set next pointers along the stream
    % State a fact for 'link next' with the arguments listed below.
    language_next(TraceIds),
    % SVO: [Subj, Verb, Compl…]
    % Check that '( TraceIds' is unifiable with '[SId, VId | CompIds]'.
    ( TraceIds = [SId, VId | CompIds]
    % If the condition above succeeded, perform the following action.
    ->  set_pointer(VId, pointer(subject, SId)),
        % Continue the multi-line expression started above.
        set_pointer(SId, pointer(predicate, VId)),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(CId, CompIds),
            % Continue the multi-line expression started above.
            set_pointer(CId, pointer(head, VId))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% State the fact: link next([]).
language_next([]).
% State the fact: link next([_]).
language_next([_]).
% Define a clause for 'link next': succeed when the following conditions hold.
language_next([A, B | Rest]) :-
    % State a fact for 'set pointer' with the arguments listed below.
    set_pointer(A, pointer(next, B)),
    % State the fact: link next([B|Rest]).
    language_next([B|Rest]).

% Define a clause for 'set pointer': succeed when the following conditions hold.
set_pointer(TraceId, NewPtr) :-
    % Execute: ( retract(word_trace(TraceId, Core, Ptrs, T)).
    ( retract(word_trace(TraceId, Core, Ptrs, T))
    % If the condition above succeeded, perform the following action.
    ->  assertz(word_trace(TraceId, Core, [NewPtr|Ptrs], T))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% language_think_path/3
%
%   Navigate from the most recent word_trace for FromCore along semantic
%   and grammatical pointers.  Returns a path (list of trace IDs) reaching
%   all reachable nodes via BFS (depth-limited to 10 steps).
%
%   Opts: [max_depth(N)]  — override default BFS depth
%         [relation(R)]   — only follow pointers with this relation label
% ---------------------------------------------------------------------------

% Define a clause for 'pai think path': succeed when the following conditions hold.
language_think_path(FromCore, Opts, Path) :-
    % Find most recent trace for FromCore
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-T, word_trace(Id, FromCore, _, T), Candidates),
    % Check that '( Candidates' is unifiable with '[]'.
    ( Candidates = []
    % If the condition above succeeded, perform the following action.
    ->  Path = []
    % Otherwise (else branch), perform the following action.
    ;   last_by_time(Candidates, StartId-_),
        % Continue the multi-line expression started above.
        option_max_depth(Opts, MaxD),
        % Continue the multi-line expression started above.
        option_relation(Opts, RelFilter),
        % Continue the multi-line expression started above.
        bfs([StartId], [], MaxD, RelFilter, Path)
    % Close the expression opened above.
    ).

% Define a clause for 'last by time': succeed when the following conditions hold.
last_by_time([X], X) :- !.
% Define a clause for 'last by time': succeed when the following conditions hold.
last_by_time([H|T], Max) :-
    % State a fact for 'last by time' with the arguments listed below.
    last_by_time(T, MaxT),
    % Check that 'H' is unifiable with '_-T1, MaxT = _-T2'.
    H = _-T1, MaxT = _-T2,
    % Check that '( T1' is greater than or equal to 'T2 -> Max = H ; Max = MaxT )'.
    ( T1 >= T2 -> Max = H ; Max = MaxT ).

% Define a clause for 'option max depth': succeed when the following conditions hold.
option_max_depth(Opts, N) :-
    % Check that '( member(max_depth(N), Opts) -> true ; N' is unifiable with '10 )'.
    ( member(max_depth(N), Opts) -> true ; N = 10 ).
% Define a clause for 'option relation': succeed when the following conditions hold.
option_relation(Opts, R) :-
    % Check that '( member(relation(R), Opts) -> true ; R' is unifiable with 'any )'.
    ( member(relation(R), Opts) -> true ; R = any ).

% State the fact: bfs([], Visited, _, _, Visited).
bfs([], Visited, _, _, Visited).
% Define a clause for 'bfs': succeed when the following conditions hold.
bfs([H|Queue], Visited, MaxD, RelFilter, Path) :-
    % Unify 'Depth' with the number of elements in list 'Visited'.
    length(Visited, Depth),
    % Check that '( Depth' is greater than or equal to 'MaxD'.
    ( Depth >= MaxD
    % If the condition above succeeded, perform the following action.
    ->  Path = Visited
    % Otherwise (else branch), perform the following action.
    ;   ( memberchk(H, Visited)
        % If the condition above succeeded, perform the following action.
        ->  bfs(Queue, Visited, MaxD, RelFilter, Path)
        % Otherwise (else branch), perform the following action.
        ;   findall(Next, (
                % Continue the multi-line expression started above.
                word_trace(H, _, Ptrs, _),
                % Continue the multi-line expression started above.
                member(pointer(Rel, Next), Ptrs),
                % Continue the multi-line expression started above.
                ( RelFilter = any -> true ; Rel = RelFilter )
            % Continue the multi-line expression started above.
            ), Nexts),
            % Continue the multi-line expression started above.
            append(Queue, Nexts, NewQueue),
            % Continue the multi-line expression started above.
            bfs(NewQueue, [H|Visited], MaxD, RelFilter, Path)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% language_speak/2
%
%   Given a Path (list of trace IDs from language_think_path), emit a surface
%   representation by reading the Core value of each trace in natural order.
% ---------------------------------------------------------------------------

% Define a clause for 'pai speak': succeed when the following conditions hold.
language_speak(Path, Surface) :-
    % Sort path by timestamp to get natural word order
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(T-Core, (
        % Continue the multi-line expression started above.
        member(Id, Path),
        % Continue the multi-line expression started above.
        word_trace(Id, Core, _, T)
    % Continue the multi-line expression started above.
    ), Timed),
    % Sort list 'Timed' into 'Sorted', keeping duplicates.
    msort(Timed, Sorted),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(W, member(_-W, Sorted), Words),
    % State the fact: atomic list concat(Words, ' ', Surface).
    atomic_list_concat(Words, ' ', Surface).

% ---------------------------------------------------------------------------
% language_set_context/2 — set an indexical binding
% ---------------------------------------------------------------------------

% Define a clause for 'pai set context': succeed when the following conditions hold.
language_set_context(Indexical, Value) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(context_param(Indexical, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(context_param(Indexical, Value)).

% Reverse a list (without importing from lists to avoid clashes)
% Define a clause for 'reverse': succeed when the following conditions hold.
reverse(L, R) :- reverse(L, [], R).
% State the fact: reverse([], A, A).
reverse([], A, A).
% Define a clause for 'reverse': succeed when the following conditions hold.
reverse([H|T], A, R) :- reverse(T, [H|A], R).
