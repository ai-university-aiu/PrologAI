/*  PrologAI — Causalontology Consolidation Test Suite  (WP-416)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/consolidation/test/test_consolidation.pl
*/

% Declare this file as a test module.
:- module(test_consolidation, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(consolidation)).

% Open the test block.
:- begin_tests(consolidation).

% Re-adding the same key merges rather than duplicating.
test(add_merges_duplicates) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(rule1, cause_x_effect_y),
    consolidation:consolidation_add(rule1, cause_x_effect_y),
    consolidation:consolidation_count(N),
    assertion(N =:= 1),
    consolidation:consolidation_record(rule1, _, Uses, _),
    assertion(Uses =:= 2).

% Touch raises the use count of an existing record.
test(touch_raises_uses) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(r, v),
    consolidation:consolidation_touch(r),
    consolidation:consolidation_touch(r),
    consolidation:consolidation_record(r, _, Uses, _),
    assertion(Uses =:= 3).

% Compression reifies a sequence into one composite record.
test(compress_sequence) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_compress(open_door, [press(a), press(b), press(c)], Composite),
    assertion(Composite == composite(open_door, [press(a), press(b), press(c)])),
    consolidation:consolidation_count(N),
    assertion(N =:= 1).

% Forgetting drops records that are both low-value and stale.
test(forget_stale_lowvalue) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(old_junk, x),      % recency 1, uses 1
    consolidation:consolidation_add(a, 1),             % bump the clock forward
    consolidation:consolidation_add(b, 2),
    consolidation:consolidation_add(c, 3),             % recency now well past old_junk
    consolidation:consolidation_time(Now),
    % Cutoff just below Now spares the fresh records; junk is stale and unused.
    Cutoff is Now,
    consolidation:consolidation_forget(2, Cutoff, Dropped),
    assertion(Dropped >= 1),
    assertion(\+ consolidation:consolidation_record(old_junk, _, _, _)).

% A fresh record is spared by the grace period even if unused.
test(grace_spares_fresh) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(fresh, v),
    consolidation:consolidation_time(Now),
    % Grace cutoff below the record's recency keeps it.
    Cutoff is Now,
    consolidation:consolidation_forget(5, Cutoff, Dropped),
    assertion(Dropped =:= 0),
    assertion(consolidation:consolidation_record(fresh, _, _, _)).

% A well-used old record is spared by its value.
test(value_spares_used) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(veteran, v),
    consolidation:consolidation_touch(veteran),
    consolidation:consolidation_touch(veteran),        % uses 3
    consolidation:consolidation_add(filler, 1),        % advance the clock
    consolidation:consolidation_add(filler2, 2),
    consolidation:consolidation_time(Now),
    % Even with a high grace cutoff, uses(3) >= floor(2) keeps the veteran.
    Cutoff is Now + 1,
    consolidation:consolidation_forget(2, Cutoff, _),
    assertion(consolidation:consolidation_record(veteran, _, _, _)).

% Stats summarise the store.
test(stats_summary) :-
    consolidation:consolidation_reset,
    consolidation:consolidation_add(a, 1),
    consolidation:consolidation_add(b, 2),
    consolidation:consolidation_touch(a),
    consolidation:consolidation_stats(stats(Count, Total)),
    assertion(Count =:= 2),
    assertion(Total =:= 3).

% Close the test block.
:- end_tests(consolidation).
