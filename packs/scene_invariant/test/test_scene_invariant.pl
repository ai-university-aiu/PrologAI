:- use_module('../prolog/scene_invariant').
:- use_module(library(plunit)).

% Scene fixtures: obj(Color, Cells) lists used as Before or After.
scene_one([obj(r, [r(0,0)])]).
scene_two([obj(r, [r(0,0)]), obj(b, [r(0,1)])]).
scene_three([obj(r, [r(0,0)]), obj(b, [r(0,1)]), obj(g, [r(1,0)])]).
scene_one_big([obj(r, [r(0,0), r(0,1), r(1,0)])]).

% Pair fixtures: Before-After terms.
% pair_n1_n1: 1 object before, 1 after
pair_n1_n1([obj(r,[r(0,0)])] - [obj(b,[r(0,0)])]).
% pair_n2_n2: 2 objects before, 2 after
pair_n2_n2([obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(b,[r(0,0)]), obj(r,[r(0,1)])]).
% pair_n1_n2: 1 object before, 2 after
pair_n1_n2([obj(r,[r(0,0)])] - [obj(r,[r(0,0)]), obj(b,[r(0,1)])]).
% pair_same_colors: r and b in both Before and After (color swap)
pair_same_colors([obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(b,[r(0,0)]), obj(r,[r(0,1)])]).
% pair_diff_colors: r before, g after (different color sets)
pair_diff_colors([obj(r,[r(0,0)])] - [obj(g,[r(0,0)])]).
% pair_same_cells: 2 cells each side (recolor only)
pair_same_cells([obj(r,[r(0,0),r(0,1)])] - [obj(b,[r(0,0),r(0,1)])]).
% pair_diff_cells: 1 cell before, 2 cells after
pair_diff_cells([obj(r,[r(0,0)])] - [obj(b,[r(0,0),r(0,1)])]).
% pair_zero_before: empty Before
pair_zero_before([] - [obj(r,[r(0,0)])]).
% pair_zero_after: empty After
pair_zero_after([obj(r,[r(0,0)])] - []).

:- begin_tests(scene_invariant).

% scene_invariant_n_before: count objects in Before scene
test(n_before_one) :-
    pair_n1_n1(P), scene_invariant_n_before(P, N), N == 1.

test(n_before_two) :-
    pair_n2_n2(P), scene_invariant_n_before(P, N), N == 2.

test(n_before_zero) :-
    pair_zero_before(P), scene_invariant_n_before(P, N), N == 0.

% scene_invariant_n_after: count objects in After scene
test(n_after_one) :-
    pair_n1_n1(P), scene_invariant_n_after(P, N), N == 1.

test(n_after_two) :-
    pair_n2_n2(P), scene_invariant_n_after(P, N), N == 2.

test(n_after_zero) :-
    pair_zero_after(P), scene_invariant_n_after(P, N), N == 0.

% scene_invariant_all_n_before: list of counts
test(all_n_before_single_pair) :-
    pair_n1_n1(P), scene_invariant_all_n_before([P], Ns), Ns == [1].

test(all_n_before_two_pairs) :-
    pair_n1_n1(P1), pair_n2_n2(P2),
    scene_invariant_all_n_before([P1, P2], Ns), Ns == [1, 2].

test(all_n_after_single_pair) :-
    pair_n2_n2(P), scene_invariant_all_n_after([P], Ns), Ns == [2].

test(all_n_after_two_pairs) :-
    pair_n1_n1(P1), pair_n2_n2(P2),
    scene_invariant_all_n_after([P1, P2], Ns), Ns == [1, 2].

% scene_invariant_const_n_before: constant object count in Before
test(const_n_before_yes) :-
    pair_n1_n1(P1), pair_diff_colors(P2),
    scene_invariant_const_n_before([P1, P2], N), N == 1.

test(const_n_before_no) :-
    pair_n1_n1(P1), pair_n2_n2(P2),
    \+ scene_invariant_const_n_before([P1, P2], _).

test(const_n_before_empty_fails) :-
    \+ scene_invariant_const_n_before([], _).

% scene_invariant_const_n_after: constant object count in After
test(const_n_after_yes) :-
    pair_n1_n1(P1), pair_diff_colors(P2),
    scene_invariant_const_n_after([P1, P2], N), N == 1.

test(const_n_after_no) :-
    pair_n1_n2(P1), pair_n1_n1(P2),
    \+ scene_invariant_const_n_after([P1, P2], _).

test(const_n_after_empty_fails) :-
    \+ scene_invariant_const_n_after([], _).

