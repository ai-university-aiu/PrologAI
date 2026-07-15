% transformgen: systematic generation of scene transformation rule candidates (tg_*, Layer 192)
:- module(transform_generate, [
    transform_generate_scene_colors/2,
    transform_generate_recolor_candidates/2,
    transform_generate_recolor_all_candidates/2,
    transform_generate_remove_candidates/2,
    transform_generate_keep_candidates/2,
    transform_generate_shift_candidates/3,
    transform_generate_reflect_candidates/3,
    transform_generate_top_candidates/3,
    transform_generate_from_scenes/3,
    transform_generate_from_pairs/2,
    transform_generate_filter_consistent/3,
    transform_generate_n_candidates/2,
    transform_generate_all_scene_candidates/3,
    transform_generate_color_map_candidate/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for include and maplist
:- use_module(library(apply), [include/3, maplist/3]).

% transform_generate_scene_colors(+Scene, -Colors)
% All distinct color atoms appearing in a scene list.
transform_generate_scene_colors(Scene, Colors) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors).

% transform_generate_recolor_candidates(+Scene, -Candidates)
% All recolor(Old,New) rules where Old and New are distinct colors in Scene.
transform_generate_recolor_candidates(Scene, Candidates) :-
    transform_generate_scene_colors(Scene, Colors),
    findall(recolor(Old, New),
        (member(Old, Colors),
         member(New, Colors),
         Old \== New),
        Candidates).

% transform_generate_recolor_all_candidates(+Scene, -Candidates)
% All recolor_all(New) rules for each color in Scene.
transform_generate_recolor_all_candidates(Scene, Candidates) :-
    transform_generate_scene_colors(Scene, Colors),
    findall(recolor_all(C), member(C, Colors), Candidates).

% transform_generate_remove_candidates(+Scene, -Candidates)
% All remove_color(C) rules for each color in Scene.
transform_generate_remove_candidates(Scene, Candidates) :-
    transform_generate_scene_colors(Scene, Colors),
    findall(remove_color(C), member(C, Colors), Candidates).

% transform_generate_keep_candidates(+Scene, -Candidates)
% All keep_color(C) rules for each color in Scene.
transform_generate_keep_candidates(Scene, Candidates) :-
    transform_generate_scene_colors(Scene, Colors),
    findall(keep_color(C), member(C, Colors), Candidates).

% transform_generate_shift_candidates(+MaxDR, +MaxDC, -Candidates)
% All shift(DR,DC) rules with |DR| =< MaxDR and |DC| =< MaxDC, excluding (0,0).
transform_generate_shift_candidates(MaxDR, MaxDC, Candidates) :-
    NegDR is -MaxDR,
    NegDC is -MaxDC,
    findall(shift(DR, DC),
        (between(NegDR, MaxDR, DR),
         between(NegDC, MaxDC, DC),
         \+ (DR =:= 0, DC =:= 0)),
        Candidates).

% transform_generate_reflect_candidates(+GridH, +GridW, -Candidates)
% reflect_h and reflect_v for given grid dimensions.
transform_generate_reflect_candidates(GridH, GridW, [reflect_h(GridW), reflect_v(GridH)]).

% transform_generate_top_candidates(+MaxN, +Scene, -Candidates)
% All top_n(K) rules for K in 1..min(MaxN, SceneSize).
transform_generate_top_candidates(MaxN, Scene, Candidates) :-
    length(Scene, Len),
    Limit is min(MaxN, Len),
    (   Limit > 0
    ->  findall(top_n(K), between(1, Limit, K), Candidates)
    ;   Candidates = []
    ).

% transform_generate_color_map_candidate(+Before, +After, -Rule)
% Derive a color_map rule from a single Before-After scene pair.
% Matches objects positionally and collects changed color pairs.
% Succeeds only if at least one color changes.
transform_generate_color_map_candidate(Before, After, color_map(Map)) :-
    length(Before, L),
    length(After, L),
    findall(CB-CA,
        (nth1(I, Before, obj(CB, _)),
         nth1(I, After, obj(CA, _)),
         CB \== CA),
        Pairs),
    Pairs \= [],
    list_to_set(Pairs, Map).

% transform_generate_from_scenes(+Before, +After, -Candidates)
% Generate rule candidates specific to a single Before-After scene pair.
% Includes recolor, recolor_all, remove/keep, color_map, shift, and sorting rules.
transform_generate_from_scenes(Before, After, Candidates) :-
    transform_generate_recolor_candidates(Before, Recolors),
    transform_generate_recolor_all_candidates(After, RecolorAlls),
    transform_generate_remove_candidates(Before, Removes),
    transform_generate_keep_candidates(After, Keeps),
    (   transform_generate_color_map_candidate(Before, After, MapRule)
    ->  MapRules = [MapRule]
    ;   MapRules = []
    ),
    transform_generate_shift_candidates(3, 3, Shifts),
    Sorting = [sorting_size_desc, sorting_size_asc, to_origin, identity],
    append([Recolors, RecolorAlls, Removes, Keeps, MapRules, Shifts, Sorting], Combined),
    list_to_set(Combined, Candidates).

% transform_generate_from_pairs(+Pairs, -Candidates)
% Generate rule candidates from a list of Before-After training pairs.
% Unions candidates from each pair.
transform_generate_from_pairs([], [identity]).
transform_generate_from_pairs(Pairs, Candidates) :-
    Pairs = [Before-After | _],
    transform_generate_from_scenes(Before, After, SceneCands),
    findall(Rule,
        (member(B-A, Pairs),
         transform_generate_from_scenes(B, A, Cands),
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

% transform_generate_filter_consistent(+Rules, +Pairs, -Consistent)
% Filter Rules to those consistent with every Before-After pair.
transform_generate_filter_consistent(Rules, Pairs, Consistent) :-
    include(transform_generate_rule_consistent_(Pairs), Rules, Consistent).

% transform_generate_rule_consistent_(+Pairs, +Rule)
% Check that Rule correctly explains every pair in Pairs.
transform_generate_rule_consistent_(Pairs, Rule) :-
    maplist(transform_generate_pair_ok_(Rule), Pairs).

% transform_generate_pair_ok_(+Rule, +Before-After)
% Succeed if Rule applied to Before gives After (order-insensitive).
transform_generate_pair_ok_(Rule, Before-After) :-
    transform_generate_apply_(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% transform_generate_apply_(+Rule, +Scene, -Result): internal application engine
transform_generate_apply_(recolor(Old, New), Scene, Result) :-
    maplist(transform_generate_recolor_atom_(Old, New), Scene, Result).
transform_generate_apply_(recolor_all(New), Scene, Result) :-
    maplist(transform_generate_set_color_(New), Scene, Result).
transform_generate_apply_(color_map(Map), Scene, Result) :-
    maplist(transform_generate_apply_map_(Map), Scene, Result).
transform_generate_apply_(shift(DR, DC), Scene, Result) :-
    maplist(transform_generate_shift_obj_(DR, DC), Scene, Result).
transform_generate_apply_(to_origin, Scene, Result) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R, _), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_, C), Cells)), Cs),
    min_list(Rs, MinR), min_list(Cs, MinC),
    DR is -MinR, DC is -MinC,
    maplist(transform_generate_shift_obj_(DR, DC), Scene, Result).
