/*  PrologAI — Tool Use Pattern: Registry, Discovery, Selection, Invocation  (PR 44)

    Elevates grounded relations into a first-class tool-use faculty.
    A tool is a grounded node_fact carrying a tool_card.

    tool_card(Identity, Description, InputSchema, OutputSchema, RiskClass,
              Authorization, Binding)
        RiskClass  : low | moderate | high
        Binding    : native(Predicate) | mcp(Server, ToolName) |
                     a2a(Skill) | body(CapName)

    Predicates:
        pai_tool_card/2     — +Identity, -Card: describe a registered tool
        pai_tool_register/2 — +Card, -ToolId: enrol a tool in the registry
        pai_tool_discover/2 — +Affordance, -Candidates: search by affordance
        pai_tool_select/3   — +Objective, +Budget, -Tool: score and choose
        pai_tool_invoke/4   — +Tool, +Args, +QuarantineScope, -Result
        pai_build_tool/3    — +Goal, +Components, -ToolId
*/

:- module(tooling, [
    pai_tool_card/2,
    pai_tool_register/2,
    pai_tool_discover/2,
    pai_tool_select/3,
    pai_tool_invoke/4,
    pai_build_tool/3
]).

:- use_module(library(lists),  [member/2, last/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, foldl/4]).

% ---------------------------------------------------------------------------
% Registry state
% ---------------------------------------------------------------------------

:- dynamic tool_record/7.      % Id, Description, InputSchema, OutputSchema, RiskClass, Auth, Binding
:- dynamic tool_reliability/3. % Id, Successes, Failures
:- dynamic tool_counter/1.

tool_counter(0).

next_tool_id(Id) :-
    retract(tool_counter(N)),
    N1 is N + 1,
    assertz(tool_counter(N1)),
    Id = tool(N1).

% ---------------------------------------------------------------------------
% pai_tool_register/2 — enrol a tool card in the registry
%
%   Card = tool_card(Identity, Description, InputSchema, OutputSchema,
%                    RiskClass, Authorization, Binding)
%   Returns ToolId (or existing Id if already registered by identity).
% ---------------------------------------------------------------------------

pai_tool_register(tool_card(Id, Desc, In, Out, Risk, Auth, Binding), ToolId) :-
    ( tool_record(Id, _, _, _, _, _, _)
    ->  ToolId = Id
    ;   next_tool_id(_Seq),
        assertz(tool_record(Id, Desc, In, Out, Risk, Auth, Binding)),
        assertz(tool_reliability(Id, 0, 0)),
        ToolId = Id
    ).

% ---------------------------------------------------------------------------
% pai_tool_card/2 — retrieve a registered tool card
% ---------------------------------------------------------------------------

pai_tool_card(Identity, tool_card(Identity, Desc, In, Out, Risk, Auth, Binding)) :-
    tool_record(Identity, Desc, In, Out, Risk, Auth, Binding).

% ---------------------------------------------------------------------------
% pai_tool_discover/2 — find tools matching an affordance
%
%   Affordance is an atom or term describing what is needed.
%   Returns a list of tool identities whose description or InputSchema
%   matches (sub-atom or functor unification).
% ---------------------------------------------------------------------------

pai_tool_discover(Affordance, Candidates) :-
    findall(Id, matching_tool(Affordance, Id), Raw),
    sort(Raw, Candidates).

matching_tool(Affordance, Id) :-
    tool_record(Id, Desc, In, _Out, _Risk, _Auth, _Binding),
    ( affordance_match(Affordance, Desc)
    ; affordance_match(Affordance, In)
    ; Affordance = Id
    ).

affordance_match(Affordance, Field) :-
    ( atom(Affordance), atom(Field)
    ->  sub_atom(Field, _, _, _, Affordance)
    ;   Affordance =.. [F|_], Field =.. [F|_]
    ).

% ---------------------------------------------------------------------------
% pai_tool_select/3 — score candidates and choose the best
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

pai_tool_select(Objective, Budget, Tool) :-
    pai_tool_discover(Objective, Candidates),
    Candidates \= [],
    budget_filter(Budget, Candidates, Allowed),
    Allowed \= [],
    maplist(score_tool, Allowed, Scored),
    msort(Scored, SortedAsc),
    last(SortedAsc, _-Tool).

