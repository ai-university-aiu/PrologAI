:- use_module('../prolog/condxf').
:- use_module(library(plunit)).

:- begin_tests(condxf).

% --- Fixtures ---
red_dot(obj(r, [r(0,0)])).
blue_dot(obj(b, [r(0,1)])).
green_dot(obj(g, [r(1,0)])).
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% --- xc_split_color/4 ---

test(split_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    xc_split_color([R, B, RB], r, Match, NoMatch),
    Match == [R, RB],
    NoMatch == [B].

test(split_color_none_match) :-
    red_dot(R), blue_dot(B),
    xc_split_color([R, B], g, Match, NoMatch),
    Match == [],
    NoMatch == [R, B].

test(split_color_all_match) :-
    red_dot(R), red_bar(RB),
    xc_split_color([R, RB], r, Match, NoMatch),
    Match == [R, RB],
    NoMatch == [].

% --- xc_merge/3 ---

test(merge_basic) :-
    red_dot(R), blue_dot(B),
    xc_merge([R], [B], [R, B]).

test(merge_empty_left) :-
    blue_dot(B),
    xc_merge([], [B], [B]).

test(merge_empty_both) :-
    xc_merge([], [], []).

% --- xc_recolor_matching/4 ---

test(recolor_matching_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    xc_recolor_matching([R, B, RB], r, g, Out),
    Out == [obj(g,[r(0,0)]), B, obj(g,[r(0,0),r(0,1),r(0,2)])].

test(recolor_matching_no_match) :-
    red_dot(R), blue_dot(B),
    xc_recolor_matching([R, B], g, y, [R, B]).

% --- xc_shift_color/5 ---

test(shift_color_basic) :-
    red_dot(R), blue_dot(B),
    xc_shift_color([R, B], r, 2, 3, Out),
    Out == [obj(r,[r(2,3)]), B].

test(shift_color_no_match) :-
    red_dot(R),
    xc_shift_color([R], b, 1, 1, [R]).

test(shift_color_multiple) :-
    red_dot(R), red_bar(RB), blue_dot(B),
    xc_shift_color([R, RB, B], r, 1, 0, Out),
    Out == [obj(r,[r(1,0)]), obj(r,[r(1,0),r(1,1),r(1,2)]), B].

% --- xc_swap_colors/4 ---

test(swap_colors_basic) :-
    red_dot(R), blue_dot(B),
    xc_swap_colors([R, B], r, b, [obj(b,[r(0,0)]), obj(r,[r(0,1)])]).

test(swap_colors_no_effect_other) :-
    green_dot(G),
    xc_swap_colors([G], r, b, [G]).

test(swap_colors_single) :-
    red_dot(R),
    xc_swap_colors([R], r, g, [obj(g,[r(0,0)])]).

% --- xc_recolor_by_size/5 ---

test(recolor_by_size_gt) :-
    red_dot(R), red_bar(RB),
    % size > 1: only bar qualifies
    xc_recolor_by_size([R, RB], 1, gt, y, Out),
    Out == [R, obj(y,[r(0,0),r(0,1),r(0,2)])].

test(recolor_by_size_eq) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    % size == 1: dots qualify
    xc_recolor_by_size([R, B, RB], 1, eq, g, Out),
    Out == [obj(g,[r(0,0)]), obj(g,[r(0,1)]), RB].

test(recolor_by_size_lt) :-
    red_dot(R), red_bar(RB),
    % size < 3: dot qualifies
    xc_recolor_by_size([R, RB], 3, lt, g, Out),
    Out == [obj(g,[r(0,0)]), RB].

% --- xc_move_color/5 ---

test(move_color_basic) :-
    red_dot(R), blue_dot(B),
    xc_move_color([R, B], r, 1, 1, Out),
    Out == [obj(r,[r(1,1)]), B].

% --- xc_largest/2 ---

test(largest_basic) :-
    red_dot(R), red_bar(RB),
    xc_largest([R, RB], RB).

test(largest_tie_first) :-
    % two size-1 dots — msort on NegN-Obj: b @< r so blue wins
    red_dot(R), blue_dot(B),
    xc_largest([R, B], B).

% --- xc_smallest/2 ---

test(smallest_basic) :-
    red_dot(R), red_bar(RB),
    xc_smallest([R, RB], R).

test(smallest_tie_first) :-
    % two size-3 bars — msort on N-Obj: b @< r so blue wins
    red_bar(RB), blue_bar(BB),
    xc_smallest([RB, BB], BB).

% --- xc_recolor_largest/3 ---

test(recolor_largest_basic) :-
    red_dot(R), red_bar(RB),
    xc_recolor_largest([R, RB], g, Out),
    Out == [R, obj(g,[r(0,0),r(0,1),r(0,2)])].

test(recolor_largest_single) :-
    red_dot(R),
    xc_recolor_largest([R], g, [obj(g,[r(0,0)])]).

% --- xc_recolor_smallest/3 ---

test(recolor_smallest_basic) :-
    red_dot(R), red_bar(RB),
    xc_recolor_smallest([R, RB], g, Out),
    Out == [obj(g,[r(0,0)]), RB].

% --- xc_unique_size/2 ---

test(unique_size_basic) :-
    red_dot(R), blue_dot(B), lshape(L),
    % R and B both size 1; L is size 3 — unique
    xc_unique_size([R, B, L], L).

test(unique_size_no_unique) :-
    red_dot(R), blue_dot(B),
    % both size 1, no unique size
    \+ xc_unique_size([R, B], _).

test(unique_size_single) :-
    red_dot(R),
    % only one object — its size is unique
    xc_unique_size([R], R).

% --- xc_recolor_unique_size/3 ---

test(recolor_unique_size_basic) :-
    red_dot(R), blue_dot(B), lshape(L),
    % L is the unique-size object
    xc_recolor_unique_size([R, B, L], g, Out),
    Out == [R, B, obj(g,[r(0,0),r(1,0),r(1,1)])].

% --- xc_split_size/5 ---

test(split_size_gt) :-
    red_dot(R), red_bar(RB),
    xc_split_size([R, RB], 1, gt, Match, NoMatch),
    Match == [RB],
    NoMatch == [R].

test(split_size_eq) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    xc_split_size([R, B, RB], 1, eq, Match, NoMatch),
    Match == [R, B],
    NoMatch == [RB].

test(split_size_le) :-
    red_dot(R), lshape(L), red_bar(RB),
    xc_split_size([R, L, RB], 3, le, Match, NoMatch),
    Match == [R, L, RB],
    NoMatch == [].

% --- Additional coverage tests ---

test(split_color_single_match) :-
    red_dot(R),
    xc_split_color([R], r, [R], []).

test(merge_nonempty_right) :-
    red_dot(R), blue_dot(B),
    xc_merge([], [R, B], [R, B]).

test(recolor_matching_all) :-
    red_dot(R), red_bar(RB),
    xc_recolor_matching([R, RB], r, g, Out),
    Out == [obj(g,[r(0,0)]), obj(g,[r(0,0),r(0,1),r(0,2)])].

test(shift_color_all_match) :-
    red_dot(R), red_bar(RB),
    xc_shift_color([R, RB], r, 1, 0, Out),
    Out == [obj(r,[r(1,0)]), obj(r,[r(1,0),r(1,1),r(1,2)])].

test(swap_colors_third_unchanged) :-
    % swapping r<->b leaves g untouched
    green_dot(G), red_dot(R), blue_dot(B),
    xc_swap_colors([G, R, B], r, b, Out),
    Out == [G, obj(b,[r(0,0)]), obj(r,[r(0,1)])].

test(recolor_by_size_ge) :-
    red_dot(R), red_bar(RB),
    % size >= 1: all qualify
    xc_recolor_by_size([R, RB], 1, ge, y, Out),
    Out == [obj(y,[r(0,0)]), obj(y,[r(0,0),r(0,1),r(0,2)])].

test(recolor_by_size_no_match) :-
    red_dot(R), blue_dot(B),
    % size > 5: no object qualifies
    xc_recolor_by_size([R, B], 5, gt, g, [R, B]).

test(split_size_ge) :-
    red_dot(R), lshape(L), red_bar(RB),
    % size >= 3: lshape and bar qualify
    xc_split_size([R, L, RB], 3, ge, Match, NoMatch),
    Match == [L, RB],
    NoMatch == [R].

test(recolor_unique_size_no_unique) :-
    % when no unique-size object exists, recolor_unique_size fails
    red_dot(R), blue_dot(B),
    \+ xc_recolor_unique_size([R, B], g, _).

:- end_tests(condxf).

:- begin_tests(xc_infer_gate).

% Dataset where only color 3 is a valid gate:
% Pairs A/B both have colors 1 and 2 mixed equally, so color 1 and 2 alone don't separate.
% But color 3 perfectly separates: pairs WITH color 3 all lose it; pairs WITHOUT never lose it.
test(infer_gate_finds_a_gate) :-
    PA = pair([obj(3, [r(0,0)]), obj(1, [r(0,1)])], [obj(1, [r(0,1)])]),  % has 3, loses 3
    PB = pair([obj(3, [r(0,0)]), obj(2, [r(0,1)])], [obj(2, [r(0,1)])]),  % has 3, loses 3
    PC = pair([obj(1, [r(0,0)])], [obj(1, [r(0,0)])]),                     % no 3, no change
    PD = pair([obj(2, [r(0,0)])], [obj(2, [r(0,0)])]),                     % no 3, no change
    xc_infer_gate([PA, PB, PC, PD], [], gate_color(3)).

% Result is always a gate_color term when a valid gate exists.
test(infer_gate_returns_gate_color_term) :-
    PA = pair([obj(3, [r(0,0)]), obj(1, [r(0,1)])], [obj(1, [r(0,1)])]),
    PB = pair([obj(3, [r(0,0)]), obj(2, [r(0,1)])], [obj(2, [r(0,1)])]),
    PC = pair([obj(1, [r(0,0)])], [obj(1, [r(0,0)])]),
    PD = pair([obj(2, [r(0,0)])], [obj(2, [r(0,0)])]),
    xc_infer_gate([PA, PB, PC, PD], [], Gate),
    Gate = gate_color(_).

% Fails when all pairs have the same change signature regardless of any color.
test(infer_gate_fails_no_distinction) :-
    % Both pairs have identical change signatures regardless of color presence.
    PA = pair([obj(1, [r(0,0)])], [obj(1, [r(0,0)])]),
    PB = pair([obj(2, [r(0,0)])], [obj(2, [r(0,0)])]),
    \+ xc_infer_gate([PA, PB], [], _).

% Fails when only one pair exists (cannot split into two non-empty groups).
test(infer_gate_fails_single_pair) :-
    PA = pair([obj(1, [r(0,0)])], []),
    \+ xc_infer_gate([PA], [], _).

:- end_tests(xc_infer_gate).
