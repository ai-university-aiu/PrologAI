% transformgen: systematic generation of scene transformation rule candidates (tg_*, Layer 192)
:- module(transformgen, [
    transformgen_scene_colors/2,
    transformgen_recolor_candidates/2,
    transformgen_recolor_all_candidates/2,
    transformgen_remove_candidates/2,
    transformgen_keep_candidates/2,
    transformgen_shift_candidates/3,
    transformgen_reflect_candidates/3,
    transformgen_top_candidates/3,
    transformgen_from_scenes/3,
    transformgen_from_pairs/2,
    transformgen_filter_consistent/3,
    transformgen_n_candidates/2,
    transformgen_all_scene_candidates/3,
    transformgen_color_map_candidate/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for include and maplist
:- use_module(library(apply), [include/3, maplist/3]).

% transformgen_scene_colors(+Scene, -Colors)
% All distinct color atoms appearing in a scene list.
transformgen_scene_colors(Scene, Colors) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors).

% transformgen_recolor_candidates(+Scene, -Candidates)
% All recolor(Old,New) rules where Old and New are distinct colors in Scene.
transformgen_recolor_candidates(Scene, Candidates) :-
    transformgen_scene_colors(Scene, Colors),
    findall(recolor(Old, New),
        (member(Old, Colors),
         member(New, Colors),
         Old \== New),
        Candidates).

% transformgen_recolor_all_candidates(+Scene, -Candidates)
% All recolor_all(New) rules for each color in Scene.
transformgen_recolor_all_candidates(Scene, Candidates) :-
    transformgen_scene_colors(Scene, Colors),
    findall(recolor_all(C), member(C, Colors), Candidates).

% transformgen_remove_candidates(+Scene, -Candidates)
% All remove_color(C) rules for each color in Scene.
transformgen_remove_candidates(Scene, Candidates) :-
    transformgen_scene_colors(Scene, Colors),
    findall(remove_color(C), member(C, Colors), Candidates).

% transformgen_keep_candidates(+Scene, -Candidates)
% All keep_color(C) rules for each color in Scene.
transformgen_keep_candidates(Scene, Candidates) :-
    transformgen_scene_colors(Scene, Colors),
    findall(keep_color(C), member(C, Colors), Candidates).

% transformgen_shift_candidates(+MaxDR, +MaxDC, -Candidates)
% All shift(DR,DC) rules with |DR| =< MaxDR and |DC| =< MaxDC, excluding (0,0).
transformgen_shift_candidates(MaxDR, MaxDC, Candidates) :-
    NegDR is -MaxDR,
    NegDC is -MaxDC,
    findall(shift(DR, DC),
        (between(NegDR, MaxDR, DR),
         between(NegDC, MaxDC, DC),
         \+ (DR =:= 0, DC =:= 0)),
        Candidates).

% transformgen_reflect_candidates(+GridH, +GridW, -Candidates)
% reflect_h and reflect_v for given grid dimensions.
transformgen_reflect_candidates(GridH, GridW, [reflect_h(GridW), reflect_v(GridH)]).

% transformgen_top_candidates(+MaxN, +Scene, -Candidates)
% All top_n(K) rules for K in 1..min(MaxN, SceneSize).
transformgen_top_candidates(MaxN, Scene, Candidates) :-
    length(Scene, Len),
    Limit is min(MaxN, Len),
    (   Limit > 0
    ->  findall(top_n(K), between(1, Limit, K), Candidates)
    ;   Candidates = []
    ).

% transformgen_color_map_candidate(+Before, +After, -Rule)
% Derive a color_map rule from a single Before-After scene pair.
% Matches objects positionally and collects changed color pairs.
% Succeeds only if at least one color changes.
transformgen_color_map_candidate(Before, After, color_map(Map)) :-
    length(Before, L),
    length(After, L),
    findall(CB-CA,
        (nth1(I, Before, obj(CB, _)),
         nth1(I, After, obj(CA, _)),
         CB \== CA),
        Pairs),
    Pairs \= [],
    list_to_set(Pairs, Map).

% transformgen_from_scenes(+Before, +After, -Candidates)
% Generate rule candidates specific to a single Before-After scene pair.
% Includes recolor, recolor_all, remove/keep, color_map, shift, and sorting rules.
transformgen_from_scenes(Before, After, Candidates) :-
    transformgen_recolor_candidates(Before, Recolors),
    transformgen_recolor_all_candidates(After, RecolorAlls),
    transformgen_remove_candidates(Before, Removes),
    transformgen_keep_candidates(After, Keeps),
    (   transformgen_color_map_candidate(Before, After, MapRule)
    ->  MapRules = [MapRule]
    ;   MapRules = []
    ),
    transformgen_shift_candidates(3, 3, Shifts),
    Sorting = [sort_size_desc, sort_size_asc, to_origin, identity],
    append([Recolors, RecolorAlls, Removes, Keeps, MapRules, Shifts, Sorting], Combined),
    list_to_set(Combined, Candidates).

% transformgen_from_pairs(+Pairs, -Candidates)
% Generate rule candidates from a list of Before-After training pairs.
% Unions candidates from each pair.
transformgen_from_pairs([], [identity]).
transformgen_from_pairs(Pairs, Candidates) :-
    Pairs = [Before-After | _],
    transformgen_from_scenes(Before, After, SceneCands),
    findall(Rule,
        (member(B-A, Pairs),
         transformgen_from_scenes(B, A, Cands),
         member(Rule, Cands)),
        AllRaw),
    list_to_set([identity | AllRaw], AllCands),
    % Also include top_n candidates based on first Before scene size
    length(Before, Len),
    Limit is min(3, Len),
    (   Limit > 0
    ->  findall(top_n(K), between(1, Limit, K), TopCands)
    ;   TopCands = []
    ),
    append(AllCands, SceneCands, Combined0),
    append(Combined0, TopCands, Combined1),
    list_to_set(Combined1, Candidates).

% transformgen_filter_consistent(+Rules, +Pairs, -Consistent)
% Filter Rules to those consistent with every Before-After pair.
transformgen_filter_consistent(Rules, Pairs, Consistent) :-
    include(transformgen_rule_consistent_(Pairs), Rules, Consistent).

% transformgen_rule_consistent_(+Pairs, +Rule)
% Check that Rule correctly explains every pair in Pairs.
transformgen_rule_consistent_(Pairs, Rule) :-
    maplist(transformgen_pair_ok_(Rule), Pairs).

% transformgen_pair_ok_(+Rule, +Before-After)
% Succeed if Rule applied to Before gives After (order-insensitive).
transformgen_pair_ok_(Rule, Before-After) :-
    transformgen_apply_(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% transformgen_apply_(+Rule, +Scene, -Result): internal application engine
transformgen_apply_(recolor(Old, New), Scene, Result) :-
    maplist(transformgen_recolor_atom_(Old, New), Scene, Result).
transformgen_apply_(recolor_all(New), Scene, Result) :-
    maplist(transformgen_set_color_(New), Scene, Result).
transformgen_apply_(color_map(Map), Scene, Result) :-
    maplist(transformgen_apply_map_(Map), Scene, Result).
transformgen_apply_(shift(DR, DC), Scene, Result) :-
    maplist(transformgen_shift_obj_(DR, DC), Scene, Result).
transformgen_apply_(to_origin, Scene, Result) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R, _), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_, C), Cells)), Cs),
    min_list(Rs, MinR), min_list(Cs, MinC),
    DR is -MinR, DC is -MinC,
    maplist(transformgen_shift_obj_(DR, DC), Scene, Result).
