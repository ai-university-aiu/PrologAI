:- use_module('../prolog/link.pl').
:- use_module(library(plunit)).

% Helpers: reusable obj terms.
red1(obj(red,[r(0,0),r(0,1)])).       % 2 cells, centroid (0,0)
blue1(obj(blue,[r(0,2),r(0,3)])).     % 2 cells, centroid (0,2)
green1(obj(green,[r(2,0)])).           % 1 cell, centroid (2,0)
red2(obj(red,[r(3,0),r(3,1)])).       % 2 cells, same form as red1
blue2(obj(blue,[r(3,2)])).             % 1 cell, centroid (3,2)
small(obj(x,[r(0,0)])).               % 1 cell
big(obj(y,[r(0,0),r(0,1),r(1,0)])).   % 3 cells

:- begin_tests(link_by_position).

test(empty_both) :-
    link_by_position([], [], []).

test(empty_first) :-
    red1(R), link_by_position([], [R], []).

test(empty_second) :-
    red1(R), link_by_position([R], [], []).

test(single_pair) :-
    red1(R), blue1(B),
    link_by_position([R], [B], [R-B]).

test(two_pairs) :-
    red1(R), blue1(B), green1(G), red2(R2),
    link_by_position([R, G], [B, R2], [R-B, G-R2]).

test(truncates_at_shorter) :-
    % Three in first, two in second: only two links.
    red1(R), blue1(B), green1(G), red2(R2), blue2(B2),
    link_by_position([R, B, G], [R2, B2], [R-R2, B-B2]).

:- end_tests(link_by_position).

:- begin_tests(link_by_nearest).

test(empty_objs2) :-
    red1(R),
    link_by_nearest([R], [], []).

test(single_pair) :-
    % red1 centroid (0,0), blue2 centroid (3,2): only candidate.
    red1(R), blue2(B),
    link_by_nearest([R], [B], [R-B]).

test(two_candidates_nearer_wins) :-
    % red1 centroid (0,0): green1 (2,0) dist=2, blue1 (0,2) dist=2.
    % Both at dist 2; green1 appears first in Objs2 so wins.
    red1(Ref), green1(G), blue1(B),
    link_by_nearest([Ref], [G, B], [Ref-G]).

test(two_sources) :-
    % red1 (0,0) -> green1 (2,0) nearest; blue1 (0,2) -> green1 is NOT nearest from blue1.
    % blue1 (0,2): green1 (2,0) dist=4, blue2 (3,2) dist=3. blue2 is nearer.
    red1(R), blue1(B), green1(G), blue2(B2),
    link_by_nearest([R, B], [G, B2], [R-G, B-B2]).

:- end_tests(link_by_nearest).

:- begin_tests(link_by_color).

test(no_matching_colors) :-
    red1(R), blue1(B),
    link_by_color([R], [B], []).

test(single_match) :-
    red1(R), red2(R2),
    link_by_color([R], [R2], [R-R2]).

test(multiple_matches) :-
    % Two red objs in each list: 2x2 = 4 links.
    R1 = obj(red,[r(0,0)]), R2 = obj(red,[r(0,1)]),
    R3 = obj(red,[r(1,0)]), R4 = obj(red,[r(1,1)]),
    link_by_color([R1,R2], [R3,R4], Links),
    length(Links, 4).

test(empty_first) :-
    red2(R2),
    link_by_color([], [R2], []).

test(empty_second) :-
    red1(R),
    link_by_color([R], [], []).

:- end_tests(link_by_color).

:- begin_tests(link_by_size).

test(same_size) :-
    % red1 (2 cells) and red2 (2 cells) match; green1 (1 cell) doesn't match red1.
    red1(R), red2(R2), green1(G),
    link_by_size([R, G], [R2], [R-R2]).

test(no_match) :-
    small(S), big(B),
    link_by_size([S], [B], []).

test(empty) :-
    link_by_size([], [], []).

test(all_same_size) :-
    A = obj(a,[r(0,0)]), B = obj(b,[r(1,0)]), C = obj(c,[r(2,0)]),
    link_by_size([A,B], [C], Links),
    length(Links, 2).

:- end_tests(link_by_size).

:- begin_tests(link_by_form).

test(same_form_diff_color) :-
    % red1 and red2 both have form [r(0,0),r(0,1)] after normalization.
    red1(R), red2(R2),
    link_by_form([R], [R2], [R-R2]).

test(difference_form) :-
    % green1 (single cell) vs red1 (2-cell horizontal): different forms.
    green1(G), red1(R),
    link_by_form([G], [R], []).

test(same_form_translated) :-
    % Two horizontally-adjacent-pair objs at different positions: same form.
    A = obj(a,[r(0,0),r(0,1)]),
    B = obj(b,[r(5,5),r(5,6)]),
    link_by_form([A], [B], [A-B]).

