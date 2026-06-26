% ruleinfer.pl - Layer 185: Scene-Level Transformation Rule Inference (ri_* prefix).
% Infers which scene-level transformation was applied to a Before scene to produce
% an After scene. Inference predicates examine one Before-After pair; consistency
% predicates verify a hypothesized rule across multiple pairs.
% No cross-pack dependencies. Uses library(lists) and library(apply).
:- module(ruleinfer, [
    % ri_infer_recolor/4: infer a single-color substitution from a Before-After pair.
    ri_infer_recolor/4,
    % ri_infer_recolor_all/3: infer that all objects were set to the same new color.
    ri_infer_recolor_all/3,
    % ri_infer_color_map/3: infer a full color substitution map from a Before-After pair.
    ri_infer_color_map/3,
    % ri_infer_keep_color/3: infer that only one color was kept (filter applied).
    ri_infer_keep_color/3,
    % ri_infer_remove_color/3: infer that one color was removed from the scene.
    ri_infer_remove_color/3,
    % ri_infer_shift/4: infer uniform spatial shift DR-DC from a Before-After pair.
    ri_infer_shift/4,
    % ri_infer_to_origin/2: succeed if After is Before shifted so bbox starts at r(0,0).
    ri_infer_to_origin/2,
    % ri_consistent_recolor/3: verify recolor(Old,New) is consistent with all pairs.
    ri_consistent_recolor/3,
    % ri_consistent_color_map/2: verify a color map is consistent with all pairs.
    ri_consistent_color_map/2,
    % ri_consistent_keep_color/2: verify keep_color(Color) is consistent with all pairs.
    ri_consistent_keep_color/2,
    % ri_consistent_remove_color/2: verify remove_color(Color) is consistent with all pairs.
    ri_consistent_remove_color/2,
    % ri_consistent_shift/3: verify shift(DR,DC) is consistent with all pairs.
    ri_consistent_shift/3,
    % ri_all_same_n_objs/1: all pairs preserve the object count.
    ri_all_same_n_objs/1,
    % ri_all_same_colors/1: all pairs preserve the set of distinct colors.
    ri_all_same_colors/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, nth0/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% ri_color_(+Obj, -Color): extract color atom.
ri_color_(obj(Color, _), Color).

% ri_size_(+Obj, -N): cell count.
ri_size_(obj(_, Cells), N) :-
    length(Cells, N).

% ri_norm_(+Obj, -Norm): normalized form (translate to origin, sort cells).
ri_norm_(obj(_, Cells), Norm) :-
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

% ri_topleft_(+Obj, -r(MinR,MinC)): top-left corner.
ri_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% ri_distinct_colors_(+Objs, -Colors): sorted distinct color set.
ri_distinct_colors_(Objs, Colors) :-
    findall(C, (member(O, Objs), ri_color_(O, C)), Cs),
    sort(Cs, Colors).

% ri_n_of_color_(+Objs, +Color, -N): count of objects with given color.
ri_n_of_color_(Objs, Color, N) :-
    findall(O, (member(O, Objs), ri_color_(O, Color)), Found),
    length(Found, N).

% ri_shift_obj_(+DR, +DC, +Obj, -Obj2): shift one object.
ri_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R + DR,
         NC is C + DC),
        Shifted).

% ri_scene_bbox_(+Scene, -MinR, -MinC): scene top-left for to_origin check.
ri_scene_bbox_(Scene, MinR, MinC) :-
    findall(R, (member(obj(_, Cells), Scene), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_, Cells), Scene), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% ri_apply_recolor_(+Old, +New, +Scene, -Scene2): apply recolor to scene.
ri_apply_recolor_(Old, New, Scene, Scene2) :-
    maplist(ri_recolor_atom_(Old, New), Scene, Scene2).

% ri_recolor_atom_(+Old, +New, +Obj, -Obj2): recolor one obj if color matches.
ri_recolor_atom_(Old, New, obj(C, Cells), obj(New, Cells)) :-
    C == Old,
    !.
ri_recolor_atom_(_, _, Obj, Obj).

% ri_apply_color_map_(+Map, +Obj, -Obj2): apply Old-New map to one object.
ri_apply_color_map_(Map, obj(C, Cells), obj(NewC, Cells)) :-
    (   member(C-NewC, Map) -> true ; NewC = C ).

% ri_shift_scene_(+Scene, +DR, +DC, -Scene2): shift whole scene.
ri_shift_scene_(Scene, DR, DC, Scene2) :-
    maplist(ri_shift_obj_(DR, DC), Scene, Scene2).

% ri_match_obj_(+BObj, +AObjs): find an After object same norm and color as BObj,
%   differing only in position.
ri_match_obj_(BObj, AObjs, AObj) :-
    ri_norm_(BObj, Norm),
    ri_color_(BObj, Color),
    member(AObj, AObjs),
    ri_color_(AObj, Color),
    ri_norm_(AObj, Norm).

% --- Exported predicates -----------------------------------------------------

% ri_infer_recolor(+Before, +After, -Old, -New): exactly one color changed.
% Old is the single color present in Before but not in After;
% New is the single color present in After but not in Before.
% The number of Old-colored objects in Before equals New-colored in After.
ri_infer_recolor(Before, After, Old, New) :-
    ri_distinct_colors_(Before, CB),
    ri_distinct_colors_(After, CA),
    subtract(CB, CA, [Old]),
    subtract(CA, CB, [New]),
    ri_n_of_color_(Before, Old, N),
    ri_n_of_color_(After, New, N).

