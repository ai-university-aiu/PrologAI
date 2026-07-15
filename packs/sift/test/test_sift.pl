:- begin_tests(sift).
:- use_module('../prolog/sift').

% sift_by_color/3 - filter by exact color.
test(by_color_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    sift_by_color(Objs, 1, [obj(1,[r(0,0)]), obj(1,[r(1,0)])]).

test(by_color_none) :-
    sift_by_color([obj(1,[r(0,0)]), obj(2,[r(0,1)])], 5, []).

test(by_color_all) :-
    Objs = [obj(3,[r(0,0)]), obj(3,[r(1,0)])],
    sift_by_color(Objs, 3, Objs).

% sift_not_color/3 - filter by excluding a color.
test(not_color_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    sift_not_color(Objs, 1, [obj(2,[r(0,1)])]).

test(not_color_none_removed) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    sift_not_color(Objs, 5, Objs).

test(not_color_all_removed) :-
    sift_not_color([obj(4,[r(0,0)]), obj(4,[r(1,0)])], 4, []).

% sift_by_size/3 - filter by exact cell count.
test(by_size_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0)])],
    sift_by_size(Objs, 1, [obj(1,[r(0,0)]), obj(3,[r(1,0)])]).

test(by_size_two_cell) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0)])],
    sift_by_size(Objs, 2, [obj(2,[r(0,1),r(0,2)])]).

test(by_size_none) :-
    sift_by_size([obj(1,[r(0,0)]), obj(2,[r(0,1)])], 5, []).

% sift_by_form/3 - filter by exact origin-normalized form.
test(by_form_basic) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(3,4),r(3,5)]), obj(3,[r(0,0),r(1,0)])],
    sift_by_form(Objs, [r(0,0),r(0,1)], [obj(1,[r(0,0),r(0,1)]), obj(2,[r(3,4),r(3,5)])]).

test(by_form_single) :-
    sift_by_form([obj(1,[r(2,3)])], [r(0,0)], [obj(1,[r(2,3)])]).

test(by_form_none) :-
    sift_by_form([obj(1,[r(0,0),r(0,1)])], [r(0,0),r(1,0)], []).

% sift_larger_than/3 - filter by cell count > N.
test(larger_than_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])],
    sift_larger_than(Objs, 1, [obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])]).

test(larger_than_none) :-
    sift_larger_than([obj(1,[r(0,0)]), obj(2,[r(0,1)])], 3, []).

test(larger_than_all) :-
    Objs = [obj(1,[r(0,0),r(0,1),r(0,2)]), obj(2,[r(1,0),r(1,1)])],
    sift_larger_than(Objs, 1, Objs).

% sift_smaller_than/3 - filter by cell count < N.
test(smaller_than_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])],
    sift_smaller_than(Objs, 3, [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)])]).

test(smaller_than_none) :-
    sift_smaller_than([obj(1,[r(0,0),r(0,1)]), obj(2,[r(1,0),r(1,1)])], 1, []).

test(smaller_than_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    sift_smaller_than(Objs, 2, Objs).

% sift_color_in/3 - filter by color membership in a list.
test(color_in_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    sift_color_in(Objs, [1,3], [obj(1,[r(0,0)]), obj(3,[r(1,0)])]).

test(color_in_none) :-
    sift_color_in([obj(1,[r(0,0)]), obj(2,[r(0,1)])], [5,6], []).

test(color_in_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    sift_color_in(Objs, [1,2,3], Objs).

% sift_color_not_in/3 - filter by color not in a list.
test(color_not_in_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    sift_color_not_in(Objs, [1,3], [obj(2,[r(0,1)])]).

test(color_not_in_none) :-
    sift_color_not_in([obj(1,[r(0,0)]), obj(2,[r(0,1)])], [1,2], []).

test(color_not_in_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    sift_color_not_in(Objs, [5,6], Objs).

% sift_max_size/2 - keep all objs with the maximum cell count.
test(max_size_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2),r(0,3)]), obj(3,[r(1,0)])],
    sift_max_size(Objs, [obj(2,[r(0,1),r(0,2),r(0,3)])]).

test(max_size_tie) :-
    O1 = obj(1,[r(0,0),r(0,1)]),
    O2 = obj(2,[r(1,0),r(1,1)]),
    sift_max_size([O1, O2], [O1, O2]).

test(max_size_single) :-
    O = obj(3,[r(0,0),r(0,1),r(0,2)]),
    sift_max_size([O], [O]).

% sift_min_size/2 - keep all objs with the minimum cell count.
test(min_size_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2),r(0,3)]), obj(3,[r(1,0)])],
    sift_min_size(Objs, [obj(1,[r(0,0)]), obj(3,[r(1,0)])]).

test(min_size_tie) :-
    O1 = obj(1,[r(0,0)]),
    O2 = obj(2,[r(1,0)]),
    sift_min_size([O1, O2], [O1, O2]).

test(min_size_single) :-
    O = obj(3,[r(0,0)]),
    sift_min_size([O], [O]).

% sift_unique_color/2 - keep objs whose color appears exactly once.
test(unique_color_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    sift_unique_color(Objs, [obj(2,[r(0,1)])]).

test(unique_color_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    sift_unique_color(Objs, Objs).

test(unique_color_none) :-
    sift_unique_color([obj(1,[r(0,0)]), obj(1,[r(1,0)])], []).

% sift_shared_color/2 - keep objs whose color appears more than once.
test(shared_color_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    sift_shared_color(Objs, [obj(1,[r(0,0)]), obj(1,[r(1,0)])]).

test(shared_color_none) :-
    sift_shared_color([obj(1,[r(0,0)]), obj(2,[r(0,1)])], []).

test(shared_color_all) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,0)]), obj(2,[r(0,1)]), obj(2,[r(1,1)])],
    sift_shared_color(Objs, Objs).

% sift_on_border/4 - keep objs with any cell on the H-by-W grid border.
% 3x3 grid: rows 0..2, cols 0..2. Border = row 0, row 2, col 0, col 2.
test(on_border_top_row) :-
    O1 = obj(1,[r(0,1)]),
    O2 = obj(2,[r(1,1)]),
    sift_on_border([O1,O2], 3, 3, [O1]).

test(on_border_corner) :-
    O = obj(1,[r(2,2)]),
    sift_on_border([O], 3, 3, [O]).

test(on_border_none) :-
    O = obj(1,[r(1,1)]),
    sift_on_border([O], 3, 3, []).

% sift_off_border/4 - keep objs with no cell on the H-by-W grid border.
test(off_border_basic) :-
    O1 = obj(1,[r(0,1)]),
    O2 = obj(2,[r(1,1)]),
    sift_off_border([O1,O2], 3, 3, [O2]).

test(off_border_all) :-
    Objs = [obj(1,[r(1,1)]), obj(2,[r(1,2)])],
    sift_off_border(Objs, 4, 4, Objs).

test(off_border_none) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    sift_off_border(Objs, 3, 3, []).

:- end_tests(sift).
