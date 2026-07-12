/*  PrologAI — Causalontology Consolidation Test Suite  (WP-416)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_distill/test/test_co_distill.pl
*/

% Declare this file as a test module.
:- module(test_co_distill, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_distill)).

% Open the test block.
:- begin_tests(co_distill).

% Re-adding the same key merges rather than duplicating.
test(add_merges_duplicates) :-
    co_distill:di_reset,
    co_distill:di_add(rule1, cause_x_effect_y),
    co_distill:di_add(rule1, cause_x_effect_y),
    co_distill:di_count(N),
    assertion(N =:= 1),
    co_distill:di_record(rule1, _, Uses, _),
    assertion(Uses =:= 2).

% Touch raises the use count of an existing record.
test(touch_raises_uses) :-
    co_distill:di_reset,
    co_distill:di_add(r, v),
    co_distill:di_touch(r),
    co_distill:di_touch(r),
    co_distill:di_record(r, _, Uses, _),
    assertion(Uses =:= 3).

% Compression reifies a sequence into one composite record.
test(compress_sequence) :-
    co_distill:di_reset,
    co_distill:di_compress(open_door, [press(a), press(b), press(c)], Composite),
    assertion(Composite == composite(open_door, [press(a), press(b), press(c)])),
    co_distill:di_count(N),
    assertion(N =:= 1).

% Forgetting drops records that are both low-value and stale.
test(forget_stale_lowvalue) :-
    co_distill:di_reset,
    co_distill:di_add(old_junk, x),      % recency 1, uses 1
    co_distill:di_add(a, 1),             % bump the clock forward
    co_distill:di_add(b, 2),
    co_distill:di_add(c, 3),             % recency now well past old_junk
    co_distill:di_time(Now),
    % Cutoff just below Now spares the fresh records; junk is stale and unused.
    Cutoff is Now,
    co_distill:di_forget(2, Cutoff, Dropped),
    assertion(Dropped >= 1),
    assertion(\+ co_distill:di_record(old_junk, _, _, _)).

% A fresh record is spared by the grace period even if unused.
test(grace_spares_fresh) :-
    co_distill:di_reset,
    co_distill:di_add(fresh, v),
    co_distill:di_time(Now),
    % Grace cutoff below the record's recency keeps it.
    Cutoff is Now,
    co_distill:di_forget(5, Cutoff, Dropped),
    assertion(Dropped =:= 0),
    assertion(co_distill:di_record(fresh, _, _, _)).

% A well-used old record is spared by its value.
test(value_spares_used) :-
    co_distill:di_reset,
    co_distill:di_add(veteran, v),
    co_distill:di_touch(veteran),
    co_distill:di_touch(veteran),        % uses 3
    co_distill:di_add(filler, 1),        % advance the clock
    co_distill:di_add(filler2, 2),
    co_distill:di_time(Now),
    % Even with a high grace cutoff, uses(3) >= floor(2) keeps the veteran.
    Cutoff is Now + 1,
    co_distill:di_forget(2, Cutoff, _),
    assertion(co_distill:di_record(veteran, _, _, _)).

% Stats summarise the store.
test(stats_summary) :-
    co_distill:di_reset,
    co_distill:di_add(a, 1),
    co_distill:di_add(b, 2),
    co_distill:di_touch(a),
    co_distill:di_stats(stats(Count, Total)),
    assertion(Count =:= 2),
    assertion(Total =:= 3).

% Close the test block.
:- end_tests(co_distill).
