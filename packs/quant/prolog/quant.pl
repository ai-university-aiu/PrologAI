% Module declaration: quant exports all qn_* predicates.
:- module(quant, [
    quant_histogram/2,
    quant_group_by_color/2,
    quant_group_by_size/2,
    quant_group_by_shape/2,
    quant_most_frequent_color/2,
    quant_least_frequent_color/2,
    quant_unique_shapes/2,
    quant_count_where/3,
    quant_all_same_color/1,
    quant_all_same_size/1,
    quant_all_same_shape/1,
    quant_colors_match/2,
    quant_shapes_match/2,
    quant_sizes_match/2,
    quant_exactly_n/3,
    quant_at_least_n/3,
    quant_max_color_count/2,
    quant_min_color_count/2
]).

% Import list utilities.
:- use_module(library(lists),
    [member/2, append/3, last/2,
     numlist/3, min_list/2, max_list/2,
     sum_list/2, flatten/2, delete/3]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4, include/3]).
% Import pairs utilities.
:- use_module(library(pairs), [pairs_keys/2, pairs_values/2, group_pairs_by_key/2]).
% Import scene pack for obj/2 access predicates.
:- use_module(library(scene)).


% HISTOGRAM
% quant_histogram(+Objects, -Pairs): list of Color-Count pairs for all object colors.
quant_histogram(Objects, Pairs) :-
% Collect all colors from the objects.
    maplist(scene_obj_color, Objects, Colors),
% Sort colors to get the unique set.
    sort(Colors, UniqueColors),
% Build one Color-Count pair per unique color.
    maplist(color_count_pair(Objects), UniqueColors, Pairs).

% color_count_pair(+Objects, +Color, -Color-Count): helper for quant_histogram.
color_count_pair(Objects, Color, Color-Count) :-
% Count how many objects have this color.
    scene_count_of_color(Objects, Color, Count).


% GROUPING
% quant_group_by_color(+Objects, -Groups): list of Color-[Objects] pairs.
quant_group_by_color(Objects, Groups) :-
% Build Color-Obj pairs, sort by color key.
    maplist(obj_to_color_pair, Objects, Pairs),
% Sort by key so group_pairs_by_key works.
    msort(Pairs, Sorted),
% Group all objects under their color key.
    group_pairs_by_key(Sorted, Groups).

% obj_to_color_pair(+Obj, -Color-Obj): build a keyed pair for grouping.
obj_to_color_pair(Obj, Color-Obj) :-
% Extract the color as the grouping key.
    scene_obj_color(Obj, Color).

% quant_group_by_size(+Objects, -Groups): list of Size-[Objects] pairs.
quant_group_by_size(Objects, Groups) :-
% Build Size-Obj pairs.
    maplist(obj_to_size_pair, Objects, Pairs),
% Sort by integer key for correct grouping.
    msort(Pairs, Sorted),
% Group all objects sharing the same size.
    group_pairs_by_key(Sorted, Groups).

% obj_to_size_pair(+Obj, -Size-Obj): build a size-keyed pair for grouping.
obj_to_size_pair(Obj, Size-Obj) :-
% Compute cell count as the grouping key.
    scene_obj_size(Obj, Size).

% quant_group_by_shape(+Objects, -Groups): list of Shape-[Objects] pairs.
quant_group_by_shape(Objects, Groups) :-
% Build Shape-Obj pairs where Shape is the normalized cell set.
    maplist(obj_to_shape_pair, Objects, Pairs),
% Sort by term order (shapes are lists of r/2 terms, comparable).
    msort(Pairs, Sorted),
% Group all objects sharing the same normalized shape.
    group_pairs_by_key(Sorted, Groups).

% obj_to_shape_pair(+Obj, -Shape-Obj): build a shape-keyed pair for grouping.
obj_to_shape_pair(Obj, Shape-Obj) :-
% Normalize the cell set as the grouping key.
    scene_obj_shape(Obj, Shape).


% FREQUENCY ANALYSIS
% quant_most_frequent_color(+Objects, -Color): color occurring in the most objects.
quant_most_frequent_color(Objects, Color) :-
% Build the histogram of Color-Count pairs.
    quant_histogram(Objects, Histogram),
% Select the pair with the maximum count.
    max_member(_-Color, Histogram).

% quant_least_frequent_color(+Objects, -Color): color occurring in the fewest objects.
quant_least_frequent_color(Objects, Color) :-
% Build the histogram of Color-Count pairs.
    quant_histogram(Objects, Histogram),
% Select the pair with the minimum count.
    min_member(_-Color, Histogram).

% quant_max_color_count(+Objects, -Max): the maximum count among all colors.
quant_max_color_count(Objects, Max) :-
% Build Color-Count histogram.
    quant_histogram(Objects, Histogram),
% Extract just the counts.
    pairs_keys(Histogram, Counts),
% Find the maximum count.
    max_list(Counts, Max).

