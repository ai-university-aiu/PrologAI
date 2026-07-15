% scenepair.pl - Layer 188: Holistic Before-After Scene Pair Analysis (ps_* prefix).
% Given a Before scene and an After scene (both lists of obj(Color,Cells) terms),
% computes scene-level observables about the transformation: whether object count
% changed, whether colors changed, the set of added/removed/changed objects, the
% color delta map, the spatial shift (if uniform), and several Boolean flags used
% for rule hypothesis ranking. No cross-pack dependencies.
:- module(scene_pair, [
    % scene_pair_same_n_objs/2: Before and After have the same number of objects.
    scene_pair_same_n_objs/2,
    % scene_pair_n_added/3: count of objects in After absent from Before (by form+color).
    scene_pair_n_added/3,
    % scene_pair_n_removed/3: count of objects in Before absent from After (by form+color).
    scene_pair_n_removed/3,
    % scene_pair_added_objs/3: list of objects in After with no match in Before.
    scene_pair_added_objs/3,
    % scene_pair_removed_objs/3: list of objects in Before with no match in After.
    scene_pair_removed_objs/3,
    % scene_pair_color_set_before/2: sorted list of distinct colors in Before.
    scene_pair_color_set_before/2,
    % scene_pair_color_set_after/2: sorted list of distinct colors in After.
    scene_pair_color_set_after/2,
    % scene_pair_same_color_set/2: Before and After have the same distinct-color set.
    scene_pair_same_color_set/2,
    % scene_pair_color_delta/3: list of OldColor-NewColor pairs where color changed.
    scene_pair_color_delta/3,
    % scene_pair_is_recolor/2: exactly one color was replaced by exactly one other color.
    scene_pair_is_recolor/2,
    % scene_pair_is_recolor_all/2: all objects in After have the same color.
    scene_pair_is_recolor_all/2,
    % scene_pair_is_shift/4: all objects shifted by the same (DR,DC); binds DR and DC.
    scene_pair_is_shift/4,
    % scene_pair_is_to_origin/2: After equals Before shifted so bounding box is at r(0,0).
    scene_pair_is_to_origin/2,
    % scene_pair_size_preserved/2: each object's cell count is unchanged (position-matched).
    scene_pair_size_preserved/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, append/3]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% scene_pair_color_(+Obj, -Color): extract color.
scene_pair_color_(obj(Color, _), Color).

% scene_pair_cells_(+Obj, -Cells): extract cell list.
scene_pair_cells_(obj(_, Cells), Cells).

% scene_pair_size_(+Obj, -N): cell count.
scene_pair_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scene_pair_norm_(+Obj, -Norm): normalized form — translate top-left to r(0,0), sort cells.
scene_pair_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC), (member(r(R,C), Cells), NR is R-MinR, NC is C-MinC), Raw),
    msort(Raw, Norm).

% scene_pair_match_(+Obj, +List): Obj matches some member of List by color and norm.
scene_pair_match_(Obj, List) :-
    scene_pair_color_(Obj, C),
    scene_pair_norm_(Obj, Norm),
    member(Cand, List),
    scene_pair_color_(Cand, C),
    scene_pair_norm_(Cand, Norm),
    !.

% scene_pair_distinct_colors_(+Scene, -Colors): sorted distinct color atoms.
scene_pair_distinct_colors_(Scene, Colors) :-
    findall(C, (member(O, Scene), scene_pair_color_(O, C)), Raw),
    msort(Raw, Sorted),
    scene_pair_dedup_(Sorted, Colors).

% scene_pair_dedup_(+List, -Deduped): remove consecutive duplicates from sorted list.
scene_pair_dedup_([], []).
scene_pair_dedup_([X], [X]) :- !.
scene_pair_dedup_([X,X|T], Out) :-
    !,
    scene_pair_dedup_([X|T], Out).
scene_pair_dedup_([X|T], [X|Out]) :-
    scene_pair_dedup_(T, Out).

% scene_pair_topleft_(+Obj, -r(MinR,MinC)): top-left cell of an object.
scene_pair_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% scene_pair_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
scene_pair_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(O, Scene), scene_pair_cells_(O, Cells), member(r(R,_), Cells)), Rs),
    findall(C, (member(O, Scene), scene_pair_cells_(O, Cells), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% scene_pair_shift_obj_(+DR, +DC, +Obj, -Obj2): shift one object.
scene_pair_shift_obj_(DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,CF), Cells), NR is R+DR, NC is CF+DC),
        Shifted).

% --- Exported predicates -----------------------------------------------------

% scene_pair_same_n_objs(+Before, +After): Before and After have the same number of objects.
scene_pair_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% scene_pair_added_objs(+Before, +After, -Added): objects in After with no match in Before.
% An object matches if it has the same color and the same normalized form.
scene_pair_added_objs(Before, After, Added) :-
    findall(O, (member(O, After), \+ scene_pair_match_(O, Before)), Added).

