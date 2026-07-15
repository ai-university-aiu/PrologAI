:- use_module('../prolog/scenecmp').
:- use_module(library(plunit)).

:- begin_tests(scenecmp).

% --- Test fixtures ---
% red dot at r(0,0) — size 1
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,1) — size 1
blue_dot(obj(b, [r(0,1)])).
% green dot at r(1,0) — size 1
green_dot(obj(g, [r(1,0)])).
% red bar: 3 cells r(0,0)..r(0,2) — size 3
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
% blue bar: 3 cells r(1,0)..r(1,2) — size 3
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
% red sq: 4 cells 2x2 at r(0,0) — size 4
red_sq(obj(r, [r(0,0),r(0,1),r(1,0),r(1,1)])).
% yellow sq: 4 cells 2x2 at r(2,2) — size 4
yellow_sq(obj(y, [r(2,2),r(2,3),r(3,2),r(3,3)])).
% L-shape: r(0,0),r(1,0),r(1,1) — size 3
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% --- scenecmp_n_objs/2 ---

test(n_objs_basic) :-
    red_dot(R), blue_dot(B),
    scenecmp_n_objs([R, B], N),
    N == 2.

test(n_objs_empty) :-
    scenecmp_n_objs([], N),
    N == 0.

test(n_objs_single) :-
    red_dot(R),
    scenecmp_n_objs([R], N),
    N == 1.

% --- scenecmp_total_cells/2 ---

test(total_cells_basic) :-
    red_dot(R), red_bar(B),
    scenecmp_total_cells([R, B], N),
    N == 4.

test(total_cells_empty) :-
    scenecmp_total_cells([], N),
    N == 0.

% --- scenecmp_colors/2 ---

