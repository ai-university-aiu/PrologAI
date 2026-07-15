/*  PrologAI — Actors Pack Test Suite  (WP actors, PRs 6-8)

    Behavioural acceptance tests for the three submodules that make up the
    multi-file 'actors' pack:
      cyclic_actor — proactive background threads (start/list/status/stop),
      receptor     — reactive signal:// message endpoints (send/handle/drain),
      pubsub       — subscribe/publish event distribution.

    Real assertions are made on the exported predicates' outputs, mirroring the
    legacy tests/pr06, tests/pr07 and tests/pr08 acceptance suites without
    copying their module names.

    Run with:
        swipl -g "run_tests, halt" test_actors.pl
*/

%% Declare this file as an internal test module that exports nothing.
:- module(test_actors, []).

%% Load the PLUnit test framework.
:- use_module(library(plunit)).
%% Import list membership checking used to assert registry contents.
:- use_module(library(lists), [memberchk/2]).
%% Load the cyclic_actor submodule (proactive background actors).
:- use_module(library(cyclic_actor)).
%% Load the receptor submodule (reactive signal:// endpoints).
:- use_module(library(receptor)).
%% Load the pubsub submodule (subscribe/publish event bus).
:- use_module(library(pubsub)).

%% Dynamic sink that a receptor handler asserts into so we can verify delivery.
:- dynamic actors_received/1.
%% Dynamic sink that a pubsub subscriber asserts into so we can verify delivery.
:- dynamic actors_delivered/1.

%% poll_for(+Goal): retry Goal up to one second (50 x 20 ms) awaiting async delivery.
poll_for(Goal) :-
    %% Delegate to the counted form starting with fifty remaining attempts.
    poll_for(Goal, 50).

%% poll_for(+Goal, +Attempts): first clause succeeds immediately once Goal holds.
poll_for(Goal, _Attempts) :-
    %% If the goal is already true we are done and commit to this solution.
    call(Goal), !.
%% poll_for(+Goal, +Attempts): otherwise sleep briefly and try again while attempts remain.
poll_for(Goal, Attempts) :-
    %% Only keep polling while there are attempts left to spend.
    Attempts > 0,
    %% Wait twenty milliseconds for the background thread to make progress.
    sleep(0.02),
    %% Count down one attempt.
    Next is Attempts - 1,
    %% Recurse with the reduced attempt budget.
    poll_for(Goal, Next).

%% Open the PLUnit block collecting the actors tests.
:- begin_tests(actors).

%% cyclic_actor lifecycle: a started actor is listed, reports a running status dict, and is removed on stop.
test(cyclic_actor_lifecycle) :-
    %% Start a proactive actor that runs the trivial goal every 100 ms.
    cyclic_actor(actors_life, true, 100),
    %% Read the current registry of running actor names.
    cyclic_actor_list(Running),
    %% The freshly started actor must appear in the registry.
    assertion(memberchk(actors_life, Running)),
    %% Query the structured status dict for this actor.
    cyclic_actor_status(actors_life, Status),
    %% The reported name field must be the actor we started.
    assertion(get_dict(name, Status, actors_life)),
    %% A live actor must report the running state.
    assertion(get_dict(state, Status, running)),
    %% The cycle counter must be a concrete integer.
    assertion((get_dict(cycle_count, Status, CC), integer(CC))),
    %% The error counter must be a concrete integer.
    assertion((get_dict(error_count, Status, EC), integer(EC))),
    %% Gracefully stop the actor, which blocks until the thread exits.
    cyclic_actor_stop(actors_life),
    %% Re-read the registry after the stop.
    cyclic_actor_list(RunningAfter),
    %% The stopped actor must no longer be listed.
    assertion(\+ memberchk(actors_life, RunningAfter)).

%% cyclic_actor counting: an actor cycling every 50 ms accumulates cycles over time.
test(cyclic_actor_cycle_count_grows) :-
    %% Start an actor that does nothing but cycle every 50 ms.
    cyclic_actor(actors_counter, true, 50),
    %% Give it 0.6 s, long enough for at least nine full cycles.
    sleep(0.6),
    %% Read back its status dict.
    cyclic_actor_status(actors_counter, Status),
    %% Extract the accumulated cycle count.
    get_dict(cycle_count, Status, CC),
    %% At least nine cycles must have elapsed in 0.6 s at 50 ms each.
    assertion(CC >= 9),
    %% Stop the actor before finishing the test.
    cyclic_actor_stop(actors_counter).

%% cyclic_actor uniqueness: creating a second actor with an existing name throws already_exists.
test(cyclic_actor_duplicate_throws,
     %% Declare the exact error term this test is expected to raise.
     [throws(error(actor_error(already_exists, actors_dup), _))]) :-
    %% Start the first actor under the name we will collide with.
    cyclic_actor(actors_dup, true, 200),
    %% Attempt the duplicate creation, cleaning up before re-raising the error.
    catch(
        %% The colliding second creation, which must throw already_exists.
        cyclic_actor(actors_dup, true, 200),
        %% Bind whatever error is raised.
        Err,
        %% Stop the surviving first actor, then re-raise for the throws/1 option to match.
        ( cyclic_actor_stop(actors_dup), throw(Err) )
    ).

%% receptor delivery: a message sent to a signal:// endpoint reaches its handler.
test(receptor_send_and_handle) :-
    %% Clear any residue from a prior run of this sink (module-qualified so the handler thread and this test agree).
    retractall(test_actors:actors_received(_)),
    %% Create a reactive receptor whose handler records each message it receives.
    receptor('signal://localhost/actors_r1',
             %% The handler asserts the delivered message into our module-qualified dynamic sink.
             [Msg]>>(assertz(test_actors:actors_received(Msg)))),
    %% Enqueue a message to the receptor (non-blocking).
    send_message('signal://localhost/actors_r1', hello_actor),
    %% Wait for the handler thread to record the delivery.
    assertion(poll_for(test_actors:actors_received(hello_actor))),
    %% Drain the backlog and terminate the receptor thread.
    receptor_decommission('signal://localhost/actors_r1'),
    %% After decommission the backlog count reports zero remaining messages.
    receptor_backlog_count('signal://localhost/actors_r1', Backlog),
    %% A decommissioned (unknown) receptor reports a zero backlog.
    assertion(Backlog =:= 0).

%% receptor validation: a non signal:// address is rejected with a domain error.
test(receptor_bad_address_throws,
     %% The malformed address must raise a domain_error naming the bad value.
     [throws(error(domain_error(signal_address, plain_atom), _))]) :-
    %% Attempt to create a receptor on an address that is not a signal:// URI.
    receptor(plain_atom, writeln).

%% pubsub delivery: subscribe returns a handle and publish reaches the subscriber.
test(pubsub_subscribe_publish) :-
    %% Clear any residue from a prior run of this sink (module-qualified so the subscriber thread and this test agree).
    retractall(test_actors:actors_delivered(_)),
    %% Subscribe a handler to a channel, capturing the returned handle.
    subscribe('test://actors_chan',
              %% The handler asserts the published event into our module-qualified dynamic sink.
              [Event]>>(assertz(test_actors:actors_delivered(Event))),
              Handle),
    %% The returned handle must be the documented ps_handle/1 shape.
    assertion(Handle = ps_handle(_)),
    %% Publish an event to the subscribed channel.
    publish('test://actors_chan', ping_actor),
    %% Wait for the asynchronous subscriber thread to record the event.
    assertion(poll_for(test_actors:actors_delivered(ping_actor))),
    %% Remove the subscription by its handle.
    unsubscribe(Handle),
    %% Clear the sink so we can prove no further deliveries arrive.
    retractall(test_actors:actors_delivered(_)),
    %% Publish again after unsubscribing.
    publish('test://actors_chan', after_unsub),
    %% Give any (erroneous) delivery a chance to land.
    sleep(0.1),
    %% No event may be delivered once the handle has been unsubscribed.
    assertion(\+ test_actors:actors_delivered(after_unsub)).

%% Close the PLUnit block collecting the actors tests.
:- end_tests(actors).
