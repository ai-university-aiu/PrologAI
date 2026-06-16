/*  PrologAI — Computer Use: Screen-and-Input Body  (PR 45)

    Lets a PrologAI mind operate a graphical computer as a human does —
    perceive the screen and actuate mouse, keyboard, and browser — realized
    through the Mind-Body pattern, so computer use is a body, not a special case.

    The screen is a sensor; input devices are actuators on an enrolled body.
    Screenshots are visual percepts processed by the detector suite, which
    extracts interface elements (buttons, fields, links, text) as node_facts
    with screen-relative locations, using reference frames for coordinate space.

    Computer use is contained by default (sandboxed desktop, allowlisted network).
    Irreversible on-screen actions pass the constitutional gate before dispatch.
    On-screen content from untrusted sources lands in quarantine — never executed
    as instructions (prompt-injection-through-the-screen defense).

    Browser use is the structured sub-mode: navigation, page-text and DOM
    extraction, form filling, and tab management are preferred over raw pixel
    control whenever a page exposes structure.

    Predicates:
        pai_screen_observe/1    — -Elements: perceive screen; return node_facts
        pai_computer_act/2      — +Action, -Confirmation: actuate with gate
        pai_browser_navigate/2  — +URL, -PageElements: navigate and extract
        pai_page_extract/2      — +Source, -Content: quarantine page content
*/

% Declare this file as the 'computer_use' module and list its exported predicates.
:- module(computer_use, [
    % Supply 'pai_screen_observe/1' as the next argument to the expression above.
    pai_screen_observe/1,
    % Supply 'pai_computer_act/2' as the next argument to the expression above.
    pai_computer_act/2,
    % Supply 'pai_browser_navigate/2' as the next argument to the expression above.
    pai_browser_navigate/2,
    % Supply 'pai_page_extract/2' as the next argument to the expression above.
    pai_page_extract/2
% Close the expression opened above.
]).

% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, memberchk/2]).
% Import [maplist/2, maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/2, maplist/3]).

% ---------------------------------------------------------------------------
% Computer body state
% ---------------------------------------------------------------------------

% Declare 'screen_element/4.    % ElementId, Type, Location, Attributes' as dynamic — its facts may be added or removed at runtime.
:- dynamic screen_element/4.    % ElementId, Type, Location, Attributes
% Declare 'screen_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic screen_counter/1.
% Declare 'quarantined_content/3. % ContentId, Source, RawContent' as dynamic — its facts may be added or removed at runtime.
:- dynamic quarantined_content/3. % ContentId, Source, RawContent
% Declare 'quarantine_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic quarantine_counter/1.
% Declare 'sandbox_mode/1.      % sandboxed | open' as dynamic — its facts may be added or removed at runtime.
:- dynamic sandbox_mode/1.      % sandboxed | open
% Declare 'act_log/3.           % ActionId, Action, Confirmation' as dynamic — its facts may be added or removed at runtime.
:- dynamic act_log/3.           % ActionId, Action, Confirmation
% Declare 'action_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic action_counter/1.
% Declare 'tab_registry/2.      % TabId, URL' as dynamic — its facts may be added or removed at runtime.
:- dynamic tab_registry/2.      % TabId, URL
% Declare 'tab_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic tab_counter/1.
% Declare 'allowlist_domain/1.  % whitelisted domains for sandboxed mode' as dynamic — its facts may be added or removed at runtime.
:- dynamic allowlist_domain/1.  % whitelisted domains for sandboxed mode

% State the fact: screen counter(0).
screen_counter(0).
% State the fact: quarantine counter(0).
quarantine_counter(0).
% State the fact: action counter(0).
action_counter(0).
% State the fact: tab counter(0).
tab_counter(0).

% State a fact for 'sandbox mode' with the arguments listed below.
sandbox_mode(sandboxed).        % default: sandboxed desktop

% Define a clause for 'next screen id': succeed when the following conditions hold.
next_screen_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(screen_counter(N)), N1 is N + 1,
    % Check that 'assertz(screen_counter(N1)), Id' is unifiable with 'elem(N1)'.
    assertz(screen_counter(N1)), Id = elem(N1).

% Define a clause for 'next quarantine id': succeed when the following conditions hold.
next_quarantine_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(quarantine_counter(N)), N1 is N + 1,
    % Check that 'assertz(quarantine_counter(N1)), Id' is unifiable with 'qc(N1)'.
    assertz(quarantine_counter(N1)), Id = qc(N1).

% Define a clause for 'next action id': succeed when the following conditions hold.
next_action_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(action_counter(N)), N1 is N + 1,
    % Check that 'assertz(action_counter(N1)), Id' is unifiable with 'act(N1)'.
    assertz(action_counter(N1)), Id = act(N1).