test(colors_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_colors([R, B, G], Colors),
    Colors == [b, g, r].

test(colors_duplicates_removed) :-
    red_dot(R), red_bar(RB),
    scenecmp_colors([R, RB], Colors),
    Colors == [r].

test(colors_empty) :-
    scenecmp_colors([], Colors),
    Colors == [].

% --- scenecmp_forms/2 ---

test(forms_basic) :-
    red_dot(R), red_bar(RB),
    scenecmp_forms([R, RB], Forms),
    % dot form: [r(0,0)]; bar form: [r(0,0),r(0,1),r(0,2)]
    length(Forms, 2).

test(forms_duplicates_removed) :-
    red_dot(R), blue_dot(B),
    % both are single-cell; same normalized form [r(0,0)]
    scenecmp_forms([R, B], Forms),
    Forms == [[r(0,0)]].

% --- scenecmp_same_n_objs/2 ---

test(same_n_objs_true) :-
    red_dot(R), blue_dot(B),
    scenecmp_same_n_objs([R], [B]).

test(same_n_objs_false) :-
    red_dot(R), blue_dot(B), green_dot(G),
    \+ scenecmp_same_n_objs([R, B], [G]).

test(same_n_objs_empty) :-
    scenecmp_same_n_objs([], []).

% --- scenecmp_same_total_cells/2 ---

test(same_total_cells_true) :-
    red_dot(R), blue_dot(B),
    scenecmp_same_total_cells([R], [B]).

test(same_total_cells_multi) :-
    red_dot(R), red_bar(B), blue_dot(BD), blue_bar(BB),
    % 1+3 = 1+3
    scenecmp_same_total_cells([R, B], [BD, BB]).

test(same_total_cells_false) :-
    red_dot(R), red_bar(RB),
    \+ scenecmp_same_total_cells([R], [RB]).

% --- scenecmp_same_colors/2 ---

test(same_colors_true) :-
    red_dot(R), blue_dot(B), red_bar(RB), blue_bar(BB),
    scenecmp_same_colors([R, B], [RB, BB]).

test(same_colors_false) :-
    red_dot(R), blue_dot(B), green_dot(G),
    \+ scenecmp_same_colors([R, B], [B, G]).

% --- scenecmp_same_forms/2 ---

test(same_forms_true) :-
    red_dot(R), blue_dot(B),
    % both are single dots; same form
    scenecmp_same_forms([R], [B]).

test(same_forms_false) :-
    red_dot(R), red_bar(RB),
    \+ scenecmp_same_forms([R], [RB]).

% --- scenecmp_added_colors/3 ---

test(added_colors_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_added_colors([R, B], [R, B, G], Added),
    Added == [g].

test(added_colors_none) :-
    red_dot(R), blue_dot(B),
    scenecmp_added_colors([R, B], [R, B], Added),
    Added == [].

test(added_colors_all_new) :-
    red_dot(R), blue_dot(B),
    scenecmp_added_colors([], [R, B], Added),
    Added == [b, r].

% --- scenecmp_removed_colors/3 ---

test(removed_colors_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_removed_colors([R, B, G], [R, B], Removed),
    Removed == [g].

test(removed_colors_none) :-
    red_dot(R), blue_dot(B),
    scenecmp_removed_colors([R, B], [R, B], Removed),
    Removed == [].

% --- scenecmp_added_forms/3 ---

test(added_forms_basic) :-
    red_dot(R), red_bar(RB),
    scenecmp_added_forms([R], [R, RB], Added),
    length(Added, 1).

test(added_forms_none) :-
    red_dot(R), blue_dot(B),
    % same single-cell form
    scenecmp_added_forms([R], [B], Added),
    Added == [].

% --- scenecmp_removed_forms/3 ---

test(removed_forms_basic) :-
    red_dot(R), red_bar(RB),
    scenecmp_removed_forms([R, RB], [R], Removed),
    length(Removed, 1).

% --- scenecmp_n_color_change/3 ---

test(n_color_change_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    % Before: r,b; After: r,g -> removed b, added g -> 2
    scenecmp_n_color_change([R, B], [R, G], N),
    N == 2.

test(n_color_change_none) :-
    red_dot(R), blue_dot(B),
    scenecmp_n_color_change([R, B], [R, B], N),
    N == 0.

test(n_color_change_only_added) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_n_color_change([R, B], [R, B, G], N),
    N == 1.

% --- scenecmp_any_change/2 ---

test(any_change_color) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_any_change([R, B], [R, G]).

test(any_change_count) :-
    red_dot(R), blue_dot(B), green_dot(G),
    scenecmp_any_change([R, B], [R, B, G]).

test(any_change_form) :-
    red_dot(R), red_bar(RB),
    scenecmp_any_change([R], [RB]).

test(no_change_equal) :-
    red_dot(R), blue_dot(B),
    \+ scenecmp_any_change([R, B], [R, B]).

test(no_change_same_colors_forms_count) :-
    red_dot(R), blue_bar(BB), blue_dot(BD), red_bar(RB),
    % Before: [red_dot, blue_bar] — colors {r,b}, forms {dot,bar}
    % After:  [blue_dot, red_bar] — colors {r,b}, forms {dot,bar}
    \+ scenecmp_any_change([R, BB], [BD, RB]).

test(total_cells_three) :-
    red_dot(R), red_bar(B), red_sq(S),
    scenecmp_total_cells([R, B, S], N),
    N == 8.

test(n_color_change_all_replaced) :-
    red_dot(R), blue_dot(B),
    % Before: {r,b}; After: {g} -> remove r and b, add g -> 3
    green_dot(G), green_dot(G2),
    scenecmp_n_color_change([R, B], [G, G2], N),
    N == 3.

test(added_colors_empty_before) :-
    red_dot(R),
    scenecmp_added_colors([], [R], Added),
    Added == [r].

test(removed_forms_none) :-
    red_dot(R), blue_dot(B),
    scenecmp_removed_forms([R], [B], Removed),
    Removed == [].

test(forms_three_distinct) :-
    red_dot(R), red_bar(RB), lshape(L),
    scenecmp_forms([R, RB, L], Forms),
    length(Forms, 3).

:- end_tests(scenecmp).
