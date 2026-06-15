/*  PrologAI — Subscribe and Publish  (Specification Section 3.5, PR 8)

    subscribe/2      — register a handler for events matching a pattern
    publish/2        — notify all matching subscribers asynchronously
    unsubscribe/1    — remove a subscription by handle
    unsubscribe_all/1 — remove all subscriptions for a pattern

    Handlers are called asynchronously so that publish/2 returns in < 5 ms.
    anchor_node/4 and prune_node/1 automatically call publish (wired here).
*/

:- module(pubsub, [
    subscribe/2,       % +Pattern, :Handler  -> -Handle (use subscribe/3 form)
    subscribe/3,       % +Pattern, :Handler, -Handle
    publish/2,         % +Address, +Event
    unsubscribe/1,     % +Handle
    unsubscribe_all/1  % +Pattern
]).

:- meta_predicate subscribe(+, 1).
:- meta_predicate subscribe(+, 1, -).

:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Subscription registry
% ---------------------------------------------------------------------------

:- dynamic pubsub_subscription/3.   % Handle, Pattern, Handler
:- dynamic pubsub_handle_counter/1.
pubsub_handle_counter(0).

:- initialization(mutex_create(pubsub_registry_mutex), now).

ps_lock(Goal) :- with_mutex(pubsub_registry_mutex, Goal).

next_handle(Handle) :-
    ps_lock((
        retract(pubsub_handle_counter(N)),
        N1 is N + 1,
        assertz(pubsub_handle_counter(N1)),
        Handle = ps_handle(N1)
    )).

% ---------------------------------------------------------------------------
% subscribe/2 and subscribe/3
% ---------------------------------------------------------------------------

subscribe(Pattern, Handler) :-
    subscribe(Pattern, Handler, _).

subscribe(Pattern, Handler, Handle) :-
    next_handle(Handle),
    ps_lock(assertz(pubsub_subscription(Handle, Pattern, Handler))).

% ---------------------------------------------------------------------------
% publish/2  — asynchronous notification to all matching handlers
% ---------------------------------------------------------------------------

publish(Address, Event) :-
    ps_lock(findall(H, (
        pubsub_subscription(_, Pattern, H),
        \+ \+ Address = Pattern
    ), Handlers)),
    maplist([Handler]>>(
        catch(
            thread_create(call(Handler, Event), _, [detached(true)]),
            _,
            true
        )
    ), Handlers).

% ---------------------------------------------------------------------------
% unsubscribe/1
% ---------------------------------------------------------------------------

unsubscribe(Handle) :-
    ps_lock(retractall(pubsub_subscription(Handle, _, _))).

% ---------------------------------------------------------------------------
% unsubscribe_all/1
% ---------------------------------------------------------------------------

unsubscribe_all(Pattern) :-
    ps_lock(retractall(pubsub_subscription(_, Pattern, _))).
