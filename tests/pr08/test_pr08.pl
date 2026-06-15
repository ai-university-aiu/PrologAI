/*  PrologAI — PR 8 Subscribe/Publish Acceptance Tests

    AC-PR08-001: subscribe + publish — handler is invoked with the event.
    AC-PR08-002: unsubscribe removes the handler; no further deliveries.
    AC-PR08-003: publish returns in under 5 ms.
    AC-PR08-004: multiple subscribers all receive the event.
    AC-PR08-005: unsubscribe_all removes all handlers for a pattern.
    AC-PR08-006: subscribe/3 returns a handle.
    AC-PR08-007: handler exception does not kill the subscriber.
    AC-PR08-008: pattern matching — wildcard pattern matches multiple addresses.
    AC-PR08-009: publish to address with no subscribers completes silently.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   assertz(file_search_path(library, ActorsPath)).

:- use_module(library(plunit)).
:- use_module(library(pubsub)).

:- dynamic pr08_event_log/1.

:- begin_tests(pr08).

test(handler_invoked) :-
    retractall(pr08_event_log(_)),
    subscribe('test://chan', [E]>>(assertz(pr08_event_log(E))), H),
    publish('test://chan', ping),
    sleep(0.1),
    pr08_event_log(ping),
    unsubscribe(H).

test(unsubscribe_stops_delivery) :-
    retractall(pr08_event_log(_)),
    subscribe('test://chan2', [E]>>(assertz(pr08_event_log(E))), H),
    unsubscribe(H),
    publish('test://chan2', should_not_arrive),
    sleep(0.1),
    \+ pr08_event_log(should_not_arrive).

test(publish_returns_fast) :-
    subscribe('test://fast', [_]>>(sleep(1)), H),
    get_time(T0),
    publish('test://fast', go),
    get_time(T1),
    Elapsed is T1 - T0,
    Elapsed < 0.005,
    unsubscribe(H).

test(multiple_subscribers) :-
    retractall(pr08_event_log(_)),
    subscribe('test://multi', [_]>>(assertz(pr08_event_log(sub1))), H1),
    subscribe('test://multi', [_]>>(assertz(pr08_event_log(sub2))), H2),
    publish('test://multi', event),
    sleep(0.15),
    pr08_event_log(sub1),
    pr08_event_log(sub2),
    unsubscribe(H1),
    unsubscribe(H2).

test(unsubscribe_all) :-
    retractall(pr08_event_log(_)),
    subscribe('test://ua', [_]>>(assertz(pr08_event_log(ua1))), _),
    subscribe('test://ua', [_]>>(assertz(pr08_event_log(ua2))), _),
    unsubscribe_all('test://ua'),
    publish('test://ua', event),
    sleep(0.1),
    \+ pr08_event_log(ua1),
    \+ pr08_event_log(ua2).

test(subscribe3_returns_handle) :-
    subscribe('test://h', [_]>>(true), H),
    H = ps_handle(_),
    unsubscribe(H).

test(handler_exception_survives) :-
    subscribe('test://ex', [_]>>(throw(deliberate)), H),
    subscribe('test://ex', [E]>>(assertz(pr08_event_log(survived(E)))), H2),
    retractall(pr08_event_log(_)),
    publish('test://ex', ok),
    sleep(0.15),
    pr08_event_log(survived(ok)),
    unsubscribe(H),
    unsubscribe(H2).

test(wildcard_pattern) :-
    retractall(pr08_event_log(_)),
    subscribe(_AnyChannel, [E]>>(assertz(pr08_event_log(wild(E)))), H),
    publish('test://chan_a', event_a),
    sleep(0.1),
    pr08_event_log(wild(event_a)),
    unsubscribe(H).

test(no_subscribers_silent) :-
    publish('test://nobody', event).

:- end_tests(pr08).
