% Module declaration with all fourteen public predicates.
:- module(multi_pair, [
% Assign consistent identity labels to objects across all training pair inputs.
    multi_pair_track_objects/2,
% Find objects that appear in every training pair input with the same properties.
    multi_pair_invariant_objects/2,
% Classify objects as content (transform targets) or markers (rule parameters).
    multi_pair_role_objects/3,
% Build the cross-pair object correspondence matrix for every pair of inputs.
    multi_pair_cross_pair_match/2,
% Extract all ob/3 objects from all pair inputs as a flat list with pair index.
    multi_pair_all_input_objects/2,
% Count how many training pairs contain an object of a given color.
    multi_pair_color_frequency/3,
% Find colors that appear in every training pair input.
    multi_pair_universal_colors/2,
% Find colors that appear in only some training pair inputs.
    multi_pair_variable_colors/2,
% Find objects (by color) that are present in the input but absent in the output.
    multi_pair_disappeared_objects/2,
% Find objects (by color) that are absent in the input but present in the output.
    multi_pair_appeared_objects/2,
% Find objects whose color is the same across all inputs (stable color identity).
    multi_pair_stable_color_objects/2,
% Find the most common object count across all training pair inputs.
    multi_pair_modal_object_count/2,
% Check if the same number of distinct objects appears in every training pair input.
    multi_pair_consistent_count/1,
% Find the color that appears in exactly one input per pair (the unique marker color).
    multi_pair_singleton_color/2
]).
% multipair.pl - Layer 251: Multi-Pair Object Tracking (mp_* prefix).
% Fourteen predicates for tracking object identity and correspondence across
% multiple training pairs simultaneously. Objects are ob(Color, Cells, BBox) terms
% where BBox = r0(R0,C0,R1,C1). Training pairs are pair(InputGrid, OutputGrid) terms.
% This pack uses color as the primary object identity proxy (no connected-component
% computation is performed here; callers may pass gridobj-extracted object lists).
% For direct grid analysis, objects are approximated by their dominant color.
:- use_module(library(lists), [member/2, subtract/3, numlist/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- PRIVATE HELPERS ---

% multi_pair_grid_colors_/3: sorted non-bg colors in a grid.
multi_pair_grid_colors_(Grid, BgColor, Colors) :-
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), All),
    sort(All, Colors).

% multi_pair_pair_input_colors_/3: colors in the input grid of a pair.
multi_pair_pair_input_colors_(pair(In, _), BgColor, Colors) :-
    multi_pair_grid_colors_(In, BgColor, Colors).

% multi_pair_pair_output_colors_/3: colors in the output grid of a pair.
multi_pair_pair_output_colors_(pair(_, Out), BgColor, Colors) :-
    multi_pair_grid_colors_(Out, BgColor, Colors).

% multi_pair_color_in_pair_/3: succeed if Color appears in the input of a pair.
multi_pair_color_in_pair_(Color, BgColor, pair(In, _)) :-
    multi_pair_grid_colors_(In, BgColor, Colors),
    member(Color, Colors).

% multi_pair_count_pairs_with_color_/4: count pairs that have Color in their input.
multi_pair_count_pairs_with_color_(Pairs, BgColor, Color, N) :-
    include(multi_pair_color_in_pair_(Color, BgColor), Pairs, Matching),
    length(Matching, N).

% multi_pair_grid_cell_count_/3: count cells of a specific color in a grid.
multi_pair_grid_cell_count_(Grid, Color, N) :-
    findall(_, (member(Row, Grid), member(Color, Row)), Cells),
    length(Cells, N).

% --- PUBLIC PREDICATES ---

% multi_pair_track_objects(+Pairs, -TrackedObjects)
% Assign identity labels (tracked(Idx, Color, PairIdxList)) to colors that appear
% across all training pair inputs. Each tracked object has a unique index, its color,
% and the list of pair indices in which it appears.
multi_pair_track_objects(Pairs, TrackedObjects) :-
    multi_pair_all_input_objects(Pairs, AllObjects),
    findall(Color, member(po(_, Color), AllObjects), AllColors),
    sort(AllColors, UniqueColors),
    length(Pairs, NPairs),
    numlist(1, NPairs, PairIdxs),
    findall(tracked(Idx, Color, PairList),
        (nth0(IdxZ, UniqueColors, Color),
         Idx is IdxZ + 1,
         findall(PIdx, (member(PIdx, PairIdxs),
                        nth1(PIdx, Pairs, pair(In, _)),
                        multi_pair_grid_colors_(In, 0, InColors),
                        member(Color, InColors)), PairList)),
        TrackedObjects).

