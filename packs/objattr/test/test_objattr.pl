:- use_module('../prolog/objattr').
:- use_module(library(plunit)).

:- begin_tests(objattr).

% --- Test fixtures ---
% red dot at r(0,0) — size 1
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,1) — size 1
blue_dot(obj(b, [r(0,1)])).
% green dot at r(1,0) — size 1
green_dot(obj(g, [r(1,0)])).
% red bar: 3 cells, r(0,0)..r(0,2) — size 3
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
% blue bar: 3 cells, r(1,0)..r(1,2) — size 3
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
% red sq: 4 cells, 2x2 at r(0,0) — size 4
red_sq(obj(r, [r(0,0),r(0,1),r(1,0),r(1,1)])).
% yellow sq: 4 cells, 2x2 at r(2,2) — size 4
yellow_sq(obj(y, [r(2,2),r(2,3),r(3,2),r(3,3)])).
% L-shape: 3 cells r(0,0),r(1,0),r(1,1) — size 3
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
% L-shape far: same shape at r(3,4) — size 3
lshape_far(obj(b, [r(3,4),r(4,4),r(4,5)])).

% --- objattr_total_cells/2 ---

test(total_cells_basic) :-
    red_dot(R), blue_bar(B),
    % 1 + 3 = 4
    objattr_total_cells([R, B], N),
    N == 4.

test(total_cells_empty) :-
    objattr_total_cells([], N),
    N == 0.

test(total_cells_all_same) :-
    red_dot(D1), blue_dot(D2), green_dot(D3),
    objattr_total_cells([D1, D2, D3], N),
    N == 3.

% --- objattr_color_counts/2 ---

