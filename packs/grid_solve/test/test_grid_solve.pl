:- use_module('../prolog/grid_solve').
:- use_module(library(plunit)).

% Fixtures

red_obj(obj(r, [r(0,0)])).
blue_obj(obj(b, [r(0,0)])).
green_obj(obj(g, [r(0,0)])).

red_at_01(obj(r, [r(0,1)])).
blue_at_01(obj(b, [r(0,1)])).
green_at_01(obj(g, [r(0,1)])).

red_bar(obj(r, [r(0,0), r(0,1), r(0,2)])).
blue_bar(obj(b, [r(0,0), r(0,1), r(0,2)])).
green_bar(obj(g, [r(0,0), r(0,1), r(0,2)])).

red_shifted(obj(r, [r(1,0)])).
blue_shifted(obj(b, [r(1,0)])).

% Training pairs for a "recolor red to green" task
recolor_pair(pair1,
    [obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]).
recolor_pair(pair2,
    [obj(r,[r(1,0)])]-[obj(g,[r(1,0)])]).

% Training pairs for a "shift down by 1" task
shift_pair(pair1,
    [obj(r,[r(0,0)])]-[obj(r,[r(1,0)])]).
shift_pair(pair2,
    [obj(r,[r(0,1)])]-[obj(r,[r(1,1)])]).

% Training pairs for a "recolor_all to blue" task
all_blue_pair(pair1,
    [obj(r,[r(0,0)])]-[obj(b,[r(0,0)])]).
all_blue_pair(pair2,
    [obj(g,[r(1,0)])]-[obj(b,[r(1,0)])]).

:- begin_tests(grid_solve).

% grid_solve_apply: recolor
test(apply_recolor) :-
    red_obj(R),
    grid_solve_apply(recolor(r,g), [R], Result),
    Result == [obj(g,[r(0,0)])].

% grid_solve_apply: recolor_all
test(apply_recolor_all) :-
    red_obj(R), blue_obj(B),
    grid_solve_apply(recolor_all(g), [R, B], Result),
    msort(Result, S),
    S == [obj(g,[r(0,0)]), obj(g,[r(0,0)])].

% grid_solve_apply: shift
test(apply_shift) :-
    red_obj(R),
    grid_solve_apply(shift(1,0), [R], Result),
    Result == [obj(r,[r(1,0)])].

% grid_solve_apply: shift negative
test(apply_shift_negative) :-
    red_shifted(R),
    grid_solve_apply(shift(-1,0), [R], Result),
    Result == [obj(r,[r(0,0)])].

% grid_solve_apply: to_origin
test(apply_to_origin) :-
    red_shifted(R),
    grid_solve_apply(to_origin, [R], Result),
    Result == [obj(r,[r(0,0)])].

% grid_solve_apply: reflect_h
test(apply_reflect_h) :-
    grid_solve_apply(reflect_h(3), [obj(r,[r(0,0)])], Result),
    Result == [obj(r,[r(0,2)])].

% grid_solve_apply: remove_color
test(apply_remove_color) :-
    red_obj(R), blue_obj(B),
    grid_solve_apply(remove_color(r), [R, B], Result),
    Result == [B].

% grid_solve_apply: keep_color
test(apply_keep_color) :-
    red_obj(R), blue_obj(B),
    grid_solve_apply(keep_color(r), [R, B], Result),
    Result == [R].

% grid_solve_apply: sorting_size_desc
test(apply_sort_size_desc) :-
    red_bar(RB), red_obj(R),
    grid_solve_apply(sorting_size_desc, [R, RB], Result),
    Result == [RB, R].

% grid_solve_apply: top_n
test(apply_top_n) :-
    red_bar(RB), red_obj(R),
    grid_solve_apply(top_n(1), [R, RB], Result),
    Result == [RB].

% grid_solve_apply: identity
test(apply_identity) :-
    red_obj(R), blue_obj(B),
    grid_solve_apply(identity, [R, B], Result),
    Result == [R, B].

% grid_solve_apply: color_map
test(apply_color_map) :-
    red_obj(R), blue_obj(B),
    grid_solve_apply(color_map([r-g, b-y]), [R, B], Result),
    msort(Result, S),
    S == [obj(g,[r(0,0)]), obj(y,[r(0,0)])].

% grid_solve_coverage: correct rule covers all pairs
test(coverage_correct_rule) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_coverage(recolor(r,g), [P1, P2], N),
    N == 2.

% grid_solve_coverage: wrong rule covers zero pairs
test(coverage_wrong_rule) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_coverage(recolor(r,b), [P1, P2], N),
    N == 0.

% grid_solve_coverage: empty pairs
test(coverage_empty_pairs) :-
    grid_solve_coverage(recolor(r,g), [], N),
    N == 0.

% grid_solve_consistent: correct rule
test(consistent_correct) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_consistent(recolor(r,g), [P1, P2]).

% grid_solve_consistent: wrong rule fails
test(consistent_wrong_fails) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    \+ grid_solve_consistent(recolor(r,b), [P1, P2]).

% grid_solve_consistent: empty pairs always passes
test(consistent_empty_pairs) :-
    grid_solve_consistent(recolor(r,g), []).

% grid_solve_rank_rules: higher coverage first
test(rank_rules_order) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_rank_rules([recolor(r,b), recolor(r,g)], [P1, P2], Ranked),
    Ranked == [recolor(r,g), recolor(r,b)].

