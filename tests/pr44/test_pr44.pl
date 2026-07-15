/*  PrologAI — PR 44 Tool Use Pattern Acceptance Tests

    AC-PR44-001: Given a registered web_search tool and an objective that
                 needs current facts, when the deliberator runs, then
                 web_search is selected, invoked through the constitutional
                 gate, and its result lands in quarantine before any use.
    AC-PR44-002: Given a tool whose recent calls have failed and an available
                 alternative, when selection runs, then the alternative is
                 preferred (reliability learning).
    AC-PR44-003: tooling_tool_register stores a tool card in the registry.
    AC-PR44-004: tooling_tool_card retrieves the registered card by identity.
    AC-PR44-005: tooling_tool_discover finds tools matching an affordance.
    AC-PR44-006: tooling_tool_invoke with a high-risk tool and no auth is denied.
    AC-PR44-007: tooling_tool_invoke with a mock binding returns validated_result.
    AC-PR44-008: tooling_build_tool synthesizes a new tool from components.
    AC-PR44-009: tooling_tool_invoke on an unregistered tool returns not_registered.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/tooling/prolog'], ToolingPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ToolingPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),   [member/2]).
% Load the built-in 'tooling' library so its predicates are available here.
:- use_module(library(tooling), [
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

% Execute the compile-time directive: begin_tests(pr44, [setup(pr44_setup), cleanup(pr44_cleanup)]).
:- begin_tests(pr44, [setup(pr44_setup), cleanup(pr44_cleanup)]).

% Execute: pr44_setup :-.
pr44_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(tooling:tool_record(_, _, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(tooling:tool_reliability(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(tooling:tool_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tooling:tool_counter(0)).

% Execute: pr44_cleanup :- pr44_setup..
pr44_cleanup :- pr44_setup.

%  AC-PR44-001: web_search selected, invoked, result in quarantine
% Define a clause for 'test': succeed when the following conditions hold.
test(web_search_selected_and_invoked, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(web_search44, 'fetch web page for current facts',
                  % Continue the multi-line expression started above.
                  input(query), output(page_text),
                  % Continue the multi-line expression started above.
                  low, open, mock(search_result_42)),
        % Supply 'web_search44' as the next argument to the expression above.
        web_search44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_select(web_search44, none, Selected)),
    % Check that 'Selected' is unifiable with 'web_search44'.
    Selected = web_search44,
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_invoke(web_search44, query(facts44), quarantine44, Result)),
    % Check that 'Result' is unifiable with 'validated_result(web_search44, _, _)'.
    Result = validated_result(web_search44, _, _).

%  AC-PR44-002: failed tool is not preferred over reliable alternative
% Define a clause for 'test': succeed when the following conditions hold.
test(reliability_selection, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(bad_tool44, 'translate document44 service', input(doc44), output(text44),
                  % Continue the multi-line expression started above.
                  low, open, mock(bad_result)),
        % Supply 'bad_tool44' as the next argument to the expression above.
        bad_tool44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(good_tool44, 'translate document44 service', input(doc44), output(text44),
                  % Continue the multi-line expression started above.
                  low, open, mock(good_result)),
        % Supply 'good_tool44' as the next argument to the expression above.
        good_tool44)),
    % Simulate many failures for bad_tool44
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tooling:tool_reliability(bad_tool44, 0, 0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tooling:tool_reliability(bad_tool44, 1, 10)),
    % good_tool44 has perfect record
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tooling:tool_reliability(good_tool44, 0, 0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tooling:tool_reliability(good_tool44, 10, 0)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_select(document44, none, Selected)),
    % Check that 'Selected' is unifiable with 'good_tool44'.
    Selected = good_tool44.

%  AC-PR44-003: register stores the card
% Define a clause for 'test': succeed when the following conditions hold.
test(register_stores_card, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(calc44, 'arithmetic calculator', input(expr), output(number),
                  % Continue the multi-line expression started above.
                  low, open, mock(42)),
        % Supply 'calc44' as the next argument to the expression above.
        calc44)),
    % Execute: tooling:tool_record(calc44, _, _, _, low, _, _)..
    tooling:tool_record(calc44, _, _, _, low, _, _).

%  AC-PR44-004: tooling_tool_card retrieves by identity
% Define a clause for 'test': succeed when the following conditions hold.
test(card_retrieval, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(mailer44, 'send email', input(msg), output(ok),
                  % Continue the multi-line expression started above.
                  moderate, open, mock(sent)),
        % Supply 'mailer44' as the next argument to the expression above.
        mailer44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_card(mailer44, Card)),
    % Check that 'Card' is unifiable with 'tool_card(mailer44, _, _, _, moderate, _, _)'.
    Card = tool_card(mailer44, _, _, _, moderate, _, _).

%  AC-PR44-005: discover finds tools by affordance
% Define a clause for 'test': succeed when the following conditions hold.
test(discover_by_affordance, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(fetcher44, 'fetch web page content',
                  % Continue the multi-line expression started above.
                  input(url), output(html), low, open, mock(html_content)),
        % Supply 'fetcher44' as the next argument to the expression above.
        fetcher44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(parser44, 'parse document structure',
                  % Continue the multi-line expression started above.
                  input(html), output(dom), low, open, mock(dom_tree)),
        % Supply 'parser44' as the next argument to the expression above.
        parser44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_discover(fetch, Candidates)),
    % Succeed for each element 'fetcher44' that is a member of the list.
    member(fetcher44, Candidates).

%  AC-PR44-006: high-risk tool without auth is denied
% Define a clause for 'test': succeed when the following conditions hold.
test(high_risk_denied, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(danger44, 'dangerous operation', input(x), output(y),
                  % Continue the multi-line expression started above.
                  high, none, mock(boom)),
        % Supply 'danger44' as the next argument to the expression above.
        danger44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_invoke(danger44, test_arg44, scope44, Result)),
    % Check that 'Result' is unifiable with 'invocation_error(danger44, authorization_denied)'.
    Result = invocation_error(danger44, authorization_denied).

%  AC-PR44-007: mock binding returns validated_result
% Define a clause for 'test': succeed when the following conditions hold.
test(mock_invocation, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(mock44, 'mock tool for testing', input(any), output(fixed),
                  % Continue the multi-line expression started above.
                  low, open, mock(the_answer_44)),
        % Supply 'mock44' as the next argument to the expression above.
        mock44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_invoke(mock44, any_input44, testscope44, Result)),
    % Check that 'Result' is unifiable with 'validated_result(mock44, _, the_answer_44)'.
    Result = validated_result(mock44, _, the_answer_44).

%  AC-PR44-008: build_tool synthesizes from components
% Define a clause for 'test': succeed when the following conditions hold.
test(build_tool, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(comp_a44, 'component A', input(x), output(y),
                  % Continue the multi-line expression started above.
                  low, open, mock(a_out)),
        % Supply 'comp_a44' as the next argument to the expression above.
        comp_a44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_register(
        % Continue the multi-line expression started above.
        tool_card(comp_b44, 'component B', input(y), output(z),
                  % Continue the multi-line expression started above.
                  low, open, mock(b_out)),
        % Supply 'comp_b44' as the next argument to the expression above.
        comp_b44)),
    % State a fact for 'once' with the arguments listed below.
    once(tooling_build_tool(transform44, [comp_a44, comp_b44], NewId)),
    % Execute: tooling:tool_record(NewId, _, _, _, _, _, _)..
    tooling:tool_record(NewId, _, _, _, _, _, _).

%  AC-PR44-009: unregistered tool returns not_registered
% Define a clause for 'test': succeed when the following conditions hold.
test(unregistered_tool, [setup(pr44_setup)]) :-
    % State a fact for 'once' with the arguments listed below.
    once(tooling_tool_invoke(no_such_tool_44xyz, arg44, scope44, Result)),
    % Check that 'Result' is unifiable with 'invocation_error(no_such_tool_44xyz, not_registered)'.
    Result = invocation_error(no_such_tool_44xyz, not_registered).

% Execute the compile-time directive: end_tests(pr44).
:- end_tests(pr44).
