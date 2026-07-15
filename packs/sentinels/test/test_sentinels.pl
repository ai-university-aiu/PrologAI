/*  PrologAI — Sentinels Bootstrap Store Test Suite  (PR 1 bootstrap)

    Behavioural PLUnit suite for the pure sentinel data-store predicates
    exported by library(sentinels): registration, listing, retraction, and
    per-domain activation.  No engine, lattice, or network is required, so
    these tests run standalone on the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/sentinels/test/test_sentinels.pl
*/

% Declare this file as a test module.
:- module(test_sentinels, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(sentinels)).

% Open the test block for sentinels.
:- begin_tests(sentinels).

% AC-SENT-001: a registered sentinel is returned verbatim by sentinels_list/2.
test(register_then_list, [cleanup(sentinels_retract(sent_dom1))]) :-
    % Begin from a clean slate for this domain.
    sentinels_retract(sent_dom1),
    % Register a single ground sentinel in the domain.
    sentinels_register(sent_dom1, 100, change_seen(apple), [], noop, "apple doc"),
    % Read back every sentinel registered in the domain.
    sentinels_list(sent_dom1, List),
    % The list holds exactly the one sentinel we registered, field for field.
    assertion(List == [sentinel(sent_dom1, 100, change_seen(apple), [], noop, "apple doc")]).

% AC-SENT-002: registering the identical sentinel twice is idempotent.
test(register_is_idempotent, [cleanup(sentinels_retract(sent_dom2))]) :-
    % Begin from a clean slate for this domain.
    sentinels_retract(sent_dom2),
    % Register a sentinel.
    sentinels_register(sent_dom2, 10, change_seen(banana), [], noop, "first"),
    % Register the same domain, priority, pattern, objectives, and action again.
    sentinels_register(sent_dom2, 10, change_seen(banana), [], noop, "second"),
    % Read back the domain's sentinels.
    sentinels_list(sent_dom2, List),
    % The duplicate was ignored, leaving a single entry.
    assertion(List == [sentinel(sent_dom2, 10, change_seen(banana), [], noop, "first")]).

% AC-SENT-003: sentinels_retract/1 empties the domain.
test(retract_removes_all, [cleanup(sentinels_retract(sent_dom3))]) :-
    % Register two distinct sentinels in the domain.
    sentinels_register(sent_dom3, 5, change_seen(carrot), [], noop, "a"),
    % Register a second, higher-priority sentinel.
    sentinels_register(sent_dom3, 7, change_seen(date), [], noop, "b"),
    % Remove every sentinel registered under the domain.
    sentinels_retract(sent_dom3),
    % Read back the now-empty domain.
    sentinels_list(sent_dom3, List),
    % Nothing remains.
    assertion(List == []).

% AC-SENT-004: an unregistered domain lists as empty rather than failing.
test(unknown_domain_is_empty) :-
    % List a domain that was never registered.
    sentinels_list(sent_never_registered, List),
    % The result is the empty list.
    assertion(List == []).

% AC-SENT-005: registering a sentinel activates its domain automatically.
test(register_activates_domain, [cleanup(sentinels_retract(sent_dom4))]) :-
    % Ensure the domain starts inactive.
    sentinels_domain_deactivate(sent_dom4),
    % Confirm the domain is not active before registration.
    assertion(\+ sentinels_domain_active(sent_dom4)),
    % Register a sentinel into the inactive domain.
    sentinels_register(sent_dom4, 1, change_seen(egg), [], noop, "egg doc"),
    % Registration has flipped the domain to active.
    assertion(sentinels_domain_active(sent_dom4)).

% AC-SENT-006: explicit activate then deactivate toggles domain state.
test(domain_activate_then_deactivate) :-
    % Activate a fresh domain.
    sentinels_domain_activate(sent_dom5),
    % The domain reports active.
    assertion(sentinels_domain_active(sent_dom5)),
    % Deactivate the same domain.
    sentinels_domain_deactivate(sent_dom5),
    % The domain no longer reports active.
    assertion(\+ sentinels_domain_active(sent_dom5)).

% Close the test block for sentinels.
:- end_tests(sentinels).
