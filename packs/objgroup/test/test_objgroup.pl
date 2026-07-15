:- use_module('../prolog/objgroup').
:- use_module(library(plunit)).
:- use_module(library(lists), [memberchk/2]).

:- begin_tests(objgroup).

% --- Test fixtures ---
% red dot at r(0,0) — size 1
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,1) — size 1
blue_dot(obj(b, [r(0,1)])).
% green dot at r(1,0) — size 1
green_dot(obj(g, [r(1,0)])).
% red bar: 3 cells r(0,0)..r(0,2)
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
% blue bar: 3 cells r(1,0)..r(1,2)
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
% red sq: 4 cells 2x2 at r(0,0)
red_sq(obj(r, [r(0,0),r(0,1),r(1,0),r(1,1)])).
% yellow sq: 4 cells 2x2 at r(2,2)
yellow_sq(obj(y, [r(2,2),r(2,3),r(3,2),r(3,3)])).
% L-shape: r(0,0),r(1,0),r(1,1)
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
% L-shape far: same shape at r(3,4)
lshape_far(obj(b, [r(3,4),r(4,4),r(4,5)])).

% --- objgroup_by_color/2 ---

test(by_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    memberchk(b-[B], Groups),
    memberchk(r-[R,RB], Groups).

test(by_color_single) :-
    red_dot(R),
    objgroup_by_color([R], Groups),
    Groups == [r-[R]].

test(by_color_empty) :-
    objgroup_by_color([], Groups),
    Groups == [].

test(by_color_all_same) :-
    red_dot(D), red_bar(B), red_sq(S),
    objgroup_by_color([D, B, S], Groups),
    Groups == [r-[D,B,S]].

test(by_color_three) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objgroup_by_color([R, B, G], Groups),
    length(Groups, 3),
    memberchk(r-[R], Groups),
    memberchk(b-[B], Groups),
    memberchk(g-[G], Groups).

% --- objgroup_by_size/2 ---

test(by_size_basic) :-
    red_dot(D), red_bar(B), red_sq(S),
    objgroup_by_size([D, B, S], Groups),
    memberchk(1-[D], Groups),
    memberchk(3-[B], Groups),
    memberchk(4-[S], Groups).

test(by_size_shared) :-
    red_dot(D), blue_dot(BD), red_bar(B), blue_bar(BB),
    objgroup_by_size([D, BD, B, BB], Groups),
    memberchk(1-Ones, Groups),
    length(Ones, 2),
    memberchk(3-Threes, Groups),
    length(Threes, 2).

test(by_size_empty) :-
    objgroup_by_size([], Groups),
    Groups == [].

test(by_size_three_sizes) :-
    red_dot(D), red_bar(B), red_sq(S), yellow_sq(YS),
    objgroup_by_size([D, B, S, YS], Groups),
    % sizes 1, 3, 4; sq and yellow_sq both size 4
    memberchk(4-Fours, Groups),
    length(Fours, 2).

% --- objgroup_by_form/2 ---

test(by_form_basic) :-
    lshape(L), lshape_far(LF), red_dot(D), blue_dot(BD),
    objgroup_by_form([L, LF, D, BD], Groups),
    % two distinct forms: L-shape and single-dot
    length(Groups, 2),
    % both groups have 2 members
    objgroup_n_members(Groups, 2, TwoGroups),
    length(TwoGroups, 2).

test(by_form_single_dot) :-
    red_dot(D),
    objgroup_by_form([D], [_-[D]]).

% --- objgroup_by_row/2 ---

test(by_row_basic) :-
    red_dot(D),   % top-left r(0,0)
    blue_dot(BD), % top-left r(0,1)
    green_dot(G), % top-left r(1,0)
    objgroup_by_row([D, BD, G], Groups),
    memberchk(0-Row0, Groups),
    length(Row0, 2),
    memberchk(1-Row1, Groups),
    length(Row1, 1).

test(by_row_all_same) :-
    red_dot(D), blue_dot(BD),
    objgroup_by_row([D, BD], Groups),
    Groups == [0-[D,BD]].

test(by_row_three_rows) :-
    red_dot(D),   % row 0
    red_bar(B),   % row 0
    green_dot(G), % row 1
    red_sq(S),    % row 0
    yellow_sq(YS), % row 2
    objgroup_by_row([D, B, G, S, YS], Groups),
    length(Groups, 3),
    memberchk(0-Row0, Groups),
    length(Row0, 3).

% --- objgroup_by_col/2 ---

test(by_col_basic) :-
    red_dot(D),   % top-left r(0,0), col 0
    blue_dot(BD), % top-left r(0,1), col 1
    green_dot(G), % top-left r(1,0), col 0
    objgroup_by_col([D, BD, G], Groups),
    memberchk(0-Col0, Groups),
    length(Col0, 2),
    memberchk(1-Col1, Groups),
    length(Col1, 1).

test(by_col_all_same) :-
    red_dot(D), green_dot(G),
    % both at col 0
    objgroup_by_col([D, G], Groups),
    Groups == [0-[D,G]].

% --- objgroup_n_groups/2 ---

test(n_groups_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    objgroup_n_groups(Groups, N),
    N == 2.

test(n_groups_empty) :-
    objgroup_n_groups([], N),
    N == 0.

test(n_groups_three) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objgroup_by_color([R, B, G], Groups),
    objgroup_n_groups(Groups, N),
    N == 3.

% --- objgroup_n_members/3 ---

test(n_members_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB), red_sq(S),
    objgroup_by_color([R, B, RB, S], Groups),
    objgroup_n_members(Groups, 1, Singletons),
    length(Singletons, 1).

test(n_members_none) :-
    red_dot(R), blue_dot(B),
    objgroup_by_color([R, B], Groups),
    objgroup_n_members(Groups, 5, Selected),
    Selected == [].

test(n_members_two) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    objgroup_n_members(Groups, 2, Selected),
    length(Selected, 1),
    Selected = [r-_].

% --- objgroup_singletons/2 ---

test(singletons_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    objgroup_singletons(Groups, Singletons),
    length(Singletons, 1),
    Singletons = [b-_].

test(singletons_all) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objgroup_by_color([R, B, G], Groups),
    objgroup_singletons(Groups, Singletons),
    length(Singletons, 3).

test(singletons_none) :-
    red_dot(R), blue_dot(B), red_bar(RB), blue_bar(BB),
    objgroup_by_color([R, B, RB, BB], Groups),
    % r has 2, b has 2 — no singletons
    objgroup_singletons(Groups, Singletons),
    Singletons == [].

% --- objgroup_largest/2 ---

test(largest_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB), red_sq(S),
    objgroup_by_color([R, B, RB, S], Groups),
    objgroup_largest(Groups, Largest),
    Largest = r-_.

test(largest_single_group) :-
    red_dot(R), red_bar(B),
    objgroup_by_color([R, B], Groups),
    objgroup_largest(Groups, Group),
    Group = r-_.

% --- objgroup_smallest/2 ---

test(smallest_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    objgroup_smallest(Groups, Smallest),
    Smallest = b-_.

test(smallest_single_group) :-
    red_dot(R),
    objgroup_by_color([R], Groups),
    objgroup_smallest(Groups, Group),
    Group = r-_.

% --- objgroup_all_same_size/1 ---

test(all_same_size_true) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objgroup_by_color([R, B, G], Groups),
    objgroup_all_same_size(Groups).

test(all_same_size_false) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    \+ objgroup_all_same_size(Groups).

test(all_same_size_empty) :-
    objgroup_all_same_size([]).

% --- objgroup_sort_desc/2 ---

test(sort_desc_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB), red_sq(S),
    objgroup_by_color([R, B, RB, S], Groups),
    objgroup_sort_desc(Groups, [First|_]),
    First = r-_.

test(sort_desc_equal) :-
    red_dot(R), blue_dot(B),
    objgroup_by_color([R, B], Groups),
    objgroup_sort_desc(Groups, Sorted),
    length(Sorted, 2).

test(sort_desc_three) :-
    red_dot(R), blue_dot(B), red_bar(RB), red_sq(S), green_dot(G),
    objgroup_by_color([R, B, RB, S, G], Groups),
    % r has 3, b has 1, g has 1
    objgroup_sort_desc(Groups, [First|_]),
    First = r-_.

% --- objgroup_flat/2 ---

test(flat_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objgroup_by_color([R, B, RB], Groups),
    objgroup_flat(Groups, Objs),
    length(Objs, 3),
    memberchk(R, Objs),
    memberchk(B, Objs),
    memberchk(RB, Objs).

test(flat_empty) :-
    objgroup_flat([], Objs),
    Objs == [].

% --- objgroup_filter_size/4 ---

test(filter_size_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB), red_sq(S),
    objgroup_by_color([R, B, RB, S], Groups),
    objgroup_filter_size(Groups, 2, 4, Filtered),
    length(Filtered, 1),
    Filtered = [r-_].

test(filter_size_all) :-
    red_dot(R), blue_dot(B),
    objgroup_by_color([R, B], Groups),
    objgroup_filter_size(Groups, 1, 1, Filtered),
    length(Filtered, 2).

test(filter_size_none) :-
    red_dot(R), blue_dot(B),
    objgroup_by_color([R, B], Groups),
    objgroup_filter_size(Groups, 5, 10, Filtered),
    Filtered == [].

test(flat_roundtrip) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    Objs = [R, B, RB],
    objgroup_by_color(Objs, Groups),
    objgroup_flat(Groups, Flat),
    % flat contains the same objects, possibly reordered by color key
    length(Flat, 3),
    memberchk(R, Flat),
    memberchk(B, Flat),
    memberchk(RB, Flat).

:- end_tests(objgroup).
