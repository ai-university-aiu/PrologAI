:- use_module('../prolog/objfilter').

% Standard test scene (7 objects of varying color, size, shape):
%   Dot   = obj(r, [r(0,0)])                          single cell; rect, hline, vline
%   Hbar  = obj(b, [r(1,0),r(1,1),r(1,2)])           3 cells; hline, rect
%   Vbar  = obj(g, [r(0,2),r(1,2),r(2,2)])           3 cells; vline, rect
%   Rect  = obj(y, [r(2,0),r(2,1),r(3,0),r(3,1)])   4 cells; rect
%   L     = obj(p, [r(4,0),r(4,1),r(5,0)])            3 cells; hollow (2x2 bbox, 3<4)
%   Frame = obj(o, [r(0,0),r(0,1),r(0,2),           8 cells; hollow (3x3 bbox, 8<9)
%                   r(1,0),r(1,2),
%                   r(2,0),r(2,1),r(2,2)])
%   Big   = obj(c, [r(0,0),r(0,1),r(0,2),r(0,3),   8 cells; rect (2x4 bbox)
%                   r(1,0),r(1,1),r(1,2),r(1,3)])

:- begin_tests(objfilter).

% Helper to build the standard test scene
scene(Objs) :-
    Dot   = obj(r, [r(0,0)]),
    Hbar  = obj(b, [r(1,0),r(1,1),r(1,2)]),
    Vbar  = obj(g, [r(0,2),r(1,2),r(2,2)]),
    Rect  = obj(y, [r(2,0),r(2,1),r(3,0),r(3,1)]),
    L     = obj(p, [r(4,0),r(4,1),r(5,0)]),
    Frame = obj(o, [r(0,0),r(0,1),r(0,2),r(1,0),r(1,2),r(2,0),r(2,1),r(2,2)]),
    Big   = obj(c, [r(0,0),r(0,1),r(0,2),r(0,3),r(1,0),r(1,1),r(1,2),r(1,3)]),
    Objs  = [Dot, Hbar, Vbar, Rect, L, Frame, Big].

% objfilter_by_color/3 tests
test(by_color_single) :-
    scene(Objs),
    objfilter_by_color(Objs, r, Filtered),
    length(Filtered, 1),
    Filtered = [obj(r, _)].

test(by_color_none) :-
    scene(Objs),
    objfilter_by_color(Objs, z, Filtered),
    Filtered = [].

test(by_color_two) :-
    Objs = [obj(a, [r(0,0)]), obj(b, [r(0,1)]), obj(a, [r(0,2)])],
    objfilter_by_color(Objs, a, Filtered),
    length(Filtered, 2).

% objfilter_not_color/3 tests
test(not_color_excludes_one) :-
    scene(Objs),
    objfilter_not_color(Objs, r, Filtered),
    length(Filtered, 6),
    \+ member(obj(r, _), Filtered).

test(not_color_none_match) :-
    scene(Objs),
    objfilter_not_color(Objs, z, Filtered),
    length(Filtered, 7).

test(not_color_all_excluded) :-
    Objs = [obj(a, [r(0,0)]), obj(a, [r(1,0)])],
    objfilter_not_color(Objs, a, Filtered),
    Filtered = [].

% objfilter_exact_size/3 tests
test(exact_size_1) :-
    scene(Objs),
    objfilter_exact_size(Objs, 1, Filtered),
    length(Filtered, 1),
    Filtered = [obj(r, _)].

test(exact_size_3) :-
    scene(Objs),
    objfilter_exact_size(Objs, 3, Filtered),
    % hbar, vbar, L all have 3 cells
    length(Filtered, 3).

test(exact_size_8) :-
    scene(Objs),
    objfilter_exact_size(Objs, 8, Filtered),
    % frame and big both have 8 cells
    length(Filtered, 2).

test(exact_size_zero) :-
    scene(Objs),
    objfilter_exact_size(Objs, 9, Filtered),
    Filtered = [].

% objfilter_min_size/3 tests
test(min_size_4) :-
    scene(Objs),
    objfilter_min_size(Objs, 4, Filtered),
    % rect (4), frame (8), big (8)
    length(Filtered, 3).

test(min_size_8) :-
    scene(Objs),
    objfilter_min_size(Objs, 8, Filtered),
    % frame and big
    length(Filtered, 2).

test(min_size_1) :-
    scene(Objs),
    objfilter_min_size(Objs, 1, Filtered),
    % all 7 objects
    length(Filtered, 7).

% objfilter_max_size/3 tests
test(max_size_3) :-
    scene(Objs),
    objfilter_max_size(Objs, 3, Filtered),
    % dot (1), hbar (3), vbar (3), L (3)
    length(Filtered, 4).

test(max_size_1) :-
    scene(Objs),
    objfilter_max_size(Objs, 1, Filtered),
    % only dot
    length(Filtered, 1).

test(max_size_8) :-
    scene(Objs),
    objfilter_max_size(Objs, 8, Filtered),
    % all 7 objects
    length(Filtered, 7).

% objfilter_is_rect/2 tests
test(is_rect_finds_rects) :-
    scene(Objs),
    objfilter_is_rect(Objs, Filtered),
    % dot (1x1), hbar (1x3), vbar (3x1), rect (2x2), big (2x4) all fill their bbox
    length(Filtered, 5).

test(is_rect_excludes_l_and_frame) :-
    scene(Objs),
    objfilter_is_rect(Objs, Filtered),
    \+ member(obj(p, _), Filtered),  % L not a rect
    \+ member(obj(o, _), Filtered).  % frame not a rect

