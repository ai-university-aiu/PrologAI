:- use_module('../prolog/pair').

:- begin_tests(pair).

% pr_obj_shape/2 tests.
test(shape_single) :-
    pr_obj_shape(obj(1, [r(0,0)]), Shape),
    Shape = [r(0,0)].

test(shape_hpair) :-
    pr_obj_shape(obj(2, [r(0,0), r(0,1)]), Shape),
    Shape = [r(0,0), r(0,1)].

test(shape_vpair_eq_hpair) :-
    pr_obj_shape(obj(3, [r(0,0), r(1,0)]), Shape),
    Shape = [r(0,0), r(0,1)].

% pr_obj_color/2 tests.
test(color_5) :-
    pr_obj_color(obj(5, [r(0,0)]), 5).

test(color_0) :-
    pr_obj_color(obj(0, [r(1,2)]), 0).

test(color_9) :-
    pr_obj_color(obj(9, [r(0,0), r(0,1), r(0,2)]), 9).

% pr_obj_size/2 tests.
test(size_one) :-
    pr_obj_size(obj(1, [r(0,0)]), N),
    N = 1.

test(size_three) :-
    pr_obj_size(obj(2, [r(0,0), r(0,1), r(0,2)]), N),
    N = 3.

test(size_four) :-
    pr_obj_size(obj(3, [r(0,0), r(0,1), r(1,0), r(1,1)]), N),
    N = 4.

% pr_shape_eq/2 tests.
test(shape_eq_hv_pair) :-
    pr_shape_eq(
        obj(1, [r(0,0), r(0,1)]),
        obj(2, [r(0,0), r(1,0)])).

test(shape_eq_same) :-
    pr_shape_eq(
        obj(1, [r(0,0), r(0,1), r(0,2)]),
        obj(1, [r(0,0), r(0,1), r(0,2)])).

test(shape_eq_lshape_rot90) :-
    pr_shape_eq(
        obj(1, [r(0,0), r(1,0), r(1,1)]),
        obj(2, [r(0,0), r(0,1), r(1,0)])).

% pr_color_eq/2 tests.
test(color_eq_basic) :-
    pr_color_eq(obj(3, [r(0,0)]), obj(3, [r(1,2)])).

test(color_eq_different_sizes) :-
    pr_color_eq(obj(7, [r(0,0), r(0,1)]), obj(7, [r(0,0)])).

test(color_eq_zero) :-
    pr_color_eq(obj(0, [r(0,0)]), obj(0, [r(2,3), r(3,4)])).

% pr_size_eq/2 tests.
test(size_eq_single) :-
    pr_size_eq(obj(1, [r(0,0)]), obj(2, [r(5,5)])).

test(size_eq_triple) :-
    pr_size_eq(
        obj(1, [r(0,0), r(0,1), r(0,2)]),
        obj(2, [r(0,0), r(1,0), r(2,0)])).

test(size_eq_quad) :-
    pr_size_eq(
        obj(1, [r(0,0), r(0,1), r(1,0), r(1,1)]),
        obj(2, [r(2,2), r(2,3), r(3,2), r(3,3)])).

% pr_group_color/2 tests.
test(group_color_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pr_group_color(Objs, Groups),
    Groups = [1-[obj(1,[r(0,0)]),obj(1,[r(1,0)])], 2-[obj(2,[r(0,1)])]].

test(group_color_single) :-
    pr_group_color([obj(3,[r(0,0)])], Groups),
    Groups = [3-[obj(3,[r(0,0)])]].

test(group_color_same_color) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(0,1)]), obj(1,[r(0,2)])],
    pr_group_color(Objs, Groups),
    Groups = [1-[obj(1,[r(0,0)]),obj(1,[r(0,1)]),obj(1,[r(0,2)])]].

% pr_group_size/2 tests.
test(group_size_two) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)]), obj(3,[r(1,1)])],
    pr_group_size(Objs, Groups),
    Groups = [1-[obj(1,[r(0,0)]),obj(3,[r(1,1)])], 2-[obj(2,[r(0,0),r(0,1)])]].

test(group_size_single_group) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    pr_group_size(Objs, Groups),
    Groups = [1-[obj(1,[r(0,0)]),obj(2,[r(1,1)])]].

test(group_size_three_groups) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)]), obj(3,[r(0,0),r(0,1),r(0,2)])],
    pr_group_size(Objs, Groups),
    Groups = [1-[obj(1,[r(0,0)])], 2-[obj(2,[r(0,0),r(0,1)])],
              3-[obj(3,[r(0,0),r(0,1),r(0,2)])]].

% pr_group_shape/2 tests.
test(group_shape_two_shapes) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(0,0),r(1,0)]),
            obj(3,[r(0,0),r(0,1),r(0,2)])],
    pr_group_shape(Objs, Groups),
    Groups = [[r(0,0),r(0,1)]-[obj(1,[r(0,0),r(0,1)]),obj(2,[r(0,0),r(1,0)])],
              [r(0,0),r(0,1),r(0,2)]-[obj(3,[r(0,0),r(0,1),r(0,2)])]].

