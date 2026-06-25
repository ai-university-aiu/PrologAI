% Module declaration: quant exports all qn_* predicates.
:- module(quant, [
    qn_histogram/2,
    qn_group_by_color/2,
    qn_group_by_size/2,
    qn_group_by_shape/2,
    qn_most_frequent_color/2,
    qn_least_frequent_color/2,
    qn_unique_shapes/2,
    qn_count_where/3,
    qn_all_same_color/1,
    qn_all_same_size/1,
    qn_all_same_shape/1,
    qn_colors_match/2,
    qn_shapes_match/2,
    qn_sizes_match/2,
    qn_exactly_n/3,
    qn_at_least_n/3,
    qn_max_color_count/2,
    qn_min_color_count/2
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
% qn_histogram(+Objects, -Pairs): list of Color-Count pairs for all object colors.
qn_histogram(Objects, Pairs) :-
% Collect all colors from the objects.
    maplist(sc_obj_color, Objects, Colors),
% Sort colors to get the unique set.
    sort(Colors, UniqueColors),
% Build one Color-Count pair per unique color.
    maplist(color_count_pair(Objects), UniqueColors, Pairs).

% color_count_pair(+Objects, +Color, -Color-Count): helper for qn_histogram.
color_count_pair(Objects, Color, Color-Count) :-
% Count how many objects have this color.
    sc_count_of_color(Objects, Color, Count).


% GROUPING
% qn_group_by_color(+Objects, -Groups): list of Color-[Objects] pairs.
qn_group_by_color(Objects, Groups) :-
% Build Color-Obj pairs, sort by color key.
    maplist(obj_to_color_pair, Objects, Pairs),
% Sort by key so group_pairs_by_key works.
    msort(Pairs, Sorted),
% Group all objects under their color key.
    group_pairs_by_key(Sorted, Groups).

% obj_to_color_pair(+Obj, -Color-Obj): build a keyed pair for grouping.
obj_to_color_pair(Obj, Color-Obj) :-
% Extract the color as the grouping key.
    sc_obj_color(Obj, Color).

% qn_group_by_size(+Objects, -Groups): list of Size-[Objects] pairs.
qn_group_by_size(Objects, Groups) :-
% Build Size-Obj pairs.
    maplist(obj_to_size_pair, Objects, Pairs),
% Sort by integer key for correct grouping.
    msort(Pairs, Sorted),
% Group all objects sharing the same size.
    group_pairs_by_key(Sorted, Groups).

% obj_to_size_pair(+Obj, -Size-Obj): build a size-keyed pair for grouping.
obj_to_size_pair(Obj, Size-Obj) :-
% Compute cell count as the grouping key.
    sc_obj_size(Obj, Size).

% qn_group_by_shape(+Objects, -Groups): list of Shape-[Objects] pairs.
qn_group_by_shape(Objects, Groups) :-
% Build Shape-Obj pairs where Shape is the normalized cell set.
    maplist(obj_to_shape_pair, Objects, Pairs),
% Sort by term order (shapes are lists of r/2 terms, comparable).
    msort(Pairs, Sorted),
% Group all objects sharing the same normalized shape.
    group_pairs_by_key(Sorted, Groups).

% obj_to_shape_pair(+Obj, -Shape-Obj): build a shape-keyed pair for grouping.
obj_to_shape_pair(Obj, Shape-Obj) :-
% Normalize the cell set as the grouping key.
    sc_obj_shape(Obj, Shape).


% FREQUENCY ANALYSIS
% qn_most_frequent_color(+Objects, -Color): color occurring in the most objects.
qn_most_frequent_color(Objects, Color) :-
% Build the histogram of Color-Count pairs.
    qn_histogram(Objects, Histogram),
% Select the pair with the maximum count.
    max_member(_-Color, Histogram).

% qn_least_frequent_color(+Objects, -Color): color occurring in the fewest objects.
qn_least_frequent_color(Objects, Color) :-
% Build the histogram of Color-Count pairs.
    qn_histogram(Objects, Histogram),
% Select the pair with the minimum count.
    min_member(_-Color, Histogram).

% qn_max_color_count(+Objects, -Max): the maximum count among all colors.
qn_max_color_count(Objects, Max) :-
% Build Color-Count histogram.
    qn_histogram(Objects, Histogram),
% Extract just the counts.
    pairs_keys(Histogram, Counts),
% Find the maximum count.
    max_list(Counts, Max).

% qn_min_color_count(+Objects, -Min): the minimum count among all colors.
qn_min_color_count(Objects, Min) :-
% Build Color-Count histogram.
    qn_histogram(Objects, Histogram),
% Extract just the counts.
    pairs_keys(Histogram, Counts),
% Find the minimum count.
    min_list(Counts, Min).


% UNIQUE SHAPES
% qn_unique_shapes(+Objects, -Shapes): sorted list of distinct normalized shapes.
qn_unique_shapes(Objects, Shapes) :-
% Compute the normalized shape of every object.
    maplist(sc_obj_shape, Objects, RawShapes),
% Remove duplicates, keeping canonical order.
    sort(RawShapes, Shapes).


% CONDITIONAL COUNTING
% qn_count_where(+Objects, +Goal, -Count): count objects for which call(Goal, Obj) succeeds.
qn_count_where(Objects, Goal, Count) :-
% Filter objects for which Goal holds.
    include(Goal, Objects, Matching),
% Count the matching objects.
    length(Matching, Count).


% UNIFORMITY TESTS
% qn_all_same_color(+Objects): succeeds if all objects have the same color.
qn_all_same_color([]).
% Base: empty list trivially satisfies the condition.
qn_all_same_color([_]).
% Single-element list: trivially true.
qn_all_same_color([H|T]) :-
% Get the reference color from the first object.
    sc_obj_color(H, C),
% Verify every remaining object has the same color.
    maplist(has_color_eq(C), T).

% has_color_eq(+Color, +Obj): succeeds if Obj has Color.
has_color_eq(Color, Obj) :-
% Delegate to sc_obj_color for color extraction.
    sc_obj_color(Obj, Color).

% qn_all_same_size(+Objects): succeeds if all objects have the same cell count.
qn_all_same_size([]).
% Empty list: trivially true.
qn_all_same_size([_]).
% Single element: trivially true.
qn_all_same_size([H|T]) :-
% Get the reference size from the first object.
    sc_obj_size(H, S),
% Verify every remaining object has the same size.
    maplist(has_size_eq(S), T).

% has_size_eq(+Size, +Obj): succeeds if Obj has Size cells.
has_size_eq(Size, Obj) :-
% Delegate to sc_obj_size for size extraction.
    sc_obj_size(Obj, Size).

% qn_all_same_shape(+Objects): succeeds if all objects have the same normalized shape.
qn_all_same_shape([]).
% Empty list: trivially true.
qn_all_same_shape([_]).
% Single element: trivially true.
qn_all_same_shape([H|T]) :-
% Compute the reference normalized shape from the first object.
    sc_obj_shape(H, Shape),
% Verify every remaining object has the same normalized shape.
    maplist(has_shape_eq(Shape), T).

% has_shape_eq(+Shape, +Obj): succeeds if Obj's normalized shape equals Shape.
has_shape_eq(Shape, Obj) :-
% Normalize and compare.
    sc_obj_shape(Obj, Shape).


% MULTISET MATCHING
% qn_colors_match(+Objects1, +Objects2): same multiset of colors in both lists.
qn_colors_match(Objs1, Objs2) :-
% Collect colors from first list.
    maplist(sc_obj_color, Objs1, Colors1),
% Collect colors from second list.
    maplist(sc_obj_color, Objs2, Colors2),
% Sort both (multiset sort) and compare.
    msort(Colors1, S1),
    msort(Colors2, S2),
% Multiset equality: sorted lists are identical.
    S1 == S2.

% qn_shapes_match(+Objects1, +Objects2): same multiset of normalized shapes.
qn_shapes_match(Objs1, Objs2) :-
% Compute normalized shapes of both lists.
    maplist(sc_obj_shape, Objs1, Shapes1),
    maplist(sc_obj_shape, Objs2, Shapes2),
% Sort both shape lists for multiset comparison.
    msort(Shapes1, S1),
    msort(Shapes2, S2),
% Multiset equality.
    S1 == S2.

% qn_sizes_match(+Objects1, +Objects2): same multiset of sizes.
qn_sizes_match(Objs1, Objs2) :-
% Compute sizes of both lists.
    maplist(sc_obj_size, Objs1, Sizes1),
    maplist(sc_obj_size, Objs2, Sizes2),
% Sort both for multiset comparison.
    msort(Sizes1, S1),
    msort(Sizes2, S2),
% Multiset equality.
    S1 == S2.


% THRESHOLD COUNTING
% qn_exactly_n(+Objects, +Pred, +N): exactly N objects satisfy Pred.
qn_exactly_n(Objects, Pred, N) :-
% Count matching objects.
    qn_count_where(Objects, Pred, Count),
% Assert equality with the target count.
    Count =:= N.

% qn_at_least_n(+Objects, +Pred, +N): at least N objects satisfy Pred.
qn_at_least_n(Objects, Pred, N) :-
% Count matching objects.
    qn_count_where(Objects, Pred, Count),
% Assert count is at least N.
    Count >= N.
