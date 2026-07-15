:- use_module('../prolog/objmatch').
:- use_module(library(plunit)).

:- begin_tests(objmatch).

% --- Test fixtures ---
% red dot at r(0,0)
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,0)
blue_dot(obj(b, [r(0,0)])).
% green dot at r(0,0)
green_dot(obj(g, [r(0,0)])).
% red bar: 3 cells horizontal at r(0,0)..r(0,2)
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
% blue bar: 3 cells horizontal at r(0,0)..r(0,2)
blue_bar(obj(b, [r(0,0),r(0,1),r(0,2)])).
% yellow bar at r(1,0)..r(1,2)
yellow_bar(obj(y, [r(1,0),r(1,1),r(1,2)])).
% red dot at r(5,5)
red_dot_far(obj(r, [r(5,5)])).
% blue dot at r(2,2)
blue_dot22(obj(b, [r(2,2)])).
% green bar at r(0,0)..r(0,1) — size 2
green_small(obj(g, [r(0,0),r(0,1)])).
% L-shape: r(0,0),r(1,0),r(1,1) — size 3
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
% L-shape at different position: r(3,4),r(4,4),r(4,5)
lshape_far(obj(y, [r(3,4),r(4,4),r(4,5)])).
% Red dot at r(1,1)
red_dot11(obj(r, [r(1,1)])).
% Blue dot at r(3,3)
blue_dot33(obj(b, [r(3,3)])).

% --- objmatch_by_color/3 ---

test(by_color_basic) :-
    red_dot(R), blue_dot(B),
    red_bar(RB), blue_bar(BB),
    objmatch_by_color([R, B], [RB, BB], Pairs),
    member(R-RB, Pairs),
    member(B-BB, Pairs).

test(by_color_no_match) :-
    red_dot(R),
    blue_bar(BB),
    objmatch_by_color([R], [BB], Pairs),
    Pairs == [].

test(by_color_all_same_color) :-
    red_dot(R1), red_bar(R2), red_dot_far(R3),
    objmatch_by_color([R1], [R2, R3], Pairs),
    length(Pairs, 2).

% --- objmatch_by_size/3 ---

test(by_size_basic) :-
    red_dot(R), blue_dot(B),
    objmatch_by_size([R], [B], Pairs),
    Pairs == [R-B].

test(by_size_no_match) :-
    red_dot(R), red_bar(RB),
    objmatch_by_size([R], [RB], Pairs),
    Pairs == [].

test(by_size_multiple) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objmatch_by_size([R], [B, G], Pairs),
    length(Pairs, 2).

% --- objmatch_by_form/3 ---

test(by_form_matching) :-
    lshape(L), lshape_far(LF),
    objmatch_by_form([L], [LF], Pairs),
    Pairs == [L-LF].

test(by_form_no_match) :-
    red_dot(R), red_bar(RB),
    objmatch_by_form([R], [RB], Pairs),
    Pairs == [].

test(by_form_same_color_different_form) :-
    red_dot(R), red_bar(RB),
    objmatch_by_form([R], [RB], Pairs),
    Pairs == [].

% --- objmatch_by_nearest/3 ---

test(by_nearest_basic) :-
    red_dot(R),         % at r(0,0)
    red_dot_far(RF),    % at r(5,5)
    blue_dot22(B),      % at r(2,2) — dist^2 from R: 8; from RF: 18
    red_dot11(R11),     % at r(1,1) — dist^2 from R: 2 (closer); from RF: 32
    % Greedy: R claims R11 (nearest), RF then takes B
    objmatch_by_nearest([R, RF], [B, R11], Pairs),
    Pairs == [R-R11, RF-B].

test(by_nearest_single) :-
    red_dot(R),
    blue_dot22(B),
    objmatch_by_nearest([R], [B], Pairs),
    Pairs == [R-B].

test(by_nearest_two) :-
    red_dot(R1),       % at r(0,0)
    red_dot11(R2),     % at r(1,1)
    blue_dot(B1),      % at r(0,0)
    blue_dot22(B2),    % at r(2,2)
    % R1 nearest to B1 (dist=0); R2 nearest to B2 (dist^2=2)
    objmatch_by_nearest([R1, R2], [B1, B2], Pairs),
    Pairs == [R1-B1, R2-B2].

test(by_nearest_empty_list2) :-
    red_dot(R),
    objmatch_by_nearest([R], [], Pairs),
    Pairs == [].

% --- objmatch_unmatched/5 ---

