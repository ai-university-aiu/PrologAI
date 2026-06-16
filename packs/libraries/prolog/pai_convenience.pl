/*  PrologAI — library/convenience  (Specification Section 3.14)
    Also covers generators, tasks, config, peers, macros, and problems
    at the interface level; full implementations grow with later PRs.
*/

% Declare this file as the 'pai_convenience' module and list its exported predicates.
:- module(pai_convenience, [
    % convenience
    % Supply 'pai_case/3' as the next argument to the expression above.
    pai_case/3,
    % Supply 'pai_step/4' as the next argument to the expression above.
    pai_step/4,
    % Supply 'pai_confirm/2' as the next argument to the expression above.
    pai_confirm/2,
    % Supply 'pai_confute/2' as the next argument to the expression above.
    pai_confute/2,
    % Supply 'pai_ensure/2' as the next argument to the expression above.
    pai_ensure/2,
    % Supply 'pai_given/2' as the next argument to the expression above.
    pai_given/2,
    % Supply 'pai_superpose/2' as the next argument to the expression above.
    pai_superpose/2,
    % Supply 'pai_collapse/3' as the next argument to the expression above.
    pai_collapse/3,
    % generators
    % Supply 'pai_generator_create/2' as the next argument to the expression above.
    pai_generator_create/2,
    % Supply 'pai_generator_next/3' as the next argument to the expression above.
    pai_generator_next/3,
    % Supply 'pai_yield/1' as the next argument to the expression above.
    pai_yield/1,
    % Supply 'pai_generator_done/0' as the next argument to the expression above.
    pai_generator_done/0,
    % Supply 'pai_generator_collect/3' as the next argument to the expression above.
    pai_generator_collect/3,
    % tasks
    % Supply 'pai_task/2' as the next argument to the expression above.
    pai_task/2,
    % Supply 'pai_async/2' as the next argument to the expression above.
    pai_async/2,
    % Supply 'pai_sync/2' as the next argument to the expression above.
    pai_sync/2,
    % Supply 'pai_await/3' as the next argument to the expression above.
    pai_await/3,
    % Supply 'pai_free/1' as the next argument to the expression above.
    pai_free/1,
    % Supply 'pai_cancel/1' as the next argument to the expression above.
    pai_cancel/1,
    % Supply 'pai_scatter/3' as the next argument to the expression above.
    pai_scatter/3,
    % Supply 'pai_critical/2' as the next argument to the expression above.
    pai_critical/2,
    % Supply 'pai_ask/4' as the next argument to the expression above.
    pai_ask/4,
    % problems
    % Supply 'pai_challenge/3' as the next argument to the expression above.
    pai_challenge/3,
    % Supply 'pai_deliberate/0' as the next argument to the expression above.
    pai_deliberate/0,
    % Supply 'challenge_status/2' as the next argument to the expression above.
    challenge_status/2,
    % Supply 'challenge_result/2' as the next argument to the expression above.
    challenge_result/2,
    % config
    % Supply 'pai_config_open/3' as the next argument to the expression above.
    pai_config_open/3,
    % Supply 'pai_config_get/3' as the next argument to the expression above.
    pai_config_get/3,
    % Supply 'pai_config_set/3' as the next argument to the expression above.
    pai_config_set/3,
    % Supply 'pai_config_close/1' as the next argument to the expression above.
    pai_config_close/1,
    % peers
    % Supply 'pai_peer_register/1' as the next argument to the expression above.
    pai_peer_register/1,
    % Supply 'pai_peer_send/2' as the next argument to the expression above.
    pai_peer_send/2,
    % Supply 'pai_peer_broadcast/1' as the next argument to the expression above.
    pai_peer_broadcast/1,
    % macros
    % Supply 'pai_macro_define/3' as the next argument to the expression above.
    pai_macro_define/3,
    % Supply 'pai_macro_expand/3' as the next argument to the expression above.
    pai_macro_expand/3
% Close the expression opened above.
]).

% Import [maplist/2, maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/2, maplist/3]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2]).

% ---------------------------------------------------------------------------
% pai_case/3: readable case branching
% ---------------------------------------------------------------------------

