/*  PrologAI — Causalontology Lore Test Suite  (WP-424)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_lore/test/test_co_lore.pl
*/

% Declare this file as a test module.
:- module(test_co_lore, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_lore)).
% Load list helpers for the assertions.
:- use_module(library(lists)).

% Open the test block.
:- begin_tests(co_lore).

% A shared fixture: a recurring danger situation and a one-off treasure situation.
setup_lore :-
    co_lore:lo_reset,
    co_lore:lo_record([low_health, enemy_near], flee, good),
    co_lore:lo_record([low_health, enemy_near], fight, bad),
    co_lore:lo_record([low_health, enemy_near], flee, good),
    co_lore:lo_record([treasure_seen], grab, good).

% A situation seen at least twice is a theme; a one-off is not.
test(theme_detection) :-
    setup_lore,
    findall(S-C, co_lore:lo_theme(S, C), Themes),
    assertion(memberchk([enemy_near, low_health]-3, Themes)),
    assertion(\+ memberchk([treasure_seen]-_, Themes)).

% Lessons recall the responses tried in matching past situations.
test(lessons_recalled) :-
    setup_lore,
    findall(R-Res, co_lore:lo_lesson([low_health, enemy_near], R, Res), Lessons),
    assertion(memberchk(flee-good, Lessons)),
    assertion(memberchk(fight-bad, Lessons)).

% A past pattern matches a richer present situation (its features are all present).
test(subset_match) :-
    setup_lore,
    % The danger pattern applies even with an extra "tired" feature present now.
    co_lore:lo_advise([low_health, enemy_near, tired], R, _),
    assertion(R == flee).

% Advice picks the response that most often turned out good.
test(advise_best) :-
    setup_lore,
    co_lore:lo_advise([low_health, enemy_near], R, Conf),
    assertion(R == flee),
    assertion(Conf =:= 1.0).

% Responses are ranked, best success fraction first.
test(responses_ranked) :-
    setup_lore,
    co_lore:lo_responses([low_health, enemy_near], Ranked),
    Ranked = [resp(First, _, _) | _],
    assertion(First == flee),
    last(Ranked, resp(Last, _, _)),
    assertion(Last == fight).

% A maxim for a theme with a good response advises doing it.
test(maxim_do) :-
    setup_lore,
    co_lore:lo_maxim([low_health, enemy_near], Maxim),
    assertion(Maxim == do(flee)).

% A maxim for a theme where every response failed advises avoiding the worst.
test(maxim_avoid) :-
    co_lore:lo_reset,
    co_lore:lo_record([trap], step, bad),
    co_lore:lo_record([trap], step, bad),
    co_lore:lo_maxim([trap], Maxim),
    assertion(Maxim == avoid(step)).

% Advice fails when nothing in the past matches the present situation.
test(no_advice_no_match) :-
    setup_lore,
    assertion(\+ co_lore:lo_advise([never_seen], _, _)).

% The count reflects the recorded experiences.
test(count) :-
    setup_lore,
    co_lore:lo_count(N),
    assertion(N =:= 4).

% Close the test block.
:- end_tests(co_lore).
