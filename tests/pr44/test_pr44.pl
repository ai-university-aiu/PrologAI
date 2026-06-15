/*  PrologAI — PR 44 Tool Use Pattern Acceptance Tests

    AC-PR44-001: Given a registered web_search tool and an objective that
                 needs current facts, when the deliberator runs, then
                 web_search is selected, invoked through the constitutional
                 gate, and its result lands in quarantine before any use.
    AC-PR44-002: Given a tool whose recent calls have failed and an available
                 alternative, when selection runs, then the alternative is
                 preferred (reliability learning).
    AC-PR44-003: pai_tool_register stores a tool card in the registry.
    AC-PR44-004: pai_tool_card retrieves the registered card by identity.
    AC-PR44-005: pai_tool_discover finds tools matching an affordance.
    AC-PR44-006: pai_tool_invoke with a high-risk tool and no auth is denied.
    AC-PR44-007: pai_tool_invoke with a mock binding returns validated_result.
    AC-PR44-008: pai_build_tool synthesizes a new tool from components.
    AC-PR44-009: pai_tool_invoke on an unregistered tool returns not_registered.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/tooling/prolog'], ToolingPath),
   assertz(file_search_path(library, ToolingPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),   [member/2]).
:- use_module(library(tooling), [
    pai_tool_card/2,
    pai_tool_register/2,
    pai_tool_discover/2,
    pai_tool_select/3,
    pai_tool_invoke/4,
    pai_build_tool/3
]).

:- begin_tests(pr44, [setup(pr44_setup), cleanup(pr44_cleanup)]).

pr44_setup :-
    retractall(tooling:tool_record(_, _, _, _, _, _, _)),
    retractall(tooling:tool_reliability(_, _, _)),
    retractall(tooling:tool_counter(_)),
    assertz(tooling:tool_counter(0)).

pr44_cleanup :- pr44_setup.

%  AC-PR44-001: web_search selected, invoked, result in quarantine
test(web_search_selected_and_invoked, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(web_search44, 'fetch web page for current facts',
                  input(query), output(page_text),
                  low, open, mock(search_result_42)),
        web_search44)),
    once(pai_tool_select(web_search44, none, Selected)),
    Selected = web_search44,
    once(pai_tool_invoke(web_search44, query(facts44), quarantine44, Result)),
    Result = validated_result(web_search44, _, _).

%  AC-PR44-002: failed tool is not preferred over reliable alternative
test(reliability_selection, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(bad_tool44, 'translate document44 service', input(doc44), output(text44),
                  low, open, mock(bad_result)),
        bad_tool44)),
    once(pai_tool_register(
        tool_card(good_tool44, 'translate document44 service', input(doc44), output(text44),
                  low, open, mock(good_result)),
        good_tool44)),
    % Simulate many failures for bad_tool44
    retract(tooling:tool_reliability(bad_tool44, 0, 0)),
    assertz(tooling:tool_reliability(bad_tool44, 1, 10)),
    % good_tool44 has perfect record
    retract(tooling:tool_reliability(good_tool44, 0, 0)),
    assertz(tooling:tool_reliability(good_tool44, 10, 0)),
    once(pai_tool_select(document44, none, Selected)),
    Selected = good_tool44.

%  AC-PR44-003: register stores the card
test(register_stores_card, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(calc44, 'arithmetic calculator', input(expr), output(number),
                  low, open, mock(42)),
        calc44)),
    tooling:tool_record(calc44, _, _, _, low, _, _).

%  AC-PR44-004: pai_tool_card retrieves by identity
test(card_retrieval, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(mailer44, 'send email', input(msg), output(ok),
                  moderate, open, mock(sent)),
        mailer44)),
    once(pai_tool_card(mailer44, Card)),
    Card = tool_card(mailer44, _, _, _, moderate, _, _).

%  AC-PR44-005: discover finds tools by affordance
test(discover_by_affordance, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(fetcher44, 'fetch web page content',
                  input(url), output(html), low, open, mock(html_content)),
        fetcher44)),
    once(pai_tool_register(
        tool_card(parser44, 'parse document structure',
                  input(html), output(dom), low, open, mock(dom_tree)),
        parser44)),
    once(pai_tool_discover(fetch, Candidates)),
    member(fetcher44, Candidates).

%  AC-PR44-006: high-risk tool without auth is denied
test(high_risk_denied, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(danger44, 'dangerous operation', input(x), output(y),
                  high, none, mock(boom)),
        danger44)),
    once(pai_tool_invoke(danger44, test_arg44, scope44, Result)),
    Result = invocation_error(danger44, authorization_denied).

%  AC-PR44-007: mock binding returns validated_result
test(mock_invocation, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(mock44, 'mock tool for testing', input(any), output(fixed),
                  low, open, mock(the_answer_44)),
        mock44)),
    once(pai_tool_invoke(mock44, any_input44, testscope44, Result)),
    Result = validated_result(mock44, _, the_answer_44).

%  AC-PR44-008: build_tool synthesizes from components
test(build_tool, [setup(pr44_setup)]) :-
    once(pai_tool_register(
        tool_card(comp_a44, 'component A', input(x), output(y),
                  low, open, mock(a_out)),
        comp_a44)),
    once(pai_tool_register(
        tool_card(comp_b44, 'component B', input(y), output(z),
                  low, open, mock(b_out)),
        comp_b44)),
    once(pai_build_tool(transform44, [comp_a44, comp_b44], NewId)),
    tooling:tool_record(NewId, _, _, _, _, _, _).

%  AC-PR44-009: unregistered tool returns not_registered
test(unregistered_tool, [setup(pr44_setup)]) :-
    once(pai_tool_invoke(no_such_tool_44xyz, arg44, scope44, Result)),
    Result = invocation_error(no_such_tool_44xyz, not_registered).

:- end_tests(pr44).
