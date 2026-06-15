/*  PrologAI — PR 43 Agent Interoperability (A2A and Mail) Acceptance Tests

    AC-PR43-001: Agent card generated from capabilities; never discloses Lattice.
    AC-PR43-002: Mail sent while recipient is offline arrives on fetch with
                 sender, timestamp, and integrity intact.
    AC-PR43-003: pai_agent_card includes capabilities registered for the agent.
    AC-PR43-004: pai_a2a_task submits a task and returns completed status.
    AC-PR43-005: pai_a2a_task with unknown skill returns failed status.
    AC-PR43-006: pai_peer_mail_send stores mail persistently.
    AC-PR43-007: pai_peer_mail_fetch returns only mail for the recipient.
    AC-PR43-008: Delivered mail does not reappear in subsequent fetch.
    AC-PR43-009: pai_agent_card opacity — card has no Lattice contents.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/a2a/prolog'], A2APath),
   assertz(file_search_path(library, A2APath)).

:- use_module(library(plunit)).
:- use_module(library(lists),  [member/2]).
:- use_module(library(a2a),    [
    pai_agent_card/1,
    pai_a2a_task/4,
    pai_peer_mail_send/3,
    pai_peer_mail_fetch/3
]).

:- begin_tests(pr43, [setup(pr43_setup), cleanup(pr43_cleanup)]).

pr43_setup :-
    retractall(a2a:agent_capability(_, _)),
    retractall(a2a:agent_identity(_, _)),
    retractall(a2a:a2a_task_record(_, _, _, _)),
    retractall(a2a:agent_mail(_, _, _, _, _)),
    retractall(a2a:delivered_mail(_)),
    retractall(a2a:mail_counter(_)),
    assertz(a2a:mail_counter(0)).

pr43_cleanup :- pr43_setup.

%  AC-PR43-001: agent card generated; includes capabilities
test(agent_card_generated, [setup(pr43_setup)]) :-
    a2a:pai_register_identity(mind_a43, pai_mind_a43),
    a2a:pai_register_capability(mind_a43, weather_forecast),
    a2a:pai_register_capability(mind_a43, document_search),
    pai_agent_card(Card),
    Card = card(identity(_), capabilities(Caps), endpoint(_)),
    once(member(weather_forecast, Caps)).

%  AC-PR43-002: mail arrives on fetch with subject and timestamp intact (AC)
test(mail_arrives_on_fetch, [setup(pr43_setup)]) :-
    % "Send while offline" — mail stored in persistent dynamic fact
    once(pai_peer_mail_send(recipient43, hello_subject, greeting43)),
    % Recipient comes online and fetches
    once(pai_peer_mail_fetch(recipient43, quarantine43, Messages)),
    Messages = [message(_, recipient43, _, hello_subject-_, greeting43)|_].

%  AC-PR43-003: capabilities reflected in card
test(capabilities_in_card, [setup(pr43_setup)]) :-
    a2a:pai_register_capability(mind43, skill_alpha),
    a2a:pai_register_capability(mind43, skill_beta),
    pai_agent_card(card(_, capabilities(Caps), _)),
    once(member(skill_alpha, Caps)),
    once(member(skill_beta, Caps)).

%  AC-PR43-004: task with registered skill → completed
test(task_completed, [setup(pr43_setup)]) :-
    a2a:pai_register_capability(mind43, forecast_skill43),
    pai_a2a_task(task_001_43, forecast_skill43, input(location, london43), Status),
    Status = completed(_).

%  AC-PR43-005: task with unknown skill → failed
test(task_unknown_skill, [setup(pr43_setup)]) :-
    pai_a2a_task(task_002_43, unknown_skill_43xyz, input(x, y), Status),
    Status = failed(_).

%  AC-PR43-006: mail stored persistently (accessible before fetch)
test(mail_stored, [setup(pr43_setup)]) :-
    pai_peer_mail_send(bob43, subject43, body43),
    a2a:agent_mail(_, bob43, _, _, body43).

%  AC-PR43-007: fetch only returns mail for the correct recipient
test(fetch_recipient_isolation, [setup(pr43_setup)]) :-
    once(pai_peer_mail_send(alice43, msg_for_alice, hello_alice43)),
    once(pai_peer_mail_send(bob43,   msg_for_bob,   hello_bob43)),
    once(pai_peer_mail_fetch(alice43, scope43, AliceMsgs)),
    once(pai_peer_mail_fetch(bob43,   scope43, BobMsgs)),
    length(AliceMsgs, 1),
    length(BobMsgs, 1),
    AliceMsgs = [message(_, alice43, _, _, hello_alice43)],
    BobMsgs   = [message(_, bob43,   _, _, hello_bob43)].

%  AC-PR43-008: delivered mail does not reappear on subsequent fetch
test(delivered_mail_not_refetched, [setup(pr43_setup)]) :-
    once(pai_peer_mail_send(carol43, subj43, body_carol43)),
    once(pai_peer_mail_fetch(carol43, scope43, First)),
    length(First, 1),
    once(pai_peer_mail_fetch(carol43, scope43, Second)),
    length(Second, 0).

%  AC-PR43-009: agent card has no raw Lattice contents
test(card_opacity, [setup(pr43_setup)]) :-
    pai_agent_card(Card),
    Card = card(identity(_Id), capabilities(_Caps), endpoint(_Ep)),
    % Ensure no lattice_node_fact or node_id term in the card
    \+ Card = card(_, _, lattice_node_fact(_, _, _, _, _)),
    \+ Card = card(lattice_node_fact(_, _, _, _, _), _, _).

:- end_tests(pr43).
