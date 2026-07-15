:- use_module('../prolog/scene_rank').
:- use_module(library(plunit)).

:- begin_tests(scene_rank).

% --- Fixtures ---
% A pair: recolor r->g (scene lists)
pair_recolor([obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]).
pair_recolor2([obj(r,[r(1,0)])]-[obj(g,[r(1,0)])]).

% A pair: shift by (1,0)
pair_shift([obj(r,[r(0,0)])]-[obj(r,[r(1,0)])]).
pair_shift2([obj(b,[r(0,1)])]-[obj(b,[r(1,1)])]).

% A pair: recolor_all to g
pair_recolor_all([obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]).

% A pair where recolor(r,g) would be wrong
pair_wrong([obj(r,[r(0,0)])]-[obj(b,[r(0,0)])]).

% Two-object pairs
pair2_recolor(
    [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(g,[r(0,0)]),obj(b,[r(0,1)])]).
pair2_shift(
    [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(r,[r(1,0)]),obj(b,[r(1,1)])]).

% --- scene_rank_n_pairs/2 ---

test(n_pairs_basic) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_n_pairs([P1, P2], 2).

test(n_pairs_empty) :-
    scene_rank_n_pairs([], 0).

% --- scene_rank_coverage_pairs/3 ---

test(coverage_pairs_all) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_coverage_pairs(recolor(r,g), [P1, P2], Covered),
    Covered == [P1, P2].

test(coverage_pairs_none) :-
    pair_recolor(P1),
    scene_rank_coverage_pairs(recolor(r,b), [P1], []).

test(coverage_pairs_partial) :-
    pair_recolor(P1), pair_wrong(P2),
    scene_rank_coverage_pairs(recolor(r,g), [P1, P2], [P1]).

% --- scene_rank_coverage/3 ---

test(coverage_full) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_coverage(recolor(r,g), [P1, P2], 2).

test(coverage_zero) :-
    pair_recolor(P1),
    scene_rank_coverage(recolor(r,b), [P1], 0).

test(coverage_partial) :-
    pair_recolor(P1), pair_wrong(P2),
    scene_rank_coverage(recolor(r,g), [P1, P2], 1).

% --- scene_rank_consistent/2 ---

test(consistent_yes) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_consistent(recolor(r,g), [P1, P2]).

test(consistent_no) :-
    pair_recolor(P1), pair_wrong(P2),
    \+ scene_rank_consistent(recolor(r,g), [P1, P2]).

test(consistent_empty) :-
    scene_rank_consistent(recolor(r,g), []).

% --- scene_rank_inconsistent_pairs/3 ---

test(inconsistent_pairs_none) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_inconsistent_pairs(recolor(r,g), [P1, P2], []).

test(inconsistent_pairs_one) :-
    pair_recolor(P1), pair_wrong(P2),
    scene_rank_inconsistent_pairs(recolor(r,g), [P1, P2], [P2]).

% --- scene_rank_rule_score/3 ---

test(rule_score_alias) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_rule_score(recolor(r,g), [P1, P2], 2).

% --- scene_rank_rank_rules/3 ---

test(rank_rules_basic) :-
    pair_recolor(P1), pair_recolor2(P2), pair_shift(P3),
    Pairs = [P1, P2, P3],
    Candidates = [recolor(r,g), shift(1,0), recolor(r,b)],
    scene_rank_rank_rules(Candidates, Pairs, Ranked),
    % recolor(r,g) covers P1,P2 = 2; shift(1,0) covers P3 = 1; recolor(r,b) = 0
    Ranked = [recolor(r,g) | _].

test(rank_rules_single) :-
    pair_recolor(P),
    scene_rank_rank_rules([recolor(r,g)], [P], [recolor(r,g)]).

test(rank_rules_empty_candidates) :-
    pair_recolor(P),
    scene_rank_rank_rules([], [P], []).

% --- scene_rank_rank_candidates/3 ---

test(rank_candidates_basic) :-
    pair_recolor(P1), pair_recolor2(P2),
    Pairs = [P1, P2],
    scene_rank_rank_candidates([recolor(r,g), recolor(r,b)], Pairs, CovRules),
    CovRules = [2-recolor(r,g) | _].

% --- scene_rank_best_rule/3 ---

test(best_rule_basic) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_best_rule([recolor(r,g), recolor(r,b)], [P1, P2], recolor(r,g)).

test(best_rule_only_one) :-
    pair_recolor(P),
    scene_rank_best_rule([recolor(r,g)], [P], recolor(r,g)).

% --- scene_rank_all_consistent/3 ---

