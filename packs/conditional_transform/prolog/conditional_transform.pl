% condxf.pl - Layer 187: Conditional and Selective Scene Transformation (xc_* prefix).
% Applies transformations to a subset of objects in a scene — those satisfying a
% condition — while leaving the remaining objects unchanged. Complements scenexf
% (which applies transformations uniformly to all objects).
% No cross-pack dependencies. Uses library(lists) and library(apply).
:- module(conditional_transform, [
    % conditional_transform_split_color/4: partition scene into objects of Color vs others.
    conditional_transform_split_color/4,
    % conditional_transform_merge/3: concatenate two object groups into one scene.
    conditional_transform_merge/3,
    % conditional_transform_recolor_matching/4: recolor objects of MatchColor to NewColor; others unchanged.
    conditional_transform_recolor_matching/4,
    % conditional_transform_shift_color/5: shift only objects of Color by (DR,DC); others unchanged.
    conditional_transform_shift_color/5,
    % conditional_transform_swap_colors/4: swap colors C1 and C2 throughout the scene.
    conditional_transform_swap_colors/4,
    % conditional_transform_recolor_by_size/5: recolor objects satisfying size Cmp N to NewColor.
    conditional_transform_recolor_by_size/5,
    % conditional_transform_move_color/5: move objects of Color by (DR,DC); alias for conditional_transform_shift_color.
    conditional_transform_move_color/5,
    % conditional_transform_recolor_largest/3: recolor the largest object to NewColor.
    conditional_transform_recolor_largest/3,
    % conditional_transform_recolor_smallest/3: recolor the smallest object to NewColor.
    conditional_transform_recolor_smallest/3,
    % conditional_transform_largest/2: the single largest object by cell count (first on ties).
    conditional_transform_largest/2,
    % conditional_transform_smallest/2: the single smallest object by cell count (first on ties).
    conditional_transform_smallest/2,
    % conditional_transform_unique_size/2: object whose cell count is unique in the scene (backtrackable).
    conditional_transform_unique_size/2,
    % conditional_transform_recolor_unique_size/3: recolor the unique-size object to NewColor.
    conditional_transform_recolor_unique_size/3,
    % conditional_transform_split_size/5: partition scene into objects satisfying size Cmp N vs others.
    conditional_transform_split_size/5,
    % conditional_transform_infer_gate/3: infer the gate color that splits pairs into distinct change groups.
    conditional_transform_infer_gate/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
:- use_module(library(apply), [maplist/3]).

% --- Private helpers ---------------------------------------------------------

% conditional_transform_color_(+Obj, -Color): extract color.
conditional_transform_color_(obj(Color, _), Color).

% conditional_transform_size_(+Obj, -N): cell count.
conditional_transform_size_(obj(_, Cells), N) :-
    length(Cells, N).

% conditional_transform_size_cmp_(+Cmp, +Size, +N): compare Size with N using Cmp atom.
% Cmp is one of: gt, lt, eq, ge, le.
conditional_transform_size_cmp_(gt, S, N) :- S > N.
conditional_transform_size_cmp_(lt, S, N) :- S < N.
conditional_transform_size_cmp_(eq, S, N) :- S =:= N.
conditional_transform_size_cmp_(ge, S, N) :- S >= N.
conditional_transform_size_cmp_(le, S, N) :- S =< N.

% conditional_transform_recolor_if_match_(+Match, +New, +Obj, -Obj2): recolor Obj if color is Match.
conditional_transform_recolor_if_match_(Match, New, obj(C, Cells), obj(New, Cells)) :-
    C == Match,
    !.
conditional_transform_recolor_if_match_(_, _, Obj, Obj).

% conditional_transform_shift_if_color_(+Color, +DR, +DC, +Obj, -Obj2): shift Obj if color matches.
conditional_transform_shift_if_color_(Color, DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    C == Color,
    !,
    findall(r(NR,NC),
        (member(r(R,CF), Cells),
         NR is R + DR,
         NC is CF + DC),
        Shifted).
conditional_transform_shift_if_color_(_, _, _, Obj, Obj).

% conditional_transform_swap_one_(+C1, +C2, +Obj, -Obj2): swap C1<->C2 in one object.
conditional_transform_swap_one_(C1, C2, obj(C, Cells), obj(NewC, Cells)) :-
    (   C == C1 -> NewC = C2
    ;   C == C2 -> NewC = C1
    ;   NewC = C
    ).

% conditional_transform_recolor_if_size_(+N, +Cmp, +New, +Obj, -Obj2): recolor if size satisfies Cmp.
conditional_transform_recolor_if_size_(N, Cmp, New, obj(_C, Cells), obj(New, Cells)) :-
    length(Cells, S),
    conditional_transform_size_cmp_(Cmp, S, N),
    !.
conditional_transform_recolor_if_size_(_, _, _, Obj, Obj).

% conditional_transform_recolor_if_obj_(+Target, +New, +Obj, -Obj2): recolor if exact same object term.
conditional_transform_recolor_if_obj_(Target, New, Obj, obj(New, Cells)) :-
    Obj == Target,
    !,
    Target = obj(_, Cells).
conditional_transform_recolor_if_obj_(_, _, Obj, Obj).

% --- Exported predicates -----------------------------------------------------

% conditional_transform_split_color(+Scene, +Color, -Match, -NoMatch): partition scene by color.
% Match: objects with color atom equal to Color. NoMatch: all others.
conditional_transform_split_color(Scene, Color, Match, NoMatch) :-
    findall(O, (member(O, Scene), conditional_transform_color_(O, Color)), Match),
    findall(O, (member(O, Scene), conditional_transform_color_(O, C), C \== Color), NoMatch).

% conditional_transform_merge(+Group1, +Group2, -Scene2): concatenate two groups into one scene.
conditional_transform_merge(Group1, Group2, Scene2) :-
    append(Group1, Group2, Scene2).

% conditional_transform_recolor_matching(+Scene, +MatchColor, +NewColor, -Scene2): recolor matching objects.
% Objects whose color is MatchColor become NewColor; others are unchanged.
conditional_transform_recolor_matching(Scene, MatchColor, NewColor, Scene2) :-
    maplist(conditional_transform_recolor_if_match_(MatchColor, NewColor), Scene, Scene2).

% conditional_transform_shift_color(+Scene, +Color, +DR, +DC, -Scene2): shift only Color objects.
% Objects with color Color are translated by (DR, DC). Others are unchanged.
conditional_transform_shift_color(Scene, Color, DR, DC, Scene2) :-
    maplist(conditional_transform_shift_if_color_(Color, DR, DC), Scene, Scene2).

% conditional_transform_swap_colors(+Scene, +C1, +C2, -Scene2): swap colors C1 and C2 throughout.
% Objects of color C1 become C2 and vice versa; other colors are unchanged.
conditional_transform_swap_colors(Scene, C1, C2, Scene2) :-
    maplist(conditional_transform_swap_one_(C1, C2), Scene, Scene2).

% conditional_transform_recolor_by_size(+Scene, +N, +Cmp, +NewColor, -Scene2): recolor objects satisfying size Cmp N.
% Cmp is one of: gt (>), lt (<), eq (=:=), ge (>=), le (=<).
conditional_transform_recolor_by_size(Scene, N, Cmp, NewColor, Scene2) :-
    maplist(conditional_transform_recolor_if_size_(N, Cmp, NewColor), Scene, Scene2).

% conditional_transform_move_color(+Scene, +Color, +DR, +DC, -Scene2): alias for conditional_transform_shift_color.
conditional_transform_move_color(Scene, Color, DR, DC, Scene2) :-
    conditional_transform_shift_color(Scene, Color, DR, DC, Scene2).

% conditional_transform_largest(+Scene, -Obj): the first largest object by cell count (first on ties).
conditional_transform_largest(Scene, Obj) :-
    findall(NegN-O, (member(O, Scene), conditional_transform_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, [_-Obj | _]).

% conditional_transform_smallest(+Scene, -Obj): the first smallest object by cell count (first on ties).
conditional_transform_smallest(Scene, Obj) :-
    findall(N-O, (member(O, Scene), conditional_transform_size_(O, N)), Keyed),
    msort(Keyed, [_-Obj | _]).

% conditional_transform_recolor_largest(+Scene, +NewColor, -Scene2): recolor the largest object to NewColor.
conditional_transform_recolor_largest(Scene, NewColor, Scene2) :-
    conditional_transform_largest(Scene, Largest),
    maplist(conditional_transform_recolor_if_obj_(Largest, NewColor), Scene, Scene2).

% conditional_transform_recolor_smallest(+Scene, +NewColor, -Scene2): recolor the smallest object.
conditional_transform_recolor_smallest(Scene, NewColor, Scene2) :-
    conditional_transform_smallest(Scene, Smallest),
    maplist(conditional_transform_recolor_if_obj_(Smallest, NewColor), Scene, Scene2).

% conditional_transform_unique_size(+Scene, -Obj): object whose cell count is unique in the scene.
% Backtracks to find all objects whose size appears only once.
conditional_transform_unique_size(Scene, Obj) :-
    member(Obj, Scene),
    conditional_transform_size_(Obj, S),
    findall(O2, (member(O2, Scene), conditional_transform_size_(O2, S)), SameSize),
    length(SameSize, 1).

% conditional_transform_recolor_unique_size(+Scene, +NewColor, -Scene2): recolor the unique-size object.
conditional_transform_recolor_unique_size(Scene, NewColor, Scene2) :-
    conditional_transform_unique_size(Scene, Unique),
    maplist(conditional_transform_recolor_if_obj_(Unique, NewColor), Scene, Scene2).

% conditional_transform_split_size(+Scene, +N, +Cmp, -Match, -NoMatch): partition by size comparison.
% Match: objects satisfying size Cmp N. NoMatch: objects not satisfying the comparison.
conditional_transform_split_size(Scene, N, Cmp, Match, NoMatch) :-
    findall(O, (member(O, Scene), conditional_transform_size_(O, S), conditional_transform_size_cmp_(Cmp, S, N)), Match),
    findall(O, (member(O, Scene), conditional_transform_size_(O, S), \+ conditional_transform_size_cmp_(Cmp, S, N)), NoMatch).

% conditional_transform_infer_gate(+Pairs, +_Variants, -Gate)
% Infer the gate color: the object color in input scenes whose presence vs absence
% separates the training pairs into groups with distinct change signatures.
% Pairs is a list of pair(SceneIn, SceneOut) where each scene is a list of obj/2 terms.
% Gate is gate_color(Color) for the first color that successfully separates the pairs.
% Fails if no single color acts as a consistent gate across all pairs.
conditional_transform_infer_gate(Pairs, _Variants, Gate) :-
    findall(C, (member(pair(S, _), Pairs), member(obj(C, _), S)), AllColors),
    sort(AllColors, UniqColors),
    member(GateColor, UniqColors),
    include(conditional_transform_scene_has_color_(GateColor), Pairs, WithGate),
    exclude(conditional_transform_scene_has_color_(GateColor), Pairs, WithoutGate),
    WithGate \= [],
    WithoutGate \= [],
    findall(Sig, (member(pair(SI, SO), WithGate), conditional_transform_change_sig_(SI, SO, Sig)), SigsW),
    findall(Sig, (member(pair(SI, SO), WithoutGate), conditional_transform_change_sig_(SI, SO, Sig)), SigsWO),
    sort(SigsW, SW), sort(SigsWO, SWO),
    SW \= SWO,
    !,
    Gate = gate_color(GateColor).

% conditional_transform_scene_has_color_(+Color, +Pair): succeed if SceneIn contains Color.
conditional_transform_scene_has_color_(Color, pair(SceneIn, _)) :-
    member(obj(Color, _), SceneIn).

% conditional_transform_change_sig_(+SceneIn, +SceneOut, -Sig): compute a change signature for a pair.
% Sig = lost(Lost)-gained(Gained) where Lost and Gained are sorted color lists.
conditional_transform_change_sig_(SceneIn, SceneOut, Sig) :-
    findall(C, member(obj(C, _), SceneIn), CIn),
    findall(C, member(obj(C, _), SceneOut), COut),
    sort(CIn, SI), sort(COut, SO),
    subtract(SI, SO, Lost),
    subtract(SO, SI, Gained),
    Sig = lost(Lost)-gained(Gained).
