% scenexf.pl - Layer 184: Scene-Level Uniform Transformation of All Objects (sx_* prefix).
% Applies transformations uniformly to every object in a list of obj(Color, Cells) terms.
% Single-object counterparts live in the objxf pack (ox_*); this pack applies them
% list-wide to produce transformed scenes.
% No cross-pack dependencies.
:- module(scenexf, [
    % scenexf_recolor/4: replace all objects of OldColor with NewColor.
    scenexf_recolor/4,
    % scenexf_recolor_all/3: set all objects to NewColor.
    scenexf_recolor_all/3,
    % scenexf_apply_color_map/3: apply OldColor-NewColor map pairs to all objects.
    scenexf_apply_color_map/3,
    % scenexf_shift/4: translate every object by (DR, DC).
    scenexf_shift/4,
    % scenexf_to_origin/2: translate scene so bounding box top-left is at r(0,0).
    scenexf_to_origin/2,
    % scenexf_reflect_h/3: reflect all objects horizontally within Width.
    scenexf_reflect_h/3,
    % scenexf_reflect_v/3: reflect all objects vertically within Height.
    scenexf_reflect_v/3,
    % scenexf_remove_color/3: remove all objects of Color.
    scenexf_remove_color/3,
    % scenexf_keep_color/3: keep only objects of Color.
    scenexf_keep_color/3,
    % scenexf_sort_size_desc/2: sort scene objects by cell count descending.
    scenexf_sort_size_desc/2,
    % scenexf_sort_size_asc/2: sort scene objects by cell count ascending.
    scenexf_sort_size_asc/2,
    % scenexf_sort_pos/2: sort scene objects by top-left position row-major.
    scenexf_sort_pos/2,
    % scenexf_top_n/3: the N largest objects by cell count.
    scenexf_top_n/3,
    % scenexf_dedup_form/2: remove duplicate forms; keep the first object of each distinct form.
    scenexf_dedup_form/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% scenexf_color_(+Obj, -Color): extract color.
scenexf_color_(obj(Color, _), Color).

% scenexf_size_(+Obj, -N): cell count.
scenexf_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scenexf_norm_(+Obj, -Sorted): normalized form (translate to origin, sort cells).
scenexf_norm_(obj(_, Cells), Sorted) :-
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

% scenexf_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
scenexf_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% scenexf_shift_obj_(+DR, +DC, +Obj, -Obj2): translate all cells of Obj by (DR, DC).
scenexf_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% scenexf_reflect_h_obj_(+Width, +Obj, -Obj2): reflect horizontally; new C = Width-1-C.
scenexf_reflect_h_obj_(Width, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(R,NC),
        (member(r(R,C), Cells),
         NC is Width - 1 - C),
        Reflected).

% scenexf_reflect_v_obj_(+Height, +Obj, -Obj2): reflect vertically; new R = Height-1-R.
scenexf_reflect_v_obj_(Height, obj(Color, Cells), obj(Color, Reflected)) :-
    findall(r(NR,C),
        (member(r(R,C), Cells),
         NR is Height - 1 - R),
        Reflected).

% scenexf_apply_map_obj_(+Map, +Obj, -Obj2): apply OldColor-NewColor map to Obj.
scenexf_apply_map_obj_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% scenexf_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
scenexf_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% --- Exported predicates -----------------------------------------------------

% scenexf_recolor(+Scene, +OldColor, +NewColor, -Scene2): replace OldColor with NewColor.
scenexf_recolor(Scene, OldColor, NewColor, Scene2) :-
    maplist(scenexf_recolor_atom_(OldColor, NewColor), Scene, Scene2).

% scenexf_recolor_atom_(+Old, +New, +Obj, -Obj2): atom-level recolor.
scenexf_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
scenexf_recolor_atom_(_, _, Obj, Obj).

% scenexf_recolor_all(+Scene, +NewColor, -Scene2): set all objects to NewColor.
scenexf_recolor_all(Scene, NewColor, Scene2) :-
    maplist(scenexf_set_color_(NewColor), Scene, Scene2).

% scenexf_set_color_(+NewColor, +Obj, -Obj2): set color of Obj to NewColor.
scenexf_set_color_(NewColor, obj(_, Cells), obj(NewColor, Cells)).

% scenexf_apply_color_map(+Scene, +Map, -Scene2): apply OldColor-NewColor pairs.
scenexf_apply_color_map(Scene, Map, Scene2) :-
    maplist(scenexf_apply_map_obj_(Map), Scene, Scene2).

% scenexf_shift(+Scene, +DR, +DC, -Scene2): translate all objects by (DR, DC).
scenexf_shift(Scene, DR, DC, Scene2) :-
    maplist(scenexf_shift_obj_(DR, DC), Scene, Scene2).

% scenexf_to_origin(+Scene, -Scene2): translate so scene bbox top-left is at r(0,0).
scenexf_to_origin([], []) :- !.
scenexf_to_origin(Scene, Scene2) :-
    scenexf_scene_bbox_(Scene, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(scenexf_shift_obj_(DR, DC), Scene, Scene2).

% scenexf_reflect_h(+Scene, +Width, -Scene2): reflect all objects horizontally.
scenexf_reflect_h(Scene, Width, Scene2) :-
    maplist(scenexf_reflect_h_obj_(Width), Scene, Scene2).

% scenexf_reflect_v(+Scene, +Height, -Scene2): reflect all objects vertically.
scenexf_reflect_v(Scene, Height, Scene2) :-
    maplist(scenexf_reflect_v_obj_(Height), Scene, Scene2).

% scenexf_remove_color(+Scene, +Color, -Scene2): remove objects of Color.
scenexf_remove_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), scenexf_color_(O, C), C \== Color), Scene2).

