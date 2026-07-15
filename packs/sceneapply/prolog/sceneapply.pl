% sceneapply.pl - Layer 186: Scene-Level Rule Term Evaluation Engine (sa_* prefix).
% Applies symbolic rule terms to obj(Color, Cells) scene lists.
% A rule term is one of: recolor(Old,New), recolor_all(New), color_map(Map),
% shift(DR,DC), to_origin, reflect_h(Width), reflect_v(Height),
% remove_color(Color), keep_color(Color), sort_size_desc, sort_size_asc,
% sort_pos, top_n(N), dedup_form.
% Companion to ruleinfer (ri_*) which infers rule terms from Before-After pairs.
% No cross-pack dependencies.
:- module(sceneapply, [
    % sceneapply_apply/3: apply a rule term to a scene.
    sceneapply_apply/3,
    % sceneapply_apply_seq/3: apply a sequence of rule terms in order.
    sceneapply_apply_seq/3,
    % sceneapply_verify/3: succeed if rule transforms Before to After (up to order).
    sceneapply_verify/3,
    % sceneapply_verify_seq/3: succeed if rule sequence transforms Before to After.
    sceneapply_verify_seq/3,
    % sceneapply_verify_all/2: succeed if rule works on all Before-After pairs.
    sceneapply_verify_all/2,
    % sceneapply_verify_seq_all/2: succeed if rule sequence works on all pairs.
    sceneapply_verify_seq_all/2,
    % sceneapply_rule_type/2: classify rule as color|spatial|filter|order|dedup.
    sceneapply_rule_type/2,
    % sceneapply_is_color_rule/1: succeed if rule is a color transformation.
    sceneapply_is_color_rule/1,
    % sceneapply_is_spatial_rule/1: succeed if rule is a spatial transformation.
    sceneapply_is_spatial_rule/1,
    % sceneapply_is_filter_rule/1: succeed if rule can change the object count.
    sceneapply_is_filter_rule/1,
    % sceneapply_colors_affected/2: list of color atoms mentioned in rule.
    sceneapply_colors_affected/2,
    % sceneapply_compose/3: make a two-step sequence from two rules.
    sceneapply_compose/3,
    % sceneapply_seq_len/2: number of steps in a rule sequence.
    sceneapply_seq_len/2,
    % sceneapply_rule_invertible/1: succeed if rule has a trivially constructible inverse.
    sceneapply_rule_invertible/1
]).