%! pai_case(+Value, +Clauses, -Result) is det.
%  Clauses: list of (Pattern -> Result) or (Pattern -> Body, Result).
% Define a clause for 'pai case': succeed when the following conditions hold.
pai_case(Value, Clauses, Result) :-
    % Succeed for each element 'Value -> Result' that is a member of the list.
    member(Value -> Result, Clauses), !.
% Define a clause for 'pai case': succeed when the following conditions hold.
pai_case(_, Clauses, Result) :-
    % Succeed for each element 'default -> Result' that is a member of the list.
    member(default -> Result, Clauses), !.
% State the fact: pai case(_, _, no_match).
pai_case(_, _, no_match).

% ---------------------------------------------------------------------------
% pai_step/4: numeric iteration
% ---------------------------------------------------------------------------

% Define a clause for 'pai step': succeed when the following conditions hold.
pai_step(Start, End, By, N) :-
    % Check that 'By' is greater than '0'.
    By > 0,
    % Evaluate the arithmetic expression 'Start' and bind the result to 'N'.
    N is Start,
    % Check that 'N' is less than or equal to 'End'.
    N =< End.
% Define a clause for 'pai step': succeed when the following conditions hold.
pai_step(Start, End, By, N) :-
    % Check that 'By' is greater than '0'.
    By > 0,
    % Evaluate the arithmetic expression 'Start + By' and bind the result to 'Next'.
    Next is Start + By,
    % Check that 'Next' is less than or equal to 'End'.
    Next =< End,
    % State the fact: pai step(Next, End, By, N).
    pai_step(Next, End, By, N).

% ---------------------------------------------------------------------------
% Assertion helpers
% ---------------------------------------------------------------------------

% Define a clause for 'pai confirm': succeed when the following conditions hold.
pai_confirm(Goal, Msg) :-
    % Execute: ( call(Goal).
    ( call(Goal)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(assertion_failed(Msg), pai_confirm/2))
    % Close the expression opened above.
    ).

% Define a clause for 'pai confute': succeed when the following conditions hold.
pai_confute(Goal, Msg) :-
    % Execute: ( \+ call(Goal).
    ( \+ call(Goal)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(assertion_failed(Msg), pai_confute/2))
    % Close the expression opened above.
    ).

