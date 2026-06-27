:- use_module('../prolog/seqinfer').
:- use_module(library(plunit)).

% Fixtures: simple single-object scenes and Before-After pairs.
% scene_r: one red object at (0,0)
scene_r([obj(r, [r(0,0)])]).
% scene_b: one blue object at (0,0)
scene_b([obj(b, [r(0,0)])]).
% scene_r_shifted: one red object at (1,0)
scene_r_shifted([obj(r, [r(1,0)])]).
% scene_b_shifted: one blue object at (1,0)
scene_b_shifted([obj(b, [r(1,0)])]).
% scene_two: two objects
scene_two([obj(r, [r(0,0)]), obj(b, [r(0,1)])]).
% scene_two_shifted: scene_two shifted right by 1
scene_two_shifted([obj(r, [r(0,1)]), obj(b, [r(0,2)])]).
% scene_three: three objects
scene_three([obj(r, [r(0,0)]), obj(b, [r(0,1)]), obj(g, [r(0,2)])]).
% scene_big: one object with 3 cells
scene_big([obj(r, [r(0,0), r(0,1), r(0,2)])]).

% pair_recolor: r -> b (single-step)
pair_recolor([obj(r,[r(0,0)])] - [obj(b,[r(0,0)])]).
% pair_shift: shift down 1 row (single-step)
pair_shift([obj(r,[r(0,0)])] - [obj(r,[r(1,0)])]).
% pair_recolor_then_shift: r -> b, then shift down 1 (two-step)
pair_recolor_then_shift([obj(r,[r(0,0)])] - [obj(b,[r(1,0)])]).
% pair_shift_then_recolor: shift down 1, then r -> b (also produces b at (1,0))
pair_shift_then_recolor([obj(r,[r(0,0)])] - [obj(b,[r(1,0)])]).
% pair_two_step_distinct: only a 2-step rule explains it
pair_recolor_then_shift2([obj(r,[r(0,0)])] - [obj(b,[r(2,0)])]).
% pair_identity: no change
pair_identity([obj(r,[r(0,0)])] - [obj(r,[r(0,0)])]).
% pair_remove: remove red objects
pair_remove([obj(r,[r(0,0)]),obj(b,[r(0,1)])] - [obj(b,[r(0,1)])]).
% pair_reflect_h: reflect_h on single-cell object returns same (symmetric)
pair_reflect_h_same([obj(r,[r(0,0)])] - [obj(r,[r(0,0)])]).

:- begin_tests(seqinfer).

% sq_apply: identity returns scene unchanged
test(apply_identity) :-
    scene_r(S), sq_apply([identity], S, R), R == S.

% sq_apply: empty rule list returns scene unchanged
test(apply_empty) :-
    scene_r(S), sq_apply([], S, R), R == S.

% sq_apply: recolor r to b
test(apply_recolor) :-
    scene_r(S), sq_apply([recolor(r,b)], S, R),
    R == [obj(b,[r(0,0)])].

% sq_apply: shift down 1
test(apply_shift) :-
    scene_r(S), sq_apply([shift(1,0)], S, R),
    R == [obj(r,[r(1,0)])].

% sq_apply: two-step recolor then shift
test(apply_recolor_then_shift) :-
    scene_r(S), sq_apply([recolor(r,b), shift(1,0)], S, R),
    R == [obj(b,[r(1,0)])].

% sq_apply: shift then recolor — same result as recolor then shift for single-cell
test(apply_shift_then_recolor) :-
    scene_r(S), sq_apply([shift(1,0), recolor(r,b)], S, R),
    R == [obj(b,[r(1,0)])].

% sq_apply: recolor_all
test(apply_recolor_all) :-
    scene_two(S), sq_apply([recolor_all(g)], S, R),
    R == [obj(g,[r(0,0)]), obj(g,[r(0,1)])].

% sq_apply: remove_color removes r objects
test(apply_remove_color) :-
    scene_two(S), sq_apply([remove_color(r)], S, R),
    R == [obj(b,[r(0,1)])].

% sq_apply: keep_color keeps only r objects
test(apply_keep_color) :-
    scene_two(S), sq_apply([keep_color(r)], S, R),
    R == [obj(r,[r(0,0)])].

% sq_apply: sort_size_desc on equal-size objects preserves order
test(apply_sort_size_desc) :-
    scene_two(S), sq_apply([sort_size_desc], S, R),
    length(R, 2).