test(empty) :-
    link_by_form([], [], []).

:- end_tests(link_by_form).

:- begin_tests(link_source).

test(empty) :-
    link_source([], []).

test(single) :-
    red1(R), blue1(B),
    link_source([R-B], [R]).

test(multiple) :-
    red1(R), blue1(B), green1(G), red2(R2),
    link_source([R-B, G-R2], [R, G]).

:- end_tests(link_source).

:- begin_tests(link_target).

test(empty) :-
    link_target([], []).

test(single) :-
    red1(R), blue1(B),
    link_target([R-B], [B]).

test(multiple) :-
    red1(R), blue1(B), green1(G), red2(R2),
    link_target([R-B, G-R2], [B, R2]).

:- end_tests(link_target).

:- begin_tests(link_invert).

test(empty) :-
    link_invert([], []).

test(single) :-
    red1(R), blue1(B),
    link_invert([R-B], [B-R]).

test(multiple) :-
    red1(R), blue1(B), green1(G), red2(R2),
    link_invert([R-B, G-R2], [B-R, R2-G]).

:- end_tests(link_invert).

:- begin_tests(link_count).

test(empty) :-
    link_count([], 0).

test(single) :-
    red1(R), blue1(B),
    link_count([R-B], 1).

test(three) :-
    red1(R), blue1(B), green1(G), red2(R2), blue2(B2),
    link_count([R-B, G-R2, B-B2], 3).

:- end_tests(link_count).

:- begin_tests(link_apply_color).

test(empty) :-
    link_apply_color([], []).

test(single_recolor) :-
    % Link: obj(red,[r(0,0)])-obj(blue,[r(1,0)]). Result: obj(blue,[r(0,0)]).
    A = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    link_apply_color([A-B], [obj(blue,[r(0,0)])]).

test(two_links) :-
    A = obj(red,[r(0,0)]),   B = obj(blue,[r(1,0)]),
    C = obj(green,[r(2,0)]), D = obj(yellow,[r(3,0)]),
    link_apply_color([A-B, C-D], [obj(blue,[r(0,0)]), obj(yellow,[r(2,0)])]).

:- end_tests(link_apply_color).

:- begin_tests(link_apply_cells).

test(empty) :-
    link_apply_cells([], []).

test(single_replace_cells) :-
    % Link: obj(red,[r(0,0)])-obj(blue,[r(1,0),r(1,1)]). Result: obj(red,[r(1,0),r(1,1)]).
    A = obj(red,[r(0,0)]), B = obj(blue,[r(1,0),r(1,1)]),
    link_apply_cells([A-B], [obj(red,[r(1,0),r(1,1)])]).

test(two_links) :-
    A = obj(red,[r(0,0)]),   B = obj(blue,[r(5,5)]),
    C = obj(green,[r(1,0)]), D = obj(yellow,[r(6,6)]),
    link_apply_cells([A-B, C-D], [obj(red,[r(5,5)]), obj(green,[r(6,6)])]).

:- end_tests(link_apply_cells).

:- begin_tests(link_filter_same_color).

test(all_same) :-
    R1 = obj(red,[r(0,0)]), R2 = obj(red,[r(1,0)]),
    link_filter_same_color([R1-R2], [R1-R2]).

test(none_same) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    link_filter_same_color([R-B], []).

test(mixed) :-
    R1 = obj(red,[r(0,0)]), R2 = obj(red,[r(1,0)]),
    B = obj(blue,[r(2,0)]),
    link_filter_same_color([R1-R2, R1-B], [R1-R2]).

test(empty) :-
    link_filter_same_color([], []).

:- end_tests(link_filter_same_color).

:- begin_tests(link_filter_diff_color).

test(all_diff) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    link_filter_diff_color([R-B], [R-B]).

test(none_diff) :-
    R1 = obj(red,[r(0,0)]), R2 = obj(red,[r(1,0)]),
    link_filter_diff_color([R1-R2], []).

test(mixed) :-
    R1 = obj(red,[r(0,0)]), R2 = obj(red,[r(1,0)]),
    B = obj(blue,[r(2,0)]),
    link_filter_diff_color([R1-R2, R1-B], [R1-B]).

:- end_tests(link_filter_diff_color).

:- begin_tests(link_unlinked).

test(all_linked) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    link_unlinked([R], [R-B], []).

test(none_linked) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    G = obj(green,[r(2,0)]),
    link_unlinked([G], [R-B], [G]).

test(partial) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    G = obj(green,[r(2,0)]),
    link_unlinked([R, G], [R-B], [G]).

test(empty_objs) :-
    R = obj(red,[r(0,0)]), B = obj(blue,[r(1,0)]),
    link_unlinked([], [R-B], []).

test(empty_links) :-
    R = obj(red,[r(0,0)]),
    link_unlinked([R], [], [R]).

:- end_tests(link_unlinked).