test(is_rect_two_element_list) :-
    Objs = [obj(a, [r(0,0),r(0,1),r(1,0),r(1,1)]),  % 2x2 rect
            obj(b, [r(0,0),r(0,1),r(1,0)])],           % L (3 cells, 2x2 bbox)
    objfilter_is_rect(Objs, Filtered),
    length(Filtered, 1),
    Filtered = [obj(a, _)].

% objfilter_is_hline/2 tests
test(is_hline_dot_and_bar) :-
    scene(Objs),
    objfilter_is_hline(Objs, Filtered),
    % dot (H=1), hbar (H=1) are hlines
    length(Filtered, 2).

test(is_hline_not_vbar) :-
    scene(Objs),
    objfilter_is_hline(Objs, Filtered),
    \+ member(obj(g, _), Filtered).

test(is_hline_explicit) :-
    H = obj(h, [r(5,0),r(5,1),r(5,2),r(5,3)]),
    objfilter_is_hline([H], Filtered),
    Filtered = [H].

% objfilter_is_vline/2 tests
test(is_vline_dot_and_vbar) :-
    scene(Objs),
    objfilter_is_vline(Objs, Filtered),
    % dot (W=1), vbar (W=1) are vlines
    length(Filtered, 2).

test(is_vline_not_hbar) :-
    scene(Objs),
    objfilter_is_vline(Objs, Filtered),
    \+ member(obj(b, _), Filtered).

test(is_vline_explicit) :-
    V = obj(v, [r(0,3),r(1,3),r(2,3),r(3,3)]),
    objfilter_is_vline([V], Filtered),
    Filtered = [V].

% objfilter_is_single/2 tests
test(is_single_only_dot) :-
    scene(Objs),
    objfilter_is_single(Objs, Filtered),
    Filtered = [obj(r, [r(0,0)])].

test(is_single_none) :-
    Objs = [obj(a, [r(0,0),r(0,1)]), obj(b, [r(1,0),r(1,1)])],
    objfilter_is_single(Objs, Filtered),
    Filtered = [].

test(is_single_two) :-
    Objs = [obj(a, [r(0,0)]), obj(b, [r(0,0),r(0,1)]), obj(c, [r(2,2)])],
    objfilter_is_single(Objs, Filtered),
    length(Filtered, 2).

% objfilter_is_hollow/2 tests
test(is_hollow_l_and_frame) :-
    scene(Objs),
    objfilter_is_hollow(Objs, Filtered),
    % L (2x2 bbox, 3 cells), frame (3x3 bbox, 8 cells)
    length(Filtered, 2).

test(is_hollow_not_rect) :-
    scene(Objs),
    objfilter_is_hollow(Objs, Filtered),
    \+ member(obj(y, _), Filtered).

test(is_hollow_not_hbar) :-
    scene(Objs),
    objfilter_is_hollow(Objs, Filtered),
    \+ member(obj(b, _), Filtered).

% objfilter_largest/2 tests
test(largest_is_first_max) :-
    scene(Objs),
    % frame (8 cells) appears before big (8 cells) in scene; expect frame
    objfilter_largest(Objs, Largest),
    Largest = obj(o, _).

test(largest_single_element) :-
    Obj = obj(a, [r(0,0),r(0,1)]),
    objfilter_largest([Obj], Largest),
    Largest = Obj.

test(largest_clear_winner) :-
    Objs = [obj(a, [r(0,0)]),
            obj(b, [r(0,0),r(0,1),r(0,2)]),
            obj(c, [r(0,0),r(0,1)])],
    objfilter_largest(Objs, Largest),
    Largest = obj(b, _).

% objfilter_smallest/2 tests
test(smallest_is_dot) :-
    scene(Objs),
    objfilter_smallest(Objs, Smallest),
    Smallest = obj(r, _).

test(smallest_single_element) :-
    Obj = obj(a, [r(0,0),r(0,1),r(0,2)]),
    objfilter_smallest([Obj], Smallest),
    Smallest = Obj.

test(smallest_tie_first) :-
    Objs = [obj(a, [r(0,0),r(0,1)]),
            obj(b, [r(1,0)]),
            obj(c, [r(2,0)])],
    % obj(b) and obj(c) both have 1 cell; obj(b) is first
    objfilter_smallest(Objs, Smallest),
    Smallest = obj(b, _).

% objfilter_filter/3 tests (meta-predicate with custom Goal)
is_blue(obj(b, _)).

test(filter_custom_blue) :-
    scene(Objs),
    objfilter_filter(Objs, is_blue, Filtered),
    Filtered = [obj(b, _)].

test(filter_empty_result) :-
    Objs = [obj(a, [r(0,0)]), obj(c, [r(1,0)])],
    objfilter_filter(Objs, is_blue, Filtered),
    Filtered = [].

test(filter_all_pass) :-
    Objs = [obj(b, [r(0,0)]), obj(b, [r(1,0)])],
    objfilter_filter(Objs, is_blue, Filtered),
    length(Filtered, 2).

% objfilter_partition/4 tests
test(partition_by_color) :-
    Objs = [obj(r, [r(0,0)]), obj(b, [r(0,1)]), obj(r, [r(0,2)])],
    objfilter_partition(Objs, is_blue, In, Out),
    In  = [obj(b, _)],
    length(Out, 2).

test(partition_all_in) :-
    Objs = [obj(b, [r(0,0)]), obj(b, [r(0,1)])],
    objfilter_partition(Objs, is_blue, In, Out),
    length(In, 2),
    Out = [].

test(partition_all_out) :-
    Objs = [obj(r, [r(0,0)]), obj(g, [r(0,1)])],
    objfilter_partition(Objs, is_blue, In, Out),
    In = [],
    length(Out, 2).

:- end_tests(objfilter).
