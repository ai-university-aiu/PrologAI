% scenexf.pl - Layer 184: Scene-Level Uniform Transformation of All Objects (sx_* prefix).
% Applies transformations uniformly to every object in a list of obj(Color, Cells) terms.
% Single-object counterparts live in the objxf pack (ox_*); this pack applies them
% list-wide to produce transformed scenes.
% No cross-pack dependencies.
:- module(scene_transform, [
    % scene_transform_recolor/4: replace all objects of OldColor with NewColor.
    scene_transform_recolor/4,
    % scene_transform_recolor_all/3: set all objects to NewColor.
    scene_transform_recolor_all/3,
    % scene_transform_apply_color_map/3: apply OldColor-NewColor map pairs to all objects.
    scene_transform_apply_color_map/3,
    % scene_transform_shift/4: translate every object by (DR, DC).
    scene_transform_shift/4,
    % scene_transform_to_origin/2: translate scene so bounding box top-left is at r(0,0).
    scene_transform_to_origin/2,
    % scene_transform_reflect_h/3: reflect all objects horizontally within Width.
    scene_transform_reflect_h/3,
    % scene_transform_reflect_v/3: reflect all objects vertically within Height.
    scene_transform_reflect_v/3,
    % scene_transform_remove_color/3: remove all objects of Color.
    scene_transform_remove_color/3,
    % scene_transform_keep_color/3: keep only objects of Color.
    scene_transform_keep_color/3,
    % scene_transform_sort_size_desc/2: sort scene objects by cell count descending.
    scene_transform_sort_size_desc/2,
    % scene_transform_sort_size_asc/2: sort scene objects by cell count ascending.
    scene_transform_sort_size_asc/2,
    % scene_transform_sort_pos/2: sort scene objects by top-left position row-major.
    scene_transform_sort_pos/2,
    % scene_transform_top_n/3: the N largest objects by cell count.
    scene_transform_top_n/3,
    % scene_transform_dedup_form/2: remove duplicate forms; keep the first object of each distinct form.
    scene_transform_dedup_form/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% scene_transform_color_(+Obj, -Color): extract color.
scene_transform_color_(obj(Color, _), Color).

% scene_transform_size_(+Obj, -N): cell count.
scene_transform_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scene_transform_norm_(+Obj, -Sorted): normalized form (translate to origin, sort cells).
scene_transform_norm_(obj(_, Cells), Sorted) :-
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

% scene_transform_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
scene_transform_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% scene_transform_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells of Obj by (DR, DC).
scene_transform_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% scene_transform_reflect_h_obj_(+Width, +Obj, -Obj2): reflect horizontally; new C = Width-1-C.
scene_transform_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% scene_transform_reflect_v_obj_(+Height, +Obj, -Obj2): reflect vertically; new R = Height-1-R.
scene_transform_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% scene_transform_apply_map_obj_(+Map, +Obj, -Obj2): apply OldColor-NewColor map to Obj.
scene_transform_apply_map_obj_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% scene_transform_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
scene_transform_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% --- Exported predicates -----------------------------------------------------

% scene_transform_recolor(+Scene, +OldColor, +NewColor, -Scene2): replace OldColor with NewColor.
scene_transform_recolor(Scene, OldColor, NewColor, Scene2) :-
    maplist(scene_transform_recolor_atom_(OldColor, NewColor), Scene, Scene2).

% scene_transform_recolor_atom_(+Old, +New, +Obj, -Obj2): atom-level recolor.
scene_transform_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
scene_transform_recolor_atom_(_, _, Obj, Obj).

% scene_transform_recolor_all(+Scene, +NewColor, -Scene2): set all objects to NewColor.
scene_transform_recolor_all(Scene, NewColor, Scene2) :-
    maplist(scene_transform_set_color_(NewColor), Scene, Scene2).

% scene_transform_set_color_(+NewColor, +Obj, -Obj2): set color of Obj to NewColor.
scene_transform_set_color_(NewColor, obj(_, Cells), obj(NewColor, Cells)).

% scene_transform_apply_color_map(+Scene, +Map, -Scene2): apply OldColor-NewColor pairs.
scene_transform_apply_color_map(Scene, Map, Scene2) :-
    maplist(scene_transform_apply_map_obj_(Map), Scene, Scene2).

% scene_transform_shift(+Scene, +DR, +DC, -Scene2): translate all objects by (DR, DC).
scene_transform_shift(Scene, DR, DC, Scene2) :-
    maplist(scene_transform_shift_obj_(DR, DC), Scene, Scene2).

% scene_transform_to_origin(+Scene, -Scene2): translate so scene bbox top-left is at r(0,0).
scene_transform_to_origin([], []) :- !.
scene_transform_to_origin(Scene, Scene2) :-
    scene_transform_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(scene_transform_shift_obj_(DR, DC), Scene, Scene2).

% scene_transform_reflect_h(+Scene, +Width, -Scene2): reflect all objects horizontally.
scene_transform_reflect_h(Scene, Width, Scene2) :-
    maplist(scene_transform_reflect_h_obj_(Width), Scene, Scene2).

% scene_transform_reflect_v(+Scene, +Height, -Scene2): reflect all objects vertically.
scene_transform_reflect_v(Scene, Height, Scene2) :-
    maplist(scene_transform_reflect_v_obj_(Height), Scene, Scene2).

% scene_transform_remove_color(+Scene, +Color, -Scene2): remove objects of Color.
scene_transform_remove_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), scene_transform_color_(O, C), C \== Color), Scene2).

% scene_transform_keep_color(+Scene, +Color, -Scene2): keep only objects of Color.
scene_transform_keep_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), scene_transform_color_(O, Color)), Scene2).

% scene_transform_sort_size_desc(+Scene, -Sorted): sort by cell count descending.
scene_transform_sort_size_desc(Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), scene_transform_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scene_transform_sort_size_asc(+Scene, -Sorted): sort by cell count ascending.
scene_transform_sort_size_asc(Scene, Sorted) :-
    findall(N-O, (member(O, Scene), scene_transform_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scene_transform_sort_pos(+Scene, -Sorted): sort by top-left position row-major ascending.
scene_transform_sort_pos(Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), scene_transform_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scene_transform_top_n(+Scene, +N, -TopN): the N largest objects by cell count.
scene_transform_top_n(Scene, N, TopN) :-
    scene_transform_sort_size_desc(Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
scene_transform_top_n(Scene, _, Scene).

% scene_transform_dedup_form(+Scene, -Deduped): keep first object of each distinct normalized form.
scene_transform_dedup_form(Scene, Deduped) :-
    scene_transform_dedup_form_acc_(Scene, [], Deduped).

% scene_transform_dedup_form_acc_(+Remaining, +SeenForms, -Deduped): accumulator.
scene_transform_dedup_form_acc_([], _, []).
scene_transform_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    scene_transform_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    scene_transform_dedup_form_acc_(T, [Norm|Seen], Rest).
scene_transform_dedup_form_acc_([_|T], Seen, Rest) :-
    scene_transform_dedup_form_acc_(T, Seen, Rest).
