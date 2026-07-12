/*  PrologAI — Causalontology Episodic Memory Test Suite  (WP-409)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_trace/test/test_co_trace.pl
*/

% Declare this file as a test module.
:- module(test_co_trace, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(co_trace)).

% Open the test block for co_trace.
:- begin_tests(co_trace).

% A recorded episode can be read back with the parts it was given.
test(record_and_read) :-
    % Start from an empty store.
    co_trace:ct_reset,
    % Record one episode and capture its id.
    co_trace:ct_record([door, locked], press(key), opened, 0.8, Id),
    % Read it back and confirm the fields survived.
    co_trace:ct_replay(Id, press(key), opened, V),
    assertion(V =:= 0.8).

% The store counts what it holds.
test(count) :-
    co_trace:ct_reset,
    co_trace:ct_record([a], act1, out1, 0.1),
    co_trace:ct_record([b], act2, out2, 0.2),
    co_trace:ct_count(N),
    assertion(N =:= 2).

% Similarity is the Jaccard overlap of the cue and the episode context.
test(similarity_jaccard) :-
    co_trace:ct_reset,
    % Context {a,b,c}; cue {a,b} shares 2 of 3 distinct features.
    co_trace:ct_record([a,b,c], act, out, 0.0, Id),
    co_trace:ct_similarity([a,b], Id, S),
    assertion(abs(S - 0.6666666666666666) < 0.0001).

% Recall returns the most similar episode for a cue.
test(recall_best) :-
    co_trace:ct_reset,
    co_trace:ct_record([sky, blue], look_up, saw_bird, 0.5, Near),
    co_trace:ct_record([ground, brown], look_down, saw_rock, 0.0, _Far),
    co_trace:ct_recall([sky, blue, cloud], Got, Score),
    assertion(Got == Near),
    assertion(Score > 0.0).

% Recalling an episode bumps its hit count.
test(recall_bumps_hits) :-
    co_trace:ct_reset,
    co_trace:ct_record([x, y], act, out, 0.0, Id),
    co_trace:ct_recall([x, y], Id, _),
    co_trace:ct_hits(Id, H),
    assertion(H =:= 1).

% Remind returns at most K matches, best first, ignoring non-overlapping ones.
test(remind_topk_ordered) :-
    co_trace:ct_reset,
    co_trace:ct_record([a,b,c], act_hi, out, 0.0, Hi),   % overlap 3/3 with cue
    co_trace:ct_record([a],     act_lo, out, 0.0, Lo),   % overlap 1/3 with cue
    co_trace:ct_record([q,r],   act_no, out, 0.0, _No),  % no overlap
    co_trace:ct_remind([a,b,c], 5, Ids),
    assertion(Ids == [Hi, Lo]).

% Reinforcement moves valence and stays clamped within [-1, 1].
test(reinforce_clamps) :-
    co_trace:ct_reset,
    co_trace:ct_record([p], act, out, 0.9, Id),
    % A +0.5 nudge would reach 1.4 but must clamp to 1.0.
    co_trace:ct_reinforce(Id, 0.5),
    co_trace:ct_replay(Id, _, _, V),
    assertion(V =:= 1.0).

% Stats report the count and the mean valence.
test(stats_mean) :-
    co_trace:ct_reset,
    co_trace:ct_record([a], act, out, 0.2),
    co_trace:ct_record([b], act, out, 0.4),
    co_trace:ct_stats(stats(Count, Mean)),
    assertion(Count =:= 2),
    assertion(abs(Mean - 0.3) < 0.0001).

% Close the test block.
:- end_tests(co_trace).
