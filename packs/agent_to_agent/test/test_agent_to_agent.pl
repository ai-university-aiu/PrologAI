/*  PrologAI — Agent Interoperability (A2A and Durable Mail) Test Suite  (PR 43)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/agent_to_agent/test/test_agent_to_agent.pl
*/

% Declare this file as a test module.
:- module(test_agent_to_agent, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(agent_to_agent)).

% Reset every dynamic fact in the pack so each test starts from a clean state.
reset_agent_to_agent :-
    % Clear all registered agent capabilities.
    retractall(agent_to_agent:agent_to_agent_agent_capability(_, _)),
    % Clear all registered agent identities.
    retractall(agent_to_agent:agent_to_agent_agent_identity(_, _)),
    % Clear all stored task records.
    retractall(agent_to_agent:agent_to_agent_task_record(_, _, _, _)),
    % Clear all stored mail.
    retractall(agent_to_agent:agent_to_agent_agent_mail(_, _, _, _, _)),
    % Clear the delivered-mail markers.
    retractall(agent_to_agent:agent_to_agent_delivered_mail(_)),
    % Clear the mail id counter.
    retractall(agent_to_agent:agent_to_agent_mail_counter(_)),
    % Reset the mail id counter to zero.
    assertz(agent_to_agent:agent_to_agent_mail_counter(0)).

% Open the test block for agent_to_agent.
:- begin_tests(agent_to_agent).

% AC-001: registered capabilities appear in the generated agent card.
test(capabilities_appear_in_card, [setup(reset_agent_to_agent)]) :-
    % Register an identity for the mind.
    agent_to_agent:agent_to_agent_register_identity(mind_a, pai_mind_a),
    % Register a first capability.
    agent_to_agent:agent_to_agent_register_capability(mind_a, weather_forecast),
    % Register a second capability.
    agent_to_agent:agent_to_agent_register_capability(mind_a, document_search),
    % Generate the agent card.
    agent_to_agent_agent_card(Card),
    % The card is the expected identity/capabilities/endpoint shape.
    Card = card(identity(pai_mind_a), capabilities(Caps), endpoint(local)),
    % The first capability is present in the card.
    assertion(memberchk(weather_forecast, Caps)),
    % The second capability is present in the card.
    assertion(memberchk(document_search, Caps)).

% AC-002: the card discloses no raw Lattice contents (opacity principle).
test(card_preserves_opacity, [setup(reset_agent_to_agent)]) :-
    % Generate the agent card with no capabilities registered.
    agent_to_agent_agent_card(Card),
    % An empty registry yields the anonymous identity and an empty capability list.
    assertion(Card == card(identity(agent_to_agent_anonymous), capabilities([]), endpoint(local))),
    % The card holds no lattice node fact in the endpoint slot.
    assertion(\+ Card = card(_, _, lattice_node_fact(_, _, _, _, _))).

% AC-003: a task for a registered skill returns a completed status with its artifact.
test(task_with_known_skill_completes, [setup(reset_agent_to_agent)]) :-
    % Register the skill the task will request.
    agent_to_agent:agent_to_agent_register_capability(mind_a, forecast_skill),
    % Submit and execute the task.
    agent_to_agent_task(task_1, forecast_skill, input(location, london), Status),
    % The task completes carrying an artifact tagged with its id and skill.
    assertion(Status == completed(artifact(task_1, forecast_skill, result(forecast_skill, input(location, london), processed)))).

% AC-004: a task for an unregistered skill returns a failed status.
test(task_with_unknown_skill_fails, [setup(reset_agent_to_agent)]) :-
    % Submit a task whose skill was never registered.
    agent_to_agent_task(task_2, unknown_skill_xyz, input(x, y), Status),
    % The task fails, naming the unknown skill.
    assertion(Status == failed(unknown_skill)).

% AC-005: mail sent while the recipient is offline arrives intact on fetch.
test(mail_sent_offline_arrives_on_fetch, [setup(reset_agent_to_agent)]) :-
    % Send addressed mail while the recipient is not awake.
    agent_to_agent_peer_mail_send(recipient_a, hello_subject, greeting_body),
    % The recipient later fetches its pending mail into a scope.
    agent_to_agent_peer_mail_fetch(recipient_a, quarantine, Messages),
    % Exactly one message is delivered.
    assertion(Messages = [_]),
    % The message preserves recipient, subject, and body.
    Messages = [message(_, To, _, Subject-_, Body)],
    % The recipient address is intact.
    assertion(To == recipient_a),
    % The subject is intact.
    assertion(Subject == hello_subject),
    % The body is intact.
    assertion(Body == greeting_body).

% AC-006: fetch returns only the addressee's mail, and delivered mail is not re-fetched.
test(fetch_isolates_recipient_and_marks_delivered, [setup(reset_agent_to_agent)]) :-
    % Send one message to alice.
    agent_to_agent_peer_mail_send(alice, msg_for_alice, hello_alice),
    % Send one message to bob.
    agent_to_agent_peer_mail_send(bob, msg_for_bob, hello_bob),
    % Alice fetches her mail.
    agent_to_agent_peer_mail_fetch(alice, scope, AliceMsgs),
    % Alice receives only her own message.
    assertion(AliceMsgs = [message(_, alice, _, msg_for_alice-_, hello_alice)]),
    % Bob fetches his mail.
    agent_to_agent_peer_mail_fetch(bob, scope, BobMsgs),
    % Bob receives only his own message.
    assertion(BobMsgs = [message(_, bob, _, msg_for_bob-_, hello_bob)]),
    % Alice fetches again after delivery.
    agent_to_agent_peer_mail_fetch(alice, scope, AliceAgain),
    % The already-delivered mail does not reappear.
    assertion(AliceAgain == []).

% Close the test block for agent_to_agent.
:- end_tests(agent_to_agent).
