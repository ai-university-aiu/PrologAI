% sceneapply.pl - Layer 186: Scene-Level Rule Term Evaluation Engine (sa_* prefix).
% Applies symbolic rule terms to obj(Color, Cells) scene lists.
% A rule term is one of: recolor(Old,New), recolor_all(New), color_map(Map),
% shift(DR,DC), to_origin, reflect_h(Width), reflect_v(Height),
% remove_color(Color), keep_color(Color), sorting_size_desc, sorting_size_asc,
% sorting_pos, top_n(N), dedup_form.
% Companion to ruleinfer (ri_*) which infers rule terms from Before-After pairs.
% No cross-pack dependencies.
:- module(scene_apply, [
    % scene_apply_apply/3: apply a rule term to a scene.
    scene_apply_apply/3,
    % scene_apply_apply_seq/3: apply a sequence of rule terms in order.
    scene_apply_apply_seq/3,
    % scene_apply_verify/3: succeed if rule transforms Before to After (up to order).
    scene_apply_verify/3,
    % scene_apply_verify_seq/3: succeed if rule sequence transforms Before to After.
    scene_apply_verify_seq/3,
    % scene_apply_verify_all/2: succeed if rule works on all Before-After pairs.
    scene_apply_verify_all/2,
    % scene_apply_verify_seq_all/2: succeed if rule sequence works on all pairs.
    scene_apply_verify_seq_all/2,
    % scene_apply_rule_type/2: classify rule as color|spatial|filter|order|dedup.
    scene_apply_rule_type/2,
    % scene_apply_is_color_rule/1: succeed if rule is a color transformation.
    scene_apply_is_color_rule/1,
    % scene_apply_is_spatial_rule/1: succeed if rule is a spatial transformation.
    scene_apply_is_spatial_rule/1,
    % scene_apply_is_filter_rule/1: succeed if rule can change the object count.
    scene_apply_is_filter_rule/1,
    % scene_apply_colors_affected/2: list of color atoms mentioned in rule.
    scene_apply_colors_affected/2,
    % scene_apply_compose/3: make a two-step sequence from two rules.
    scene_apply_compose/3,
    % scene_apply_seq_len/2: number of steps in a rule sequence.
    scene_apply_seq_len/2,
    % scene_apply_rule_invertible/1: succeed if rule has a trivially constructible inverse.
    scene_apply_rule_invertible/1
]).

