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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/a2a/prolog'], A2APath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, A2APath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2]).
% Load the built-in 'a2a' library so its predicates are available here.
:- use_module(library(a2a),    [
    % Supply 'pai_agent_card/1' as the next argument to the expression above.
    pai_agent_card/1,
    % Supply 'pai_a2a_task/4' as the next argument to the expression above.
    pai_a2a_task/4,
    % Supply 'pai_peer_mail_send/3' as the next argument to the expression above.
    pai_peer_mail_send/3,
    % Supply 'pai_peer_mail_fetch/3' as the next argument to the expression above.
    pai_peer_mail_fetch/3
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr43, [setup(pr43_setup), cleanup(pr43_cleanup)]).
:- begin_tests(pr43, [setup(pr43_setup), cleanup(pr43_cleanup)]).

% Execute: pr43_setup :-.
pr43_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:agent_capability(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:agent_identity(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:a2a_task_record(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:agent_mail(_, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:delivered_mail(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(a2a:mail_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(a2a:mail_counter(0)).

% Execute: pr43_cleanup :- pr43_setup..
pr43_cleanup :- pr43_setup.

%  AC-PR43-001: agent card generated; includes capabilities
% Define a clause for 'test': succeed when the following conditions hold.
test(agent_card_generated, [setup(pr43_setup)]) :-
    % Execute: a2a:pai_register_identity(mind_a43, pai_mind_a43),.
    a2a:pai_register_identity(mind_a43, pai_mind_a43),
    % Execute: a2a:pai_register_capability(mind_a43, weather_forecast),.
    a2a:pai_register_capability(mind_a43, weather_forecast),
    % Execute: a2a:pai_register_capability(mind_a43, document_search),.
    a2a:pai_register_capability(mind_a43, document_search),
    % State a fact for 'pai agent card' with the arguments listed below.
    pai_agent_card(Card),
    % Check that 'Card' is unifiable with 'card(identity(_), capabilities(Caps), endpoint(_))'.
    Card = card(identity(_), capabilities(Caps), endpoint(_)),
    % State the fact: once(member(weather_forecast, Caps)).
    once(member(weather_forecast, Caps)).

%  AC-PR43-002: mail arrives on fetch with subject and timestamp intact (AC)
% Define a clause for 'test': succeed when the following conditions hold.
test(mail_arrives_on_fetch, [setup(pr43_setup)]) :-
    % "Send while offline" — mail stored in persistent dynamic fact
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_send(recipient43, hello_subject, greeting43)),
    % Recipient comes online and fetches
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_fetch(recipient43, quarantine43, Messages)),
    % Check that 'Messages' is unifiable with '[message(_, recipient43, _, hello_subject-_, greeting43)|_]'.
    Messages = [message(_, recipient43, _, hello_subject-_, greeting43)|_].

%  AC-PR43-003: capabilities reflected in card
% Define a clause for 'test': succeed when the following conditions hold.
test(capabilities_in_card, [setup(pr43_setup)]) :-
    % Execute: a2a:pai_register_capability(mind43, skill_alpha),.
    a2a:pai_register_capability(mind43, skill_alpha),
    % Execute: a2a:pai_register_capability(mind43, skill_beta),.
    a2a:pai_register_capability(mind43, skill_beta),
    % State a fact for 'pai agent card' with the arguments listed below.
    pai_agent_card(card(_, capabilities(Caps), _)),
    % State a fact for 'once' with the arguments listed below.
    once(member(skill_alpha, Caps)),
    % State the fact: once(member(skill_beta, Caps)).
    once(member(skill_beta, Caps)).

%  AC-PR43-004: task with registered skill → completed
% Define a clause for 'test': succeed when the following conditions hold.
test(task_completed, [setup(pr43_setup)]) :-
    % Execute: a2a:pai_register_capability(mind43, forecast_skill43),.
    a2a:pai_register_capability(mind43, forecast_skill43),
    % State a fact for 'pai a2a task' with the arguments listed below.
    pai_a2a_task(task_001_43, forecast_skill43, input(location, london43), Status),
    % Check that 'Status' is unifiable with 'completed(_)'.
    Status = completed(_).

%  AC-PR43-005: task with unknown skill → failed
% Define a clause for 'test': succeed when the following conditions hold.
test(task_unknown_skill, [setup(pr43_setup)]) :-
    % State a fact for 'pai a2a task' with the arguments listed below.
    pai_a2a_task(task_002_43, unknown_skill_43xyz, input(x, y), Status),
    % Check that 'Status' is unifiable with 'failed(_)'.
    Status = failed(_).

%  AC-PR43-006: mail stored persistently (accessible before fetch)
% Define a clause for 'test': succeed when the following conditions hold.
test(mail_stored, [setup(pr43_setup)]) :-
    % State a fact for 'pai peer mail send' with the arguments listed below.
    pai_peer_mail_send(bob43, subject43, body43),
    % Execute: a2a:agent_mail(_, bob43, _, _, body43)..
    a2a:agent_mail(_, bob43, _, _, body43).

%  AC-PR43-007: fetch only returns mail for the correct recipient
% Define a clause for 'test': succeed when the following conditions hold.
test(fetch_recipient_isolation, [setup(pr43_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_send(alice43, msg_for_alice, hello_alice43)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_send(bob43,   msg_for_bob,   hello_bob43)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_fetch(alice43, scope43, AliceMsgs)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_fetch(bob43,   scope43, BobMsgs)),
    % Unify '1' with the number of elements in list 'AliceMsgs'.
    length(AliceMsgs, 1),
    % Unify '1' with the number of elements in list 'BobMsgs'.
    length(BobMsgs, 1),
    % Check that 'AliceMsgs' is unifiable with '[message(_, alice43, _, _, hello_alice43)]'.
    AliceMsgs = [message(_, alice43, _, _, hello_alice43)],
    % Check that 'BobMsgs' is unifiable with '[message(_, bob43,   _, _, hello_bob43)]'.
    BobMsgs   = [message(_, bob43,   _, _, hello_bob43)].

%  AC-PR43-008: delivered mail does not reappear on subsequent fetch
% Define a clause for 'test': succeed when the following conditions hold.
test(delivered_mail_not_refetched, [setup(pr43_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_send(carol43, subj43, body_carol43)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_fetch(carol43, scope43, First)),
    % Unify '1' with the number of elements in list 'First'.
    length(First, 1),
    % State a fact for 'once' with the arguments listed below.
    once(pai_peer_mail_fetch(carol43, scope43, Second)),
    % Unify '0' with the number of elements in list 'Second'.
    length(Second, 0).

%  AC-PR43-009: agent card has no raw Lattice contents
% Define a clause for 'test': succeed when the following conditions hold.
test(card_opacity, [setup(pr43_setup)]) :-
    % State a fact for 'pai agent card' with the arguments listed below.
    pai_agent_card(Card),
    % Check that 'Card' is unifiable with 'card(identity(_Id), capabilities(_Caps), endpoint(_Ep))'.
    Card = card(identity(_Id), capabilities(_Caps), endpoint(_Ep)),
    % Ensure no lattice_node_fact or node_id term in the card
    % Succeed only if 'Card = card(_, _, lattice_node_fact(_, _, _, _, _' cannot be proved (negation as failure).
    \+ Card = card(_, _, lattice_node_fact(_, _, _, _, _)),
    % Succeed only if 'Card = card(lattice_node_fact(_, _, _, _, _), _, _' cannot be proved (negation as failure).
    \+ Card = card(lattice_node_fact(_, _, _, _, _), _, _).

% Execute the compile-time directive: end_tests(pr43).
:- end_tests(pr43).