% Define a clause for 'pai ensure': succeed when the following conditions hold.
pai_ensure(Goal, Type) :-
    % Execute: ( call(Goal).
    ( call(Goal)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(type_error(Type, Goal), pai_ensure/2))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Lambda alias
% ---------------------------------------------------------------------------

% Define a clause for 'pai given': succeed when the following conditions hold.
pai_given(Params, Body) :- call(Params, Body).

% ---------------------------------------------------------------------------
% Nondeterminism conveniences
% ---------------------------------------------------------------------------

%! pai_superpose(+Alternatives, -Item) is nondet.
%  Nondeterministically enumerate Alternatives (like member/2).
% Define a clause for 'pai superpose': succeed when the following conditions hold.
pai_superpose(Alternatives, Item) :-
    % Succeed for each element 'Item' that is a member of the list.
    member(Item, Alternatives).

%! pai_collapse(+Goal, +Budget, -Results) is det.
%  Collect up to Budget solutions of Goal into Results (like findall).
% Define a clause for 'pai collapse': succeed when the following conditions hold.
pai_collapse(_, 0, []) :- !.
% Define a clause for 'pai collapse': succeed when the following conditions hold.
pai_collapse(Goal, Budget, Results) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(X, call(Goal, X), All),
    % Unify 'Total' with the number of elements in list 'All'.
    length(All, Total),
    % Evaluate the arithmetic expression 'min(Budget, Total)' and bind the result to 'Take'.
    Take is min(Budget, Total),
    % Unify 'Take' with the number of elements in list 'Results'.
    length(Results, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(Results, _, All).

% ---------------------------------------------------------------------------
% Generators (lazy sequences)
% ---------------------------------------------------------------------------

% Declare 'pai_gen_entry/3.  % Id, State, Goal' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_gen_entry/3.  % Id, State, Goal
% Declare 'pai_gen_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_gen_counter/1.
% State the fact: pai gen counter(0).
pai_gen_counter(0).

% Define a clause for 'next gen id': succeed when the following conditions hold.
next_gen_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_gen_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_gen_counter(N1)),
    % Check that 'Id' is unifiable with 'gen(N1)'.
    Id = gen(N1).

% Define a clause for 'pai generator create': succeed when the following conditions hold.
pai_generator_create(Goal, Id) :-
    % State a fact for 'next gen id' with the arguments listed below.
    next_gen_id(Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_gen_entry(Id, initial, Goal)).

% Define a clause for 'pai generator next': succeed when the following conditions hold.
pai_generator_next(Id, Binding, NextId) :-
    % State a fact for 'pai gen entry' with the arguments listed below.
    pai_gen_entry(Id, _, Goal),
    % Execute: ( call(Goal, Binding).
    ( call(Goal, Binding)
    % If the condition above succeeded, perform the following action.
    ->  NextId = Id
    % Otherwise (else branch), perform the following action.
    ;   NextId = done
    % Close the expression opened above.
    ).

% State a fact for 'pai yield' with the arguments listed below.
pai_yield(_).  % Used inside a generator goal to yield a value

% Execute: pai_generator_done.  % Signal generator exhaustion.
pai_generator_done.  % Signal generator exhaustion

% Define a clause for 'pai generator collect': succeed when the following conditions hold.
pai_generator_collect(Goal, N, Results) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(X, (between(1, N, _), call(Goal, X)), Results).

% ---------------------------------------------------------------------------
% Tasks (async/concurrent)
% ---------------------------------------------------------------------------

% Declare 'pai_task_entry/3.  % TaskId, Goal, Status(pending/done/cancelled)' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_task_entry/3.  % TaskId, Goal, Status(pending/done/cancelled)
% Declare 'pai_task_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_task_counter/1.
% State the fact: pai task counter(0).
pai_task_counter(0).

% Define a clause for 'next task id': succeed when the following conditions hold.
next_task_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_task_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_task_counter(N1)),
    % Check that 'Id' is unifiable with 'task(N1)'.
    Id = task(N1).

% Define a clause for 'pai task': succeed when the following conditions hold.
pai_task(Goal, TaskId) :-
    % State a fact for 'next task id' with the arguments listed below.
    next_task_id(TaskId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_task_entry(TaskId, Goal, pending)).

% Define a clause for 'pai async': succeed when the following conditions hold.
pai_async(Goals, TaskIds) :-
    % State the fact: maplist([Goal, TaskId]>>(pai_task(Goal, TaskId)), Goals, TaskIds).
    maplist([Goal, TaskId]>>(pai_task(Goal, TaskId)), Goals, TaskIds).

% Define a clause for 'pai sync': succeed when the following conditions hold.
pai_sync(Goals, Results) :-
    % State the fact: maplist([Goal, Result]>>(call(Goal, Result)), Goals, Results).
    maplist([Goal, Result]>>(call(Goal, Result)), Goals, Results).

% Define a clause for 'pai await': succeed when the following conditions hold.
pai_await(TaskId, _Timeout, Result) :-
    % State a fact for 'pai task entry' with the arguments listed below.
    pai_task_entry(TaskId, Goal, pending),
    % State a fact for 'call' with the arguments listed below.
    call(Goal, Result),
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_task_entry(TaskId, Goal, pending)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_task_entry(TaskId, Goal, done(Result))).
% Define a clause for 'pai await': succeed when the following conditions hold.
pai_await(TaskId, _Timeout, Result) :-
    % State the fact: pai task entry(TaskId, _, done(Result)).
    pai_task_entry(TaskId, _, done(Result)).

% Define a clause for 'pai free': succeed when the following conditions hold.
pai_free(TaskId) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_task_entry(TaskId, _, _)).

% Define a clause for 'pai cancel': succeed when the following conditions hold.
pai_cancel(TaskId) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_task_entry(TaskId, Goal, pending)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_task_entry(TaskId, Goal, cancelled)).

% Define a clause for 'pai scatter': succeed when the following conditions hold.
pai_scatter(Fn, Args, Results) :-
    % State the fact: maplist([Arg, Res]>>(call(Fn, Arg, Res)), Args, Results).
    maplist([Arg, Res]>>(call(Fn, Arg, Res)), Args, Results).