test(all_consistent_some) :-
    pair_recolor(P1), pair_recolor2(P2),
    Pairs = [P1, P2],
    scene_rank_all_consistent([recolor(r,g), recolor(r,b)], Pairs, [recolor(r,g)]).

test(all_consistent_none) :-
    pair_wrong(P),
    scene_rank_all_consistent([recolor(r,g)], [P], []).

test(all_consistent_empty_pairs) :-
    scene_rank_all_consistent([recolor(r,g), recolor(r,b)], [], Consistent),
    % every rule is vacuously consistent with []
    length(Consistent, 2).

% --- scene_rank_filter_min_coverage/4 ---

test(filter_min_coverage_basic) :-
    pair_recolor(P1), pair_recolor2(P2), pair_wrong(P3),
    Pairs = [P1, P2, P3],
    scene_rank_filter_min_coverage([recolor(r,g), recolor(r,b)], Pairs, 2, [recolor(r,g)]).

test(filter_min_coverage_zero) :-
    pair_recolor(P),
    scene_rank_filter_min_coverage([recolor(r,b)], [P], 0, [recolor(r,b)]).

% --- scene_rank_perfect_rules/3 ---

test(perfect_rules_yes) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_perfect_rules([recolor(r,g), recolor(r,b)], [P1, P2], [recolor(r,g)]).

test(perfect_rules_none) :-
    pair_recolor(P1), pair_wrong(P2),
    scene_rank_perfect_rules([recolor(r,g)], [P1, P2], []).

% --- scene_rank_coverage_ratio/3 ---

test(coverage_ratio_basic) :-
    pair_recolor(P1), pair_recolor2(P2),
    scene_rank_coverage_ratio(recolor(r,g), [P1, P2], Num/Den),
    Num == 2, Den == 2.

test(coverage_ratio_partial) :-
    pair_recolor(P1), pair_wrong(P2),
    scene_rank_coverage_ratio(recolor(r,g), [P1, P2], Num/Den),
    Num == 1, Den == 2.

% --- scene_rank_top_n_rules/4 ---

test(top_n_rules_basic) :-
    pair_recolor(P1), pair_recolor2(P2), pair_shift(P3),
    Pairs = [P1, P2, P3],
    Candidates = [recolor(r,g), shift(1,0), recolor(r,b)],
    scene_rank_top_n_rules(Candidates, Pairs, 2, TopN),
    length(TopN, 2),
    TopN = [2-recolor(r,g) | _].

test(top_n_rules_all) :-
    pair_recolor(P),
    scene_rank_top_n_rules([recolor(r,g)], [P], 5, TopN),
    % only 1 candidate, asks for 5 — returns all 1
    length(TopN, 1).

% --- Two-object pair tests ---

test(coverage_two_obj_pair) :-
    pair2_recolor(P),
    scene_rank_coverage(recolor(r,g), [P], 1).

test(coverage_two_obj_shift) :-
    pair2_shift(P),
    scene_rank_coverage(shift(1,0), [P], 1).

% --- Additional coverage tests ---

test(consistent_empty_candidates) :-
    pair_recolor(P),
    scene_rank_all_consistent([], [P], []).

test(best_rule_prefers_higher_coverage) :-
    pair_recolor(P1), pair_recolor2(P2), pair_shift(P3),
    Pairs = [P1, P2, P3],
    % recolor(r,g) covers 2; shift(1,0) covers 1
    scene_rank_best_rule([shift(1,0), recolor(r,g)], Pairs, recolor(r,g)).

test(top_n_rules_n_larger_than_candidates) :-
    pair_recolor(P),
    scene_rank_top_n_rules([recolor(r,g), recolor(r,b)], [P], 10, TopN),
    length(TopN, 2).

test(filter_min_coverage_none_pass) :-
    pair_recolor(P),
    scene_rank_filter_min_coverage([recolor(r,b)], [P], 1, []).

test(perfect_rules_all_on_empty_pairs) :-
    % every rule vacuously covers 0/0 pairs; 0 >= 0 so all are perfect
    scene_rank_perfect_rules([recolor(r,g), recolor(r,b)], [], Perfect),
    length(Perfect, 2).

test(coverage_recolor_all_rule) :-
    % recolor_all(g) on a single-red-dot pair -> g dot
    scene_rank_coverage(recolor_all(g), [[obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]], 1).

test(coverage_remove_color_rule) :-
    P = [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(b,[r(0,1)])],
    scene_rank_coverage(remove_color(r), [P], 1).

test(rank_rules_tie_deterministic) :-
    % Both rules cover 0 pairs — still returns both in some order
    pair_recolor(P),
    scene_rank_rank_rules([recolor(r,b), shift(5,5)], [P], Ranked),
    length(Ranked, 2).

:- end_tests(scene_rank).
