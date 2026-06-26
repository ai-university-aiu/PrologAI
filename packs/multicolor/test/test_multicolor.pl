:- use_module('../prolog/multicolor').
:- use_module(library(plunit)).

% Fixtures
scene_one_color([obj(r,[r(0,0)]), obj(r,[r(0,1)])]).
scene_two_colors([obj(r,[r(0,0)]), obj(b,[r(0,1)])]).
scene_three_colors([obj(r,[r(0,0)]), obj(b,[r(0,1)]), obj(g,[r(1,0)])]).
scene_imbalanced([obj(r,[r(0,0)]), obj(r,[r(0,1)]), obj(r,[r(1,0)]), obj(b,[r(1,1)])]).
% r appears 3 times, b once
scene_tie([obj(r,[r(0,0)]), obj(b,[r(0,1)]), obj(g,[r(1,0)]), obj(y,[r(1,1)])]).
% All colors appear once

:- begin_tests(multicolor).

% mc_color_counts: basic two-color scene
test(color_counts_two) :-
    scene_two_colors(S),
    mc_color_counts(S, Counts),
    msort(Counts, Sorted),
    Sorted == [b-1, r-1].

% mc_color_counts: three colors
test(color_counts_three) :-
    scene_three_colors(S),
    mc_color_counts(S, Counts),
    msort(Counts, Sorted),
    Sorted == [b-1, g-1, r-1].

% mc_color_counts: one color repeated
test(color_counts_one_repeated) :-
    scene_one_color(S),
    mc_color_counts(S, Counts),
    Counts == [r-2].

% mc_color_counts: empty scene
test(color_counts_empty) :-
    mc_color_counts([], Counts),
    Counts == [].

% mc_count_of_color: present color
test(count_of_color_present) :-
    scene_imbalanced(S),
    mc_count_of_color(S, r, N),
    N == 3.

% mc_count_of_color: single occurrence
test(count_of_color_single) :-
    scene_imbalanced(S),
    mc_count_of_color(S, b, N),
    N == 1.

% mc_count_of_color: absent color is zero
test(count_of_color_absent) :-
    scene_two_colors(S),
    mc_count_of_color(S, g, N),
    N == 0.

% mc_color_present: present color succeeds
test(color_present_yes) :-
    scene_two_colors(S),
    mc_color_present(S, r).

% mc_color_present: absent color fails
test(color_present_no) :-
    scene_two_colors(S),
    \+ mc_color_present(S, g).

% mc_dominant_color: clear winner
test(dominant_color_clear) :-
    scene_imbalanced(S),
    mc_dominant_color(S, r).

% mc_dominant_color: tie broken by term order (b @< r)
test(dominant_color_tie) :-
    scene_two_colors(S),  % r-1, b-1: tie; b @< r
    mc_dominant_color(S, b).

% mc_rarest_color: clear loser
test(rarest_color_clear) :-
    scene_imbalanced(S),
    mc_rarest_color(S, b).

% mc_rarest_color: all tied, term order picks first
test(rarest_color_all_tied) :-
    scene_three_colors(S),  % b-1, g-1, r-1: tie; b @< g @< r
    mc_rarest_color(S, b).

% mc_singleton_colors: all singletons
test(singleton_colors_all) :-
    scene_three_colors(S),
    mc_singleton_colors(S, Colors),
    msort(Colors, Sorted),
    Sorted == [b, g, r].

% mc_singleton_colors: one singleton
test(singleton_colors_one) :-
    scene_imbalanced(S),
    mc_singleton_colors(S, Colors),
    Colors == [b].

% mc_singleton_colors: no singletons (one color, two objects)
test(singleton_colors_none) :-
    scene_one_color(S),
    mc_singleton_colors(S, Colors),
    Colors == [].

% mc_unique_color: backtrackable
test(unique_color_finds_all) :-
    scene_three_colors(S),
    findall(C, mc_unique_color(S, C), Found),
    msort(Found, Sorted),
    Sorted == [b, g, r].

% mc_unique_color: only one matches
test(unique_color_one_match) :-
    scene_imbalanced(S),
    mc_unique_color(S, b).

% mc_color_freq_rank: rank 1 is most frequent
test(freq_rank_1) :-
    scene_imbalanced(S),  % r=3, b=1
    mc_color_freq_rank(S, 1, Color),
    Color == r.

