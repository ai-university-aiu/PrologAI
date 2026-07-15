% condxf.pl - Layer 187: Conditional and Selective Scene Transformation (xc_* prefix).
% Applies transformations to a subset of objects in a scene — those satisfying a
% condition — while leaving the remaining objects unchanged. Complements scenexf
% (which applies transformations uniformly to all objects).
% No cross-pack dependencies. Uses library(lists) and library(apply).
:- module(condxf, [
    % condxf_split_color/4: partition scene into objects of Color vs others.
    condxf_split_color/4,
    % condxf_merge/3: concatenate two object groups into one scene.
    condxf_merge/3,
    % condxf_recolor_matching/4: recolor objects of MatchColor to NewColor; others unchanged.
    condxf_recolor_matching/4,
    % condxf_shift_color/5: shift only objects of Color by (DR,DC); others unchanged.
    condxf_shift_color/5,
    % condxf_swap_colors/4: swap colors C1 and C2 throughout the scene.
    condxf_swap_colors/4,
    % condxf_recolor_by_size/5: recolor objects satisfying size Cmp N to NewColor.
    condxf_recolor_by_size/5,
    % condxf_move_color/5: move objects of Color by (DR,DC); alias for condxf_shift_color.
    condxf_move_color/5,
    % condxf_recolor_largest/3: recolor the largest object to NewColor.
    condxf_recolor_largest/3,
    % condxf_recolor_smallest/3: recolor the smallest object to NewColor.
    condxf_recolor_smallest/3,
    % condxf_largest/2: the single largest object by cell count (first on ties).
    condxf_largest/2,
    % condxf_smallest/2: the single smallest object by cell count (first on ties).
    condxf_smallest/2,
    % condxf_unique_size/2: object whose cell count is unique in the scene (backtrackable).
    condxf_unique_size/2,
    % condxf_recolor_unique_size/3: recolor the unique-size object to NewColor.
    condxf_recolor_unique_size/3,
    % condxf_split_size/5: partition scene into objects satisfying size Cmp N vs others.
    condxf_split_size/5,
    % condxf_infer_gate/3: infer the gate color that splits pairs into distinct change groups.
    condxf_infer_gate/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
:- use_module(library(apply), [maplist/3]).

% --- Private helpers ---------------------------------------------------------

% condxf_color_(+Obj, -Color): extract color.
condxf_color_(obj(Color, _), Color).

% condxf_size_(+Obj, -N): cell count.
condxf_size_(obj(_, Cells), N) :-
    length(Cells, N).

% condxf_size_cmp_(+Cmp, +Size, +N): compare Size with N using Cmp atom.
% Cmp is one of: gt, lt, eq, ge, le.
condxf_size_cmp_(gt, S, N) :- S > N.
condxf_size_cmp_(lt, S, N) :- S < N.
condxf_size_cmp_(eq, S, N) :- S =:= N.
condxf_size_cmp_(ge, S, N) :- S >= N.
condxf_size_cmp_(le, S, N) :- S =< N.

% condxf_recolor_if_match_(+Match, +New, +Obj, -Obj2): recolor Obj if color is Match.
condxf_recolor_if_match_(Match, New, obj(C, Cells), obj(New, Cells)) :-
    C == Match,
    !.
condxf_recolor_if_match_(_, _, Obj, Obj).

% condxf_shift_if_color_(+Color, +DR, +DC, +Obj, -Obj2): shift Obj if color matches.
condxf_shift_if_color_(Color, DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    C == Color,
    !,
    findall(r(NR,NC),
        (member(r(R,CF), Cells),
         NR is R + DR,
         NC is CF + DC),
        Shifted).
condxf_shift_if_color_(_, _, _, Obj, Obj).

% condxf_swap_one_(+C1, +C2, +Obj, -Obj2): swap C1<->C2 in one object.
condxf_swap_one_(C1, C2, obj(C, Cells), obj(NewC, Cells)) :-
    (   C == C1 -> NewC = C2
    ;   C == C2 -> NewC = C1
    ;   NewC = C
    ).

% condxf_recolor_if_size_(+N, +Cmp, +New, +Obj, -Obj2): recolor if size satisfies Cmp.
condxf_recolor_if_size_(N, Cmp, New, obj(_C, Cells), obj(New, Cells)) :-
    length(Cells, S),
    condxf_size_cmp_(Cmp, S, N),
    !.
condxf_recolor_if_size_(_, _, _, Obj, Obj).

% condxf_recolor_if_obj_(+Target, +New, +Obj, -Obj2): recolor if exact same object term.
condxf_recolor_if_obj_(Target, New, Obj, obj(New, Cells)) :-
    Obj == Target,
    !,
    Target = obj(_, Cells).
condxf_recolor_if_obj_(_, _, Obj, Obj).

% --- Exported predicates -----------------------------------------------------

% condxf_split_color(+Scene, +Color, -Match, -NoMatch): partition scene by color.
% Match: objects with color atom equal to Color. NoMatch: all others.
condxf_split_color(Scene, Color, Match, NoMatch) :-
    findall(O, (member(O, Scene), condxf_color_(O, Color)), Match),
    findall(O, (member(O, Scene), condxf_color_(O, C), C \== Color), NoMatch).

% condxf_merge(+Group1, +Group2, -Scene2): concatenate two groups into one scene.
condxf_merge(Group1, Group2, Scene2) :-
    append(Group1, Group2, Scene2).

% condxf_recolor_matching(+Scene, +MatchColor, +NewColor, -Scene2): recolor matching objects.
% Objects whose color is MatchColor become NewColor; others are unchanged.
condxf_recolor_matching(Scene, MatchColor, NewColor, Scene2) :-
    maplist(condxf_recolor_if_match_(MatchColor, NewColor), Scene, Scene2).

% condxf_shift_color(+Scene, +Color, +DR, +DC, -Scene2): shift only Color objects.
% Objects with color Color are translated by (DR, DC). Others are unchanged.
condxf_shift_color(Scene, Color, DR, DC, Scene2) :-
    maplist(condxf_shift_if_color_(Color, DR, DC), Scene, Scene2).

% condxf_swap_colors(+Scene, +C1, +C2, -Scene2): swap colors C1 and C2 throughout.
% Objects of color C1 become C2 and vice versa; other colors are unchanged.
condxf_swap_colors(Scene, C1, C2, Scene2) :-
    maplist(condxf_swap_one_(C1, C2), Scene, Scene2).

% condxf_recolor_by_size(+Scene, +N, +Cmp, +NewColor, -Scene2): recolor objects satisfying size Cmp N.
% Cmp is one of: gt (>), lt (<), eq (=:=), ge (>=), le (=<).
condxf_recolor_by_size(Scene, N, Cmp, NewColor, Scene2) :-
    maplist(condxf_recolor_if_size_(N, Cmp, NewColor), Scene, Scene2).

% condxf_move_color(+Scene, +Color, +DR, +DC, -Scene2): alias for condxf_shift_color.
condxf_move_color(Scene, Color, DR, DC, Scene2) :-
    condxf_shift_color(Scene, Color, DR, DC, Scene2).

% condxf_largest(+Scene, -Obj): the first largest object by cell count (first on ties).
condxf_largest(Scene, Obj) :-
    findall(NegN-O, (member(O, Scene), condxf_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, [_-Obj | _]).

% condxf_smallest(+Scene, -Obj): the first smallest object by cell count (first on ties).
condxf_smallest(Scene, Obj) :-
    findall(N-O, (member(O, Scene), condxf_size_(O, N)), Keyed),
    msort(Keyed, [_-Obj | _]).

% condxf_recolor_largest(+Scene, +NewColor, -Scene2): recolor the largest object to NewColor.
condxf_recolor_largest(Scene, NewColor, Scene2) :-
    condxf_largest(Scene, Largest),
    maplist(condxf_recolor_if_obj_(Largest, NewColor), Scene, Scene2).

% condxf_recolor_smallest(+Scene, +NewColor, -Scene2): recolor the smallest object.
condxf_recolor_smallest(Scene, NewColor, Scene2) :-
    condxf_smallest(Scene, Smallest),
    maplist(condxf_recolor_if_obj_(Smallest, NewColor), Scene, Scene2).

% condxf_unique_size(+Scene, -Obj): object whose cell count is unique in the scene.
% Backtracks to find all objects whose size appears only once.
condxf_unique_size(Scene, Obj) :-
    member(Obj, Scene),
    condxf_size_(Obj, S),
    findall(O2, (member(O2, Scene), condxf_size_(O2, S)), SameSize),
    length(SameSize, 1).

% condxf_recolor_unique_size(+Scene, +NewColor, -Scene2): recolor the unique-size object.
condxf_recolor_unique_size(Scene, NewColor, Scene2) :-
    condxf_unique_size(Scene, Unique),
    maplist(condxf_recolor_if_obj_(Unique, NewColor), Scene, Scene2).

% condxf_split_size(+Scene, +N, +Cmp, -Match, -NoMatch): partition by size comparison.
% Match: objects satisfying size Cmp N. NoMatch: objects not satisfying the comparison.
condxf_split_size(Scene, N, Cmp, Match, NoMatch) :-
    findall(O, (member(O, Scene), condxf_size_(O, S), condxf_size_cmp_(Cmp, S, N)), Match),
    findall(O, (member(O, Scene), condxf_size_(O, S), \+ condxf_size_cmp_(Cmp, S, N)), NoMatch).

% condxf_infer_gate(+Pairs, +_Variants, -Gate)
% Infer the gate color: the object color in input scenes whose presence vs absence
% separates the training pairs into groups with distinct change signatures.
% Pairs is a list of pair(SceneIn, SceneOut) where each scene is a list of obj/2 terms.
% Gate is gate_color(Color) for the first color that successfully separates the pairs.
% Fails if no single color acts as a consistent gate across all pairs.
condxf_infer_gate(Pairs, _Variants, Gate) :-
    findall(C, (member(pair(S, _), Pairs), member(obj(C, _), S)), AllColors),
    sort(AllColors, UniqColors),
    member(GateColor, UniqColors),
    include(condxf_scene_has_color_(GateColor), Pairs, WithGate),
    exclude(condxf_scene_has_color_(GateColor), Pairs, WithoutGate),
    WithGate \= [],
    WithoutGate \= [],
    findall(Sig, (member(pair(SI, SO), WithGate), condxf_change_sig_(SI, SO, Sig)), SigsW),
    findall(Sig, (member(pair(SI, SO), WithoutGate), condxf_change_sig_(SI, SO, Sig)), SigsWO),
    sort(SigsW, SW), sort(SigsWO, SWO),
    SW \= SWO,
    !,
    Gate = gate_color(GateColor).

% condxf_scene_has_color_(+Color, +Pair): succeed if SceneIn contains Color.
condxf_scene_has_color_(Color, pair(SceneIn, _)) :-
    member(obj(Color, _), SceneIn).

% condxf_change_sig_(+SceneIn, +SceneOut, -Sig): compute a change signature for a pair.
% Sig = lost(Lost)-gained(Gained) where Lost and Gained are sorted color lists.
condxf_change_sig_(SceneIn, SceneOut, Sig) :-
    findall(C, member(obj(C, _), SceneIn), CIn),
    findall(C, member(obj(C, _), SceneOut), COut),
    sort(CIn, SI), sort(COut, SO),
    subtract(SI, SO, Lost),
    subtract(SO, SI, Gained),
    Sig = lost(Lost)-gained(Gained).
