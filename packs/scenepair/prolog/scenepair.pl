% scenepair.pl - Layer 188: Holistic Before-After Scene Pair Analysis (ps_* prefix).
% Given a Before scene and an After scene (both lists of obj(Color,Cells) terms),
% computes scene-level observables about the transformation: whether object count
% changed, whether colors changed, the set of added/removed/changed objects, the
% color delta map, the spatial shift (if uniform), and several Boolean flags used
% for rule hypothesis ranking. No cross-pack dependencies.
:- module(scenepair, [
    % ps_same_n_objs/2: Before and After have the same number of objects.
    ps_same_n_objs/2,
    % ps_n_added/3: count of objects in After absent from Before (by form+color).
    ps_n_added/3,
    % ps_n_removed/3: count of objects in Before absent from After (by form+color).
    ps_n_removed/3,
    % ps_added_objs/3: list of objects in After with no match in Before.
    ps_added_objs/3,
    % ps_removed_objs/3: list of objects in Before with no match in After.
    ps_removed_objs/3,
    % ps_color_set_before/2: sorted list of distinct colors in Before.
    ps_color_set_before/2,
    % ps_color_set_after/2: sorted list of distinct colors in After.
    ps_color_set_after/2,
    % ps_same_color_set/2: Before and After have the same distinct-color set.
    ps_same_color_set/2,
    % ps_color_delta/3: list of OldColor-NewColor pairs where color changed.
    ps_color_delta/3,
    % ps_is_recolor/2: exactly one color was replaced by exactly one other color.
    ps_is_recolor/2,
    % ps_is_recolor_all/2: all objects in After have the same color.
    ps_is_recolor_all/2,
    % ps_is_shift/4: all objects shifted by the same (DR,DC); binds DR and DC.
    ps_is_shift/4,
    % ps_is_to_origin/2: After equals Before shifted so bounding box is at r(0,0).
    ps_is_to_origin/2,
    % ps_size_preserved/2: each object's cell count is unchanged (position-matched).
    ps_size_preserved/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, append/3]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% ps_color_(+Obj, -Color): extract color.
ps_color_(obj(Color, _), Color).

% ps_cells_(+Obj, -Cells): extract cell list.
ps_cells_(obj(_, Cells), Cells).

% ps_size_(+Obj, -N): cell count.
ps_size_(obj(_, Cells), N) :-
    length(Cells, N).

% ps_norm_(+Obj, -Norm): normalized form — translate top-left to r(0,0), sort cells.
ps_norm_(obj(_, Cells), Norm) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC), (member(r(R,C), Cells), NR is R-MinR, NC is C-MinC), Raw),
    msort(Raw, Norm).

% ps_match_(+Obj, +List): Obj matches some member of List by color and norm.
ps_match_(Obj, List) :-
    ps_color_(Obj, C),
    ps_norm_(Obj, Norm),
    member(Cand, List),
    ps_color_(Cand, C),
    ps_norm_(Cand, Norm),
    !.

% ps_distinct_colors_(+Scene, -Colors): sorted distinct color atoms.
ps_distinct_colors_(Scene, Colors) :-
    findall(C, (member(O, Scene), ps_color_(O, C)), Raw),
    msort(Raw, Sorted),
    ps_dedup_(Sorted, Colors).

% ps_dedup_(+List, -Deduped): remove consecutive duplicates from sorted list.
ps_dedup_([], []).
ps_dedup_([X], [X]) :- !.
ps_dedup_([X,X|T], Out) :-
    !,
    ps_dedup_([X|T], Out).
ps_dedup_([X|T], [X|Out]) :-
    ps_dedup_(T, Out).

