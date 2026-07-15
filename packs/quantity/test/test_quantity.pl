:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(grid)).
:- use_module(library(scene)).
:- use_module('../prolog/quantity').

% FIXTURE: five objects with known colors and sizes.
% Two red (color 1) single-cell objects, one red 2-cell, one blue (2) L-shape, one green (3) 2-cell.
fixture_objects([
    obj(1, [r(0,0)]),
    obj(1, [r(1,0)]),
    obj(1, [r(2,0), r(2,1)]),
    obj(2, [r(0,2), r(0,3), r(1,2)]),
    obj(3, [r(3,0), r(3,1)])
]).


:- begin_tests(quantity_histogram).

% Histogram has one entry per unique color.
test(histogram_colors, nondet) :-
    fixture_objects(Objs),
    quantity_histogram(Objs, Hist),
    pairs_keys(Hist, Colors),
    msort(Colors, [1,2,3]).

% Color 1 appears in 3 objects.
test(histogram_count_1, nondet) :-
    fixture_objects(Objs),
    quantity_histogram(Objs, Hist),
    member(1-3, Hist).

% Color 2 appears in 1 object.
test(histogram_count_2, nondet) :-
    fixture_objects(Objs),
    quantity_histogram(Objs, Hist),
    member(2-1, Hist).

% Histogram of empty list is empty.
test(histogram_empty) :-
    quantity_histogram([], []).

:- end_tests(quantity_histogram).


:- begin_tests(quantity_grouping).

% Group by color: 3 groups (1, 2, 3).
test(group_by_color_count, nondet) :-
    fixture_objects(Objs),
    quantity_group_by_color(Objs, Groups),
    length(Groups, 3).

% Group by color: color 1 group has 3 objects.
test(group_by_color_1, nondet) :-
    fixture_objects(Objs),
    quantity_group_by_color(Objs, Groups),
    member(1-ColorGroup, Groups),
    length(ColorGroup, 3).

% Group by size: single-cell group has 2 objects (both red single-cells).
test(group_by_size_1, nondet) :-
    fixture_objects(Objs),
    quantity_group_by_size(Objs, Groups),
    member(1-SizeGroup, Groups),
    length(SizeGroup, 2).

% Group by shape: two-cell horizontal shape [r(0,0),r(0,1)] appears in 2 objects.
test(group_by_shape_horizontal, nondet) :-
    fixture_objects(Objs),
    quantity_group_by_shape(Objs, Groups),
    member([r(0,0),r(0,1)]-ShapeGroup, Groups),
    length(ShapeGroup, 2).

:- end_tests(quantity_grouping).


:- begin_tests(quantity_frequency).

% Most frequent color in fixture is 1 (appears 3 times).
test(most_frequent) :-
    fixture_objects(Objs),
    quantity_most_frequent_color(Objs, 1).

% Least frequent colors are 2 and 3 (each appears once); min_member picks deterministically.
test(least_frequent, nondet) :-
    fixture_objects(Objs),
    quantity_least_frequent_color(Objs, C),
    member(C, [2,3]).

% Max color count is 3.
test(max_count) :-
    fixture_objects(Objs),
    quantity_max_color_count(Objs, 3).

% Min color count is 1.
test(min_count) :-
    fixture_objects(Objs),
    quantity_min_color_count(Objs, 1).

:- end_tests(quantity_frequency).


:- begin_tests(quantity_shapes).

% Unique shapes: single-cell, two-cell-h, L-shape are distinct.
test(unique_shapes_count, nondet) :-
    fixture_objects(Objs),
    quantity_unique_shapes(Objs, Shapes),
    length(Shapes, 3).

% Single-cell shape [r(0,0)] is in the unique set.
test(unique_shapes_has_single, nondet) :-
    fixture_objects(Objs),
    quantity_unique_shapes(Objs, Shapes),
    member([r(0,0)], Shapes).

:- end_tests(quantity_shapes).


:- begin_tests(quantity_count_where).

