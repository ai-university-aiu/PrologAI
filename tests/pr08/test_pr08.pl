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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'pubsub' library so its predicates are available here.
:- use_module(library(pubsub)).

% Declare 'pr08_event_log/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pr08_event_log/1.

% Execute the compile-time directive: begin_tests(pr08).
:- begin_tests(pr08).

% Define a clause for 'test': succeed when the following conditions hold.
test(handler_invoked) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://chan', [E]>>(assertz(pr08_event_log(E))), H),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://chan', ping),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % State a fact for 'pr08 event log' with the arguments listed below.
    pr08_event_log(ping),
    % State the fact: unsubscribe(H).
    unsubscribe(H).

% Define a clause for 'test': succeed when the following conditions hold.
test(unsubscribe_stops_delivery) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://chan2', [E]>>(assertz(pr08_event_log(E))), H),
    % State a fact for 'unsubscribe' with the arguments listed below.
    unsubscribe(H),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://chan2', should_not_arrive),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % Succeed only if 'pr08_event_log(should_not_arrive' cannot be proved (negation as failure).
    \+ pr08_event_log(should_not_arrive).

% Define a clause for 'test': succeed when the following conditions hold.
test(publish_returns_fast) :-
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://fast', [_]>>(sleep(1)), H),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://fast', go),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T1),
    % Evaluate the arithmetic expression 'T1 - T0' and bind the result to 'Elapsed'.
    Elapsed is T1 - T0,
    % Check that 'Elapsed' is less than '0.005'.
    Elapsed < 0.005,
    % State the fact: unsubscribe(H).
    unsubscribe(H).

% Define a clause for 'test': succeed when the following conditions hold.
test(multiple_subscribers) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://multi', [_]>>(assertz(pr08_event_log(sub1))), H1),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://multi', [_]>>(assertz(pr08_event_log(sub2))), H2),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://multi', event),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.15),
    % State a fact for 'pr08 event log' with the arguments listed below.
    pr08_event_log(sub1),
    % State a fact for 'pr08 event log' with the arguments listed below.
    pr08_event_log(sub2),
    % State a fact for 'unsubscribe' with the arguments listed below.
    unsubscribe(H1),
    % State the fact: unsubscribe(H2).
    unsubscribe(H2).

% Define a clause for 'test': succeed when the following conditions hold.
test(unsubscribe_all) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://ua', [_]>>(assertz(pr08_event_log(ua1))), _),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://ua', [_]>>(assertz(pr08_event_log(ua2))), _),
    % State a fact for 'unsubscribe all' with the arguments listed below.
    unsubscribe_all('test://ua'),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://ua', event),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % Succeed only if 'pr08_event_log(ua1' cannot be proved (negation as failure).
    \+ pr08_event_log(ua1),
    % Succeed only if 'pr08_event_log(ua2' cannot be proved (negation as failure).
    \+ pr08_event_log(ua2).

% Define a clause for 'test': succeed when the following conditions hold.
test(subscribe3_returns_handle) :-
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://h', [_]>>(true), H),
    % Check that 'H' is unifiable with 'ps_handle(_)'.
    H = ps_handle(_),
    % State the fact: unsubscribe(H).
    unsubscribe(H).

% Define a clause for 'test': succeed when the following conditions hold.
test(handler_exception_survives) :-
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://ex', [_]>>(throw(deliberate)), H),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe('test://ex', [E]>>(assertz(pr08_event_log(survived(E)))), H2),
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://ex', ok),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.15),
    % State a fact for 'pr08 event log' with the arguments listed below.
    pr08_event_log(survived(ok)),
    % State a fact for 'unsubscribe' with the arguments listed below.
    unsubscribe(H),
    % State the fact: unsubscribe(H2).
    unsubscribe(H2).

% Define a clause for 'test': succeed when the following conditions hold.
test(wildcard_pattern) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr08_event_log(_)),
    % State a fact for 'subscribe' with the arguments listed below.
    subscribe(_AnyChannel, [E]>>(assertz(pr08_event_log(wild(E)))), H),
    % State a fact for 'publish' with the arguments listed below.
    publish('test://chan_a', event_a),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % State a fact for 'pr08 event log' with the arguments listed below.
    pr08_event_log(wild(event_a)),
    % State the fact: unsubscribe(H).
    unsubscribe(H).

% Define a clause for 'test': succeed when the following conditions hold.
test(no_subscribers_silent) :-
    % State the fact: publish('test://nobody', event).
    publish('test://nobody', event).

% Execute the compile-time directive: end_tests(pr08).
:- end_tests(pr08).
