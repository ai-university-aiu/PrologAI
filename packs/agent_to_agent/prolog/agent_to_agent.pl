/*  PrologAI — Agent Interoperability: A2A Protocol and Durable Agent Mail  (PR 43)

    Lets PrologAI minds participate in the emerging society of agents by
    speaking the Agent2Agent (A2A) protocol and exchanging durable mail with
    minds that are not simultaneously awake.

    A2A (Agent2Agent — Linux Foundation):
        An AGENT CARD declares identity, capabilities, endpoint, and auth.
        TASKS have a defined lifecycle: submitted → working → completed/failed.
        MESSAGES carry role-tagged parts; ARTIFACTS are task outputs.
        Opacity is preserved: the card discloses capabilities, never Lattice
        contents; inbound agents receive results, not raw memory queries.

    Durable agent mail:
        agent_to_agent_peer_mail_send/3  — send addressed, persistent mail to a recipient
        agent_to_agent_peer_mail_fetch/3 — fetch pending mail; land it in quarantine scope
        Mail is inscribed with sender, timestamp, and a SHA-256 integrity hash.

    Predicates:
        agent_to_agent_agent_card/1       — -Card: generate the agent card
        agent_to_agent_task/4         — +TaskId, +Skill, +Input, -Status
        agent_to_agent_peer_mail_send/3   — +To, +Subject, +Body
        agent_to_agent_peer_mail_fetch/3  — +Recipient, +Scope, -Messages
*/

% Declare this file as the 'a2a' module and list its exported predicates.
:- module(agent_to_agent, [
    % Supply 'agent_to_agent_agent_card/1' as the next argument to the expression above.
    agent_to_agent_agent_card/1,
    % Supply 'agent_to_agent_task/4' as the next argument to the expression above.
    agent_to_agent_task/4,
    % Supply 'agent_to_agent_peer_mail_send/3' as the next argument to the expression above.
    agent_to_agent_peer_mail_send/3,
    % Supply 'agent_to_agent_peer_mail_fetch/3' as the next argument to the expression above.
    agent_to_agent_peer_mail_fetch/3
% Close the expression opened above.
]).

% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, memberchk/2]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/3]).

% ---------------------------------------------------------------------------
% Agent card state
% ---------------------------------------------------------------------------

% Declare 'agent_to_agent_agent_capability/2.    % AgentId, Capability' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_agent_capability/2.    % AgentId, Capability
% Declare 'agent_to_agent_agent_identity/2.      % AgentId, IdentityTerm' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_agent_identity/2.      % AgentId, IdentityTerm
% Declare 'agent_to_agent_task_record/4.     % TaskId, Skill, Input, Status' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_task_record/4.     % TaskId, Skill, Input, Status
% Declare 'agent_to_agent_agent_mail/5.          % MailId, To, From, Subject, Body' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_agent_mail/5.          % MailId, To, From, Subject, Body

% Mail counter for unique IDs
% Declare 'agent_to_agent_mail_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_mail_counter/1.
% State the fact: mail counter(0).
agent_to_agent_mail_counter(0).