test(group_shape_all_singles) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(5,5)]), obj(3,[r(2,3)])],
    pr_group_shape(Objs, Groups),
    Groups = [[r(0,0)]-[obj(1,[r(0,0)]),obj(2,[r(5,5)]),obj(3,[r(2,3)])]].

test(group_shape_two_objs_different) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(0,0),r(0,1)])],
    pr_group_shape(Objs, Groups),
    Groups = [[r(0,0)]-[obj(1,[r(0,0)])],
              [r(0,0),r(0,1)]-[obj(1,[r(0,0),r(0,1)])]].

% pr_unique_color/2 tests.
test(unique_color_one) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,0)]), obj(2,[r(0,1)])],
    pr_unique_color(Objs, Obj),
    Obj = obj(2,[r(0,1)]).

test(unique_color_first) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(2,[r(1,0)])],
    pr_unique_color(Objs, Obj),
    Obj = obj(1,[r(0,0)]).

test(unique_color_many) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(2,[r(1,0)]),
            obj(3,[r(1,1)]), obj(3,[r(2,2)])],
    pr_unique_color(Objs, Obj),
    Obj = obj(1,[r(0,0)]).

% pr_unique_size/2 tests.
test(unique_size_one) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)]), obj(3,[r(1,1)])],
    pr_unique_size(Objs, Obj),
    Obj = obj(2,[r(0,0),r(0,1)]).

test(unique_size_first) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)]), obj(3,[r(0,0),r(0,1)])],
    pr_unique_size(Objs, Obj),
    Obj = obj(1,[r(0,0)]).

test(unique_size_last) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(0,0),r(0,1)]), obj(3,[r(0,0)])],
    pr_unique_size(Objs, Obj),
    Obj = obj(3,[r(0,0)]).

% pr_match_color/3 tests.
test(match_color_one_pair) :-
    Objs1 = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    Objs2 = [obj(1,[r(1,0)]), obj(3,[r(1,1)])],
    pr_match_color(Objs1, Objs2, Pairs),
    Pairs = [1-obj(1,[r(0,0)])-obj(1,[r(1,0)])].

test(match_color_two_pairs) :-
    Objs1 = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    Objs2 = [obj(1,[r(1,0)]), obj(2,[r(1,1)])],
    pr_match_color(Objs1, Objs2, Pairs),
    Pairs = [1-obj(1,[r(0,0)])-obj(1,[r(1,0)]),
             2-obj(2,[r(0,1)])-obj(2,[r(1,1)])].

test(match_color_no_match) :-
    pr_match_color([obj(1,[r(0,0)])], [obj(2,[r(0,0)])], Pairs),
    Pairs = [].

% pr_match_size/3 tests.
test(match_size_one_pair) :-
    Objs1 = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(0,0)])],
    Objs2 = [obj(3,[r(1,0),r(1,1)])],
    pr_match_size(Objs1, Objs2, Pairs),
    Pairs = [2-obj(1,[r(0,0),r(0,1)])-obj(3,[r(1,0),r(1,1)])].

test(match_size_two_pairs) :-
    Objs1 = [obj(1,[r(0,0)]), obj(2,[r(0,0),r(0,1)])],
    Objs2 = [obj(3,[r(1,0)]), obj(4,[r(1,0),r(1,1)])],
    pr_match_size(Objs1, Objs2, Pairs),
    Pairs = [1-obj(1,[r(0,0)])-obj(3,[r(1,0)]),
             2-obj(2,[r(0,0),r(0,1)])-obj(4,[r(1,0),r(1,1)])].

test(match_size_no_match) :-
    pr_match_size([obj(1,[r(0,0)])], [obj(2,[r(0,0),r(0,1)])], Pairs),
    Pairs = [].

% pr_match_shape/3 tests.
test(match_shape_hv_pair) :-
    Objs1 = [obj(1,[r(0,0),r(0,1)])],
    Objs2 = [obj(2,[r(0,0),r(1,0)])],
    pr_match_shape(Objs1, Objs2, Pairs),
    Pairs = [[r(0,0),r(0,1)]-obj(1,[r(0,0),r(0,1)])-obj(2,[r(0,0),r(1,0)])].

test(match_shape_lshape) :-
    Objs1 = [obj(1,[r(0,0),r(1,0),r(1,1)])],
    Objs2 = [obj(2,[r(0,0),r(0,1),r(1,0)])],
    pr_match_shape(Objs1, Objs2, Pairs),
    length(Pairs, 1).

test(match_shape_no_match) :-
    pr_match_shape([obj(1,[r(0,0)])], [obj(2,[r(0,0),r(0,1)])], Pairs),
    Pairs = [].

:- end_tests(pair).
