:- use_module('../prolog/proximity.pl').
:- use_module(library(plunit)).

% Helper: objects used across tests.
% O_red_topleft: red object at rows 0-1, cols 0-1 (centroid 0,0).
o_red(obj(red, [r(0,0), r(0,1), r(1,0), r(1,1)])).
% O_blue_bottomright: blue object at rows 4-5, cols 4-5 (centroid 4,4).
o_blue(obj(blue, [r(4,4), r(4,5), r(5,4), r(5,5)])).
% O_green_mid: green object at row 2, col 2 (centroid 2,2).
o_green(obj(green, [r(2,2)])).
% O_yellow_near_red: yellow single cell at r(0,2) (centroid 0,2).
o_yellow(obj(yellow, [r(0,2)])).
% O_purple: purple single cell at r(3,0) (centroid 3,0).
o_purple(obj(purple, [r(3,0)])).
% O_orange: single cell at r(1,1) - adjacent to red's r(1,1)? No, same cell - use r(1,2).
o_orange(obj(orange, [r(1,2)])).

:- begin_tests(px_centroid).

test(single_cell) :-
% Single cell at r(3,5): centroid is (3,5).
    px_centroid(obj(red,[r(3,5)]), 3, 5).

test(four_cells_square) :-
% 2x2 square at (0,0)..(1,1): centroid is (0,0) via integer truncation.
    px_centroid(obj(red,[r(0,0),r(0,1),r(1,0),r(1,1)]), R, C),
    R =:= 0, C =:= 0.

test(four_cells_offset) :-
% 2x2 square at (4,4)..(5,5): centroid is (4,4) via truncation.
    px_centroid(obj(blue,[r(4,4),r(4,5),r(5,4),r(5,5)]), R, C),
    R =:= 4, C =:= 4.

test(three_cells_truncate) :-
% Cells at r(0,0), r(0,1), r(0,2): sum_R=0, sum_C=3, N=3 -> C=1.
    px_centroid(obj(x,[r(0,0),r(0,1),r(0,2)]), 0, 1).

:- end_tests(px_centroid).

:- begin_tests(px_centroid_dist).

test(same_centroid) :-
% Two objects at same position: distance 0.
    px_centroid_dist(obj(a,[r(2,2)]), obj(b,[r(2,2)]), 0).

test(row_only_diff) :-
% Objects differ only in row: distance = |3-0| = 3.
    px_centroid_dist(obj(a,[r(0,0)]), obj(b,[r(3,0)]), 3).

test(col_only_diff) :-
% Objects differ only in col: distance = |0-4| = 4.
    px_centroid_dist(obj(a,[r(0,0)]), obj(b,[r(0,4)]), 4).

test(both_diff) :-
% Manhattan distance of (0,0) to (4,4): 4+4=8.
    o_red(R), o_blue(B),
    px_centroid_dist(R, B, 8).

:- end_tests(px_centroid_dist).

:- begin_tests(px_min_cell_dist).

test(adjacent_objects) :-
% Red 2x2 at (0,0)..(1,1), orange at (1,2): min cell dist = |1-1|+|1-2|=1.
    o_red(R), o_orange(O),
    px_min_cell_dist(R, O, 1).

test(separated_objects) :-
% Red at (0,0)..(1,1), green at (2,2): closest pair is r(1,1) vs r(2,2) -> dist=2.
    o_red(R), o_green(G),
    px_min_cell_dist(R, G, 2).

test(same_cell) :-
% Both share cell r(2,2): min dist = 0.
    px_min_cell_dist(obj(a,[r(2,2)]), obj(b,[r(2,2)]), 0).

:- end_tests(px_min_cell_dist).

:- begin_tests(px_touching).

test(horizontally_adjacent) :-
% r(1,1) and r(1,2) are 4-adjacent.
    px_touching(obj(a,[r(1,1)]), obj(b,[r(1,2)])).

test(vertically_adjacent) :-
% r(1,1) and r(2,1) are 4-adjacent.
    px_touching(obj(a,[r(1,1)]), obj(b,[r(2,1)])).

test(not_touching_diagonal) :-
% r(1,1) and r(2,2) are diagonal; not 4-adjacent.
    \+ px_touching(obj(a,[r(1,1)]), obj(b,[r(2,2)])).

