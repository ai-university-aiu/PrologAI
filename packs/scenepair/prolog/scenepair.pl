% scenepair.pl - Layer 188: Holistic Before-After Scene Pair Analysis (ps_* prefix).
% Given a Before scene and an After scene (both lists of obj(Color,Cells) terms),
% computes scene-level observables about the transformation: whether object count
% changed, whether colors changed, the set of added/removed/changed objects, the
% color delta map, the spatial shift (if uniform), and several Boolean flags used
% for rule hypothesis ranking. No cross-pack dependencies.
:- module(scenepair, [
    % scenepair_same_n_objs/2: Before and After have the same number of objects.
    scenepair_same_n_objs/2,
    % scenepair_n_added/3: count of objects in After absent from Before (by form+color).
    scenepair_n_added/3,
    % scenepair_n_removed/3: count of objects in Before absent from After (by form+color).
    scenepair_n_removed/3,
    % scenepair_added_objs/3: list of objects in After with no match in Before.
    scenepair_added_objs/3,
    % scenepair_removed_objs/3: list of objects in Before with no match in After.
    scenepair_removed_objs/3,
    % scenepair_color_set_before/2: sorted list of distinct colors in Before.
    scenepair_color_set_before/2,
    % scenepair_color_set_after/2: sorted list of distinct colors in After.
    scenepair_color_set_after/2,
    % scenepair_same_color_set/2: Before and After have the same distinct-color set.
    scenepair_same_color_set/2,
    % scenepair_color_delta/3: list of OldColor-NewColor pairs where color changed.
    scenepair_color_delta/3,
    % scenepair_is_recolor/2: exactly one color was replaced by exactly one other color.
    scenepair_is_recolor/2,
    % scenepair_is_recolor_all/2: all objects in After have the same color.
    scenepair_is_recolor_all/2,
    % scenepair_is_shift/4: all objects shifted by the same (DR,DC); binds DR and DC.
    scenepair_is_shift/4,
    % scenepair_is_to_origin/2: After equals Before shifted so bounding box is at r(0,0).
    scenepair_is_to_origin/2,
    % scenepair_size_preserved/2: each object's cell count is unchanged (position-matched).
    scenepair_size_preserved/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, append/3]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% scenepair_color_(+Obj, -Color): extract color.
scenepair_color_(obj(Color, _), Color).

% scenepair_cells_(+Obj, -Cells): extract cell list.
scenepair_cells_(obj(_, Cells), Cells).

% scenepair_size_(+Obj, -N): cell count.
scenepair_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scenepair_norm_(+Obj, -Norm): normalized form — translate top-left to r(0,0), sort cells.
scenepair_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC), (member(r(R,C), Cells), NR is R-MinR, NC is C-MinC), Raw),
    msort(Raw, Norm).

% scenepair_match_(+Obj, +List): Obj matches some member of List by color and norm.
scenepair_match_(Obj, List) :-
    scenepair_color_(Obj, C),
    scenepair_norm_(Obj, Norm),
    member(Cand, List),
    scenepair_color_(Cand, C),
    scenepair_norm_(Cand, Norm),
    !.

% scenepair_distinct_colors_(+Scene, -Colors): sorted distinct color atoms.
scenepair_distinct_colors_(Scene, Colors) :-
    findall(C, (member(O, Scene), scenepair_color_(O, C)), Raw),
    msort(Raw, Sorted),
    scenepair_dedup_(Sorted, Colors).

% scenepair_dedup_(+List, -Deduped): remove consecutive duplicates from sorted list.
scenepair_dedup_([], []).
scenepair_dedup_([X], [X]) :- !.
scenepair_dedup_([X,X|T], Out) :-
    !,
    scenepair_dedup_([X|T], Out).
scenepair_dedup_([X|T], [X|Out]) :-
    scenepair_dedup_(T, Out).

% scenepair_topleft_(+Obj, -r(MinR,MinC)): top-left cell of an object.
scenepair_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% scenepair_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
scenepair_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(O, Scene), scenepair_cells_(O, Cells), member(r(R,_), Cells)), Rs),
    findall(C, (member(O, Scene), scenepair_cells_(O, Cells), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% scenepair_shift_obj_(+DR, +DC, +Obj, -Obj2): shift one object.
scenepair_shift_obj_(DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,CF), Cells), NR is R+DR, NC is CF+DC),
        Shifted).

% --- Exported predicates -----------------------------------------------------

% scenepair_same_n_objs(+Before, +After): Before and After have the same number of objects.
scenepair_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% scenepair_added_objs(+Before, +After, -Added): objects in After with no match in Before.
% An object matches if it has the same color and the same normalized form.
scenepair_added_objs(Before, After, Added) :-
    findall(O, (member(O, After), \+ scenepair_match_(O, Before)), Added).

