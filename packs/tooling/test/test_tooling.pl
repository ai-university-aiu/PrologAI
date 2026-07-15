/*  PrologAI — Tool Use Pattern Test Suite  (tooling pack, WP-44)

    In-pack PLUnit regression for the tooling faculty: registry,
    discovery, reliability-weighted selection, gated invocation, and
    tool synthesis. Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/tooling/test/test_tooling.pl
*/

% Declare this file as a test module with no exports.
:- module(test_tooling, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(tooling)).
% Import member/2 for membership assertions.
:- use_module(library(lists), [member/2]).

% Clear the registry so each test starts from an empty, deterministic state.
reset_tooling :-
    % Remove every registered tool record.
    retractall(tooling:tool_record(_, _, _, _, _, _, _)),
    % Remove every reliability tally.
    retractall(tooling:tool_reliability(_, _, _)),
    % Remove the id counter.
    retractall(tooling:tool_counter(_)),
    % Reset the id counter to zero.
    assertz(tooling:tool_counter(0)).

% Open the test block for tooling.
:- begin_tests(tooling).

% Registering a card enrols the tool and its card is retrievable by identity.
test(register_and_card_roundtrip, [setup(reset_tooling)]) :-
    % Enrol a low-risk calculator tool.
    tooling_tool_register(tool_card(calc, 'arithmetic calculator', input(expr), output(number), low, open, mock(42)), ToolId),
    % The returned identity is the card identity.
    assertion(ToolId == calc),
    % The card can be fetched back by identity.
    tooling_tool_card(calc, Card),
    % The retrieved card preserves the identity and risk class.
    assertion(Card = tool_card(calc, _, _, _, low, _, _)).

% Discovery finds a tool whose description affords the query and excludes others.
test(discover_by_affordance, [setup(reset_tooling)]) :-
    % Register a web fetcher.
    tooling_tool_register(tool_card(fetcher, 'fetch web page content', input(url), output(html), low, open, mock(html)), _),
    % Register an unrelated parser.
    tooling_tool_register(tool_card(parser, 'parse document structure', input(html), output(dom), low, open, mock(dom)), _),
    % Search for tools affording 'fetch'.
    tooling_tool_discover(fetch, Candidates),
    % The fetcher is a candidate.
    assertion(member(fetcher, Candidates)),
    % The unrelated parser is not a candidate.
    assertion(\+ member(parser, Candidates)).

% Selection prefers the more reliable of two tools with the same affordance.
test(reliability_selection, [setup(reset_tooling)]) :-
    % Register a translator that will carry a poor record.
    tooling_tool_register(tool_card(bad_tool, 'translate document service', input(doc), output(text), low, open, mock(bad)), _),
    % Register a translator with the same affordance that will carry a perfect record.
    tooling_tool_register(tool_card(good_tool, 'translate document service', input(doc), output(text), low, open, mock(good)), _),
    % Drop the bad tool's fresh tally.
    retract(tooling:tool_reliability(bad_tool, _, _)),
    % Give the bad tool one success and ten failures.
    assertz(tooling:tool_reliability(bad_tool, 1, 10)),
    % Drop the good tool's fresh tally.
    retract(tooling:tool_reliability(good_tool, _, _)),
    % Give the good tool ten successes and no failures.
    assertz(tooling:tool_reliability(good_tool, 10, 0)),
    % Select the best tool for the 'document' objective (once: take the single best).
    once(tooling_tool_select(document, none, Selected)),
    % The reliable tool wins.
    assertion(Selected == good_tool).

% A mock-bound low-risk invocation clears the gate and returns a validated result.
test(mock_invocation, [setup(reset_tooling)]) :-
    % Register a low-risk mock tool that returns a fixed value.
    tooling_tool_register(tool_card(mock_tool, 'mock tool for testing', input(any), output(fixed), low, open, mock(the_answer)), _),
    % Invoke it inside a quarantine scope (once: dispatch is deterministic here).
    once(tooling_tool_invoke(mock_tool, any_input, testscope, Result)),
    % The result names the tool and carries the mock return value.
    assertion(Result = validated_result(mock_tool, _, the_answer)).

% A high-risk tool without granted authorization is denied by the constitutional gate.
test(high_risk_denied, [setup(reset_tooling)]) :-
    % Register a high-risk, unauthorized tool.
    tooling_tool_register(tool_card(danger, 'dangerous operation', input(x), output(y), high, none, mock(boom)), _),
    % Attempt to invoke it.
    tooling_tool_invoke(danger, arg, scope, Result),
    % Invocation is refused with authorization_denied.
    assertion(Result == invocation_error(danger, authorization_denied)).

% Invoking a tool that was never registered reports not_registered.
test(unregistered_tool, [setup(reset_tooling)]) :-
    % Invoke a tool identity absent from the registry.
    tooling_tool_invoke(no_such_tool, arg, scope, Result),
    % The error names the missing tool.
    assertion(Result == invocation_error(no_such_tool, not_registered)).

% Building a tool from registered components synthesizes and registers a new tool.
test(build_tool_from_components, [setup(reset_tooling)]) :-
    % Register component A.
    tooling_tool_register(tool_card(comp_a, 'component A', input(x), output(y), low, open, mock(a_out)), _),
    % Register component B.
    tooling_tool_register(tool_card(comp_b, 'component B', input(y), output(z), low, open, mock(b_out)), _),
    % Compose them into a new tool for the 'transform' goal.
    tooling_build_tool(transform, [comp_a, comp_b], NewId),
    % The synthesized tool is now present in the registry.
    assertion(tooling:tool_record(NewId, _, _, _, _, _, _)).

% Close the test block for tooling.
:- end_tests(tooling).