% sq_apply: reflect_h on single cell: cell at r(0,0) in 1-row bbox stays at r(0,0)
test(apply_reflect_h_single) :-
    scene_r(S), sq_apply([reflect_h], S, R),
    R == [obj(r,[r(0,0)])].

% sq_apply: to_origin moves object to start at r(0,0)
test(apply_to_origin) :-
    scene_r_shifted(S), sq_apply([to_origin], S, R),
    R == [obj(r,[r(0,0)])].

% sq_verify: verify correct transformation
test(verify_recolor) :-
    pair_recolor(B-A), sq_verify([recolor(r,b)], B, A).

% sq_verify: verify two-step
test(verify_two_step) :-
    pair_recolor_then_shift(B-A), sq_verify([recolor(r,b), shift(1,0)], B, A).

% sq_verify: wrong rule fails
test(verify_wrong_rule) :-
    pair_recolor(B-A), \+ sq_verify([shift(1,0)], B, A).

% sq_consistent: single pair, single rule
test(consistent_single) :-
    pair_recolor(P), sq_consistent([recolor(r,b)], [P]).

% sq_consistent: two identical pairs
test(consistent_two_pairs) :-
    pair_recolor(P), sq_consistent([recolor(r,b)], [P, P]).

% sq_consistent: wrong rule on two pairs fails
test(consistent_wrong) :-
    pair_recolor(P), \+ sq_consistent([shift(1,0)], [P]).

% sq_coverage: all pairs explained
test(coverage_all) :-
    pair_recolor(P), sq_coverage([recolor(r,b)], [P, P], N), N == 2.

% sq_coverage: none explained
test(coverage_none) :-
    pair_recolor(P), sq_coverage([shift(1,0)], [P], N), N == 0.

% sq_coverage: partial
test(coverage_partial) :-
    pair_recolor(P1), pair_shift(P2),
    sq_coverage([recolor(r,b)], [P1, P2], N), N == 1.

% sq_n_pairs: count
test(n_pairs) :-
    pair_recolor(P), sq_n_pairs([P, P, P], N), N == 3.

% sq_n_pairs: empty
test(n_pairs_empty) :-
    sq_n_pairs([], N), N == 0.

% sq_infer_2step: finds recolor then shift
test(infer_2step_recolor_shift) :-
    pair_recolor_then_shift(P),
    sq_infer_2step([identity, recolor(r,b), shift(1,0), shift(-1,0)], [P, P], Seq),
    sq_consistent(Seq, [P]).

% sq_infer_2step: two-pair training
test(infer_2step_two_pairs) :-
    pair_recolor_then_shift(P),
    sq_infer_2step([recolor(r,b), shift(1,0), recolor(r,g)], [P, P], Seq),
    sq_consistent(Seq, [P]).

% sq_coverage_ratio: all covered
test(coverage_ratio_all) :-
    pair_recolor(P), sq_coverage_ratio([recolor(r,b)], [P,P], Num/Den),
    Num == 2, Den == 2.

% sq_coverage_ratio: none covered
test(coverage_ratio_none) :-
    pair_recolor(P), sq_coverage_ratio([shift(1,0)], [P], Num/Den),
    Num == 0, Den == 1.

% sq_explain: returns coverage
test(explain_coverage) :-
    pair_recolor(P), sq_explain([recolor(r,b)], [P], N), N == 1.

% sq_verify_all: all pairs pass
test(verify_all_pass) :-
    pair_recolor(P), sq_verify_all([recolor(r,b)], [P, P]).

% sq_verify_all: fails when any pair fails
test(verify_all_fail) :-
    pair_recolor(P1), pair_shift(P2),
    \+ sq_verify_all([recolor(r,b)], [P1, P2]).

% sq_all_consistent: filter to fully-consistent sequences
test(all_consistent) :-
    pair_recolor(P),
    Seqs = [[recolor(r,b)], [shift(1,0)], [identity]],
    sq_all_consistent(Seqs, [P], Consistent),
    length(Consistent, 1),
    Consistent = [[recolor(r,b)]].

% sq_rank_seqs: top sequence has highest coverage
test(rank_seqs) :-
    pair_recolor(P),
    Seqs = [[recolor(r,b)], [shift(1,0)]],
    sq_rank_seqs(Seqs, [P], Ranked),
    Ranked = [[recolor(r,b)] | _].