% scenexf_keep_color(+Scene, +Color, -Scene2): keep only objects of Color.
scenexf_keep_color(Scene, Color, Scene2) :-
    findall(O, (member(O, Scene), scenexf_color_(O, Color)), Scene2).

% scenexf_sort_size_desc(+Scene, -Sorted): sort by cell count descending.
scenexf_sort_size_desc(Scene, Sorted) :-
    findall(NegN-O, (member(O, Scene), scenexf_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scenexf_sort_size_asc(+Scene, -Sorted): sort by cell count ascending.
scenexf_sort_size_asc(Scene, Sorted) :-
    findall(N-O, (member(O, Scene), scenexf_size_(O, N)), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scenexf_sort_pos(+Scene, -Sorted): sort by top-left position row-major ascending.
scenexf_sort_pos(Scene, Sorted) :-
    findall(r(R,C)-O, (member(O, Scene), scenexf_topleft_(O, r(R,C))), Keyed),
    msort(Keyed, SortedKeyed),
    findall(O, member(_-O, SortedKeyed), Sorted).

% scenexf_top_n(+Scene, +N, -TopN): the N largest objects by cell count.
scenexf_top_n(Scene, N, TopN) :-
    scenexf_sort_size_desc(Scene, Sorted),
    length(Prefix, N),
    append(Prefix, _, Sorted),
    !,
    TopN = Prefix.
scenexf_top_n(Scene, _, Scene).

% scenexf_dedup_form(+Scene, -Deduped): keep first object of each distinct normalized form.
scenexf_dedup_form(Scene, Deduped) :-
    scenexf_dedup_form_acc_(Scene, [], Deduped).

% scenexf_dedup_form_acc_(+Remaining, +SeenForms, -Deduped): accumulator.
scenexf_dedup_form_acc_([], _, []).
scenexf_dedup_form_acc_([H|T], Seen, [H|Rest]) :-
    scenexf_norm_(H, Norm),
    \+ memberchk(Norm, Seen),
    !,
    scenexf_dedup_form_acc_(T, [Norm|Seen], Rest).
scenexf_dedup_form_acc_([_|T], Seen, Rest) :-
    scenexf_dedup_form_acc_(T, Seen, Rest).
