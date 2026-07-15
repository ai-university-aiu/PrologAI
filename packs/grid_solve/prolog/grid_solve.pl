% gridsolve: end-to-end scene puzzle solver (gs_*, Layer 191)
:- module(grid_solve, [
    grid_solve_apply/3,
    grid_solve_coverage/3,
    grid_solve_consistent/2,
    grid_solve_rank_rules/3,
    grid_solve_best_rule/3,
    grid_solve_infer_candidates/2,
    grid_solve_default_candidates/1,
    grid_solve_solve/3,
    grid_solve_solve_n/4,
    grid_solve_explain/3,
    grid_solve_consistent_rules/3,
    grid_solve_valid_rules/3,
    grid_solve_n_pairs/2,
    grid_solve_all_same_output/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for maplist and include
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% grid_solve_n_pairs(+Pairs, -N)
% Number of Before-After pairs.
grid_solve_n_pairs(Pairs, N) :-
    length(Pairs, N).

% grid_solve_apply(+Rule, +Scene, -Result)
% Apply a symbolic rule term to an obj(Color,Cells) scene list.
% Same dispatch vocabulary as sceneapply.
grid_solve_apply(recolor(Old, New), Scene, Result) :-
    maplist(grid_solve_recolor_atom_(Old, New), Scene, Result).
grid_solve_apply(recolor_all(New), Scene, Result) :-
    maplist(grid_solve_set_color_(New), Scene, Result).
grid_solve_apply(color_map(Map), Scene, Result) :-
    maplist(grid_solve_apply_map_(Map), Scene, Result).
grid_solve_apply(shift(DR, DC), Scene, Result) :-
    maplist(grid_solve_shift_obj_(DR, DC), Scene, Result).
grid_solve_apply(to_origin, Scene, Result) :-
    grid_solve_scene_bbox_(Scene, MinR, MinC),
    DR is -MinR,
    DC is -MinC,
    maplist(grid_solve_shift_obj_(DR, DC), Scene, Result).
grid_solve_apply(reflect_h(Width), Scene, Result) :-
    maplist(grid_solve_reflect_h_obj_(Width), Scene, Result).
grid_solve_apply(reflect_v(Height), Scene, Result) :-
    maplist(grid_solve_reflect_v_obj_(Height), Scene, Result).
grid_solve_apply(remove_color(Color), Scene, Result) :-
    include(grid_solve_not_color_(Color), Scene, Result).
grid_solve_apply(keep_color(Color), Scene, Result) :-
    include(grid_solve_is_color_(Color), Scene, Result).
grid_solve_apply(sorting_size_desc, Scene, Result) :-
    findall(NegN-O, (member(O, Scene), O = obj(_, Cells), length(Cells, N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    grid_solve_pairs_values_(Sorted, Result).
grid_solve_apply(sorting_size_asc, Scene, Result) :-
    findall(N-O, (member(O, Scene), O = obj(_, Cells), length(Cells, N)), Keyed),
    msort(Keyed, Sorted),
    grid_solve_pairs_values_(Sorted, Result).
grid_solve_apply(top_n(N), Scene, Result) :-
    grid_solve_apply(sorting_size_desc, Scene, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Result, Take),
    append(Result, _, Sorted).
grid_solve_apply(identity, Scene, Scene).

% Internal helpers for grid_solve_apply

% grid_solve_recolor_atom_(+Old, +New, +Obj, -Out)
grid_solve_recolor_atom_(Old, New, obj(C, Cells), obj(Out, Cells)) :-
    (C == Old -> Out = New ; Out = C).

% grid_solve_set_color_(+New, +Obj, -Out)
grid_solve_set_color_(New, obj(_, Cells), obj(New, Cells)).

% grid_solve_apply_map_(+Map, +Obj, -Out)
grid_solve_apply_map_(Map, obj(C, Cells), obj(Out, Cells)) :-
    (member(C-T, Map) -> Out = T ; Out = C).

% grid_solve_shift_obj_(+DR, +DC, +Obj, -Out)
grid_solve_shift_obj_(DR, DC, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, NC), (member(r(R, C2), Cells), NR is R + DR, NC is C2 + DC), NewCells).

% grid_solve_reflect_h_obj_(+Width, +Obj, -Out)
grid_solve_reflect_h_obj_(Width, obj(C, Cells), obj(C, NewCells)) :-
    W1 is Width - 1,
    findall(r(R, NC), (member(r(R, C2), Cells), NC is W1 - C2), NewCells).

% grid_solve_reflect_v_obj_(+Height, +Obj, -Out)
grid_solve_reflect_v_obj_(Height, obj(C, Cells), obj(C, NewCells)) :-
    H1 is Height - 1,
    findall(r(NR, C2), (member(r(R, C2), Cells), NR is H1 - R), NewCells).

% grid_solve_is_color_(+Color, +Obj)
grid_solve_is_color_(Color, obj(C, _)) :- C == Color.

% grid_solve_not_color_(+Color, +Obj)
grid_solve_not_color_(Color, obj(C, _)) :- C \== Color.

% grid_solve_scene_bbox_(+Scene, -MinR, -MinC)
grid_solve_scene_bbox_(Scene, MinR, MinC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R, _), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_, C), Cells)), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% grid_solve_pairs_values_(+Pairs, -Values)
grid_solve_pairs_values_([], []).
grid_solve_pairs_values_([_-V | Rest], [V | RestV]) :-
    grid_solve_pairs_values_(Rest, RestV).

% grid_solve_pair_ok_(+Rule, +Before-After)
% Succeed if applying Rule to Before produces After (order-insensitive).
grid_solve_pair_ok_(Rule, Before-After) :-
    grid_solve_apply(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% grid_solve_coverage(+Rule, +Pairs, -N)
% Number of pairs that the rule correctly explains.
grid_solve_coverage(Rule, Pairs, N) :-
    include(grid_solve_pair_ok_(Rule), Pairs, Covered),
    length(Covered, N).

% grid_solve_consistent(+Rule, +Pairs)
% Succeed if the rule correctly transforms every pair.
grid_solve_consistent(Rule, Pairs) :-
    maplist(grid_solve_pair_ok_(Rule), Pairs).

% grid_solve_rank_rules(+Rules, +Pairs, -Ranked)
% Sort Rules by coverage descending. Ties broken by standard term order.
grid_solve_rank_rules(Rules, Pairs, Ranked) :-
    findall(NegN-Rule,
        (member(Rule, Rules),
         grid_solve_coverage(Rule, Pairs, N),
         NegN is -N),
        Keyed),
    msort(Keyed, Sorted),
    grid_solve_pairs_values_(Sorted, Ranked).

% grid_solve_best_rule(+Rules, +Pairs, -Best)
% The rule with the highest coverage. Fails if Rules is empty.
grid_solve_best_rule(Rules, Pairs, Best) :-
    grid_solve_rank_rules(Rules, Pairs, [Best | _]).

% grid_solve_consistent_rules(+Rules, +Pairs, -Consistent)
% The subset of Rules that are fully consistent with every pair.
grid_solve_consistent_rules(Rules, Pairs, Consistent) :-
    include(grid_solve_consistent_check_(Pairs), Rules, Consistent).

% grid_solve_consistent_check_(+Pairs, +Rule)
grid_solve_consistent_check_(Pairs, Rule) :-
    grid_solve_consistent(Rule, Pairs).

% grid_solve_valid_rules(+Rules, +Pairs, -Valid)
% The subset of Rules with coverage > 0.
grid_solve_valid_rules(Rules, Pairs, Valid) :-
    include(grid_solve_has_coverage_(Pairs), Rules, Valid).

% grid_solve_has_coverage_(+Pairs, +Rule)
grid_solve_has_coverage_(Pairs, Rule) :-
    grid_solve_coverage(Rule, Pairs, N),
    N > 0.

% grid_solve_infer_candidates(+Pairs, -Candidates)
% Infer specific candidate rule terms from training pairs.
% Tries common patterns: recolor, recolor_all, shift, to_origin, color_map.
grid_solve_infer_candidates(Pairs, Candidates) :-
    findall(Rule, grid_solve_infer_one_(Pairs, Rule), All),
    list_to_set(All, Candidates).

% grid_solve_infer_one_(+Pairs, -Rule): backtrack over plausible rule patterns
grid_solve_infer_one_(Pairs, recolor(Old, New)) :-
    Pairs \= [],
    Pairs = [Before-After | _],
    grid_solve_distinct_colors_(Before, CB),
    grid_solve_distinct_colors_(After, CA),
    subtract(CB, CA, [Old]),
    subtract(CA, CB, [New]),
    length(Before, LB),
    length(After, LB).

grid_solve_infer_one_(Pairs, recolor_all(New)) :-
    Pairs \= [],
    Pairs = [_-After | _],
    After \= [],
    grid_solve_distinct_colors_(After, [New]).

grid_solve_infer_one_(Pairs, color_map(Map)) :-
    Pairs \= [],
    grid_solve_infer_color_map_(Pairs, Map),
    Map \= [].

grid_solve_infer_one_(Pairs, shift(DR, DC)) :-
    Pairs \= [],
    Pairs = [Before-After | _],
    Before = [First | _],
    grid_solve_topleft_(First, r(R1, C1)),
    grid_solve_color_(First, Color),
    grid_solve_norm_(First, Norm),
    member(Fa, After),
    grid_solve_color_(Fa, Color),
    grid_solve_norm_(Fa, Norm),
    grid_solve_topleft_(Fa, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1.

grid_solve_infer_one_(Pairs, to_origin) :-
    Pairs \= [],
    Pairs = [Before-_ | _],
    grid_solve_scene_bbox_(Before, MinR, MinC),
    (MinR \= 0 ; MinC \= 0).

grid_solve_infer_one_([_-After | _], remove_color(Color)) :-
    After \= [],
    member(_, After),
    grid_solve_distinct_colors_(After, Colors),
    member(Color, Colors),
    length(After, La),
    La > 0.

% grid_solve_infer_color_map_(+Pairs, -Map)
grid_solve_infer_color_map_(Pairs, Map) :-
    Pairs = [Before-After | _],
    length(Before, L),
    length(After, L),
    findall(CB-CA,
        (nth1(I, Before, OB), nth1(I, After, OA),
         grid_solve_color_(OB, CB), grid_solve_color_(OA, CA),
         CB \== CA),
        Pairs2),
    list_to_set(Pairs2, Map).

% grid_solve_default_candidates(-Candidates)
% A standard broad set of candidate rule terms for blind search.
grid_solve_default_candidates([
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
    sorting_size_desc, sorting_size_asc,
    top_n(1), top_n(2),
    identity
]).

% grid_solve_solve(+Pairs, +TestInput, -Output)
% Full end-to-end solve: infer candidates, add defaults, rank, apply best.
% Fails if no rule achieves any coverage.
grid_solve_solve(Pairs, TestInput, Output) :-
    grid_solve_infer_candidates(Pairs, Inferred),
    grid_solve_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    grid_solve_best_rule(All, Pairs, Best),
    grid_solve_apply(Best, TestInput, Output).

% grid_solve_solve_n(+Pairs, +N, -TopRules, -Output)
% Return the top N rules (as Coverage-Rule pairs) and apply the best to TestInput.
% TestInput is not needed here; we return rules only.
grid_solve_solve_n(Pairs, N, TopRules, BestRule) :-
    grid_solve_infer_candidates(Pairs, Inferred),
    grid_solve_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    findall(NegCov-Rule,
        (member(Rule, All),
         grid_solve_coverage(Rule, Pairs, Cov),
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

% grid_solve_explain(+Pairs, -BestRule, -Coverage)
% Return the best rule and its coverage for the given training pairs.
grid_solve_explain(Pairs, BestRule, Coverage) :-
    grid_solve_infer_candidates(Pairs, Inferred),
    grid_solve_default_candidates(Defaults),
    append(Inferred, Defaults, AllRaw),
    list_to_set(AllRaw, All),
    grid_solve_best_rule(All, Pairs, BestRule),
    grid_solve_coverage(BestRule, Pairs, Coverage).

% grid_solve_all_same_output(+Rule, +TestInputs, -Outputs)
% Apply Rule to each test input in TestInputs, returning the list of outputs.
grid_solve_all_same_output(Rule, TestInputs, Outputs) :-
    maplist(grid_solve_apply(Rule), TestInputs, Outputs).

% Internal utility predicates

% grid_solve_color_(+Obj, -Color)
grid_solve_color_(obj(C, _), C).

% grid_solve_norm_(+Obj, -Norm)
% Translate top-left to r(0,0), msort cells.
grid_solve_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R, _), Cells), Rs),
    findall(C, member(r(_, C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR, NC), (member(r(R, C), Cells), NR is R - MinR, NC is C - MinC), Raw),
    msort(Raw, Norm).

% grid_solve_topleft_(+Obj, -r(MinR,MinC))
grid_solve_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R, _), Cells), Rs),
    findall(C, member(r(_, C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% grid_solve_distinct_colors_(+Scene, -Colors)
grid_solve_distinct_colors_(Scene, Colors) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors).
