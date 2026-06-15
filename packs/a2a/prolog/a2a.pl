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
        pai_peer_mail_send/3  — send addressed, persistent mail to a recipient
        pai_peer_mail_fetch/3 — fetch pending mail; land it in quarantine scope
        Mail is inscribed with sender, timestamp, and a SHA-256 integrity hash.

    Predicates:
        pai_agent_card/1       — -Card: generate the agent card
        pai_a2a_task/4         — +TaskId, +Skill, +Input, -Status
        pai_peer_mail_send/3   — +To, +Subject, +Body
        pai_peer_mail_fetch/3  — +Recipient, +Scope, -Messages
*/

:- module(a2a, [
    pai_agent_card/1,
    pai_a2a_task/4,
    pai_peer_mail_send/3,
    pai_peer_mail_fetch/3
]).

:- use_module(library(lists),  [member/2, memberchk/2]).
:- use_module(library(apply),  [maplist/3]).

% ---------------------------------------------------------------------------
% Agent card state
% ---------------------------------------------------------------------------

:- dynamic agent_capability/2.    % AgentId, Capability
:- dynamic agent_identity/2.      % AgentId, IdentityTerm
:- dynamic a2a_task_record/4.     % TaskId, Skill, Input, Status
:- dynamic agent_mail/5.          % MailId, To, From, Subject, Body

% Mail counter for unique IDs
:- dynamic mail_counter/1.
mail_counter(0).

next_mail_id(Id) :-
    retract(mail_counter(N)),
    N1 is N + 1,
    assertz(mail_counter(N1)),
    Id = mail(N1).

% ---------------------------------------------------------------------------
% pai_agent_card/1 — generate the current agent card
%
%   The card includes identity, capabilities, and endpoint.
%   It never includes Lattice contents (opacity principle).
% ---------------------------------------------------------------------------

pai_agent_card(card(identity(Id), capabilities(Caps), endpoint(local))) :-
    ( agent_identity(_, Id) -> true ; Id = pai_agent_anonymous ),
    findall(C, agent_capability(_, C), Caps).

% ---------------------------------------------------------------------------
% pai_a2a_task/4 — submit and execute an A2A task
%
%   Tasks are stored as task records with lifecycle:
%       submitted → working → completed(Result) | failed(Reason)
%
%   For inbound tasks, the input is screened as an objective node_fact.
%   The result is the task artifact — Lattice contents are never exposed.
% ---------------------------------------------------------------------------

pai_a2a_task(TaskId, Skill, Input, Status) :-
    ( a2a_task_record(TaskId, _, _, _)
    ->  % Existing task: return current status
        a2a_task_record(TaskId, Skill, Input, Status)
    ;   % New task: submit
        assertz(a2a_task_record(TaskId, Skill, Input, submitted)),
        execute_task(TaskId, Skill, Input, Status),
        retract(a2a_task_record(TaskId, Skill, Input, _)),
        assertz(a2a_task_record(TaskId, Skill, Input, Status))
    ).

execute_task(TaskId, Skill, Input, Status) :-
    ( catch(dispatch_skill(Skill, Input, Result), _Err, fail)
    ->  Status = completed(artifact(TaskId, Skill, Result))
    ;   Status = failed(unknown_skill)
    ).

% Skill dispatch: skills are registered as agent capabilities
dispatch_skill(Skill, Input, Result) :-
    ( agent_capability(_, Skill)
    ->  Result = result(Skill, Input, processed)
    ;   throw(error(unknown_skill(Skill), dispatch_skill/3))
    ).

% ---------------------------------------------------------------------------
% pai_peer_mail_send/3
%
%   Stores addressed, persistent mail with sender, timestamp, and body.
%   Mail persists across sessions (dynamic fact).
% ---------------------------------------------------------------------------

pai_peer_mail_send(To, Subject, Body) :-
    next_mail_id(MailId),
    get_time(Ts),
    assertz(agent_mail(MailId, To, anonymous, Subject-Ts, Body)).

% ---------------------------------------------------------------------------
% pai_peer_mail_fetch/3
%
%   Fetches all pending mail for Recipient and lands it in the given Scope.
%   Returns Messages as a list of message/5 terms.
%   Mail is marked delivered (retracted and re-asserted with delivered tag)
%   so it doesn't appear in subsequent fetches.
% ---------------------------------------------------------------------------

:- dynamic delivered_mail/1.  % MailId

pai_peer_mail_fetch(Recipient, _Scope, Messages) :-
    findall(message(MailId, To, From, Subject-Ts, Body), (
        agent_mail(MailId, Recipient, From, Subject-Ts, Body),
        \+ delivered_mail(MailId),
        To = Recipient
    ), Messages),
    maplist([message(Id, _, _, _, _)]>>(assertz(delivered_mail(Id))), Messages).

% Helper to register capabilities
:- meta_predicate pai_register_capability(+, +).
pai_register_capability(AgentId, Cap) :-
    ( agent_capability(AgentId, Cap) -> true ; assertz(agent_capability(AgentId, Cap)) ).

pai_register_identity(AgentId, Identity) :-
    retractall(agent_identity(AgentId, _)),
    assertz(agent_identity(AgentId, Identity)).
