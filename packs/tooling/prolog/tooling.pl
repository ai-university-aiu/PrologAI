/*  PrologAI — Tool Use Pattern: Registry, Discovery, Selection, Invocation  (PR 44)

    Elevates grounded relations into a first-class tool-use faculty.
    A tool is a grounded node_fact carrying a tool_card.

    tool_card(Identity, Description, InputSchema, OutputSchema, RiskClass,
              Authorization, Binding)
        RiskClass  : low | moderate | high
        Binding    : native(Predicate) | mcp(Server, ToolName) |
                     a2a(Skill) | body(CapName)

    Predicates:
        tooling_tool_card/2     — +Identity, -Card: describe a registered tool
        tooling_tool_register/2 — +Card, -ToolId: enrol a tool in the registry
        tooling_tool_discover/2 — +Affordance, -Candidates: search by affordance
        tooling_tool_select/3   — +Objective, +Budget, -Tool: score and choose
        tooling_tool_invoke/4   — +Tool, +Args, +QuarantineScope, -Result
        tooling_build_tool/3    — +Goal, +Components, -ToolId
*/

% Declare this file as the 'tooling' module and list its exported predicates.
:- module(tooling, [
    % Supply 'tooling_tool_card/2' as the next argument to the expression above.
    tooling_tool_card/2,
    % Supply 'tooling_tool_register/2' as the next argument to the expression above.
    tooling_tool_register/2,
    % Supply 'tooling_tool_discover/2' as the next argument to the expression above.
    tooling_tool_discover/2,
    % Supply 'tooling_tool_select/3' as the next argument to the expression above.
    tooling_tool_select/3,
    % Supply 'tooling_tool_invoke/4' as the next argument to the expression above.
    tooling_tool_invoke/4,
    % Supply 'tooling_build_tool/3' as the next argument to the expression above.
    tooling_build_tool/3
% Close the expression opened above.
]).

% Import [member/2, last/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, last/2]).
% Import [maplist/2, maplist/3, foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/2, maplist/3, foldl/4]).

% ---------------------------------------------------------------------------
% Registry state
% ---------------------------------------------------------------------------

% Declare 'tool_record/7.      % Id, Description, InputSchema, OutputSchema, RiskClass, Auth, Binding' as dynamic — its facts may be added or removed at runtime.
:- dynamic tool_record/7.      % Id, Description, InputSchema, OutputSchema, RiskClass, Auth, Binding
% Declare 'tool_reliability/3. % Id, Successes, Failures' as dynamic — its facts may be added or removed at runtime.
:- dynamic tool_reliability/3. % Id, Successes, Failures
% Declare 'tool_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic tool_counter/1.

% State the fact: tool counter(0).
tool_counter(0).

% Define a clause for 'next tool id': succeed when the following conditions hold.
next_tool_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tool_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tool_counter(N1)),
    % Check that 'Id' is unifiable with 'tool(N1)'.
    Id = tool(N1).

% ---------------------------------------------------------------------------
% tooling_tool_register/2 — enrol a tool card in the registry
%
%   Card = tool_card(Identity, Description, InputSchema, OutputSchema,
%                    RiskClass, Authorization, Binding)
%   Returns ToolId (or existing Id if already registered by identity).
% ---------------------------------------------------------------------------

