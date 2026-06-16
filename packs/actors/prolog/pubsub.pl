/*  PrologAI — Subscribe and Publish  (Specification Section 3.5, PR 8)

    subscribe/2      — register a handler for events matching a pattern
    publish/2        — notify all matching subscribers asynchronously
    unsubscribe/1    — remove a subscription by handle
    unsubscribe_all/1 — remove all subscriptions for a pattern

    Handlers are called asynchronously so that publish/2 returns in < 5 ms.
    anchor_node/4 and prune_node/1 automatically call publish (wired here).
*/

% Declare this file as the 'pubsub' module and list its exported predicates.
:- module(pubsub, [
    % Continue the multi-line expression started above.
    subscribe/2,       % +Pattern, :Handler  -> -Handle (use subscribe/3 form)
    % Continue the multi-line expression started above.
    subscribe/3,       % +Pattern, :Handler, -Handle
    % Continue the multi-line expression started above.
    publish/2,         % +Address, +Event
    % Continue the multi-line expression started above.
    unsubscribe/1,     % +Handle
    % Continue the multi-line expression started above.
    unsubscribe_all/1  % +Pattern
% Close the expression opened above.
]).

% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate subscribe(+, 1).
% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate subscribe(+, 1, -).

% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Subscription registry
% ---------------------------------------------------------------------------

% Declare 'pubsub_subscription/3.   % Handle, Pattern, Handler' as dynamic — its facts may be added or removed at runtime.
:- dynamic pubsub_subscription/3.   % Handle, Pattern, Handler
% Declare 'pubsub_handle_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pubsub_handle_counter/1.
% State the fact: pubsub handle counter(0).
pubsub_handle_counter(0).

% Register the following goal to run automatically at load time.
:- initialization(mutex_create(pubsub_registry_mutex), now).

% Define a clause for 'ps lock': succeed when the following conditions hold.
ps_lock(Goal) :- with_mutex(pubsub_registry_mutex, Goal).

% Define a clause for 'next handle': succeed when the following conditions hold.
next_handle(Handle) :-
    % State a fact for 'ps lock' with the arguments listed below.
    ps_lock((
        % Continue the multi-line expression started above.
        retract(pubsub_handle_counter(N)),
        % Continue the multi-line expression started above.
        N1 is N + 1,
        % Continue the multi-line expression started above.
        assertz(pubsub_handle_counter(N1)),
        % Continue the multi-line expression started above.
        Handle = ps_handle(N1)
    % Close the expression opened above.
    )).

% ---------------------------------------------------------------------------
% subscribe/2 and subscribe/3
% ---------------------------------------------------------------------------

% Define a clause for 'subscribe': succeed when the following conditions hold.
subscribe(Pattern, Handler) :-
    % State the fact: subscribe(Pattern, Handler, _).
    subscribe(Pattern, Handler, _).

% Define a clause for 'subscribe': succeed when the following conditions hold.
subscribe(Pattern, Handler, Handle) :-
    % State a fact for 'next handle' with the arguments listed below.
    next_handle(Handle),
    % State the fact: ps lock(assertz(pubsub_subscription(Handle, Pattern, Handler))).
    ps_lock(assertz(pubsub_subscription(Handle, Pattern, Handler))).

% ---------------------------------------------------------------------------
% publish/2  — asynchronous notification to all matching handlers
% ---------------------------------------------------------------------------

% Define a clause for 'publish': succeed when the following conditions hold.
publish(Address, Event) :-
    % State a fact for 'ps lock' with the arguments listed below.
    ps_lock(findall(H, (
        % Continue the multi-line expression started above.
        pubsub_subscription(_, Pattern, H),
        % Continue the multi-line expression started above.
        \+ \+ Address = Pattern
    % Continue the multi-line expression started above.
    ), Handlers)),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([Handler]>>(
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            thread_create(call(Handler, Event), _, [detached(true)]),
            % Supply '_' as the next argument to the expression above.
            _,
            % Supply 'true' as the next argument to the expression above.
            true
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Handlers).

% ---------------------------------------------------------------------------
% unsubscribe/1
% ---------------------------------------------------------------------------

% Define a clause for 'unsubscribe': succeed when the following conditions hold.
unsubscribe(Handle) :-
    % State the fact: ps lock(retractall(pubsub_subscription(Handle, _, _))).
    ps_lock(retractall(pubsub_subscription(Handle, _, _))).

% ---------------------------------------------------------------------------
% unsubscribe_all/1
% ---------------------------------------------------------------------------

% Define a clause for 'unsubscribe all': succeed when the following conditions hold.
unsubscribe_all(Pattern) :-
    % State the fact: ps lock(retractall(pubsub_subscription(_, Pattern, _))).
    ps_lock(retractall(pubsub_subscription(_, Pattern, _))).
