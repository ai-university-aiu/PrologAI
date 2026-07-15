:- use_module('../prolog/scenepair').
:- use_module(library(plunit)).

:- begin_tests(scenepair).

% --- Fixtures ---
red_dot(obj(r, [r(0,0)])).
blue_dot(obj(b, [r(0,1)])).
green_dot(obj(g, [r(1,0)])).
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% shifted versions
red_dot_shifted(obj(r, [r(1,1)])).
blue_dot_shifted(obj(b, [r(1,2)])).
red_bar_shifted(obj(r, [r(1,0),r(1,1),r(1,2)])).
blue_bar_shifted(obj(b, [r(2,0),r(2,1),r(2,2)])).

% recolored versions
green_dot_from_red(obj(g, [r(0,0)])).
green_bar_from_red(obj(g, [r(0,0),r(0,1),r(0,2)])).

% --- scenepair_same_n_objs/2 ---

test(same_n_objs_equal) :-
    red_dot(R), blue_dot(B),
    scenepair_same_n_objs([R, B], [B, R]).

test(same_n_objs_unequal) :-
    red_dot(R), blue_dot(B),
    \+ scenepair_same_n_objs([R, B], [R]).

test(same_n_objs_empty) :-
    scenepair_same_n_objs([], []).

% --- scenepair_added_objs/3 ---

test(added_objs_one) :-
    red_dot(R), blue_dot(B),
    scenepair_added_objs([R], [R, B], Added),
    Added == [B].

test(added_objs_none) :-
    red_dot(R), blue_dot(B),
    scenepair_added_objs([R, B], [R, B], []).

test(added_objs_all) :-
    blue_dot(B),
    scenepair_added_objs([], [B], Added),
    Added == [B].

% --- scenepair_removed_objs/3 ---

test(removed_objs_one) :-
    red_dot(R), blue_dot(B),
    scenepair_removed_objs([R, B], [R], Removed),
    Removed == [B].

test(removed_objs_none) :-
    red_dot(R),
    scenepair_removed_objs([R], [R], []).

test(removed_objs_all) :-
    red_dot(R),
    scenepair_removed_objs([R], [], [R]).

% --- scenepair_n_added/3 and scenepair_n_removed/3 ---

test(n_added_basic) :-
    red_dot(R), blue_dot(B),
    scenepair_n_added([R], [R, B], 1).

test(n_removed_basic) :-
    red_dot(R), blue_dot(B),
    scenepair_n_removed([R, B], [R], 1).

test(n_added_zero) :-
    red_dot(R),
    scenepair_n_added([R], [R], 0).

% --- scenepair_color_set_before/2 and scenepair_color_set_after/2 ---

test(color_set_before_basic) :-
    red_dot(R), blue_dot(B),
    scenepair_color_set_before([R, B], Colors),
    Colors == [b, r].

test(color_set_after_basic) :-
    green_dot_from_red(G), blue_dot(B),
    scenepair_color_set_after([G, B], Colors),
    Colors == [b, g].

test(color_set_single) :-
    red_dot(R),
    scenepair_color_set_before([R], [r]).

% --- scenepair_same_color_set/2 ---

test(same_color_set_yes) :-
    red_dot(R), blue_dot(B),
    red_bar(RB),
    scenepair_same_color_set([R, B], [RB, B]).

test(same_color_set_no) :-
    red_dot(R), blue_dot(B), green_dot(G),
    \+ scenepair_same_color_set([R, B], [R, G]).

test(same_color_set_empty) :-
    scenepair_same_color_set([], []).

% --- scenepair_color_delta/3 ---

test(color_delta_basic) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    % R(r) -> G(g), B(b) stays
    scenepair_color_delta([R, B], [G, B], Delta),
    Delta == [r-g].

test(color_delta_no_change) :-
    red_dot(R), blue_dot(B),
    scenepair_color_delta([R, B], [R, B], []).

