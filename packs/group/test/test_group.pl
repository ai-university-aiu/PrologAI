:- begin_tests(group).
:- use_module('../prolog/group').

% gp_by_color/2 - partition by color.
test(by_color_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)]), obj(1,[r(0,1)])],
    gp_by_color(Objs, [1-[obj(1,[r(0,0)]),obj(1,[r(0,1)])], 2-[obj(2,[r(1,1)])]]).

test(by_color_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,1)])],
    gp_by_color(Objs, [1-[obj(1,[r(0,0)]),obj(1,[r(1,1)])]]).

test(by_color_empty) :-
    gp_by_color([], []).

% gp_by_size/2 - partition by cell count.
test(by_size_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1),r(1,2)])],
    gp_by_size(Objs, [1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1),r(1,2)])]]).

test(by_size_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    gp_by_size(Objs, [1-[obj(1,[r(0,0)]),obj(2,[r(1,1)])]]).

test(by_size_empty) :-
    gp_by_size([], []).

% gp_by_row/2 - partition by minimum row.
test(by_row_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    gp_by_row(Objs, [0-[obj(1,[r(0,0)])], 1-[obj(2,[r(1,1)])]]).

test(by_row_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    gp_by_row(Objs, [0-[obj(1,[r(0,0)]),obj(2,[r(0,1)])]]).

test(by_row_empty) :-
    gp_by_row([], []).

% gp_by_col/2 - partition by minimum column.
test(by_col_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,2)])],
    gp_by_col(Objs, [0-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,2)])]]).

test(by_col_all_same) :-
    Objs = [obj(1,[r(0,1)]), obj(2,[r(1,1)])],
    gp_by_col(Objs, [1-[obj(1,[r(0,1)]),obj(2,[r(1,1)])]]).

test(by_col_single) :-
    gp_by_col([obj(3,[r(0,2)])], [2-[obj(3,[r(0,2)])]]).

% gp_by_form/2 - partition by origin-normalized cell list.
test(by_form_two) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(2,2),r(2,3)]), obj(3,[r(0,0),r(1,0)])],
    gp_by_form(Objs, [[r(0,0),r(0,1)]-[obj(1,[r(0,0),r(0,1)]),obj(2,[r(2,2),r(2,3)])],
                       [r(0,0),r(1,0)]-[obj(3,[r(0,0),r(1,0)])]]).

test(by_form_all_same) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    gp_by_form(Objs, [[r(0,0)]-[obj(1,[r(0,0)]),obj(2,[r(1,1)])]]).

test(by_form_empty) :-
    gp_by_form([], []).

% gp_size_of/2 - number of groups.
test(size_of_two) :-
    gp_size_of([1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1)])]],  2).

test(size_of_empty) :-
    gp_size_of([], 0).

test(size_of_three) :-
    gp_size_of([1-[], 2-[], 3-[]], 3).

% gp_flatten/2 - flatten groups to flat list.
test(flatten_two_groups) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_flatten([1-[O1,O2], 2-[O3]], [O1,O2,O3]).

test(flatten_empty) :-
    gp_flatten([], []).

test(flatten_single_group) :-
    O = obj(1,[r(0,0)]),
    gp_flatten([1-[O]], [O]).

% gp_largest_group/2 - group with most objects.
test(largest_group_basic) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_largest_group([1-[O1,O2], 2-[O3]], 1-[O1,O2]).

test(largest_group_three) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]), O3 = obj(2,[r(1,2)]), O4 = obj(3,[r(2,2)]),
    gp_largest_group([1-[O1], 2-[O2,O3,O4], 3-[O4]], 2-[O2,O3,O4]).

test(largest_group_tie) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_largest_group([1-[O1], 2-[O2]], 1-[O1]).

% gp_smallest_group/2 - group with fewest objects.
test(smallest_group_basic) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_smallest_group([1-[O1,O2], 2-[O3]], 2-[O3]).

test(smallest_group_three) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]), O3 = obj(2,[r(2,2)]),
    gp_smallest_group([1-[O1], 2-[O2,O3]], 1-[O1]).

test(smallest_group_tie) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_smallest_group([1-[O1], 2-[O2]], 1-[O1]).

% gp_singleton_groups/2 - groups with exactly one object.
test(singleton_groups_one) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_singleton_groups([1-[O1,O2], 2-[O3]], [2-[O3]]).

test(singleton_groups_all) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_singleton_groups([1-[O1], 2-[O2]], [1-[O1], 2-[O2]]).

test(singleton_groups_none) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]), O4 = obj(2,[r(1,2)]),
    gp_singleton_groups([1-[O1,O2], 2-[O3,O4]], []).

% gp_shared_groups/2 - groups with more than one object.
test(shared_groups_one) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_shared_groups([1-[O1,O2], 2-[O3]], [1-[O1,O2]]).

test(shared_groups_none) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_shared_groups([1-[O1], 2-[O2]], []).

test(shared_groups_all) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]), O4 = obj(2,[r(1,2)]),
    gp_shared_groups([1-[O1,O2], 2-[O3,O4]], [1-[O1,O2], 2-[O3,O4]]).

% gp_group_sizes/2 - sorted distinct group cardinalities.
test(group_sizes_two) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_group_sizes([1-[O1,O2], 2-[O3]], [1,2]).

test(group_sizes_all_same) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_group_sizes([1-[O1], 2-[O2]], [1]).

test(group_sizes_empty) :-
    gp_group_sizes([], []).

% gp_all_same_size/1 - all groups have same cardinality.
test(all_same_size_yes) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(2,[r(1,1)]),
    gp_all_same_size([1-[O1], 2-[O2]]).

test(all_same_size_no, [fail]) :-
    O1 = obj(1,[r(0,0)]), O2 = obj(1,[r(0,1)]), O3 = obj(2,[r(1,1)]),
    gp_all_same_size([1-[O1,O2], 2-[O3]]).

test(all_same_size_empty) :-
    gp_all_same_size([]).

% gp_keys/2 - sorted list of group keys.
test(keys_two_colors) :-
    gp_keys([1-[obj(1,[r(0,0)])], 2-[obj(2,[r(1,1)])]], [1,2]).

test(keys_empty) :-
    gp_keys([], []).

test(keys_unsorted_input) :-
    gp_keys([3-[obj(3,[r(0,0)])], 1-[obj(1,[r(1,1)])], 2-[obj(2,[r(2,2)])]], [1,2,3]).

:- end_tests(group).
