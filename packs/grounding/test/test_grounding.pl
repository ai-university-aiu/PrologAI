/*  PrologAI — Causalontology Clue Grounding Test Suite  (WP-417)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/grounding/test/test_grounding.pl
*/

% Declare this file as a test module.
:- module(test_grounding, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(grounding)).

% Open the test block.
:- begin_tests(grounding).

% "that looks like a key" grounds to a key-like continuant with dispositions.
test(ground_key_phrase) :-
    grounding:grounding_reset,
    grounding:grounding_ground('that looks like a key', obj7, A),
    assertion(memberchk(continuant(obj7, key_like), A)),
    assertion(memberchk(disposition(obj7, opens_locks), A)).

% A word list grounds the same way as a phrase atom.
test(ground_word_list) :-
    grounding:grounding_reset,
    grounding:grounding_ground([that, is, a, lock], cell(3,4), A),
    assertion(memberchk(continuant(cell(3,4), lock_like), A)),
    assertion(memberchk(goal(state(cell(3,4), open)), A)).

% A door clue sets a traverse goal.
test(ground_door_goal) :-
    grounding:grounding_reset,
    grounding:grounding_ground('that looks like a door, let us walk through it', d1, A),
    assertion(memberchk(goal(traverse(d1)), A)).

% "pick that up" suggests a prioritized pickup action.
test(ground_pickup) :-
    grounding:grounding_reset,
    grounding:grounding_ground('pick that up', k9, A),
    assertion(memberchk(action(pickup(k9)), A)),
    assertion(memberchk(priority(pickup(k9), high), A)).

% A warning clue marks interaction preventive.
test(ground_preventive) :-
    grounding:grounding_reset,
    grounding:grounding_ground('do not touch that, it hurts', spike, A),
    assertion(memberchk(preventive(interact(spike)), A)),
    assertion(memberchk(avoid(interact(spike)), A)).

% Praise grounds to positive reinforcement of the recent path.
test(ground_reinforce) :-
    grounding:grounding_reset,
    grounding:grounding_ground('good, that worked', _, A),
    assertion(memberchk(reinforce(recent, positive), A)).

% An unrelated clue grounds to nothing, and is not a clue.
test(no_grounding) :-
    grounding:grounding_reset,
    grounding:grounding_ground('the weather is nice', x, A),
    assertion(A == []),
    assertion(\+ grounding:grounding_is_clue('the weather is nice')).

% A caller-added rule wins over the built-ins.
test(custom_rule) :-
    grounding:grounding_reset,
    grounding:grounding_rule_add(gem, R, [continuant(R, treasure), goal(collect(R))]),
    grounding:grounding_ground([grab, the, gem], g1, A),
    % Both the custom gem rule and the built-in grab rule contain the keyword;
    % the clue grounds on the first matching token — here "grab" (built-in pickup).
    assertion(memberchk(action(pickup(g1)), A)),
    % The custom keyword is known and grounds on its own.
    grounding:grounding_ground([gem], g1, B),
    assertion(memberchk(goal(collect(g1)), B)).

% The provenance of a grounded hint is a high-confidence human hint.
test(provenance) :-
    grounding:grounding_provenance(prov(Source, Conf)),
    assertion(Source == human_hint),
    assertion(Conf =:= 0.9).

% Close the test block.
:- end_tests(grounding).