% mc_color_freq_rank: rank 2
test(freq_rank_2) :-
    scene_imbalanced(S),
    mc_color_freq_rank(S, 2, Color),
    Color == b.

% mc_color_freq_rank: out of range fails
test(freq_rank_out_of_range) :-
    scene_two_colors(S),
    \+ mc_color_freq_rank(S, 3, _).

% mc_color_partition: groups by color
test(color_partition_two) :-
    scene_two_colors(S),
    mc_color_partition(S, Groups),
    member(b-[obj(b,[r(0,1)])], Groups),
    member(r-[obj(r,[r(0,0)])], Groups),
    length(Groups, 2).

% mc_color_partition: single color
test(color_partition_one) :-
    scene_one_color(S),
    mc_color_partition(S, Groups),
    Groups = [r-Objs],
    length(Objs, 2).

% mc_color_partition: empty scene
test(color_partition_empty) :-
    mc_color_partition([], Groups),
    Groups == [].

% mc_pair_colors: two colors give one pair
test(pair_colors_two) :-
    scene_two_colors(S),
    mc_pair_colors(S, Pairs),
    Pairs == [b-r].

% mc_pair_colors: three colors give three pairs
test(pair_colors_three) :-
    scene_three_colors(S),
    mc_pair_colors(S, Pairs),
    msort(Pairs, Sorted),
    Sorted == [b-g, b-r, g-r].

% mc_pair_colors: single color gives no pairs
test(pair_colors_single) :-
    scene_one_color(S),
    mc_pair_colors(S, Pairs),
    Pairs == [].

% mc_equal_count_pairs: all same count
test(equal_count_pairs_all_equal) :-
    scene_three_colors(S),  % b-1, g-1, r-1
    mc_equal_count_pairs(S, Pairs),
    msort(Pairs, Sorted),
    Sorted == [b-g, b-r, g-r].

% mc_equal_count_pairs: none equal
test(equal_count_pairs_none) :-
    scene_imbalanced(S),  % r-3, b-1
    mc_equal_count_pairs(S, Pairs),
    Pairs == [].

% mc_majority_color: clear majority
test(majority_color_clear) :-
    scene_imbalanced(S),  % r=3 out of 4 = 75%
    mc_majority_color(S, r).

% mc_majority_color: no majority fails
test(majority_color_none) :-
    scene_two_colors(S),  % r=1, b=1 — neither > 50%
    \+ mc_majority_color(S, _).

% mc_n_distinct_colors: two colors
test(n_distinct_two) :-
    scene_two_colors(S),
    mc_n_distinct_colors(S, N),
    N == 2.

% mc_n_distinct_colors: one color
test(n_distinct_one) :-
    scene_one_color(S),
    mc_n_distinct_colors(S, N),
    N == 1.

% mc_n_distinct_colors: empty scene
test(n_distinct_empty) :-
    mc_n_distinct_colors([], N),
    N == 0.

% mc_color_index: most frequent is index 1
test(color_index_1) :-
    scene_imbalanced(S),
    mc_color_index(S, r, 1).

% mc_color_index: least frequent is index 2 (of 2)
test(color_index_2) :-
    scene_imbalanced(S),
    mc_color_index(S, b, 2).

% mc_color_index: backtrackable over tied colors
test(color_index_tied) :-
    scene_tie(S),  % all count=1; sorted by descending count then term order
    mc_color_index(S, b, 1).  % b @< g @< r @< y

% mc_count_of_color: three of one color
test(count_of_color_three) :-
    scene_imbalanced(S),
    mc_count_of_color(S, r, 3).

% mc_n_distinct_colors: three distinct
test(n_distinct_three) :-
    scene_three_colors(S),
    mc_n_distinct_colors(S, N),
    N == 3.

% mc_color_partition: three colors
test(color_partition_three) :-
    scene_three_colors(S),
    mc_color_partition(S, Groups),
    length(Groups, 3),
    member(r-[obj(r,[r(0,0)])], Groups).

% mc_dominant_color: single-color scene
test(dominant_color_single) :-
    scene_one_color(S),
    mc_dominant_color(S, r).

% mc_rarest_color: single-color scene
test(rarest_color_single) :-
    scene_one_color(S),
    mc_rarest_color(S, r).

:- end_tests(multicolor).
