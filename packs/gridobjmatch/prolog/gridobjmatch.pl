% Module declaration with all fourteen public predicates.
:- module(gridobjmatch, [
% Match ob/3 objects from two lists by shared color; return match/2 pairs.
    gridobjmatch_match_color/3,
% Match objects from two lists by nearest doubled-centroid distance; return match/2 pairs.
    gridobjmatch_match_nearest/3,
% Match objects from two lists by shared cell count; return match/2 pairs.
    gridobjmatch_match_size/3,
% Objs in Objs1 that appear in no match/2 pair as the first element.
    gridobjmatch_unmatched_a/3,
% Objs in Objs2 that appear in no match/2 pair as the second element.
    gridobjmatch_unmatched_b/3,
% Partition a Pairs list into same-color and different-color sub-lists.
    gridobjmatch_color_diff/3,
% mv(DR,DC) movement vector from the top-left bbox of O1 to that of O2.
    gridobjmatch_move_vector/2,
% List of mv(DR,DC) vectors for every match/2 pair in Pairs.
    gridobjmatch_move_vectors/2,
% Succeed if every pair in Pairs has the same move vector mv(DR,DC).
    gridobjmatch_constant_move/2,
% Sorted list of cm(OldColor,NewColor) inferred from color-changing pairs.
    gridobjmatch_infer_color_map/2,
% Objects in Objs2 whose color does not appear in any object in Objs1.
    gridobjmatch_appeared/3,
% Objects in Objs1 whose color does not appear in any object in Objs2.
    gridobjmatch_disappeared/3,
% Succeed if Objs1 and Objs2 have the same multiset of object colors.
    gridobjmatch_same_structure/2,
% N is the change in object count: length(Objs2) - length(Objs1).
    gridobjmatch_count_change/3
]).
% gridobjmatch.pl - Layer 246: Object Matching and Change Detection (gom_* prefix).
% Fourteen predicates for matching ob(Color,Cells,BBox) object terms between two
% lists and detecting what changed between them.
:- use_module(library(lists), [member/2, subtract/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- PRIVATE HELPERS ---

% gridobjmatch_color_/2: extract Color from an ob/3 term.
gridobjmatch_color_(ob(Color, _, _), Color).

% gridobjmatch_size_/2: cell count of an ob/3 term.
gridobjmatch_size_(ob(_, Cells, _), N) :-
    length(Cells, N).

% gridobjmatch_top_left_/3: top-left corner (R0, C0) of the bounding box of an ob/3 term.
gridobjmatch_top_left_(ob(_, _, r0(R0, C0, _, _)), R0, C0).

% gridobjmatch_centroid_/3: doubled centroid (R0+R1, C0+C1) of an ob/3 term.
% Using the doubled value avoids fractional division while preserving ordering.
gridobjmatch_centroid_(ob(_, _, r0(R0, C0, R1, C1)), CR, CC) :-
    CR is R0 + R1,
    CC is C0 + C1.

% gridobjmatch_select_color_/4: find the first ob in List with Color; return it and remainder.
gridobjmatch_select_color_([O|Rest], Color, O, Rest) :-
    gridobjmatch_color_(O, Color), !.
gridobjmatch_select_color_([O|Rest], Color, Found, [O|Rem]) :-
    gridobjmatch_select_color_(Rest, Color, Found, Rem).

% gridobjmatch_select_size_/4: find the first ob in List with Size; return it and remainder.
gridobjmatch_select_size_([O|Rest], Size, O, Rest) :-
    gridobjmatch_size_(O, Size), !.
gridobjmatch_select_size_([O|Rest], Size, Found, [O|Rem]) :-
    gridobjmatch_select_size_(Rest, Size, Found, Rem).

% gridobjmatch_find_nearest_/3: find the ob in Objs with the smallest doubled-centroid
% Manhattan distance to O1. Ties broken by canonical term order via msort.
gridobjmatch_find_nearest_(O1, Objs, Best) :-
    gridobjmatch_centroid_(O1, R1, C1),
    findall(D-O2,
        (member(O2, Objs),
         gridobjmatch_centroid_(O2, R2, C2),
         D is abs(R2 - R1) + abs(C2 - C1)),
        Pairs),
    msort(Pairs, [_-Best|_]).

% gridobjmatch_remove_once_/3: remove the first occurrence of Elem from List.
gridobjmatch_remove_once_([Elem|Rest], Elem, Rest) :- !.
gridobjmatch_remove_once_([O|Rest], Elem, [O|Rem]) :-
    gridobjmatch_remove_once_(Rest, Elem, Rem).

% gridobjmatch_has_vector_/2: succeed if match pair P has move vector V.
gridobjmatch_has_vector_(V, P) :- gridobjmatch_move_vector(P, V).

% gridobjmatch_new_color_/2: succeed if O has a color not in ColorList (used with include/3).
gridobjmatch_new_color_(ColorList, O) :-
    gridobjmatch_color_(O, C),
    \+ member(C, ColorList).

% gridobjmatch_gone_color_/2: succeed if O has a color not in ColorList (used with include/3).
gridobjmatch_gone_color_(ColorList, O) :-
    gridobjmatch_color_(O, C),
    \+ member(C, ColorList).

% --- PUBLIC PREDICATES ---

% gridobjmatch_match_color(+Objs1, +Objs2, -Pairs)
% Pairs is a list of match(O1, O2) terms. For each O1 in Objs1 the first object
% in Objs2 sharing the same color is consumed as its match. Objects in either
% list that cannot be matched are silently dropped.
gridobjmatch_match_color([], _, []).
gridobjmatch_match_color([O1|Rest], Objs2, Pairs) :-
    gridobjmatch_color_(O1, Color),
    (gridobjmatch_select_color_(Objs2, Color, O2, Objs2Rem) ->
        Pairs = [match(O1, O2)|MorePairs],
        gridobjmatch_match_color(Rest, Objs2Rem, MorePairs)
    ;
        gridobjmatch_match_color(Rest, Objs2, Pairs)
    ).

% gridobjmatch_match_nearest(+Objs1, +Objs2, -Pairs)
% Pairs is a list of match(O1, O2) terms. For each O1 in Objs1 the object in
% Objs2 with the smallest doubled-centroid Manhattan distance is greedily consumed.
% When Objs2 is exhausted the remaining Objs1 are unmatched.
gridobjmatch_match_nearest([], _, []).
gridobjmatch_match_nearest([_|_], [], []).
gridobjmatch_match_nearest([O1|Rest], Objs2, [match(O1, Best)|Pairs]) :-
    Objs2 \= [],
    gridobjmatch_find_nearest_(O1, Objs2, Best),
    gridobjmatch_remove_once_(Objs2, Best, Objs2Rem),
    gridobjmatch_match_nearest(Rest, Objs2Rem, Pairs).

% gridobjmatch_match_size(+Objs1, +Objs2, -Pairs)
% Pairs is a list of match(O1, O2) terms. For each O1 in Objs1 the first object
% in Objs2 with the same cell count is consumed as its match. Unmatched objects
% are dropped.
gridobjmatch_match_size([], _, []).
gridobjmatch_match_size([O1|Rest], Objs2, Pairs) :-
    gridobjmatch_size_(O1, Size),
    (gridobjmatch_select_size_(Objs2, Size, O2, Objs2Rem) ->
        Pairs = [match(O1, O2)|MorePairs],
        gridobjmatch_match_size(Rest, Objs2Rem, MorePairs)
    ;
        gridobjmatch_match_size(Rest, Objs2, Pairs)
    ).

% gridobjmatch_unmatched_a(+Pairs, +Objs1, -Unmatched)
% Unmatched is the sub-list of Objs1 that does not appear as the first element
% of any match/2 term in Pairs.
gridobjmatch_unmatched_a(Pairs, Objs1, Unmatched) :-
    findall(O1, member(match(O1, _), Pairs), Matched),
    subtract(Objs1, Matched, Unmatched).

% gridobjmatch_unmatched_b(+Pairs, +Objs2, -Unmatched)
% Unmatched is the sub-list of Objs2 that does not appear as the second element
% of any match/2 term in Pairs.
gridobjmatch_unmatched_b(Pairs, Objs2, Unmatched) :-
    findall(O2, member(match(_, O2), Pairs), Matched),
    subtract(Objs2, Matched, Unmatched).

% gridobjmatch_color_diff(+Pairs, -Same, -Diff)
% Same is the sub-list of Pairs where the two objects share the same color.
% Diff is the sub-list where the colors differ.
gridobjmatch_color_diff([], [], []).
gridobjmatch_color_diff([M|Rest], Same, Diff) :-
    M = match(O1, O2),
    gridobjmatch_color_(O1, C1),
    gridobjmatch_color_(O2, C2),
    gridobjmatch_color_diff(Rest, RestSame, RestDiff),
    (C1 = C2 ->
        Same = [M|RestSame], Diff = RestDiff
    ;
        Same = RestSame, Diff = [M|RestDiff]
    ).

% gridobjmatch_move_vector(+Pair, -mv(DR, DC))
% Pair is match(O1, O2). DR and DC are the differences in the top-left
% bounding-box row and column from O1 to O2 (positive = down or right).
gridobjmatch_move_vector(match(O1, O2), mv(DR, DC)) :-
    gridobjmatch_top_left_(O1, R1, C1),
    gridobjmatch_top_left_(O2, R2, C2),
    DR is R2 - R1,
    DC is C2 - C1.

% gridobjmatch_move_vectors(+Pairs, -Vectors)
% Vectors is the list of mv/2 terms computed by gridobjmatch_move_vector/2 for each pair.
gridobjmatch_move_vectors(Pairs, Vectors) :-
    maplist(gridobjmatch_move_vector, Pairs, Vectors).

% gridobjmatch_constant_move(+Pairs, -mv(DR, DC))
% Succeed if every pair in Pairs has the same move vector mv(DR, DC).
% Fails for an empty list (no evidence of any consistent move).
gridobjmatch_constant_move([P|Rest], V) :-
    gridobjmatch_move_vector(P, V),
    maplist(gridobjmatch_has_vector_(V), Rest).

% gridobjmatch_infer_color_map(+Pairs, -Map)
% Map is a sorted, deduplicated list of cm(OldColor, NewColor) for each matched
% pair where the two objects have different colors.
gridobjmatch_infer_color_map(Pairs, Map) :-
    findall(cm(C1, C2),
        (member(match(O1, O2), Pairs),
         gridobjmatch_color_(O1, C1),
         gridobjmatch_color_(O2, C2),
         C1 \= C2),
        Raw),
    sort(Raw, Map).

% gridobjmatch_appeared(+Objs1, +Objs2, -Appeared)
% Appeared is the sub-list of Objs2 containing objects whose color does not
% appear in any object in Objs1 (brand-new colors in Objs2).
gridobjmatch_appeared(Objs1, Objs2, Appeared) :-
    findall(C, (member(O, Objs1), gridobjmatch_color_(O, C)), Cs1),
    include(gridobjmatch_new_color_(Cs1), Objs2, Appeared).

% gridobjmatch_disappeared(+Objs1, +Objs2, -Disappeared)
% Disappeared is the sub-list of Objs1 containing objects whose color does not
% appear in any object in Objs2 (colors lost from Objs1 to Objs2).
gridobjmatch_disappeared(Objs1, Objs2, Disappeared) :-
    findall(C, (member(O, Objs2), gridobjmatch_color_(O, C)), Cs2),
    include(gridobjmatch_gone_color_(Cs2), Objs1, Disappeared).

% gridobjmatch_same_structure(+Objs1, +Objs2)
% Succeed if Objs1 and Objs2 contain the same multiset of object colors.
% Order within the lists does not matter.
gridobjmatch_same_structure(Objs1, Objs2) :-
    findall(C, (member(O, Objs1), gridobjmatch_color_(O, C)), Cs1),
    findall(C, (member(O, Objs2), gridobjmatch_color_(O, C)), Cs2),
    msort(Cs1, Sorted),
    msort(Cs2, Sorted).

% gridobjmatch_count_change(+Objs1, +Objs2, -N)
% N is the change in object count: length(Objs2) - length(Objs1).
% Positive N means objects were added; negative means removed; zero means same.
gridobjmatch_count_change(Objs1, Objs2, N) :-
    length(Objs1, N1),
    length(Objs2, N2),
    N is N2 - N1.
