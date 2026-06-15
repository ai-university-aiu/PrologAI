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

:- module(computer_use, [
    pai_screen_observe/1,
    pai_computer_act/2,
    pai_browser_navigate/2,
    pai_page_extract/2
]).

:- use_module(library(lists),  [member/2, memberchk/2]).
:- use_module(library(apply),  [maplist/2, maplist/3]).

% ---------------------------------------------------------------------------
% Computer body state
% ---------------------------------------------------------------------------

:- dynamic screen_element/4.    % ElementId, Type, Location, Attributes
:- dynamic screen_counter/1.
:- dynamic quarantined_content/3. % ContentId, Source, RawContent
:- dynamic quarantine_counter/1.
:- dynamic sandbox_mode/1.      % sandboxed | open
:- dynamic act_log/3.           % ActionId, Action, Confirmation
:- dynamic action_counter/1.
:- dynamic tab_registry/2.      % TabId, URL
:- dynamic tab_counter/1.
:- dynamic allowlist_domain/1.  % whitelisted domains for sandboxed mode

screen_counter(0).
quarantine_counter(0).
action_counter(0).
tab_counter(0).

sandbox_mode(sandboxed).        % default: sandboxed desktop

next_screen_id(Id) :-
    retract(screen_counter(N)), N1 is N + 1,
    assertz(screen_counter(N1)), Id = elem(N1).

next_quarantine_id(Id) :-
    retract(quarantine_counter(N)), N1 is N + 1,
    assertz(quarantine_counter(N1)), Id = qc(N1).

next_action_id(Id) :-
    retract(action_counter(N)), N1 is N + 1,
    assertz(action_counter(N1)), Id = act(N1).

next_tab_id(Id) :-
    retract(tab_counter(N)), N1 is N + 1,
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

pai_screen_observe(Elements) :-
    findall(element(Id, Type, Loc, Attrs),
            screen_element(Id, Type, Loc, Attrs),
            Elements).

% Helper: register a screen element (simulates detector output)
register_screen_element(Type, Location, Attributes, ElementId) :-
    next_screen_id(ElementId),
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

pai_computer_act(Action, Confirmation) :-
    ( irreversible_action(Action)
    ->  ( constitutional_gate(Action)
        ->  dispatch_action(Action, Result),
            next_action_id(AId),
            assertz(act_log(AId, Action, Result)),
            Confirmation = confirmed(AId, Action, Result)
        ;   Confirmation = denied(Action, authorization_required)
        )
    ;   dispatch_action(Action, Result),
        next_action_id(AId),
        assertz(act_log(AId, Action, Result)),
        Confirmation = confirmed(AId, Action, Result)
    ).

irreversible_action(navigate(URL)) :-
    sandbox_mode(sandboxed),
    \+ allowlisted_url(URL).
irreversible_action(submit_form(_)).

constitutional_gate(navigate(URL)) :-
    ( allowlisted_url(URL) -> true
    ; sandbox_mode(open)
    ).
constitutional_gate(submit_form(FormId)) :-
    screen_element(FormId, form, _, _).
constitutional_gate(click(_)).
constitutional_gate(type(_, _)).
constitutional_gate(scroll(_, _)).
constitutional_gate(hotkey(_)).

allowlisted_url(URL) :-
    ( atom(URL) -> U = URL ; term_to_atom(URL, U) ),
    allowlist_domain(Domain),
    sub_atom(U, _, _, _, Domain).

dispatch_action(click(ElementId), clicked(ElementId)) :-
    ( screen_element(ElementId, _, _, _) -> true ; true ).
dispatch_action(type(ElementId, Text), typed(ElementId, Text)).
dispatch_action(navigate(URL), navigated(URL)).
dispatch_action(scroll(Direction, Amount), scrolled(Direction, Amount)).
dispatch_action(hotkey(Keys), hotkey_sent(Keys)).
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

pai_browser_navigate(URL, PageElements) :-
    next_tab_id(TabId),
    assertz(tab_registry(TabId, URL)),
    % Simulate DOM extraction: in reality calls browser driver
    simulate_page_elements(URL, RawElements),
    % Quarantine all page content
    maplist([page_element(T, L, C), page_element(T, L, QC)]>>(
        pai_page_extract(C, QC)
    ), RawElements, PageElements).

simulate_page_elements(URL, Elements) :-
    ( atom(URL)
    ->  atom_string(URL, URLStr),
        string_concat("page_title_", URLStr, TitleStr),
        atom_string(Title, TitleStr),
        Elements = [
            page_element(title,    location(0,0),    Title),
            page_element(button,   location(10,50),  submit_btn),
            page_element(input,    location(10,100), text_field),
            page_element(link,     location(10,150), link_href),
            page_element(content,  location(10,200), page_body)
        ]
    ;   Elements = [page_element(content, location(0,0), unknown_page)]
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

pai_page_extract(RawContent, quarantined(ContentId, screen, RawContent)) :-
    next_quarantine_id(ContentId),
    assertz(quarantined_content(ContentId, screen, RawContent)).