test(color_delta_diff_length) :-
    red_dot(R), blue_dot(B),
    scenepair_color_delta([R, B], [R], []).

test(color_delta_two_changes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G), lshape(L),
    % R->G (r->g), B->L (b->p) — L is a p-colored obj
    scenepair_color_delta([R, B], [G, L], Delta),
    msort(Delta, Sorted),
    Sorted == [b-p, r-g].

% --- scenepair_is_recolor/2 ---

test(is_recolor_yes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    scenepair_is_recolor([R, B], [G, B]).

test(is_recolor_no_two_changes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G), lshape(L),
    \+ scenepair_is_recolor([R, B], [G, L]).

test(is_recolor_no_length_diff) :-
    red_dot(R), blue_dot(B),
    \+ scenepair_is_recolor([R, B], [R]).

% --- scenepair_is_recolor_all/2 ---

test(is_recolor_all_yes) :-
    red_dot(R), red_bar(RB),
    green_dot_from_red(G), green_bar_from_red(GB),
    scenepair_is_recolor_all([R, RB], [G, GB]).

test(is_recolor_all_already_one_color) :-
    green_dot_from_red(G),
    scenepair_is_recolor_all([G], [G]).

test(is_recolor_all_no) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    % After has r and g — not recolor_all
    \+ scenepair_is_recolor_all([R, B], [G, R]).

% --- scenepair_is_shift/3 ---

test(is_shift_yes) :-
    red_dot(R), blue_dot(B),
    red_dot_shifted(RS), blue_dot_shifted(BS),
    scenepair_is_shift([R, B], [RS, BS], DR, DC),
    DR == 1, DC == 1.

test(is_shift_zero) :-
    red_dot(R),
    scenepair_is_shift([R], [R], DR, DC),
    DR == 0, DC == 0.

test(is_shift_no) :-
    red_dot(R), red_bar(RB),
    \+ scenepair_is_shift([R], [RB], _, _).

% --- scenepair_is_to_origin/2 ---

test(is_to_origin_yes) :-
    % Before: dot at r(2,3); After: dot at r(0,0)
    Before = [obj(r,[r(2,3)])],
    After  = [obj(r,[r(0,0)])],
    scenepair_is_to_origin(Before, After).

test(is_to_origin_already) :-
    red_dot(R),
    scenepair_is_to_origin([R], [R]).

test(is_to_origin_no) :-
    red_dot(R), blue_dot(B),
    \+ scenepair_is_to_origin([R], [B]).

% --- scenepair_size_preserved/2 ---

test(size_preserved_yes) :-
    red_dot(R), green_dot_from_red(G),
    scenepair_size_preserved([R], [G]).

test(size_preserved_bars) :-
    red_bar(RB), blue_bar(BB),
    scenepair_size_preserved([RB], [BB]).

test(size_preserved_no) :-
    red_dot(R), red_bar(RB),
    \+ scenepair_size_preserved([R], [RB]).

test(size_preserved_diff_length) :-
    red_dot(R), blue_dot(B),
    \+ scenepair_size_preserved([R, B], [R]).

% --- Additional coverage tests ---

test(color_delta_swap) :-
    % r->b in first position, b->r in second position
    red_dot(R), blue_dot(B),
    scenepair_color_delta([R, B], [B, R], Delta),
    msort(Delta, Sorted),
    Sorted == [b-r, r-b].

test(added_objs_form_match) :-
    % obj(r,[r(0,0)]) and obj(r,[r(0,0)]) are same color+form -> not added
    red_dot(R),
    scenepair_added_objs([R], [R], []).

test(is_shift_multi_obj_bar) :-
    red_bar(RB), blue_bar(BB),
    red_bar_shifted(RBS),
    % shift [RB, BB] down by 1: expect scenepair_is_shift to detect DR=1, DC=0
    blue_bar_shifted(BBS),
    scenepair_is_shift([RB, BB], [RBS, BBS], DR, DC),
    DR == 1, DC == 0.

:- end_tests(scenepair).
