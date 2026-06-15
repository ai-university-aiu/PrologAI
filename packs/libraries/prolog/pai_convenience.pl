/*  PrologAI — library/convenience  (Specification Section 3.14)
    Also covers generators, tasks, config, peers, macros, and problems
    at the interface level; full implementations grow with later PRs.
*/

:- module(pai_convenience, [
    % convenience
    pai_case/3,
    pai_step/4,
    pai_confirm/2,
    pai_confute/2,
    pai_ensure/2,
    pai_given/2,
    pai_superpose/2,
    pai_collapse/3,
    % generators
    pai_generator_create/2,
    pai_generator_next/3,
    pai_yield/1,
    pai_generator_done/0,
    pai_generator_collect/3,
    % tasks
    pai_task/2,
    pai_async/2,
    pai_sync/2,
    pai_await/3,
    pai_free/1,
    pai_cancel/1,
    pai_scatter/3,
    pai_critical/2,
    pai_ask/4,
    % problems
    pai_challenge/3,
    pai_deliberate/0,
    challenge_status/2,
    challenge_result/2,
    % config
    pai_config_open/3,
    pai_config_get/3,
    pai_config_set/3,
    pai_config_close/1,
    % peers
    pai_peer_register/1,
    pai_peer_send/2,
    pai_peer_broadcast/1,
    % macros
    pai_macro_define/3,
    pai_macro_expand/3
]).

:- use_module(library(apply),  [maplist/2, maplist/3]).
:- use_module(library(lists),  [member/2]).

% ---------------------------------------------------------------------------
% pai_case/3: readable case branching
% ---------------------------------------------------------------------------

%! pai_case(+Value, +Clauses, -Result) is det.
%  Clauses: list of (Pattern -> Result) or (Pattern -> Body, Result).
pai_case(Value, Clauses, Result) :-
    member(Value -> Result, Clauses), !.
pai_case(_, Clauses, Result) :-
    member(default -> Result, Clauses), !.
pai_case(_, _, no_match).

% ---------------------------------------------------------------------------
% pai_step/4: numeric iteration
% ---------------------------------------------------------------------------

pai_step(Start, End, By, N) :-
    By > 0,
    N is Start,
    N =< End.
pai_step(Start, End, By, N) :-
    By > 0,
    Next is Start + By,
    Next =< End,
    pai_step(Next, End, By, N).

% ---------------------------------------------------------------------------
% Assertion helpers
% ---------------------------------------------------------------------------

pai_confirm(Goal, Msg) :-
    ( call(Goal)
    ->  true
    ;   throw(error(assertion_failed(Msg), pai_confirm/2))
    ).

pai_confute(Goal, Msg) :-
    ( \+ call(Goal)
    ->  true
    ;   throw(error(assertion_failed(Msg), pai_confute/2))
    ).

pai_ensure(Goal, Type) :-
    ( call(Goal)
    ->  true
    ;   throw(error(type_error(Type, Goal), pai_ensure/2))
    ).

% ---------------------------------------------------------------------------
% Lambda alias
% ---------------------------------------------------------------------------

pai_given(Params, Body) :- call(Params, Body).

% ---------------------------------------------------------------------------
% Nondeterminism conveniences
% ---------------------------------------------------------------------------

%! pai_superpose(+Alternatives, -Item) is nondet.
%  Nondeterministically enumerate Alternatives (like member/2).
pai_superpose(Alternatives, Item) :-
    member(Item, Alternatives).

%! pai_collapse(+Goal, +Budget, -Results) is det.
%  Collect up to Budget solutions of Goal into Results (like findall).
pai_collapse(_, 0, []) :- !.
pai_collapse(Goal, Budget, Results) :-
    findall(X, call(Goal, X), All),
    length(All, Total),
    Take is min(Budget, Total),
    length(Results, Take),
    append(Results, _, All).

% ---------------------------------------------------------------------------
% Generators (lazy sequences)
% ---------------------------------------------------------------------------

:- dynamic pai_gen_entry/3.  % Id, State, Goal
:- dynamic pai_gen_counter/1.
pai_gen_counter(0).

next_gen_id(Id) :-
    retract(pai_gen_counter(N)),
    N1 is N + 1,
    assertz(pai_gen_counter(N1)),
    Id = gen(N1).

pai_generator_create(Goal, Id) :-
    next_gen_id(Id),
    assertz(pai_gen_entry(Id, initial, Goal)).

pai_generator_next(Id, Binding, NextId) :-
    pai_gen_entry(Id, _, Goal),
    ( call(Goal, Binding)
    ->  NextId = Id
    ;   NextId = done
    ).

