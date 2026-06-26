% sceneapply.pl - Layer 186: Scene-Level Rule Term Evaluation Engine (sa_* prefix).
% Applies symbolic rule terms to obj(Color, Cells) scene lists.
% A rule term is one of: recolor(Old,New), recolor_all(New), color_map(Map),
% shift(DR,DC), to_origin, reflect_h(Width), reflect_v(Height),
% remove_color(Color), keep_color(Color), sort_size_desc, sort_size_asc,
% sort_pos, top_n(N), dedup_form.
% Companion to ruleinfer (ri_*) which infers rule terms from Before-After pairs.
% No cross-pack dependencies.
:- module(sceneapply, [
    % sa_apply/3: apply a rule term to a scene.
    sa_apply/3,
    % sa_apply_seq/3: apply a sequence of rule terms in order.
    sa_apply_seq/3,
    % sa_verify/3: succeed if rule transforms Before to After (up to order).
    sa_verify/3,
    % sa_verify_seq/3: succeed if rule sequence transforms Before to After.
    sa_verify_seq/3,
    % sa_verify_all/2: succeed if rule works on all Before-After pairs.
    sa_verify_all/2,
    % sa_verify_seq_all/2: succeed if rule sequence works on all pairs.
    sa_verify_seq_all/2,
    % sa_rule_type/2: classify rule as color|spatial|filter|order|dedup.
    sa_rule_type/2,
    % sa_is_color_rule/1: succeed if rule is a color transformation.
    sa_is_color_rule/1,
    % sa_is_spatial_rule/1: succeed if rule is a spatial transformation.
    sa_is_spatial_rule/1,
    % sa_is_filter_rule/1: succeed if rule can change the object count.
    sa_is_filter_rule/1,
    % sa_colors_affected/2: list of color atoms mentioned in rule.
    sa_colors_affected/2,
    % sa_compose/3: make a two-step sequence from two rules.
    sa_compose/3,
    % sa_seq_len/2: number of steps in a rule sequence.
    sa_seq_len/2,
    % sa_rule_invertible/1: succeed if rule has a trivially constructible inverse.
    sa_rule_invertible/1
]).