% Define a clause for 'pai critical': succeed when the following conditions hold.
pai_critical(MutexName, Goal) :-
    % State the fact: with mutex(MutexName, Goal).
    with_mutex(MutexName, Goal).

% Define a clause for 'pai ask': succeed when the following conditions hold.
pai_ask(Address, Message, _Timeout, Response) :-
    % Stub: for full implementation see PR 7 (receptors)
    % Write formatted output to the current output stream.
    format(atom(Response), "ack(~w, ~w)", [Address, Message]).

% ---------------------------------------------------------------------------
% Problems
% ---------------------------------------------------------------------------

% Declare 'pai_challenge_entry/3' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_challenge_entry/3.

% Define a clause for 'pai challenge': succeed when the following conditions hold.
pai_challenge(Id, Goal, Opts) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_challenge_entry(Id, Goal, Opts)).

% Execute: pai_deliberate :-.
pai_deliberate :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(pai_challenge_entry(Id, Goal, _Opts), (
        % Continue the multi-line expression started above.
        ( call(Goal)
        % If the condition above succeeded, perform the following action.
        ->  retract(pai_challenge_entry(Id, Goal, _)),
            % Continue the multi-line expression started above.
            assertz(pai_challenge_entry(Id, Goal, solved))
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    )).

% Define a clause for 'challenge status': succeed when the following conditions hold.
challenge_status(Id, Status) :-
    % State the fact: pai challenge entry(Id, _, Status).
    pai_challenge_entry(Id, _, Status).

% Define a clause for 'challenge result': succeed when the following conditions hold.
challenge_result(Id, Result) :-
    % State the fact: pai challenge entry(Id, _, Result).
    pai_challenge_entry(Id, _, Result).

% ---------------------------------------------------------------------------
% Config
% ---------------------------------------------------------------------------

% Declare 'pai_config_entry/3.   % StoreId, Key, Value' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_config_entry/3.   % StoreId, Key, Value

% Define a clause for 'pai config open': succeed when the following conditions hold.
pai_config_open(StoreId, _Path, _Opts) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_config_entry(StoreId, '$open', true)).

% Define a clause for 'pai config get': succeed when the following conditions hold.
pai_config_get(StoreId, Key, Value) :-
    % State the fact: pai config entry(StoreId, Key, Value).
    pai_config_entry(StoreId, Key, Value).

% Define a clause for 'pai config set': succeed when the following conditions hold.
pai_config_set(StoreId, Key, Value) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_config_entry(StoreId, Key, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_config_entry(StoreId, Key, Value)).

% Define a clause for 'pai config close': succeed when the following conditions hold.
pai_config_close(StoreId) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_config_entry(StoreId, _, _)).

% ---------------------------------------------------------------------------
% Peers
% ---------------------------------------------------------------------------

% Declare 'pai_peer_entry/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_peer_entry/1.
% Declare 'pai_peer_mailbox/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_peer_mailbox/2.

% Define a clause for 'pai peer register': succeed when the following conditions hold.
pai_peer_register(PeerId) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_peer_entry(PeerId)).

% Define a clause for 'pai peer send': succeed when the following conditions hold.
pai_peer_send(PeerId, Message) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_peer_mailbox(PeerId, Message)).

% Define a clause for 'pai peer broadcast': succeed when the following conditions hold.
pai_peer_broadcast(Message) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(pai_peer_entry(PeerId), pai_peer_send(PeerId, Message)).

% ---------------------------------------------------------------------------
% Macros
% ---------------------------------------------------------------------------

% Declare 'pai_macro_entry/3' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_macro_entry/3.

% Define a clause for 'pai macro define': succeed when the following conditions hold.
pai_macro_define(Name, Params, Body) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_macro_entry(Name, _, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_macro_entry(Name, Params, Body)).

% Define a clause for 'pai macro expand': succeed when the following conditions hold.
pai_macro_expand(Name, Args, Expanded) :-
    % State a fact for 'pai macro entry' with the arguments listed below.
    pai_macro_entry(Name, Params, Body),
    % State the fact: copy term(Params-Body, Args-Expanded).
    copy_term(Params-Body, Args-Expanded).