% ri_infer_recolor_all(+Before, +After, -New): all After objects have same color New.
ri_infer_recolor_all(Before, After, New) :-
    Before \== [],
    After \== [],
    ri_distinct_colors_(After, [New]).

% ri_infer_color_map(+Before, +After, -Map): infer Old-New pairs for changed colors.
% Map contains one Old-New pair per color that changed.
ri_infer_color_map(Before, After, Map) :-
    length(Before, N),
    length(After, N),
    ri_infer_color_map_acc_(Before, After, Map).

% ri_infer_color_map_acc_(+Before, +After, -Map): match by norm+size+position order.
ri_infer_color_map_acc_([], [], []).
ri_infer_color_map_acc_([B|BT], [A|AT], Map) :-
    ri_color_(B, CB),
    ri_color_(A, CA),
    (   CB == CA
    ->  ri_infer_color_map_acc_(BT, AT, Map)
    ;   ri_infer_color_map_acc_(BT, AT, RestMap),
        (   member(CB-CA, RestMap)
        ->  Map = RestMap
        ;   Map = [CB-CA | RestMap]
        )
    ).

% ri_infer_keep_color(+Before, +After, -Color): After keeps only Color objects.
% All After objects appear in Before (same color and norm); only one color in After.
ri_infer_keep_color(Before, After, Color) :-
    After \== [],
    ri_distinct_colors_(After, [Color]),
    length(Before, NB),
    ri_n_of_color_(Before, Color, NA),
    NA < NB,
    ri_n_of_color_(After, Color, NA).

% ri_infer_remove_color(+Before, +After, -Color): Color objects were removed.
% Color is in Before but not in After; all other objects are unchanged.
ri_infer_remove_color(Before, After, Color) :-
    ri_distinct_colors_(Before, CB),
    ri_distinct_colors_(After, CA),
    subtract(CB, CA, [Color]).

% ri_infer_shift(+Before, +After, -DR, -DC): all objects shifted by same DR, DC.
% Uses first object to compute candidate shift; verifies all objects match.
ri_infer_shift(Before, After, DR, DC) :-
    Before = [FirstB | _],
    ri_topleft_(FirstB, r(R1, C1)),
    ri_color_(FirstB, Color),
    ri_norm_(FirstB, Norm),
    member(FirstA, After),
    ri_color_(FirstA, Color),
    ri_norm_(FirstA, Norm),
    ri_topleft_(FirstA, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1,
    ri_shift_scene_(Before, DR, DC, ShiftedBefore),
    msort(ShiftedBefore, SB),
    msort(After, SA),
    SB == SA,
    !.

% ri_infer_to_origin(+Before, +After): After == Before shifted to origin.
ri_infer_to_origin(Before, After) :-
    Before \== [],
    ri_scene_bbox_(Before, MinR, MinC),
    DR is -MinR,
    DC is -MinC,
    ri_shift_scene_(Before, DR, DC, Expected),
    msort(Expected, SE),
    msort(After, SA),
    SE == SA.

% ri_consistent_recolor(+Old, +New, +Pairs): recolor(Old,New) works on all pairs.
% Pairs is a list of Before-After terms.
ri_consistent_recolor(Old, New, Pairs) :-
    forall(member(Before-After, Pairs),
        (   ri_apply_recolor_(Old, New, Before, Expected),
            msort(Expected, SE),
            msort(After, SA),
            SE == SA
        )).

% ri_consistent_color_map(+Map, +Pairs): color map works on all pairs.
ri_consistent_color_map(Map, Pairs) :-
    forall(member(Before-After, Pairs),
        (   maplist(ri_apply_color_map_(Map), Before, Expected),
            msort(Expected, SE),
            msort(After, SA),
            SE == SA
        )).

% ri_consistent_keep_color(+Color, +Pairs): keep_color(Color) works on all pairs.
ri_consistent_keep_color(Color, Pairs) :-
    forall(member(Before-After, Pairs),
        (   findall(O, (member(O, Before), ri_color_(O, Color)), Expected),
            msort(Expected, SE),
            msort(After, SA),
            SE == SA
        )).

% ri_consistent_remove_color(+Color, +Pairs): remove_color(Color) works on all pairs.
ri_consistent_remove_color(Color, Pairs) :-
    forall(member(Before-After, Pairs),
        (   findall(O, (member(O, Before), ri_color_(O, C), C \== Color), Expected),
            msort(Expected, SE),
            msort(After, SA),
            SE == SA
        )).

% ri_consistent_shift(+DR, +DC, +Pairs): shift(DR,DC) works on all pairs.
ri_consistent_shift(DR, DC, Pairs) :-
    forall(member(Before-After, Pairs),
        (   ri_shift_scene_(Before, DR, DC, Expected),
            msort(Expected, SE),
            msort(After, SA),
            SE == SA
        )).

% ri_all_same_n_objs(+Pairs): all pairs preserve the object count.
ri_all_same_n_objs(Pairs) :-
    forall(member(Before-After, Pairs),
        (   length(Before, N),
            length(After, N)
        )).

% ri_all_same_colors(+Pairs): all pairs preserve the set of distinct colors.
ri_all_same_colors(Pairs) :-
    forall(member(Before-After, Pairs),
        (   ri_distinct_colors_(Before, Colors),
            ri_distinct_colors_(After, Colors)
        )).