% scenepair_removed_objs(+Before, +After, -Removed): objects in Before with no match in After.
scenepair_removed_objs(Before, After, Removed) :-
    findall(O, (member(O, Before), \+ scenepair_match_(O, After)), Removed).

% scenepair_n_added(+Before, +After, -N): count of added objects.
scenepair_n_added(Before, After, N) :-
    scenepair_added_objs(Before, After, Added),
    length(Added, N).

% scenepair_n_removed(+Before, +After, -N): count of removed objects.
scenepair_n_removed(Before, After, N) :-
    scenepair_removed_objs(Before, After, Removed),
    length(Removed, N).

% scenepair_color_set_before(+Before, -Colors): sorted distinct colors in Before.
scenepair_color_set_before(Before, Colors) :-
    scenepair_distinct_colors_(Before, Colors).

% scenepair_color_set_after(+After, -Colors): sorted distinct colors in After.
scenepair_color_set_after(After, Colors) :-
    scenepair_distinct_colors_(After, Colors).

% scenepair_same_color_set(+Before, +After): both scenes have the same distinct-color set.
scenepair_same_color_set(Before, After) :-
    scenepair_distinct_colors_(Before, CB),
    scenepair_distinct_colors_(After, CA),
    CB == CA.

% scenepair_color_delta(+Before, +After, -Delta): list of OldColor-NewColor pairs.
% Delta contains one entry per position where the color changed, based on
% position-matched object pairs (Before and After must have the same length).
% If lengths differ, Delta is [].
scenepair_color_delta(Before, After, Delta) :-
    length(Before, NB),
    length(After, NA),
    (   NB =:= NA
    ->  scenepair_color_delta_acc_(Before, After, Delta)
    ;   Delta = []
    ).

% scenepair_color_delta_acc_: accumulate OldColor-NewColor pairs for position-matched pairs.
scenepair_color_delta_acc_([], [], []).
scenepair_color_delta_acc_([B|BT], [A|AT], Delta) :-
    scenepair_color_(B, CB),
    scenepair_color_(A, CA),
    scenepair_color_delta_acc_(BT, AT, Rest),
    (   CB == CA
    ->  Delta = Rest
    ;   (   member(CB-CA, Rest)
        ->  Delta = Rest
        ;   Delta = [CB-CA | Rest]
        )
    ).

% scenepair_is_recolor(+Before, +After): exactly one color in Before was replaced by exactly
% one other color in After. Before and After must have the same number of objects.
scenepair_is_recolor(Before, After) :-
    scenepair_same_n_objs(Before, After),
    scenepair_distinct_colors_(Before, CB),
    scenepair_distinct_colors_(After, CA),
    subtract(CB, CA, [_OldColor]),
    subtract(CA, CB, [_NewColor]).

% scenepair_is_recolor_all(+Before, +After): all objects in After have the same color.
scenepair_is_recolor_all(Before, After) :-
    Before \= [],
    After \= [],
    scenepair_distinct_colors_(After, [_SingleColor]).

% scenepair_is_shift(+Before, +After, -DR, -DC): all objects shifted uniformly by (DR,DC).
% Before and After must have the same length. Uses the first object to derive the
% candidate shift, then verifies across the full scene.
scenepair_is_shift(Before, After, DR, DC) :-
    scenepair_same_n_objs(Before, After),
    Before = [FirstB | _],
    scenepair_topleft_(FirstB, r(R1, C1)),
    scenepair_color_(FirstB, Color),
    scenepair_norm_(FirstB, Norm),
    member(FirstA, After),
    scenepair_color_(FirstA, Color),
    scenepair_norm_(FirstA, Norm),
    scenepair_topleft_(FirstA, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1,
    maplist(scenepair_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SB),
    msort(After, SA),
    SB == SA,
    !.

% scenepair_is_to_origin(+Before, +After): After equals Before shifted so bounding box
% top-left is at r(0,0).
scenepair_is_to_origin(Before, After) :-
    Before \= [],
    scenepair_scene_bbox_(Before, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(scenepair_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SShifted),
    msort(After, SAfter),
    SShifted == SAfter.

% scenepair_size_preserved(+Before, +After): same length, each position-matched pair has
% the same cell count.
scenepair_size_preserved(Before, After) :-
    scenepair_same_n_objs(Before, After),
    maplist(scenepair_same_size_, Before, After).

% scenepair_same_size_: pair of objects with equal cell count.
scenepair_same_size_(B, A) :-
    scenepair_size_(B, N),
    scenepair_size_(A, N).