budget_filter(max_failures(Max), Candidates, Allowed) :-
    include([Id]>>(
        tool_reliability(Id, _S, F),
        F < Max
    ), Candidates, Allowed).
budget_filter(none, Candidates, Candidates).

score_tool(Id, Score-Id) :-
    tool_record(Id, _Desc, _In, _Out, Risk, _Auth, _Binding),
    tool_reliability(Id, S, F),
    ReliabilityBonus is S / (S + F + 1),
    risk_penalty(Risk, Penalty),
    Score is 1.0 + ReliabilityBonus - Penalty.

risk_penalty(low,      0.0).
risk_penalty(moderate, 0.2).
risk_penalty(high,     0.5).
risk_penalty(_,        0.0).

% ---------------------------------------------------------------------------
% pai_tool_invoke/4 — gated invocation with quarantine and reliability update
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

pai_tool_invoke(Tool, Args, QuarantineScope, Result) :-
    ( tool_record(Tool, _Desc, _In, _Out, Risk, Auth, Binding)
    ->  ( constitutional_gate(Tool, Risk, Auth)
        ->  ( catch(dispatch_binding(Binding, Tool, Args, RawResult), _Err, fail)
            ->  quarantine_land(QuarantineScope, Tool, RawResult),
                update_reliability(Tool, success),
                Result = validated_result(Tool, Args, RawResult)
            ;   update_reliability(Tool, failure),
                Result = invocation_error(Tool, dispatch_failed)
            )
        ;   Result = invocation_error(Tool, authorization_denied)
        )
    ;   Result = invocation_error(Tool, not_registered)
    ).

constitutional_gate(_Tool, high, granted) :- !.
constitutional_gate(_Tool, high, _)      :- !, fail.
constitutional_gate(_Tool, _,    _).

dispatch_binding(native(Pred), _Tool, Args, Result) :-
    Goal =.. [Pred, Args, Result],
    call(Goal).
dispatch_binding(mcp(Server, ToolName), _Tool, Args, Result) :-
    Result = mcp_result(Server, ToolName, Args).
dispatch_binding(a2a(Skill), _Tool, Args, Result) :-
    Result = a2a_result(Skill, Args).
dispatch_binding(body(Cap), _Tool, Args, Result) :-
    Result = body_result(Cap, Args).
dispatch_binding(mock(ReturnValue), _Tool, _Args, ReturnValue).

quarantine_land(Scope, Tool, Raw) :-
    ( atom(Scope)
    ->  atomic_list_concat([quarantine, Scope, Tool], '_', Key),
        ( catch(nb_getval(Key, Old), _, (nb_setval(Key, []), Old = [])) -> true ; Old = [] ),
        nb_setval(Key, [Raw|Old])
    ;   true
    ).

update_reliability(Tool, success) :-
    retract(tool_reliability(Tool, S, F)),
    S1 is S + 1,
    assertz(tool_reliability(Tool, S1, F)).
update_reliability(Tool, failure) :-
    retract(tool_reliability(Tool, S, F)),
    F1 is F + 1,
    assertz(tool_reliability(Tool, S, F1)).

% ---------------------------------------------------------------------------
% pai_build_tool/3 — synthesize a new tool from a goal and component tools
%
%   Goal is an atom describing what the new tool should accomplish.
%   Components is a list of existing tool identities to compose.
%   ToolId is the new tool's identity.
%
%   The composed binding is registered only if all components are registered
%   (constitutional pipeline check).
% ---------------------------------------------------------------------------

pai_build_tool(Goal, Components, ToolId) :-
    maplist([C]>>(tool_record(C, _, _, _, _, _, _)), Components),
    atomic_list_concat([synthesized|Components], '_', ToolId),
    ( tool_record(ToolId, _, _, _, _, _, _)
    ->  true
    ;   atomic_list_concat(['composed: '|Components], ' + ', CompDesc),
        Desc = CompDesc,
        Card = tool_card(ToolId, Desc, input(Goal), output(Goal), low, open, mock(composed_result(ToolId))),
        pai_tool_register(Card, _)
    ).