% scene_invariant_n_preserved: object count same Before vs After
test(n_preserved_yes_single) :-
    pair_n1_n1(P), scene_invariant_n_preserved([P]).

test(n_preserved_yes_two_pairs) :-
    pair_n1_n1(P1), pair_n2_n2(P2),
    scene_invariant_n_preserved([P1, P2]).

test(n_preserved_no) :-
    pair_n1_n2(P), \+ scene_invariant_n_preserved([P]).

test(n_preserved_empty) :-
    scene_invariant_n_preserved([]).

% scene_invariant_colors_before: sorted colors in Before
test(colors_before_one) :-
    pair_n1_n1(P), scene_invariant_colors_before(P, Colors), Colors == [r].

test(colors_before_two) :-
    pair_same_colors(P), scene_invariant_colors_before(P, Colors),
    Colors == [b, r].

test(colors_before_diff_pair) :-
    pair_diff_colors(P), scene_invariant_colors_before(P, Colors), Colors == [r].

% scene_invariant_colors_after: sorted colors in After
test(colors_after_one) :-
    pair_n1_n1(P), scene_invariant_colors_after(P, Colors), Colors == [b].

test(colors_after_two) :-
    pair_same_colors(P), scene_invariant_colors_after(P, Colors),
    Colors == [b, r].

test(colors_after_diff) :-
    pair_diff_colors(P), scene_invariant_colors_after(P, Colors), Colors == [g].

% scene_invariant_const_colors_before: color set constant across all Before scenes
test(const_colors_before_yes) :-
    pair_n1_n1(P1), pair_diff_cells(P2),
    scene_invariant_const_colors_before([P1, P2], Colors), Colors == [r].

test(const_colors_before_no) :-
    pair_n1_n1(P1), pair_same_colors(P2),
    \+ scene_invariant_const_colors_before([P1, P2], _).

test(const_colors_before_empty_fails) :-
    \+ scene_invariant_const_colors_before([], _).

% scene_invariant_const_colors_after: color set constant across all After scenes
test(const_colors_after_yes) :-
    pair_n1_n1(P1), pair_diff_cells(P2),
    scene_invariant_const_colors_after([P1, P2], Colors), Colors == [b].

test(const_colors_after_no) :-
    pair_n1_n1(P1), pair_diff_colors(P2),
    \+ scene_invariant_const_colors_after([P1, P2], _).

test(const_colors_after_empty_fails) :-
    \+ scene_invariant_const_colors_after([], _).

% scene_invariant_colors_preserved: color set same in Before and After
test(colors_preserved_yes_recolor) :-
    pair_same_colors(P), scene_invariant_colors_preserved([P]).

test(colors_preserved_yes_same_color) :-
    pair_same_cells(P), \+ scene_invariant_colors_preserved([P]).

test(colors_preserved_no_diff_colors) :-
    pair_diff_colors(P), \+ scene_invariant_colors_preserved([P]).

test(colors_preserved_empty) :-
    scene_invariant_colors_preserved([]).

% scene_invariant_total_cells_before: sum of cell counts in Before
test(total_cells_before_one_cell) :-
    pair_n1_n1(P), scene_invariant_total_cells_before(P, N), N == 1.

test(total_cells_before_two_cells) :-
    pair_same_cells(P), scene_invariant_total_cells_before(P, N), N == 2.

test(total_cells_before_three_cells) :-
    scene_one_big(B), pair_n1_n1(P0),
    P0 = _-A, P = B-A,
    scene_invariant_total_cells_before(P, N), N == 3.

% scene_invariant_cells_preserved: total cell count same Before vs After
test(cells_preserved_yes) :-
    pair_same_cells(P), scene_invariant_cells_preserved([P]).

test(cells_preserved_n1_n1) :-
    pair_n1_n1(P), scene_invariant_cells_preserved([P]).

test(cells_preserved_no) :-
    pair_diff_cells(P), \+ scene_invariant_cells_preserved([P]).

test(cells_preserved_empty) :-
    scene_invariant_cells_preserved([]).

% Cross-predicate: n_before == n_after implies n_preserved
test(n_before_after_equal_implies_preserved) :-
    pair_n2_n2(P),
    scene_invariant_n_before(P, NB), scene_invariant_n_after(P, NA),
    NB == NA,
    scene_invariant_n_preserved([P]).

% const_n_before single pair
test(const_n_before_single_pair) :-
    pair_n1_n1(P), scene_invariant_const_n_before([P], N), N == 1.

% const_n_after single pair
test(const_n_after_single_pair) :-
    pair_n1_n1(P), scene_invariant_const_n_after([P], N), N == 1.

:- end_tests(scene_invariant).