% Define a clause for 'pai tool register': succeed when the following conditions hold.
tooling_tool_register(tool_card(Id, Desc, In, Out, Risk, Auth, Binding), ToolId) :-
    % Execute: ( tool_record(Id, _, _, _, _, _, _).
    ( tool_record(Id, _, _, _, _, _, _)
    % If the condition above succeeded, perform the following action.
    ->  ToolId = Id
    % Otherwise (else branch), perform the following action.
    ;   next_tool_id(_Seq),
        % Continue the multi-line expression started above.
        assertz(tool_record(Id, Desc, In, Out, Risk, Auth, Binding)),
        % Continue the multi-line expression started above.
        assertz(tool_reliability(Id, 0, 0)),
        % Continue the multi-line expression started above.
        ToolId = Id
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% tooling_tool_card/2 — retrieve a registered tool card
% ---------------------------------------------------------------------------

% Define a clause for 'pai tool card': succeed when the following conditions hold.
tooling_tool_card(Identity, tool_card(Identity, Desc, In, Out, Risk, Auth, Binding)) :-
    % State the fact: tool record(Identity, Desc, In, Out, Risk, Auth, Binding).
    tool_record(Identity, Desc, In, Out, Risk, Auth, Binding).

% ---------------------------------------------------------------------------
% tooling_tool_discover/2 — find tools matching an affordance
%
%   Affordance is an atom or term describing what is needed.
%   Returns a list of tool identities whose description or InputSchema
%   matches (sub-atom or functor unification).
% ---------------------------------------------------------------------------

% Define a clause for 'pai tool discover': succeed when the following conditions hold.
tooling_tool_discover(Affordance, Candidates) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, matching_tool(Affordance, Id), Raw),
    % Sort list 'Raw' into 'Candidates', removing duplicates.
    sort(Raw, Candidates).

% Define a clause for 'matching tool': succeed when the following conditions hold.
matching_tool(Affordance, Id) :-
    % State a fact for 'tool record' with the arguments listed below.
    tool_record(Id, Desc, In, _Out, _Risk, _Auth, _Binding),
    % Execute: ( affordance_match(Affordance, Desc).
    ( affordance_match(Affordance, Desc)
    % Otherwise (else branch), perform the following action.
    ; affordance_match(Affordance, In)
    % Otherwise (else branch), perform the following action.
    ; Affordance = Id
    % Close the expression opened above.
    ).

% Define a clause for 'affordance match': succeed when the following conditions hold.
affordance_match(Affordance, Field) :-
    % Execute: ( atom(Affordance), atom(Field).
    ( atom(Affordance), atom(Field)
    % If the condition above succeeded, perform the following action.
    ->  sub_atom(Field, _, _, _, Affordance)
    % Otherwise (else branch), perform the following action.
    ;   Affordance =.. [F|_], Field =.. [F|_]
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% tooling_tool_select/3 — score candidates and choose the best
%
%   Objective is an atom/term describing what must be accomplished.
%   Budget is max_failures(N) — tools with >= N recent failures are excluded.
%   Returns the best-scoring Tool identity.
%
%   Scoring:
%       base score = 1.0 (all tools start equal)
%       + reliability bonus = successes / (successes + failures + 1)
%       - risk penalty:  high=0.5, moderate=0.2, low=0.0
%       tools exceeding failure budget are excluded
% ---------------------------------------------------------------------------

% Define a clause for 'pai tool select': succeed when the following conditions hold.
tooling_tool_select(Objective, Budget, Tool) :-
    % State a fact for 'pai tool discover' with the arguments listed below.
    tooling_tool_discover(Objective, Candidates),
    % Check that 'Candidates' is not unifiable with '[]'.
    Candidates \= [],
    % State a fact for 'budget filter' with the arguments listed below.
    budget_filter(Budget, Candidates, Allowed),
    % Check that 'Allowed' is not unifiable with '[]'.
    Allowed \= [],
    % State a fact for 'maplist' with the arguments listed below.
    maplist(score_tool, Allowed, Scored),
    % Sort list 'Scored' into 'SortedAsc', keeping duplicates.
    msort(Scored, SortedAsc),
    % Unify the second argument with the last element of list 'SortedAsc'.
    last(SortedAsc, _-Tool).

% Define a clause for 'budget filter': succeed when the following conditions hold.
budget_filter(max_failures(Max), Candidates, Allowed) :-
    % State a fact for 'include' with the arguments listed below.
    include([Id]>>(
        % Continue the multi-line expression started above.
        tool_reliability(Id, _S, F),
        % Continue the multi-line expression started above.
        F < Max
    % Continue the multi-line expression started above.
    ), Candidates, Allowed).
% State the fact: budget filter(none, Candidates, Candidates).
budget_filter(none, Candidates, Candidates).

% Define a clause for 'score tool': succeed when the following conditions hold.
score_tool(Id, Score-Id) :-
    % State a fact for 'tool record' with the arguments listed below.
    tool_record(Id, _Desc, _In, _Out, Risk, _Auth, _Binding),
    % State a fact for 'tool reliability' with the arguments listed below.
    tool_reliability(Id, S, F),
    % Evaluate the arithmetic expression 'S / (S + F + 1)' and bind the result to 'ReliabilityBonus'.
    ReliabilityBonus is S / (S + F + 1),
    % State a fact for 'risk penalty' with the arguments listed below.
    risk_penalty(Risk, Penalty),
    % Evaluate the arithmetic expression '1.0 + ReliabilityBonus - Penalty' and bind the result to 'Score'.
    Score is 1.0 + ReliabilityBonus - Penalty.

% State the fact: risk penalty(low,      0.0).
risk_penalty(low,      0.0).
% State the fact: risk penalty(moderate, 0.2).
risk_penalty(moderate, 0.2).
% State the fact: risk penalty(high,     0.5).
risk_penalty(high,     0.5).
% State the fact: risk penalty(_,        0.0).
risk_penalty(_,        0.0).

% ---------------------------------------------------------------------------
% tooling_tool_invoke/4 — gated invocation with quarantine and reliability update
%
%   Tool is the tool identity.
%   Args is the input term.
%   QuarantineScope is an atom naming the quarantine compartment.
%   Result is validated_result(Tool, Args, RawResult) on success,
%          or invocation_error(Tool, Reason) on failure.
%
%   The constitutional gate (simplified here as risk_class check) must
%   approve the call before dispatch. High-risk tools require explicit
%   authorization == granted in the tool card.
% ---------------------------------------------------------------------------

% Define a clause for 'pai tool invoke': succeed when the following conditions hold.
tooling_tool_invoke(Tool, Args, QuarantineScope, Result) :-
    % Execute: ( tool_record(Tool, _Desc, _In, _Out, Risk, Auth, Binding).
    ( tool_record(Tool, _Desc, _In, _Out, Risk, Auth, Binding)
    % If the condition above succeeded, perform the following action.
    ->  ( constitutional_gate(Tool, Risk, Auth)
        % If the condition above succeeded, perform the following action.
        ->  ( catch(dispatch_binding(Binding, Tool, Args, RawResult), _Err, fail)
            % If the condition above succeeded, perform the following action.
            ->  quarantine_land(QuarantineScope, Tool, RawResult),
                % Continue the multi-line expression started above.
                update_reliability(Tool, success),
                % Continue the multi-line expression started above.
                Result = validated_result(Tool, Args, RawResult)
            % Otherwise (else branch), perform the following action.
            ;   update_reliability(Tool, failure),
                % Continue the multi-line expression started above.
                Result = invocation_error(Tool, dispatch_failed)
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   Result = invocation_error(Tool, authorization_denied)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   Result = invocation_error(Tool, not_registered)
    % Close the expression opened above.
    ).

% Define a clause for 'constitutional gate': succeed when the following conditions hold.
constitutional_gate(_Tool, high, granted) :- !.
% Define a clause for 'constitutional gate': succeed when the following conditions hold.
constitutional_gate(_Tool, high, _)      :- !, fail.
% State the fact: constitutional gate(_Tool, _,    _).
constitutional_gate(_Tool, _,    _).

% Define a clause for 'dispatch binding': succeed when the following conditions hold.
dispatch_binding(native(Pred), _Tool, Args, Result) :-
    % Execute: Goal =.. [Pred, Args, Result],.
    Goal =.. [Pred, Args, Result],
    % State the fact: call(Goal).
    call(Goal).
% Define a clause for 'dispatch binding': succeed when the following conditions hold.
dispatch_binding(mcp(Server, ToolName), _Tool, Args, Result) :-
    % Check that 'Result' is unifiable with 'mcp_result(Server, ToolName, Args)'.
    Result = mcp_result(Server, ToolName, Args).
% Define a clause for 'dispatch binding': succeed when the following conditions hold.
dispatch_binding(a2a(Skill), _Tool, Args, Result) :-
    % Check that 'Result' is unifiable with 'a2a_result(Skill, Args)'.
    Result = a2a_result(Skill, Args).
% Define a clause for 'dispatch binding': succeed when the following conditions hold.
dispatch_binding(body(Cap), _Tool, Args, Result) :-
    % Check that 'Result' is unifiable with 'body_result(Cap, Args)'.
    Result = body_result(Cap, Args).
% State the fact: dispatch binding(mock(ReturnValue), _Tool, _Args, ReturnValue).
dispatch_binding(mock(ReturnValue), _Tool, _Args, ReturnValue).

% Define a clause for 'quarantine land': succeed when the following conditions hold.
quarantine_land(Scope, Tool, Raw) :-
    % Execute: ( atom(Scope).
    ( atom(Scope)
    % If the condition above succeeded, perform the following action.
    ->  atomic_list_concat([quarantine, Scope, Tool], '_', Key),
        % Continue the multi-line expression started above.
        ( catch(nb_getval(Key, Old), _, (nb_setval(Key, []), Old = [])) -> true ; Old = [] ),
        % Continue the multi-line expression started above.
        nb_setval(Key, [Raw|Old])
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'update reliability': succeed when the following conditions hold.
update_reliability(Tool, success) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tool_reliability(Tool, S, F)),
    % Evaluate the arithmetic expression 'S + 1' and bind the result to 'S1'.
    S1 is S + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tool_reliability(Tool, S1, F)).
% Define a clause for 'update reliability': succeed when the following conditions hold.
update_reliability(Tool, failure) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tool_reliability(Tool, S, F)),
    % Evaluate the arithmetic expression 'F + 1' and bind the result to 'F1'.
    F1 is F + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tool_reliability(Tool, S, F1)).

% ---------------------------------------------------------------------------
% tooling_build_tool/3 — synthesize a new tool from a goal and component tools
%
%   Goal is an atom describing what the new tool should accomplish.
%   Components is a list of existing tool identities to compose.
%   ToolId is the new tool's identity.
%
%   The composed binding is registered only if all components are registered
%   (constitutional pipeline check).
% ---------------------------------------------------------------------------

% Define a clause for 'pai build tool': succeed when the following conditions hold.
tooling_build_tool(Goal, Components, ToolId) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist([C]>>(tool_record(C, _, _, _, _, _, _)), Components),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat([synthesized|Components], '_', ToolId),
    % Execute: ( tool_record(ToolId, _, _, _, _, _, _).
    ( tool_record(ToolId, _, _, _, _, _, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   atomic_list_concat(['composed: '|Components], ' + ', CompDesc),
        % Continue the multi-line expression started above.
        Desc = CompDesc,
        % Continue the multi-line expression started above.
        Card = tool_card(ToolId, Desc, input(Goal), output(Goal), low, open, mock(composed_result(ToolId))),
        % Continue the multi-line expression started above.
        tooling_tool_register(Card, _)
    % Close the expression opened above.
    ).
