% scenerank.pl - Layer 189: Rule Hypothesis Ranking for obj(Color,Cells) Scene Lists (rk_* prefix).
% Given a list of Before-After scene pairs (training examples) and a list of
% candidate rule terms, ranks the candidates by coverage (how many pairs each
% rule explains) and consistency (whether the rule correctly transforms every
% explained pair). Used to select the best symbolic rule for a puzzle.
% A Before-After pair is expressed as the term Before-After.
% Rule terms follow the sceneapply vocabulary.
% No cross-pack dependencies. Uses library(lists) and library(apply).
:- module(scenerank, [
    % scenerank_coverage/3: count of pairs that the rule explains (transforms correctly).
    scenerank_coverage/3,
    % scenerank_consistent/2: rule correctly transforms every pair in the list.
    scenerank_consistent/2,
    % scenerank_inconsistent_pairs/3: pairs that the rule does NOT correctly transform.
    scenerank_inconsistent_pairs/3,
    % scenerank_rank_rules/3: sort candidate rules by coverage descending, then term order.
    scenerank_rank_rules/3,
    % scenerank_best_rule/3: the rule with the highest coverage on the pair list.
    scenerank_best_rule/3,
    % scenerank_all_consistent/3: rules from the candidate list that are fully consistent.
    scenerank_all_consistent/3,
    % scenerank_coverage_pairs/3: list of pairs that the rule correctly explains.
    scenerank_coverage_pairs/3,
    % scenerank_rule_score/3: coverage count for a single rule (alias for scenerank_coverage).
    scenerank_rule_score/3,
    % scenerank_filter_min_coverage/4: keep only rules whose coverage is >= MinN.
    scenerank_filter_min_coverage/4,
    % scenerank_n_pairs/2: number of pairs in the pair list.
    scenerank_n_pairs/2,
    % scenerank_perfect_rules/3: rules with coverage == total pair count.
    scenerank_perfect_rules/3,
    % scenerank_coverage_ratio/3: coverage as a fraction Num/Den (both integers).
    scenerank_coverage_ratio/3,
    % scenerank_rank_candidates/3: like scenerank_rank_rules but returns Coverage-Rule pairs.
    scenerank_rank_candidates/3,
    % scenerank_top_n_rules/4: the top N rules by coverage (Coverage-Rule pairs).
    scenerank_top_n_rules/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, append/3]).
:- use_module(library(apply), [include/3, maplist/2]).

% --- Private helpers ---------------------------------------------------------

% scenerank_pair_ok_(+Rule, +Pair): Rule correctly transforms Before to After.
% Uses msort for order-insensitive comparison.
scenerank_pair_ok_(Rule, Before-After) :-
    scenerank_apply_(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% scenerank_apply_(+Rule, +Scene, -Scene2): apply one rule term to a scene.
% Implements the same dispatch as sceneapply but without importing that pack.
scenerank_apply_(recolor(Old, New), Scene, Scene2) :-
    maplist(scenerank_recolor_atom_(Old, New), Scene, Scene2).
scenerank_apply_(recolor_all(New), Scene, Scene2) :-
    maplist(scenerank_set_color_(New), Scene, Scene2).
scenerank_apply_(color_map(Map), Scene, Scene2) :-
    maplist(scenerank_apply_map_(Map), Scene, Scene2).
scenerank_apply_(shift(DR, DC), Scene, Scene2) :-
    maplist(scenerank_shift_obj_(DR, DC), Scene, Scene2).
scenerank_apply_(to_origin, [], []) :- !.
scenerank_apply_(to_origin, Scene, Scene2) :-
    scenerank_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR, DC is -MinC,
    maplist(scenerank_shift_obj_(DR, DC), Scene, Scene2).
scenerank_apply_(reflect_h(Width), Scene, Scene2) :-
    maplist(scenerank_reflect_h_(Width), Scene, Scene2).
scenerank_apply_(reflect_v(Height), Scene, Scene2) :-
    maplist(scenerank_reflect_v_(Height), Scene, Scene2).
scenerank_apply_(remove_color(Color), Scene, Scene2) :-
    findall(O, (member(O, Scene), O = obj(C,_), C \== Color), Scene2).
scenerank_apply_(keep_color(Color), Scene, Scene2) :-
    findall(O, (member(O, Scene), O = obj(C,_), C == Color), Scene2).
scenerank_apply_(sort_size_desc, Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), O = obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, KSorted),
    pairs_values_(KSorted, Sorted).
scenerank_apply_(sort_size_asc, Scene, Sorted) :-
    findall(N-O, (member(O, Scene), O = obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, KSorted),
    pairs_values_(KSorted, Sorted).
scenerank_apply_(top_n(N), Scene, TopN) :-
    scenerank_apply_(sort_size_desc, Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
scenerank_apply_(top_n(_), Scene, Scene).

% pairs_values_: extract values from Key-Value list.
pairs_values_([], []).
pairs_values_([_-V|T], [V|VT]) :-
    pairs_values_(T, VT).

% scenerank_recolor_atom_: recolor one object if color matches.
scenerank_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
scenerank_recolor_atom_(_, _, Obj, Obj).

% scenerank_set_color_: set one object to a fixed color.
scenerank_set_color_(New, obj(_, Cells), obj(New, Cells)).

% scenerank_apply_map_: apply a color map to one object.
scenerank_apply_map_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map)
    ->  true
    ;   NewC = C
    ).

% scenerank_shift_obj_: shift one object by (DR, DC).
scenerank_shift_obj_(DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,CF), Cells), NR is R+DR, NC is CF+DC),
        Shifted).