test(not_touching_gap) :-
% r(0,0) and r(0,2): distance 2, not adjacent.
    \+ px_touching(obj(a,[r(0,0)]), obj(b,[r(0,2)])).

test(multi_cell_touching) :-
% Red 2x2 includes r(0,1); yellow is at r(0,2): adjacent.
    o_red(R), o_yellow(Y),
    px_touching(R, Y).

:- end_tests(px_touching).

:- begin_tests(px_nearest).

test(single_candidate) :-
% Only one candidate: it is nearest regardless of distance.
    o_red(R), o_blue(B),
    px_nearest([B], R, B).

test(two_candidates_closer_first) :-
% Green at (2,2) is closer to red(0,0) than blue(4,4): centroid dists 4 vs 8.
    o_red(Ref), o_green(G), o_blue(B),
    px_nearest([G, B], Ref, G).

test(two_candidates_closer_second) :-
% Blue(4,4) and green(2,2): nearest to blue is green (dist 4 vs 8).
    o_blue(Ref), o_green(G), o_red(R),
    px_nearest([R, G], Ref, G).

test(tie_broken_by_order) :-
% Two candidates equidistant from ref; first one wins.
    Ref = obj(x,[r(0,0)]),
    A = obj(a,[r(0,2)]),
    B = obj(b,[r(2,0)]),
    % Both are distance 2 from ref.
    px_nearest([A, B], Ref, A).

:- end_tests(px_nearest).

:- begin_tests(px_farthest).

test(single_candidate) :-
    o_red(R), o_blue(B),
    px_farthest([B], R, B).

test(two_candidates) :-
% Blue(4,4) is farther from red(0,0) than green(2,2): dist 8 vs 4.
    o_red(Ref), o_green(G), o_blue(B),
    px_farthest([G, B], Ref, B).

test(tie_broken_by_order) :-
% Two equidistant candidates: first wins.
    Ref = obj(x,[r(2,2)]),
    A = obj(a,[r(0,0)]),
    B = obj(b,[r(4,4)]),
    % Both are distance 4 from ref.
    px_farthest([A, B], Ref, A).

:- end_tests(px_farthest).

:- begin_tests(px_sort_by_dist).

test(already_sorted) :-
% Yellow(0,2) dist 2, green(2,2) dist 4, blue(4,4) dist 8 from red(0,0).
    o_red(Ref), o_yellow(Y), o_green(G), o_blue(B),
    px_sort_by_dist([Y,G,B], Ref, [Y,G,B]).

test(reverse_order) :-
% Blue, green, yellow from red: should sort to yellow, green, blue.
    o_red(Ref), o_yellow(Y), o_green(G), o_blue(B),
    px_sort_by_dist([B,G,Y], Ref, [Y,G,B]).

test(single_element) :-
    o_red(R), o_blue(B),
    px_sort_by_dist([B], R, [B]).

test(empty) :-
    o_red(R),
    px_sort_by_dist([], R, []).

:- end_tests(px_sort_by_dist).

:- begin_tests(px_within_dist).

test(all_within) :-
% Yellow(0,2) dist 2, green(2,2) dist 4 from red(0,0): all within 4.
    o_red(Ref), o_yellow(Y), o_green(G),
    px_within_dist([Y,G], Ref, 4, [Y,G]).

test(none_within) :-
% Blue(4,4) dist 8 from red: none within 4.
    o_red(Ref), o_blue(B),
    px_within_dist([B], Ref, 4, []).

test(partial) :-
% Yellow(dist 2) within 3, green(dist 4) not within 3.
    o_red(Ref), o_yellow(Y), o_green(G),
    px_within_dist([Y,G], Ref, 3, [Y]).

test(exact_boundary) :-
% Yellow at dist 2: within 2 (boundary inclusive).
    o_red(Ref), o_yellow(Y),
    px_within_dist([Y], Ref, 2, [Y]).

:- end_tests(px_within_dist).

:- begin_tests(px_beyond_dist).

test(all_beyond) :-
% Blue(dist 8) and green(dist 4) from red: both beyond 3.
    o_red(Ref), o_blue(B), o_green(G),
    px_beyond_dist([B,G], Ref, 3, [B,G]).

