:- use_module('../prolog/object_locate').
:- use_module(library(plunit)).
:- use_module(library(lists), [memberchk/2]).

:- begin_tests(object_locate).

% --- Test fixtures ---
% red dot at r(0,0) — centroid (0,0)
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,2) — centroid (0,2)
blue_dot_r(obj(b, [r(0,2)])).
% green dot at r(2,0) — centroid (2,0)
green_dot_b(obj(g, [r(2,0)])).
% yellow dot at r(2,2) — centroid (2,2)
yellow_dot_br(obj(y, [r(2,2)])).
% red bar: 3 cells r(1,0)..r(1,2) — centroid (1,1)
red_bar(obj(r, [r(1,0),r(1,1),r(1,2)])).
% blue bar: 3 cells r(3,0)..r(3,2) — centroid (3,1)
blue_bar(obj(b, [r(3,0),r(3,1),r(3,2)])).
% anchor: 2x2 red square at r(1,1)..r(2,2) — centroid (1.5, 1.5)
anchor(obj(r, [r(1,1),r(1,2),r(2,1),r(2,2)])).
% L-shape: r(0,0),r(1,0),r(1,1) — same form as lshape_far
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
% L-shape far at r(3,3): r(3,3),r(4,3),r(4,4) — same normalized form
lshape_far(obj(b, [r(3,3),r(4,3),r(4,4)])).
% cell just below red_dot: at r(1,0) — touches red_dot from below
touch_below(obj(g, [r(1,0)])).
% cell just right of red_dot: at r(0,1) — touches red_dot on right
touch_right(obj(b, [r(0,1)])).
% cell diagonal to red_dot: at r(1,1) — 8-adjacent but not 4-adjacent
diag_neighbor(obj(y, [r(1,1)])).

% --- object_locate_above/3 ---

test(above_basic) :-
    red_dot(R),     % centroid (0,0)
    red_bar(B),     % centroid (1,1)
    blue_bar(BB),   % centroid (3,1)
    % Ref is red_bar at row 1; objects above: red_dot at row 0
    object_locate_above([R, B, BB], B, Found),
    Found == [R].

test(above_none) :-
    red_dot(R), red_bar(B),
    % Ref is red_dot at row 0; nothing above
    object_locate_above([R, B], R, Found),
    Found == [].

test(above_multiple) :-
    red_dot(R),   % row 0
    red_bar(B),   % row 1
    blue_bar(BB), % row 3
    % Ref is blue_bar at row 3; R and B are above
    object_locate_above([R, B, BB], BB, Found),
    length(Found, 2).

% --- object_locate_below/3 ---

test(below_basic) :-
    red_dot(R),   % row 0
    red_bar(B),   % row 1
    blue_bar(BB), % row 3
    % Ref is red_bar at row 1; blue_bar is below
    object_locate_below([R, B, BB], B, Found),
    Found == [BB].

test(below_none) :-
    blue_bar(BB), red_dot(R),
    object_locate_below([R, BB], BB, Found),
    Found == [].

% --- object_locate_left_of/3 ---

test(left_of_basic) :-
    red_dot(R),      % col 0
    blue_dot_r(BD),  % col 2
    % Ref is blue_dot_r; red_dot is left
    object_locate_left_of([R, BD], BD, Found),
    Found == [R].

test(left_of_none) :-
    red_dot(R), blue_dot_r(BD),
    object_locate_left_of([R, BD], R, Found),
    Found == [].

% --- object_locate_right_of/3 ---

test(right_of_basic) :-
    red_dot(R),      % col 0
    blue_dot_r(BD),  % col 2
    object_locate_right_of([R, BD], R, Found),
    Found == [BD].

% --- object_locate_touching4/3 ---

test(touching4_basic) :-
    red_dot(R),          % r(0,0)
    touch_below(TB),     % r(1,0) — 4-adjacent below
    touch_right(TR),     % r(0,1) — 4-adjacent right
    diag_neighbor(DN),   % r(1,1) — diagonal only
    object_locate_touching4([TB, TR, DN], R, Found),
    length(Found, 2),
    memberchk(TB, Found),
    memberchk(TR, Found).