% Load list and apply utilities.
:- use_module(library(lists), [member/2, nth0/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- Private helpers ---------------------------------------------------------

% sa_color_(+Obj, -Color): extract color.
sa_color_(obj(Color, _), Color).

% sa_size_(+Obj, -N): cell count.
sa_size_(obj(_, Cells), N) :-
    length(Cells, N).

% sa_norm_(+Obj, -Norm): normalized form (translate to origin, sort cells).
sa_norm_(obj(_, Cells), Norm) :-
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

% sa_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
sa_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% sa_recolor_atom_(+Old, +New, +Obj, -Obj2): recolor obj if color matches Old.
sa_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
sa_recolor_atom_(_, _, Obj, Obj).

% sa_set_color_(+New, +Obj, -Obj2): set color to New.
sa_set_color_(New, obj(_, Cells), obj(New, Cells)).

% sa_apply_map_(+Map, +Obj, -Obj2): apply Old-New color map to one object.
sa_apply_map_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% sa_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells.
sa_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% sa_reflect_h_obj_(+Width, +Obj, -Obj2): flip horizontally.
sa_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% sa_reflect_v_obj_(+Height, +Obj, -Obj2): flip vertically.
sa_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% sa_is_color_(+Color, +Obj): obj has given color (for include/3).
sa_is_color_(Color, obj(C, _)) :- C == Color.

% sa_not_color_(+Color, +Obj): obj does not have given color (for include/3).
sa_not_color_(Color, obj(C, _)) :- C \== Color.

% sa_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): scene bounding box.
sa_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% sa_dedup_form_acc_(+Remaining, +Seen, -Deduped): accumulator for dedup_form.
sa_dedup_form_acc_([], _, []).
sa_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    sa_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    sa_dedup_form_acc_(T, [Norm|Seen], Rest).
sa_dedup_form_acc_([_|T], Seen, Rest) :-
    sa_dedup_form_acc_(T, Seen, Rest).

% --- Exported predicates -----------------------------------------------------

% sa_apply(+Rule, +Scene, -Scene2): apply a rule term to the scene.
sa_apply(recolor(Old, New), Scene, Scene2) :-
    maplist(sa_recolor_atom_(Old, New), Scene, Scene2).
sa_apply(recolor_all(New), Scene, Scene2) :-
    maplist(sa_set_color_(New), Scene, Scene2).
sa_apply(color_map(Map), Scene, Scene2) :-
    maplist(sa_apply_map_(Map), Scene, Scene2).
sa_apply(shift(DR, DC), Scene, Scene2) :-
    maplist(sa_shift_obj_(DR, DC), Scene, Scene2).
sa_apply(to_origin, [], []) :- !.
sa_apply(to_origin, Scene, Scene2) :-
    sa_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR, DC is -MinC,
    maplist(sa_shift_obj_(DR, DC), Scene, Scene2).
sa_apply(reflect_h(Width), Scene, Scene2) :-
    maplist(sa_reflect_h_obj_(Width), Scene, Scene2).
sa_apply(reflect_v(Height), Scene, Scene2) :-
    maplist(sa_reflect_v_obj_(Height), Scene, Scene2).
sa_apply(remove_color(Color), Scene, Scene2) :-
    include(sa_not_color_(Color), Scene, Scene2).
sa_apply(keep_color(Color), Scene, Scene2) :-
    include(sa_is_color_(Color), Scene, Scene2).
sa_apply(sort_size_desc, Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), sa_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sa_apply(sort_size_asc, Scene, Sorted) :-
    findall(N-O, (member(O, Scene), sa_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sa_apply(sort_pos, Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), sa_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).
sa_apply(top_n(N), Scene, TopN) :-
    sa_apply(sort_size_desc, Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
sa_apply(top_n(_), Scene, Scene).
sa_apply(dedup_form, Scene, Deduped) :-
    sa_dedup_form_acc_(Scene, [], Deduped).

% sa_apply_seq(+Rules, +Scene, -Scene2): apply a sequence of rules in order.
sa_apply_seq([], Scene, Scene).
sa_apply_seq([Rule|Rules], Scene, Scene2) :-
    sa_apply(Rule, Scene, Mid),
    sa_apply_seq(Rules, Mid, Scene2).

% sa_verify(+Rule, +Before, +After): rule transforms Before to After (order-insensitive).
sa_verify(Rule, Before, After) :-
    sa_apply(Rule, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% sa_verify_seq(+Rules, +Before, +After): rule sequence transforms Before to After.
sa_verify_seq(Rules, Before, After) :-
    sa_apply_seq(Rules, Before, Result),
    msort(Result, SR),
    msort(After, SA),
    SR == SA.

% sa_verify_all(+Rule, +Pairs): rule works on all Before-After pairs.
sa_verify_all(Rule, Pairs) :-
    forall(member(Before-After, Pairs),
           sa_verify(Rule, Before, After)).

% sa_verify_seq_all(+Rules, +Pairs): rule sequence works on all pairs.
sa_verify_seq_all(Rules, Pairs) :-
    forall(member(Before-After, Pairs),
           sa_verify_seq(Rules, Before, After)).

% sa_rule_type(+Rule, -Type): classify rule.
sa_rule_type(recolor(_,_), color).
sa_rule_type(recolor_all(_), color).
sa_rule_type(color_map(_), color).
sa_rule_type(shift(_,_), spatial).
sa_rule_type(to_origin, spatial).
sa_rule_type(reflect_h(_), spatial).
sa_rule_type(reflect_v(_), spatial).
sa_rule_type(remove_color(_), filter).
sa_rule_type(keep_color(_), filter).
sa_rule_type(sort_size_desc, order).
sa_rule_type(sort_size_asc, order).
sa_rule_type(sort_pos, order).
sa_rule_type(top_n(_), filter).
sa_rule_type(dedup_form, dedup).

% sa_is_color_rule(+Rule): true if rule type is color.
sa_is_color_rule(Rule) :- sa_rule_type(Rule, color).

% sa_is_spatial_rule(+Rule): true if rule type is spatial.
sa_is_spatial_rule(Rule) :- sa_rule_type(Rule, spatial).

% sa_is_filter_rule(+Rule): true if rule type is filter.
sa_is_filter_rule(Rule) :- sa_rule_type(Rule, filter).

% sa_colors_affected(+Rule, -Colors): color atoms referenced in the rule.
sa_colors_affected(recolor(Old, New), [Old, New]).
sa_colors_affected(recolor_all(New), [New]).
sa_colors_affected(color_map(Map), Colors) :-
    findall(C, (member(C-_, Map) ; member(_-C, Map)), Cs),
    sort(Cs, Colors).
sa_colors_affected(remove_color(Color), [Color]).
sa_colors_affected(keep_color(Color), [Color]).
sa_colors_affected(shift(_,_), []).
sa_colors_affected(to_origin, []).
sa_colors_affected(reflect_h(_), []).
sa_colors_affected(reflect_v(_), []).
sa_colors_affected(sort_size_desc, []).
sa_colors_affected(sort_size_asc, []).
sa_colors_affected(sort_pos, []).
sa_colors_affected(top_n(_), []).
sa_colors_affected(dedup_form, []).

% sa_compose(+Rule1, +Rule2, -Seq): make a two-step sequence.
sa_compose(Rule1, Rule2, [Rule1, Rule2]).

% sa_seq_len(+Seq, -N): number of steps in a rule sequence.
sa_seq_len(Seq, N) :- length(Seq, N).

% sa_rule_invertible(+Rule): succeed if rule has a trivially constructible inverse.
% Invertible rules: recolor, shift (can negate), reflect_h/v (self-inverse).
sa_rule_invertible(recolor(_, _)).
sa_rule_invertible(shift(_, _)).
sa_rule_invertible(reflect_h(_)).
sa_rule_invertible(reflect_v(_)).