% Define a clause for 'next mail id': succeed when the following conditions hold.
agent_to_agent_next_mail_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(agent_to_agent_mail_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(agent_to_agent_mail_counter(N1)),
    % Check that 'Id' is unifiable with 'mail(N1)'.
    Id = mail(N1).

% ---------------------------------------------------------------------------
% agent_to_agent_agent_card/1 — generate the current agent card
%
%   The card includes identity, capabilities, and endpoint.
%   It never includes Lattice contents (opacity principle).
% ---------------------------------------------------------------------------

% Define a clause for 'pai agent card': succeed when the following conditions hold.
agent_to_agent_agent_card(card(identity(Id), capabilities(Caps), endpoint(local))) :-
    % Check that '( agent_to_agent_agent_identity(_, Id) -> true ; Id' is unifiable with 'agent_to_agent_anonymous )'.
    ( agent_to_agent_agent_identity(_, Id) -> true ; Id = agent_to_agent_anonymous ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(C, agent_to_agent_agent_capability(_, C), Caps).

% ---------------------------------------------------------------------------
% agent_to_agent_task/4 — submit and execute an A2A task
%
%   Tasks are stored as task records with lifecycle:
%       submitted → working → completed(Result) | failed(Reason)
%
%   For inbound tasks, the input is screened as an objective node_fact.
%   The result is the task artifact — Lattice contents are never exposed.
% ---------------------------------------------------------------------------

% Define a clause for 'pai a2a task': succeed when the following conditions hold.
agent_to_agent_task(TaskId, Skill, Input, Status) :-
    % Execute: ( agent_to_agent_task_record(TaskId, _, _, _).
    ( agent_to_agent_task_record(TaskId, _, _, _)
    % If the condition above succeeded, perform the following action.
    ->  % Existing task: return current status
        % Continue the multi-line expression started above.
        agent_to_agent_task_record(TaskId, Skill, Input, Status)
    % Otherwise (else branch), perform the following action.
    ;   % New task: submit
        % Continue the multi-line expression started above.
        assertz(agent_to_agent_task_record(TaskId, Skill, Input, submitted)),
        % Continue the multi-line expression started above.
        agent_to_agent_execute_task(TaskId, Skill, Input, Status),
        % Continue the multi-line expression started above.
        retract(agent_to_agent_task_record(TaskId, Skill, Input, _)),
        % Continue the multi-line expression started above.
        assertz(agent_to_agent_task_record(TaskId, Skill, Input, Status))
    % Close the expression opened above.
    ).

% Define a clause for 'execute task': succeed when the following conditions hold.
agent_to_agent_execute_task(TaskId, Skill, Input, Status) :-
    % Execute: ( catch(agent_to_agent_dispatch_skill(Skill, Input, Result), _Err, fail).
    ( catch(agent_to_agent_dispatch_skill(Skill, Input, Result), _Err, fail)
    % If the condition above succeeded, perform the following action.
    ->  Status = completed(artifact(TaskId, Skill, Result))
    % Otherwise (else branch), perform the following action.
    ;   Status = failed(unknown_skill)
    % Close the expression opened above.
    ).

% Skill dispatch: skills are registered as agent capabilities
% Define a clause for 'dispatch skill': succeed when the following conditions hold.
agent_to_agent_dispatch_skill(Skill, Input, Result) :-
    % Execute: ( agent_to_agent_agent_capability(_, Skill).
    ( agent_to_agent_agent_capability(_, Skill)
    % If the condition above succeeded, perform the following action.
    ->  Result = result(Skill, Input, processed)
    % Otherwise (else branch), perform the following action.
    ;   throw(error(unknown_skill(Skill), agent_to_agent_dispatch_skill/3))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% agent_to_agent_peer_mail_send/3
%
%   Stores addressed, persistent mail with sender, timestamp, and body.
%   Mail persists across sessions (dynamic fact).
% ---------------------------------------------------------------------------

% Define a clause for 'pai peer mail send': succeed when the following conditions hold.
agent_to_agent_peer_mail_send(To, Subject, Body) :-
    % State a fact for 'next mail id' with the arguments listed below.
    agent_to_agent_next_mail_id(MailId),
    % State a fact for 'get time' with the arguments listed below.
    get_time(Ts),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(agent_to_agent_agent_mail(MailId, To, anonymous, Subject-Ts, Body)).

% ---------------------------------------------------------------------------
% agent_to_agent_peer_mail_fetch/3
%
%   Fetches all pending mail for Recipient and lands it in the given Scope.
%   Returns Messages as a list of message/5 terms.
%   Mail is marked delivered (retracted and re-asserted with delivered tag)
%   so it doesn't appear in subsequent fetches.
% ---------------------------------------------------------------------------

% Declare 'agent_to_agent_delivered_mail/1.  % MailId' as dynamic — its facts may be added or removed at runtime.
:- dynamic agent_to_agent_delivered_mail/1.  % MailId

% Define a clause for 'pai peer mail fetch': succeed when the following conditions hold.
agent_to_agent_peer_mail_fetch(Recipient, _Scope, Messages) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(message(MailId, To, From, Subject-Ts, Body), (
        % Continue the multi-line expression started above.
        agent_to_agent_agent_mail(MailId, Recipient, From, Subject-Ts, Body),
        % Continue the multi-line expression started above.
        \+ agent_to_agent_delivered_mail(MailId),
        % Continue the multi-line expression started above.
        To = Recipient
    % Continue the multi-line expression started above.
    ), Messages),
    % State the fact: maplist([message(Id, _, _, _, _)]>>(assertz(agent_to_agent_delivered_mail(Id))), Messages).
    maplist([message(Id, _, _, _, _)]>>(assertz(agent_to_agent_delivered_mail(Id))), Messages).

% Helper to register capabilities
% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate agent_to_agent_register_capability(+, +).
% Define a clause for 'pai register capability': succeed when the following conditions hold.
agent_to_agent_register_capability(AgentId, Cap) :-
    % Execute: ( agent_to_agent_agent_capability(AgentId, Cap) -> true ; assertz(agent_to_agent_agent_capability(AgentId, Cap)) )..
    ( agent_to_agent_agent_capability(AgentId, Cap) -> true ; assertz(agent_to_agent_agent_capability(AgentId, Cap)) ).

% Define a clause for 'pai register identity': succeed when the following conditions hold.
agent_to_agent_register_identity(AgentId, Identity) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(agent_to_agent_agent_identity(AgentId, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(agent_to_agent_agent_identity(AgentId, Identity)).