test(touching4_none) :-
    red_dot(R), yellow_dot_br(Y),
    % r(0,0) and r(2,2): not adjacent
    object_locate_touching4([Y], R, Found),
    Found == [].

% --- object_locate_touching8/3 ---

test(touching8_includes_diagonal) :-
    red_dot(R),          % r(0,0)
    diag_neighbor(DN),   % r(1,1) — 8-adjacent
    object_locate_touching8([DN], R, Found),
    Found == [DN].

test(touching8_not_distant) :-
    red_dot(R), yellow_dot_br(Y),
    object_locate_touching8([Y], R, Found),
    Found == [].

% --- object_locate_overlapping/3 ---

test(overlapping_basic) :-
    red_dot(R), % r(0,0)
    % make an obj that shares r(0,0)
    Shared = obj(b, [r(0,0), r(0,1)]),
    object_locate_overlapping([Shared], R, Found),
    Found == [Shared].

test(overlapping_none) :-
    red_dot(R), blue_dot_r(BD),
    object_locate_overlapping([BD], R, Found),
    Found == [].

% --- object_locate_same_color/3 ---

test(same_color_basic) :-
    red_dot(R), red_bar(RB), blue_bar(BB),
    object_locate_same_color([R, RB, BB], R, Found),
    length(Found, 2),
    memberchk(R, Found),
    memberchk(RB, Found).

test(same_color_none) :-
    red_dot(R), blue_bar(BB), blue_dot_r(BD),
    object_locate_same_color([BB, BD], R, Found),
    Found == [].

% --- object_locate_same_form/3 ---

test(same_form_basic) :-
    lshape(L), lshape_far(LF), red_dot(R),
    object_locate_same_form([L, LF, R], L, Found),
    length(Found, 2),
    memberchk(L, Found),
    memberchk(LF, Found).

test(same_form_none) :-
    red_dot(R), red_bar(RB),
    object_locate_same_form([RB], R, Found),
    Found == [].

% --- object_locate_aligned_h/3 ---

test(aligned_h_basic) :-
    red_dot(R),      % top-left row 0
    blue_dot_r(BD),  % top-left row 0
    green_dot_b(G),  % top-left row 2
    object_locate_aligned_h([R, BD, G], R, Found),
    length(Found, 2),
    memberchk(R, Found),
    memberchk(BD, Found).

test(aligned_h_none) :-
    red_dot(R), green_dot_b(G),
    object_locate_aligned_h([G], R, Found),
    Found == [].

% --- object_locate_aligned_v/3 ---

test(aligned_v_basic) :-
    red_dot(R),      % top-left col 0
    green_dot_b(G),  % top-left col 0
    blue_dot_r(BD),  % top-left col 2
    object_locate_aligned_v([R, G, BD], R, Found),
    length(Found, 2),
    memberchk(R, Found),
    memberchk(G, Found).

% --- object_locate_nearest/3 ---

test(nearest_basic) :-
    red_dot(R),      % centroid (0,0)
    blue_dot_r(BD),  % centroid (0,2)
    yellow_dot_br(Y),% centroid (2,2)
    % Nearest to red_dot: blue_dot_r (dist^2=4) vs yellow_dot_br (dist^2=8)
    object_locate_nearest([BD, Y], R, Nearest),
    Nearest == BD.

test(nearest_single) :-
    red_dot(R), blue_dot_r(BD),
    object_locate_nearest([BD], R, Nearest),
    Nearest == BD.

% --- object_locate_farthest/3 ---

test(farthest_basic) :-
    red_dot(R),       % centroid (0,0)
    blue_dot_r(BD),   % centroid (0,2) — dist^2 = 4
    yellow_dot_br(Y), % centroid (2,2) — dist^2 = 8
    object_locate_farthest([BD, Y], R, Farthest),
    Farthest == Y.

