% scenexf.pl - Layer 184: Scene-Level Uniform Transformation of All Objects (sx_* prefix).
% Applies transformations uniformly to every object in a list of obj(Color, Cells) terms.
% Single-object counterparts live in the objxf pack (ox_*); this pack applies them
% list-wide to produce transformed scenes.
% No cross-pack dependencies.
:- module(scenexf, [
    % sx_recolor/4: replace all objects of OldColor with NewColor.
    sx_recolor/4,
    % sx_recolor_all/3: set all objects to NewColor.
    sx_recolor_all/3,
    % sx_apply_color_map/3: apply OldColor-NewColor map pairs to all objects.
    sx_apply_color_map/3,
    % sx_shift/4: translate every object by (DR, DC).
    sx_shift/4,
    % sx_to_origin/2: translate scene so bounding box top-left is at r(0,0).
    sx_to_origin/2,
    % sx_reflect_h/3: reflect all objects horizontally within Width.
    sx_reflect_h/3,
    % sx_reflect_v/3: reflect all objects vertically within Height.
    sx_reflect_v/3,
    % sx_remove_color/3: remove all objects of Color.
    sx_remove_color/3,
    % sx_keep_color/3: keep only objects of Color.
    sx_keep_color/3,
    % sx_sort_size_desc/2: sort scene objects by cell count descending.
    sx_sort_size_desc/2,
    % sx_sort_size_asc/2: sort scene objects by cell count ascending.
    sx_sort_size_asc/2,
    % sx_sort_pos/2: sort scene objects by top-left position row-major.
    sx_sort_pos/2,
    % sx_top_n/3: the N largest objects by cell count.
    sx_top_n/3,
    % sx_dedup_form/2: remove duplicate forms; keep the first object of each distinct form.
    sx_dedup_form/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% sx_color_(+Obj, -Color): extract color.
sx_color_(obj(Color, _), Color).

% sx_size_(+Obj, -N): cell count.
sx_size_(obj(_, Cells), N) :-
    length(Cells, N).

% sx_norm_(+Obj, -Sorted): normalized form (translate to origin, sort cells).
sx_norm_(obj(_, Cells), Sorted) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
    sort(Raw, Sorted).

% sx_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
sx_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% sx_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells of Obj by (DR, DC).
sx_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% sx_reflect_h_obj_(+Width, +Obj, -Obj2): reflect horizontally; new C = Width-1-C.
sx_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% sx_reflect_v_obj_(+Height, +Obj, -Obj2): reflect vertically; new R = Height-1-R.
sx_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% sx_apply_map_obj_(+Map, +Obj, -Obj2): apply OldColor-NewColor map to Obj.
sx_apply_map_obj_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% sx_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
sx_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% --- Exported predicates -----------------------------------------------------

% sx_recolor(+Scene, +OldColor, +NewColor, -Scene2): replace OldColor with NewColor.
sx_recolor(Scene, OldColor, NewColor, Scene2) :-
    maplist(sx_recolor_atom_(OldColor, NewColor), Scene, Scene2).

% sx_recolor_atom_(+Old, +New, +Obj, -Obj2): atom-level recolor.
sx_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
sx_recolor_atom_(_, _, Obj, Obj).

% sx_recolor_all(+Scene, +NewColor, -Scene2): set all objects to NewColor.
sx_recolor_all(Scene, NewColor, Scene2) :-
    maplist(sx_set_color_(NewColor), Scene, Scene2).

% sx_set_color_(+NewColor, +Obj, -Obj2): set color of Obj to NewColor.
sx_set_color_(NewColor, obj(_, Cells), obj(NewColor, Cells)).

% sx_apply_color_map(+Scene, +Map, -Scene2): apply OldColor-NewColor pairs.
sx_apply_color_map(Scene, Map, Scene2) :-
    maplist(sx_apply_map_obj_(Map), Scene, Scene2).

% sx_shift(+Scene, +DR, +DC, -Scene2): translate all objects by (DR, DC).
sx_shift(Scene, DR, DC, Scene2) :-
    maplist(sx_shift_obj_(DR, DC), Scene, Scene2).

% sx_to_origin(+Scene, -Scene2): translate so scene bbox top-left is at r(0,0).
sx_to_origin([], []) :- !.
sx_to_origin(Scene, Scene2) :-
    sx_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(sx_shift_obj_(DR, DC), Scene, Scene2).

% sx_reflect_h(+Scene, +Width, -Scene2): reflect all objects horizontally.
sx_reflect_h(Scene, Width, Scene2) :-
    maplist(sx_reflect_h_obj_(Width), Scene, Scene2).

% sx_reflect_v(+Scene, +Height, -Scene2): reflect all objects vertically.
sx_reflect_v(Scene, Height, Scene2) :-
    maplist(sx_reflect_v_obj_(Height), Scene, Scene2).

% sx_remove_color(+Scene, +Color, -Scene2): remove objects of Color.
sx_remove_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), sx_color_(O, C), C \== Color), Scene2).

% sx_keep_color(+Scene, +Color, -Scene2): keep only objects of Color.
sx_keep_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), sx_color_(O, Color)), Scene2).

% sx_sort_size_desc(+Scene, -Sorted): sort by cell count descending.
sx_sort_size_desc(Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), sx_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% sx_sort_size_asc(+Scene, -Sorted): sort by cell count ascending.
sx_sort_size_asc(Scene, Sorted) :-
    findall(N-O, (member(O, Scene), sx_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% sx_sort_pos(+Scene, -Sorted): sort by top-left position row-major ascending.
sx_sort_pos(Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), sx_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% sx_top_n(+Scene, +N, -TopN): the N largest objects by cell count.
sx_top_n(Scene, N, TopN) :-
    sx_sort_size_desc(Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
sx_top_n(Scene, _, Scene).

% sx_dedup_form(+Scene, -Deduped): keep first object of each distinct normalized form.
sx_dedup_form(Scene, Deduped) :-
    sx_dedup_form_acc_(Scene, [], Deduped).

% sx_dedup_form_acc_(+Remaining, +SeenForms, -Deduped): accumulator.
sx_dedup_form_acc_([], _, []).
sx_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    sx_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    sx_dedup_form_acc_(T, [Norm|Seen], Rest).
sx_dedup_form_acc_([_|T], Seen, Rest) :-
    sx_dedup_form_acc_(T, Seen, Rest).