transformgen_apply_(remove_color(Color), Scene, Result) :-
    include(transformgen_not_color_(Color), Scene, Result).
transformgen_apply_(keep_color(Color), Scene, Result) :-
    include(transformgen_is_color_(Color), Scene, Result).
transformgen_apply_(sort_size_desc, Scene, Result) :-
    findall(NegN-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    transformgen_values_(Sorted, Result).
transformgen_apply_(sort_size_asc, Scene, Result) :-
    findall(N-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, Sorted),
    transformgen_values_(Sorted, Result).
transformgen_apply_(top_n(N), Scene, Result) :-
    transformgen_apply_(sort_size_desc, Scene, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Result, Take),
    append(Result, _, Sorted).
transformgen_apply_(reflect_h(Width), Scene, Result) :-
    W1 is Width - 1,
    maplist(transformgen_reflect_h_(W1), Scene, Result).
transformgen_apply_(reflect_v(Height), Scene, Result) :-
    H1 is Height - 1,
    maplist(transformgen_reflect_v_(H1), Scene, Result).
transformgen_apply_(identity, Scene, Scene).

% Internal helpers for transformgen_apply_
transformgen_recolor_atom_(Old, New, obj(C, Cells), obj(Out, Cells)) :-
    (C == Old -> Out = New ; Out = C).
transformgen_set_color_(New, obj(_, Cells), obj(New, Cells)).
transformgen_apply_map_(Map, obj(C, Cells), obj(Out, Cells)) :-
    (member(C-T, Map) -> Out = T ; Out = C).
transformgen_shift_obj_(DR, DC, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, NC), (member(r(R, C2), Cells), NR is R+DR, NC is C2+DC), NewCells).
transformgen_is_color_(Color, obj(C, _)) :- C == Color.
transformgen_not_color_(Color, obj(C, _)) :- C \== Color.
transformgen_reflect_h_(W1, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(R, NC), (member(r(R, C2), Cells), NC is W1 - C2), NewCells).
transformgen_reflect_v_(H1, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, C2), (member(r(R, C2), Cells), NR is H1 - R), NewCells).
transformgen_values_([], []).
transformgen_values_([_-V | Rest], [V | RestV]) :- transformgen_values_(Rest, RestV).

% transformgen_n_candidates(+Candidates, -N)
% Count candidates in a list.
transformgen_n_candidates(Candidates, N) :-
    length(Candidates, N).

% transformgen_all_scene_candidates(+Scene, +MaxShift, -Candidates)
% Generate all rule candidates from a single scene with given shift bound.
transformgen_all_scene_candidates(Scene, MaxShift, Candidates) :-
    transformgen_recolor_candidates(Scene, Recolors),
    transformgen_recolor_all_candidates(Scene, RecolorAlls),
    transformgen_remove_candidates(Scene, Removes),
    transformgen_keep_candidates(Scene, Keeps),
    transformgen_shift_candidates(MaxShift, MaxShift, Shifts),
    length(Scene, Len),
    (   Len > 0
    ->  findall(top_n(K), between(1, Len, K), Tops)
    ;   Tops = []
    ),
    Extras = [to_origin, sort_size_desc, sort_size_asc, identity],
    append([Recolors, RecolorAlls, Removes, Keeps, Shifts, Tops, Extras], Combined),
    list_to_set(Combined, Candidates).