pai_yield(_).  % Used inside a generator goal to yield a value

pai_generator_done.  % Signal generator exhaustion

pai_generator_collect(Goal, N, Results) :-
    findall(X, (between(1, N, _), call(Goal, X)), Results).

% ---------------------------------------------------------------------------
% Tasks (async/concurrent)
% ---------------------------------------------------------------------------

:- dynamic pai_task_entry/3.  % TaskId, Goal, Status(pending/done/cancelled)
:- dynamic pai_task_counter/1.
pai_task_counter(0).

next_task_id(Id) :-
    retract(pai_task_counter(N)),
    N1 is N + 1,
    assertz(pai_task_counter(N1)),
    Id = task(N1).

pai_task(Goal, TaskId) :-
    next_task_id(TaskId),
    assertz(pai_task_entry(TaskId, Goal, pending)).

pai_async(Goals, TaskIds) :-
    maplist([Goal, TaskId]>>(pai_task(Goal, TaskId)), Goals, TaskIds).

pai_sync(Goals, Results) :-
    maplist([Goal, Result]>>(call(Goal, Result)), Goals, Results).

pai_await(TaskId, _Timeout, Result) :-
    pai_task_entry(TaskId, Goal, pending),
    call(Goal, Result),
    retract(pai_task_entry(TaskId, Goal, pending)),
    assertz(pai_task_entry(TaskId, Goal, done(Result))).
pai_await(TaskId, _Timeout, Result) :-
    pai_task_entry(TaskId, _, done(Result)).

pai_free(TaskId) :-
    retractall(pai_task_entry(TaskId, _, _)).

pai_cancel(TaskId) :-
    retract(pai_task_entry(TaskId, Goal, pending)),
    assertz(pai_task_entry(TaskId, Goal, cancelled)).

pai_scatter(Fn, Args, Results) :-
    maplist([Arg, Res]>>(call(Fn, Arg, Res)), Args, Results).

pai_critical(MutexName, Goal) :-
    with_mutex(MutexName, Goal).

pai_ask(Address, Message, _Timeout, Response) :-
    % Stub: for full implementation see PR 7 (receptors)
    format(atom(Response), "ack(~w, ~w)", [Address, Message]).

% ---------------------------------------------------------------------------
% Problems
% ---------------------------------------------------------------------------

:- dynamic pai_challenge_entry/3.

pai_challenge(Id, Goal, Opts) :-
    assertz(pai_challenge_entry(Id, Goal, Opts)).

pai_deliberate :-
    forall(pai_challenge_entry(Id, Goal, _Opts), (
        ( call(Goal)
        ->  retract(pai_challenge_entry(Id, Goal, _)),
            assertz(pai_challenge_entry(Id, Goal, solved))
        ;   true
        )
    )).

challenge_status(Id, Status) :-
    pai_challenge_entry(Id, _, Status).

challenge_result(Id, Result) :-
    pai_challenge_entry(Id, _, Result).

% ---------------------------------------------------------------------------
% Config
% ---------------------------------------------------------------------------

:- dynamic pai_config_entry/3.   % StoreId, Key, Value

pai_config_open(StoreId, _Path, _Opts) :-
    assertz(pai_config_entry(StoreId, '$open', true)).

pai_config_get(StoreId, Key, Value) :-
    pai_config_entry(StoreId, Key, Value).

pai_config_set(StoreId, Key, Value) :-
    retractall(pai_config_entry(StoreId, Key, _)),
    assertz(pai_config_entry(StoreId, Key, Value)).

pai_config_close(StoreId) :-
    retractall(pai_config_entry(StoreId, _, _)).

% ---------------------------------------------------------------------------
% Peers
% ---------------------------------------------------------------------------

:- dynamic pai_peer_entry/1.
:- dynamic pai_peer_mailbox/2.

pai_peer_register(PeerId) :-
    assertz(pai_peer_entry(PeerId)).

pai_peer_send(PeerId, Message) :-
    assertz(pai_peer_mailbox(PeerId, Message)).

pai_peer_broadcast(Message) :-
    forall(pai_peer_entry(PeerId), pai_peer_send(PeerId, Message)).

% ---------------------------------------------------------------------------
% Macros
% ---------------------------------------------------------------------------

:- dynamic pai_macro_entry/3.

pai_macro_define(Name, Params, Body) :-
    retractall(pai_macro_entry(Name, _, _)),
    assertz(pai_macro_entry(Name, Params, Body)).

pai_macro_expand(Name, Args, Expanded) :-
    pai_macro_entry(Name, Params, Body),
    copy_term(Params-Body, Args-Expanded).