% multi_pair_all_input_objects(+Pairs, -AllObjects)
% AllObjects is a flat list of po(PairIdx, Color) terms for every non-bg color
% found in each training pair's input grid.
multi_pair_all_input_objects(Pairs, AllObjects) :-
    length(Pairs, N),
    numlist(1, N, Idxs),
    findall(po(Idx, Color),
        (member(Idx, Idxs),
         nth1(Idx, Pairs, pair(In, _)),
         multi_pair_grid_colors_(In, 0, Colors),
         member(Color, Colors)),
        AllObjects).

% multi_pair_invariant_objects(+TrackedObjects, -Objects)
% Objects is the list of tracked/3 terms where the PairList covers ALL training pairs.
% These are objects that appear in every input without exception.
multi_pair_invariant_objects(TrackedObjects, Objects) :-
    (TrackedObjects = [] ->
        Objects = []
    ;
        TrackedObjects = [tracked(_, _, FirstList)|_],
        length(FirstList, NPairs),
        include([tracked(_, _, PL)]>>(length(PL, NPairs)), TrackedObjects, Objects)
    ).

% multi_pair_role_objects(+TrackedObjects, -ContentObjs, -MarkerObjs)
% ContentObjs: objects appearing in EVERY pair (invariant, potential targets).
% MarkerObjs: objects appearing in SOME but not ALL pairs (variable markers).
multi_pair_role_objects(TrackedObjects, ContentObjs, MarkerObjs) :-
    multi_pair_invariant_objects(TrackedObjects, ContentObjs),
    subtract(TrackedObjects, ContentObjs, MarkerObjs).

% multi_pair_cross_pair_match(+Pairs, -MatchMatrix)
% MatchMatrix is a list of match(I, J, CommonColors) terms for every pair (I, J)
% of training pair indices. CommonColors are colors in both pair I and pair J inputs.
multi_pair_cross_pair_match(Pairs, MatchMatrix) :-
    length(Pairs, N),
    numlist(1, N, Idxs),
    findall(match(I, J, Common),
        (member(I, Idxs), member(J, Idxs), I < J,
         nth1(I, Pairs, pair(InI, _)),
         nth1(J, Pairs, pair(InJ, _)),
         multi_pair_grid_colors_(InI, 0, CI),
         multi_pair_grid_colors_(InJ, 0, CJ),
         findall(C, (member(C, CI), member(C, CJ)), Common0),
         sort(Common0, Common)),
        MatchMatrix).

% multi_pair_color_frequency(+Pairs, +Color, -Frequency)
% Frequency is the number of training pair inputs that contain Color.
multi_pair_color_frequency(Pairs, Color, Frequency) :-
    multi_pair_count_pairs_with_color_(Pairs, 0, Color, Frequency).

% multi_pair_universal_colors(+Pairs, -Colors)
% Colors is the list of non-bg colors that appear in EVERY training pair input.
multi_pair_universal_colors([], []).
multi_pair_universal_colors(Pairs, Colors) :-
    Pairs \= [],
    findall(CL, (member(P, Pairs), multi_pair_pair_input_colors_(P, 0, CL)), ColorLists),
    multi_pair_list_intersection_(ColorLists, Colors).

% multi_pair_list_intersection_/2: intersection of a list of lists.
multi_pair_list_intersection_([], []).
multi_pair_list_intersection_([L], L).
multi_pair_list_intersection_([L|Rest], Intersection) :-
    Rest \= [],
    multi_pair_list_intersection_(Rest, RestIntersection),
    findall(X, (member(X, L), member(X, RestIntersection)), Raw),
    sort(Raw, Intersection).