% ps_topleft_(+Obj, -r(MinR,MinC)): top-left cell of an object.
ps_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% ps_scene_bbox_(+Scene, -MinR, -MaxR, -MinC, -MaxC): bounding box of whole scene.
ps_scene_bbox_(Scene, MinR, MaxR, MinC, MaxC) :-
    findall(R, (member(O, Scene), ps_cells_(O, Cells), member(r(R,_), Cells)), Rs),
    findall(C, (member(O, Scene), ps_cells_(O, Cells), member(r(_,C), Cells)), Cs),
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% ps_shift_obj_(+DR, +DC, +Obj, -Obj2): shift one object.
ps_shift_obj_(DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    findall(r(NR,NC),
        (member(r(R,CF), Cells), NR is R+DR, NC is CF+DC),
        Shifted).

% --- Exported predicates -----------------------------------------------------

% ps_same_n_objs(+Before, +After): Before and After have the same number of objects.
ps_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% ps_added_objs(+Before, +After, -Added): objects in After with no match in Before.
% An object matches if it has the same color and the same normalized form.
ps_added_objs(Before, After, Added) :-
    findall(O, (member(O, After), \+ ps_match_(O, Before)), Added).

% ps_removed_objs(+Before, +After, -Removed): objects in Before with no match in After.
ps_removed_objs(Before, After, Removed) :-
    findall(O, (member(O, Before), \+ ps_match_(O, After)), Removed).

% ps_n_added(+Before, +After, -N): count of added objects.
ps_n_added(Before, After, N) :-
    ps_added_objs(Before, After, Added),
    length(Added, N).

% ps_n_removed(+Before, +After, -N): count of removed objects.
ps_n_removed(Before, After, N) :-
    ps_removed_objs(Before, After, Removed),
    length(Removed, N).

% ps_color_set_before(+Before, -Colors): sorted distinct colors in Before.
ps_color_set_before(Before, Colors) :-
    ps_distinct_colors_(Before, Colors).

% ps_color_set_after(+After, -Colors): sorted distinct colors in After.
ps_color_set_after(After, Colors) :-
    ps_distinct_colors_(After, Colors).

% ps_same_color_set(+Before, +After): both scenes have the same distinct-color set.
ps_same_color_set(Before, After) :-
    ps_distinct_colors_(Before, CB),
    ps_distinct_colors_(After, CA),
    CB == CA.

% ps_color_delta(+Before, +After, -Delta): list of OldColor-NewColor pairs.
% Delta contains one entry per position where the color changed, based on
% position-matched object pairs (Before and After must have the same length).
% If lengths differ, Delta is [].
ps_color_delta(Before, After, Delta) :-
    length(Before, NB),
    length(After, NA),
    (   NB =:= NA
    ->  ps_color_delta_acc_(Before, After, Delta)
    ;   Delta = []
    ).

% ps_color_delta_acc_: accumulate OldColor-NewColor pairs for position-matched pairs.
ps_color_delta_acc_([], [], []).
ps_color_delta_acc_([B|BT], [A|AT], Delta) :-
    ps_color_(B, CB),
    ps_color_(A, CA),
    ps_color_delta_acc_(BT, AT, Rest),
    (   CB == CA
    ->  Delta = Rest
    ;   (   member(CB-CA, Rest)
        ->  Delta = Rest
        ;   Delta = [CB-CA | Rest]
        )
    ).

% ps_is_recolor(+Before, +After): exactly one color in Before was replaced by exactly
% one other color in After. Before and After must have the same number of objects.
ps_is_recolor(Before, After) :-
    ps_same_n_objs(Before, After),
    ps_distinct_colors_(Before, CB),
    ps_distinct_colors_(After, CA),
    subtract(CB, CA, [_OldColor]),
    subtract(CA, CB, [_NewColor]).

% ps_is_recolor_all(+Before, +After): all objects in After have the same color.
ps_is_recolor_all(Before, After) :-
    Before \= [],
    After \= [],
    ps_distinct_colors_(After, [_SingleColor]).

% ps_is_shift(+Before, +After, -DR, -DC): all objects shifted uniformly by (DR,DC).
% Before and After must have the same length. Uses the first object to derive the
% candidate shift, then verifies across the full scene.
ps_is_shift(Before, After, DR, DC) :-
    ps_same_n_objs(Before, After),
    Before = [FirstB | _],
    ps_topleft_(FirstB, r(R1, C1)),
    ps_color_(FirstB, Color),
    ps_norm_(FirstB, Norm),
    member(FirstA, After),
    ps_color_(FirstA, Color),
    ps_norm_(FirstA, Norm),
    ps_topleft_(FirstA, r(R2, C2)),
    DR is R2 - R1,
    DC is C2 - C1,
    maplist(ps_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SB),
    msort(After, SA),
    SB == SA,
    !.

% ps_is_to_origin(+Before, +After): After equals Before shifted so bounding box
% top-left is at r(0,0).
ps_is_to_origin(Before, After) :-
    Before \= [],
    ps_scene_bbox_(Before, MinR, _, MinC, _),
    DR is -MinR,
    DC is -MinC,
    maplist(ps_shift_obj_(DR, DC), Before, Shifted),
    msort(Shifted, SShifted),
    msort(After, SAfter),
    SShifted == SAfter.

% ps_size_preserved(+Before, +After): same length, each position-matched pair has
% the same cell count.
ps_size_preserved(Before, After) :-
    ps_same_n_objs(Before, After),
    maplist(ps_same_size_, Before, After).

% ps_same_size_: pair of objects with equal cell count.
ps_same_size_(B, A) :-
    ps_size_(B, N),
    ps_size_(A, N).