test(farthest_single) :-
    red_dot(R), green_dot_b(G),
    object_locate_farthest([G], R, Farthest),
    Farthest == G.

% --- object_locate_n_touching4/3 ---

test(n_touching4_basic) :-
    red_dot(R), touch_below(TB), touch_right(TR), diag_neighbor(DN),
    object_locate_n_touching4([TB, TR, DN], R, N),
    N == 2.

test(n_touching4_none) :-
    red_dot(R), yellow_dot_br(Y),
    object_locate_n_touching4([Y], R, N),
    N == 0.

test(n_touching4_all) :-
    anchor(A), % r(1,1),r(1,2),r(2,1),r(2,2)
    TopN = obj(w, [r(0,1)]),
    BotN = obj(w, [r(3,1)]),
    LeftN = obj(w, [r(1,0)]),
    RightN = obj(w, [r(1,3)]),
    object_locate_n_touching4([TopN, BotN, LeftN, RightN], A, N),
    N == 4.

% --- Additional tests ---

test(above_excludes_self) :-
    red_dot(R), red_bar(B),
    % Ref is included in Objs; Ref should not appear in Found since it has same row
    object_locate_above([R, B], B, Found),
    Found == [R].

test(below_multiple) :-
    red_dot(R),   % row 0
    red_bar(B),   % row 1
    blue_bar(BB), % row 3
    object_locate_below([R, B, BB], R, Found),
    length(Found, 2).

test(left_of_multiple) :-
    red_dot(R),       % col 0
    blue_dot_r(BD),   % col 2
    yellow_dot_br(Y), % col 2
    object_locate_left_of([R, BD, Y], BD, Found),
    Found == [R].

test(right_of_none) :-
    blue_dot_r(BD), yellow_dot_br(Y),
    % BD at col 2; Y at col 2 — same col, not right_of
    object_locate_right_of([BD, Y], Y, Found),
    Found == [].

test(touching4_empty_list) :-
    red_dot(R),
    object_locate_touching4([], R, Found),
    Found == [].

test(touching8_basic_multi) :-
    red_dot(R),          % r(0,0)
    touch_below(TB),     % r(1,0) — 4-adj (also 8-adj)
    touch_right(TR),     % r(0,1) — 4-adj (also 8-adj)
    diag_neighbor(DN),   % r(1,1) — 8-adj only
    object_locate_touching8([TB, TR, DN], R, Found),
    length(Found, 3).

test(overlapping_self) :-
    red_dot(R),
    object_locate_overlapping([R], R, Found),
    Found == [R].

test(same_color_empty) :-
    red_dot(R),
    object_locate_same_color([], R, Found),
    Found == [].

test(same_form_dots_all) :-
    red_dot(R), blue_dot_r(BD), green_dot_b(G),
    % all are single-dot form
    object_locate_same_form([R, BD, G], R, Found),
    length(Found, 3).

test(aligned_v_empty) :-
    red_dot(R),
    object_locate_aligned_v([], R, Found),
    Found == [].

test(nearest_three) :-
    red_dot(R),       % (0,0)
    blue_dot_r(BD),   % (0,2) dist^2=4
    green_dot_b(G),   % (2,0) dist^2=4
    yellow_dot_br(Y), % (2,2) dist^2=8
    object_locate_nearest([BD, G, Y], R, Nearest),
    % Both BD and G are equidistant; msort picks one deterministically
    memberchk(Nearest, [BD, G]).

test(farthest_three) :-
    red_dot(R),       % (0,0)
    blue_dot_r(BD),   % (0,2) dist^2=4
    yellow_dot_br(Y), % (2,2) dist^2=8
    object_locate_farthest([BD, Y], R, Farthest),
    Farthest == Y.

test(n_touching4_single) :-
    red_dot(R), touch_below(TB),
    object_locate_n_touching4([TB], R, N),
    N == 1.

:- end_tests(object_locate).