% multi_pair_variable_colors(+Pairs, -Colors)
% Colors is the list of non-bg colors that appear in SOME but not ALL training pair inputs.
multi_pair_variable_colors([], []).
multi_pair_variable_colors(Pairs, Colors) :-
    Pairs \= [],
    findall(CL, (member(P, Pairs), multi_pair_pair_input_colors_(P, 0, CL)), ColorLists),
    findall(C, (member(L, ColorLists), member(C, L)), AllRaw),
    sort(AllRaw, AllColors),
    multi_pair_list_intersection_(ColorLists, Universal),
    subtract(AllColors, Universal, Colors).

% multi_pair_disappeared_objects(+Pairs, -Colors)
% Colors is the sorted list of colors that appear in every input but no output.
multi_pair_disappeared_objects(Pairs, Colors) :-
    multi_pair_universal_colors(Pairs, Universal),
    findall(C,
        (member(C, Universal),
         \+ (member(pair(_, Out), Pairs),
             multi_pair_grid_colors_(Out, 0, OutColors),
             member(C, OutColors))),
        Raw),
    sort(Raw, Colors).

% multi_pair_appeared_objects(+Pairs, -Colors)
% Colors is the sorted list of colors that appear in outputs but in NO input.
multi_pair_appeared_objects(Pairs, Colors) :-
    findall(C, (member(P, Pairs), multi_pair_pair_output_colors_(P, 0, OC), member(C, OC)), OutRaw),
    sort(OutRaw, AllOutColors),
    findall(C, (member(P, Pairs), multi_pair_pair_input_colors_(P, 0, IC), member(C, IC)), InRaw),
    sort(InRaw, AllInColors),
    subtract(AllOutColors, AllInColors, Colors).

% multi_pair_stable_color_objects(+Pairs, -Colors)
% Colors is the list of colors whose frequency is the same in every input
% (i.e., every input has the same number of cells of that color).
multi_pair_stable_color_objects(Pairs, Colors) :-
    multi_pair_universal_colors(Pairs, Universal),
    include([Color]>>(multi_pair_stable_count_(Pairs, Color)), Universal, Colors).

% multi_pair_stable_count_/2: succeed if Color has same cell count in all inputs.
multi_pair_stable_count_(Pairs, Color) :-
    findall(N, (member(pair(In, _), Pairs),
                multi_pair_grid_cell_count_(In, Color, N)), Counts),
    sort(Counts, Sorted),
    Sorted = [_].

% multi_pair_modal_object_count(+Pairs, -Count)
% Count is the most common number of distinct non-bg colors (objects) across
% all training pair inputs. If tied, returns the first (smallest) count.
multi_pair_modal_object_count(Pairs, Count) :-
    findall(N, (member(pair(In, _), Pairs),
                multi_pair_grid_colors_(In, 0, Colors),
                length(Colors, N)), Counts),
    (Counts = [] -> Count = 0 ;
        msort(Counts, Sorted),
        multi_pair_mode_(Sorted, Count)
    ).

% multi_pair_mode_/2: find the most frequent element in a sorted list.
multi_pair_mode_(Sorted, Mode) :-
    findall(N-V, (sort(Sorted, Unique), member(V, Unique),
                   findall(X, (member(X, Sorted), X =:= V), Same),
                   length(Same, N)), Pairs0),
    msort(Pairs0, PairsSorted),
    last(PairsSorted, _-Mode).

% multi_pair_consistent_count(+Pairs)
% Succeed if every training pair input has the same number of distinct non-bg colors.
multi_pair_consistent_count(Pairs) :-
    findall(N, (member(pair(In, _), Pairs),
                multi_pair_grid_colors_(In, 0, Colors),
                length(Colors, N)), Counts),
    sort(Counts, Sorted),
    Sorted = [_].

% multi_pair_singleton_color(+Pairs, -Color)
% Color is a non-bg color that appears in exactly one input across all training pairs.
% If multiple such colors exist, returns all via backtracking; first solution on call.
multi_pair_singleton_color(Pairs, Color) :-
    multi_pair_all_input_objects(Pairs, AllObjects),
    findall(C, member(po(_, C), AllObjects), AllColors),
    sort(AllColors, UniqueColors),
    member(Color, UniqueColors),
    findall(_, (member(po(_, Color), AllObjects)), Occ),
    length(Occ, 1).
