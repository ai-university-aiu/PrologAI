% multicolor: multi-color scene analysis — frequency, partition, and queries (mc_*, Layer 193)
:- module(multicolor, [
    mc_color_counts/2,
    mc_count_of_color/3,
    mc_color_present/2,
    mc_dominant_color/2,
    mc_rarest_color/2,
    mc_singleton_colors/2,
    mc_unique_color/2,
    mc_color_freq_rank/3,
    mc_color_partition/2,
    mc_pair_colors/2,
    mc_equal_count_pairs/2,
    mc_majority_color/2,
    mc_n_distinct_colors/2,
    mc_color_index/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for include and maplist
:- use_module(library(apply), [include/3, maplist/3]).

% mc_color_counts(+Scene, -Counts)
% Counts is a sorted list of Color-N pairs, one per distinct color.
% N is the number of objects of that color.
mc_color_counts(Scene, Counts) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-N, (member(C, Colors), mc_count_of_color_(Scene, C, N)), Counts).

% mc_count_of_color_(+Scene, +Color, -N): count objects of Color in Scene
mc_count_of_color_(Scene, Color, N) :-
    findall(_, (member(obj(C, _), Scene), C == Color), Matches),
    length(Matches, N).

% mc_count_of_color(+Scene, +Color, -N)
% N is the number of objects of Color in Scene. N=0 if Color not present.
mc_count_of_color(Scene, Color, N) :-
    mc_count_of_color_(Scene, Color, N).

% mc_color_present(+Scene, +Color)
% Succeed if Color appears in at least one object in Scene.
mc_color_present(Scene, Color) :-
    member(obj(C, _), Scene),
    C == Color,
    !.

% mc_dominant_color(+Scene, -Color)
% Color with the most objects. Ties broken by standard term order.
mc_dominant_color(Scene, Color) :-
    mc_color_counts(Scene, Counts),
    Counts \= [],
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, [_-Color | _]).

% mc_rarest_color(+Scene, -Color)
% Color with the fewest objects. Ties broken by standard term order.
mc_rarest_color(Scene, Color) :-
    mc_color_counts(Scene, Counts),
    Counts \= [],
    findall(N-C, member(C-N, Counts), Keyed),
    msort(Keyed, [_-Color | _]).

% mc_singleton_colors(+Scene, -Colors)
% All colors that appear in exactly one object.
mc_singleton_colors(Scene, Colors) :-
    mc_color_counts(Scene, Counts),
    findall(C, member(C-1, Counts), Colors).

% mc_unique_color(+Scene, -Color)
% Backtrackable: each color that appears in exactly one object.
mc_unique_color(Scene, Color) :-
    mc_color_counts(Scene, Counts),
    member(Color-1, Counts).

% mc_color_freq_rank(+Scene, +N, -Color)
% The Nth most frequent color (1 = most frequent). Fails if N > number of distinct colors.
mc_color_freq_rank(Scene, N, Color) :-
    mc_color_counts(Scene, Counts),
    findall(NegCount-C, (member(C-Count, Counts), NegCount is -Count), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(N, Ranked, Color).

% mc_color_partition(+Scene, -Groups)
% Groups is a list of Color-Objs pairs, one per distinct color.
% Objs is the list of all objects of that color.
mc_color_partition(Scene, Groups) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-Objs, (member(C, Colors), findall(O, (member(O, Scene), O=obj(C,_)), Objs)), Groups).

% mc_pair_colors(+Scene, -Pairs)
% All unordered pairs of distinct colors {C1, C2} as sorted C1-C2 terms (C1 @< C2).
mc_pair_colors(Scene, Pairs) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C1-C2, (member(C1, Colors), member(C2, Colors), C1 @< C2), Pairs).

% mc_equal_count_pairs(+Scene, -Pairs)
% All unordered pairs of colors that have equal object count.
mc_equal_count_pairs(Scene, Pairs) :-
    mc_color_counts(Scene, Counts),
    findall(C1-C2,
        (member(C1-N, Counts),
         member(C2-N, Counts),
         C1 @< C2),
        Pairs).

% mc_majority_color(+Scene, -Color)
% Color whose object count exceeds half the total scene size.
% Fails if no such color exists.
mc_majority_color(Scene, Color) :-
    length(Scene, Total),
    Half is Total / 2,
    mc_color_counts(Scene, Counts),
    member(Color-N, Counts),
    N > Half,
    !.

% mc_n_distinct_colors(+Scene, -N)
% Number of distinct colors in the scene.
mc_n_distinct_colors(Scene, N) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    length(Colors, N).

% mc_color_index(+Scene, +Color, -Index)
% 1-based rank of Color by descending frequency.
% The most frequent color has index 1.
mc_color_index(Scene, Color, Index) :-
    mc_color_counts(Scene, Counts),
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(Index, Ranked, Color).