transform_generate_apply_(remove_color(Color), Scene, Result) :-
    include(transform_generate_not_color_(Color), Scene, Result).
transform_generate_apply_(keep_color(Color), Scene, Result) :-
    include(transform_generate_is_color_(Color), Scene, Result).
transform_generate_apply_(sorting_size_desc, Scene, Result) :-
    findall(NegN-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    transform_generate_values_(Sorted, Result).
transform_generate_apply_(sorting_size_asc, Scene, Result) :-
    findall(N-O, (member(O, Scene), O=obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, Sorted),
    transform_generate_values_(Sorted, Result).
transform_generate_apply_(top_n(N), Scene, Result) :-
    transform_generate_apply_(sorting_size_desc, Scene, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Result, Take),
    append(Result, _, Sorted).
transform_generate_apply_(reflect_h(Width), Scene, Result) :-
    W1 is Width - 1,
    maplist(transform_generate_reflect_h_(W1), Scene, Result).
transform_generate_apply_(reflect_v(Height), Scene, Result) :-
    H1 is Height - 1,
    maplist(transform_generate_reflect_v_(H1), Scene, Result).
transform_generate_apply_(identity, Scene, Scene).

% Internal helpers for transform_generate_apply_
transform_generate_recolor_atom_(Old, New, obj(C, Cells), obj(Out, Cells)) :-
    (C == Old -> Out = New ; Out = C).
transform_generate_set_color_(New, obj(_, Cells), obj(New, Cells)).
transform_generate_apply_map_(Map, obj(C, Cells), obj(Out, Cells)) :-
    (member(C-T, Map) -> Out = T ; Out = C).
transform_generate_shift_obj_(DR, DC, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, NC), (member(r(R, C2), Cells), NR is R+DR, NC is C2+DC), NewCells).
transform_generate_is_color_(Color, obj(C, _)) :- C == Color.
transform_generate_not_color_(Color, obj(C, _)) :- C \== Color.
transform_generate_reflect_h_(W1, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(R, NC), (member(r(R, C2), Cells), NC is W1 - C2), NewCells).
transform_generate_reflect_v_(H1, obj(C, Cells), obj(C, NewCells)) :-
    findall(r(NR, C2), (member(r(R, C2), Cells), NR is H1 - R), NewCells).
transform_generate_values_([], []).
transform_generate_values_([_-V | Rest], [V | RestV]) :- transform_generate_values_(Rest, RestV).

% transform_generate_n_candidates(+Candidates, -N)
% Count candidates in a list.
transform_generate_n_candidates(Candidates, N) :-
    length(Candidates, N).

% transform_generate_all_scene_candidates(+Scene, +MaxShift, -Candidates)
% Generate all rule candidates from a single scene with given shift bound.
transform_generate_all_scene_candidates(Scene, MaxShift, Candidates) :-
    transform_generate_recolor_candidates(Scene, Recolors),
    transform_generate_recolor_all_candidates(Scene, RecolorAlls),
    transform_generate_remove_candidates(Scene, Removes),
    transform_generate_keep_candidates(Scene, Keeps),
    transform_generate_shift_candidates(MaxShift, MaxShift, Shifts),
    length(Scene, Len),
    (   Len > 0
    ->  findall(top_n(K), between(1, Len, K), Tops)
    ;   Tops = []
    ),
    Extras = [to_origin, sorting_size_desc, sorting_size_asc, identity],
    append([Recolors, RecolorAlls, Removes, Keeps, Shifts, Tops, Extras], Combined),
    list_to_set(Combined, Candidates).