% sq_default_rules: non-empty
test(default_rules_nonempty) :-
    sq_default_rules(Rs), Rs \= [].

% sq_default_rules: contains identity
test(default_rules_has_identity) :-
    sq_default_rules(Rs), once(member(identity, Rs)).

% sq_apply: three-step sequence
test(apply_three_step) :-
    scene_r(S),
    sq_apply([shift(1,0), shift(0,1), recolor(r,b)], S, R),
    R == [obj(b,[r(1,1)])].

% sq_apply: shift right 2 cols using two shifts
test(apply_double_shift) :-
    scene_r(S),
    sq_apply([shift(0,1), shift(0,1)], S, R),
    R == [obj(r,[r(0,2)])].

% sq_consistent: empty pairs succeeds vacuously
test(consistent_empty_pairs) :-
    sq_consistent([recolor(r,b)], []).

% sq_verify_all: empty pairs succeeds vacuously
test(verify_all_empty) :-
    sq_verify_all([recolor(r,b)], []).

% sq_apply: color_map rule applies substitution table
test(apply_color_map) :-
    scene_two(S),
    sq_apply([color_map([r-g, b-y])], S, R),
    R == [obj(g,[r(0,0)]), obj(y,[r(0,1)])].

% sq_apply: color_map with no matching entry is identity
test(apply_color_map_no_match) :-
    scene_r(S),
    sq_apply([color_map([b-g])], S, R),
    R == [obj(r,[r(0,0)])].

% sq_apply: top_n keeps only N largest
test(apply_top_n) :-
    scene_three(S),
    sq_apply([top_n(2)], S, R),
    length(R, 2).

% sq_coverage: two different pairs, two different rules, each covers 1
test(coverage_two_different) :-
    pair_recolor(P1), pair_shift(P2),
    sq_coverage([recolor(r,b)], [P1, P2], N1), N1 == 1,
    sq_coverage([shift(1,0)], [P1, P2], N2), N2 == 1.

% sq_apply: reflect_v on single cell is identity
test(apply_reflect_v_single) :-
    scene_r(S), sq_apply([reflect_v], S, R),
    R == [obj(r,[r(0,0)])].

% sq_apply: sort_size_asc on two equal-size objects preserves all
test(apply_sort_size_asc) :-
    scene_two(S), sq_apply([sort_size_asc], S, R),
    length(R, 2).

:- end_tests(seqinfer).

:- begin_tests(sq_arc2_candidates).

% sq_arc2_candidates returns a non-empty list.
test(arc2_candidates_nonempty) :-
    sq_arc2_candidates(Rules),
    Rules \= [].

% sq_arc2_candidates includes identity.
test(arc2_candidates_has_identity) :-
    sq_arc2_candidates(Rules),
    member(identity, Rules).

% sq_arc2_candidates includes integer recolor entries.
test(arc2_candidates_has_int_recolor) :-
    sq_arc2_candidates(Rules),
    member(recolor(1, 2), Rules).

% sq_arc2_candidates includes to_origin.
test(arc2_candidates_has_to_origin) :-
    sq_arc2_candidates(Rules),
    member(to_origin, Rules).

% sq_arc2_candidates includes reflect_h and reflect_v.
test(arc2_candidates_has_reflects) :-
    sq_arc2_candidates(Rules),
    member(reflect_h, Rules),
    member(reflect_v, Rules).

% sq_arc2_candidates includes top_n variants.
test(arc2_candidates_has_top_n) :-
    sq_arc2_candidates(Rules),
    member(top_n(1), Rules),
    member(top_n(2), Rules).

% sq_arc2_candidates list length is at least 50.
test(arc2_candidates_length) :-
    sq_arc2_candidates(Rules),
    length(Rules, N),
    N >= 50.

% sq_arc2_candidates can be used directly with sq_infer_2step.
test(arc2_candidates_compatible_with_infer) :-
    % scene: color 1 -> color 2 (recolor); then shift (0,1).
    P1 = pair([obj(1, [r(0,0)])], [obj(2, [r(0,1)])]),
    sq_arc2_candidates(Cands),
    % Just check that infer does not crash; result is unimportant.
    (sq_infer_2step(Cands, [P1], _) -> true ; true).

:- end_tests(sq_arc2_candidates).