test(unmatched_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    Pairs = [R-B],
    objmatch_unmatched(Pairs, [R, G], [B, G], Um1, Um2),
    Um1 == [G],
    Um2 == [G].

test(unmatched_all_matched) :-
    red_dot(R), blue_dot(B),
    Pairs = [R-B],
    objmatch_unmatched(Pairs, [R], [B], Um1, Um2),
    Um1 == [],
    Um2 == [].

test(unmatched_empty_pairs) :-
    red_dot(R), blue_dot(B),
    objmatch_unmatched([], [R], [B], Um1, Um2),
    Um1 == [R],
    Um2 == [B].

% --- objmatch_filter_changed_color/2 ---

test(filter_changed_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    % R-B: color changed; R-G: color changed; (same color pair would be R-R)
    objmatch_filter_changed_color([R-B, R-G], Changed),
    length(Changed, 2).

test(filter_changed_none) :-
    red_dot(R1), red_dot_far(R2),
    objmatch_filter_changed_color([R1-R2], Changed),
    Changed == [].

test(filter_changed_mixed) :-
    red_dot(R), blue_dot(B), red_dot_far(R2),
    objmatch_filter_changed_color([R-B, R-R2], Changed),
    Changed == [R-B].

% --- objmatch_filter_same_color/2 ---

test(filter_same_basic) :-
    red_dot(R), red_dot_far(R2), blue_dot(B),
    objmatch_filter_same_color([R-R2, R-B], Same),
    Same == [R-R2].

test(filter_same_empty) :-
    red_dot(R), blue_dot(B),
    objmatch_filter_same_color([R-B], Same),
    Same == [].

% --- objmatch_color_deltas/2 ---

test(color_deltas_basic) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objmatch_color_deltas([R-B, R-G], Deltas),
    Deltas == [r-b, r-g].

test(color_deltas_empty) :-
    objmatch_color_deltas([], Deltas),
    Deltas == [].

% --- objmatch_pos_deltas/2 ---

test(pos_deltas_basic) :-
    red_dot(R),         % centroid r(0,0)
    blue_dot22(B),      % centroid r(2,2)
    objmatch_pos_deltas([R-B], Deltas),
    Deltas == [dr(2,2)].

test(pos_deltas_zero) :-
    red_dot(R), blue_dot(B),  % both at r(0,0)
    objmatch_pos_deltas([R-B], Deltas),
    Deltas == [dr(0,0)].

% --- objmatch_size_deltas/2 ---

test(size_deltas_basic) :-
    red_dot(R), red_bar(RB),  % size 1 -> 3, delta = 2
    objmatch_size_deltas([R-RB], Deltas),
    Deltas == [2].

test(size_deltas_negative) :-
    red_bar(RB), red_dot(R),  % size 3 -> 1, delta = -2
    objmatch_size_deltas([RB-R], Deltas),
    Deltas == [-2].

test(size_deltas_zero) :-
    red_dot(R), blue_dot(B),
    objmatch_size_deltas([R-B], Deltas),
    Deltas == [0].

% --- objmatch_all_same_color_delta/1 ---

test(all_same_color_delta_true) :-
    red_dot(R1), blue_dot(B1),
    red_dot11(R2), blue_dot22(B2),
    % Both pairs: r -> b
    objmatch_all_same_color_delta([R1-B1, R2-B2]).

test(all_same_color_delta_false) :-
    red_dot(R), blue_dot(B), green_dot(G),
    % Pairs: r->b and r->g — not same delta
    \+ objmatch_all_same_color_delta([R-B, R-G]).

test(all_same_color_delta_empty) :-
    objmatch_all_same_color_delta([]).

% --- objmatch_all_same_pos_delta/1 ---

test(all_same_pos_delta_true) :-
    red_dot(R1),     % r(0,0)
    red_dot11(R2),   % r(1,1) — delta dr(1,1)
    % Both are the same dr(1,1) delta so all_same_pos_delta holds for one pair.
    objmatch_all_same_pos_delta([R1-R2]).

test(all_same_pos_delta_two_equal) :-
    red_dot(R1),     % r(0,0)
    red_dot11(R2),   % r(1,1) — delta dr(1,1)
    blue_dot22(B2),  % r(2,2) — delta dr(2,2) from r(0,0)
    blue_dot(B1),    % r(0,0)
    % R1->R2 delta=dr(1,1); B1->B2 delta=dr(2,2) — NOT equal
    \+ objmatch_all_same_pos_delta([R1-R2, B1-B2]).

test(all_same_pos_delta_empty) :-
    objmatch_all_same_pos_delta([]).

% --- objmatch_all_same_size_delta/1 ---

test(all_same_size_delta_true) :-
    red_dot(R1), red_bar(RB1),   % 1->3, delta=2
    blue_dot(B1), blue_bar(BB1), % 1->3, delta=2
    objmatch_all_same_size_delta([R1-RB1, B1-BB1]).

test(all_same_size_delta_false) :-
    red_dot(R), red_bar(RB),       % 1->3, delta=2
    blue_dot(B), green_small(GS),  % 1->2, delta=1
    \+ objmatch_all_same_size_delta([R-RB, B-GS]).

test(all_same_size_delta_empty) :-
    objmatch_all_same_size_delta([]).

% --- objmatch_zip/3 ---

test(zip_basic) :-
    red_dot(R), blue_dot(B),
    red_bar(RB), blue_bar(BB),
    objmatch_zip([R, B], [RB, BB], Pairs),
    Pairs == [R-RB, B-BB].

test(zip_single) :-
    red_dot(R), blue_dot(B),
    objmatch_zip([R], [B], Pairs),
    Pairs == [R-B].

test(zip_empty) :-
    objmatch_zip([], [], Pairs),
    Pairs == [].

test(zip_three) :-
    red_dot(R), blue_dot(B), green_dot(G),
    red_bar(RB), blue_bar(BB), yellow_bar(YB),
    objmatch_zip([R, B, G], [RB, BB, YB], Pairs),
    length(Pairs, 3),
    nth0(0, Pairs, R-RB),
    nth0(1, Pairs, B-BB),
    nth0(2, Pairs, G-YB).

:- end_tests(objmatch).