% quant_min_color_count(+Objects, -Min): the minimum count among all colors.
quant_min_color_count(Objects, Min) :-
% Build Color-Count histogram.
    quant_histogram(Objects, Histogram),
% Extract just the counts.
    pairs_keys(Histogram, Counts),
% Find the minimum count.
    min_list(Counts, Min).


% UNIQUE SHAPES
% quant_unique_shapes(+Objects, -Shapes): sorted list of distinct normalized shapes.
quant_unique_shapes(Objects, Shapes) :-
% Compute the normalized shape of every object.
    maplist(scene_obj_shape, Objects, RawShapes),
% Remove duplicates, keeping canonical order.
    sort(RawShapes, Shapes).


% CONDITIONAL COUNTING
% quant_count_where(+Objects, +Goal, -Count): count objects for which call(Goal, Obj) succeeds.
quant_count_where(Objects, Goal, Count) :-
% Filter objects for which Goal holds.
    include(Goal, Objects, Matching),
% Count the matching objects.
    length(Matching, Count).


% UNIFORMITY TESTS
% quant_all_same_color(+Objects): succeeds if all objects have the same color.
quant_all_same_color([]).
% Base: empty list trivially satisfies the condition.
quant_all_same_color([_]).
% Single-element list: trivially true.
quant_all_same_color([H|T]) :-
% Get the reference color from the first object.
    scene_obj_color(H, C),
% Verify every remaining object has the same color.
    maplist(has_color_eq(C), T).

% has_color_eq(+Color, +Obj): succeeds if Obj has Color.
has_color_eq(Color, Obj) :-
% Delegate to scene_obj_color for color extraction.
    scene_obj_color(Obj, Color).

% quant_all_same_size(+Objects): succeeds if all objects have the same cell count.
quant_all_same_size([]).
% Empty list: trivially true.
quant_all_same_size([_]).
% Single element: trivially true.
quant_all_same_size([H|T]) :-
% Get the reference size from the first object.
    scene_obj_size(H, S),
% Verify every remaining object has the same size.
    maplist(has_size_eq(S), T).

% has_size_eq(+Size, +Obj): succeeds if Obj has Size cells.
has_size_eq(Size, Obj) :-
% Delegate to scene_obj_size for size extraction.
    scene_obj_size(Obj, Size).

% quant_all_same_shape(+Objects): succeeds if all objects have the same normalized shape.
quant_all_same_shape([]).
% Empty list: trivially true.
quant_all_same_shape([_]).
% Single element: trivially true.
quant_all_same_shape([H|T]) :-
% Compute the reference normalized shape from the first object.
    scene_obj_shape(H, Shape),
% Verify every remaining object has the same normalized shape.
    maplist(has_shape_eq(Shape), T).

% has_shape_eq(+Shape, +Obj): succeeds if Obj's normalized shape equals Shape.
has_shape_eq(Shape, Obj) :-
% Normalize and compare.
    scene_obj_shape(Obj, Shape).


% MULTISET MATCHING
% quant_colors_match(+Objects1, +Objects2): same multiset of colors in both lists.
quant_colors_match(Objs1, Objs2) :-
% Collect colors from first list.
    maplist(scene_obj_color, Objs1, Colors1),
% Collect colors from second list.
    maplist(scene_obj_color, Objs2, Colors2),
% Sort both (multiset sort) and compare.
    msort(Colors1, S1),
    msort(Colors2, S2),
% Multiset equality: sorted lists are identical.
    S1 == S2.

% quant_shapes_match(+Objects1, +Objects2): same multiset of normalized shapes.
quant_shapes_match(Objs1, Objs2) :-
% Compute normalized shapes of both lists.
    maplist(scene_obj_shape, Objs1, Shapes1),
    maplist(scene_obj_shape, Objs2, Shapes2),
% Sort both shape lists for multiset comparison.
    msort(Shapes1, S1),
    msort(Shapes2, S2),
% Multiset equality.
    S1 == S2.

% quant_sizes_match(+Objects1, +Objects2): same multiset of sizes.
quant_sizes_match(Objs1, Objs2) :-
% Compute sizes of both lists.
    maplist(scene_obj_size, Objs1, Sizes1),
    maplist(scene_obj_size, Objs2, Sizes2),
% Sort both for multiset comparison.
    msort(Sizes1, S1),
    msort(Sizes2, S2),
% Multiset equality.
    S1 == S2.


% THRESHOLD COUNTING
% quant_exactly_n(+Objects, +Pred, +N): exactly N objects satisfy Pred.
quant_exactly_n(Objects, Pred, N) :-
% Count matching objects.
    quant_count_where(Objects, Pred, Count),
% Assert equality with the target count.
    Count =:= N.

% quant_at_least_n(+Objects, +Pred, +N): at least N objects satisfy Pred.
quant_at_least_n(Objects, Pred, N) :-
% Count matching objects.
    quant_count_where(Objects, Pred, Count),
% Assert count is at least N.
    Count >= N.