test(color_counts_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objattr_color_counts([R, B, RB], Pairs),
    member(b-1, Pairs),
    member(r-2, Pairs).

test(color_counts_single_color) :-
    red_dot(D), red_bar(B), red_sq(S),
    objattr_color_counts([D, B, S], Pairs),
    Pairs == [r-3].

test(color_counts_empty) :-
    objattr_color_counts([], Pairs),
    Pairs == [].

% --- objattr_cell_counts_by_color/2 ---

test(cell_counts_by_color_basic) :-
    red_dot(R), red_bar(RB), blue_dot(B),
    % red total = 1+3=4, blue total = 1
    objattr_cell_counts_by_color([R, RB, B], Pairs),
    member(b-1, Pairs),
    member(r-4, Pairs).

test(cell_counts_by_color_same) :-
    red_dot(D), blue_dot(B),
    % both size 1
    objattr_cell_counts_by_color([D, B], Pairs),
    member(b-1, Pairs),
    member(r-1, Pairs).

% --- objattr_n_colors/2 ---

test(n_colors_three) :-
    red_dot(R), blue_dot(B), green_dot(G),
    objattr_n_colors([R, B, G], N),
    N == 3.

test(n_colors_one) :-
    red_dot(R), red_bar(RB),
    objattr_n_colors([R, RB], N),
    N == 1.

test(n_colors_empty) :-
    objattr_n_colors([], N),
    N == 0.

% --- objattr_n_objs_of_color/3 ---

test(n_objs_of_color_basic) :-
    red_dot(R), red_bar(RB), blue_dot(B),
    objattr_n_objs_of_color([R, RB, B], r, N),
    N == 2.

test(n_objs_of_color_zero) :-
    red_dot(R),
    objattr_n_objs_of_color([R], b, N),
    N == 0.

% --- objattr_dominant_color/2 ---

test(dominant_color_basic) :-
    red_sq(S), blue_dot(B), green_dot(G),
    % red has 4 cells, blue=1, green=1
    objattr_dominant_color([S, B, G], C),
    C == r.

test(dominant_color_single) :-
    red_dot(R),
    objattr_dominant_color([R], C),
    C == r.

% --- objattr_rarest_color/2 ---

test(rarest_color_basic) :-
    red_sq(S), blue_dot(B), green_dot(G),
    % blue=1, green=1, red=4 — rarest is b or g (first in sorted order)
    objattr_rarest_color([S, B, G], C),
    member(C, [b, g]).

test(rarest_color_single) :-
    blue_dot(B),
    objattr_rarest_color([B], C),
    C == b.

% --- objattr_unique_color/2 ---

test(unique_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    % blue appears once; red appears twice
    objattr_unique_color([R, B, RB], C),
    C == b.

test(unique_color_all_unique) :-
    red_dot(R), blue_dot(B), green_dot(G),
    % all appear once; objattr_unique_color/2 returns first alphabetically
    objattr_unique_color([R, B, G], _).

test(unique_color_none) :-
    red_dot(R), red_bar(RB),
    \+ objattr_unique_color([R, RB], _).

% --- objattr_size_rank/2 ---

test(size_rank_basic) :-
    red_dot(D), red_bar(B), red_sq(S),
    % sq=4, bar=3, dot=1 -> [sq, bar, dot]
    objattr_size_rank([D, B, S], [S, B, D]).

test(size_rank_single) :-
    red_dot(D),
    objattr_size_rank([D], [D]).

% --- objattr_pos_rank/2 ---

test(pos_rank_basic) :-
    % dot at r(0,0), bar at r(0,0) — same row, dot and bar share min col
    red_sq(S),   % top-left r(0,0)
    yellow_sq(Y), % top-left r(2,2)
    % S before Y in row-major order
    objattr_pos_rank([Y, S], [S, Y]).

test(pos_rank_row_order) :-
    red_dot(R),       % r(0,0)
    green_dot(G),     % r(1,0)
    blue_dot(B),      % r(0,1)
    % row-major: r(0,0) < r(0,1) < r(1,0)
    objattr_pos_rank([G, B, R], [R, B, G]).

% --- objattr_majority_size/2 ---

test(majority_size_basic) :-
    red_dot(D1), blue_dot(D2), red_bar(B), red_sq(S),
    % sizes: 1,1,3,4 — majority is 1
    objattr_majority_size([D1, D2, B, S], N),
    N == 1.

test(majority_size_single) :-
    red_bar(B),
    objattr_majority_size([B], N),
    N == 3.

% --- objattr_all_same_color/1 ---

test(all_same_color_true) :-
    red_dot(D), red_bar(B), red_sq(S),
    objattr_all_same_color([D, B, S]).

test(all_same_color_false) :-
    red_dot(D), blue_dot(B),
    \+ objattr_all_same_color([D, B]).

test(all_same_color_empty) :-
    objattr_all_same_color([]).

test(all_same_color_single) :-
    blue_dot(B),
    objattr_all_same_color([B]).

% --- objattr_all_same_size/1 ---

test(all_same_size_true) :-
    red_dot(D), blue_dot(BD), green_dot(G),
    objattr_all_same_size([D, BD, G]).

test(all_same_size_false) :-
    red_dot(D), red_bar(B),
    \+ objattr_all_same_size([D, B]).

test(all_same_size_empty) :-
    objattr_all_same_size([]).

% --- objattr_all_same_form/1 ---

test(all_same_form_true) :-
    lshape(L), lshape_far(LF),
    % same shape, different colors and positions
    objattr_all_same_form([L, LF]).

test(all_same_form_false) :-
    lshape(L), red_bar(B),
    \+ objattr_all_same_form([L, B]).

test(all_same_form_empty) :-
    objattr_all_same_form([]).

test(all_same_form_dots) :-
    % All dots have same shape: just r(0,0) after normalization
    red_dot(R), blue_dot(B), green_dot(G),
    objattr_all_same_form([R, B, G]).

% --- Additional tests ---

test(total_cells_three_objs) :-
    red_dot(D), red_bar(B), red_sq(S),
    % 1 + 3 + 4 = 8
    objattr_total_cells([D, B, S], N),
    N == 8.

test(n_colors_two) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    objattr_n_colors([R, B, RB], N),
    N == 2.

test(dominant_color_two_reds) :-
    red_dot(D), red_bar(B), blue_dot(BD),
    % red total = 4, blue total = 1
    objattr_dominant_color([D, B, BD], C),
    C == r.

test(majority_size_three_same) :-
    red_dot(D1), blue_dot(D2), green_dot(D3), red_bar(B),
    % sizes: 1,1,1,3 — majority is 1
    objattr_majority_size([D1, D2, D3, B], N),
    N == 1.

:- end_tests(objattr).