% Define a clause for 'next tab id': succeed when the following conditions hold.
next_tab_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(tab_counter(N)), N1 is N + 1,
    % Check that 'assertz(tab_counter(N1)), Id' is unifiable with 'tab(N1)'.
    assertz(tab_counter(N1)), Id = tab(N1).

% ---------------------------------------------------------------------------
% pai_screen_observe/1 — take a virtual screenshot and extract elements
%
%   Returns a list of screen_element/4 terms extracted from the virtual
%   desktop state.  In a real deployment, this calls the system's screenshot
%   API and runs the detector suite; here the simulator returns the current
%   dynamic screen_element facts.
%
%   Elements: list of element(Id, Type, Location, Attributes)
% ---------------------------------------------------------------------------

% Define a clause for 'pai screen observe': succeed when the following conditions hold.
pai_screen_observe(Elements) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(element(Id, Type, Loc, Attrs),
            % Continue the multi-line expression started above.
            screen_element(Id, Type, Loc, Attrs),
            % Supply 'Elements' as the next argument to the expression above.
            Elements).

% Helper: register a screen element (simulates detector output)
% Define a clause for 'register screen element': succeed when the following conditions hold.
register_screen_element(Type, Location, Attributes, ElementId) :-
    % State a fact for 'next screen id' with the arguments listed below.
    next_screen_id(ElementId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(screen_element(ElementId, Type, Location, Attributes)).

% ---------------------------------------------------------------------------
% pai_computer_act/2 — gate and dispatch an action
%
%   Actions:
%       click(ElementId)            — click a screen element
%       type(ElementId, Text)       — type text into a field
%       navigate(URL)               — browser navigation
%       scroll(Direction, Amount)   — scroll the viewport
%       hotkey(Keys)                — send keyboard shortcut
%
%   Irreversible actions (navigate to unknown domains in sandboxed mode,
%   submit forms) pass the constitutional gate first.
%
%   Returns Confirmation = confirmed(ActionId, Action, Result)
%           or denied(Action, Reason)
% ---------------------------------------------------------------------------

% Define a clause for 'pai computer act': succeed when the following conditions hold.
pai_computer_act(Action, Confirmation) :-
    % Execute: ( irreversible_action(Action).
    ( irreversible_action(Action)
    % If the condition above succeeded, perform the following action.
    ->  ( constitutional_gate(Action)
        % If the condition above succeeded, perform the following action.
        ->  dispatch_action(Action, Result),
            % Continue the multi-line expression started above.
            next_action_id(AId),
            % Continue the multi-line expression started above.
            assertz(act_log(AId, Action, Result)),
            % Continue the multi-line expression started above.
            Confirmation = confirmed(AId, Action, Result)
        % Otherwise (else branch), perform the following action.
        ;   Confirmation = denied(Action, authorization_required)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   dispatch_action(Action, Result),
        % Continue the multi-line expression started above.
        next_action_id(AId),
        % Continue the multi-line expression started above.
        assertz(act_log(AId, Action, Result)),
        % Continue the multi-line expression started above.
        Confirmation = confirmed(AId, Action, Result)
    % Close the expression opened above.
    ).

% Define a clause for 'irreversible action': succeed when the following conditions hold.
irreversible_action(navigate(URL)) :-
    % State a fact for 'sandbox mode' with the arguments listed below.
    sandbox_mode(sandboxed),
    % Succeed only if 'allowlisted_url(URL' cannot be proved (negation as failure).
    \+ allowlisted_url(URL).
% State the fact: irreversible action(submit_form(_)).
irreversible_action(submit_form(_)).

% Define a clause for 'constitutional gate': succeed when the following conditions hold.
constitutional_gate(navigate(URL)) :-
    % Execute: ( allowlisted_url(URL) -> true.
    ( allowlisted_url(URL) -> true
    % Otherwise (else branch), perform the following action.
    ; sandbox_mode(open)
    % Close the expression opened above.
    ).
% Define a clause for 'constitutional gate': succeed when the following conditions hold.
constitutional_gate(submit_form(FormId)) :-
    % State the fact: screen element(FormId, form, _, _).
    screen_element(FormId, form, _, _).
% State the fact: constitutional gate(click(_)).
constitutional_gate(click(_)).
% State the fact: constitutional gate(type(_, _)).
constitutional_gate(type(_, _)).
% State the fact: constitutional gate(scroll(_, _)).
constitutional_gate(scroll(_, _)).
% State the fact: constitutional gate(hotkey(_)).
constitutional_gate(hotkey(_)).

% Define a clause for 'allowlisted url': succeed when the following conditions hold.
allowlisted_url(URL) :-
    % Check that '( atom(URL) -> U' is unifiable with 'URL ; term_to_atom(URL, U) )'.
    ( atom(URL) -> U = URL ; term_to_atom(URL, U) ),
    % State a fact for 'allowlist domain' with the arguments listed below.
    allowlist_domain(Domain),
    % State the fact: sub atom(U, _, _, _, Domain).
    sub_atom(U, _, _, _, Domain).

% Define a clause for 'dispatch action': succeed when the following conditions hold.
dispatch_action(click(ElementId), clicked(ElementId)) :-
    % Execute: ( screen_element(ElementId, _, _, _) -> true ; true )..
    ( screen_element(ElementId, _, _, _) -> true ; true ).
% State the fact: dispatch action(type(ElementId, Text), typed(ElementId, Text)).
dispatch_action(type(ElementId, Text), typed(ElementId, Text)).
% State the fact: dispatch action(navigate(URL), navigated(URL)).
dispatch_action(navigate(URL), navigated(URL)).
% State the fact: dispatch action(scroll(Direction, Amount), scrolled(Direction, Amount)).
dispatch_action(scroll(Direction, Amount), scrolled(Direction, Amount)).
% State the fact: dispatch action(hotkey(Keys), hotkey_sent(Keys)).
dispatch_action(hotkey(Keys), hotkey_sent(Keys)).
% State the fact: dispatch action(submit_form(FormId), submitted(FormId)).
dispatch_action(submit_form(FormId), submitted(FormId)).

% ---------------------------------------------------------------------------
% pai_browser_navigate/2 — structured browser navigation
%
%   Navigates to URL, extracts page structure (simulated), and returns
%   a list of page_element/3 terms (Type, Location, Content).
%   Content from untrusted sources lands in quarantine via pai_page_extract/2.
%   Browser control is preferred over raw pixel control when page has structure.
%
%   PageElements: list of page_element(Type, Location, Content)
% ---------------------------------------------------------------------------

% Define a clause for 'pai browser navigate': succeed when the following conditions hold.
pai_browser_navigate(URL, PageElements) :-
    % State a fact for 'next tab id' with the arguments listed below.
    next_tab_id(TabId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tab_registry(TabId, URL)),
    % Simulate DOM extraction: in reality calls browser driver
    % State a fact for 'simulate page elements' with the arguments listed below.
    simulate_page_elements(URL, RawElements),
    % Quarantine all page content
    % State a fact for 'maplist' with the arguments listed below.
    maplist([page_element(T, L, C), page_element(T, L, QC)]>>(
        % Continue the multi-line expression started above.
        pai_page_extract(C, QC)
    % Continue the multi-line expression started above.
    ), RawElements, PageElements).

% Define a clause for 'simulate page elements': succeed when the following conditions hold.
simulate_page_elements(URL, Elements) :-
    % Execute: ( atom(URL).
    ( atom(URL)
    % If the condition above succeeded, perform the following action.
    ->  atom_string(URL, URLStr),
        % Continue the multi-line expression started above.
        string_concat("page_title_", URLStr, TitleStr),
        % Continue the multi-line expression started above.
        atom_string(Title, TitleStr),
        % Continue the multi-line expression started above.
        Elements = [
            % Continue the multi-line expression started above.
            page_element(title,    location(0,0),    Title),
            % Continue the multi-line expression started above.
            page_element(button,   location(10,50),  submit_btn),
            % Continue the multi-line expression started above.
            page_element(input,    location(10,100), text_field),
            % Continue the multi-line expression started above.
            page_element(link,     location(10,150), link_href),
            % Continue the multi-line expression started above.
            page_element(content,  location(10,200), page_body)
        % Close the expression opened above.
        ]
    % Otherwise (else branch), perform the following action.
    ;   Elements = [page_element(content, location(0,0), unknown_page)]
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_page_extract/2 — quarantine on-screen/page content
%
%   Wraps content as quarantined(ContentId, Source, Content).
%   Content is NEVER executed as a command — it must be explicitly
%   reviewed and promoted before use.
%
%   This is the architectural defense against prompt injection through
%   the screen or browser.
% ---------------------------------------------------------------------------

% Define a clause for 'pai page extract': succeed when the following conditions hold.
pai_page_extract(RawContent, quarantined(ContentId, screen, RawContent)) :-
    % State a fact for 'next quarantine id' with the arguments listed below.
    next_quarantine_id(ContentId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(quarantined_content(ContentId, screen, RawContent)).
