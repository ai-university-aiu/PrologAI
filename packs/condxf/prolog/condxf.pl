% condxf.pl - Layer 187: Conditional and Selective Scene Transformation (xc_* prefix).
% Applies transformations to a subset of objects in a scene — those satisfying a
% condition — while leaving the remaining objects unchanged. Complements scenexf
% (which applies transformations uniformly to all objects).
% No cross-pack dependencies. Uses library(lists) and library(apply).
:- module(condxf, [
    % xc_split_color/4: partition scene into objects of Color vs others.
    xc_split_color/4,
    % xc_merge/3: concatenate two object groups into one scene.
    xc_merge/3,
    % xc_recolor_matching/4: recolor objects of MatchColor to NewColor; others unchanged.
    xc_recolor_matching/4,
    % xc_shift_color/5: shift only objects of Color by (DR,DC); others unchanged.
    xc_shift_color/5,
    % xc_swap_colors/4: swap colors C1 and C2 throughout the scene.
    xc_swap_colors/4,
    % xc_recolor_by_size/5: recolor objects satisfying size Cmp N to NewColor.
    xc_recolor_by_size/5,
    % xc_move_color/5: move objects of Color by (DR,DC); alias for xc_shift_color.
    xc_move_color/5,
    % xc_recolor_largest/3: recolor the largest object to NewColor.
    xc_recolor_largest/3,
    % xc_recolor_smallest/3: recolor the smallest object to NewColor.
    xc_recolor_smallest/3,
    % xc_largest/2: the single largest object by cell count (first on ties).
    xc_largest/2,
    % xc_smallest/2: the single smallest object by cell count (first on ties).
    xc_smallest/2,
    % xc_unique_size/2: object whose cell count is unique in the scene (backtrackable).
    xc_unique_size/2,
    % xc_recolor_unique_size/3: recolor the unique-size object to NewColor.
    xc_recolor_unique_size/3,
    % xc_split_size/5: partition scene into objects satisfying size Cmp N vs others.
    xc_split_size/5
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
:- use_module(library(apply), [maplist/3]).

% --- Private helpers ---------------------------------------------------------

% xc_color_(+Obj, -Color): extract color.
xc_color_(obj(Color, _), Color).

% xc_size_(+Obj, -N): cell count.
xc_size_(obj(_, Cells), N) :-
    length(Cells, N).

% xc_size_cmp_(+Cmp, +Size, +N): compare Size with N using Cmp atom.
% Cmp is one of: gt, lt, eq, ge, le.
xc_size_cmp_(gt, S, N) :- S > N.
xc_size_cmp_(lt, S, N) :- S < N.
xc_size_cmp_(eq, S, N) :- S =:= N.
xc_size_cmp_(ge, S, N) :- S >= N.
xc_size_cmp_(le, S, N) :- S =< N.

% xc_recolor_if_match_(+Match, +New, +Obj, -Obj2): recolor Obj if color is Match.
xc_recolor_if_match_(Match, New, obj(C, Cells), obj(New, Cells)) :-
    C == Match,
    !.
xc_recolor_if_match_(_, _, Obj, Obj).

% xc_shift_if_color_(+Color, +DR, +DC, +Obj, -Obj2): shift Obj if color matches.
xc_shift_if_color_(Color, DR, DC, obj(C, Cells), obj(C, Shifted)) :-
    C == Color,
    !,
    findall(r(NR,NC),
        (member(r(R,CF), Cells),
         NR is R + DR,
         NC is CF + DC),
        Shifted).
xc_shift_if_color_(_, _, _, Obj, Obj).

% xc_swap_one_(+C1, +C2, +Obj, -Obj2): swap C1<->C2 in one object.
xc_swap_one_(C1, C2, obj(C, Cells), obj(NewC, Cells)) :-
    (   C == C1 -> NewC = C2
    ;   C == C2 -> NewC = C1
    ;   NewC = C
    ).

% xc_recolor_if_size_(+N, +Cmp, +New, +Obj, -Obj2): recolor if size satisfies Cmp.
xc_recolor_if_size_(N, Cmp, New, obj(_C, Cells), obj(New, Cells)) :-
    length(Cells, S),
    xc_size_cmp_(Cmp, S, N),
    !.
xc_recolor_if_size_(_, _, _, Obj, Obj).

% xc_recolor_if_obj_(+Target, +New, +Obj, -Obj2): recolor if exact same object term.
xc_recolor_if_obj_(Target, New, Obj, obj(New, Cells)) :-
    Obj == Target,
    !,
    Target = obj(_, Cells).
xc_recolor_if_obj_(_, _, Obj, Obj).

% --- Exported predicates -----------------------------------------------------

% xc_split_color(+Scene, +Color, -Match, -NoMatch): partition scene by color.
% Match: objects with color atom equal to Color. NoMatch: all others.
xc_split_color(Scene, Color, Match, NoMatch) :-
    findall(O, (member(O, Scene), xc_color_(O, Color)), Match),
    findall(O, (member(O, Scene), xc_color_(O, C), C \== Color), NoMatch).

% xc_merge(+Group1, +Group2, -Scene2): concatenate two groups into one scene.
xc_merge(Group1, Group2, Scene2) :-
    append(Group1, Group2, Scene2).

% xc_recolor_matching(+Scene, +MatchColor, +NewColor, -Scene2): recolor matching objects.
% Objects whose color is MatchColor become NewColor; others are unchanged.
xc_recolor_matching(Scene, MatchColor, NewColor, Scene2) :-
    maplist(xc_recolor_if_match_(MatchColor, NewColor), Scene, Scene2).

% xc_shift_color(+Scene, +Color, +DR, +DC, -Scene2): shift only Color objects.
% Objects with color Color are translated by (DR, DC). Others are unchanged.
xc_shift_color(Scene, Color, DR, DC, Scene2) :-
    maplist(xc_shift_if_color_(Color, DR, DC), Scene, Scene2).

% xc_swap_colors(+Scene, +C1, +C2, -Scene2): swap colors C1 and C2 throughout.
% Objects of color C1 become C2 and vice versa; other colors are unchanged.
xc_swap_colors(Scene, C1, C2, Scene2) :-
    maplist(xc_swap_one_(C1, C2), Scene, Scene2).

% xc_recolor_by_size(+Scene, +N, +Cmp, +NewColor, -Scene2): recolor objects satisfying size Cmp N.
% Cmp is one of: gt (>), lt (<), eq (=:=), ge (>=), le (=<).
xc_recolor_by_size(Scene, N, Cmp, NewColor, Scene2) :-
    maplist(xc_recolor_if_size_(N, Cmp, NewColor), Scene, Scene2).

% xc_move_color(+Scene, +Color, +DR, +DC, -Scene2): alias for xc_shift_color.
xc_move_color(Scene, Color, DR, DC, Scene2) :-
    xc_shift_color(Scene, Color, DR, DC, Scene2).

% xc_largest(+Scene, -Obj): the first largest object by cell count (first on ties).
xc_largest(Scene, Obj) :-
    findall(NegN-O, (member(O, Scene), xc_size_(O, N), NegN is -N), Keyed),
    msort(Keyed, [_-Obj | _]).

% xc_smallest(+Scene, -Obj): the first smallest object by cell count (first on ties).
xc_smallest(Scene, Obj) :-
    findall(N-O, (member(O, Scene), xc_size_(O, N)), Keyed),
    msort(Keyed, [_-Obj | _]).

% xc_recolor_largest(+Scene, +NewColor, -Scene2): recolor the largest object to NewColor.
xc_recolor_largest(Scene, NewColor, Scene2) :-
    xc_largest(Scene, Largest),
    maplist(xc_recolor_if_obj_(Largest, NewColor), Scene, Scene2).

% xc_recolor_smallest(+Scene, +NewColor, -Scene2): recolor the smallest object.
xc_recolor_smallest(Scene, NewColor, Scene2) :-
    xc_smallest(Scene, Smallest),
    maplist(xc_recolor_if_obj_(Smallest, NewColor), Scene, Scene2).

% xc_unique_size(+Scene, -Obj): object whose cell count is unique in the scene.
% Backtracks to find all objects whose size appears only once.
xc_unique_size(Scene, Obj) :-
    member(Obj, Scene),
    xc_size_(Obj, S),
    findall(O2, (member(O2, Scene), xc_size_(O2, S)), SameSize),
    length(SameSize, 1).

% xc_recolor_unique_size(+Scene, +NewColor, -Scene2): recolor the unique-size object.
xc_recolor_unique_size(Scene, NewColor, Scene2) :-
    xc_unique_size(Scene, Unique),
    maplist(xc_recolor_if_obj_(Unique, NewColor), Scene, Scene2).

% xc_split_size(+Scene, +N, +Cmp, -Match, -NoMatch): partition by size comparison.
% Match: objects satisfying size Cmp N. NoMatch: objects not satisfying the comparison.
xc_split_size(Scene, N, Cmp, Match, NoMatch) :-
    findall(O, (member(O, Scene), xc_size_(O, S), xc_size_cmp_(Cmp, S, N)), Match),
    findall(O, (member(O, Scene), xc_size_(O, S), \+ xc_size_cmp_(Cmp, S, N)), NoMatch).