% scene_pair_removed_objs(+Before, +After, -Removed): objects in Before with no match in After.
scene_pair_removed_objs(Before, After, Removed) :-
    findall(O, (member(O, Before), \+ scene_pair_match_(O, After)), Removed).

% scene_pair_n_added(+Before, +After, -N): count of added objects.
scene_pair_n_added(Before, After, N) :-
    scene_pair_added_objs(Before, After, Added),
    length(Added, N).

% scene_pair_n_removed(+Before, +After, -N): count of removed objects.
scene_pair_n_removed(Before, After, N) :-
    scene_pair_removed_objs(Before, After, Removed),
    length(Removed, N).

% scene_pair_color_set_before(+Before, -Colors): sorted distinct colors in Before.
scene_pair_color_set_before(Before, Colors) :-
    scene_pair_distinct_colors_(Before, Colors).

% scene_pair_color_set_after(+After, -Colors): sorted distinct colors in After.
scene_pair_color_set_after(After, Colors) :-
    scene_pair_distinct_colors_(After, Colors).

% scene_pair_same_color_set(+Before, +After): both scenes have the same distinct-color set.
scene_pair_same_color_set(Before, After) :-
    scene_pair_distinct_colors_(Before, CB),
    scene_pair_distinct_colors_(After, CA),
    CB == CA.

% scene_pair_color_delta(+Before, +After, -Delta): list of OldColor-NewColor pairs.
% Delta contains one entry per position where the color changed, based on
% position-matched object pairs (Before and After must have the same length).
% If lengths differ, Delta is [].
scene_pair_color_delta(Before, After, Delta) :-
    length(Before, NB),
    length(After, NA),
    (   NB =:= NA
    ->  scene_pair_color_delta_acc_(Before, After, Delta)
    ;   Delta = []
    ).

% scene_pair_color_delta_acc_: accumulate OldColor-NewColor pairs for position-matched pairs.
scene_pair_color_delta_acc_([], [], []).
scene_pair_color_delta_acc_([B|BT], [A|AT], Delta) :-
    scene_pair_color_(B, CB),
    scene_pair_color_(A, CA),
    scene_pair_color_delta_acc_(BT, AT, Rest),
    (   CB == CA
    ->  Delta = Rest
    ;   (   member(CB-CA, Rest)
        ->  Delta = Rest
        ;   Delta = [CB-CA | Rest]
        )
    ).

% scene_pair_is_recolor(+Before, +After): exactly one color in Before was replaced by exactly
% one other color in After. Before and After must have the same number of objects.
scene_pair_is_recolor(Before, After) :-
    scene_pair_same_n_objs(Before, After),
    scene_pair_distinct_colors_(Before, CB),
    scene_pair_distinct_colors_(After, CA),
    subtract(CB, CA, [_OldColor]),
    subtract(CA, CB, [_NewColor]).

% scene_pair_is_recolor_all(+Before, +After): all objects in After have the same color.
scene_pair_is_recolor_all(Before, After) :-
    Before \= [],
    After \= [],
    scene_pair_distinct_colors_(After, [_SingleColor]).

% scene_pair_is_shift(+Before, +After, -DR, -DC): all objects shifted uniformly by (DR,DC).
% Before and After must have the same length. Uses the first object to derive the
% candidate shift, then verifies across the full scene.
scene_pair_is_shift(Before, After, DR, DC) :-
    scene_pair_same_n_objs(Before, After),
    Before = [FirstB | _],
    scene_pair_topleft_(FirstB, r(R1, C1)),
    scene_pair_color_(FirstB, Color),
    scene_pair_norm_(FirstB, Norm),
    member(FirstA, After),
    scene_pair_color_(FirstA, Color),
    scene_pair_norm_(FirstA, Norm),
    scene_pair_topleft_(FirstA, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1,
    maplist(scene_pair_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SB),
    msort(After, SA),
    SB == SA,
    !.

% scene_pair_is_to_origin(+Before, +After): After equals Before shifted so bounding box
% top-left is at r(0,0).
scene_pair_is_to_origin(Before, After) :-
    Before \= [],
    scene_pair_scene_bbox_(Before, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(scene_pair_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SShifted),
    msort(After, SAfter),
    SShifted == SAfter.

% scene_pair_size_preserved(+Before, +After): same length, each position-matched pair has
% the same cell count.
scene_pair_size_preserved(Before, After) :-
    scene_pair_same_n_objs(Before, After),
    maplist(scene_pair_same_size_, Before, After).

% scene_pair_same_size_: pair of objects with equal cell count.
scene_pair_same_size_(B, A) :-
    scene_pair_size_(B, N),
    scene_pair_size_(A, N).