test(none_beyond) :-
% Yellow(dist 2) is not beyond 4.
    o_red(Ref), o_yellow(Y),
    px_beyond_dist([Y], Ref, 4, []).

test(exact_not_beyond) :-
% Yellow at dist 2: not beyond 2 (strict inequality).
    o_red(Ref), o_yellow(Y),
    px_beyond_dist([Y], Ref, 2, []).

test(partial) :-
% Yellow(dist 2) not beyond 3, blue(dist 8) is beyond 3.
    o_red(Ref), o_yellow(Y), o_blue(B),
    px_beyond_dist([Y,B], Ref, 3, [B]).

:- end_tests(px_beyond_dist).

:- begin_tests(px_closest_pair).

test(two_objects) :-
% Red(0,0) and green(2,2): centroid dist = 4.
    o_red(R), o_green(G),
    px_closest_pair([R,G], R-G).

test(three_objects_min_pair) :-
% Red(0,0), yellow(0,2), green(2,2): dists red-yellow=2, red-green=4, yellow-green=2.
% Min dist is 2 (tie between red-yellow and yellow-green). First pair by index order wins.
    o_red(R), o_yellow(Y), o_green(G),
    px_closest_pair([R,Y,G], R-Y).

test(order_independent_result) :-
% Green(2,2) and blue(4,4): dist = 4. Only pair, so it is the closest.
    o_green(G), o_blue(B),
    px_closest_pair([G,B], G-B).

:- end_tests(px_closest_pair).

:- begin_tests(px_farthest_pair).

test(two_objects) :-
% Red(0,0) and blue(4,4): centroid dist = 8.
    o_red(R), o_blue(B),
    px_farthest_pair([R,B], R-B).

test(three_objects_max_pair) :-
% Red(0,0), green(2,2), blue(4,4): dists red-green=4, red-blue=8, green-blue=4.
% Max is red-blue at 8.
    o_red(R), o_green(G), o_blue(B),
    px_farthest_pair([R,G,B], R-B).

:- end_tests(px_farthest_pair).

:- begin_tests(px_touching_objs).

test(one_touching) :-
% Orange at r(1,2) touches red 2x2 via r(1,1)-r(1,2).
    o_red(Ref), o_orange(Org), o_blue(B),
    px_touching_objs([Org, B], Ref, [Org]).

test(none_touching) :-
% Blue and green are not touching red.
    o_red(Ref), o_blue(B), o_green(G),
    px_touching_objs([B,G], Ref, []).

test(all_touching) :-
% Yellow at r(0,2) touches red r(0,1); orange at r(1,2) touches red r(1,1).
    o_red(Ref), o_yellow(Y), o_orange(Org),
    px_touching_objs([Y, Org], Ref, [Y, Org]).

test(empty_list) :-
    o_red(Ref),
    px_touching_objs([], Ref, []).

:- end_tests(px_touching_objs).

:- begin_tests(px_non_touching_objs).

test(one_non_touching) :-
% Blue does not touch red; orange does.
    o_red(Ref), o_orange(Org), o_blue(B),
    px_non_touching_objs([Org, B], Ref, [B]).

test(all_non_touching) :-
    o_red(Ref), o_blue(B), o_green(G),
    px_non_touching_objs([B,G], Ref, [B,G]).

test(empty_result) :-
    o_red(Ref), o_yellow(Y), o_orange(Org),
    px_non_touching_objs([Y, Org], Ref, []).

:- end_tests(px_non_touching_objs).

:- begin_tests(px_dist_rank).

test(single_object) :-
    o_red(Ref), o_blue(B),
    px_dist_rank([B], Ref, [8-B]).

test(three_objects_sorted) :-
% Yellow(dist 2), green(dist 4), blue(dist 8) from red.
    o_red(Ref), o_yellow(Y), o_green(G), o_blue(B),
    px_dist_rank([B,Y,G], Ref, [2-Y, 4-G, 8-B]).

test(empty) :-
    o_red(Ref),
    px_dist_rank([], Ref, []).

test(tie_stable_order) :-
% Two objects equidistant: appear in original list order.
    Ref = obj(x,[r(0,0)]),
    A = obj(a,[r(0,2)]),
    B = obj(b,[r(2,0)]),
    px_dist_rank([A,B], Ref, [2-A, 2-B]).

:- end_tests(px_dist_rank).