% grid_solve_rank_rules: empty rule list
test(rank_rules_empty) :-
    recolor_pair(pair1, P1),
    grid_solve_rank_rules([], [P1], Ranked),
    Ranked == [].

% grid_solve_best_rule: correct rule wins
test(best_rule_wins) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_best_rule([recolor(r,b), recolor(r,g)], [P1, P2], Best),
    Best == recolor(r,g).

% grid_solve_consistent_rules: filters to fully consistent
test(consistent_rules_filter) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_consistent_rules([recolor(r,g), recolor(r,b)], [P1, P2], Consistent),
    Consistent == [recolor(r,g)].

% grid_solve_consistent_rules: empty candidates
test(consistent_rules_empty_candidates) :-
    recolor_pair(pair1, P1),
    grid_solve_consistent_rules([], [P1], Consistent),
    Consistent == [].

% grid_solve_valid_rules: filters to rules with coverage > 0
test(valid_rules_filter) :-
    recolor_pair(pair1, P1),
    grid_solve_valid_rules([recolor(r,g), recolor(r,b)], [P1], Valid),
    Valid == [recolor(r,g)].

% grid_solve_valid_rules: identity has zero coverage on recolor pair
test(valid_rules_identity_zero) :-
    recolor_pair(pair1, P1),
    grid_solve_valid_rules([identity, recolor(r,g)], [P1], Valid),
    Valid == [recolor(r,g)].

% grid_solve_infer_candidates: recolor task
test(infer_candidates_recolor) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_infer_candidates([P1, P2], Candidates),
    member(recolor(r,g), Candidates).

% grid_solve_infer_candidates: shift task
test(infer_candidates_shift) :-
    shift_pair(pair1, P1), shift_pair(pair2, P2),
    grid_solve_infer_candidates([P1, P2], Candidates),
    member(shift(1,0), Candidates).

% grid_solve_infer_candidates: empty pairs gives empty list
test(infer_candidates_empty) :-
    grid_solve_infer_candidates([], Candidates),
    Candidates == [].

% grid_solve_default_candidates: contains common rules
test(default_candidates_contents) :-
    grid_solve_default_candidates(Cands),
    member(recolor(r,b), Cands),
    member(shift(1,0), Cands),
    member(to_origin, Cands),
    member(identity, Cands).

% grid_solve_solve: recolor task
test(solve_recolor) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_solve([P1, P2], [obj(r,[r(2,0)])], Output),
    msort(Output, S),
    S == [obj(g,[r(2,0)])].

% grid_solve_solve: shift task
test(solve_shift) :-
    shift_pair(pair1, P1), shift_pair(pair2, P2),
    grid_solve_solve([P1, P2], [obj(r,[r(0,0)])], Output),
    Output == [obj(r,[r(1,0)])].

% grid_solve_solve: recolor_all task
test(solve_recolor_all) :-
    all_blue_pair(pair1, P1), all_blue_pair(pair2, P2),
    grid_solve_solve([P1, P2], [obj(g,[r(5,5)])], Output),
    Output == [obj(b,[r(5,5)])].

% grid_solve_solve_n: returns top N rules
test(solve_n_returns_n) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_solve_n([P1, P2], 2, TopRules, _),
    length(TopRules, 2).

% grid_solve_solve_n: best rule achieves full coverage and applies correctly
test(solve_n_best_rule) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_solve_n([P1, P2], 1, [Cov-_], BestRule),
    Cov == 2,
    grid_solve_apply(BestRule, [obj(r,[r(2,0)])], Out),
    msort(Out, S),
    S == [obj(g,[r(2,0)])].

% grid_solve_explain: returns a fully-covering rule that works on new input
test(explain_recolor) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_explain([P1, P2], BestRule, Coverage),
    Coverage == 2,
    grid_solve_apply(BestRule, [obj(r,[r(5,5)])], Out),
    msort(Out, S),
    S == [obj(g,[r(5,5)])].

% grid_solve_explain: shift task
test(explain_shift) :-
    shift_pair(pair1, P1), shift_pair(pair2, P2),
    grid_solve_explain([P1, P2], BestRule, Coverage),
    BestRule == shift(1,0),
    Coverage == 2.

% grid_solve_n_pairs: count
test(n_pairs_count) :-
    recolor_pair(pair1, P1), recolor_pair(pair2, P2),
    grid_solve_n_pairs([P1, P2], N),
    N == 2.

% grid_solve_n_pairs: empty
test(n_pairs_empty) :-
    grid_solve_n_pairs([], N),
    N == 0.

% grid_solve_all_same_output: apply rule to multiple inputs
test(all_same_output) :-
    grid_solve_all_same_output(recolor(r,g),
        [[obj(r,[r(0,0)])], [obj(r,[r(1,0)])]],
        Outputs),
    Outputs == [[obj(g,[r(0,0)])], [obj(g,[r(1,0)])]].

% grid_solve_all_same_output: empty inputs
test(all_same_output_empty) :-
    grid_solve_all_same_output(recolor(r,g), [], Outputs),
    Outputs == [].

% grid_solve_solve: identity rule wins when all pairs already match
test(solve_identity_wins) :-
    % Both pairs: same scene before and after
    P1 = [obj(r,[r(0,0)])]-[obj(r,[r(0,0)])],
    P2 = [obj(r,[r(1,0)])]-[obj(r,[r(1,0)])],
    grid_solve_solve([P1, P2], [obj(r,[r(5,5)])], Output),
    % Output should be the scene unchanged (some consistent rule applies)
    Output = [obj(_, [r(5,5)])].

:- end_tests(grid_solve).