% Load list and apply utilities.
:- use_module(library(lists), [member/2, nth0/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- Private helpers ---------------------------------------------------------

% sceneapply_color_(+Obj, -Color): extract color.
sceneapply_color_(obj(Color, _), Color).

% sceneapply_size_(+Obj, -N): cell count.
sceneapply_size_(obj(_, Cells), N) :-
    length(Cells, N).

% sceneapply_norm_(+Obj, -Norm): normalized form (translate to origin, sort cells).
sceneapply_norm_(obj(_, Cells), Norm) :-
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

% sceneapply_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
sceneapply_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% sceneapply_recolor_atom_(+Old, +New, +Obj, -Obj2): recolor obj if color matches Old.
sceneapply_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
sceneapply_recolor_atom_(_, _, Obj, Obj).

% sceneapply_set_color_(+New, +Obj, -Obj2): set color to New.
sceneapply_set_color_(New, obj(_, Cells), obj(New, Cells)).

% sceneapply_apply_map_(+Map, +Obj, -Obj2): apply Old-New color map to one object.
sceneapply_apply_map_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% sceneapply_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells.
sceneapply_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% sceneapply_reflect_h_obj_(+Width, +Obj, -Obj2): flip horizontally.
sceneapply_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% sceneapply_reflect_v_obj_(+Height, +Obj, -Obj2): flip vertically.
sceneapply_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% sceneapply_is_color_(+Color, +Obj): obj has given color (for include/3).
sceneapply_is_color_(Color, obj(C, _)) :- C == Color.

% sceneapply_not_color_(+Color, +Obj): obj does not have given color (for include/3).
sceneapply_not_color_(Color, obj(C, _)) :- C \== Color.

% sceneapply_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): scene bounding box.
sceneapply_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% sceneapply_dedup_form_acc_(+Remaining, +Seen, -Deduped): accumulator for dedup_form.
sceneapply_dedup_form_acc_([], _, []).
sceneapply_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    sceneapply_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    sceneapply_dedup_form_acc_(T, [Norm|Seen], Rest).
sceneapply_dedup_form_acc_([_|T], Seen, Rest) :-
    sceneapply_dedup_form_acc_(T, Seen, Rest).

% --- Exported predicates -----------------------------------------------------

% sceneapply_apply(+Rule, +Scene, -Scene2): apply a rule term to the scene.
sceneapply_apply(recolor(Old, New), Scene, Scene2) :-
    maplist(sceneapply_recolor_atom_(Old, New), Scene, Scene2).
sceneapply_apply(recolor_all(New), Scene, Scene2) :-
    maplist(sceneapply_set_color_(New), Scene, Scene2).
sceneapply_apply(color_map(Map), Scene, Scene2) :-
    maplist(sceneapply_apply_map_(Map), Scene, Scene2).
sceneapply_apply(shift(DR, DC), Scene, Scene2) :-
    maplist(sceneapply_shift_obj_(DR, DC), Scene, Scene2).
sceneapply_apply(to_origin, [], []) :- !.
sceneapply_apply(to_origin, Scene, Scene2) :-
    sceneapply_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR, DC is -MinC,
    maplist(sceneapply_shift_obj_(DR, DC), Scene, Scene2).
sceneapply_apply(reflect_h(Width), Scene, Scene2) :-
    maplist(sceneapply_reflect_h_obj_(Width), Scene, Scene2).
sceneapply_apply(reflect_v(Height), Scene, Scene2) :-
    maplist(sceneapply_reflect_v_obj_(Height), Scene, Scene2).
sceneapply_apply(remove_color(Color), Scene, Scene2) :-
    include(sceneapply_not_color_(Color), Scene, Scene2).
sceneapply_apply(keep_color(Color), Scene, Scene2) :-
    include(sceneapply_is_color_(Color), Scene, Scene2).
sceneapply_apply(sort_size_desc, Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), sceneapply_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sceneapply_apply(sort_size_asc, Scene, Sorted) :-
    findall(N-O, (member(O, Scene), sceneapply_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sceneapply_apply(sort_pos, Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), sceneapply_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sceneapply_apply(top_n(N), Scene, TopN) :-
    sceneapply_apply(sort_size_desc, Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
sceneapply_apply(top_n(_), Scene, Scene).
sceneapply_apply(dedup_form, Scene, Deduped) :-
    sceneapply_dedup_form_acc_(Scene, [], Deduped).

% sceneapply_apply_seq(+Rules, +Scene, -Scene2): apply a sequence of rules in order.
sceneapply_apply_seq([], Scene, Scene).
sceneapply_apply_seq([Rule|Rules], Scene, Scene2) :-
    sceneapply_apply(Rule, Scene, Mid),
    sceneapply_apply_seq(Rules, Mid, Scene2).

% sceneapply_verify(+Rule, +Before, +After): rule transforms Before to After (order-insensitive).
sceneapply_verify(Rule, Before, After) :-
    sceneapply_apply(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% sceneapply_verify_seq(+Rules, +Before, +After): rule sequence transforms Before to After.
sceneapply_verify_seq(Rules, Before, After) :-
    sceneapply_apply_seq(Rules, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% sceneapply_verify_all(+Rule, +Pairs): rule works on all Before-After pairs.
sceneapply_verify_all(Rule, Pairs) :-
    forall(member(Before-After, Pairs),
           sceneapply_verify(Rule, Before, After)).

% sceneapply_verify_seq_all(+Rules, +Pairs): rule sequence works on all pairs.
sceneapply_verify_seq_all(Rules, Pairs) :-
    forall(member(Before-After, Pairs),
           sceneapply_verify_seq(Rules, Before, After)).

% sceneapply_rule_type(+Rule, -Type): classify rule.
sceneapply_rule_type(recolor(_,_), color).
sceneapply_rule_type(recolor_all(_), color).
sceneapply_rule_type(color_map(_), color).
sceneapply_rule_type(shift(_,_), spatial).
sceneapply_rule_type(to_origin, spatial).
sceneapply_rule_type(reflect_h(_), spatial).
sceneapply_rule_type(reflect_v(_), spatial).
sceneapply_rule_type(remove_color(_), filter).
sceneapply_rule_type(keep_color(_), filter).
sceneapply_rule_type(sort_size_desc, order).
sceneapply_rule_type(sort_size_asc, order).
sceneapply_rule_type(sort_pos, order).
sceneapply_rule_type(top_n(_), filter).
sceneapply_rule_type(dedup_form, dedup).

% sceneapply_is_color_rule(+Rule): true if rule type is color.
sceneapply_is_color_rule(Rule) :- sceneapply_rule_type(Rule, color).

% sceneapply_is_spatial_rule(+Rule): true if rule type is spatial.
sceneapply_is_spatial_rule(Rule) :- sceneapply_rule_type(Rule, spatial).

% sceneapply_is_filter_rule(+Rule): true if rule type is filter.
sceneapply_is_filter_rule(Rule) :- sceneapply_rule_type(Rule, filter).

% sceneapply_colors_affected(+Rule, -Colors): color atoms referenced in the rule.
sceneapply_colors_affected(recolor(Old, New), [Old, New]).
sceneapply_colors_affected(recolor_all(New), [New]).
sceneapply_colors_affected(color_map(Map), Colors) :-
    findall(C, (member(C-_, Map) ; member(_-C, Map)), Cs),
    sort(Cs, Colors).
sceneapply_colors_affected(remove_color(Color), [Color]).
sceneapply_colors_affected(keep_color(Color), [Color]).
sceneapply_colors_affected(shift(_,_), []).
sceneapply_colors_affected(to_origin, []).
sceneapply_colors_affected(reflect_h(_), []).
sceneapply_colors_affected(reflect_v(_), []).
sceneapply_colors_affected(sort_size_desc, []).
sceneapply_colors_affected(sort_size_asc, []).
sceneapply_colors_affected(sort_pos, []).
sceneapply_colors_affected(top_n(_), []).
sceneapply_colors_affected(dedup_form, []).

% sceneapply_compose(+Rule1, +Rule2, -Seq): make a two-step sequence.
sceneapply_compose(Rule1, Rule2, [Rule1, Rule2]).

% sceneapply_seq_len(+Seq, -N): number of steps in a rule sequence.
sceneapply_seq_len(Seq, N) :- length(Seq, N).

% sceneapply_rule_invertible(+Rule): succeed if rule has a trivially constructible inverse.
% Invertible rules: recolor, shift (can negate), reflect_h/v (self-inverse).
sceneapply_rule_invertible(recolor(_, _)).
sceneapply_rule_invertible(shift(_, _)).
sceneapply_rule_invertible(reflect_h(_)).
sceneapply_rule_invertible(reflect_v(_)).
