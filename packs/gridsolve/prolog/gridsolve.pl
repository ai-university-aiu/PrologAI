% gridsolve: end-to-end scene puzzle solver (gs_*, Layer 191)
:- module(gridsolve, [
    gs_apply/3,
    gs_coverage/3,
    gs_consistent/2,
    gs_rank_rules/3,
    gs_best_rule/3,
    gs_infer_candidates/2,
    gs_default_candidates/1,
    gs_solve/3,
    gs_solve_n/4,
    gs_explain/3,
    gs_consistent_rules/3,
    gs_valid_rules/3,
    gs_n_pairs/2,
    gs_all_same_output/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for maplist and include
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% gs_n_pairs(+Pairs, -N)
% Number of Before-After pairs.
gs_n_pairs(Pairs, N) :-
    length(Pairs, N).

% gs_apply(+Rule, +Scene, -Result)
% Apply a symbolic rule term to an obj(Color,Cells) scene list.
% Same dispatch vocabulary as sceneapply.
gs_apply(recolor(Old, New), Scene, Result) :-
    maplist(gs_recolor_atom_(Old, New), Scene, Result).
gs_apply(recolor_all(New), Scene, Result) :-
    maplist(gs_set_color_(New), Scene, Result).
gs_apply(color_map(Map), Scene, Result) :-
    maplist(gs_apply_map_(Map), Scene, Result).
gs_apply(shift(DR, DC), Scene, Result) :-
    maplist(gs_shift_obj_(DR, DC), Scene, Result).
gs_apply(to_origin, Scene, Result) :-
    gs_scene_bbox_(Scene, MinR, MinC),
    DR is -MinR,
    DC is -MinC,
    maplist(gs_shift_obj_(DR, DC), Scene, Result).
gs_apply(reflect_h(Width), Scene, Result) :-
    maplist(gs_reflect_h_obj_(Width), Scene, Result).
gs_apply(reflect_v(Height), Scene, Result) :-
    maplist(gs_reflect_v_obj_(Height), Scene, Result).
gs_apply(remove_color(Color), Scene, Result) :-
    include(gs_not_color_(Color), Scene, Result).
gs_apply(keep_color(Color), Scene, Result) :-
    include(gs_is_color_(Color), Scene, Result).
gs_apply(sort_size_desc, Scene, Result) :-
    findall(NegN-O, (member(O, Scene), O = obj(_, Cells), length(Cells, N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    gs_pairs_values_(Sorted, Result).
gs_apply(sort_size_asc, Scene, Result) :-
    findall(N-O, (member(O, Scene), O = obj(_, Cells), length(Cells, N)), Keyed),
    msort(Keyed, Sorted),
    gs_pairs_values_(Sorted, Result).
gs_apply(top_n(N), Scene, Result) :-
    gs_apply(sort_size_desc, Scene, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Result, Take),
    append(Result, _, Sorted).
gs_apply(identity, Scene, Scene).

% Internal helpers for gs_apply

% gs_recolor_atom_(+Old, +New, +Obj, -Out)
gs_recolor_atom_(Old, New, obj(C, Cells), obj(Out, Cells)) :-
    (C == Old -> Out = New ; Out = C).

% gs_set_color_(+New, +Obj, -Out)
gs_set_color_(New, obj(_, Cells), obj(New, Cells)).

% gs_apply_map_(+Map, +Obj, -Out)
gs_apply_map_(Map, obj(C, Cells), obj(Out, Cells)) :-
    (member(C-T, Map) -> Out = T ; Out = C).

% gs_shift_obj_(+DR, +DC, +Obj, -Out)
gs_shift_obj_(DR, DC, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, NC), (member(r(R, C2), Cells), NR is R + DR, NC is C2 + DC), NewCells).

% gs_reflect_h_obj_(+Width, +Obj, -Out)
gs_reflect_h_obj_(Width, obj(C, Cells), obj(C, NewCells)) :-
    W1 is Width - 1,
    findall(r(R, NC), (member(r(R, C2), Cells), NC is W1 - C2), NewCells).

% gs_reflect_v_obj_(+Height, +Obj, -Out)
gs_reflect_v_obj_(Height, obj(C, Cells), obj(C, NewCells)) :-
    H1 is Height - 1,
    findall(r(NR, C2), (member(r(R, C2), Cells), NR is H1 - R), NewCells).

% gs_is_color_(+Color, +Obj)
gs_is_color_(Color, obj(C, _)) :- C == Color.

% gs_not_color_(+Color, +Obj)
gs_not_color_(Color, obj(C, _)) :- C \== Color.

% gs_scene_bbox_(+Scene, -MinR, -MinC)
gs_scene_bbox_(Scene, MinR, MinC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R, _), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_, C), Cells)), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% gs_pairs_values_(+Pairs, -Values)
gs_pairs_values_([], []).
gs_pairs_values_([_-V | Rest], [V | RestV]) :-
    gs_pairs_values_(Rest, RestV).

% gs_pair_ok_(+Rule, +Before-After)
% Succeed if applying Rule to Before produces After (order-insensitive).
gs_pair_ok_(Rule, Before-After) :-
    gs_apply(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% gs_coverage(+Rule, +Pairs, -N)
% Number of pairs that the rule correctly explains.
gs_coverage(Rule, Pairs, N) :-
    include(gs_pair_ok_(Rule), Pairs, Covered),
    length(Covered, N).

% gs_consistent(+Rule, +Pairs)
% Succeed if the rule correctly transforms every pair.
gs_consistent(Rule, Pairs) :-
    maplist(gs_pair_ok_(Rule), Pairs).

% gs_rank_rules(+Rules, +Pairs, -Ranked)
% Sort Rules by coverage descending. Ties broken by standard term order.
gs_rank_rules(Rules, Pairs, Ranked) :-
    findall(NegN-Rule,
        (member(Rule, Rules),
         gs_coverage(Rule, Pairs, N),
         NegN is -N),
        Keyed),
    msort(Keyed, Sorted),
    gs_pairs_values_(Sorted, Ranked).

% gs_best_rule(+Rules, +Pairs, -Best)
% The rule with the highest coverage. Fails if Rules is empty.
gs_best_rule(Rules, Pairs, Best) :-
    gs_rank_rules(Rules, Pairs, [Best | _]).

% gs_consistent_rules(+Rules, +Pairs, -Consistent)
% The subset of Rules that are fully consistent with every pair.
gs_consistent_rules(Rules, Pairs, Consistent) :-
    include(gs_consistent_check_(Pairs), Rules, Consistent).

% gs_consistent_check_(+Pairs, +Rule)
gs_consistent_check_(Pairs, Rule) :-
    gs_consistent(Rule, Pairs).

% gs_valid_rules(+Rules, +Pairs, -Valid)
% The subset of Rules with coverage > 0.
gs_valid_rules(Rules, Pairs, Valid) :-
    include(gs_has_coverage_(Pairs), Rules, Valid).

% gs_has_coverage_(+Pairs, +Rule)
gs_has_coverage_(Pairs, Rule) :-
    gs_coverage(Rule, Pairs, N),
    N > 0.

% gs_infer_candidates(+Pairs, -Candidates)
% Infer specific candidate rule terms from training pairs.
% Tries common patterns: recolor, recolor_all, shift, to_origin, color_map.
gs_infer_candidates(Pairs, Candidates) :-
    findall(Rule, gs_infer_one_(Pairs, Rule), All),
    list_to_set(All, Candidates).

% gs_infer_one_(+Pairs, -Rule): backtrack over plausible rule patterns
gs_infer_one_(Pairs, recolor(Old, New)) :-
    Pairs \= [],
    Pairs = [Before-After | _],
    gs_distinct_colors_(Before, CB),
    gs_distinct_colors_(After, CA),
    subtract(CB, CA, [Old]),
    subtract(CA, CB, [New]),
    length(Before, LB),
    length(After, LB).

gs_infer_one_(Pairs, recolor_all(New)) :-
    Pairs \= [],
    Pairs = [_-After | _],
    After \= [],
    gs_distinct_colors_(After, [New]).

gs_infer_one_(Pairs, color_map(Map)) :-
    Pairs \= [],
    gs_infer_color_map_(Pairs, Map),
    Map \= [].

gs_infer_one_(Pairs, shift(DR, DC)) :-
    Pairs \= [],
    Pairs = [Before-After | _],
    Before = [First | _],
    gs_topleft_(First, r(R1, C1)),
    gs_color_(First, Color),
    gs_norm_(First, Norm),
    member(Fa, After),
    gs_color_(Fa, Color),
    gs_norm_(Fa, Norm),
    gs_topleft_(Fa, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1.

gs_infer_one_(Pairs, to_origin) :-
    Pairs \= [],
    Pairs = [Before-_ | _],
    gs_scene_bbox_(Before, MinR, MinC),
    (MinR \= 0 ; MinC \= 0).

gs_infer_one_([_-After | _], remove_color(Color)) :-
    After \= [],
    member(_, After),
    gs_distinct_colors_(After, Colors),
    member(Color, Colors),
    length(After, La),
    La > 0.

% gs_infer_color_map_(+Pairs, -Map)
gs_infer_color_map_(Pairs, Map) :-
    Pairs = [Before-After | _],
    length(Before, L),
    length(After, L),
    findall(CB-CA,
        (nth1(I, Before, OB), nth1(I, After, OA),
         gs_color_(OB, CB), gs_color_(OA, CA),
         CB \== CA),
        Pairs2),
    list_to_set(Pairs2, Map).

% gs_default_candidates(-Candidates)
% A standard broad set of candidate rule terms for blind search.
gs_default_candidates([
    recolor(r, b), recolor(r, g), recolor(r, y), recolor(r, p), recolor(r, w),
    recolor(b, r), recolor(b, g), recolor(b, y), recolor(b, p), recolor(b, w),
    recolor(g, r), recolor(g, b), recolor(g, y), recolor(g, p), recolor(g, w),
    recolor(y, r), recolor(y, b), recolor(y, g),
    recolor(p, r), recolor(p, b), recolor(p, g),
    recolor_all(r), recolor_all(b), recolor_all(g),
    recolor_all(y), recolor_all(p), recolor_all(w),
    shift(1, 0), shift(-1, 0), shift(0, 1), shift(0, -1),
    shift(1, 1), shift(1, -1), shift(-1, 1), shift(-1, -1),
    to_origin,
    remove_color(r), remove_color(b), remove_color(g),
    sort_size_desc, sort_size_asc,
    top_n(1), top_n(2),
    identity
]).

% gs_solve(+Pairs, +TestInput, -Output)
% Full end-to-end solve: infer candidates, add defaults, rank, apply best.
% Fails if no rule achieves any coverage.
gs_solve(Pairs, TestInput, Output) :-
    gs_infer_candidates(Pairs, Inferred),
    gs_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    gs_best_rule(All, Pairs, Best),
    gs_apply(Best, TestInput, Output).

% gs_solve_n(+Pairs, +N, -TopRules, -Output)
% Return the top N rules (as Coverage-Rule pairs) and apply the best to TestInput.
% TestInput is not needed here; we return rules only.
gs_solve_n(Pairs, N, TopRules, BestRule) :-
    gs_infer_candidates(Pairs, Inferred),
    gs_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    findall(NegCov-Rule,
        (member(Rule, All),
         gs_coverage(Rule, Pairs, Cov),
         NegCov is -Cov),
        Keyed),
    msort(Keyed, Sorted),
    findall(Cov-Rule, (member(NegCov-Rule, Sorted), Cov is -NegCov), CovRulePairs0),
    (   length(CovRulePairs0, Len), Take is min(N, Len)
    ->  length(TopRules, Take), append(TopRules, _, CovRulePairs0)
    ;   TopRules = CovRulePairs0
    ),
    (   TopRules = [_-BestRule | _]
    ->  true
    ;   BestRule = identity
    ).

% gs_explain(+Pairs, -BestRule, -Coverage)
% Return the best rule and its coverage for the given training pairs.
gs_explain(Pairs, BestRule, Coverage) :-
    gs_infer_candidates(Pairs, Inferred),
    gs_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    gs_best_rule(All, Pairs, BestRule),
    gs_coverage(BestRule, Pairs, Coverage).

% gs_all_same_output(+Rule, +TestInputs, -Outputs)
% Apply Rule to each test input in TestInputs, returning the list of outputs.
gs_all_same_output(Rule, TestInputs, Outputs) :-
    maplist(gs_apply(Rule), TestInputs, Outputs).

% Internal utility predicates

% gs_color_(+Obj, -Color)
gs_color_(obj(C, _), C).

% gs_norm_(+Obj, -Norm)
% Translate top-left to r(0,0), msort cells.
gs_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R, _), Cells), Rs),
    findall(C, member(r(_, C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR, NC), (member(r(R, C), Cells), NR is R - MinR, NC is C - MinC), Raw),
    msort(Raw, Norm).

% gs_topleft_(+Obj, -r(MinR,MinC))
gs_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R, _), Cells), Rs),
    findall(C, member(r(_, C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% gs_distinct_colors_(+Scene, -Colors)
gs_distinct_colors_(Scene, Colors) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors).
