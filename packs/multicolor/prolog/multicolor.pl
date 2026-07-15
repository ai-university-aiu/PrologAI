% multicolor: multi-color scene analysis — frequency, partition, and queries (mc_*, Layer 193)
:- module(multicolor, [
    multicolor_color_counts/2,
    multicolor_count_of_color/3,
    multicolor_color_present/2,
    multicolor_dominant_color/2,
    multicolor_rarest_color/2,
    multicolor_singleton_colors/2,
    multicolor_unique_color/2,
    multicolor_color_freq_rank/3,
    multicolor_color_partition/2,
    multicolor_pair_colors/2,
    multicolor_equal_count_pairs/2,
    multicolor_majority_color/2,
    multicolor_n_distinct_colors/2,
    multicolor_color_index/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for include and maplist
:- use_module(library(apply), [include/3, maplist/3]).

% multicolor_color_counts(+Scene, -Counts)
% Counts is a sorted list of Color-N pairs, one per distinct color.
% N is the number of objects of that color.
multicolor_color_counts(Scene, Counts) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-N, (member(C, Colors), multicolor_count_of_color_(Scene, C, N)), Counts).

% multicolor_count_of_color_(+Scene, +Color, -N): count objects of Color in Scene
multicolor_count_of_color_(Scene, Color, N) :-
    findall(_, (member(obj(C, _), Scene), C == Color), Matches),
    length(Matches, N).

% multicolor_count_of_color(+Scene, +Color, -N)
% N is the number of objects of Color in Scene. N=0 if Color not present.
multicolor_count_of_color(Scene, Color, N) :-
    multicolor_count_of_color_(Scene, Color, N).

% multicolor_color_present(+Scene, +Color)
% Succeed if Color appears in at least one object in Scene.
multicolor_color_present(Scene, Color) :-
    member(obj(C, _), Scene),
    C == Color,
    !.

% multicolor_dominant_color(+Scene, -Color)
% Color with the most objects. Ties broken by standard term order.
multicolor_dominant_color(Scene, Color) :-
    multicolor_color_counts(Scene, Counts),
    Counts \= [],
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, [_-Color | _]).

% multicolor_rarest_color(+Scene, -Color)
% Color with the fewest objects. Ties broken by standard term order.
multicolor_rarest_color(Scene, Color) :-
    multicolor_color_counts(Scene, Counts),
    Counts \= [],
    findall(N-C, member(C-N, Counts), Keyed),
    msort(Keyed, [_-Color | _]).

% multicolor_singleton_colors(+Scene, -Colors)
% All colors that appear in exactly one object.
multicolor_singleton_colors(Scene, Colors) :-
    multicolor_color_counts(Scene, Counts),
    findall(C, member(C-1, Counts), Colors).

% multicolor_unique_color(+Scene, -Color)
% Backtrackable: each color that appears in exactly one object.
multicolor_unique_color(Scene, Color) :-
    multicolor_color_counts(Scene, Counts),
    member(Color-1, Counts).

% multicolor_color_freq_rank(+Scene, +N, -Color)
% The Nth most frequent color (1 = most frequent). Fails if N > number of distinct colors.
multicolor_color_freq_rank(Scene, N, Color) :-
    multicolor_color_counts(Scene, Counts),
    findall(NegCount-C, (member(C-Count, Counts), NegCount is -Count), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(N, Ranked, Color).

% multicolor_color_partition(+Scene, -Groups)
% Groups is a list of Color-Objs pairs, one per distinct color.
% Objs is the list of all objects of that color.
multicolor_color_partition(Scene, Groups) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-Objs, (member(C, Colors), findall(O, (member(O, Scene), O=obj(C,_)), Objs)), Groups).

% multicolor_pair_colors(+Scene, -Pairs)
% All unordered pairs of distinct colors {C1, C2} as sorted C1-C2 terms (C1 @< C2).
multicolor_pair_colors(Scene, Pairs) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C1-C2, (member(C1, Colors), member(C2, Colors), C1 @< C2), Pairs).

% multicolor_equal_count_pairs(+Scene, -Pairs)
% All unordered pairs of colors that have equal object count.
multicolor_equal_count_pairs(Scene, Pairs) :-
    multicolor_color_counts(Scene, Counts),
    findall(C1-C2,
        (member(C1-N, Counts),
         member(C2-N, Counts),
         C1 @< C2),
        Pairs).

% multicolor_majority_color(+Scene, -Color)
% Color whose object count exceeds half the total scene size.
% Fails if no such color exists.
multicolor_majority_color(Scene, Color) :-
    length(Scene, Total),
    Half is Total / 2,
    multicolor_color_counts(Scene, Counts),
    member(Color-N, Counts),
    N > Half,
    !.

% multicolor_n_distinct_colors(+Scene, -N)
% Number of distinct colors in the scene.
multicolor_n_distinct_colors(Scene, N) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    length(Colors, N).

% multicolor_color_index(+Scene, +Color, -Index)
% 1-based rank of Color by descending frequency.
% The most frequent color has index 1.
multicolor_color_index(Scene, Color, Index) :-
    multicolor_color_counts(Scene, Counts),
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(Index, Ranked, Color).
