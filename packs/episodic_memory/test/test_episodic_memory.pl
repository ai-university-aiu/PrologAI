/*  PrologAI — Causalontology Episodic Memory Test Suite  (WP-409)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/episodic_memory/test/test_episodic_memory.pl
*/

% Declare this file as a test module.
:- module(test_episodic_memory, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(episodic_memory)).

% Open the test block for episodic_memory.
:- begin_tests(episodic_memory).

% A recorded episode can be read back with the parts it was given.
test(record_and_read) :-
    % Start from an empty store.
    episodic_memory:episodic_memory_reset,
    % Record one episode and capture its id.
    episodic_memory:episodic_memory_record([door, locked], press(key), opened, 0.8, Id),
    % Read it back and confirm the fields survived.
    episodic_memory:episodic_memory_replay(Id, press(key), opened, V),
    assertion(V =:= 0.8).

% The store counts what it holds.
test(count) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([a], act1, out1, 0.1),
    episodic_memory:episodic_memory_record([b], act2, out2, 0.2),
    episodic_memory:episodic_memory_count(N),
    assertion(N =:= 2).

% Similarity is the Jaccard overlap of the cue and the episode context.
test(similarity_jaccard) :-
    episodic_memory:episodic_memory_reset,
    % Context {a,b,c}; cue {a,b} shares 2 of 3 distinct features.
    episodic_memory:episodic_memory_record([a,b,c], act, out, 0.0, Id),
    episodic_memory:episodic_memory_similarity([a,b], Id, S),
    assertion(abs(S - 0.6666666666666666) < 0.0001).

% Recall returns the most similar episode for a cue.
test(recall_best) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([sky, blue], look_up, saw_bird, 0.5, Near),
    episodic_memory:episodic_memory_record([ground, brown], look_down, saw_rock, 0.0, _Far),
    episodic_memory:episodic_memory_recall([sky, blue, cloud], Got, Score),
    assertion(Got == Near),
    assertion(Score > 0.0).

% Recalling an episode bumps its hit count.
test(recall_bumps_hits) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([x, y], act, out, 0.0, Id),
    episodic_memory:episodic_memory_recall([x, y], Id, _),
    episodic_memory:episodic_memory_hits(Id, H),
    assertion(H =:= 1).

% Remind returns at most K matches, best first, ignoring non-overlapping ones.
test(remind_topk_ordered) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([a,b,c], act_hi, out, 0.0, Hi),   % overlap 3/3 with cue
    episodic_memory:episodic_memory_record([a],     act_lo, out, 0.0, Lo),   % overlap 1/3 with cue
    episodic_memory:episodic_memory_record([q,r],   act_no, out, 0.0, _No),  % no overlap
    episodic_memory:episodic_memory_remind([a,b,c], 5, Ids),
    assertion(Ids == [Hi, Lo]).

% Reinforcement moves valence and stays clamped within [-1, 1].
test(reinforce_clamps) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([p], act, out, 0.9, Id),
    % A +0.5 nudge would reach 1.4 but must clamp to 1.0.
    episodic_memory:episodic_memory_reinforce(Id, 0.5),
    episodic_memory:episodic_memory_replay(Id, _, _, V),
    assertion(V =:= 1.0).

% Stats report the count and the mean valence.
test(stats_mean) :-
    episodic_memory:episodic_memory_reset,
    episodic_memory:episodic_memory_record([a], act, out, 0.2),
    episodic_memory:episodic_memory_record([b], act, out, 0.4),
    episodic_memory:episodic_memory_stats(stats(Count, Mean)),
    assertion(Count =:= 2),
    assertion(abs(Mean - 0.3) < 0.0001).

% Close the test block.
:- end_tests(episodic_memory).