% Load list and apply utilities.
:- use_module(library(lists), [member/2, nth0/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- Private helpers ---------------------------------------------------------

% scene_apply_color_(+Obj, -Color): extract color.
scene_apply_color_(obj(Color, _), Color).

% scene_apply_size_(+Obj, -N): cell count.
scene_apply_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scene_apply_norm_(+Obj, -Norm): normalized form (translate to origin, sort cells).
scene_apply_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
    sort(Raw, Norm).

% scene_apply_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
scene_apply_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% scene_apply_recolor_atom_(+Old, +New, +Obj, -Obj2): recolor obj if color matches Old.
scene_apply_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
scene_apply_recolor_atom_(_, _, Obj, Obj).

% scene_apply_set_color_(+New, +Obj, -Obj2): set color to New.
scene_apply_set_color_(New, obj(_, Cells), obj(New, Cells)).

% scene_apply_apply_map_(+Map, +Obj, -Obj2): apply Old-New color map to one object.
scene_apply_apply_map_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% scene_apply_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells.
scene_apply_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% scene_apply_reflect_h_obj_(+Width, +Obj, -Obj2): flip horizontally.
scene_apply_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% scene_apply_reflect_v_obj_(+Height, +Obj, -Obj2): flip vertically.
scene_apply_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% scene_apply_is_color_(+Color, +Obj): obj has given color (for include/3).
scene_apply_is_color_(Color, obj(C, _)) :- C == Color.

% scene_apply_not_color_(+Color, +Obj): obj does not have given color (for include/3).
scene_apply_not_color_(Color, obj(C, _)) :- C \== Color.

% scene_apply_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): scene bounding box.
scene_apply_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% scene_apply_dedup_form_acc_(+Remaining, +Seen, -Deduped): accumulator for dedup_form.
scene_apply_dedup_form_acc_([], _, []).
scene_apply_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    scene_apply_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    scene_apply_dedup_form_acc_(T, [Norm|Seen], Rest).
scene_apply_dedup_form_acc_([_|T], Seen, Rest) :-
    scene_apply_dedup_form_acc_(T, Seen, Rest).

% --- Exported predicates -----------------------------------------------------

% scene_apply_apply(+Rule, +Scene, -Scene2): apply a rule term to the scene.
scene_apply_apply(recolor(Old, New), Scene, Scene2) :-
    maplist(scene_apply_recolor_atom_(Old, New), Scene, Scene2).
scene_apply_apply(recolor_all(New), Scene, Scene2) :-
    maplist(scene_apply_set_color_(New), Scene, Scene2).
scene_apply_apply(color_map(Map), Scene, Scene2) :-
    maplist(scene_apply_apply_map_(Map), Scene, Scene2).
scene_apply_apply(shift(DR, DC), Scene, Scene2) :-
    maplist(scene_apply_shift_obj_(DR, DC), Scene, Scene2).
scene_apply_apply(to_origin, [], []) :- !.
scene_apply_apply(to_origin, Scene, Scene2) :-
    scene_apply_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR, DC is -MinC,
    maplist(scene_apply_shift_obj_(DR, DC), Scene, Scene2).
scene_apply_apply(reflect_h(Width), Scene, Scene2) :-
    maplist(scene_apply_reflect_h_obj_(Width), Scene, Scene2).
scene_apply_apply(reflect_v(Height), Scene, Scene2) :-
    maplist(scene_apply_reflect_v_obj_(Height), Scene, Scene2).
scene_apply_apply(remove_color(Color), Scene, Scene2) :-
    include(scene_apply_not_color_(Color), Scene, Scene2).
scene_apply_apply(keep_color(Color), Scene, Scene2) :-
    include(scene_apply_is_color_(Color), Scene, Scene2).
scene_apply_apply(sorting_size_desc, Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), scene_apply_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
scene_apply_apply(sorting_size_asc, Scene, Sorted) :-
    findall(N-O, (member(O, Scene), scene_apply_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
scene_apply_apply(sorting_pos, Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), scene_apply_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
scene_apply_apply(top_n(N), Scene, TopN) :-
    scene_apply_apply(sorting_size_desc, Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
scene_apply_apply(top_n(_), Scene, Scene).
scene_apply_apply(dedup_form, Scene, Deduped) :-
    scene_apply_dedup_form_acc_(Scene, [], Deduped).

% scene_apply_apply_seq(+Rules, +Scene, -Scene2): apply a sequence of rules in order.
scene_apply_apply_seq([], Scene, Scene).
scene_apply_apply_seq([Rule|Rules], Scene, Scene2) :-
    scene_apply_apply(Rule, Scene, Mid),
    scene_apply_apply_seq(Rules, Mid, Scene2).

% scene_apply_verify(+Rule, +Before, +After): rule transforms Before to After (order-insensitive).
scene_apply_verify(Rule, Before, After) :-
    scene_apply_apply(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% scene_apply_verify_seq(+Rules, +Before, +After): rule sequence transforms Before to After.
scene_apply_verify_seq(Rules, Before, After) :-
    scene_apply_apply_seq(Rules, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% scene_apply_verify_all(+Rule, +Pairs): rule works on all Before-After pairs.
scene_apply_verify_all(Rule, Pairs) :-
    forall(member(Before-After, Pairs),
           scene_apply_verify(Rule, Before, After)).

% scene_apply_verify_seq_all(+Rules, +Pairs): rule sequence works on all pairs.
scene_apply_verify_seq_all(Rules, Pairs) :-
    forall(member(Before-After, Pairs),
           scene_apply_verify_seq(Rules, Before, After)).

% scene_apply_rule_type(+Rule, -Type): classify rule.
scene_apply_rule_type(recolor(_,_), color).
scene_apply_rule_type(recolor_all(_), color).
scene_apply_rule_type(color_map(_), color).
scene_apply_rule_type(shift(_,_), spatial).
scene_apply_rule_type(to_origin, spatial).
scene_apply_rule_type(reflect_h(_), spatial).
scene_apply_rule_type(reflect_v(_), spatial).
scene_apply_rule_type(remove_color(_), filter).
scene_apply_rule_type(keep_color(_), filter).
scene_apply_rule_type(sorting_size_desc, order).
scene_apply_rule_type(sorting_size_asc, order).
scene_apply_rule_type(sorting_pos, order).
scene_apply_rule_type(top_n(_), filter).
scene_apply_rule_type(dedup_form, dedup).

% scene_apply_is_color_rule(+Rule): true if rule type is color.
scene_apply_is_color_rule(Rule) :- scene_apply_rule_type(Rule, color).

% scene_apply_is_spatial_rule(+Rule): true if rule type is spatial.
scene_apply_is_spatial_rule(Rule) :- scene_apply_rule_type(Rule, spatial).

% scene_apply_is_filter_rule(+Rule): true if rule type is filter.
scene_apply_is_filter_rule(Rule) :- scene_apply_rule_type(Rule, filter).

% scene_apply_colors_affected(+Rule, -Colors): color atoms referenced in the rule.
scene_apply_colors_affected(recolor(Old, New), [Old, New]).
scene_apply_colors_affected(recolor_all(New), [New]).
scene_apply_colors_affected(color_map(Map), Colors) :-
    findall(C, (member(C-_, Map) ; member(_-C, Map)), Cs),
    sort(Cs, Colors).
scene_apply_colors_affected(remove_color(Color), [Color]).
scene_apply_colors_affected(keep_color(Color), [Color]).
scene_apply_colors_affected(shift(_,_), []).
scene_apply_colors_affected(to_origin, []).
scene_apply_colors_affected(reflect_h(_), []).
scene_apply_colors_affected(reflect_v(_), []).
scene_apply_colors_affected(sorting_size_desc, []).
scene_apply_colors_affected(sorting_size_asc, []).
scene_apply_colors_affected(sorting_pos, []).
scene_apply_colors_affected(top_n(_), []).
scene_apply_colors_affected(dedup_form, []).

% scene_apply_compose(+Rule1, +Rule2, -Seq): make a two-step sequence.
scene_apply_compose(Rule1, Rule2, [Rule1, Rule2]).

% scene_apply_seq_len(+Seq, -N): number of steps in a rule sequence.
scene_apply_seq_len(Seq, N) :- length(Seq, N).

% scene_apply_rule_invertible(+Rule): succeed if rule has a trivially constructible inverse.
% Invertible rules: recolor, shift (can negate), reflect_h/v (self-inverse).
scene_apply_rule_invertible(recolor(_, _)).
scene_apply_rule_invertible(shift(_, _)).
scene_apply_rule_invertible(reflect_h(_)).
scene_apply_rule_invertible(reflect_v(_)).