% scenerank_reflect_h_: reflect one object horizontally within Width.
scenerank_reflect_h_(Width, obj(C, Cells), obj(C, Reflected)) :-
    W1 is Width - 1,
    findall(r(R, NC), (member(r(R,C2), Cells), NC is W1 - C2), Reflected).

% scenerank_reflect_v_: reflect one object vertically within Height.
scenerank_reflect_v_(Height, obj(C, Cells), obj(C, Reflected)) :-
    H1 is Height - 1,
    findall(r(NR, CF), (member(r(R,CF), Cells), NR is H1 - R), Reflected).

% scenerank_scene_bbox_: bounding box of the whole scene.
scenerank_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_,Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_,Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% --- Exported predicates -----------------------------------------------------

% scenerank_n_pairs(+Pairs, -N): number of pairs in the pair list.
scenerank_n_pairs(Pairs, N) :-
    length(Pairs, N).

% scenerank_coverage_pairs(+Rule, +Pairs, -Covered): list of pairs the rule explains.
scenerank_coverage_pairs(Rule, Pairs, Covered) :-
    include(scenerank_pair_ok_(Rule), Pairs, Covered).

% scenerank_coverage(+Rule, +Pairs, -N): count of pairs the rule correctly explains.
scenerank_coverage(Rule, Pairs, N) :-
    scenerank_coverage_pairs(Rule, Pairs, Covered),
    length(Covered, N).

% scenerank_consistent(+Rule, +Pairs): rule correctly transforms every pair.
scenerank_consistent(Rule, Pairs) :-
    maplist(scenerank_pair_ok_(Rule), Pairs).

% scenerank_inconsistent_pairs(+Rule, +Pairs, -Bad): pairs the rule does not explain.
scenerank_inconsistent_pairs(Rule, Pairs, Bad) :-
    findall(P, (member(P, Pairs), \+ scenerank_pair_ok_(Rule, P)), Bad).

% scenerank_rule_score(+Rule, +Pairs, -N): alias for scenerank_coverage.
scenerank_rule_score(Rule, Pairs, N) :-
    scenerank_coverage(Rule, Pairs, N).

% scenerank_rank_rules(+Rules, +Pairs, -Ranked): sort Rules by coverage descending.
% Ranked is a list of Rule atoms/terms in coverage-descending order.
% Ties are broken by standard term order (ascending), giving a stable order.
scenerank_rank_rules(Rules, Pairs, Ranked) :-
    findall(NegN-Rule,
        (member(Rule, Rules),
         scenerank_coverage(Rule, Pairs, N),
         NegN is -N),
        Keyed),
    msort(Keyed, Sorted),
    pairs_values_(Sorted, Ranked).

% scenerank_rank_candidates(+Rules, +Pairs, -CovRulePairs): Coverage-Rule pairs, desc.
scenerank_rank_candidates(Rules, Pairs, CovRulePairs) :-
    findall(NegN-N-Rule,
        (member(Rule, Rules),
         scenerank_coverage(Rule, Pairs, N),
         NegN is -N),
        Keyed),
    msort(Keyed, Sorted),
    findall(N-Rule, member(_-N-Rule, Sorted), CovRulePairs).

% scenerank_best_rule(+Rules, +Pairs, -Best): the rule with the highest coverage.
% Fails if Rules is empty.
scenerank_best_rule(Rules, Pairs, Best) :-
    scenerank_rank_rules(Rules, Pairs, [Best | _]).

% scenerank_all_consistent(+Rules, +Pairs, -Consistent): rules fully consistent with all pairs.
scenerank_all_consistent(Rules, Pairs, Consistent) :-
    include(scenerank_consistent_check_(Pairs), Rules, Consistent).

% scenerank_consistent_check_: helper for include/3.
scenerank_consistent_check_(Pairs, Rule) :-
    scenerank_consistent(Rule, Pairs).

% scenerank_filter_min_coverage(+Rules, +Pairs, +MinN, -Filtered): keep rules with coverage >= MinN.
scenerank_filter_min_coverage(Rules, Pairs, MinN, Filtered) :-
    include(scenerank_coverage_ge_(Pairs, MinN), Rules, Filtered).

% scenerank_coverage_ge_: helper for include/3.
scenerank_coverage_ge_(Pairs, MinN, Rule) :-
    scenerank_coverage(Rule, Pairs, N),
    N >= MinN.

% scenerank_perfect_rules(+Rules, +Pairs, -Perfect): rules whose coverage equals pair count.
scenerank_perfect_rules(Rules, Pairs, Perfect) :-
    scenerank_n_pairs(Pairs, Total),
    scenerank_filter_min_coverage(Rules, Pairs, Total, Perfect).

% scenerank_coverage_ratio(+Rule, +Pairs, -Num/Den): coverage as a fraction.
% Den is the number of pairs; Num is the coverage count.
scenerank_coverage_ratio(Rule, Pairs, Num/Den) :-
    scenerank_n_pairs(Pairs, Den),
    scenerank_coverage(Rule, Pairs, Num).

% scenerank_top_n_rules(+Rules, +Pairs, +N, -TopN): the top N rules as Coverage-Rule pairs.
scenerank_top_n_rules(Rules, Pairs, N, TopN) :-
    scenerank_rank_candidates(Rules, Pairs, All),
    length(Prefix, N),
    (   append(Prefix, _, All)
    ->  TopN = Prefix
    ;   TopN = All
    ).
