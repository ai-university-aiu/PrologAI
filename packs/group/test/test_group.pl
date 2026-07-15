:- begin_tests(group).
:- use_module('../prolog/group').

% group_by_color/2 - partition by color.
test(by_color_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)]), obj(1,[r(0,1)])],
    group_by_color(Objs, [1-[obj(1,[r(0,0)]),obj(1,[r(0,1)])], 2-[obj(2,[r(1,1)])]]).

test(by_color_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,1)])],
    group_by_color(Objs, [1-[obj(1,[r(0,0)]),obj(1,[r(1,1)])]]).

test(by_color_empty) :-
    group_by_color([], []).

% group_by_size/2 - partition by cell count.
test(by_size_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1),r(1,2)])],
    group_by_size(Objs, [1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1),r(1,2)])]]).

test(by_size_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    group_by_size(Objs, [1-[obj(1,[r(0,0)]),obj(2,[r(1,1)])]]).

test(by_size_empty) :-
    group_by_size([], []).

% group_by_row/2 - partition by minimum row.
test(by_row_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    group_by_row(Objs, [0-[obj(1,[r(0,0)])], 1-[obj(2,[r(1,1)])]]).

test(by_row_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    group_by_row(Objs, [0-[obj(1,[r(0,0)]),obj(2,[r(0,1)])]]).

test(by_row_empty) :-
    group_by_row([], []).

% group_by_col/2 - partition by minimum column.
test(by_col_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,2)])],
    group_by_col(Objs, [0-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,2)])]]).

test(by_col_all_same) :-
    Objs = [obj(1,[r(0,1)]), obj(2,[r(1,1)])],
    group_by_col(Objs, [1-[obj(1,[r(0,1)]),obj(2,[r(1,1)])]]).

test(by_col_single) :-
    group_by_col([obj(3,[r(0,2)])], [2-[obj(3,[r(0,2)])]]).

% group_by_form/2 - partition by origin-normalized cell list.
test(by_form_two) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(2,2),r(2,3)]), obj(3,[r(0,0),r(1,0)])],
    group_by_form(Objs, [[r(0,0),r(0,1)]-[obj(1,[r(0,0),r(0,1)]),obj(2,[r(2,2),r(2,3)])],
                       [r(0,0),r(1,0)]-[obj(3,[r(0,0),r(1,0)])]]).

test(by_form_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    group_by_form(Objs, [[r(0,0)]-[obj(1,[r(0,0)]),obj(2,[r(1,1)])]]).

test(by_form_empty) :-
    group_by_form([], []).

% group_size_of/2 - number of groups.
test(size_of_two) :-
    group_size_of([1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1)])]],  2).

test(size_of_empty) :-
    group_size_of([], 0).

test(size_of_three) :-
    group_size_of([1-[], 2-[], 3-[]], 3).

% group_flatten/2 - flatten groups to flat list.
test(flatten_two_groups) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_flatten([1-[O1,O2], 2-[O3]], [O1,O2,O3]).

test(flatten_empty) :-
    group_flatten([], []).

test(flatten_single_group) :-
    O = obj(1,[r(0,0)]),
    group_flatten([1-[O]], [O]).

% group_largest_group/2 - group with most objects.
test(largest_group_basic) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_largest_group([1-[O1,O2], 2-[O3]], 1-[O1,O2]).

test(largest_group_three) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]), O3 = obj(2,[r(1,2)]), O4 = obj(3,[r(2,2)]),
    group_largest_group([1-[O1], 2-[O2,O3,O4], 3-[O4]], 2-[O2,O3,O4]).

test(largest_group_tie) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_largest_group([1-[O1], 2-[O2]], 1-[O1]).

% group_smallest_group/2 - group with fewest objects.
test(smallest_group_basic) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_smallest_group([1-[O1,O2], 2-[O3]], 2-[O3]).

test(smallest_group_three) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]), O3 = obj(2,[r(2,2)]),
    group_smallest_group([1-[O1], 2-[O2,O3]], 1-[O1]).

test(smallest_group_tie) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_smallest_group([1-[O1], 2-[O2]], 1-[O1]).

% group_singleton_groups/2 - groups with exactly one object.
test(singleton_groups_one) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_singleton_groups([1-[O1,O2], 2-[O3]], [2-[O3]]).

test(singleton_groups_all) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_singleton_groups([1-[O1], 2-[O2]], [1-[O1], 2-[O2]]).

test(singleton_groups_none) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]), O4 = obj(2,[r(1,2)]),
    group_singleton_groups([1-[O1,O2], 2-[O3,O4]], []).

% group_shared_groups/2 - groups with more than one object.
test(shared_groups_one) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_shared_groups([1-[O1,O2], 2-[O3]], [1-[O1,O2]]).

test(shared_groups_none) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_shared_groups([1-[O1], 2-[O2]], []).

test(shared_groups_all) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]), O4 = obj(2,[r(1,2)]),
    group_shared_groups([1-[O1,O2], 2-[O3,O4]], [1-[O1,O2], 2-[O3,O4]]).

% group_group_sizes/2 - sorted distinct group cardinalities.
test(group_sizes_two) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_group_sizes([1-[O1,O2], 2-[O3]], [1,2]).

test(group_sizes_all_same) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_group_sizes([1-[O1], 2-[O2]], [1]).

test(group_sizes_empty) :-
    group_group_sizes([], []).

% group_all_same_size/1 - all groups have same cardinality.
test(all_same_size_yes) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    group_all_same_size([1-[O1], 2-[O2]]).

test(all_same_size_no, [fail]) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    group_all_same_size([1-[O1,O2], 2-[O3]]).

test(all_same_size_empty) :-
    group_all_same_size([]).

% group_keys/2 - sorted list of group keys.
test(keys_two_colors) :-
    group_keys([1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1)])]], [1,2]).

test(keys_empty) :-
    group_keys([], []).

test(keys_unsorted_input) :-
    group_keys([3-[obj(3,[r(0,0)])], 1-[obj(1,[r(1,1)])], 2-[obj(2,[r(2,2)])]], [1,2,3]).

:- end_tests(group).