% Count objects of color 1: should be 3.
test(count_where_color1) :-
    fixture_objects(Objs),
    quantity_count_where(Objs, has_color_1, Count),
    Count =:= 3.

% Count objects of size 2: red 2-cell + green 2-cell = 2.
test(count_where_size2) :-
    fixture_objects(Objs),
    quantity_count_where(Objs, has_size_2, Count),
    Count =:= 2.

:- end_tests(quantity_count_where).

% Helper predicates for count_where tests (named, not lambdas).
has_color_1(Obj) :- scene_obj_color(Obj, 1).
has_size_2(Obj) :- scene_obj_size(Obj, 2).


:- begin_tests(quantity_uniformity).

% All same color: uniform list.
test(all_same_color_yes) :-
    quantity_all_same_color([obj(2,[r(0,0)]), obj(2,[r(1,1)])]).

% All same color: fails when colors differ.
test(all_same_color_no) :-
    \+ quantity_all_same_color([obj(1,[r(0,0)]), obj(2,[r(1,1)])]).

% All same size: two single-cell objects.
test(all_same_size_yes) :-
    quantity_all_same_size([obj(1,[r(0,0)]), obj(2,[r(1,1)])]).

% All same size: fails when sizes differ.
test(all_same_size_no) :-
    \+ quantity_all_same_size([obj(1,[r(0,0)]), obj(1,[r(1,1),r(2,1)])]).

% All same shape: two vertical 2-cell objects.
test(all_same_shape_yes) :-
    quantity_all_same_shape([obj(1,[r(0,0),r(1,0)]), obj(2,[r(3,5),r(4,5)])]).

% All same shape: fails when shapes differ.
test(all_same_shape_no) :-
    \+ quantity_all_same_shape([obj(1,[r(0,0)]), obj(1,[r(0,0),r(0,1)])]).

% All same color: empty list trivially succeeds.
test(all_same_color_empty) :-
    quantity_all_same_color([]).

:- end_tests(quantity_uniformity).


:- begin_tests(quantity_matching).

% Colors match: same multiset.
test(colors_match_yes) :-
    quantity_colors_match([obj(1,[r(0,0)]),obj(2,[r(1,0)])],
                    [obj(2,[r(0,1)]),obj(1,[r(2,0)])]).

% Colors match: fails with different multisets.
test(colors_match_no) :-
    \+ quantity_colors_match([obj(1,[r(0,0)])], [obj(2,[r(0,0)])]).

% Shapes match: same multiset of normalized shapes.
test(shapes_match_yes) :-
    quantity_shapes_match([obj(1,[r(0,0)]), obj(2,[r(5,5)])],
                    [obj(3,[r(2,2)]), obj(4,[r(0,7)])]).

% Shapes match: fails when shapes differ.
test(shapes_match_no) :-
    \+ quantity_shapes_match([obj(1,[r(0,0)])], [obj(1,[r(0,0),r(0,1)])]).

% Sizes match: same multiset of sizes.
test(sizes_match_yes) :-
    quantity_sizes_match([obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)])],
                   [obj(3,[r(5,5)]), obj(4,[r(3,3),r(4,3)])]).

:- end_tests(quantity_matching).


:- begin_tests(quantity_threshold).

% Exactly 3 objects have color 1.
test(exactly_n_yes) :-
    fixture_objects(Objs),
    quantity_exactly_n(Objs, has_color_1, 3).

% Not exactly 2 objects have color 1.
test(exactly_n_no) :-
    fixture_objects(Objs),
    \+ quantity_exactly_n(Objs, has_color_1, 2).

% At least 2 objects have color 1.
test(at_least_n_yes) :-
    fixture_objects(Objs),
    quantity_at_least_n(Objs, has_color_1, 2).

% Not at least 4 objects have color 1.
test(at_least_n_no) :-
    fixture_objects(Objs),
    \+ quantity_at_least_n(Objs, has_color_1, 4).

:- end_tests(quantity_threshold).
